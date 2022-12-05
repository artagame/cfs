<#
.SYNOPSIS
  Download excel file attachment from a work item.
.DESCRIPTION
  This script will be used to download an excel file from an Azure DevOps workitem which contains the values needed to run the main pipeline.

.NOTES
  Version:        1.0
  Author:         Abaigail Rose Artagame
  Creation Date:  29/11/2022
  Purpose/Change: Initial script development


#>


#-----------------------------------------------------------[Declarations]------------------------------------------------------------
param(
  $SubscriptionId,
  $PAT,
  $MainVgId,
  $FileName
)


#-----------------------------------------------------------[Functions]------------------------------------------------------------
Function Get-RunId{
  <#
        .SYNOPSIS
        Returns the latest subscription run id.

        .DESCRIPTION
        Returns the latest subscription run id.

        .PARAMETER SubsriptionId
        Id of the Service Hook Subscription.

        .PARAMETER PAT
        Personal Access Token used for Authentication. 
        
    #>
  Param(

    $SubscriptionId,
    $PAT

  )
  Begin{
    Write-Host "Getting run history for id: $SubscriptionId..."
  }
  Process
  {
    Try{
     
      # Create header with PAT
      $token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($PAT)"))

      $header = @{authorization = "Basic $token"}

      $getRunHistoryApi = "$($env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI)_apis/hooks/notificationsquery?api-version=7.1-preview.1"

      $getRunHistoryReqBod = '
      {
          "subscriptionIds": ["--SUBSCRIPTIONID--"]
      }'

      $getRunHistoryReqBod = $getRunHistoryReqBod.Replace("--SUBSCRIPTIONID--", $SubscriptionId)

      $getRunHistory = Invoke-RestMethod -Uri $getRunHistoryApi -Method Post -Headers $header -Body $getRunHistoryReqBod -ContentType 'application/json' -ErrorAction Stop

      return $getRunHistory.results[0].id

    }
    Catch
    {
      Write-Host $_.exception
      return $null
    }
  }
  End{}
}
Function Get-WorkItemId{
  <#
        .SYNOPSIS
        Returns the work item id that triggered the service hook.

        .DESCRIPTION
        Returns the work item id that triggered the service hook.

        .PARAMETER SubsriptionId
        Id of the Service Hook Subscription.

        .PARAMETER RunId
        Id of the latest Service Hook Subscription Run.     

        .PARAMETER PAT
        Personal Access Token used for Authentication. 
    #>
  Param(

    $SubscriptionId,
    $RunId,
    $PAT

  )
  Begin{
    Write-Host "Getting work item id..."
  }
  Process
  {
    Try{

      # Create header with PAT
      $token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($PAT)"))

      $header = @{authorization = "Basic $token"}

      $getWorkItemIdApi = "$($env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI)_apis/hooks/subscriptions/$SubscriptionId/notifications/$RunId" + "?api-version=7.1-preview.1"
      $getworkItemId = Invoke-RestMethod -Uri $getWorkItemIdApi -Method Get -Headers $header -ErrorAction Stop
      
      return $getworkItemId.details.event.resource.id

    }
    Catch
    {
      Write-Host $_.exception
      return $null
    }
  }
  End{}
}
Function Update-Variable{
  <#
        .SYNOPSIS
        Save Work Item Id as variable in a Variable Group

        .DESCRIPTION
        Save Work Item Id as variable in a Variable Group

        .PARAMETER VariableGroupId
        Variable Group Id

        .PARAMETER VariableName
        Variable Name to be updated

        .PARAMETER VariableValue
        Variable value 
    #>
  Param(

    $VariableGroupId,
    $VariableName,
    $VariableValue

  )
  Begin{
    Write-Host "Updating Variable $VariableName..."
  }
  Process
  {
    Try{
      az devops login
      az pipelines variable-group variable update --group-id $VariableGroupId --name $VariableName --value $VariableValue --org $($env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI) --project $env:SYSTEM_TEAMPROJECTID

      return $true
    }
    Catch
    {
      Write-Host $_.exception
      return $false
    }
  }
  End{}
}
Function Get-AttachmentDownloadUrl{
  <#
        .SYNOPSIS
        Gets the attachment download url.

        .DESCRIPTION
        Gets the attachment download url.

        .PARAMETER WorkItemId
        Work Item Id.

        .PARAMETER FileName
        Name of the Work Item File.

        .PARAMETER PAT
        Personal Access Token used for Authentication. 

    #>
  Param(

    $WorkItemId,
    $FileName,
    $PAT

  )
  Begin{
    Write-Host "Getting the attachment download url..."
  }
  Process
  {
    Try{

      # Create header with PAT
      $token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($PAT)"))
      $header = @{authorization = "Basic $token"}
      
      $getAttDlUrlApi = "$($env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI)$env:SYSTEM_TEAMPROJECTID/_apis/wit/workitems/$WorkItemId" + '?$expand=all&api-version=7.1-preview.3'

      $getAttDlUrl = Invoke-RestMethod -Uri $getAttDlUrlApi -Method Get -Headers $header -ErrorAction Stop

      $getAttDlUrlRes = $getAttDlUrl.relations | Where-Object{$_.attributes.name -eq $FileName}

      return $getAttDlUrlRes.url
    }
    Catch
    {
      Write-Host $_.exception
      return $null
    }
  }
  End{}
}
Function Download-Attachment{
  <#
        .SYNOPSIS
        Downloads the work item attachment

        .DESCRIPTION
        Downloads the work item attachment

        .PARAMETER AttachmentDownloadUrl
        Attachment Download Url

        .PARAMETER FileName
        Attachment File Name

        .PARAMETER PAT
        Personal Access Token used for Authentication. 

    #>
  Param(

    $AttachmentDownloadUrl,
    $FileName,
    $PAT

  )
  Begin{
    Write-Host "Downloading the attachment..."
  }
  Process
  {
    Try{

      # Create header with PAT
      $token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($PAT)"))

      $header = @{authorization = "Basic $token"}

      $getAttDlUrl = Invoke-WebRequest -Uri $AttachmentDownloadUrl -Method Get -Headers $header -ErrorAction Stop
      [System.IO.File]::WriteAllBytes($FileName, $getAttDlUrl.Content)

      return $true
    }
    Catch
    {
      Write-Host $_.exception
      return $false
    }
  }
  End{}
}


#-----------------------------------------------------------[Execution]------------------------------------------------------------
#Call Get-RunId Function
$RunId = Get-RunId -SubscriptionId $SubscriptionId -PAT $PAT
if($RunId -eq $null)
{
  Write-Error "There is an error in getting the service hook subscription latest run id." 
}

#Call Get-WorkItemId Function
$WorkItemId = Get-WorkItemId -SubscriptionId $SubscriptionId -RunId $RunId -PAT $PAT
if($WorkItemId -eq $null)
{
  Write-Error "There is an error in getting the work item id." 
}

#Call Update-Variable
$SaveWorkItemId = Update-Variable -VariableGroupId $MainVgId -VariableName "WorkItemId" -VariableValue $WorkItemId
if($SaveWorkItemId -eq $false)
{
  Write-Error "There is an error in updating the value for variable WorkItemId." 
}

#Call Get-AttachmentDownloadUrl Function
$AttachmentDownloadUrl = Get-AttachmentDownloadUrl -WorkItemId $WorkItemId -FileName $FileName -PAT $PAT
if($AttachmentDownloadUrl -eq $null)
{
  Write-Error "There is an error in getting the attachment download url." 
}

#Call Download-Attachment Function
$DownloadAttachment = Download-Attachment -AttachmentDownloadUrl $AttachmentDownloadUrl -FileName $FileName -PAT $PAT
if($DownloadAttachment -eq $false)
{
  Write-Error "There is an error in downloading the attachment." 
}
Write-Host "The attachment have been downloaded." 
