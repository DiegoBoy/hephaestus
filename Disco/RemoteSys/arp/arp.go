package arp

import (
	"fmt"
	"math/rand"
	"net"
	"sync"
	"time"

	"github.com/mdlayher/arp"
)

type Target {
	IP net.IP
}

type Result struct {
	Target	*Target
	Err		error
}

type Scanner struct {
	Timeout	time.Duration
	Iface *net.Interface
}

func New(iface *net.Interface) (*Scanner, error) {
	if iface.HardwareAddr == nil {
		return nil, fmt.Errorf("Error: 'invalid network interface %s'\texpected: HardwarAddr,\tgot: nil", iface.Name)
	} 

	s := &Scanner { 
		Timeout: time.Duration(time.Second),
		Iface: iface,
	}
	return s, nil
}

func (s *Scanner) Scan(target *Target) (bool, error) {
	client, err := arp.Dial(s.Iface)
	if err != nil { return false, err }

	err = client.Request(target.IP);
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

			if response.Operation == arp.OperationReply && response.SenderIP.Equal(target.IP) {
				return true, nil
			}
		}
	}
}

func (s *Scanner) ScanRange(targets <-chan Target) <-chan Result {
	ch := make(chan Result)

	var wg sync.WaitGroup
	for target := range targets {
		wg.Add(1)

		go func(ch chan<- Result, target Target) {
			defer wg.Done()
	
			// wait rand(100)ms before pinging to wind down the flood
			delay := time.Millisecond * time.Duration(rand.Intn(100))
			time.Sleep(delay)
	
			isAlive, err := s.Scan(target.IP)
			if err != nil {
				ch <- Result{ Target: ip, Err: err }
			} else if isAlive {
				ch <- Result{ Target: ip, Err: nil }
			}
		}(ch, target)
	}
	
	go func() {
		wg.Wait()
		close(ch)
	}()

	return ch
}