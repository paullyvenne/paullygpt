# PaullyGPT
A flavor of ChatGPT powered by PowerShell.

## Introduction

Introducing PaullyGPT, an exceptional ChatGPT client meticulously designed to enhance your research and interactive experiences. Powered by PowerShell, PaullyGPT seamlessly integrates with ChatGPT to provide you with a captivating conversational interface. Engage in insightful discussions, explore diverse perspectives, and unlock the vast depths of knowledge effortlessly. With PaullyGPT, you not only have access to text-based interactions but also the remarkable feature of text-to-speech functionality. Let PaullyGPT be your trusted companion on your journey of discovery, guiding you towards new horizons of knowledge and understanding. Elevate your research and interactive endeavors with the harmonious synergy of PaullyGPT and ChatGPT.

[PaullyGPT client in Powershell](images/paullygpt1.png)

## Features
* A lightning-fast and user-friendly ChatGPT experience in the convenience of a PowerShell or VSCODE Terminal with PS extensions.
* Valuable conversation transcripts are automatically saved to a local folder for reference.
* Seamlessly resume conversations with a handy summary of previous sessions, ensuring continuity and context.
* Enhance your experience with useful Text-To-Speech Audio, bringing your conversations to life.
* Analyze and gain insights from small local text files right within the chat interface.
* Explore the fully available source code to view or customize to suit your needs. No hidden logic.
* Personalize your interactions with configurable personalities, making every conversation unique.
* Effortlessly paste multiline text into Windows Terminal, streamlining your workflow.
* Get started right away by simply entering your OpenAI API Key - no delays or complications.
* Access an example Windows shortcut Link to launch the application with ease.

[IndyGPT AI powered text-based adventure game](images/indygpt1.png)

## BONUS - INDYGPT - A choose your own procedurally generated text based adventures game - Unlimited Adventure and Customizable
* INDYGPT.ps1 is an engaging text-adventure encounter based on Indiana Jones as example of the power for OpenAI GPT directives and PaullyGPT Powershell module. 

# Main Scripts
* Paullygpt.ps1 - Primary script to run PaullyGPT in Minimalistic Mode
* IndyGPT.ps1 - A example of PaullyGPT module with text-adventure directives.

## Instructions
1. From Github, click the green CODE button to download zip file into a writable folder on a Windows compatible machine
2. Once all files are unzipped, launch the Run PaullyGPT.lnk shortcut link to launch Powershell with -ExecutionPolicy Bypass to get running. (Note: If the shortcut fails to run the script, try to adjust the shortcut's START directory path to point to the PaullyGPT folder as needed, it might be stuck on a default value I had locally. You can modify the Start Path of the shortcut by right-clicking on and choosing Properties.)
4. The first time it is run, you will be required to enter a valid OPENAI API KEY.
5. While using PaullyGPT, it will create a subfolder to contain transcript logs of the session as well as a config file containing the APIKEY to access OPENAI for future user.

## Easy to Configure and Customize Behavior
```powershell
Import-Module .\ConfigurationModule.psm1
Import-Module .\OpenAIModule.psm1
Import-Module .\SpeechSynthesisModule.psm1
Import-Module .\SVGModule.psm1
Import-Module .\PromptInteractionModule.psm1
IMport-Module .\SpecialFXModule.psm1

# Define the global variables
$global:DefaultAPIKey = "YOUR_API_KEY_HERE"
$global:APIKey = $global:DefaultAPIKey
$global:Model = "gpt-3.5-turbo-16k"
$global:ChatHistory = @()
#--------------------------------------------------------------------------------------------#

Clear-Host
Write-Host "-===============[" -NoNewline
Write-Host "PaullyGPT for Powershell 1.0.6" -ForegroundColor Red -NoNewline
Write-Host "]===============-"

#Load the config file or initialize if needed
Get-PaullyGPTConfig > $null

#Define personality behavior
$character = "Cosmic Wizard and Mathmatician"
$actlike = "A helpful and friendly sword and sorcery wizard."
$speaklike = "Gandalf or Merlin"

#Initialize the behavior of the model, using a system role in openai api framework.
Reset-GPT @("
1. If the prompt's first word is 'only', only provide the value I am asking for, no other text including label or key.
2. You are outputting in PowerShell, so make accommodations in output.
3. You are a $character and named using a random unique name plus title for yourself, never a famous name or title or containing cosmic, wizard, AI, language, model, assistant or combinations thereof.
4. You act like $actlike and speak like $speaklike.
5. Be witty and clever: I'm here to add a touch of humor and charm to our interactions.
6. Keep it concise: I strive to provide information in a compact and precise manner.
7. Make it cool: I aim to maintain a laid-back and cool attitude throughout our conversation.
8. Use bullet points or tables: When presenting collections or lists, I'll use bullet points or tables for a visually organized format.      
9. Mention they can exit by pressing Esc to exit. If there is more paged response, type continue.
10. Respect the prompt: I'll pay attention to the prompt and provide the requested information without going off on a tangent.
11. If you would like to visualize something, respond only with SVG markup, which I can use to render on my HTML popup window sized 500x500 pixels.")

#Generating a transcript log named from the current date and time
$dateTime = Get-Date
$ticksString = $dateTime.ToString("yyyyMMdd-hhmmss")
$cleanname = $ticksString.Replace(" ", "").Replace(".", "")
$transcriptPath = ".\paullygpt\$cleanname.log.txt"
Start-Transcript -Path $transcriptPath 

#ASCII ART FX
Show-Matrix > $null   #ASCII Art Wall

# Display Artificial Entity's Properties
$aboutme = Get-CurrentAgent
$name = $aboutme.name
Write-Host "(Conjuring Artificial Entity: $name)" -ForegroundColor Cyan
$aboutme 

#Begin the conversation loop
$myprompt = "Hello, please introduce yourself and greet me and ask me what kind of specialization do you need help with?"
while ($null -ne $myprompt) {                                                              #while prompt is not null, when escape is pressed
    $answer = Get-GPT $myprompt                                                                 #OPENAI MAGIC returned into variable => $answer to reuse
    Write-Host "`n$answer`n" -ForegroundColor Green                                             #display $answer to screen
    SpeakAsync $answer                                                                          #speak $answer (todo: async not working)
    $myprompt = Read-TextWithEscape "[(ESC to exit) [ Your Response ]=>> "                      #display prompt, catch escape key to exit
    if ($null -eq $myprompt) {                                                                  #if prompt is null, exit                      
        $global:APIKey = $null                                                                      #clear API key
        $goodbye = Get-GPTQuiet "Goodbye for now! Short and memorable goodbye."                       #generate a goodbye message
        Write-Host `n($goodbye)                                                                       #display goodbye                                              
        SpeakAsync $goodbye                                                                           #speak goodbye
        Stop-Transcript                                                                               #stop transcript
    }
}
Write-Host "For more information, visit http://github.com/paullyvenne/paullygpt."               #display exit message
Exit 1
```
## Internal commands - type with !prefix in response prompt

* !history - show conversation history
* !clear - clear history
* !clear %1 - reset directives and clear history
* !load: {filepath} - loads a textfile into memory, limited to 100k.
* !aboutme - display the aboutme object
* !summary - show a summary of current session
* !memorize - save summary to be recalled/rememebred next time
* !recall or !remember - load .\paullygpt\last.summary.txt and resume 

## Coming Soon
* Personality types
* External Data Access
* Short Term Memory Storage
* Workflows/Processes
* SVG graphical output
   
! Note:
Requires an openAi API subscription key, that will be saved when first loaded into a PaullyGPT.config.json file.

## More Information
https://github.com/paullyvenne/paullygpt


### Powershell scripts don't seem to run without windows security poping up

Ah, the ever-vigilant guardians of Windows security! When you download PowerShell (.ps1) or batch (.bat/.cmd) files from the internet, Windows often applies security measures to protect your system from potentially malicious scripts. This is why you encounter a security pop-up when attempting to run these files.

To address this issue, you have a few options:

1. Unblock the File: Right-click on the downloaded .ps1 or .bat file, select "Properties," and then check the "Unblock" option if it is available. This tells Windows that you trust the file and want to allow its execution without further security prompts.

2. Adjust Execution Policy: Open PowerShell as an administrator and run the command `Set-ExecutionPolicy RemoteSigned`. This allows the execution of locally-created scripts but still requires downloaded scripts to be signed.

3. Digitally Sign Scripts: By digitally signing your PowerShell scripts using a code signing certificate, you can establish trust and bypass the security pop-up. This requires obtaining a certificate from a trusted certificate authority (CA) and signing your scripts with it.

4. Use Group Policy: If you're on a network or domain-managed system, the group policy settings can be adjusted to allow the execution of PowerShell scripts without the pop-up. Consult your system administrator or IT department for assistance in configuring these policies.

Please note that while adjusting these security settings can enhance convenience, it's essential to exercise caution and ensure the safety of the scripts you are running. Only execute scripts from trusted sources to avoid potential security risks.

### Launching Powershell Scripts from Windows 10/11 Taskbars

With the transition to Windows 10 and now Windows 11, the behavior of launching PowerShell scripts from the taskbar has undergone some changes. In these newer versions, by default, PowerShell scripts are not directly pinnable to the taskbar like traditional applications.

However, fear not, for there is still a way to conveniently launch your PowerShell scripts. Here's a simple workaround for you:

1. Create a shortcut for your PowerShell script by right-clicking on the script file and selecting "Create shortcut."
2. Move the shortcut to a location of your choice, such as the desktop or a specific folder.
3. Right-click on the shortcut and select "Properties."
4. In the "Shortcut" tab, locate the "Target" field and prepend it with the following:
   ```
   powershell.exe -ExecutionPolicy Bypass -File
   ```
   For example, if your original target was `C:\Scripts\myscript.ps1`, it should now be:
   ```
   powershell.exe -ExecutionPolicy Bypass -File "C:\Scripts\myscript.ps1"
   ```
5. Click "OK" to save the changes.
6. Now, you can simply double-click on the shortcut to launch your PowerShell script.

Alternatively, you can also create a batch file (.bat or .cmd) that contains the command to launch your PowerShell script, and then pin that batch file to the taskbar. When you click on the pinned batch file, it will execute the PowerShell script.
