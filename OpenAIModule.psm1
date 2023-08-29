
function Send-OpenAICompletion {
    param (
        [string]$Prompt,
        [int]$MaxTokens = 500,
        [double]$Temperature = 0.8,
        [string]$APIKey,
        [bool]$savePrompt = $true
    )

    $newMessage = @{
        role    = "user"
        content = $Prompt
    }

    $global:ChatHistory += $newMessage 
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
        if($true -eq $global:DEBUG) {
            Write-Host "An error occurred: $_" -ForegroundColor Red
            Write-Host ($param) -ForegroundColor Yellow
        } else {
            Write-Host "An error occurred: $($_.Exception.ToString())" -ForegroundColor Red
        }
        return $null
    }
}
function Send-OpenAICompletion2 {
    param (
        [string]$Prompt,
        [int]$MaxTokens = 500,
        [double]$Temperature = 0.8,
        [string]$APIKey,
        [switch]$Paginate
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

    $result = @()

    do {
        try {
            $response = Invoke-RestMethod @param
            if ($null -ne $response) {
                if ($null -ne $response.error) {
                    throw [System.Exception]::new($response.error.message)
                }
                else {
                    $result += $response.choices[0].message.content

                    if ($Paginate -and $response.choices[0].finish_reason -ne 'stop') {
                        $newResult = Send-OpenAICompletion -Prompt $Prompt -MaxTokens $MaxTokens -Temperature $Temperature -APIKey $APIKey -Paginate
                        if ($null -ne $newResult) {
                            $result += $newResult
                        }
                    }
                    else {
                        break
                    }
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
    } until (!$Paginate)

    return $result -join ' '
}
function Get-OpenAICompletion {
    param (
        [string]$Prompt,
        [int]$MaxTokens = 500,
        [double]$Temperature = 0.8,
        [bool]$savePrompt = $true
    )

    $configFilePath = ".\paullygpt\paullygpt.config.json"
    $config = Read-Config -ConfigFilePath $configFilePath

    $apiKey = Get-ValidAPIKey -APIKey $config.APIKey
    if (-not $apiKey) {
        Write-Host "Failed to get a valid API key. Exiting."
        Exit 1
    }

    $result = Send-OpenAICompletion -Prompt $Prompt -MaxTokens $MaxTokens -Temperature $Temperature -APIKey $apiKey -savePrompt $savePrompt 
    $isSVG = $result -match "(?s)<svg.*?</svg>"
    #i want to refactor the if below to properly check for null or empty svgmarkup
    if ($isSVG -eq $true) {
        $svgMarkup = $matches[0]
        $result = $result.Replace($svgMarkup, "[See Visual Output]")
        Update-SVG -SVGMarkup $svgMarkup -Title "Paully GPT" 
    }
    return $result
}
function Reset-GPT {
    param(
        [string]$directive
    )
    $global:ChatHistory = @()
    $global:ChatHistory += @{ role = "system"; content = $directive }
}
function Get-GPT {
    param(
        [string]$prompt
    )
    $completion = Get-GPTQuiet -Prompt $prompt
    $global:ChatHistory += @{ role = "assistant"; content = $completion }
    return $completion
}
function Get-GPTQuiet {
    param(
        [string]$prompt
    )
    $completion = Get-OpenAICompletion -Prompt $prompt
    return $completion
}

function Get-GPTandForget {
    param(
        [string]$prompt
    )
    $completion = Get-OpenAICompletion -Prompt $prompt -savePrompt $false
    return $completion
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