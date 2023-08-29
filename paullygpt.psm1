Import-Module .\ConfigurationModule.psm1
Import-Module .\OpenAIModule.psm1
Import-Module .\SpeechSynthesisModule.psm1
Import-Module .\SVGModule.psm1
Import-Module .\PromptInteractionModule.psm1
Import-Module .\SpecialFXModule.psm1
# Import-Module .\StorageAccountModule.psm1
# Import-Module .\UIModule.psm1
# Import the HTML Agility Pack module
# Import-Module -Name HtmlAgilityPack

$global:version = "1.0.10"
$global:DEBUG = $false

# Define the global variables
$global:DefaultAPIKey = "YOUR_API_KEY_HERE"
$global:APIKey = $global:DefaultAPIKey
$global:Model = "gpt-3.5-turbo-16k" #"gpt-4"
$global:ChatHistory = @()
$global:fileSizeLimit = 100 #kb

$dateTime = Get-Date
$timestamp = $dateTime.ToString()
$dayOfWeek = $dateTime.DayOfWeek

$transcriptPath = ".\paullygpt\transcript.log.txt"
$transcriptPath2 = ".\paullygpt\transcript.summary.txt"

# Define the global functions
#-------------------------------------------------------
# Function: Invoke-PaullyGPT
#-------------------------------------------------------
function Invoke_PaullyGPT_V1 {
    param(
        [bool] $resumeLastSession = $false,
        [string]$firstPrompt = "Say hello, mention it's $timestamp, the day of the week is $dayOfWeek, please briefly introduce yourself, ask name, ask what areas 'do you need help with?', and follow with one empty lines and share an insightful quote based on your character. ",
        [string]$directives = "
    Follow these directives:
        1. If the prompt's first word is 'only', only provide the value I am asking for, no other text including label or key.
        2. You are outputting in PowerShell, so make accommodations in output for a terminal width of $width characters.
        3. You are a $character and named using a random unique name that begins with $nameBeginsWith plus title for yourself, never a famous name or title or containing cosmic, wizard, AI, language, model, assistant or combinations thereof.
        4. You act like $actlike and speak like $speaklike.
        5. Be witty and clever but truthful: I'm here to add a touch of humor and charm to our interactions.
        6. Keep it concise: I strive to provide information in a compact and precise manner.
        7. Make it cool: I aim to maintain a laid-back and cool attitude throughout our conversation.
        8. Use bullet points or tablular output for tables when presenting collections or lists.      
        9. Mention they can exit by pressing Esc to exit. If there is more paged response, type continue.
        10. Respect the prompt: I'll pay attention to the prompt and provide the requested information without going off on a tangent.
        11. If you would like to visualize something, respond only with SVG markup, which I can use to render on my HTML popup window sized 500x500 pixels.
        12. For internal commands, output in a codeblock.
        13. Keep track of our conversations in a json object with a message string array using more compact language.
        14. Update your json object with the properties about any information learned from our conversations.
        15. Please keep track of all topics and be ready with a summary at anytime with the latest topics and prompts."
        )

    # Display the hosting process information
    # Write-Host "PowerShell is hosted by process:"
    # $parentProcess | Select-Object ProcessName, Id, SessionId

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
    $width = $Host.UI.RawUI.WindowSize.Width

    #Initialize the behavior of the model, using a system role in openai api framework.
    #Feel free to tweak the heck out of this to get the behavior you want.
    Reset-GPT @($directives)

    $dateTime = Get-Date
    $ticksString = $dateTime.ToString("yyyyMMdd-hhmmss")
    $cleanname = $ticksString.Replace(" ", "").Replace(".", "")
    $transcriptPath = ".\paullygpt\$cleanname.log.txt"
    $transcriptPath2 = ".\paullygpt\$cleanname.summary.txt"
    Start-Transcript -Path $transcriptPath 

    if ($false -eq $global:DEBUG) {
        #Generating a transcript log named from the current date and time

        #Optional ASCII Art App Banner
        ShowMatrix > $null

        # Display Artificial Entity's Properties
        Write-Host " $spaces~~=(Conjuring Artificial Entity)=~~" -NoNewline -ForegroundColor Yellow 
        # [console]::beep(400, 500)
        # Start-Sleep -Milliseconds 100
        # [console]::beep(500, 500)
        # Start-Sleep -Milliseconds 20
        # [console]::beep(600, 500)
        # Start-Sleep -Milliseconds 40
        # [console]::beep(500, 500)
        # Start-Sleep -Milliseconds 80
        # [console]::beep(400, 500)
        # $aboutme = Get-CurrentAgent #Returns object
        # Write-Host $aboutme -ForegroundColor Cyan
    }
    else {
        $global:speechEnabled = $true
    }

    if($true -eq $resumeLastSession) {
        $myprompt = Recall_Last_Prompt 
    } else {
        $myprompt = $firstPrompt
    }
    




# foreach ($line in $starLines) {
#     $paddedLine = $line.PadRight($width)
#     Write-Host $paddedLine -ForegroundColor Blue
# }

    #Begin the conversation loop
    while ($null -ne $myprompt) {
        #Any commands begin with "!"

        if ($myprompt -like "exit") {
            $myprompt = $null
            shutDown
            break
        }

        if ($myprompt -like "!*" ) {
            $mycommand = [string]::new($myprompt).Substring(1, $myprompt.Length - 1).Trim()
            $myprompt = Invoke-PaullyGPTCommand -Command $mycommand
        }

        if ($null -ne $myprompt -and -not ($myprompt -like "`n*")) {
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
        #Write-Host "`n(•̀ᴗ•́)و " -ForegroundColor Yellow
        Write-Host "[(ESC to exit, CTRL-T to Mute, or type !help)]" -ForegroundColor DarkGray
        
        $myprompt = Read-TextWithEscape "[ Your Response ]=>> "
        if ($null -eq $myprompt) {
            #if prompt is null, exit                      
            shutDown
            break
        }
    }
    Write-Host "For more information, visit http://github.com/paullyvenne/paullygpt."               #display exit message
    Exit 1 #App exit code 1 = normal exit, 0 = error exit
}

function shutDown {
        $global:APIKey = $null                                                                      #clear API key
        #say goodbye
        $goodbye = Get-GPTQuiet "Goodbye for now and stay curious!"
        Write-Host `n($goodbye)
        #stop transcript and summarize 
        $summary = Save_Summary -Path $transcriptPath2
        if($true -eq $global:DEBUG) {
            Write-Host $summary -ForegroundColor Green
        }
        SpeakAsync $goodbye  
        Stop-Transcript
}

function Recall_Last_Prompt {
    Param()
    $lastPath = ".\paullygpt\last.summary.txt"
    if($true -eq (Test-Path $lastPath)) {
        $dateTime = Get-Date
        $file = Get-Item -Path $lastPath
        $lastWriteTime = $file.LastWriteTime
        $fileContents = Get-Content -Path $lastPath
        #resume last
        $global:ChatHistory += @(@{ role = "user"; content = "today is $dateTime and previously on $lastWriteTime the following was discussed: ``````$fileContents``````" })
        $prompt = "Welcome the user and if there was a previous session, resume our last conversation from $lastWriteTime by summarizing the notes but not after."
        return $prompt
    }
    $firstPrompt = "Welcome yourself and ask the user to begin a question."
    return $firstPrompt
}
function Summarize_Conversation {
    # $global:ChatHistory += @(@{ role = "user"; content = "" }) #filler?
    $summary = Get-GPT "Summarize our conversations into bullet points. Include any questions, notes, thoughts, banter, comments, or feedback that would be useful to resume our discussion for next time"
    return $summary
}

function Save_Summary {
    Param([string]$Path)
    $directory = ".\paullygpt\"
    $fileName = Split-Path -Path $Path -Leaf
    $fullPath = $directory + $fileName.Replace(".log.txt", ".summary.txt")
    $lastPath = $directory + "last.summary.txt"
    $summary = Summarize_Conversation 
    $summary | Out-File -FilePath $fullPath -Encoding UTF8
    $summary | Out-File -FilePath $lastPath -Encoding UTF8
    return $summary
}

#-------------------------------------------------------
# Invoke-PaullyGPTCommand
#-------------------------------------------------------
function Invoke-PaullyGPTCommand {
    param(
        [string]$Command   
    )

    $mycommand = $Command
    $myprompt = $null

    switch ($mycommand) {

        { $mycommand -like "help*" } { 
            Write-Host "Commands: !help, !aboutme, !history, !memorize, !recall, !clear, !exit" -ForegroundColor Green
            Write-Host "Coming Soon: !preview, !resumeconversation, !saveconversation, !savelastresponse, !savecode, !ls" -ForegroundColor Green
            break 
        }

        # { $mycommand -like "ls*" } { break }
        # { $mycommand -like "savecode:*" } { break }
        # { $mycommand -like "saveconversation:*" } { break }
        # { $mycommand -like "resumeconversation:*" } { break }
        # { $mycommand -like "preview:*" } { break }

        { $mycommand -like "aboutme*" } {
            if ($null -eq $aboutme) { $aboutme = Get-CurrentAgent }
            Write-Host $aboutme -ForegroundColor Cyan
        }
        { $mycommand -like "history*" } {
            if ($global:ChatHistory.Count -gt 0) {
                foreach ($message in $global:ChatHistory) {
                    # Only show the role and content
                    $roleName = $message.Role
                    $content = $message.Content
                    Write-Host "{$roleName}: $content" -ForegroundColor Green
                }
            }
            else {
                "No Conversation."
            }
            break
        }
        { $mycommand -like "summarize*" -or $mycommand -like "summary*"} { 
            #Save memory
            $summary = Summarize_Conversation
            Write-Host $summary -ForegroundColor Green
            break }

        { $mycommand -like "memorize*" } { 
            #Save memory
            $summary = Save_Summary -Path $transcriptPath2
            Write-Host $summary -ForegroundColor Green
            break }

        { $mycommand -like "recall*"} { 
            #restore memory
            $myprompt = Recall_Last_Prompt 
            break }

        { $mycommand -like "url:*" } {
            #Experimental for now
            $url = $mycommand -replace "url:", ""
            try {
                $response = Invoke-WebRequest -Uri $url
                if ($null -ne $response -and $null -ne $response.Content) {

                    $urlContents = ExtractHtmlInnerText -htmlText $response.Content
                    
                    $size = ($urlContents).Length / 1KB  #
                    if ($size -gt $global:fileSizeLimit) {
                        Write-Host "The file size is larger than limit: $global:fileSizeLimit kb."
                    }
                    else {
                        if($null -ne $urlContents -and $urlContents.Length -gt 0) {
                            $analysis = LearnFromSourceGPT -Source $url -Contents $urlContents -analyzeContents $true
                            SpeakAsync $analysis
                        }
                    }
                }
            }
            catch {
                Write-Host "Error: Failed to retrieve web page content for $url. $_" -ForegroundColor Red
                $global:ChatHistory = @($global:ChatHistory | Select-Object -SkipLast 1)
            }
            break
        }
        { $mycommand -like "load:*" } {
            $param = ($mycommand -replace "load:", "").Trim()
            try {
                if (Test-Path $param) {
                    $content = Get-Content -Path $param -TotalCount 1
                    $size = (Get-Item $param).Length / 1KB  #
                    if ($size -gt $global:fileSizeLimit) {
                        Write-Host "The file size is larger than limit: $global:fileSizeLimit kb."
                    }
                    else {
                        if ($content -match "[^\x20-\x7E]") {
                            Write-Host "Cannot load binary files." -ForegroundColor Red
                        }
                        else {
                            Write-Host "Loading File...$param" -ForegroundColor Green
                            $fileContents = (Get-Content $param) | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
                            $analysis = LearnFromSourceGPT -Source $param -Contents $fileContents -analyzeContents $true
                            SpeakAsync $analysis
                        }
                    } 
                }
            }
            catch {
                Write-Host "Error: Failed to retrieve file content for $param. $_" -ForegroundColor Red
                $global:ChatHistory = @($global:ChatHistory | Select-Object -SkipLast 1)
            }
            break
        }
        { $mycommand -like "clear*" -or $mycommand -like "reset*" } {
            if($mycommand -like "clear*") {
                $directive = ($mycommand -replace "clear", "").Trim()
            }
            if($mycommand -like "reset*") {
                $directive = ($mycommand -replace "reset", "").Trim()
            }
            if ($false -eq [string]::IsNullOrEmpty($directive)) {
                $confirmation = Read-Host "Are you sure you want to clear history and reset directives? (Y/N)"
                if ($confirmation -eq "Y") {
                    $global:ChatHistory = @(@{ role = "system"; content = $directive })
                    Write-Host "Reset to: `n$directive" -ForegroundColor Green
                }
            }
            else {
                $confirmation = Read-Host "Are you sure you want to clear history? (Y/N)"
                if ($confirmation -eq "Y") {
                    if ($global:ChatHistory.Length -gt 0) {
                        $global:ChatHistory = @($global:ChatHistory | Select-Object -First 1)
                        Write-Host "Cleared!" -ForegroundColor Green
                    }
                }
            }
            break
        }
        { $mycommand -like "exit*" } {
            $myprompt = $null
            break
        }
        
    }
    return $myprompt
}

$global:dataSources = @{}

function LearnFromSourceGPT {
    param(
        [string]$source, 
        [string]$contents,
        [bool]$analyzeContents = $true)

    if ($true -eq [string]::isNullOrEmpty($source)) {
        throw "Source is required."
    }

    if ($true -eq [string]::isNullOrEmpty($contents)) {
        throw "Contents is required."
    }

    $backup = $global:ChatHistory.Clone()
    $hash = [Guid]::NewGuid().ToString()
        
    #q: not used yet?

    $dataSources[$hash] = $source.Trim()

    $encoded_contents = $contents | ConvertTo-Json

    # $global:ChatHistory += @{
    #     role    = "user"
    #     content = 
    # }

    $startTime = Get-Date
    Write-Host "Analyzing..." -ForegroundColor Green
    $analysis = Get-GPT "Give me an analysis this text labeled $hash : ``````$encoded_contents``````"
    if($null -ne $analysis) {
        $finishTime = Get-Date
        $totalSeconds = [Math]::Round(($finishTime).Subtract($startTime).TotalSeconds, 1)
        Write-Host "$totalSeconds seconds." -ForegroundColor Cyan                                                               #OPENAI MAGIC returned into variable => $answer to reuse
        Write-Host "`n$analysis`n" -ForegroundColor Blue
        # $backup += @{
        #     role    = "assistant"
        #     content = $analysis
        # }
    }
    # $global:ChatHistory = $backup
    return $analysis
}

function ExtractHtmlInnerText {
    param (
        [string] $htmlText
    )
    $html = New-Object -ComObject "HTMLFile"
    $rawbytes = [System.Text.Encoding]::UTF8.GetBytes($htmlText)
    $html.write($rawbytes)
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($html.body.innerText)
    $filteredBytes = $bytes | Where-Object { $_ -lt 128 -or $_ -ge 192 }
    $utf8String = [System.Text.Encoding]::UTF8.GetString($filteredBytes)
    return $utf8String
}