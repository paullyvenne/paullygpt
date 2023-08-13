using namespace System.Windows.Forms
using namespace System.Drawing

# Load the System.Windows.Forms assembly
# which implicitly loads System.Drawing too.
Add-Type -AssemblyName System.Windows.Forms
Import-Module .\OpenAIModule.psm1

$global:speechEnabled = $true
$enterMode = $true

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
                if ($confirmation -like "[yY]*") { 
                    return $null }
                else { Write-Host $prompt -ForegroundColor Red -NoNewline }
            }

            "Backspace" {
                if ($inputText.Length -gt 0) {
                    $inputText = $inputText.Substring(0, $inputText.Length - 1)
                    Write-Host -NoNewline "`b `b"
                }
            }

            # Clipboard paste
            { ($key.Modifiers -band [System.ConsoleModifiers]::Control) -and ($key.Key -eq "V") } {
                #$inputText += Read-FromInputBox
                $enterMode = $false
                $pastedText = [System.Windows.Forms.Clipboard]::GetText()
                [System.Windows.Forms.Clipboard]::Clear() > $null
                if ($null -ne $pastedText ) {
                    Write-Host -NoNewline $pastedText
                    $inputText += $pastedText
                } 
                Start-Sleep -Milliseconds 100
                $enterMode = $true 
                break
            }

            "Enter" { 
                if($true -eq $enterMode) {
                    $dateTime = Get-Date
                    $timestamp = $dateTime.ToString()
                    Write-Host "`n$timestamp ...`n" -ForegroundColor Cyan ; 
                    return $inputText 
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

function Read-TextWithEscape2 {
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
                if ($confirmation -like "[yY]*") { 
                    return $null }
                else { Write-Host $prompt -ForegroundColor Red -NoNewline }
            }

            "Backspace" {
                if ($inputText.Length -gt 0) {
                    $inputText = $inputText.Substring(0, $inputText.Length - 1)
                    Write-Host -NoNewline "`b `b"
                }
            }

            # Clipboard paste
            { ($key.Modifiers -band [System.ConsoleModifiers]::Control) -and ($key.Key -eq "V") } {
                #$inputText += Read-FromInputBox
                $enterMode = $false
                $pastedText = [System.Windows.Forms.Clipboard]::GetText()
                [System.Windows.Forms.Clipboard]::Clear() > $null
                if ($null -ne $pastedText ) {
                    Write-Host -NoNewline $pastedText
                    $inputText += $pastedText
                } 
                Start-Sleep -Milliseconds 100
                $enterMode = $true 
                break
            }

            "Enter" { 
                if($true -eq $enterMode) {
                    $dateTime = Get-Date
                    $timestamp = $dateTime.ToString()
                    Write-Host "`n$timestamp ...`n" -ForegroundColor Cyan ; 
                    return $inputText 
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

function Get-CurrentAgent {
    $retries = 0
    $jsonRegex = '(?s)```json(.*?)```'
    $jsonResult = $null

    do {
        $gptResponse = Get-GPT "a json with properties about yourself"

        if ($gptResponse -ne $null) {
            try {
                $jsonResult = $gptResponse | ConvertFrom-Json
            }
            catch {
                Write-Host "Error: Unable to convert GPT response to JSON format."
            }
        }
        else {
            $jsonResult = $gptResponse | Select-String -Pattern $jsonRegex | ForEach-Object { $_.Matches.Groups[1].Value }
        }

        $retries += 1
    }
    until (($retries -gt 5) -or ($jsonResult -ne $null -or $jsonResult.Trim().Length -gt 0))

    return $jsonResult 
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


function Read-FromInputBox {
    # Create the form.
    ($form = [Form] @{
        Text            = "Paste in your response:"
        Size            = [Size]::new(300, 200)
        ControlBox      = $false
        FormBorderStyle = 'FixedDialog'
        StartPosition   = 'CenterScreen'
        TopMost         = $true
    }).Controls.AddRange(@(

    ($textBox = [TextBox] @{
                MultiLine = $true
                Location  = [Point]::new(10, 10)
                Size      = [Size]::new(260, 100)
            })

    ($okButton = [Button] @{
                Location     = [Point]::new(100, 120)
                Size         = [Size]::new(80, 30)
                Text         = '&OK'
                DialogResult = 'OK'
                Enabled      = $false
            })

    ($cancelButton = [Button] @{
                Location = [Point]::new(190, 120)
                Size     = [Size]::new(80, 30)
                Text     = 'Cancel'
            })

        ))

    # Make Esc click the Cancel button.
    # Note: We do NOT use $form.AcceptButton = $okButton,
    #       because that would prevent using Enter to enter multiple lines.
    $form.CancelButton = $cancelButton

    # Make sure that OK can only be clicked if the textbox is non-blank.
    $textBox.add_TextChanged({
            $okButton.Enabled = $textBox.Text.Trim().Length -gt 0
        })

    $form.BringToFront()

    # Display the dialog modally and evaluate the result.
    $dialogResult = $form.ShowDialog()
    if ($dialogResult -ne 'OK') {
        Throw 'Canceled by user request.'
    }

    $form.BringToFront()
    
    # Parse the multi-line string into an array of individual addresses.
    $inputResult = -split $textBox.Text
    return $inputResult
}