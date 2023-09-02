Import-Module .\ConfigurationModule.psm1
Import-Module .\OpenAIModule.psm1
Import-Module .\SpeechSynthesisModule.psm1
Import-Module .\SVGModule.psm1
Import-Module .\PromptInteractionModule.psm1
Import-Module .\SpecialFXModule.psm1
Import-Module .\PaullyGPT.psm1

$global:DEBUG = $false
$global:MaxTokens = 800    #conversation size limit
$global:Temperature = 0.4  #randomness
#q: what happens the higher the temperature?
$global:MaxCompletionLoop = 5
$global:MaxExceptionLoop = 5

$global:YOUDONTMIND_SOUND = $false
if($global:YOUDONTMIND_SOUND){ 
    PlayIntroMusic
}

$dateTime = Get-Date
$timestamp = $dateTime.ToString()
$dayOfWeek = $dateTime.DayOfWeek`

#MINIMALIST DIRECTIVE MODE
$firstPrompt = "Say hello, mention it's $timestamp, the day of the week is $dayOfWeek, please briefly introduce yourself, ask name, ask what areas 'do you need help with?', and follow with one empty lines and share an insightful quote based on your character."
$directives = "Be a helpful assistant and advisor running in a Powershell script coincidentally called PaullyGPT who can resume conversations with notes from previous sessions."
Invoke_PaullyGPT_V1 -Directives $directives -FirstPrompt $firstPrompt -ResumeLastSession $true -SaveLastSession $true

#Runs best with Visual Studio Code with Run command and Powershell extensions installed.
#Added some delays to allow for multiline pasting of text into the terminal. (e.g. Windows Terminal - Multiline Warnings)