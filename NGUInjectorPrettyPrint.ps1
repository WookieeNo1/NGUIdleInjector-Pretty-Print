param ([String]$LogFile = $args[0], [String]$DisplayMode = $args[1], [System.object]$LineFilter = $args[2])


try {

    $ExistingVariables = Get-Variable -Scope Global| Select-Object -ExpandProperty Name

    [bool]$bLogfile = $false
    [bool]$bDisplay = $false

    # Fix for $host.ui.RawUI.WindowTitle = $BaseFile + ' Parser' Exception
    if ($PSVersionTable.PSversion.major -lt 7) {
        Write-Host "Requires PowerShell v7"
        exit
    }
    $configFullPath = "$PSScriptRoot\ParseNGUInjector_tools.ps1"
    Import-Module -Force $configFullPath

    if ($LogFile) {
        $LogFile = $LogFile.ToString().ToLower()
        $bLogfile = ($LogFile -in $ValidFiles)
    }

    if ($DisplayMode) {
        $DisplayMode = $DisplayMode.ToString().ToLower()
        $bDisplay = ($DisplayMode -in $ValidModes)
    }

    if ($LineFilter -and $LineFilter -ne "") {
        #Prepare regex search string
        $LineFilter = ParseLineFilter($LineFilter)
    }
    else {
        $LineFilter = $null
    }

    CheckColoursFile
    MonitorColoursFile

    CheckFlagsFile
    
    $ActiveParser = [LogParser]::new()
    $ActiveParser.LineFilter = $LineFilter

    $Old_Title = $host.ui.RawUI.WindowTitle
    if ($bLogfile) {
        $ActiveParser.BaseFile = $LogFile
    }
    if ($bDisplay) {
        $ActiveParser.DisplayMode = $DisplayMode
    }
    $RanFromParam = $bLogfile -and $bDisplay
    if ($RanFromParam) {
        Execute
    }
    else {
        run
    }
}
finally {
    DisableMonitorColoursFile
    Write-Host
    Write-Host "Resetting title to", $Old_Title
    $host.ui.RawUI.WindowTitle = $Old_Title

    $NewVariables = Get-Variable | Select-Object -ExpandProperty Name | Where-Object {$ExistingVariables -notcontains $_ -and $_ -ne "ExistingVariables"}
    
    if ($NewVariables)
    {
        Remove-Variable $NewVariables -ErrorAction SilentlyContinue -Scope Global
    }
}
