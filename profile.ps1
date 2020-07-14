Write-Host "Building..."
Push-Location (Split-Path -Path $MyInvocation.MyCommand.Definition -Parent)

# Set up a simple prompt, adding the git prompt parts inside git repos
function prompt {
    $HasErrors = Check-Errors
	$prefix = ""
    $postfix = '>'
  #  if ( Elevated-Credentials -eq $true )
  #  {
  #      $prefix = 'Elevated Prompt: '
  #      $postfix = '!'+$postfix
  #  }
    
    if ($HasErrors)
    {
        $postfix = '?'+$postfix
    }

	$date = date
	$userLocation = '['+[System.Environment]::MachineName + '] ' + $pwd	
	$topline = [System.Environment]::MachineName + ' ' + $date
	
	$host.UI.RawUi.WindowTitle = $prefix + $userLocation
    
	Write-Host $topline -foregroundcolor Green
    Write-Host $pwd -nonewline -foregroundcolor Green
    
    # Git Prompt
   # $Global:GitStatus = Get-GitStatus
    #$Global:AzureResources = Load-AzureResources
    
	Write-Host $postfix -nonewline -foregroundcolor Green	
	return " "
}

###Initialize this before prompt() is run. Preferably in PS ctor.
function Build-PSEnvironment(){
    $HasEnvVars = Test-Path "A:\Set-SHVars.ps1"

    if ($HasEnvVars)
    {
        # DotSource me plz. 
        . A:\Set-SHVars.ps1
    
        Write-Host "Configuring Household settings."
        Set-GlobalVars

        if ($HasLocalPSCache)
        {
            Write-Host "Configuring Developer settings."
            Set-DevVars
        }

        return $true
    }
    else
    {
        Write-Host "Failed to load env vars from Azure FileShare" -ForegroundColor Red
    }
        
    return $false
}

function Check-Errors()
{
    #return error collection .Any()
    return $false;
}

### Runs in profile()
function Load-AzureResources
{
    if(Test-Path $AzureResourcesFile)
    {
        return Get-Content -Raw -Path $AzureResourcesFile | ConvertTo-Json
    }
    else
    {
        Write-Host "Azure Resources not loaded" -ForegroundColor Yellow
    }
}

function PS_Ctor
{
    Write-Host "Running ctor"
	## Set Powershell variables here
	##Set-Variable -name ScriptPath -value (Script_Path 'Scripts') -option Constant -scope Global -description "Home directory for Scripts"
	#Set-Variable -name ModulePath -value (Script_Path 'Modules') -option Constant -scope Global -description "Home directory for Modules"
	##Set-Variable -name TestPath -value (Script_Path 'Test-Scripts') -option Constant -scope Global -description "Home directory for Test scripts"
	
	## Add $ScriptPath to NT's Path Enviroment variable so these can be easily ran from the shell
	#$env:path += ';' + $ScriptPath # + ';' + $ModulePath
	
	##  EV is used to give Powershell the equivalent of setlocal/endlocal that the NT shell has
	[System.Collections.Stack]$Global:EV = New-Object -typeName System.Collections.Stack
	Set-Variable -name EV -scope Global -description "Used by Set-Local/End-Local (For Internal use only)"
	
	#Register-DefaultAliases
	#Register-DefaultDrives
	#Import-DefaultModules  
    $Global:PSCtorSuccess = Build-PSEnvironment
}  ## End of PS_Ctor

PS_Ctor

Pop-Location

## Clean up
Remove-Item Function:PS_Ctor