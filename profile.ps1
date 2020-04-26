Push-Location (Split-Path -Path $MyInvocation.MyCommand.Definition -Parent)
$LocalCacheFolder = "C:\Source\Repos\Powershell"
$PSCodeRoot = "."
$HasLocalCache = Test-Path "C:\Source\Repos\Powershell"

if ($HasLocalCache)
{
  $PSCodeRoot= $LocalCacheFolder 

  #TODO: Check if local profile.ps1 matches that in PSCodeRoot
}
else
{
#TODO: Cleanup logic.
  $LocalCacheFolder = "D:\Source\Repos\Powershell"
  $PSCodeRoot = "."
  $HasLocalCache = Test-Path "D:\Source\Repos\Powershell"
  $PSCodeRoot= $LocalCacheFolder 
}

. $PSCodeRoot/scripts/Config.ps1

# Git utils
. $PSCodeRoot/scripts/GitUtils.ps1
. $PSCodeRoot/scripts/GitPrompt.ps1

# Use Git tab expansion
. $PSCodeRoot/scripts/GitTabExpansion.ps1

# SetConsoleIcon
. $PSCodeRoot/scripts/Set-ConsoleIcon.ps1

# Set up a simple prompt, adding the git prompt parts inside git repos
function prompt {
	$prefix = ""
    if ( Elevated-Credentials -eq $true )
    {
        $prefix = 'Elevated Prompt: '
    }
    
	$date = date
	$userLocation = '['+[System.Environment]::MachineName + '] ' + $pwd	
	$topline = [System.Environment]::MachineName + ' ' + $date
	
	$host.UI.RawUi.WindowTitle = $prefix + $userLocation
    
	Write-Host($topline) -foregroundcolor Green
    Write-Host($pwd) -nonewline -foregroundcolor Green
    
    # Git Prompt
    $Global:GitStatus = Get-GitStatus
    
	Write-Host('>') -nonewline -foregroundcolor Green	
	return " "
}

#if(-not (Test-Path Function:\DefaultTabExpansion)) {
#    Rename-Item Function:\TabExpansion DefaultTabExpansion
#}

# Set up tab expansion and include git expansion
#function TabExpansion($line, $lastWord) {
 #   $lastBlock = [regex]::Split($line, '[|;]')[-1]
    
  #  switch -regex ($lastBlock) {
        # Execute git tab completion for all git-related commands
   #     'git (.*)' { GitTabExpansion $lastBlock }
        
        # Fall back on existing tab expansion
    #    default { DefaultTabExpansion $line $lastWord }
   # }
#}

function PS_Ctor
{
	## Set Powershell variables here
	##Set-Variable -name ScriptPath -value (Script_Path 'Scripts') -option Constant -scope Global -description "Home directory for Scripts"
	#Set-Variable -name ModulePath -value (Script_Path 'Modules') -option Constant -scope Global -description "Home directory for Modules"
	##Set-Variable -name TestPath -value (Script_Path 'Test-Scripts') -option Constant -scope Global -description "Home directory for Test scripts"
	
	## Add $ScriptPath to NT's Path Enviroment variable so these can be easily ran from the shell
	$env:path += ';' + $ScriptPath # + ';' + $ModulePath
	
	##  EV is used to give Powershell the equivalent of setlocal/endlocal that the NT shell has
	[System.Collections.Stack]$Global:EV = New-Object -typeName System.Collections.Stack
	Set-Variable -name EV -scope Global -description "Used by Set-Local/End-Local (For Internal use only)"
	
	Register-DefaultAliases
	Register-DefaultDrives
	#Import-DefaultModules  
}  ## End of PS_Ctor

PS_Ctor

Enable-GitColors

#Glass

Pop-Location

## Clean up
Remove-Item Function:PS_Ctor