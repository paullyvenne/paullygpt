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
                $clipboardText = [System.Windows.Forms.Clipboard]::GetText()
                $pastedText += $clipboardText
                #Read-FromInputBox -InputText $clipboardText -Prompt "Paste text from clipboard"
                #[System.Windows.Forms.Clipboard]::Clear() > $null
                $enterMode = $false
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
                    Write-Host "`n$timestamp ...`n" -NoNewLine -ForegroundColor Cyan; 
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

function Get-ParentProcessInfo {
    $hostProcessId = $PID
    $hostProcess = Get-Process -Id $hostProcessId
    $parentProcessId = $hostProcess.ParentProcessId
    $parentProcess = Get-Process -Id $parentProcessId

    Write-Host "PowerShell is hosted by process:"
    $parentProcess | Select-Object ProcessName, Id, SessionId        
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
    param(
        [string]$inputText,
        [string]$prompt
    )

    # Create the form
    $form = New-Object System.Windows.Forms.Form
    $form.Text = $prompt
    $form.MaximizeBox = $false  # Prevent maximizing the form
    $form.MinimizeBox = $false  # Prevent minimizing the form
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
    $form.Width = 400
    $form.Height = 300

    # Create the TextBox
    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Multiline = $true
    $textBox.ScrollBars = "Vertical"
    $textBox.Dock = [System.Windows.Forms.DockStyle]::Fill
    $textBox.Text = $inputText

    # Create the OK button
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = "OK"
    $okButton.Dock = "Bottom"

    # Create the Cancel button
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = "Cancel"
    $cancelButton.Dock = "Bottom"

    # Add controls to the form
    $form.Controls.Add($textBox)
    $form.Controls.Add($okButton)
    $form.Controls.Add($cancelButton)

    # Event handler for the OK button click
    $okButton.Add_Click({
        $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
    })

    # Event handler for the Cancel button click
    $cancelButton.Add_Click({
        $form.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    })

    # Center the form on the screen
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen

    # Make the form topmost and bring it to the front
    $form.TopMost = $true
    $form.BringToFront()

    # Show the form and return the result
    $result = $form.ShowDialog($_.me)

    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        return $textBox.Text
    }

    return $null
}

