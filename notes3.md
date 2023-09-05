In PowerShell, you can launch another window using the `Start-Process` cmdlet. To communicate between multiple PowerShell instances, you can use various methods such as named pipes, TCP/IP sockets, or shared files. Here's an example using named pipes:

1. Launch a new PowerShell window using `Start-Process`:

```powershell
Start-Process powershell.exe
```

This will open a new PowerShell window.

2. In the newly opened PowerShell window, create a named pipe server using the `New-Object` cmdlet:

```powershell
$pipeServer = New-Object System.IO.Pipes.NamedPipeServerStream("MyNamedPipe", [System.IO.Pipes.PipeDirection]::InOut)
```

This command creates a named pipe server named "MyNamedPipe" that supports both reading and writing.

3. In the original PowerShell window, connect to the named pipe server using the `New-Object` cmdlet:

```powershell
$pipeClient = New-Object System.IO.Pipes.NamedPipeClientStream(".", "MyNamedPipe", [System.IO.Pipes.PipeDirection]::InOut)
```

This command creates a named pipe client that connects to the server using the same pipe name.

4. In both the server and client PowerShell windows, use the pipe to communicate. For example, in the server window, you can send a message:

```powershell
$pipeServer.WriteByte(65)  # Sending ASCII value of 'A'
$pipeServer.Flush()
```

5. In the client window, you can read the message:

```powershell
$receivedByte = $pipeClient.ReadByte()
$receivedChar = [char]$receivedByte
Write-Host "Received: $receivedChar"
```

This will read the byte sent by the server and convert it back to a character.

By using this approach, you can establish communication channels between multiple PowerShell instances. However, keep in mind that this is a basic example, and depending on your specific requirements, you may need to implement more sophisticated mechanisms for inter-process communication.

I have a plan to use a master powershell to be the RoundTable
With a "King" and "Knights"...or whatever you want to use
Each Knight would be a seperate powershell instance of PaullyGPT with different directives.
The King will generate codeblocks of directives for each Knight to achieve the King's goals.

Knight will communicate with the King via named pipes.
Instead of a keyboard input, it will receieve pipe streams from the King.
Instead of displaying output, it's result will be sent via pipe streams with codeblocks for the King.
Codeblocks will be the function result of these Knight processes.

Some Knights will have access to storage with knowledge of query and insert commands.
Some Knights will be used for translations/mapping between systems.
Some Knights will be used for writing directives.
Some Knights will be used for implementing directives and their codeblocks will be used to initiate external calls (somehow).

Some Knights will be containerized with only directives
Some Knights will get a shared summary from the King of other knights.
The King must be good at organization and planning.

It would be nice to have 1 codebase. 