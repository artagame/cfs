<#
.SYNOPSIS
  Update work item state and add comment
.DESCRIPTION
  This script will be used to update a work item state and add a new comment to it. 

.NOTES
  Version:        1.0
  Author:         Abaigail Rose Artagame
  Creation Date:  29/11/2022
  Purpose/Change: Initial script development


#>


#-----------------------------------------------------------[Declarations]------------------------------------------------------------
param(
  $WorkItemId,
  $PAT,
  $WorkItemState,
  $WorkItemComment
)


#-----------------------------------------------------------[Functions]------------------------------------------------------------
Function Update-WorkItemState{
  <#
        .SYNOPSIS
        Updates work item state.

        .DESCRIPTION
        Updates work item state.

        .PARAMETER WorkItemId
        ID of the Work Item to be updated.

        .PARAMETER PAT
        Personal Access Token used for Authentication. 

        .PARAMETER WorkItemState
        New Work Item State        
    #>
  Param(

    $WorkItemId,
    $PAT,
    $WorkItemState

  )
  Begin{
    Write-Host "Updating Work Item $WorkItemId..."
  }
  Process
  {
    Try{
     
      # Create header with PAT
      $token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($PAT)"))

      $header = @{authorization = "Basic $token"}

      $updateWorkItemApi = "$($env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI)_apis/wit/workitems/$WorkItemId" + "?api-version=7.1-preview.3"

      $updateWorkItemReqBod = '
      [
        {
          "op": "add",
          "path": "/fields/System.State",
          "value": "--WORKITEMSTATE--"
        }
      ]'

      $updateWorkItemReqBod = $updateWorkItemReqBod.Replace("--WORKITEMSTATE--", $WorkItemState)

      $updateWorkItem = Invoke-RestMethod -Uri $updateWorkItemApi -Method Patch -Headers $header -Body $updateWorkItemReqBod -ContentType 'application/json-patch+json' -ErrorAction Stop

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
Function Add-WorkItemComment{
  <#
        .SYNOPSIS
        Add a new comment to a work item.

        .DESCRIPTION
        Add a new comment to a work item.

        .PARAMETER WorkItemId
        ID of the Work Item to be updated.

        .PARAMETER PAT
        Personal Access Token used for Authentication. 

        .PARAMETER WorItemComment
        New Work Item Comment        
        
    #>
  Param(

    $WorkItemId,
    $PAT,
    $WorItemComment

  )
  Begin{
    Write-Host "Updating Work Item $WorkItemId..."
  }
  Process
  {
    Try{
     
      # Create header with PAT
      $token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($PAT)"))

      $header = @{authorization = "Basic $token"}

      $addWorkItemCommentApi = "$($env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI)$env:SYSTEM_TEAMPROJECTID/_apis/wit/workItems/$WorkItemId" + "/comments?api-version=7.0-preview.3"

      $addWorkItemCommentReqBod = '
        {
          "text": "--WORKITEMCOMMENT--"
        }'

      $addWorkItemCommentReqBod = $addWorkItemCommentReqBod.Replace("--WORKITEMCOMMENT--", $WorItemComment)

      $addWorkItemComment = Invoke-RestMethod -Uri $addWorkItemCommentApi -Method Post -Headers $header -Body $addWorkItemCommentReqBod -ContentType 'application/json' -ErrorAction Stop

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
#Call Update-WorkItemState
#Change Task State from To DO to In Progress

$UpdateWorkItemState = Update-WorkItemState -WorkItemId $WorkItemId -PAT $PAT -WorkItemState $WorkItemState
if($UpdateWorkItemState -eq $false)
{
  Write-Error "There is an error in updating the work item state." 
}
Write-Host "Updating work item state for $WorkItemId is successful."

#Call Add-WorkItemComment
#Add Comments to Task
Write-Host $WorItemComment
$addWorkItemComment = Add-WorkItemComment -WorkItemId $WorkItemId -PAT $PAT -WorItemComment $WorkItemComment
if($addWorkItemComment -eq $false)
{
  Write-Error "There is an error in adding a new the work item comment." 
}
Write-Host "Added work item comment for $WorkItemId is successful."
