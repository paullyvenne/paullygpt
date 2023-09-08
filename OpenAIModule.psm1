$global:MaxTokens = 500
$global:Temperature = 0.8
$global:MaxCompletionLoop = 5
$global:MaxExceptionLoop = 20

$lastContent = ""

function Optimize_MessageTokens {
    param (
        [object[]]$Messages,
        [long]$MaxTokenSize = 16384,
        [long]$MaxCompletionTokenSize = 500
    )

    $neededBuffer = $MaxTokenSize-$MaxCompletionTokenSize
    if($Messages.Length -gt 12 -and $Message.Length -gt $neededBuffer) {
        return @($Messages[0]) + @($Messages | Select-Object -Skip 10)
    } else {
        return @($Messages[0]) + @($Messages | Select-Object -Skip 2)
    }
    # $replyPrompts = $Messages.Clone() | Select-Object -Skip 1
    # $count = Get_MessageTokenCount -Messages $replyPrompts
    # if(!($count -gt ($MaxTokenSize - $MaxCompletionTokenSize))) {
    #     return $Messages }
    # else {
    #     while($count -gt ($MaxTokenSize - $MaxCompletionTokenSize)) {
    #         $replyPrompts = $Messages | Select-Object -Skip 1
    #         $count = Get_MessageTokenCount -Messages $replyPrompts
    #     }
    #     $optimizedMessages = @($Messages[0]) + $replyPrompts
    #     return $optimizedMessages
    # }
}

function Trim_MessageTokens {
    param (
        [object[]]$Messages,
        [long]$MaxTokenSize = 16384,
        [long]$MaxCompletionTokenSize = 500
    )
        $replyPrompts = $Messages.Clone() | Select-Object -Skip 1
        $count = Get_MessageTokenCount -Messages $replyPrompts
        $replyPrompts = $replyPrompts | Select-Object -Skip $MaxCompletionTokenSize
        $optimizedMessages = @($Messages[0]) + $replyPrompts
        return $optimizedMessages
}

function Get_MessageTokenCount{
    Param(
        [object[]]$Messages
    )
    $tokenCount = $Messages | ForEach-Object { ($_.Content -split '[^a-zA-Z0-9]+').Count } | Measure-Object -Sum | Select-Object -ExpandProperty Sum
    return $tokenCount
}
function Append_Message {
    param (
        [string]$Prompt,
        [string]$Role = "user"
    )
    try {
        if(!([string]::IsNullOrEmpty($Prompt))) {
            $Prompt = $Prompt.Trim()

            $newMessage = @{
                role    = $Role
                content = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::UTF8.GetBytes($Prompt))
            }
            if($global:ChatHistory.Count -eq 0) {
                $global:ChatHistory = @()
            }
            $global:ChatHistory += @($newMessage) 
        }
    } catch {
        Write-Host "An error occurred: $($_.Exception.ToString())" -ForegroundColor Red
    }
    return $null
}

function Send-OpenAICompletion {
    param (
        [string]$Prompt,
        [int]$MaxTokens = $global:MaxTokens,
        [double]$Temperature = $global:Temperature,
        [string]$APIKey,
        [int]$MaxCompletionLoop = $global:MaxCompletionLoop,
        [int]$MaxExceptionLoop = $global:MaxExceptionLoop,
        [bool]$SavePrompt = $true,
        [bool]$SaveResponse = $true
    )

    $output = ""

    if($SavePrompt -eq $true) {
        Append_Message -Role "user" -Prompt $Prompt
    }

   
    # #Clean up ChatHistory from oldest if it exceeds MaxTokens
    # $currentCount = Get_MessageTokenCount
    # while($currentCount -gt 8000 -and $global:ChatHistory.Length -gt 1){
    #     $global:ChatHistory.RemoveAt(1)
    #     $currentCount = GetMessageTokenCount
    #     #Should also request a summary soon message to be added to the chat history
    # }

    $body = @{
        model       = $global:Model
        messages    = $global:ChatHistory
        temperature = $Temperature
        max_tokens  = $maxCompletionTokens
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
                #content should alwasys be final message.
                $content = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::UTF8.GetBytes($response.choices[0].message.content))
                #encode $content to utf-8
                
                $reason = $response.choices[0].finish_reason

                if($SaveResponse -eq $true) {
                    Append_Message -Role "assistant" -Prompt $content
                }
                
                $output += $content
                if(($MaxCompletionLoop -gt 0) -and ($reason -eq "length")) {
                    #$added = $content.Replace($lastContent, "")
                    #Write-Host "." -ForegroundColor Yellow -NoNewline
                    #Write-Host "$reason : $added`nStill thinking..." -ForegroundColor Yellow
                    $output += Send-OpenAICompletion -Prompt "continue" -MaxTokens $MaxTokens -Temperature $Temperature -APIKey $APIKey -SavePrompt $false -SaveReponse $true -MaxCompletionLoop ($MaxCompletionLoop-1) -MaxExceptionLoop $MaxExceptionLoop                   
                }
                return $output
            }
        }
        else {
            throw [System.Exception]::new("An unexpected error occurred. The response was null.")
        }
    }
    catch [System.Net.WebException] {
        Write-Host "An error occurred: $($_.Exception.ToString())" -ForegroundColor Red
        $httpResponse = $_.Exception.Response
        if ($httpResponse -and $httpResponse.StatusCode -eq "BadRequest") {
            if ($MaxExceptionLoop -gt 0) {
                Write-Host "." -NoNewline -ForegroundColor Red
                $global:ChatHistory = Optimize_MessageTokens -Messages $global:ChatHistory -MaxCompletionTokenSize $MaxTokens 
                $output = Send-OpenAICompletion -Prompt "" -MaxTokens $MaxTokens -Temperature $Temperature -APIKey $APIKey -SavePrompt $SavePrompt -SaveReponse $saveResponse -MaxCompletionLoop $MaxCompletionLoop -MaxExceptionLoop ($MaxExceptionLoop-1)                       
            }
        }
        throw [System.Exception]::new("An unexpected error occurred: $_")
    }
    catch {
        if($null -ne $_.ErrorDetails) {
            if(($_.ErrorDetails | ConvertFrom-Json).error.message -like "*maximum context length*") {
                if ($MaxExceptionLoop -gt 0) {
                    Write-Host "." -NoNewline -ForegroundColor Red
                    $global:ChatHistory = Optimize_MessageTokens -Messages $global:ChatHistory -MaxCompletionTokenSize $MaxTokens 
                    Start-Sleep -Milliseconds 500
                    return Send-OpenAICompletion -Prompt "" -MaxTokens $MaxTokens -Temperature $Temperature -APIKey $APIKey -SavePrompt $SavePrompt -SaveReponse $saveResponse -MaxCompletionLoop $MaxCompletionLoop -MaxExceptionLoop ($MaxExceptionLoop-1)                       
                }
            }
        }
        if($true -eq $global:DEBUG) {
            Write-Host "An error occurred: $_" -ForegroundColor Red
            Write-Host ($param) -ForegroundColor Yellow
            if($null -ne $_.ErrorDetails.Message) {
                Write-Host ($_.ErrorDetails.Message | ConvertFrom-Json).error.message -ForegroundColor Red
            }
        }
        Write-Host "An error occurred: $($_.Exception.ToString())" -ForegroundColor Red
    }
    return $null
}
# function Send-OpenAICompletion3 {
#     param (
#         [string]$Prompt,
#         [int]$MaxTokens = 500,
#         [double]$Temperature = 0.8,
#         [string]$APIKey,
#         [bool]$savePrompt = $true
#     )

#     $newMessage = @{
#         role    = "user"
#         content = $Prompt
#     }

#     $global:ChatHistory +#= $newMessage 
#     $body = @{
#         model       = $global:Model
#         messages    = $global:ChatHistory
#         temperature = $Temperature
#         max_tokens  = $MaxTokens
#         n           = 1
#         stop        = $null
#     } | ConvertTo-Json -Depth 5 -Compress

#     $headers = @{
#         "Content-Type"  = "application/json"
#         "Authorization" = "Bearer $APIKey"
#     }

#     $param = @{
#         Uri     = "https://api.openai.com/v1/chat/completions"
#         Headers = $headers
#         Method  = "Post"
#         Body    = $body
#     }

#     try {
#         $response = Invoke-RestMethod @param
#         if ($null -ne $response) {
#             if ($null -ne $response.error) {
#                 throw [System.Exception]::new($response.error.message)
#             }
#             else {
#                 return $response.choices[0].message.content
#             }
#         }
#         else {
#             throw [System.Exception]::new("An unexpected error occurred. The response was null.")
#         }
#     }
#     catch {
#         if($true -eq $global:DEBUG) {
#             Write-Host "An error occurred: $_" -ForegroundColor Red
#             Write-Host ($param) -ForegroundColor Yellow
#         } else {
#             Write-Host "An error occurred: $($_.Exception.ToString())" -ForegroundColor Red
#         }
#         return $null
#     }
# }
# function Send-OpenAICompletion2 {
#     param (
#         [string]$Prompt,
#         [int]$MaxTokens = 500,
#         [double]$Temperature = 0.8,
#         [string]$APIKey,
#         [switch]$Paginate
#     )

#     $body = @{
#         model       = $global:Model
#         messages    = $global:ChatHistory
#         temperature = $Temperature
#         max_tokens  = $MaxTokens
#         n           = 1
#         stop        = $null
#     } | ConvertTo-Json -Depth 5 -Compress

#     $headers = @{
#         "Content-Type"  = "application/json"
#         "Authorization" = "Bearer $APIKey"
#     }

#     $param = @{
#         Uri     = "https://api.openai.com/v1/chat/completions"
#         Headers = $headers
#         Method  = "Post"
#         Body    = $body
#     }

#     $result = @()

#     do {
#         try {
#             $response = Invoke-RestMethod @param
#             if ($null -ne $response) {
#                 if ($null -ne $response.error) {
#                     throw [System.Exception]::new($response.error.message)
#                 }
#                 else {
#                     $result += $response.choices[0].message.content

#                     if ($Paginate -and $response.choices[0].finish_reason -ne 'stop') {
#                         $newResult = Send-OpenAICompletion -Prompt $Prompt -MaxTokens $MaxTokens -Temperature $Temperature -APIKey $APIKey -Paginate
#                         if ($null -ne $newResult) {
#                             $result += $newResult
#                         }
#                     }
#                     else {
#                         break
#                     }
#                 }
#             }
#             else {
#                 throw [System.Exception]::new("An unexpected error occurred. The response was null.")
#             }
#         }
#         catch {
#             Write-Host "An error occurred: $($_.Exception.Message)" -ForegroundColor Red
#             Exit 1
#         }
#     } until (!$Paginate)

#     return $result -join ' '
# }
function Get-OpenAICompletion {
    param (
        [string]$Prompt,
        [int]$MaxTokens = 500,
        [double]$Temperature = 0.8,
        [bool]$SavePrompt = $true,
        [bool]$SaveResponse = $true
    )

    $configFilePath =  $global:DefaultDataFolder + "paullygpt.config.json"
    $config = Read-Config -ConfigFilePath $configFilePath

    $apiKey = Get-ValidAPIKey -APIKey $config.APIKey
    if (-not $apiKey) {
        Write-Host "Failed to get a valid API key. Exiting."
        Exit 1
    }

    $result = Send-OpenAICompletion -Prompt $Prompt -MaxTokens $MaxTokens -Temperature $Temperature -APIKey $apiKey -SavePrompt $SavePrompt -SaveResponse $SaveResponse
    $isSVG = $result -match "(?s)<svg.*?</svg>"
    #i want to refactor the if below to properly check for null or empty svgmarkup
    if ($isSVG -eq $true) {
        $svgMarkup = $matches[0]
        $result = $result.Replace($svgMarkup, "[See Visual Output]")
        Update-SVG -SVGMarkup $svgMarkup -Title "Paully GPT" 
    }

    #Clean Up
    $filteredArray = $global:ChatHistory | Where-Object { $_.role -ne "user" -or !$_.content.StartsWith($hash) }
    $global:ChatHistory = $filteredArray
    return $result
}
function Reset-GPT {
    param(
        [string]$Directive
    )
    $global:ChatHistory = @()
    Append_Message -Role "system" -Prompt $Directive
}
function Get-GPT {
    param(
        [string]$Prompt,
        [bool]$SavePrompt = $true,
        [bool]$SaveResponse = $true
    )
    $completion = Get-OpenAICompletion -Prompt $Prompt -SavePrompt $SavePrompt -SaveResponse $SaveResponse -MaxTokens $global:MaxTokens
    return $completion
}
function Get-GPTQuiet {
    param(
        [string]$Prompt,
        [bool]$SavePrompt = $true,
        [bool]$SaveResponse = $false
    )
    $completion = Get-OpenAICompletion -Prompt $Prompt -SavePrompt $SavePrompt -SaveResponse $SaveResponse -MaxTokens $global:MaxTokens
    return $completion
}

function Get-GPTAndForget {
    param(
        [string]$prompt,
        [bool]$SavePrompt = $false,
        [bool]$SaveResponse = $false
    )
    $completion = Get-OpenAICompletion -Prompt $prompt -SavePrompt $SavePrompt -SaveResponse $SaveResponse -MaxTokens $global:MaxTokens
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
        $testResponse = Send-OpenAICompletion -Prompt "Test API key" -APIKey $APIKey -SavePrompt $false -SaveResponse $false
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