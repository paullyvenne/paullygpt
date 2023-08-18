Add-Type -AssemblyName System.Speech
Add-Type -AssemblyName System.Windows.Forms

$global:speechEnabled = $true
$global:speechSynthesizer = $null
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
function GetVoiceList {
    $synthesizer = New-Object -TypeName System.Speech.Synthesis.SpeechSynthesizer
    $voices = $synthesizer.GetInstalledVoices().VoiceInfo

    "Available voices:"
    $voices | ForEach-Object { "{0}. {1}" -f $_.VoiceIndex, $_.Name }

    return $voices
}
function SetDefaultVoice {
    Param(
        [Parameter(Mandatory=$true)]
        [String] $voiceName
    )

    $synthesizer = New-Object -TypeName System.Speech.Synthesis.SpeechSynthesizer
    $synthesizer.SelectVoice($voiceName)

    Write-Host "Voice set to: $voiceName."
}

function SpeakAsync {
    param([string]$text)

    if (-not $global:speechEnabled) {
        return
    }

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

function PromptVoice {
    $voices = GetVoiceList
    Write-Host "Choose a voice:"
    $voices | ForEach-Object { "{0}. {1}" -f $_.VoiceIndex, $_.Name }
    $voiceIndex = Read-Host "Enter voice index: "
    $voiceName = $voices[$voiceIndex].Name
    SetDefaultVoice -voiceName $voiceName
}