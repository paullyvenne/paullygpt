Add-Type -AssemblyName System.Speech
Add-Type -AssemblyName System.Windows.Forms

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