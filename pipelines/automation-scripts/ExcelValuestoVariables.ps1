<#
.SYNOPSIS
  Read Excel file and save values from it into a variable group. 
.DESCRIPTION
  This script will be used to read the downloaded excel file from the artifacts and update the variables values in the variable group.

.NOTES
  Version:        1.0
  Author:         Abaigail Rose Artagame
  Creation Date:  29/11/2022
  Purpose/Change: Initial script development


#>


#-----------------------------------------------------------[Declarations]------------------------------------------------------------
param(
  $ExcelFilePath,
  $SheetName,
  $MainVgId
)


#-----------------------------------------------------------[Functions]------------------------------------------------------------
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
#-----------------------------------------------------------[Execution]------------------------------------------------------------
#Read Excel File
$VariableNameColumn = 1
$ValueColumn = 2
$StartRow = 1
Install-Module -Name ImportExcel -Force
[array]$Data = Import-Excel -Path $ExcelFilePath -ImportColumns @($VariableNameColumn,$ValueColumn) -StartRow $StartRow -WorksheetName $SheetName


#Loop into Rows
foreach($Row in $Data)
{
    $VariableName = $Row.'Variable Name'
    $VariableValue = $Row.Value

    #Call Update-Variable

    $SaveValueToVariable = Update-Variable -VariableGroupId $MainVgId -VariableName $VariableName -VariableValue $VariableValue
    if($SaveValueToVariable -eq $false)
    {
        Write-Error "There is an error in updating the value for variable $VariableName" 
    }
    Write-Host "Updating variable $VariableName is successful."

}