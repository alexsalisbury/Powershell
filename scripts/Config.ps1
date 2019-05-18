## Standard Drives
function Register-DefaultDrives{
	New-PSDrive -name MyDocs -psprovider FileSystem -root (My_Docs) -scope Global | Out-Null
	New-PSdrive -name scripts -PSprovider filesystem -root $ScriptPath -scope Global | Out-Null
	
	$ScratchDef = 'Scratch for user files'
	#New-PSdrive -Name Scratch -Description $ScratchDef -PSProvider FileSystem -Root \\server\folder\psscratch -scope Global | Out-Null
}

function Register-DefaultAliases {
# Set Alias's here
	$Scripts = @(@{n = 'sh';v = 'Search-History'},@{n = 'pwd';v = 'Get-CurrentLocation'}, @{n = 'ren';v = 'rename'}, @{n = 'ss';v = 'Select-String'} )
    $Scripts | ForEach {
        Set-Alias -name $_.n  -value $_.v  –Option  AllScope,Constant –Scope Global
    }
}

## Pushes the current environment variables onto a stack so that the can be retrieved later
function Set-Local
{
   Get-ChildItem env: | ForEach { $envhash = @{} } { $envhash[$_.name] = $_.value } { $EV.push($envhash) }
}

## Destroys the current environment variables and loads the previous environment set with Set-Local
function End-Local
{
   if ($EV.Count -gt 0)
   {
      del env:*
      $envhash = $EV.pop()
      $envhash.keys | ForEach { Set-Content env:$_ $envhash[$_] }
   }
}

## Defines ScriptPath to add scripts to Path
function Script_Path
{
	if ($HasLocalCache)
	{
		$ScriptHome = $LocalCacheFolder
	}
	else
	{
    	$ScriptHome = Split-Path -path $Profile -parent
    }
    
    $ScriptHome += '\' + $args[0]
    $ScriptHome
}

## Helper to MyDocuments
function My_Docs
{
    $Documenthome = Split-Path -path $Profile -parent
    $Documenthome = $Documenthome.Remove($Documenthome.LastIndexOf('\'))
    $Documenthome
}

function Get-Batchfile ($file) 
{
    $cmd = "`"$file`" & set"
    cmd /c $cmd | Foreach-Object {
            $p, $v = $_.split('=')
            Set-Item -path env:$p -value $v
    }
}

function Register-TFSModule
{ 
	Add-PSSnapin Microsoft.TeamFoundation.PowerShell    
}
	

## Modified from Scott Hanselman's original
## http://www.hanselman.com/blog/AwesomeVisualStudioCommandPromptAndPowerShellIconsWithOverlays.aspx
function Set-VSMode($version = "9.0")
{ 
	# 32 bit is top line. x64 is next.
	#$key = "HKLM:SOFTWARE\Microsoft\VisualStudio\" + $version
	$key = "HKLM:SOFTWARE\Wow6432Node\Microsoft\VisualStudio\" + $version
	
    $VsKey = get-ItemProperty $key
    $VsInstallPath = [System.IO.Path]::GetDirectoryName($VsKey.InstallDir)
    $VsToolsDir = [System.IO.Path]::GetDirectoryName($VsInstallPath)
    $VsToolsDir = [System.IO.Path]::Combine($VsToolsDir, "Tools")
    $BatchFile = [System.IO.Path]::Combine($VsToolsDir, "vsvars32.bat")
    [System.Console]::Title = "Visual Studio " + $version + " Windows Powershell"
    $iconpath = $ScriptPath+"\icons\vspowershell.ico"
    Set-ConsoleIcon $iconpath
    
    # add mstest to path
    # C:\Program Files (x86)\Microsoft Visual Studio 9.0\Common7\IDE
    $env:Path += ";C:\Program Files (x86)\Microsoft Visual Studio 9.0\Common7\IDE"
}

##http://poshcode.org/2052
#requires -version 2
function Glass([switch]$Disable)
{
	## defines a new type inline. Could be cleaned up.
	add-type -namespace Hacks -name Aero -memberdefinition @"
	
    [StructLayout(LayoutKind.Sequential)]
    public struct MARGINS
    {
       public int left; 
       public int right; 
       public int top; 
       public int bottom; 
    } 

    [DllImport("dwmapi.dll", PreserveSig = false)]
    public static extern void DwmExtendFrameIntoClientArea(IntPtr hwnd, ref MARGINS margins);

    [DllImport("dwmapi.dll", PreserveSig = false)]
    public static extern bool DwmIsCompositionEnabled();
"@
	
	if (([Environment]::OSVersion.Version.Major -gt 5) -and
	     [hacks.aero]::DwmIsCompositionEnabled()) {
	
	   $hwnd = (get-process -id $pid).mainwindowhandle
	
	   $margin = new-object 'hacks.aero+margins'
	
	   $host.ui.RawUI.BackgroundColor = "black"
	   $host.ui.rawui.foregroundcolor = "white"
	
	   if ($Disable) {
	
	       $margin.top = 0
	       $margin.left = 0
	
	
	   } else {
	
	       $margin.top = -1
	       $margin.left = -1
	
	   }
	
	   [hacks.aero]::DwmExtendFrameIntoClientArea($hwnd, [ref]$margin)
	
	} 
	else 
	{
	   write-warning "Aero is either not available or not enabled on this workstation."
	}
}

function Shatter()
{
	Glass -Disable
}

function GetWinInetProxy()
{
	$path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
	(Get-ItemProperty $path).ProxyOverride;
}

function SetWinInetProxy()
{
	#$path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
	#$override = "*.domain.com;"+ (Get-ItemProperty $path).ProxyOverride;
	#Set-ItemProperty $path ProxyOverride $override
}

function GetWinHttpProxy()
{
	(netsh winhttp dump -Split \"/r\")
}

function SetWinHttpProxy()
{
   netsh winhttp set proxy proxy-server="server.domain.com" bypass-list="*.example.com;*.domain.com;";
}

function ImportIEProxy
{
	netsh winhttp import proxy source =ie;
}

function ResetWinHttpProxy
{
	netsh winhttp reset proxy
}

## Standard Aliases
#function Register-DefaultAliases {
## Set Alias's here
#	$Scripts = @(@{n = 'sh';v = 'Search-History'},@{n = 'pwd';v = 'Get-CurrentLocation'}, @{n = 'ren';v = 'rename'}, @{n = 'ss';v = 'Select-String'} )
#    $Scripts | ForEach {
#        Set-Alias -name $_.n  -value $_.v  –Option  AllScope,Constant –Scope Global
#    }
#}

## Standard Modules
#function Import-DefaultModules
#{
	#$Modules = 'Example'
	#$Modules | ForEach {
	#   Write-Host "Importing the following modules $_"
	#    Import-Module -Name $_  #-Verbose
	#}
	#

	#Import-Module $PscxPath\Pscx
	
	# Import the Pscx.Deprecated module only if you need PSCX's Start-Process, 
	# Select-Xml and Get-Random cmdlets instead of PowerShell's built-in version
	# of these cmdlets.
	#Import-Module Pscx.Deprecated 
#}