package hephaestus/Disco/RemoteSys/arp

import (
	"fmt"
	"math/rand"
	"net"
	"sync"
	"time"

	"github.com/mdlayher/arp"
	"github.com/DiegoBoy/hephaestus/Disco/RemoteSys/arp"
)

type Scanner struct {
	Timeout	time.Duration
	Iface *net.Interface
}

type Result struct {
	Target	net.IP
	Err		error
}

func main() error {
	if iface, err := net.InterfaceByName("eth0"); err != nil {
		fmt.Printf("[!] %w\n", err)
		return
	} else if s, err := New(iface); err != nil {
		fmt.Printf("[!] %w\n", err)
		return
	}

	for r := range s.Scan() {
		if r.Err != nil {
			fmt.Printf("[!] %v: %w\n", ip, err)
		} else {
			fmt.Printf("[*] %v\n", err.Target)
		}
	}
}

func New(iface *net.Interface) (*ArpScanner, error) {
	if iface.HardwareAddr == nil {
		return nil, fmt.Errorf("Error: 'invalid network interface %s'\texpected: HardwarAddr,\tgot: nil", iface.Name)
	} 

	s =	&ArpScanner { 
		Timeout: time.Duration(time.Second),
		iface: iface
	}
	return s, nil
}

func (s *ArpScanner) ScanRange() <-chan Result {
	ch := make(chan Result)
	defer close(ch)
	
	var wg sync.WaitGroup
	for i := 0; i < 256; i++ {
		wg.Add(1)

		go func(ch chan<- ArpScanner, i int) {
			defer wg.Done()
	
			// wait rand(100)ms before pinging to wind down the flood
			delay := time.Millisecond * time.Duration(rand.Intn(100))
			time.Sleep(delay)
	
			ip := net.ParseIP(fmt.Sprintf("192.168.132.%d", i))
			
			isAlive, err := s.Scan(ip)
			if err != nil {
				ch<-Result{ Target: ip, Err, err }
			} else if isAlive {
				ch<-Result{ Target: ip, Err, nil }
			}
		}(ch, i)
	}
	wg.Wait()
}

func (s *ArpScanner) Scan(ip net.IP) (bool, error) {
	client, err := arp.Dial(s.iface)
	if err != nil { return false, err }

	err = client.Request(ip);
	if err != nil { return false, err }

	timeout := time.After(s.Timeout)
	for {
		select {
		case <-timeout:
			return false, nil
		default:
			var response *arp.Packet
			response, _, err = client.Read()
			if err != nil { return false, err }

			if response.Operation == arp.OperationReply && response.SenderIP.Equal(ip) {
				return true, nil
			}
		}
	}
}