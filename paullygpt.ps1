Import-Module .\ConfigurationModule.psm1
Import-Module .\OpenAIModule.psm1
Import-Module .\SpeechSynthesisModule.psm1
Import-Module .\SVGModule.psm1
Import-Module .\PromptInteractionModule.psm1
Import-Module .\SpecialFXModule.psm1
# Import-Module .\StorageAccountModule.psm1

$global:version = "1.0.8"
$global:DEBUG = $false


# Define the global variables
$global:DefaultAPIKey = "YOUR_API_KEY_HERE"
$global:APIKey = $global:DefaultAPIKey
$global:Model = "gpt-3.5-turbo-16k" #"gpt-4"
$global:ChatHistory = @()
#--------------------------------------------------------------------------------------------#

# Display the hosting process information
Write-Host "PowerShell is hosted by process:"
$parentProcess | Select-Object ProcessName, Id, SessionId

$ratio = 4.2
$spaces = (" " * ($Host.UI.RawUI.WindowSize.Width / $ratio))

#Clear-Host
Write-Host "$spaces-===============[" -NoNewline
Write-Host "PaullyGPT for Powershell $global:version" -ForegroundColor Red -NoNewline
Write-Host "]===============-"

#Load the config file or initialize if needed
Get-PaullyGPTConfig > $null

#PromptSettings
#PromptVoice
#PromptCharacter

#Define personality behavior
# $character = "advanced scientist"
# $actlike = "A helpful and friendly advisor"
# $speaklike = "Doc from 'Back to the Future'"
#-------------------------------------------------------
# $character = "Wise Zen Master, Programmer, Mathmatician, Scientist, Explorer, Philosopher, and more"
# $actlike = "A helpful and friendly advisor."
# $speaklike = "Sun Tzu or Confucious"
#-------------------------------------------------------
$character = "Cosmic Wizard and Programmer, Mathmatician, Scientist, Explorer, and Philosopher"
$actlike = "A helpful and friendly sword and sorcery wizard."
$speaklike = "Gandalf or Merlin"
#-------------------------------------------------------
# $character = "An excitedly helpful pirate and explorer"
# $actlike = "A helpful and friendly advisor"
# $speaklike = "Disney's 1964 Long John Silver"
#-------------------------------------------------------
# $character = "detective, investigator, thinker, and strategist"
# $actlike = "A helpful and friendly advisor"
# $speaklike = "Sherlock Holmes"
#-------------------------------------------------------

$nameBeginsWith = [char](Get-Random -Minimum 97 -Maximum 123)

#Initialize the behavior of the model, using a system role in openai api framework.
Reset-GPT @("
    Follow these directives:
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
        12. For internal commands, output in a codeblock.
        13. Keep track of our conversations in a json object with a message string array using more compact language.
        14. Update your json object with the properties about any information learned from our conversations."
)

if ($false -eq $global:DEBUG) {
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

    $dateTime = Get-Date
    $timestamp = $dateTime.ToString()
    $myprompt = "Say hello, mention it's $timestamp, please briefly introduce yourself, ask name, ask what areas 'do you need help with?', and follow with one empty lines and share an insightful quote based on your character."
}
else {
    $global:speechEnabled = $true
    $myprompt = "!aboutme"
}
#Begin the conversation loop
while ($null -ne $myprompt) {
    if ($myprompt -like "!*" ) {
        $mycommand = [string]::new($myprompt).Substring(1, $myprompt.Length - 1).Trim()
        $myprompt = $null
        switch ($mycommand) {
            { $mycommand -like "aboutme" } {
                $aboutme 
                break
            }
            { $mycommand -like "history" } {
                if($global:ChatHistory.Count -gt 0) {
                    foreach ($message in $global:ChatHistory) {
                        # Only show the role and content
                        $roleName = $message.Role
                        $content = $message.Content
                        Write-Host "{$roleName}: $content" -ForegroundColor Green
                    }
                } else {
                    "No Conversation."
                }
                break
            }
            { $mycommand -like "load:*" } {
                $param = ($mycommand -replace "load:", "").Trim()
                $param
                if (Test-Path $param) {
                    $content = Get-Content -Path $param -TotalCount 1
                    $size = (Get-Item $param).Length / 1KB  #
                    if ($size -gt 250) {
                        Write-Host "The file size is larger than 250kb."
                    } else {
                        if ($content -match "[^\x20-\x7E]") {
                            Write-Host "Cannot load binary files." -ForegroundColor Red
                        } else {
                            Write-Host "Loading File...$param" -ForegroundColor Green
                            $fileContents = (Get-Content $param) | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
                            $newMessage = @{
                                role    = "assistant"
                                content = "$param contents contains ````$fileContents````"
                            }
                            $global:ChatHistory += $newMessage 
                            Write-Host "Analyzing..." -ForegroundColor Green
                            $myprompt = "Give me a analysis of the contents of $param now."
                        }
                    } 
                }
                break
            }
            { $mycommand -like "save:*" } {
                $param = $mycommand -replace "save:", ""
                $param
                break
            }
            { $mycommand -like "clear" } {
                $confirmation = Read-Host "Are you sure you want to clear history? (Y/N)"
                if ($confirmation -eq "Y") {
                    if ($myArray.Count -gt 0) {
                        $global:ChatHistory = @($global:ChatHistory | Select-Object -First 1)
                    }
                    Write-Host "Cleared!" -ForegroundColor Green
                }
                break
            }
            { $mycommand -like "exit*" } {
                $myprompt = $null
                break
            }
        }

    }
    if($null -ne $myprompt) {
        $startTime = Get-Date
        $answer = Get-GPT $myprompt  
        $finishTime = Get-Date
        $totalSeconds = [Math]::Round(($finishTime).Subtract($startTime).TotalSeconds, 1)
        Write-Host "$totalSeconds seconds." -ForegroundColor Cyan                                                               #OPENAI MAGIC returned into variable => $answer to reuse
        Write-Host "`n$answer`n" -ForegroundColor Blue
        # Write-Storage -Message $answer
        SpeakAsync $answer
    }
    #display prompt, catch escape key to exit
    Write-Host "[(ESC to exit, CTRL-T to Mute)]" -ForegroundColor DarkGray
    $myprompt = Read-TextWithEscape "[ Your Response ]=>> "
    if ($null -eq $myprompt) {
        #if prompt is null, exit                      
        $global:APIKey = $null                                                                      #clear API key
        $goodbye = Get-GPTQuiet "Goodbye for now! Short and memorable goodbye."
        #generate a goodbye message
        Write-Host `n($goodbye)
        if ($true -eq $global:DEBUG) {  
            $aboutme = Get-GPTQuiet "show your json object"                                                                     #speak goodbye
            Write-Host `n($aboutme)                                                                     #display goodbye                                              
        }
        SpeakAsync $goodbye    
        if ($false -eq $global:DEBUG) {
            #speak goodbye
            Stop-Transcript
        }                                                                #stop transcript
    }
}
Write-Host "For more information, visit http://github.com/paullyvenne/paullygpt."               #display exit message
Exit 1

