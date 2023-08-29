Import-Module .\ConfigurationModule.psm1
Import-Module .\OpenAIModule.psm1
Import-Module .\SpeechSynthesisModule.psm1
Import-Module .\SVGModule.psm1
Import-Module .\PromptInteractionModule.psm1
Import-Module .\SpecialFXModule.psm1
Import-Module .\PaullyGPT.psm1

# Define a module-level variable to store instances
$global:PaullyGPT_Instances = @{}

# Function to create a new instance of PaullyGPT
function New-PaullyGPTInstance {
    param (
        [string]$InstanceName = "default"
    )

    # Check if the instance name already exists
    if ($global:PaullyGPT_Instances.ContainsKey($InstanceName)) {
        Write-Host "Instance '$InstanceName' already exists."
        return
    }

    # Create a new instance
    $instance = @{
        'name' = $InstanceName
        'chatHistory' = @()
    }

    # Add the instance to the global variable
    $global:PaullyGPT_Instances[$InstanceName] = $instance

    Write-Host "New PaullyGPT instance created: $InstanceName"
}

# Function to get an instance of PaullyGPT
function Get-PaullyGPTInstance {
    param (
        [string]$InstanceName = "default"
    )

    # Check if the instance name exists
    if (-not $global:PaullyGPT_Instances.ContainsKey($InstanceName)) {
        Write-Host "Instance '$InstanceName' does not exist."
        return
    }

    # Get the instance
    return $global:PaullyGPT_Instances[$InstanceName]
}

# Function to add a message to the chat history of an instance
function Add-ToPaullyGPTChatHistory {
    param (
        [string]$InstanceName = "default",
        [string]$Role,
        [string]$Content
    )

    $instance = Get-PaullyGPTInstance -InstanceName $InstanceName

    if ($instance) {
        $message = @{
            'role' = $Role
            'content' = $Content
        }
        $instance['chatHistory'] += $message
    }
}

# Function to clear the chat history of an instance
function Clear-PaullyGPTChatHistory {
    param (
        [string]$InstanceName = "default"
    )

    $instance = Get-PaullyGPTInstance -InstanceName $InstanceName

    if ($instance) {
        $instance['chatHistory'] = @()
    }
}

# Function