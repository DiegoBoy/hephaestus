package main

import (
	"bytes"
	"fmt"
	"math"
	"math/rand"
	"net"
	"runtime"
	"strings"
	"sync"
	"sync/atomic"
	"syscall"
	"time"

	"golang.org/x/net/icmp"
	"golang.org/x/net/ipv4"
	"golang.org/x/net/ipv6"
)

type IcmpMode int
const (
	IcmpModeRaw IcmpMode = iota
	IcmpModeUnprivileged
)
func (enum IcmpMode) String() string {
	return []string { "IcmpModeRaw", "IcmpModeUnprivileged" }[enum]
}

const (
	_protocolIcmp     = 1
	_protocolIPv6Icmp = 58
)

var (
	_networkIpv4 = map[IcmpMode]string{ IcmpModeRaw: "ip4:icmp",	  IcmpModeUnprivileged: "udp4" }
	_networkIpv6 = map[IcmpMode]string{ IcmpModeRaw: "ip6:ipv6-icmp", IcmpModeUnprivileged: "udp6" }
)

// TODO: check Sender IP in response - report if it's a different IP than the address pinged
func main() {
	// if len(os.Args) < 2 {
	// 	fmt.Printf("Upase: %p <ip address>\n", os.Args[0])
	// 	os.Exit(1)
	// }

	// ip := net.ParseIP(os.Args[1])
	// s := New()
	// ipaddr := &net.IPAddr { ip, "" }
	// scan(s, ipaddr, IcmpPacketRaw)

	var (
		scanner *IcmpScanner = New()
		counter uint32 = 0
		wg sync.WaitGroup
	)

	for i := 0; i < 256; i++ {
		wg.Add(1)

		go func(s *IcmpScanner, i int) {
			defer wg.Done()
	
			// wait rand(100)ms before pinging to wind down the flood
			delay := time.Millisecond * time.Duration(s.rand.Intn(100))
			time.Sleep(delay)
	
			ip := net.ParseIP(fmt.Sprintf("10.11.1.%d", i))
			ipaddr := &net.IPAddr { ip, "" }
			
			//scan(s, ipaddr, IcmpPacketUnprivileged)
			//scan(s, ipaddr, IcmpPacketRaw)

			// if unprivileged (requires  net.ipv4.ping_group_range) fails, try raw (requires sudo)
			for j := 0; j < 2 ; j++ {
				if scan(s, ipaddr, IcmpPacketUnprivileged) || 
				   scan(s, ipaddr, IcmpPacketRaw) {
					atomic.AddUint32(&counter, 1)
					return
				}
			}
		}(scanner, i)
	}

	wg.Wait()
	fmt.Printf("[*]\tTotal found: %d\n", counter)
}

func scan(s *IcmpScanner, ipaddr *net.IPAddr, packetType IcmpMode) bool {
	isAlive, ttl, err := s.Ping(ipaddr, packetType)
	if err != nil {
		fmt.Printf("[!]\t%v\t[proto=%s]\t(%T):\t%w\n", ipaddr, packetType.String(), err, err)
	} else if isAlive {
		fmt.Printf("[*]\t%v\t[proto=%s]\t(ttl:%d)\n", ipaddr, packetType.String(), ttl)
	}
	return isAlive
}

type Scanner struct {
	DataSize	int
	Rand		*rand.Rand
	Timeout		time.Duration
}

func New() *IcmpScanner {
	source := rand.NewSource(GetSeed())
	return &IcmpScanner{
		DataSize:	32,
		Timeout:	time.Second,
		rand:		rand.New(source),
	}
}

func (s *IcmpScanner) Scan(packetType IcmpMode, ipaddr *net.IPAddr) (bool, int, error) {
	var isIPv4 bool = IsIPv4(ipaddr)
	conn, err := Listen(packetType, isIPv4)
	defer conn.Close()
	
	var requestMsg *icmp.Message
	requestMsg, err = s.Send(packetType, ipaddr, conn, isIPv4)
	if err != nil {
		return false, 0, err
	}

	timeout := time.After(s.Timeout)
	for {
		select {
		case <-timeout:
			return false, 0, nil
		default:
			var response *icmpResponse
			response, err = s.recvIcmp(ipaddr, conn, isIPv4)
			
			// ignore, cauped by read timeout
			if e, ok := err.(*net.OpError); 
				ok && strings.HasPrefix(e.Error(), "read ") {				
					continue
			} else if e, ok := err.(error); 
				ok && e.Error() == "invalid connection" {
					continue
			}
			
			if err != nil {
				return false, 0, err
			} else if echoReplyMatches(requestMsg, response.msg) {
				return true, response.ttl, nil
			}
		}
	}
}

func Listen(icmpMode IcmpMode, ipaddr *net.IPAddr) (*icmp.PacketConn, error) {
	var (
		conn *icmp.PacketConn
		err error
	)

	if IsIPv4(ipaddr) {
		if conn, err = icmp.ListenPacket(_networkIpv4[icmpMode], net.IPv4zero.String()); err != nil {
			return nil, err
		}
		err = conn.IPv4PacketConn().SetControlMessage(ipv4.FlagTTL, true)
	} else {
		if conn, err = icmp.ListenPacket(_networkIpv6[icmpMode], net.IPv6zero.String()); err != nil {
			return nil, err
		}
		err = conn.IPv6PacketConn().SetControlMessage(ipv6.FlagHopLimit, true)
	}
	
	if runtime.GOOS != "windows" && err != nil {
		return nil, err
	}

	return conn, nil
}

func (s *IcmpScanner) Send(icmpMode IcmpMode, ipaddr *net.IPAddr, conn *icmp.PacketConn, isIPv4 bool) (*icmp.Message, error) {
	switch icmpMode {
	case IcmpModeIcmp:
		return s.SendIcmpEcho(ipaddr, conn, isIPv4)
	case IcmpPacketUnprivileged:
		return s.SendUdpEcho(ipaddr, conn, isIPv4)
	default:
		return nil, fmt.Errorf("Invalid ping protocol: %v", protocol)
	}
}

func (s *IcmpScanner) SendIcmpEcho(ipaddr *net.IPAddr, conn *icmp.PacketConn, isIPv4 bool) (*icmp.Message, error) {
	return s.SendEchoInternal(ipaddr, conn, isIPv4)
}

func (s *IcmpScanner) SendUdpEcho(ipaddr *net.IPAddr, conn *icmp.PacketConn, isIPv4 bool) (*icmp.Message, error) {
	udpAddr := &net.UDPAddr{IP: ipaddr.IP, Zone: ipaddr.Zone}
	return s.SendEchoInternal(udpAddr, conn, isIPv4)
}

func (s *IcmpScanner) SendEchoInternal(addr net.Addr, conn *icmp.PacketConn, isIPv4 bool) (*icmp.Message, error) {
	var echoType icmp.Type = ipv4.ICMPTypeEcho
	if !isIPv4 {
		echoType = ipv6.ICMPTypeEchoRequest
	}
	msg := s.craftIcmpMessage(echoType)
	msgBytes, err := msg.Marshal(nil)
	if err != nil {
		return nil, err
	}

	for {
		if _, err := conn.WriteTo(msgBytes, addr); err != nil {
			if neterr, ok := err.(*net.OpError); ok {
				if neterr.Err == syscall.ENOBUFS {
					continue
				}
			}
		}
		return msg, err
	}
}

func (s *IcmpScanner) recvIcmp(ipaddr *net.IPAddr, conn *icmp.PacketConn, isIPv4 bool) (*icmpResponse, error) {
	var err error
	if err = conn.SetReadDeadline(time.Now().Add(time.Millisecond * 500)); err != nil {
		return nil, err
	}

	var protocol, ttl int
	var src, dst net.IP
	buffer := make([]byte, s.getIcmpMsgLength(isIPv4))
	
	if isIPv4 {
		protocol = _protocolIcmp
		
		var cm *ipv4.ControlMessage
		_, cm, _, err = conn.IPv4PacketConn().ReadFrom(buffer)
		if cm != nil {
			ttl = cm.TTL
			src = cm.Src
			dst = cm.Dst
		}
	} else {
		protocol = _protocolIPv6Icmp

		var cm *ipv6.ControlMessage
		_, cm, _, err = conn.IPv6PacketConn().ReadFrom(buffer)
		if cm != nil {
			ttl = cm.HopLimit
			src = cm.Src
			dst = cm.Dst
		}
	}
	if  err != nil {
		return nil, err
	}

	msg, err := icmp.ParseMessage(protocol, buffer)
	response := &icmpResponse{ 
		msg: msg,
		src: src,
		dst: dst,
		ttl: ttl,
	}
	return response, err
}

func (s *IcmpScanner) craftIcmpMessage(echoType icmp.Type) *icmp.Message {
	data := make([]byte, s.DataSize)
	s.rand.Read(data)

	body := &icmp.Echo{
		ID:   s.rand.Intn(math.MaxUint16),
		Seq:  0,
		Data: data,
	}

	msg := &icmp.Message{
		Type: echoType,
		Code: 0,
		Body: body,
	}
	return msg
}

func (s *IcmpScanner) getIcmpMsgLength(isIPv4 bool) int {
	if runtime.GOOS == "windows" {
		if isIPv4 {
			return s.DataSize + 8 + ipv4.HeaderLen
		}
		return s.DataSize + 8 + ipv6.HeaderLen
	}
	return s.DataSize + 8
}

func echoReplyMatches(request *icmp.Message, response *icmp.Message) bool {
	if !ipEchoReply(response) {
		return false
	}

	req, okReq := request.Body.(*icmp.Echo)
	rsp, okRsp := response.Body.(*icmp.Echo)
	return okReq && okRsp && bytes.Equal(req.Data, rsp.Data)
}

func ipEchoReply(msg *icmp.Message) bool {
	return msg.Type == ipv4.ICMPTypeEchoReply || msg.Type == ipv6.ICMPTypeEchoReply
}

type icmpResponse struct {
	msg		*icmp.Message
	src		net.IP
	dst		net.IP
	ttl		int
}

// TODO: move utilp to golang module
/////////////////////
////// UTIL /////////
/////////////////////
var seed uint64 = uint64(time.Now().UnixNano())
func GetSeed() int64 {
	return int64(atomic.AddUint64(&seed, 1))
}

func IsIPv4(ipaddr *net.IPAddr) bool {
	return ipaddr.IP.To4() != nil
}

func IsIPv6(ipaddr *net.IPAddr) bool {
	return !IsIPv4(ipaddr)
}