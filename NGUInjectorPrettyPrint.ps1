param ($LogFile = $args[0], $DisplayMode = $args[1], $p_LineFilter = $args[2])

# Fix for $host.ui.RawUI.WindowTitle = $BaseFile + ' Parser' Exception
if ($PSVersionTable.PSversion.major -lt 7) {
    Write-Host "Requires PowerShell v7"
    exit
}

$configFullPath = "$PSScriptRoot\ParseNGUInjector_tools.ps1"
Import-Module -Force $configFullPath

try {
    if ($p_LineFilter -and $p_LineFilter -ne "") {
        $p_LineFilter = $p_LineFilter.TrimStart("*").TrimEnd("*")
        $p_LineFilter = "*"+$p_LineFilter+"*"
    }
    else {
        $p_LineFilter = $null
    }

    CheckColoursFile

    $StopWatch = New-Object -TypeName System.Diagnostics.StopWatch
    $ActiveSettings = [LogParserSettings]::new()
    $ActiveSettings.LineFilter = $p_LineFilter
    $ParsedLine = [LogLine]::new()

    $ValidFiles = @("inject.log", "pitspin.log", "loot.log")
    $ValidModes = @("full", "tail")

    $RanFromParam = $false

    $Old_Title = $host.ui.RawUI.WindowTitle

    if ($LogFile -and $LogFile -in $ValidFiles) {
        $BaseFile = $LogFile
        if ($DisplayMode -and $DisplayMode -in $ValidModes) {
            $FileName = $Env:Userprofile + "\Desktop\NGUInjector\logs\" + $BaseFile

            $RanFromParam = $true

            $host.ui.RawUI.WindowTitle = $BaseFile + ' Parser'

            if ($DisplayMode -eq $ValidModes[0]) {
                if ($ActiveSettings.LineFilter) {
                    Get-Content $FileName | where-object {$_ -like $ActiveSettings.LineFilter} | ForEach-Object { ProcessLines }
                }
                else{
                    Get-Content $FileName | ForEach-Object { ProcessLines }
                }
            }
            else {
                if ($ActiveSettings.LineFilter){
                    Get-Content $FileName -Tail 30 -Wait | where-object {$_ -like $ActiveSettings.LineFilter} | ForEach-Object { ProcessLines }
                }
                else{
                    Get-Content $FileName -Tail 30 -Wait | ForEach-Object { ProcessLines }
                }
            }
        }
    }
    if ($RanFromParam) {
        Read-Host -Prompt "Press Enter to Exit" -MaskInput
    }
    else {
        run
    }
}
finally {
    Write-Host
    Write-Host "Resetting title to", $Old_Title
    $host.ui.RawUI.WindowTitle = $Old_Title
}
