#!/usr/bin/ruby

# gem install -r winrm
require "winrm"

if ARGV.length < 3
    puts "Usage: %s <target> <user> <passwd>" % File.basename($0)
    exit
end

endpoint = "http://#{ARGV[0]}:5985/wsman"
user = "#{ARGV[1]}"
password = "#{ARGV[2]}"

puts "Connecting to %s with username %s" % [endpoint, user]

conn = WinRM::Connection.new( 
endpoint: endpoint,
  user: user,
  password: password
)

command=""

conn.shell(:powershell) do |shell|
    until command == "exit\n" do
        print "PS > "
        command = STDIN.gets        
        output = shell.run(command) do |stdout, stderr|
            STDOUT.print stdout
            STDERR.print stderr
        end
    end    
    puts "Exiting with code #{output.exitcode}"
end