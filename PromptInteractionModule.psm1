# Add a reference for clipboard functionality
Add-Type -AssemblyName System.Windows.Forms

Import-Module .\OpenAIModule.psm1

$global:speechEnabled = $true
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
        $retries += 1
    } until (($retries > 5) -or ($null -ne $s2 -or $s2.Trim().Length -gt 0))
    return $s2 | ConvertFrom-Json
}

function Read-TextWithEscape {
    param (
        [string]$prompt
    )

    Write-Host $prompt -ForegroundColor Red -NoNewline
    $inputText = ""

    while ($true) {
        $key = [System.Console]::ReadKey($true)
        $char = $key.KeyChar

        switch ($key.Key) {
            "Escape" {
                Write-Host ""
                $confirmation = Read-Host "Do you want to exit? (Y/N)"
                if ($confirmation -like "[yY]*") { return $null }
                else { Write-Host $prompt -ForegroundColor Red -NoNewline }
            }

            
            "Enter" { 
                $dateTime = Get-Date
                $timestamp = $dateTime.ToString()
                Write-Host "`n$timestamp ...`n" -ForegroundColor Cyan ; return $inputText 
            }
            
            "Backspace" {
                if ($inputText.Length -gt 0) {
                    $inputText = $inputText.Substring(0, $inputText.Length - 1)
                    Write-Host -NoNewline "`b `b"
                }
            }

            # Clipboard paste
            { ($key.Modifiers -band [System.ConsoleModifiers]::Control) -and ($key.Key -eq "V") } {
                $pastedText = [System.Windows.Forms.Clipboard]::GetText()
                if ($pastedText -ne $null) {
                    $inputText += $pastedText
                    Write-Host -NoNewline $pastedText
                    Start-Sleep -Milliseconds 100
                }
            }

            # Toggle speech
            { ($key.Modifiers -band [System.ConsoleModifiers]::Control) -and ($key.Key -eq "T") } {
                $global:speechEnabled = -not $global:speechEnabled 
            }

            default {
                $inputText += $char
                Write-Host -NoNewline $char
            }
        }
    }

    return $inputText
}

function ReadJsonFromFile {
    param (
        [string]$filePath
    )
    $json = Get-Content -Path $filePath | ConvertFrom-Json
    return $json
}

function ReadFromFile {
    param (
        [string]$filePath
    )
    $content = Get-Content -Path $filePath
    return $content
}

function ReadFromWeb {
    param (
        [string]$url
    )
    $response = Invoke-WebRequest -Uri $url
    return $response.Content
}
