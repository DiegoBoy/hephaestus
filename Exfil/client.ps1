param (
	[Parameter(Mandatory=$true)]
	[string]$server,
	
	[Parameter(Mandatory=$true)]
	[int]$port, 
	
	[Parameter(Mandatory=$true)]
	[string]$filename
)

$socket = New-Object Net.Sockets.TcpClient($server, $port)
$stream = $socket.GetStream()
Write-Host ('File sender connected to [{0}:{1}]' -f $server, $port)

if (-not $stream.CanWrite)
{
	Write-Host 'Socket cannot write!!!'
	return -1
}

$filename_base = [IO.Path]::GetFileName($filename)
$filename_len = $filename_base.Length
$stream.WriteByte([byte]$filename_len)
Write-Host ('Sent file name length [{0}]' -f $filename_len)
$stream.Write([Text.Encoding]::UTF8.GetBytes($filename_base), 0, $filename_base.Length)
Write-Host ('Sent target file name [{0}]' -f $filename_base)

$buffer = New-Object System.Byte[] 1024;
$file = [IO.File]::OpenRead($filename)
$total = 0
while ($true)
{
    $read_count = $file.Read($buffer, 0, $buffer.Length)
    if ($read_count -le 0)
    {
        break
    }
    $stream.Write($buffer, 0, $read_count)
    $total += $read_count
}

Write-Host ('Sent total [{0}] bytes' -f $total)
$socket.close()
