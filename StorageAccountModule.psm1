Import-Module -Name Az

$azContext = $null

function Init_Azure {
    # Check for the availability of the key
    #try {
        Write-Host "Attempting..." -ForegroundColor Blue
        Connect-AzAccount


        #Connect-AzAccount -ServicePrincipal -ApplicationId <client-id> -Credential (New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "<client-id>", (ConvertTo-SecureString -String "<client-secret>" -AsPlainText -Force)) -Tenant <tenant-id>
        #Set-AzStorageContext -StorageAccountName <storage-account-name> -ResourceGroupName <resource-group-name>  
        #Set-AzStorageBlobContent -Container $containerName -File $localFilePath -Blob $blobName

        #} catch ($ex) {
    #    Write-Host $ex 
    #}
}

function Write-Storage {
    param (
        [string]$tableName = "Conversations",
        [string]$object
    )

    Init_Azure

    if($null -eq $azContext -or $null -eq $tableName -or $null -eq $object) {
        Write-Host "Write-Storge invalid arguements." -ForegroundColor Red
        return
    }

    $storageAccountName = "vennesolutions"
    $storageAccountKey = "8TJkyuTZ5hL6RrJ0unuouru7fO8NCI8KSLe9d0td0nSuSDSqZKoqQo17Anu8uNCg3BkAkUFiypWOGh6TLRmCWw=="
    $azContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey

    # Create a storage table
    New-AzStorageTable -Name $tableName
    
    # Create an entity for the conversation entry
    $currentDate = Get-Date
    $entity = New-AzStorageTableEntity -Property @{
        PartitionKey = $currentDate.ToString("yyyy-MM-dd")
        RowKey       = [Guid]::NewGuid().ToString()
        Message      = $object | ConvertTo-Json
    }

    # Save the entity to the storage table
    Set-AzStorageTableEntity -TableName $tableName -Entity $entity
}