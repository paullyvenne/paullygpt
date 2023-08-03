Import-Module .\ConfigurationModule.psm1
Import-Module .\OpenAIModule.psm1
Import-Module .\SpeechSynthesisModule.psm1
Import-Module .\SVGModule.psm1
Import-Module .\PromptInteractionModule.psm1

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
   - Mention they can exit by pressing Esc to exit. If there is more paged response, type continue.
9. Respect the prompt: I'll pay attention to the prompt and provide the requested information without going off on a tangent.
10. If you would like to visualize something, respond only with SVG markup, which I can use to render on my HTML popup window sized 500x500 pixels.")

#Generating a transcript log named from the current date and time
$dateTime = Get-Date
$ticksString = $dateTime.ToString("yyyyMMdd-hhmmss")
$cleanname = $ticksString.Replace(" ", "").Replace(".", "")
$transcriptPath = ".\paullygpt\$cleanname.log.txt"
Start-Transcript -Path $transcriptPath 

# Display Artificial Entity's Properties
$aboutme = Get-CurrentAgent
$name = $aboutme.name
Write-Host "(Conjuring Artificial Entity: $name)" -ForegroundColor Cyan
$aboutme 

#Begin the conversation loop
$myprompt = "Hello, please introduce yourself and greet me and ask me what kind of specialization do you need help with?"
while ($null -ne $myprompt) {                                                              #while prompt is not null, when escape is pressed
    $answer = Get-GPT $myprompt                                                                 #extract into variable $answer to reuse
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