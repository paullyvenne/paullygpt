Import-Module .\ConfigurationModule.psm1
Import-Module .\OpenAIModule.psm1
Import-Module .\SpeechSynthesisModule.psm1
Import-Module .\SVGModule.psm1
Import-Module .\PromptInteractionModule.psm1
Import-Module .\SpecialFXModule.psm1
Import-Module .\PaullyGPT.psm1

$global:DEBUG = $false

$global:YOUDONTMIND_SOUND = $true
if($global:YOUDONTMIND_SOUND){ 
    PlayIntroMusic
}

$dateTime = Get-Date
$timestamp = $dateTime.ToString()
$dayOfWeek = $dateTime.DayOfWeek

#MINIMALIST DIRECTIVE MODE
$firstPrompt = "Say hello, mention it's $timestamp, the day of the week is $dayOfWeek, please briefly introduce yourself, ask name, ask what areas 'do you need help with?', and follow with one empty lines and share an insightful quote based on your character."
$directives = "Be a helpful assistant and advisor who can resume conversations with notes from previous sessions."
Invoke_PaullyGPT_V1 -Directives $directives -FirstPrompt $firstPrompt -ResumeLastSession $true

#Runs best with Visual Studio Code with Run command and Powershell extensions installed.
#Added some delays to allow for multiline pasting of text into the terminal. (e.g. Windows Terminal - Multiline Warnings)