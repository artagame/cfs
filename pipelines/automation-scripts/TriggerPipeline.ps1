<#
.SYNOPSIS
 Trigger a pipeline.
.DESCRIPTION
  This script will be used to trigger an existing Azure DevOps pipeline.


.NOTES
  Version:        1.0
  Author:         Abaigail Rose Artagame
  Creation Date:  29/11/2022
  Purpose/Change: Initial script development


#>


#-----------------------------------------------------------[Declarations]------------------------------------------------------------
param(
  $PipelineId,
  $PAT
)

#-----------------------------------------------------------[Functions]------------------------------------------------------------
Function Run-Pipeline{
  <#
        .SYNOPSIS
        Triggers an existing pipeline.

        .DESCRIPTION
        Triggers an existing pipeline.

        .PARAMETER PipelineId
        ID of the Pipeline to be triggered.

        .PARAMETER PAT
        Personal Access Token used for Authentication.      
    #>
  Param(

    $PipelineId,
    $PAT
  )
  Begin{
    Write-Host "Triggering Pipeline $PipelineId..."
  }
  Process
  {
    Try{
     
      # Create header with PAT
      $token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($PAT)"))

      $header = @{authorization = "Basic $token"}

      $triggerPipelineApi = "$($env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI)$env:SYSTEM_TEAMPROJECTID/_apis/pipelines/$PipelineId/runs" + "?api-version=7.1-preview.1"
      
      $triggerPipelineReqBod = '
        {
        }'

      $triggerPipeline = Invoke-RestMethod -Uri $triggerPipelineApi -Method Post -Headers $header -Body $triggerPipelineReqBod -ContentType 'application/json' -ErrorAction Stop

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
#Call Run-Pipeline

$TriggerPipeline = Run-Pipeline -PipelineId $PipelineId -PAT $PAT
if($TriggerPipeline -eq $false)
{
  Write-Error "There is an error in triggering the pipeline." 
}
Write-Host "Triggered the pipeline successfully."
