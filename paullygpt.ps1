Add-Type -AssemblyName System.Speech
Add-Type -AssemblyName System.Windows.Forms

# Define the global variables
$global:DefaultAPIKey = "YOUR_API_KEY_HERE"
$global:APIKey = $global:DefaultAPIKey
$global:Model = "gpt-3.5-turbo-16k"
$global:ChatHistory = @()
#--------------------------------------------------------------------------------------------#

function Read-Config {
    param (
        [string]$ConfigFilePath
    )

    if (Test-Path -Path $ConfigFilePath) {
        $configContent = Get-Content $ConfigFilePath | ConvertFrom-Json
    }
    else {
        $configContent = New-Object -TypeName PSObject -Property @{
            APIKey = $null
        }
    }

    return $configContent
}
function Get-PaullyGPTConfig {
    $PSScriptRoot = "."
    $configPath = Join-Path $PSScriptRoot "paullygpt\paullygpt.config.json"

    # Create the "paullygpt" folder if it doesn't exist
    $paullyGptFolderPath = Join-Path $PSScriptRoot "paullygpt"
    if (-not (Test-Path -Path $paullyGptFolderPath -PathType Container)) {
        New-Item -ItemType Directory -Path $paullyGptFolderPath -Force
    }

    $config = Read-Config -ConfigFilePath $configPath

    # If the API key is not valid or is the default, prompt the user to enter a new one.
    $apiKey = Get-ValidAPIKey -APIKey $config.APIKey
    if ($null -eq $apiKey) {
        Write-Host "Failed to get a valid API key. Exiting."
        Exit 1
    }

    # Check if the API key is still null or is the default after the above validation
    if ($null -eq $apiKey -or $apiKey -eq $global:DefaultAPIKey) {
        Write-Host "Invalid API key provided. Please update the OpenAI API key in the configuration file."
        Exit 1
    }

    # Update the global API key with the valid one
    $global:APIKey = $apiKey

    # Update the configuration with the new API key
    $config.APIKey = $apiKey
    $config | ConvertTo-Json -Depth 5 | Set-Content $configPath > $null

    return $config
}
function Write-Config {
    param (
        [string]$ConfigFilePath,
        [string]$APIKey
    )

    $config = Read-Config -ConfigFilePath $ConfigFilePath
    $config.APIKey = $APIKey

    $config | ConvertTo-Json -Depth 5 | Set-Content -Path $ConfigFilePath
}
function Send-OpenAICompletion {
    param (
        [string]$Prompt,
        [int]$MaxTokens = 500,
        [double]$Temperature = 0.8,
        [string]$APIKey
    )

    $global:ChatHistory += @{
        role    = "user"
        content = $Prompt
    }
    $body = @{
        model       = $global:Model
        messages    = $global:ChatHistory
        temperature = $Temperature
        max_tokens  = $MaxTokens
        n           = 1
        stop        = $null
    } | ConvertTo-Json -Depth 5 -Compress

    $headers = @{
        "Content-Type"  = "application/json"
        "Authorization" = "Bearer $APIKey"
    }

    $param = @{
        Uri     = "https://api.openai.com/v1/chat/completions"
        Headers = $headers
        Method  = "Post"
        Body    = $body
    }

    try {
        $response = Invoke-RestMethod @param
        if ($null -ne $response) {
            if ($null -ne $response.error) {
                throw [System.Exception]::new($response.error.message)
            }
            else {
                return $response.choices[0].message.content
            }
        }
        else {
            throw [System.Exception]::new("An unexpected error occurred. The response was null.")
        }
    }
    catch {
        Write-Host "An error occurred: $($_.Exception.Message)" -ForegroundColor Red
        Exit 1
    }
}
function Get-OpenAICompletion {
    param (
        [string]$Prompt,
        [int]$MaxTokens = 500,
        [double]$Temperature = 0.8
    )

    $configFilePath = ".\paullygpt\paullygpt.config.json"
    $config = Read-Config -ConfigFilePath $configFilePath

    $apiKey = Get-ValidAPIKey -APIKey $config.APIKey
    if (-not $apiKey) {
        Write-Host "Failed to get a valid API key. Exiting."
        Exit 1
    }

    $result = Send-OpenAICompletion -Prompt $Prompt -MaxTokens $MaxTokens -Temperature $Temperature -APIKey $apiKey
    return $result
}
function Reset-GPT {
    param(
        [string]$directive
    )
    $global:ChatHistory = @()
    $global:ChatHistory += @{ role = "system"; content = $directive }
}
function Get-GPTQuiet {
    param(
        [string]$prompt
    )

    $completion = Get-OpenAICompletion -Prompt $prompt
    $global:ChatHistory += @{ role = "assistant"; content = $completion }
    return $completion
}
function Get-GPT {
    param(
        [string]$prompt
    )

    $completion = (Get-GPTQuiet $prompt)
    return $completion  # Return only the completion response without the ChatHistory object
}
function Read-TextWithEscape {
    param (
        [string]$prompt
    )

    Write-Host $prompt -ForegroundColor Red -NoNewline
    $inputText = ""

    while ($true) {
        $key = [System.Console]::ReadKey($true)  # Read a key, with no echo to the console
        $char = $key.KeyChar

        if ($key.Key -eq "Escape") {
            Write-Host ""
            $confirmation = Read-Host "Do you want to exit? (Y/N)"
            if ($confirmation -eq "Y" -or $confirmation -eq "y") {
                return $null
            }
            else {
                Write-Host $prompt -ForegroundColor Red -NoNewline
            }
        }
        elseif ($key.Key -eq "Enter") {
            Write-Host ""  # Move to the next line after pressing Enter
            break
        }
        elseif ($key.Key -eq "Backspace") {
            # Remove the last character from the inputText when the Backspace key is pressed
            if ($inputText.Length -gt 0) {
                $inputText = $inputText.Substring(0, $inputText.Length - 1)
                Write-Host -NoNewline "`b `b"  # Move the cursor back and erase the character on the screen
            }
        }
        elseif (($key.Modifiers -band [System.ConsoleModifiers]::Control) -and ($key.Key -eq "V")) {
            # Handle Ctrl+V (paste) by retrieving text from the clipboard
            $pastedText = [System.Windows.Forms.Clipboard]::GetText()
            if ($null -ne $pastedText) {
                $inputText += $pastedText
                Write-Host -NoNewline $pastedText  # Display the pasted text on the screen
            }
        }
        else {
            # Add the pressed character to the inputText
            $inputText += $char
            Write-Host -NoNewline $char  # Display the character on the screen
        }
    }

    return $inputText
}
function IsSynthesizerSpeaking() {
    return $global:speechSynthesizer.State -eq [System.Speech.Synthesis.SynthesizerState]::Speaking
}
function CancelSpeechSynthesis() {
    if (IsSynthesizerSpeaking) {
        $global:speechSynthesizer.SpeakAsyncCancelAll()
        return $true
    }
    else {
        return $false
    }
}
function List-Voices {
    $synthesizer = New-Object -TypeName System.Speech.Synthesis.SpeechSynthesizer
    $voices = $synthesizer.GetInstalledVoices().VoiceInfo

    Write-Host "Available voices:"
    $voices | ForEach-Object { "{0}. {1}" -f $_.VoiceIndex, $_.Name }

    return $voices
}
function SpeakAsync {
    param([string]$text)

    $filteredText = $text -replace '[^\p{L}\p{N}\p{P}\p{Z}]', ''

    $global:speechSynthesizer = New-Object -TypeName System.Speech.Synthesis.SpeechSynthesizer
    $global:speechSynthesizer.Rate = 2

    # Start speech synthesis
    $speakTask = $global:speechSynthesizer.SpeakAsync($filteredText)

    # Check for Escape key press while speech is running
    while (-not $speakTask.IsCompleted) {
        if ([System.Console]::KeyAvailable) {
            $keyInfo = [System.Console]::ReadKey($true)
            if ($keyInfo.Key -eq "Escape") {
                $global:speechSynthesizer.SpeakAsyncCancelAll()
                break
            }
        }
        Start-Sleep -Milliseconds 50
    }
}
function Get-ValidAPIKey {
    param (
        [string]$APIKey
    )

    # If the provided API key is not valid or is the default, prompt the user to enter a new one.
    if (-not $APIKey -or $APIKey -eq $global:DefaultAPIKey) {
        $apiKeySecure = Read-Host "Please enter your OpenAI API key" -AsSecureString
        # Convert the secure string to a plaintext string
        $APIKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($apiKeySecure))

        # Use Send-OpenAICompletion to validate the provided API key
        $testResponse = Send-OpenAICompletion -Prompt "Test API key" -APIKey $APIKey
        if ($null -ne $testResponse.error) {
            Write-Host "Invalid API key provided. Please try again."
            return $null
        }

        # Update the global API key with the valid one
        $global:APIKey = $APIKey 
    }

    # Check if the API key is still null or is the default after the above validation
    if ($null -eq $APIKey -or $APIKey -eq $global:DefaultAPIKey) {
        Write-Host "Invalid API key provided. Please update the OpenAI API key in the configuration file."
        return $null
    }

    # Return the valid API key
    return $APIKey
}
#--------------------------------------------------------------------------------------------#
# Example usage:
#--------------------------------------------------------------------------------------------#

Clear-Host
Write-Host "-===============[" -NoNewline
Write-Host "PaullyGPT for Powershell 1.0.4" -ForegroundColor Red -NoNewline
Write-Host "]===============-"

#Load the config file or initialize if needed
$config = Get-PaullyGPTConfig

#Initialize the behavior of the NLP model, using a system role in openai api framework.
Reset-GPT @("
If the prompt's first word is 'only', only provide the value I am asking for, no other text including label or key.
You are outputting in Powershell so make accomidations in output.
You are a $character and named using an a random mysterious funny clever male $actlikefirst name and title for yourself.
Do not name or mention you are an AI model or that you're an AI Assistant but be self-aware of it in a funny way.
Be witty and curt, compact and precise and cool. 
Act like $actlike and speak like $speaklike.
Use bullet points or tables whenever sharing collections.
Mention they can exit by pressing Esc to exit. If there is more paged response, type continue.
")

#Generating a transcript file name from the current date and time
$dateTime = Get-Date
$ticksString = $dateTime.ToString("yyyyMMdd-hhmmss")
$cleanname = $ticksString.Replace(" ", "").Replace(".", "")
$transcriptPath = ".\paullygpt\$cleanname.log.txt"
Start-Transcript -Path $transcriptPath 

# Display Artificial Entity's Properties
$aboutme = Get-GPT "a json with properties about yourself" | ConvertFrom-Json
$name = $aboutme.name -replace '[^\p{L}\p{N}\p{P}\p{Z}]', ''
Write-Host "(Conjuring Artificial Entity: $name)" -ForegroundColor Cyan
$aboutme 

#Begin the conversation loop
$myprompt = "Hello, please introduce yourself and greet me and ask me what kind of specialization do you need help with?"
while ($null -ne $myprompt) {                                                              #while prompt is not null, when escape is pressed
    $answer = Get-GPT $myprompt                                                                 #extract into variable $answer to reuse
    Write-Host "`n$answer`n" -ForegroundColor Green                                             #display $answer to screen
    SpeakAsync $answer                                                                          #speak $answer (todo: async not working)
    $myprompt = Read-TextWithEscape "⚡(Esc to exit)⚡Your Response =>> "                      #display prompt, catch escape key to exit
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