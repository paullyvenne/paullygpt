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
    $configPath = ".\paullygpt\paullygpt.config.json"

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