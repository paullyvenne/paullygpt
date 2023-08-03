Import-Module .\OpenAIModule.psm1

function Get-CurrentAgent {
    $retries = 0
    $jsonRegex = '(?s)```json(.*?)```'
    $s2 = $null
    do {
        $s1 = Get-GPT "a json with properties about yourself"
        if ($null -ne ($s1 | ConvertFrom-Json)) {
            $s2 = $s1 
        } else {
            $s2 = $s1 | Select-String -Pattern $jsonRegex | ForEach-Object { $_.Matches.Groups[1].Value }
        }
        $retries +=1
    } until (($retries > 5) -or ($null -ne $s2e -or $s2.Trim().Length -gt 0))
    return $s2 | ConvertFrom-Json
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
            if ($pastedText -ne $null) {
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