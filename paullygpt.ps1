Import-Module .\ConfigurationModule.psm1
Import-Module .\OpenAIModule.psm1
Import-Module .\SpeechSynthesisModule.psm1
Import-Module .\SVGModule.psm1
Import-Module .\PromptInteractionModule.psm1
Import-Module .\SpecialFXModule.psm1
# Import-Module .\StorageAccountModule.psm1

$enterMode = $true



$global:DEBUG = $false

# Define the global variables
$global:DefaultAPIKey = "YOUR_API_KEY_HERE"
$global:APIKey = $global:DefaultAPIKey
$global:Model = "gpt-3.5-turbo-16k"
$global:ChatHistory = @()
#--------------------------------------------------------------------------------------------#

$ratio = 4.2
$spaces = (" " * ($Host.UI.RawUI.WindowSize.Width / $ratio))

#Clear-Host
Write-Host "$spaces-===============[" -NoNewline
Write-Host "PaullyGPT for Powershell 1.0.7" -ForegroundColor Red -NoNewline
Write-Host "]===============-"


#Load the config file or initialize if needed
Get-PaullyGPTConfig > $null

#Define personality behavior
#-------------------------------------------------------
$character = "Cosmic Wizard and Programmer, Mathmatician, Scientist, Explorer, and Philosopher"
$actlike = "A helpful and friendly sword and sorcery wizard."
$speaklike = "Gandalf or Merlin"
#-------------------------------------------------------
# $character = "An excitedly helpful pirate and explorer"
# $actlike = "A helpful and friendly pirate"
# $speaklike = "Disney's 1964 Long John Silver"
#-------------------------------------------------------
# $character = "an investigator, thinker, and strategist"
# $actlike = "A helpful and friendly detective like Sherlock Holmes"
# $speaklike = "Sherlock Holmes"
#-------------------------------------------------------

$nameBeginsWith = [char](Get-Random -Minimum 97 -Maximum 123)

#Initialize the behavior of the model, using a system role in openai api framework.
Reset-GPT @("
1. If the prompt's first word is 'only', only provide the value I am asking for, no other text including label or key.
2. You are outputting in PowerShell, so make accommodations in output.
3. You are a $character and named using a random unique name that begins with $nameBeginsWith plus title for yourself, never a famous name or title or containing cosmic, wizard, AI, language, model, assistant or combinations thereof.
4. You act like $actlike and speak like $speaklike.
5. Be witty and clever but truthful: I'm here to add a touch of humor and charm to our interactions.
6. Keep it concise: I strive to provide information in a compact and precise manner.
7. Make it cool: I aim to maintain a laid-back and cool attitude throughout our conversation.
8. Use bullet points or tables: When presenting collections or lists, I'll use bullet points or tables for a visually organized format.      
9. Mention they can exit by pressing Esc to exit. If there is more paged response, type continue.
10. Respect the prompt: I'll pay attention to the prompt and provide the requested information without going off on a tangent.
11. If you would like to visualize something, respond only with SVG markup, which I can use to render on my HTML popup window sized 500x500 pixels.
12. For internal commands, output in a codeblock"
)

if($false -eq $global:DEBUG) {
    #Generating a transcript log named from the current date and time
    $dateTime = Get-Date
    $ticksString = $dateTime.ToString("yyyyMMdd-hhmmss")
    $cleanname = $ticksString.Replace(" ", "").Replace(".", "")
    $transcriptPath = ".\paullygpt\$cleanname.log.txt"
    Start-Transcript -Path $transcriptPath 

    ShowMatrix > $null

    # Display Artificial Entity's Properties
    $aboutme = Get-CurrentAgent
    $name = $aboutme.name
    Write-Host " $spaces~~=(Conjuring Artificial Entity: $name)=~~" -ForegroundColor Cyan
    $aboutme 
} else {
    $global:speechEnabled = $false
}

#Begin the conversation loop
$myprompt = "Hello, please briefly introduce yourself and ask my name and greet me and ask me what kind of specialization do you need help with?"
while ($null -ne $myprompt) {
    # if($myprompt -like 'command:*' ) {
    #     $commandResult = Get-GPTQuiet $myprompt
    #     $answer = $commandResult
    #     Write-Host "`n$answer`n" -ForegroundColor Cyan
    # } else {
    # if ($true) {
        #while prompt is not null, when escape is pressed
        $answer = Get-GPT $myprompt                                                                 #OPENAI MAGIC returned into variable => $answer to reuse
        Write-Host "`n$answer`n" -ForegroundColor Green
        # Write-Storage -Message $answer
        SpeakAsync $answer
    # }
    
    Write-Host "[(ESC to exit, CTRL-T to Mute)]" -ForegroundColor DarkGray
    $myprompt = Read-TextWithEscape "[ Your Response ]=>> "                      #display prompt, catch escape key to exit
    if ($null -eq $myprompt) {                                                                  #if prompt is null, exit                      
        $global:APIKey = $null                                                                      #clear API key
        $goodbye = Get-GPTQuiet "Goodbye for now! Short and memorable goodbye."                        #generate a goodbye message
        Write-Host `n($goodbye)                                                                       #display goodbye                                              
        SpeakAsync $goodbye    
        if($false -eq $global:DEBUG) {                                                                       #speak goodbye
            Stop-Transcript
        }                                                                #stop transcript
    } else {
        # Write-Storage -Message $myprompt
    }
}
Write-Host "For more information, visit http://github.com/paullyvenne/paullygpt."               #display exit message
Exit 1

