Import-Module .\Modules\ConfigurationModule.psm1
Import-Module .\Modules\OpenAIModule.psm1
Import-Module .\Modules\SpeechSynthesisModule.psm1
Import-Module .\Modules\SVGModule.psm1
Import-Module .\Modules\PromptInteractionModule.psm1
Import-Module .\Modules\SpecialFXModule.psm1
# Import-Module .\StorageAccountModule.psm1
# Import-Module .\UIModule.psm1
# Import the HTML Agility Pack module
# Import-Module -Name HtmlAgilityPack

$global:version = "1.0.17"
$global:DEBUG = $false

# Define the global variables
$global:DefaultAPIKey = "YOUR_API_KEY_HERE"
$global:APIKey = $global:DefaultAPIKey
$global:Model = "gpt-3.5-turbo-16k" #"gpt-4"
$global:ChatHistory = @()
$global:fileSizeLimit = 76 #kb
$global:DefaultDataFolder = ".\paullygpt\"

$dateTime = Get-Date
$timestamp = $dateTime.ToString()
$dayOfWeek = $dateTime.DayOfWeek

#$shutDownRegistered = $false

$transcriptPath = ".\paullygpt\transcript.log.txt"
$transcriptPath2 = ".\paullygpt\transcript.summary.txt"
$transcriptPath3 = ".\paullygpt\transcript.json"

function Yo_Paully {
    Param(
        [Parameter(Mandatory = $true)]
        [string]$Prompt,
        [string]$Directives = "You are running inside of a Powershell script commandline named Yo_Paully, like your Boss Paully, keep commentary to a minimal but colorful.",
        [bool]$Resume = $true,
        [int]$MaxTokens = 700,
        [float]$Temperature = 0.8,
        [string]$SessionFile = "last.json"
    )

    $global:MaxTokens = $MaxTokens
    $global:Temperature = $Temperature
    
    return Invoke_PaullyGPT_V1 -Directives $Directives -FirstPrompt $Prompt -ResumeLastSession $Resume -SaveLastSession $Resume -SessionFile $SessionFile -IsCLI $true -MaxTokens $MaxTokens
}

# Define the global functions
#-------------------------------------------------------
# Function: Invoke-PaullyGPT
#-------------------------------------------------------
function Invoke_PaullyGPT_V1 {
    Param(
        [bool]$IsCLI = $false,
        [bool]$ResumeLastSession = $false,
        [bool]$SaveLastSession = $false,
        [string]$SessionFile = "last.json",
        [string]$FirstPrompt = "Say hello, mention it's $timestamp, the day of the week is $dayOfWeek, please briefly introduce yourself, ask name, ask what areas 'do you need help with?', and follow with one empty lines and share an insightful quote based on your character. ",
        [string]$Directives = ",
        [int]$MaxTokens = 700,

        $global:MaxTokens = $MaxTokens
        
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


    if ($IsCLI -ne $true) {
        #Clear-Host
        Write-Host "$spaces-===============[" -NoNewline
        Write-Host "PaullyGPT for Powershell $global:version" -ForegroundColor Red -NoNewline
        Write-Host "]===============-"
    }

    #Load the config file or initialize if needed
    Get-PaullyGPTConfig | Out-Null

    #Launch-HTTPListener -Port 8080 -Verbose:$false
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
    Reset-GPT $Directives

    $dateTime = Get-Date
    $ticksString = $dateTime.ToString("yyyyMMdd-hhmmss")
    $cleanname = $ticksString.Replace(" ", "").Replace(".", "")
    $transcriptPath = ".\paullygpt\$cleanname.log.txt"
    $transcriptPath2 = ".\paullygpt\$cleanname.summary.txt"
    $transcriptPath3 = ".\paullygpt\$cleanname.json"
    
    # Start-Transcript -Path $transcriptPath -NoClobber
    # Write-Host "Notice: Summary of last conversations only works if you exit normally or use the !memorize command."

    if ($IsCLI -eq $false -and $global:DEBUG -eq $false) {
        #Generating a transcript log named from the current date and time

        #Optional ASCII Art App Banner
        ShowMatrix > $null

        # Display Artificial Entity's Properties
        Write-Host " $spaces~~=(Conjuring Artificial Entity)=~~" -NoNewline -ForegroundColor Yellow 
    }
        else {
        $global:speechEnabled = ($IsCLI -eq $false)
    }

    if ($true -eq $ResumeLastSession) {

        if($IsCLI -eq $true) {
            if($FirstPrompt -like "!recall:*") {
                $SessionFile = ($FirstPrompt -replace "!recall:", "").Trim()
            }
            Recall_Conversation_History -SessionFile $SessionFile  -DefaultPrompt $FirstPrompt -IsCLI $IsCLI | Out-Null
            $myprompt = $FirstPrompt
        } else {
            $myprompt = Recall_Conversation_History -SessionFile $SessionFile  -DefaultPrompt $FirstPrompt -IsCLI $IsCLI 
        }
    }
    else {
        $myprompt = $FirstPrompt
    }
    


    # foreach ($line in $starLines) {
    #     $paddedLine = $line.PadRight($width)
    #     Write-Host $paddedLine -ForegroundColor Blue
    # }

    #Begin the conversation loop
    while ($null -ne $myprompt) {
        #Any commands begin with "!"

        if ($myprompt -like "!exit" -or $myprompt -like "exit" -or $myprompt -like "quit" -or $myprompt -like "bye" -or $myprompt -like "goodbye") {
            $myprompt = $null
            shutDown
            break
        }

        if ($myprompt -like "!*" ) {
            $mycommand = [string]::new($myprompt).Substring(1, $myprompt.Length - 1).Trim()
            Write-Host "`n" -NoNewline
            $myprompt = Invoke-PaullyGPTCommand -Command $mycommand -Directives $Directives -IsCLI $IsCLI -SaveLastSession $SaveLastSession 
            if($myprompt.Length -gt 0 -and $myprompt[0] -eq $null) {
                $myprompt = $null
            }
        }

        #(!$myprompt.StartsWith("!")) -and 
        
        if ($IsCLI -eq $true) {
            
            if ($null -ne $myprompt) {
                $answer = Get-GPT $myprompt  
                
                if ($SaveLastSession -eq $true) {
                    $directory = ".\paullygpt\"
                    $lastPathJson = $directory + $SessionFile
                    $global:ChatHistory | ConvertTo-Json -Depth 5 -Compress | Out-File -FilePath $transcriptPath3 -Encoding UTF8 -Force
                    $global:ChatHistory | ConvertTo-Json -Depth 5 -Compress | Out-File -FilePath $lastPathJson -Encoding UTF8 -Force
                }

            }
            else {
                $answer = $global:ChatHistory[$global:ChatHistory.Count - 1].Content
            }
            return $answer
        }
        else {
            if ((-not [string]::IsNullOrEmpty($myprompt)) -and (-not ($myprompt -like "`n*"))) {
                $startTime = Get-Date
                $answer = Get-GPT $myprompt  

                if (($true -eq $SaveLastSession) -and ($myprompt -ne $FirstPrompt)) {
                    $directory = ".\paullygpt\"
                    $lastPathJson = $directory + $SessionFile
                    $global:ChatHistory | ConvertTo-Json -Depth 5 -Compress | Out-File -FilePath $transcriptPath3 -Encoding UTF8 -Force
                    $global:ChatHistory | ConvertTo-Json -Depth 5 -Compress | Out-File -FilePath $lastPathJson -Encoding UTF8 -Force
                }

                $finishTime = Get-Date
                $totalSeconds = [Math]::Round(($finishTime).Subtract($startTime).TotalSeconds, 1)
                Write-Host " $totalSeconds seconds." -ForegroundColor Cyan                                                  #OPENAI MAGIC returned into variable => $answer to reuse
                Write-Host "`n$answer`n" -ForegroundColor Blue
                # Write-Storage -Message $answer
                SpeakAsync $answer
            }


            # if($false -eq $shutDownRegistered) {
            #     # Register the event handler for the Exit event
            #     $null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action $shutdown 
            #     $shutDownRegistered = $true
            # }

            #display prompt, catch escape key to exit
            #Write-Host "`n(•̀ᴗ•́)و " -ForegroundColor Yellow
            $tokenCount = Get_MessageTokenCount -Messages $global:ChatHistory
            $messageCount = $global:ChatHistory.Count
            Write-Host "[$tokenCount tokens / $messageCount messages]" -ForegroundColor DarkGray
            Write-Host "[(ESC to exit, CTRL-T to Mute, or type !help)]" -ForegroundColor Gray

            $myprompt = Read-TextWithEscape "[ Your Response ]=>> "
            if ($null -eq $myprompt) {
                #if prompt is null, exit                      
                shutDown
                break
            }
            else {
                Start-Transcript -Path $transcriptPath -Append | Out-Null
            }
        }
    }
    Write-Host "For more information, visit http://github.com/paullyvenne/paullygpt."               #display exit message
    Exit 1 #App exit code 1 = normal exit, 0 = error exit
}

# $shutdown = {
#     shutDown
# }

function shutDown {
    $global:APIKey = $null                                                                      #clear API key
    #say goodbye
    #Write-Host "Saving memories and shutting down..."
    #1
    #stop transcript and summarize 
    # $summary = Save_Summary -Path $transcriptPath2
    # if($true -eq $global:DEBUG) {
    #     Write-Host $summary -ForegroundColor Green
    # }
    if (($true -eq $SaveLastSession)) {
        $directory = ".\paullygpt\"
        $lastPathJson = $directory + $SessionFile
        $global:ChatHistory | ConvertTo-Json -Depth 5 -Compress | Out-File -FilePath $transcriptPath3 -Encoding UTF8 -Force
        $global:ChatHistory | ConvertTo-Json -Depth 5 -Compress | Out-File -FilePath $lastPathJson -Encoding UTF8 -Force
    }
    $goodbye = "Goodbye for now and stay curious!"
    Write-Host `n($goodbye)
    SpeakAsync $goodbye  
}

function Recall_Conversation_History {
    Param(
        [string]$SessionFile,
        [string]$DefaultPrompt,
        [bool]$IsCLI = $false    
    )

    $lastPath = ".\paullygpt\" + $SessionFile
    if ($true -eq (Test-Path $lastPath)) {
        $dateTime = Get-Date
        $file = Get-Item -Path $lastPath
        $lastWriteTime = $file.LastWriteTime
        $fileContents = Get-Content -Path $lastPath
        #resume last
        if ($null -ne $fileContents) {
            $newJson = $fileContents | ConvertFrom-Json 
            if ($newJson.Count -gt 0) {
                if ($newJson.Count -eq "1") {
                    $global:ChatHistory = @()
                    Append_Message -Role $newJson.Role -Prompt  $newJson.Content
                    return $newJson
                }
                else {

                    $global:ChatHistory = @()
                    for($i = 0; $i -lt $newJson.Count; $i++) {
                        $message = $newJson[$i]
                        $role = $message.Role
                        $content = $message.Content
                        if(!([string]::isNullOrEmpty($content))) {
                            Append_Message -Role $role -Prompt $content
                        }
                    }`
                    
                    $Prompt = $DefaultPrompt
                    if ($IsCLI -eq $false) {
                        $Prompt = "Welcome the user and introduce yourself, based on the memory, show a summary of discussed topics and ask the user to begin a question. Keep adding to the list of discussed topics"
                    }
                    return $Prompt
                }
            }
        }
    }
    return $DefaultPrompt
}

function Recall_Last_Prompt {
    Param()
    if ($true -eq $ResumeLastSession) {
        $lastPath = ".\paullygpt\last.summary.txt"
        if ($true -eq (Test-Path $lastPath)) {
            $dateTime = Get-Date
            $file = Get-Item -Path $lastPath
            $lastWriteTime = $file.LastWriteTime
            $fileContents = Get-Content -Path $lastPath
            #resume last
            if ($false -eq [string]::IsNullOrEmpty($fileContents)) {
                Append_Message -Role "assistant" -Prompt "today is $dateTime and previously on $lastWriteTime the following was discussed: ``````$fileContents``````"
                $prompt = "Welcome the user and introduce yourself, based on the memory, show a summary of discussed topics and ask the user to begin a question. Keep adding to the list of discussed topics"
                return $prompt
            }
        }
    }
    $FirstPrompt = "Welcome yourself and ask the user to begin a question."
    return $FirstPrompt
}

function Summarize_Conversation {
    $Prompt = "Summarize all topics discussed into bullet points to be reviewed and resume where you left off."
    $summary = Get-GPTAndForget $Prompt
    return $summary
}

function Save_Summary {
    Param([string]$Path,
        [string]$SessionFile = "last.json",
        [bool]$IsCLI = $false
    )
    $directory = ".\paullygpt\"
    $fileName = Split-Path -Path $Path -Leaf
    # $fullPath = $directory + $fileName.Replace(".log.txt", ".summary.txt")
    # $lastPath = $directory + "last.summary.txt"
    $lastPathJson = $directory + $SessionFile
    # $summary = Summarize_Conversation
    # $summary | Out-File -FilePath $fullPath -Encoding UTF8 -Force!me
    # $summary | Out-File -FilePath $lastPath -Encoding UTF8 -Force
    $global:ChatHistory | ConvertTo-Json -Depth 5 -Compress | Out-File -FilePath $lastPathJson -Encoding UTF8 -Force
    $summary = "Saved memories to $lastPathJson."
    if($IsCLI -eq $false) {
        Write-Host $summary -ForegroundColor Green
    }
    return $summary
}

#-------------------------------------------------------
# Invoke-PaullyGPTCommand
#-------------------------------------------------------
function Invoke-PaullyGPTCommand {
    Param(
        [string]$Directives,
        [string]$Command,
        [bool]$IsCLI = $false, 
        [bool]$SaveLastSession = $true  
    )

    $mycommand = $Command
    $myprompt = $null

    switch ($mycommand) {

        { $mycommand -like "help*" } { 
            Write-Host "Commands: !help, !aboutme, !history, !memorize[: optional file], !recall, !pop[: count], !remove[: index], !clear, !reset[: newdirective], !load[: filename], !qload[: filename], !exit" -ForegroundColor Green
            break 
        }

        # { $mycommand -like "ls*" } { break }
        # { $mycommand -like "savecode:*" } { break }
        # { $mycommand -like "saveconversation:*" } { break }
        # { $mycommand -like "resumeconversation:*" } { break }
        # { $mycommand -like "preview:*" } { break }

        { $mycommand -like "aboutme*" } {
            if ($null -eq $aboutme) { $aboutme = Get-CurrentAgent }
            if ($IsCLI -eq $true) {
                return $aboutme
            }
            Write-Host $aboutme -ForegroundColor Cyan
        }
        { $mycommand -like "history*" } {
            if ($global:ChatHistory.Count -gt 0) {
                $ss = ""
                foreach ($message in $global:ChatHistory) {
                    # Only show the role and content
                    $roleName = $message.Role
                    $content = $message.Content
                    $timestamp = $message.timestamp
                    $s = "{$timestamp} {$roleName}: $content"
                    $ss += $s
                    Write-Host $s -ForegroundColor Green
                }
                if ($IsCLI -eq $true) {
                    return $ss
                }
            }
            else {
                $s = "No Conversation."
                if ($IsCLI -eq $true) {
                    return $s
                }
                Write-Host  -ForegroundColor Green
            }
            break
        }
        { $mycommand -like "summarize*" -or $mycommand -like "summary*" } { 
            #Save memory
            if ($global:ChatHistory.Length -gt 1) {
                $analysis = Summarize_Conversation
                if ($IsCLI -eq $true) {
                    return $analysis
                }
                Write-Host $analysis -ForegroundColor Green
            }
            break 
        }

        { $mycommand -like "remove*" } {
            $indexToRemove = ($mycommand -replace "remove", "").Trim()
            #TODO: functionize
            $global:ChatHistory = $global:ChatHistory | Where-Object { $global:ChatHistory.IndexOf($_) -ne $indexToRemove }
            if ($IsCLI -eq $true) {
                #return "-1 Pop goes the weasel!"#
            }
            Write-Host "-1 Pop goes the weasel!" -ForegroundColor Green
        }

        { $mycommand -like "pop:*" } {
            $popCount = ($mycommand -replace "pop", "").Trim()
            if ($false -eq [string]::isNullOrEmpty($outfile)) {
                if ($outFile.StartsWith(":")) {
                    $popCount = $outFile.Substring(1, $outFile.Length - 1).Trim() #remove first :
                }
            }
            else {
                $popCount = 1
            }
            if ($global:ChatHistory.Length -gt 1) {
                $tokenCount = Get_MessageTokenCount -Messages $global:ChatHistory
                Write-Host $tokenCount -ForegroundColor Green

                Pop_Oldest -PopCount $popCount | Out-Null
                
                $tokenCount = Get_MessageTokenCount -Messages $global:ChatHistory
                Write-Host $tokenCount -ForegroundColor Green

                $directory = ".\paullygpt\"
                $lastPathJson = $directory + $supportFile
                try {
                    $global:ChatHistory | ConvertTo-Json -Depth 5 -Compress | Out-File -FilePath $transcriptPath3 -Encoding UTF8 -Force
                } Catch {}
                try {
                $global:ChatHistory | ConvertTo-Json -Depth 5 -Compress | Out-File -FilePath $lastPathJson -Encoding UTF8 -Force
                } Catch {}
                $msg = ""
                if ($global:ChatHistory.Count -gt 0) {
                    foreach ($message in $global:ChatHistory) {
                        # Only show the role and content
                        $roleName = $message.Role
                        $content = $message.Content
                        $timestamp = $message.timestamp
                        $msg = "{$timestamp} {$roleName}: $content" 
                    }
                }
                if ($IsCLI -eq $true) {
                    #return "-$popCount Pop goes the weasel!"
                }
                Write-Host "-$popCount Pop goes the weasel!" -ForegroundColor Green
                $myprompt = $null
            }
            break
        }

        { $mycommand -like "memorize*" } { 
            $outFile = ($mycommand -replace "memorize", "").Trim()
            if ($false -eq [string]::isNullOrEmpty($outfile)) {
                if ($outFile.StartsWith(":")) {
                    $outFile = $outFile.Substring(1, $outFile.Length - 1).Trim() #remove first :
                }
            }
            else {
                $outFile = $SessionFile
            }
            #Save memory
            $summary = Save_Summary -Path $transcriptPath2 -SessionFile $outFile -IsCLI $IsCLI
            if ($IsCLI -eq $true) {
                return $summary
            }
            $myprompt = $null
            break 
        }

        { $mycommand -like "recall*" } { 
            #restore memory
            $inFile = ($mycommand -replace "recall", "").Trim()
            if ($false -eq [string]::isNullOrEmpty($inFile)) {
                if ($inFile.StartsWith(":")) {
                    $inFile = $inFile.Substring(1, $inFile.Length - 1).Trim() #remove first :
                }
            }
            else {
                $inFile = $SessionFile
            }
            Recall_Conversation_History -SessionFile $inFile -IsCLI $IsCLI
            $myprompt = Summarize_Conversation
            break 
        }

        { $mycommand -like "url:*" } {
            #Experimental for now
            $url = ($mycommand -replace "url:", "").Trim()
            try {
                $response = Invoke-WebRequest -Uri $url
                if ($null -ne $response -and $null -ne $response.Content) {

                    $urlContents = ExtractHtmlInnerText -htmlText $response.Content
                    
                    $size = ($urlContents).Length / 1KB  #
                    if ($size -gt $global:fileSizeLimit) {
                        Write-Host "The file size is larger than limit: $global:fileSizeLimit kb."
                    }
                    else {
                        if ($null -ne $urlContents -and $urlContents.Length -gt 0) {
                            $analysis = LearnFromSourceGPT -Source $null -Contents $urlContents -analyzeContents $true -IsCLI $IsCLI
                            if ($IsCLI -eq $true) {
                                return $analysis
                            }
                            SpeakAsync $analysis
                        }
                    }
                }
            }
            catch {
                Write-Host "Error: Failed to retrieve web page content for $url. $_" -ForegroundColor Red
                Pop_History
            }
            break
        }

        { $mycommand -like "qload:*" } {
            $param = ($mycommand -replace "qload:", "").Trim()
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
                            if ($IsCLI -eq $false) {
                                Write-Host "Loading File...$param..." -ForegroundColor Green -NoNewline
                            }
                            $fileContents = (Get-Content $param) | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
                            Write-Host "Done." -ForegroundColor Green
                            #$analysis = LearnFromSourceGPT -Source $param -Contents $fileContents -analyzeContents $false -IsCLI $IsCLI
                            $encoded_contents = $fileContents | ConvertTo-Json
                            $hash = Get-SHA1Hash -String $encoded_contents
                            $analysis = "Remember snippet '$hash' from source '$param' contains : ``````$encoded_contents``````"
                            Append_Message -Role "assistant" -Prompt $analysis
                            if ($IsCLI -eq $true) {
                                return $analysis
                            }
                            $myprompt = $null
                        }
                    }
                }
            }
            catch {
                Write-Host "Error: Failed to retrieve file content for $param. $_" -ForegroundColor Red
                Pop_History
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
                            if ($IsCLI -eq $false) {
                                Write-Host "Loading File...$param..." -ForegroundColor Green -NoNewline
                            }
                            $fileContents = (Get-Content $param) | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
                            Write-Host "Done." -ForegroundColor Green
                            $analysis = LearnFromSourceGPT -Source $param -Contents $fileContents -analyzeContents $true -IsCLI $IsCLI
                            if ($IsCLI -eq $true) {
                                return $analysis
                            }
                            SpeakAsync $analysis
                        }
                    } 
                }
            }
            catch {
                Write-Host "Error: Failed to retrieve file content for $param. $_" -ForegroundColor Red
                Pop_History
            }
            break
        }
        
        { $mycommand -like "reset:*" } {
            if ($mycommand -like "reset:*") {
                $directive = ($mycommand -replace "reset", "").Trim()
            }
            $confirmation = "Y"
            if ($IsCLI -eq $false) {
                $confirmation = Read-Host "Are you sure you want to clear history and reset directives? (Y/N)"
            }
            if ($confirmation -eq "Y") {
                Reset-GPT $directive
                if ($IsCLI -eq $true) {
                    return ("Reset to: `n$directive")
                }
                Write-Host "Reset to: `n$directive" -ForegroundColor Green
            }
            $myprompt = $null
            break
        }

        { $mycommand -like "clear*" } {
            if ($mycommand -like "clear*") {
                $directive = ($mycommand -replace "clear", "").Trim()
            }
            $confirmation = "Y"
            if ($IsCLI -eq $false) {
                $confirmation = Read-Host "Are you sure you want to clear history? (Y/N)"
            }
            if ($confirmation -eq "Y") {
                if ($global:ChatHistory.Length -gt 0) {
                    $global:ChatHistory = @($global:ChatHistory[0])
                    if ($IsCLI -eq $true) {
                        #return "Cleared!"
                    }
                    Write-Host "Cleared!" -ForegroundColor Green
                }
            }
            $myprompt = $null
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
    Param(
        [string]$Contents,
        [string]$Source = $null, 
        [bool]$AnalyzeContents = $true,
        [bool]$IsCLI = $false
    )

    if ($true -eq [string]::isNullOrEmpty($Contents)) {
        throw "Contents is required."
    }

    $backup = $global:ChatHistory.Clone()
    
    $encoded_contents = $Contents | ConvertTo-Json
    $hash = Get-SHA1Hash -String $encoded_contents
    #q: not used yet?

    $target = "data with reference hash '$hash'"
    #if source declared otherwise ignore
    if($null -ne $Source) {
        $dataSources[$hash] = $Source.Trim()
        $target += "from source '$Source'"
    }

    if ($IsCLI -eq $false) {
        $startTime = Get-Date
        Write-Host "Analyzing..." -ForegroundColor Green
        $lastCount = $global:ChatHistory.Count
    }
    
    $analysis = Get-GPT "Without mentioning the reference hash, give me a compact detailed analysis of $target which contains : ``````$encoded_contents``````"
    if($analysis -ne $null) {
        $analysis = $analysis.Replace("data with reference hash '$hash'", "data")
    }
    
    if ($global:ChatHistory.Count -gt 0) {
        $filteredArray = $global:ChatHistory | Where-Object { $_.role -ne "user" -and !$_.content.StartsWith($hash) }
        $global:ChatHistory = $filteredArray
    }

    if ($null -ne $analysis -and $IsCLI -eq $false) {
        $finishTime = Get-Date
        $totalSeconds = [Math]::Round(($finishTime).Subtract($startTime).TotalSeconds, 1)
        Write-Host " $totalSeconds seconds." -ForegroundColor Cyan                                                               #OPENAI MAGIC returned into variable => $answer to reuse
        Write-Host "`n$analysis`n" -ForegroundColor Blue
        # $backup += @{
        #     role    = "assistant"
        #     content = $analysis
        # }
    }
    return $analysis
}

function ExtractHtmlInnerText {
    param (
        [string]$htmlText
    )
    $decodedHtml = [System.Net.WebUtility]::HtmlDecode($htmlText)
    $innerText = ($decodedHtml -split '<[^>]+>' | Where-Object { $_.Trim() -ne "" }) -join " "
    return $innerText
}

function Pop_History {
    Param(
        [int]$PopCount = 1
    )
    if ($global:ChatHistory.Count -eq 0) {
        return $null
    }
    $last = @($global:ChatHistory | Select-Object -Last 1)
    $global:ChatHistory = $global:ChatHistory[0..($global:ChatHistory.Length - ($PopCount + 1))]
    return $global:ChatHistory
}

function Pop_Oldest {
    Param(
        [int]$PopCount = 1
    )
    if ($global:ChatHistory.Count -eq 0) {
        return $null
    }
    $oldestMessage = $global:ChatHistory[0]
    #$first = $global:ChatHistory[1]
    $global:ChatHistory = @($oldestMessage) + ($global:ChatHistory | Select-Object -Skip ($PopCount + 1))
    return $global:ChatHistory
}


function Get-SHA1Hash {
    param (
        [Parameter(Mandatory=$true)]
        [string]$String
    )

    $bytes = [System.Text.Encoding]::UTF8.GetBytes($String)
    $sha1 = New-Object -TypeName System.Security.Cryptography.SHA1CryptoServiceProvider
    $sha1HashBytes = $sha1.ComputeHash($bytes)
    $sha1Hash = [System.BitConverter]::ToString($sha1HashBytes).Replace("-", "")

    return $sha1Hash
}