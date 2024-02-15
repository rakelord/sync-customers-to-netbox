Import-Module PSTopdeskFunctions
Import-Module PSNetboxFunctions

$config = Get-Content -Path ".\config.json" -Raw -Encoding UTF8 | ConvertFrom-Json

Connect-NetboxAPI -Url $config.Netbox.Url -Token $config.Netbox.API.Token -LogToFile $config.LogToFile
Connect-TOPdeskAPI -Url $config.TOPdesk.Url -LoginName $config.TOPdesk.API.Username -Secret $config.TOPdesk.API.Secret -LogToFile $config.LogToFile

$TOPdeskCustomers = Get-TopdeskBranches -LogToFile $config.LogToFile | Where-Object {$_.optionalFields1.text2 -ne ''}
$NetboxCustomers = Get-NetboxObjects -APIEndpoint "/api/tenancy/tenants/" -LogToFile $config.LogToFile

foreach ($Customer in $TOPdeskCustomers){
    $CustomerID = $Customer.optionalFields1.text2
    $NetboxCustomer = $NetboxCustomers.Where({$_.custom_fields.navision_id -eq $CustomerID})

    $customerExist = (IsNotNULL($NetboxCustomer.name))
    $updatedInLast2Days = (Get-ValidDate($Customer.modificationDate)) -gt (Get-ValidDate(Get-Date).AddDays(-2))
    if ($customerExist){
        ############
        ## UPDATE ##
        ############

        $updatedInLast2Days = (Get-ValidDate($Customer.modificationDate)) -gt (Get-ValidDate(Get-Date).AddDays(-2))
        if ($updatedInLast2Days){
            Update-NetboxTenant -tenantObject $NetboxCustomer -tenantName $Customer.name -newTags ("topdesk-synced") -LogToFile $config.LogToFile
        }
    }
    else {
        ############
        ## CREATE ##
        ############

        $Data = @{
            custom_fields = @{ 
                navision_id = $CustomerID 
            }
        }
        New-NetboxTenant -tenantName $Customer.name -tags ("topdesk-synced") -objectData $Data -LogToFile $config.LogToFile
    }
}

#############
## DISABLE ##
#############

foreach ($NetboxCustomer in $NetboxCustomers){
    $CustomerID = $NetboxCustomer.custom_fields.navision_id
    $TOPdeskCustomer = $TOPdeskCustomers.Where({$_.optionalFields1.text2 -eq $CustomerID})

    $customerDoesNotExist = (IsNULL($TOPdeskCustomer.name))
    $customerStillActive = ("topdesk-synced" -in $NetboxCustomer.tags.display)
    if ($customerDoesNotExist -AND $customerStillActive){
        $customerTags = $NetboxCustomer.tags | Where-Object {$_.name -ne 'topdesk-synced'}
        $tags = AddTagsToObject -CurrentTags $customerTags.name -NewTags ("topdesk-synced-orphaned")

        $updateData = $tags | ConvertTo-Json -Compress
        Write-Log -Message "Disable Customer: $($NetboxCustomer.name) - $($NetboxCustomer.id) - $updateData" -Active $config.LogToFile
        Invoke-RestMethod -Uri "$($netboxUrl)/api/tenancy/tenants/$($NetboxCustomer.id)/" -Method PATCH -Headers $netboxAuthenticationHeader -Body $updateData -ContentType "application/json;charset=utf-8"
    }
}