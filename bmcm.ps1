param (
    [Parameter()]
    [switch]$dp,
    [Parameter()]
    [switch]$md,    
    [Parameter()]
    [string]$file,
    [Parameter()]
    [string]$world,
    [Parameter()]
    [switch]$Clear,
    [Parameter()]
    [switch]$List,
    [Parameter()]
    [switch]$MCVersions,
    [Parameter()]
    [switch]$log,
    [Parameter()]
    [switch]$help
)

$bmcmversion = "v1.0.1"
function Clear-ext {
    param (
        $fn
    )
    Remove-Item  $PSScriptRoot\ext\$fn -Recurse -Force -Confirm:$false  | out-null
}
function Add-ModLog {
    param (
        $ModName
    )
    Add-Content -Path $PSScriptRoot\logs\installed.log -Value "($(Get-Date)): $($ModName) (Minecraft) (Path: $($env:APPDATA)\.minecraft\mods\$($ModName))"
}
function Zip {
    [CmdletBinding()]
    param (
        $z
    )
    Write-Verbose ".zip found..."
    $zp = Resolve-Path -Path $z
    $zn = [System.IO.Path]::GetFileNameWithoutExtension($z)
    New-Item -Path $PSScriptRoot\ext -Name $zn -ItemType "directory"  | out-null
    Write-Verbose "Unzipping..."
    Expand-Archive -Path $zp -DestinationPath $PSScriptRoot\ext\$zn  | out-null        
    Write-Verbose "Searching for .jar..."
    # Pt. 1 : Check for .jar file in .zip archive
    $archive = @(Get-ChildItem $PSScriptRoot\ext\$zn -Filter *.jar -Recurse -File)
    if ($archive.Length -eq 0) {
        Write-Verbose "No .jar file found in this archive"
        Clear-ext $zn
        exit
    }
    Write-Verbose ".jar file found, installing..."
    # Pt. 2 : Do installation
    if (-Not (Test-Path -Path $env:APPDATA\.minecraft)) {
        Write-Host "No .minecraft folder found in $env:APPDATA"
        Clear-ext $zn
        exit
    }
    Write-Verbose ".minecraft folder found..."
    if (-Not (Test-Path -Path $env:APPDATA\.minecraft\mods)) {
        Write-Host "No mods folder found in $env:APPDATA\.minecraft, creating..."
        New-Item -Path $env:APPDATA\.minecraft -Name "mods" -ItemType "directory"  | out-null
    }
    Write-Verbose "Moving .jar to mods..."
    try {
        Move-Item -Path $archive -Destination $env:APPDATA\.minecraft\mods -ErrorAction Stop
    } catch {
        Write-Host "This mod is already installed!"
        Clear-ext $zn
        exit
    }
    Clear-ext $zn
    Write-Verbose "Cleaning ext folder..."
    Add-ModLog $zn
    Write-Host "Installation Complete!"
}
function Jar {
    [CmdletBinding()]
    param (
        $mod
    )
    Write-Verbose ".jar file detected..."
    if (-Not (Test-Path -Path $env:APPDATA\.minecraft)) {
        Write-Host "No .minecraft folder found in $env:APPDATA"
        exit
    }
    Write-Verbose ".minecraft folder found..."
    if (-Not (Test-Path -Path $env:APPDATA\.minecraft\mods)) {
        Write-Host "No mods folder found in $env:APPDATA\.minecraft, creating..."
        New-Item -Path $env:APPDATA\.minecraft -Name "mods" -ItemType "directory"  | out-null
    }
    Write-Verbose "Moving .jar to mods..."
    try {
        Move-Item -Path $mod -Destination $env:APPDATA\.minecraft\mods -ErrorAction Stop
    } catch {
        Write-Host "This mod is already installed!"
        exit
    }
    Add-ModLog $([System.IO.Path]::GetFileNameWithoutExtension($mod))
    Write-Host "Installation Complete!"
}
function Initialize-Mod {
    param (
        $m
    )
    try {
        $mp = Resolve-Path -Path $m -ErrorAction Stop
    } catch {
        Write-Host "ERROR: Mod folder or file not found! (file: $m) c: 1"
        break
    }
    if ([string]::IsNullOrEmpty($mp)) {
        exit
    }
    $e = [System.IO.Path]::GetExtension($mp)
    if ($e -ne ".jar" -and $e -ne ".zip") {
        write-host "Mod must be either a .jar or .zip"
        exit
    }
    if ($e -eq ".jar") {
        Jar $mp
        return
    }
    if ($e -eq ".zip") {
        Zip $mp
        return
    }
}
#######################################################################################
#                                       FLAGS                                         #
#######################################################################################
if ($clear) {
    Write-Verbose "Clearing Installation log..."
    Clear-Content -Path $PSScriptRoot\logs\installed.log
    Add-Content -Path $PSScriptRoot\logs\installed.log -Value "-- START OF INSTALLED LOG FOR Bear's Mod Manager --"
    Write-Host "Installation log cleared!"
    return
}
if ($List) {
    Write-Host "Currently installed mods:"
    Write-Host @(Get-ChildItem $env:APPDATA\.minecraft\mods -Recurse -File).Length
    return
}
if ($MCVersions) {
    Write-Host "Currently installed versions:"
    Get-ChildItem "$env:APPDATA\.minecraft\versions" -directory | Select-Object FullName
    return
}

if ($dp) {
    if (![string]::IsNullOrEmpty($file)) {
        if (![string]::IsNullOrEmpty($world)) {
            Write-Host "Install DP"
            Write-Host "file: $($file) world: $($world)"
        } else {
            Write-Host "No world specified"
        }
    } else {
        Write-Host "No datapack specified"
    }
}

if ($md) {
    if (![string]::IsNullOrEmpty($file)) {
        Initialize-Mod $file
    } else {
        Write-Host "No mod specified"
    }
}
if ($log) {
    Write-Host $(Get-Content $PSScriptRoot\logs\installed.log)
}