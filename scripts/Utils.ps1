# General Utility Functions
function Coalesce-Args 
{
    $result = $null
    foreach($arg in $args) {
        if ($arg -is [ScriptBlock]) {
            $result = & $arg
        } else {
            $result = $arg
        }
        if ($result) { break }
    }
    $result
}
Set-Alias ?? Coalesce-Args

## 'Short-Cuts' for Editing common files
#function Edit-Profile { Smart-Edit c:\windows\system32\drivers\etc\hosts  }

function Edit-Hosts { Smart-Edit c:\windows\system32\drivers\etc\hosts  }

## Editor Helpers.
function Detect-EInstalled 
{
	Test-path $home\appdata\roaming\e
}

function Smart-Edit ([string] $s)
{
	if (Detect-EInstalled) {
		e $s
	}
	else {
 		notepad $s
 	}
}

## Gets the list of installed programs from the registry. Not perfect.
function Get-InstalledPrograms 
{
	$Keys = Get-ChildItem HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall
 	$Items = $keys |foreach-object {Get-ItemProperty $_.PsPath}
 	$Names = $items | foreach-object {$_.DisplayName}
 	$Names
}


## Returns TRUE if the user is running with Admin credentials
function Elevated-Credentials
{
    $CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = new-object System.Security.principal.windowsprincipal($CurrentUser)
    $principal.IsInRole("Administrators") -eq $true
}

##
## Helper function for searching Powershells "about_* files
##
function Search-Help ([string] $s)
{
    Get-ChildItem $PSHome\en-US\*.txt | Select-String $s | Out-Host -paging
}

##
## Checks to see if a given Cmdlet or Function has an alias
##
function Has-Alias ([string] $name)
{
    Get-Alias | Where {$_.ResolvedCommand -like "*$name*"} | ForEach { Write-Host "The alias for $($_.ResolvedCommand) is $($_.Name)" }
}

##
## Returns a list of recently ran commands that match the argument supplied
##
function Search-History
{
    $cmd = $args[0];
    Get-History | Where {$_.CommandLine -like "$cmd*"}
}

## Resolves the OS path from the PSDrive
function Get-NativePath ([string] $path = $(throw 'drive must be specified') )
{
    if ( (Test-Path $path) -eq $false)
    {
        Write-Host "$($path) is not valid. check and call again"
        $null
    }
    else
    {
        $root = Split-Path -path (Resolve-Path -path $path) -qualifier
        $folder = Split-Path -path (Resolve-Path -path $path) -noQualifier
        $root = $root | ForEach { (Get-PsDrive $_.TrimEnd(':')).Root.TrimEnd('\') }
        if ($root.Count -gt 0)
        {
            for ($i=0; $i -le $root.Count; $i++)  {$root[$i] + $folder[$i]}
        }
        else
        {
            $root + $folder
        }
    }
}

## This behves like native CD it does not shift the focus to the new drive
function Move-Location([string] $path = $(throw 'drive must be specified'), [switch] $CD)
{
    if ($CD -eq $true)
    {
         Set-Location ($path + $args)
    }
    else
    {
        $root = Split-Path -path (Resolve-Path -path $path) -qualifier
        $folder = Split-Path -path (Resolve-Path -path $path) -noQualifier
        (Get-PsDrive $root.TrimEnd(':')).CurrentLocation = $folder
    }
}

## This behaves like the native PWD or CD (without a path) It will print out the current directory in the drive specified
function Get-CurrentLocation([string] $drive = '.', [switch] $Native)
{
    if ($Native)
    {
         (resolve-path $drive).ProviderPath
    }
    else
    {
        (resolve-path $drive).Path
    } 
}

## This behaves like the native rename it accepts wildcards and the current directory as part of the filename
function rename([string] $from = $(throw 'file must be specified'), [string] $to = $(throw 'file must be specified') )
{
    [io.fileinfo[]] $f = split-path (resolve-path $from) -Leaf

    switch -regex ($to)
    {

    '\*\.(?<Extension>.+)'    {$f | % { Rename-Item $_ ($_.BaseName + '.' + $matches['Extension']) }; break}
    '(?<BaseName>[^.*]+)\.\*' {$f | % { Rename-Item $_ ($matches['BaseName'] + $_.Extension) }; break}
    default                   {Rename-Item (split-Path $from -Leaf) (Split-Path $to -Leaf) ; break}
    }
}

## This function will process in a *.bat/*.cmd script and serialize the enviroment variables set with that script into the PS shell
function Set-Env ([string] $cmd, [switch] $Append)
{
   if ($cmd -match '[^=]+=[^=]+')
   {
      $p,$v = $cmd.Split('=') | ForEach {$_.Trim()} | ForEach {$_.Trim("'`"")}
      if ($Append)
      {
   		 set-item -path env:$p -value ((get-env $p).Value + ';' + $v)
      }
      else
      {
   		 Set-Item -path env:$p -value $v
      }
      
      return     
   }

## Powershell will flatten out the command line into one string which will break the batch file being processed
   $arg_array = $args[0] | % {$_}

## This will first execute the batch file and then use SET to dump out the new environment settings.
## The ouput of that is passed on to Powershell which adds these into the Powershell host process.
##
## This is a slight variation to what is in Bruce Payette's book. The difference is both command
## extensions and delayed environment variable expansion is turned on which is required for some
## batch files like the Windows SDK.

# The Windows 7 SDK breaks without command extenstions
#
   cmd /v:on /e:on /c "$cmd" $arg_array `& set | Foreach-Object {

        $p,$v = $_.split('=')

       if ( $v -eq $null )
            {Write-Host $p }

       if ( $p -ne $null -and $v -ne $null )
       {
            Set-Item -path env:$p -value $v
       }
    }
}

function Get-Env([string] $name = '*')
{
     Get-ChildItem env:$name | Sort -Prop Name
}

function Print-Path()
{
    $env:path.Split(';')
}

function Set-Attributes ([string[]] $filenames = $(throw 'file must be specified'), [string[]] $Attrcol = $(throw 'attributes must be specified') )
{
    [io.fileinfo[]] $files = Get-ChildItem -Force -Path $filenames

    $fileattributes = @{R=[io.fileattributes]::ReadOnly;H=[io.fileattributes]::Hidden;A=[io.fileattributes]::Archive; `
                      N=[io.fileattributes]::Normal;S=[io.fileattributes]::System}

    $fileAttributes.Values | % {[int]$allAttributes += $_}

    foreach ($file in $files)
    {
        foreach ($attr in $Attrcol)
        {
            if ($attr[0] -eq '~')
            {
                $file.Attributes = $file.Attributes -band ($allAttributes -bxor $fileattributes[$attr[1].ToString()])     
            }
            elseif ($attr[0] -eq '+')
            {
                $file.Attributes = $file.Attributes -bor $fileattributes[$attr[1].ToString()]
            }
            else
            {
                Write-Warning "Invalidformat $attr"
            }
        }
    }   
}

########################## Wrappers for several standard utilities so the can be used with PSDrives ###################
function findstr() 
{
   if ($args[0].StartsWith('/') )
   {
       findstr.exe $args[0] (Convert-Path $args[1]) (Convert-Path $args[2])
   }
   else
   {
       findstr.exe (Convert-Path $args[0]) (Convert-Path $args[1])
   }
}

function windiff() 
{
   if ($args[0] -eq $null -and $args[1] -eq $null)
   {
      windiff.exe
   }
   else
   {
      windiff.exe (Convert-Path $args[0]) (Convert-Path $args[1])
   }
}

function explorer() 
{
   invoke-item (Convert-Path $args[0])
}

function Sync-ScriptsToLocal
{
#	Copy-Item d:\source\repos c:\LocalPowershellCache
}

function notepad([string] $file = '') 
{
   if ($file -eq '')
   {
       notepad.exe
   }
   else 
   {
       $root = split-path -Parent -Path $file
       if ($root -eq '') 
       {
          $root = '.'
       }
       notepad.exe ((convert-path $root) + '\' + (split-path -Leaf -Path $file))
   }
}