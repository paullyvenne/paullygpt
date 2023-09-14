using namespace System.Windows.Forms
using namespace System.Drawing

# Load the System.Windows.Forms assembly
# which implicitly loads System.Drawing too.
Add-Type -AssemblyName System.Windows.Forms
Import-Module .\Modules\OpenAIModule.psm1

$global:speechEnabled = $true
$enterMode = $true

$lastKeyTime = Get-Date
function Read-TextWithEscape {
    param (
        [string]$Prompt
    )

    Write-Host $Prompt -ForegroundColor Red -NoNewline
    $InputText = ""
    while ($true) {
        $key = [System.Console]::ReadKey($true)
        $char = $key.KeyChar

        #Write-Host $key.Key -NoNewline -ForegroundColor Yellow

        $lastDuration = (Get-Date) - $lastKeyTime
        $enterMode = ($lastDuration.TotalMilliseconds -gt 100) # 100 MS since last keypress
        $lastKeyTime = Get-Date

        switch ($key.Key) {
            "Escape" {
                Write-Host ""
                $confirmation = Read-Host "Do you want to exit? (Y/N)"
                if ($confirmation -like "[yY]*") { 
                    return $null }
                else { Write-Host $Prompt -ForegroundColor Red -NoNewline }
            }

            "Backspace" {
                if ($InputText.Length -gt 0) {
                    $InputText = $InputText.Substring(0, $InputText.Length - 1)
                    Write-Host -NoNewline "`b `b"
                }
            }

            # Clipboard paste
            { ($key.Modifiers -band [System.ConsoleModifiers]::Control) -and ($key.Key -eq "V") } {
                $clipboardText = [System.Windows.Forms.Clipboard]::GetText()
                $pastedText += $clipboardText
                #Read-FromInputBox -InputText $clipboardText -Prompt "Paste text from clipboard"
                #[System.Windows.Forms.Clipboard]::Clear() > $null
                # Write-Host "enterMode = $enterMode" -ForegroundColor Yellow
                if ($null -ne $pastedText ) {
                    Write-Host -NoNewline $pastedText
                    $InputText += $pastedText
                } 
                Start-Sleep -Milliseconds 100
                break
            }

            "Enter" { 
                if($true -eq $enterMode) {
                    $dateTime = Get-Date
                    $timestamp = $dateTime.ToString()
                    Write-Host "`n$timestamp ..." -NoNewLine -ForegroundColor Cyan; 
                    return $InputText 
                } else {
                    $InputText += "`n"
                    #Write-Host "`n" -NoNewLine -ForegroundColor Cyan; 
                }
            }

            # Toggle speech
            { ($key.Modifiers -band [System.ConsoleModifiers]::Control) -and ($key.Key -eq "T") } {
                $global:speechEnabled = -not $global:speechEnabled 
            }

            default {
                $InputText += $char
                Write-Host -NoNewline $char
            }
        }
    }

    return $InputText
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
        $gptResponse = Get-GPTQuiet "a json with properties about yourself"
        if ($null -ne $gptResponse) {
            try {
                $jsonResult = $gptResponse 
                #| ConvertFrom-Json
            }
            catch {
                Write-Host $gptResponse
            }
        }
        else {
            $jsonResult = $gptResponse | Select-String -Pattern $jsonRegex | ForEach-Object { $_.Matches.Groups[1].Value }
        }
        $retries += 1
    }
    until (($retries -gt 5) -or ($null -ne $jsonResult -or $jsonResult.Trim().Length -gt 0))

    if($retries -gt 5) {
        Write-Host "Error: Unable to convert GPT response to JSON format."
    }

    return $jsonResult 
}

function ReadJsonFromFile {
    param (
        [string]$FilePath
    )
    $json = Get-Content -Path $FilePath | ConvertFrom-Json
    return $json
}

function ReadFromFile {
    param (
        [string]$FilePath
    )
    $content = Get-Content -Path $FilePath
    return $content
}

function ReadFromWeb {
    param (
        [string]$Url
    )
    $response = Invoke-WebRequest -Uri $Url
    return $response.Content
}

function Read-FromInputBox {
    param(
        [string]$InputText,
        [string]$Prompt
    )

    # Create the form
    $form = New-Object System.Windows.Forms.Form
    $form.Text = $Prompt
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
    $textBox.Text = $InputText

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

