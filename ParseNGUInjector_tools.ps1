#########################################
## Requires NGUInjectorPrettyPrint.ps1 ##
#########################################
Clear-Host

#0 Black
#1 DarkBlue
#2 DarkGreen
#3 DarkCyan
#4 DarkRed
#5 DarkMagenta
#6 DarkYellow
#7 Gray
#8 DarkGray
#9 Blue
#10 Green
#11 Cyan
#12 Red
#13 Magenta
#14 Yellow
#15 White

$global:clrSignificantData = 10
$global:clrINFO = 11
$global:clrWarning = 12
$global:clrOperational = 14
$global:clrSettings = 3
$global:clrException = 4
$global:clrStandard = 15

#Specific Message Highlighting
$global:clrMoneyPitReward = $clrINFO
$global:clrHyperbole = $clrException
$global:clrCardsField = $clrStandard

$MaxTailItems = 30

#Allows for Inject, PitSpin, Loot and Cards logs
$ValidFiles = @("inject.log", "pitspin.log", "loot.log", "cards.log")
$ValidModes = @("tail", "full")

#List blocking simple filter strings
$InvalidLineFilters = @(" ", ":")
#Added All colour variables to default list
$Colours = @(
    [PSCustomObject]@{
        Variable = "clrMoneyPitReward"
        Value    = $clrMoneyPitReward
    }
    [PSCustomObject]@{
        Variable = "clrHyperbole"
        Value    = $clrHyperbole
    }
    [PSCustomObject]@{
        Variable = "clrSignificantData"
        Value    = 10
    }
    [PSCustomObject]@{
        Variable = "clrINFO"
        Value    = 11
    }
    [PSCustomObject]@{
        Variable = "clrWarning"
        Value    = 12
    }
    [PSCustomObject]@{
        Variable = "clrOperational"
        Value    = 3
    }
    [PSCustomObject]@{
        Variable = "clrSettings"
        Value    = 3
    }
    [PSCustomObject]@{
        Variable = "clrException"
        Value    = 4
    }
    [PSCustomObject]@{
        Variable = "clrStandard"
        Value    = 15
    }
    [PSCustomObject]@{
        Variable = "clrCardsField"
        Value    = $clrCardsField
    }
)

$ColoursFullPath = "$PSScriptRoot\Colours.CSV"

$global:CardsSmartDisplay = $false

$Flags = @(
    [PSCustomObject]@{
        Variable = "CardsSmartDisplay"
        Value    = $CardsSmartDisplay
    }
)

$FlagsFullPath = "$PSScriptRoot\Flags.CSV"

$global:ColoursChanged = $false
$global:watcher = $null
$global:handlers = $null
$global:EventDetails = $null


class LogParser {
    [string]$LastTimeStamp = ""
    [string]$filler = ""
    [string]$LineFilter = ""
    [string]$BaseFile = $ValidFiles[0]
    [string]$DisplayMode = $ValidModes[0]

    [System.Diagnostics.StopWatch]$StopWatch = [System.Diagnostics.Stopwatch]::new()

    [LogLine]$ParsedLine = [LogLine]::new()

    [string]Location() { return $Env:Userprofile + "\Desktop\NGUInjector\logs\" + $this.BaseFile } 
}

# LineFilter now parses regular expressions
function ParseLineFilter {
    param (
        $Filters
    )
    $Filters = $Filters -join ','
    $Filters = $Filters -replace '"|\*\.'  -replace ',','|'
    $Filters = '^.*({0}).*$' -f $Filters

    return $Filters

}

function MonitorColoursFile {
    $global:watcher = New-Object -TypeName System.IO.FileSystemWatcher -Property @{
        Path                  = Split-Path $ColoursFullPath -Parent
        Filter                = Split-Path $ColoursFullPath -Leaf
        IncludeSubdirectories = $false
    }

    $action = {
        #Retain the event
        $global:EventDetails = $event.SourceEventArgs
        #Enable the Change Notification
        $global:ColoursChanged = $true
        
    }    

    # set up the event handlers
    $global:handlers = . {
        Register-ObjectEvent -InputObject $global:watcher -EventName Changed -Action $action
        Register-ObjectEvent -InputObject $global:watcher -EventName Created -Action $action
        Register-ObjectEvent -InputObject $global:watcher -EventName Deleted -Action $action
        Register-ObjectEvent -InputObject $global:watcher -EventName Renamed -Action $action
    }
}

function DisableMonitorColoursFile {
    $global:watcher.EnableRaisingEvents = $false
  
    # remove the event handlers
    $global:handlers | ForEach-Object {
        Unregister-Event -SourceIdentifier $_.Name
    }
    
    # event handlers are technically implemented as a special kind
    # of background job, so remove the jobs now:
    $global:handlers | Remove-Job
    
    # properly dispose the FileSystemWatcher:
    $global:watcher.Dispose()
   
}

function SetBaseDataFile {
    param (
        $s_DataFilePath,
        $a_DataItems
    )

    Add-Content -Path $s_DataFilePath -Value 'Variable,Value'
    $a_DataItems | Export-Csv -Path $s_DataFilePath -UseQuotes Never
}

function CheckColoursFile {
    CheckDataFile $ColoursFullPath $Colours
}

function CheckFlagsFile {
    CheckDataFile $FlagsFullPath $Flags
}

function CheckDataFile(){
    param (
        $s_DataFilePath,
        $a_DataItems
    )

    # Colours File Does Not Exist
    if ( -not (Test-Path -Path $s_DataFilePath) ) {
        SetBaseDataFile $s_DataFilePath $a_DataItems
    }
    else {
        $TestCSV = Get-Content $s_DataFilePath -First 1
        If ($TestCSV.Length -eq 0 -or $TestCSV -notmatch 'Variable,Value') {
            # File Present, but invalid
            $Backup = $s_DataFilePath.Replace('CSV', 'old')

            Write-Host "Invalid CSV - $s_DataFilePath" -ForegroundColor $clrWarning
            Write-Host "Existing File renamed to", $Backup -ForegroundColor $clrWarning

            Remove-Item $Backup -ErrorAction SilentlyContinue
            Rename-Item $s_DataFilePath $Backup

            SetBaseDataFile $s_DataFilePath $a_DataItems

        }
        elseif (-not ((Get-Content $s_DataFilePath -Raw) -match "\r\n$")) {
            # Insert terminal CR/LF as necessary
            Add-Content $s_DataFilePath ""
        }

        # Need to check that all current values are present
        $MissingItems = foreach ($Item in $a_DataItems) {
            $test = Import-Csv -Path $s_DataFilePath |
            Where-Object {
                $FileVariable = $_.Variable.Replace(" ", "")
                $FileVariable = $FileVariable.Replace("`t", ",")
                # Detect either normal or commented Variable, ignoring WhiteSpace
                $FileVariable -eq $Item.Variable -or $FileVariable -eq '#' + $Item.Variable
            }
            #1 if no result, add to output
            if ( $NULL -eq $test) {
                $Item
            }
        }
        # If any output, append, using default values, to CSV file
        if ( $MissingItems ) {
            $MissingItems | Export-Csv $s_DataFilePath –Append -UseQuotes Never
        }
    }

    ReadDataFile $s_DataFilePath $a_DataItems

}

function ReadDataFile() {
    param (
        $s_DataFilePath,
        $a_DataItems
    )

    # Import User-Defined Variables from validated list
    $ValidVariables = @($a_DataItems.Variable)
    
    Import-Csv -Path $s_DataFilePath | ForEach-Object -Process {

        #Fixed for Variable redefinition only applying locally by adding -Scope Script
        if ($PSItem.Variable -in $ValidVariables) {
            if ($s_DataFilePath -like "*Flags.csv") {
                Set-Variable -Name $PSItem.Variable -Value ($PSItem.Value -like "True") -Scope Global
            }
            else {
                Set-Variable -Name $PSItem.Variable -Value ($PSItem.Value) -Scope Global
            }
        }
    }
}

function MergeParser {
    param (
        $MergeStr
    )
    $Parts = $MergeStr.trim().split(" in slot ", 2)
    Write-Host -NoNewline $Parts[0] -ForegroundColor $clrSignificantData
    Write-Host -NoNewline " in slot " -ForegroundColor $clrStandard
    Write-Host -NoNewline $Parts[1] -ForegroundColor $clrSignificantData
}

function MissingParser {
    param (
        $MergeStr
    )
    $Parts = $MergeStr.trim().split(" with ID ", 2)
    Write-Host -NoNewline $Parts[0] -ForegroundColor $clrSignificantData
    Write-Host -NoNewline " with ID " -ForegroundColor $clrStandard
    Write-Host -NoNewline $Parts[1] -ForegroundColor $clrSignificantData
}

Function ButteringParser() {
    param (
        $ButterStr
    )
    $Parts = $ButterStr.trim().split(" ", 2)
    Write-Host -NoNewline " "
    Write-Host -NoNewline $Parts[0] -ForegroundColor $clrSignificantData
    Write-Host -NoNewline " "
    Write-Host -NoNewline $Parts[1] -ForegroundColor $clrINFO

}

Function RemovingParser() {
    param (
        $RemovingStr
    )
    $Parts = $RemovingStr.trim().split(" ")
    Write-Host -NoNewline $Parts[0..3] -ForegroundColor $clrINFO
    Write-Host -NoNewline " "
    Write-Host -NoNewline $Parts[4] -ForegroundColor $clrSignificantData
}

Function BuyingParser() {
    param (
        $BuyingStr
    )
    $Parts = $BuyingStr.trim().split(" ", 2)
    Write-Host -NoNewline " "
    Write-Host -NoNewline $Parts[0] -ForegroundColor $clrSignificantData
    Write-Host -NoNewline " "
    Write-Host -NoNewline $Parts[1] -ForegroundColor $clrINFO

}

Function SettingsParser() {
    # remove date string if present - fudge
    if ( $ActiveParser.ParsedLine.Raw -like "*:*" -and $ActiveParser.ParsedLine.SettingsFirst) {
        $ActiveParser.ParsedLine.ActiveLine = $ActiveParser.ParsedLine.Raw.split(":")[2]
        $ActiveParser.ParsedLine.Populate($ActiveParser.ParsedLine.ActiveLine)
        $ActiveParser.ParsedLine.Raw = $ActiveParser.ParsedLine.ActiveLine
    }

    $SettingsFiller = "          " * $ActiveParser.ParsedLine.IndentLevel

    Write-Host -NoNewline $ActiveParser.ParsedLine.filler

    if ($ActiveParser.ParsedLine.SettingsFirst) {
        $ActiveParser.ParsedLine.SettingsFirst = $false

        Write-Host -NoNewline "  "
        Write-Host -NoNewline $SettingsFiller
        Write-Host -NoNewline $ActiveParser.ParsedLine.Parts[0] -ForegroundColor $clrSettings

        $ActiveParser.ParsedLine.IndentLevel = $ActiveParser.ParsedLine.IndentLevel + 1
    }
    elseif ($ActiveParser.ParsedLine.SettingsArray) {
        if ($ActiveParser.ParsedLine.Parts[0].trim().StartsWith("]")) {
            $ActiveParser.ParsedLine.IndentLevel = $ActiveParser.ParsedLine.IndentLevel - 1
            $SettingsFiller = "          " * $ActiveParser.ParsedLine.IndentLevel
            $ActiveParser.ParsedLine.SettingsArray = $false
            $clrArray = $clrSettings
        }
        else {
            $clrArray = $clrSignificantData
        }

        Write-Host -NoNewline $SettingsFiller
        Write-Host -NoNewline $ActiveParser.ParsedLine.Parts[0].trim().split(",") -ForegroundColor $clrArray -Separator ""
        if ($ActiveParser.ParsedLine.Parts[0].trim().EndsWith(",")) {
            Write-Host -NoNewline "," -ForegroundColor $clrSettings -Separator ""
        }
    }
    else {
        if ($ActiveParser.ParsedLine.Parts[0] -eq "}") {
            $ActiveParser.ParsedLine.IndentLevel = 0
            $ActiveParser.ParsedLine.SettingsActive = $false

            Write-Host -NoNewline "  "
            Write-Host -NoNewline $ActiveParser.ParsedLine.Parts[0] -ForegroundColor $clrSettings
        }
        elseif ($ActiveParser.ParsedLine.Parts.count -eq 2) {
            Write-Host -NoNewline $SettingsFiller
            Write-Host -NoNewline $ActiveParser.ParsedLine.Parts[0], ": " -ForegroundColor $clrSettings -Separator ""
            if ($ActiveParser.ParsedLine.Parts[1].Trim() -eq "[") {
                $ActiveParser.ParsedLine.SettingsArray = $true
                $ActiveParser.ParsedLine.IndentLevel = $ActiveParser.ParsedLine.IndentLevel + 1
                Write-Host -NoNewline $ActiveParser.ParsedLine.Parts[1] -ForegroundColor $clrINFO -Separator ""
            }
            else {
                if ($ActiveParser.ParsedLine.Parts[1].Trim() -eq "[],") {
                    $clrItem = $clrSettings
                }
                else {
                    $clrItem = $clrSignificantData
                }

                Write-Host -NoNewline $ActiveParser.ParsedLine.Parts[1].Trim().split(",") -ForegroundColor $clrItem -Separator ""
                if ($ActiveParser.ParsedLine.Parts[1].EndsWith(",")) {
                    Write-Host -NoNewline "," -ForegroundColor $clrSettings -Separator ""
                }
            }
        }
        else {
            #Fix for exception caused cos of Stupid Coder forgetting to use correct variable
            Write-Host -NoNewline $ActiveParser.ParsedLine.Parts.split(",") -ForegroundColor $clrSignificantData -Separator ""
            if ($ActiveParser.ParsedLine.Parts.EndsWith(",")) {
                Write-Host -NoNewline "," -ForegroundColor $clrSettings -Separator ""
            }
            elseif ($ActiveParser.LineFilter) {
                $ActiveParser.ParsedLine.SettingsActive = $false
            }
        }
    }
    Write-Host
}
Function CustomAllocationParser() {
    $Parts = $ActiveParser.ParsedLine.Parts[0].split(" ", 2).Trim()
    if ($ActiveParser.ParsedLine.KeyWord -eq "Challenge targets") {
        Write-Host
        Write-Host -NoNewline $ActiveParser.ParsedLine.filler, $ActiveParser.ParsedLine.filler -Separator ""
        Write-Host -NoNewline $ActiveParser.ParsedLine.KeyWord, ": " -ForegroundColor $clrINFO -Separator ""
    }
    elseif ($ActiveParser.ParsedLine.KeyWord -eq "Rebirthing") {
        Write-Host -NoNewline $ActiveParser.ParsedLine.filler, $ActiveParser.ParsedLine.filler -Separator ""
        Write-Host -NoNewline $ActiveParser.ParsedLine.KeyWord, "" -ForegroundColor $clrINFO -Separator " "
    }
    else {
        Write-Host -NoNewline $ActiveParser.ParsedLine.filler, $ActiveParser.ParsedLine.filler -Separator ""
        Write-Host -NoNewline $Parts[0], "" -ForegroundColor $clrSignificantData
    }

    if ($ActiveParser.ParsedLine.KeyWord -eq "Rebirthing") {
        $SubParts = $ActiveParser.ParsedLine.ActiveLine.split(" ").Trim()
        if ($ActiveParser.ParsedLine.Raw.StartsWith("Rebirth Disabled.")) {
            # "Rebirth Disabled."
            Write-Host -NoNewline $SubParts[1] -ForegroundColor $clrSettings
        }
        elseif ($ActiveParser.ParsedLine.Raw.StartsWith("Rebirthing at")) {
            # "Rebirthing at {trb.RebirthTime} seconds"
            Write-Host -NoNewline $SubParts[1], "" -ForegroundColor $clrSettings
            Write-Host -NoNewline $SubParts[2], "" -ForegroundColor $clrSignificantData
            Write-Host -NoNewline $SubParts[3], "" -ForegroundColor $clrSettings
        }
        elseif ($ActiveParser.ParsedLine.Raw.StartsWith("Rebirthing when number bonus is")) {
            # "Rebirthing when number bonus is {nrb.MultTarget}x previous number"
            Write-Host -NoNewline $SubParts[1..4], "" -ForegroundColor $clrSettings -Separator " "
            Write-Host -NoNewline $SubParts[5], "" -ForegroundColor $clrSignificantData
            Write-Host -NoNewline $SubParts[6..7], "" -ForegroundColor $clrSettings -Separator " "
        }
        elseif ($ActiveParser.ParsedLine.Raw.StartsWith("Rebirthing when number allows you")) {
            # "Rebirthing when number allows you +{brb.NumBosses} bosses"
            Write-Host -NoNewline $SubParts[1..4], "" -ForegroundColor $clrSettings -Separator " "
            Write-Host -NoNewline $SubParts[5], "" -ForegroundColor $clrSignificantData
            Write-Host -NoNewline $SubParts[6..7], "" -ForegroundColor $clrSettings -Separator " "
        }
    }
    elseif ($ActiveParser.ParsedLine.KeyWord -eq "Challenge targets") {
        $SubParts = $ActiveParser.ParsedLine.Parts[1].split(",").Trim()
        foreach ($Challenge in $SubParts) {
            Write-Host
            Write-Host -NoNewline $ActiveParser.ParsedLine.filler, $ActiveParser.ParsedLine.filler, $ActiveParser.ParsedLine.filler -Separator ""
            Write-Host -NoNewline $Challenge, "" -ForegroundColor $clrSignificantData -Separator ""
            if ($Challenge -ne $SubParts[$SubParts.Count - 1]) {
                Write-Host -NoNewline "," -ForegroundColor $clrSettings -Separator ""
            }
        }
    }
    else {
        Write-Host $Parts[1] -ForegroundColor $clrSettings
    }

    if ($ActiveParser.ParsedLine.Raw -eq "") {
        $ActiveParser.ParsedLine.CustomAllocation = $false
    }
}

function LoadedParser {
    param (
        $LoadedStr
    )
    $Parts = $LoadedStr.trim().split(" ")
    Write-Host -NoNewline $Parts[0..4], "" -ForegroundColor $clrINFO -Separator " "
    Write-Host -NoNewline " "
    Write-Host -NoNewline $Parts[5] -ForegroundColor $clrSignificantData
}

function CastParser {
    param (
        $CastStr
    )
    $Parts = $CastStr.trim().split(" ")
    Write-Host -NoNewline $Parts[0..1], "" -ForegroundColor $clrINFO -Separator " "
    Write-Host -NoNewline $Parts[2] -ForegroundColor $clrSignificantData
    Write-Host -NoNewline " "
    Write-Host -NoNewline $Parts[3], "" -ForegroundColor $clrINFO -Separator " "
    Write-Host -NoNewline $Parts[4] -ForegroundColor $clrSignificantData
    Write-Host -NoNewline
}

function BoostParser {
    param (
        [string]$BoostStr
    )

    $SplitStr = ', '

    $Boosts = $BoostStr.trim().split($SplitStr).trim()
    $MaxBoosts = $Boosts.length - 1

    foreach ($ActiveBoost in $Boosts) {
        $ThisBoost = $ActiveBoost.trim().split()

        Write-Host -NoNewline $ThisBoost[0] -ForegroundColor $clrSignificantData
        Write-Host -NoNewline " "
        Write-Host -NoNewline $ThisBoost[1] -ForegroundColor $clrStandard

        if ([array]::indexof($Boosts, $ActiveBoost) -lt $MaxBoosts) {
            Write-Host -NoNewline $SplitStr -ForegroundColor $clrStandard
        }
    }
}

function ExceptionParser() {

    if ($ActiveParser.ParsedLine.Parts[0].TrimStart().StartsWith( "at ")) {
        Write-Host -NoNewline $ActiveParser.ParsedLine.Parts[0] -ForegroundColor $clrException
    }
    else {
        $ActiveParser.ParsedLine.Exception = $false
    }
}

class LogLine {
    [string]$Raw = ""
    [string]$TimeStamp = ""
    [string]$Filler = ""
    [string]$KeyWord = ""
    [string]$ActiveLine = ""
    [System.Collections.ArrayList]$Parts
    [bool]$SettingsActive = $false
    [bool]$SettingsFirst = $false
    [bool]$SettingsArray = $false
    [int]$IndentLevel = 0
    [bool]$CustomAllocation = $false
    [bool]$Exception = $false
    [bool]$Merge = $false
    [bool]$Line1 = $true

    [void]Populate([string]$str) {
        [bool]$DateStripped = $false

        # Assorted String fixes
        $str = $str.Replace("<b>", "")
        $str = $str.Replace("</b>", "")
        $str = $str.Replace("(BOSS)also", "(BOSS) also")

        $this.Raw = $str
        $this.Parts = @($str.trim().split(":"))
        if ($this.Parts.Count -gt 2) {
            # Remove Seconds component - output will only show changes in minutes, filling with space within the same minute
            $this.TimeStamp = $this.Parts[0].trim() + ":" + $this.Parts[1].trim()
            $this.TimeStamp = $this.TimeStamp.split("(").trim()[0]
            # Timestamp is now fixed length
            $this.TimeStamp = $this.TimeStamp + " " * (19 - $this.TimeStamp.length)
            $DateStripped = $true
            $this.filler = " " * $this.TimeStamp.length
            $this.Parts.RemoveRange(0, 2)
            if ($this.Exception) {
                $this.Parts[0] = "  " + ($this.Parts -Join ":").ToString().TrimStart(" ")
                while ($this.Parts.Count -gt 1) {
                    $this.Parts.RemoveRange($this.Parts.Count - 1, 1)
                }
            }
        }
        if ($this.Merge) {
            $this.Parts[0] = $this.KeyWord.trim() + " " + $this.Parts[0].trim()
            $this.ActiveLine = $this.Parts[0]
        }
        elseif ($this.Exception -and -not $DateStripped) {
            $this.Parts[0] = $this.Raw
            while ($this.Parts.Count -gt 1) {
                $this.Parts.RemoveRange($this.Parts.Count - 1, 1)
            }
        }
        elseif ($this.Parts.Count -gt 1) {
            $this.KeyWord = $this.Parts[0].trim()
            $this.ActiveLine = $this.Parts.Trim() -join ":"
        }
        else {
            $this.KeyWord = $this.Parts[0].ToString().Trim()
            $this.ActiveLine = $this.Parts[0].ToString().Trim()
        }
        switch ($this.KeyWord.split(" ")[0]) {
            "Casting" {
                $this.KeyWord = "Casting Failed"
                $this.Parts[0] = $this.KeyWord
                $this.Parts.Add($this.ActiveLine.split(" - ", 2)[0])
                $this.Parts[1] = $this.Parts[1].Replace($this.KeyWord, "").Trim()
                $this.Parts.Add($this.ActiveLine.split(" - ", 2)[1])
            }
            "Merging" {
                $this.Parts = $this.ActiveLine.split(" ", 2)
            }
            # $"Missing item {Controller.itemInfo.itemName[itemId]} with ID {itemId}"
            "Missing" {
                $this.KeyWord = "Missing item"
                $this.Parts[0] = $this.Parts[0].Replace($this.KeyWord, "").Trim()
            }
            "Rebirthing" {
                $this.KeyWord = "Rebirthing"
                $this.Parts[0] = $this.Parts[0].Replace($this.KeyWord, "").Trim()
            }
            "Removing" {
                $this.Parts = $this.ActiveLine.split(" ")
            }
            "Saved" {
                if ($this.ActiveLine.split(" ")[1] -eq "Loadout") {
                    $this.KeyWord = "Saved Loadout"
                    $this.Parts[0] = $this.KeyWord
                    $this.Parts.Add($this.ActiveLine.split(" ", 3)[2])
                }
                elseif ($this.ActiveLine.StartsWith("Saved Current Loadout")) {
                    $this.KeyWord = "Saved Current Loadout"
                    $this.Parts[0] = $this.KeyWord
                    $this.Parts.Add($this.ActiveLine.split(" ", 4)[3])
                }
            }
            "Upgrading" {
                $this.KeyWord = "Upgrading Digger"
                $this.Parts[0] = $this.KeyWord
                $this.Parts.Add($this.ActiveLine.split(" ", 3)[2])
            }
            default {}
        }
    }
}

function Parse_inject_Keywords {

    switch ($ActiveParser.ParsedLine.KeyWord) {
        # $"Boosts Needed to Green: {needed.Power} Power, {needed.Toughness} Toughness, {needed.Special} Special"
        "Boosts Needed to Green" {
            Write-Host -NoNewline $ActiveParser.ParsedLine.KeyWord, ": " -ForegroundColor $clrINFO -Separator ""
            BoostParser($ActiveParser.ParsedLine.Parts[1])
        }
        # "Casting Failed Blood MacGuffin A Spell - Insufficient Power " + mcguffA +" of " + Main.Settings.BloodMacGuffinAThreshold
        # "Casting Failed Blood MacGuffin B Spell - Insufficient Power " + mcguffB +" of " + Main.Settings.BloodMacGuffinBThreshold
        # "Casting Failed Iron Blood Spell - Insufficient Power " + iron + " of " + Main.Settings.IronPillThreshold
        "Casting Failed" {
            Write-Host -NoNewline $ActiveParser.ParsedLine.KeyWord, " " -ForegroundColor $clrINFO -Separator ""
            Write-Host -NoNewline $ActiveParser.ParsedLine.Parts[1] -ForegroundColor $clrSignificantData
            Write-Host -NoNewline " - " -ForegroundColor $clrINFO
            CastParser($ActiveParser.ParsedLine.Parts[2])
        }

        # $"Cube Power: {cube.Power} ({_character.inventoryController.cubePowerSoftcap()} softcap). Cube Toughness: {cube.Toughness} ({_character.inventoryController.cubeToughnessSoftcap()} softcap)"
        "Cube Power" {
            #Power Toughness
            $CubePower = $ActiveParser.ParsedLine.Parts[1].trim().split(".")
            $CubeTough = $ActiveParser.ParsedLine.Parts[2].trim().split(".")

            Write-Host -NoNewline "Cube Power: " -ForegroundColor $clrINFO -Separator ""
            CapValues($CubePower[0..2].trim())

            Write-Host -NoNewline " Cube Toughness: " -ForegroundColor $clrINFO -Separator ""
            CapValues($CubeTough[0..2].trim())
        }
        # output
        #     Cube Progress: ... Power. Average Per Minute: ...
        "Cube Progress" {
            Write-Host -NoNewline $ActiveParser.ParsedLine.KeyWord, ": " -ForegroundColor $clrINFO -Separator ""
            # Fixed Code Progress Highlighting by joining Parts with ": "
            Highlight_Numbers($ActiveParser.ParsedLine.Parts[1..2].trim() -join ": " )
        }
        # $"Equipping Diggers: {string.Join(",", diggers.Select(x => x.ToString()).ToArray())}"
        "Equipping Diggers" {
            Write-Host -NoNewline $ActiveParser.ParsedLine.KeyWord, ": " -ForegroundColor $clrINFO -Separator ""
            Write-Host -NoNewline $ActiveParser.ParsedLine.Parts[1].trim() -ForegroundColor $clrSignificantData
        }
        # $"Equipped Items: {items}"
        "Equipped Items" {
            Write-Host -NoNewline $ActiveParser.ParsedLine.KeyWord, ": " -ForegroundColor $clrINFO -Separator ""
            Write-Host -NoNewline $ActiveParser.ParsedLine.Parts[1].trim() -ForegroundColor $clrSignificantData
        }

        # $"Failed to load quicksave: {e.Message}" ---- NOT YET DONE
        # $"Failed to read quicksave: {e.Message}" ---- NOT YET DONE

        # "Injected"
        "Injected" {
            Write-Host -NoNewline $ActiveParser.ParsedLine.KeyWord -ForegroundColor $clrOperational
        }
        # $"Key: {index}"
        "Key" {
            Write-Host -NoNewline $ActiveParser.ParsedLine.KeyWord, ": " -ForegroundColor $clrINFO -Separator ""
            Write-Host -NoNewline $ActiveParser.ParsedLine.Parts[1].trim() -ForegroundColor $clrSignificantData
        }
        # $"Last Minute: {diff}." ---- NOT YET DONE
        # $"Last Minute: {diff}. Average Per Minute: {average:0}. ETA: {eta:0} minutes."
        "Last Minute" {
            Write-Host -NoNewline $ActiveParser.ParsedLine.KeyWord, ": " -ForegroundColor $clrINFO -Separator ""
            Write-Host -NoNewline $ActiveParser.ParsedLine.Parts[1..2].trim(), ""  -ForegroundColor $clrStandard -Separator ": "
            $Parts = $ActiveParser.ParsedLine.Parts[3].trim().split(" ")
            Write-Host -NoNewline $Parts[0].trim(), "" -ForegroundColor $clrSignificantData
            Write-Host -NoNewline $Parts[1].trim(), "" -ForegroundColor $clrStandard
        }
        # "Loaded Settings"
        "Loaded Settings" {
            Write-Host -NoNewline $ActiveParser.ParsedLine.KeyWord -ForegroundColor $clrOperational
            $ActiveParser.ParsedLine.SettingsActive = $true
            $ActiveParser.ParsedLine.SettingsFirst = $true
        }

        # $"Loaded Zone Overrides: {string.Join(",", overrides.ToArray())}"
        "Loaded Zone Overrides" {
            Write-Host -NoNewline $ActiveParser.ParsedLine.KeyWord, ": " -ForegroundColor $clrINFO -Separator ""
            Write-Host -NoNewline $ActiveParser.ParsedLine.Parts[1].trim() -ForegroundColor $clrSignificantData
        }
        # $"Missing item {Controller.itemInfo.itemName[itemId]} with ID {itemId}"
        "Missing item" {
            Write-Host -NoNewline $ActiveParser.ParsedLine.KeyWord, ": " -ForegroundColor $clrINFO -Separator ""
            MissingParser($ActiveParser.ParsedLine.Parts[0])
        }

        # $"Received New Gear: {string.Join(",", gearIds.Select(x => x.ToString()).ToArray())}"
        "Received New Gear" {
            Write-Host -NoNewline $ActiveParser.ParsedLine.KeyWord, ": " -ForegroundColor $clrINFO -Separator ""
            Write-Host -NoNewline $ActiveParser.ParsedLine.Parts[1].trim() -ForegroundColor $clrSignificantData
        }
        # Hack for Loadout Switch
        "Received New Gear for Yggdrasil" {
            Write-Host -NoNewline $ActiveParser.ParsedLine.KeyWord, ": " -ForegroundColor $clrINFO -Separator ""
            Write-Host -NoNewline $ActiveParser.ParsedLine.Parts[1].trim() -ForegroundColor $clrSignificantData
        }
        # $"Saved Loadout {string.Join(",", _savedLoadout.Select(x => x.ToString()).ToArray())}"
        # $"Saved Loadout {string.Join(",", _tempLoadout.Select(x => x.ToString()).ToArray())}"
        "Saved Loadout" {
            Write-Host -NoNewline $ActiveParser.ParsedLine.KeyWord, ": " -ForegroundColor $clrINFO -Separator ""
            Write-Host -NoNewline $ActiveParser.ParsedLine.Parts[1].trim() -ForegroundColor $clrSignificantData
        }
        # Hack for Loadout Switch
        "Saved Current Loadout" {
            Write-Host -NoNewline $ActiveParser.ParsedLine.KeyWord, ": " -ForegroundColor $clrINFO -Separator ""
            Write-Host -NoNewline $ActiveParser.ParsedLine.Parts[1].trim() -ForegroundColor $clrSignificantData
        }
        # "Upgrading Digger " + _cheapestDigger
        "Upgrading Digger" {
            Write-Host -NoNewline $ActiveParser.ParsedLine.KeyWord, "" -ForegroundColor $clrINFO
            Write-Host -NoNewline $ActiveParser.ParsedLine.Parts[1].trim() -ForegroundColor $clrSignificantData
        }

        default {
            $ActiveParser.ParsedLine.KeyWord = $ActiveParser.ParsedLine.ActiveLine.trim().split(" ", 2)[0].TRIM()

            $ParseSub = $ActiveParser.ParsedLine.ActiveLine.split(" ", 2)

            switch ($ActiveParser.ParsedLine.KeyWord) {
                # "Bad save version"

                # $"Buying {numPurchases} {t} purchases"
                "Buying" {
                    Write-Host -NoNewline "Buying" -ForegroundColor $clrINFO -Separator " "
                    BuyingParser($ParseSub[1])

                }
                # "Created empty allocation profile. Please update allocation.json"

                # "Buttering Major Quest"
                # "Buttering Minor Quest"
                "Buttering" {
                    Write-Host -NoNewline "Buttering" -ForegroundColor $clrINFO -Separator " "
                    ButteringParser($ParseSub[1])
                }
                # "Delaying rebirth 1 loop to allow fruit effects"
                # "Delaying rebirth to wait for ygg loadout/diggers"
                # "Delaying rebirth while boss fight is in progress"
                "Delaying" {
                    Write-Host -NoNewline $ActiveParser.ParsedLine.ActiveLine -ForegroundColor $clrINFO
                }
                # "Equipping Gold Drop Loadout"
                # "Equipping Gold Loadout"
                # "Equipping Loadout for Titans"
                # "Equipping Loadout for Yggdrasil and Harvesting"
                # "Equipping Money Pit"
                # "Equipping Previous Diggers"
                # "Equipping Quick Diggers"
                # "Equipping Quick Loadout"
                # "Equipping Titan Loadout"
                # "Equipping Yggdrasil Loadout"
                "Equipping" {
                    Write-Host -NoNewline $ActiveParser.ParsedLine.ActiveLine -ForegroundColor $clrINFO
                }
                # "Failed to load allocation file. Resave to reload"
                "Failed" {
                    Write-Host -NoNewline $ActiveParser.ParsedLine.ActiveLine -ForegroundColor $clrINFO
                }
                # "Finished equipping gear"
                "Finished" {
                    Write-Host -NoNewline $ActiveParser.ParsedLine.ActiveLine -ForegroundColor $clrINFO
                }
                # "Gold Loadout kill done. Turning off setting and swapping gear"
                "Gold" {
                    Write-Host -NoNewline $ActiveParser.ParsedLine.ActiveLine -ForegroundColor $clrINFO
                }
                # "Harvesting without swap because threshold not met"
                "Harvesting" {
                    Write-Host -NoNewline $ActiveParser.ParsedLine.ActiveLine -ForegroundColor $clrINFO
                }
                #Loaded Custom Allocation from profile
                "Loaded" {
                    LoadedParser($ActiveParser.ParsedLine.Parts)
                    $ActiveParser.ParsedLine.CustomAllocation = $true
                }

                # "Loading quicksave"

                # $"Merging {SanitizeName(target.name)} in slot {target.slot}"
                # $"Merging {target.name} in slot {target.slot}"
                "Merging" {
                    Write-Host -NoNewline $ActiveParser.ParsedLine.KeyWord, "" -ForegroundColor $clrINFO
                    MergeParser($ActiveParser.ParsedLine.Parts[1])
                }
                # $"Moving to ITOPOD to idle."

                # "Normal Rebirth Engaged"
                "Normal" {
                    Write-Host -NoNewline $ActiveParser.ParsedLine.ActiveLine -ForegroundColor $clrINFO
                }

                # "Quicksave doesn't exist"

                # $"Rebirthing into {rbType}"
                "Rebirthing" {
                    Write-Host -NoNewline $ActiveParser.ParsedLine.KeyWord -ForegroundColor $clrWarning
                    $Parts = $ActiveParser.ParsedLine.ActiveLine.trim().split(" into ", 2)
                    Write-Host -NoNewline " into " -ForegroundColor $clrINFO
                    Write-Host -NoNewline $Parts[1] -ForegroundColor $clrSignificantData
                }
                # $"Removing energy for fruit {i}"
                # $"Removing magic for fruit {i}"
                "Removing" {
                    Write-Host -NoNewline $ActiveParser.ParsedLine.Parts[0], "" -ForegroundColor $clrINFO -Separator " "
                    Write-Host -NoNewline $ActiveParser.ParsedLine.Parts[1], "" -ForegroundColor $clrSignificantData -Separator " "
                    Write-Host -NoNewline $ActiveParser.ParsedLine.Parts[2..3], "" -ForegroundColor $clrINFO -Separator " "
                    Write-Host -NoNewline $ActiveParser.ParsedLine.Parts[4] -ForegroundColor $clrSignificantData
                }
                # $"Restoring original loadout"
                # "Restoring Previous Loadout"
                "Restoring" {
                    Write-Host -NoNewline $ActiveParser.ParsedLine.ActiveLine -ForegroundColor $clrINFO
                }

                # $"Running money loadout for {bossId}"

                # "Saving Settings"
                "Saving" {
                    Write-Host -NoNewline $ActiveParser.ParsedLine.ActiveLine -ForegroundColor $clrOperational
                }

                # "Time Machine Gold is 0. Lets reset gold snipe zone."
                "Time" {
                    Write-Host -NoNewline $ActiveParser.ParsedLine.ActiveLine -ForegroundColor $clrINFO
                }

                # $"Turning in {questItems.Length} quest items"
                # "Turning in quest"
                "Turning" {
                    Highlight_Numbers($ActiveParser.ParsedLine.ActiveLine)
                }

                # "Unable to harvest now"

                # "Writing quicksave and json"
                "Writing" {
                    Write-Host -NoNewline $ActiveParser.ParsedLine.ActiveLine -ForegroundColor $clrOperational
                }

                default {
                    ##############################################################
                    ##   Assume ANYTHING unknown is the start of an exception   ##
                    ##############################################################
                    Write-Host -NoNewline $ActiveParser.ParsedLine.ActiveLine -ForegroundColor $clrWarning -Separator ":"
                    $ActiveParser.ParsedLine.Exception = $true
                }
            }
        }
    }
}

function Highlight_Numbers() {
    $Numeric = @(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, "+")
    if ($args[0] -ne "") {
        $Parts = $args[0].trim().ToString().split(" ")
        foreach ($part in $Parts) {
            if ($part.Substring(0, 1) -in $Numeric) {
                # fix for Numeric values without trailing ' '
                # eg - You eat the fruit and icrease your Attack and Defense! Power Fruit α's multiplier increased from <b>0%</b> to <b>4.489E+007%</b>.You've also gained 23982 Seeds!
                if ($part.EndsWith('%.')) {
                    Write-Host -NoNewline $part.Substring(0, $part.Length - 1) -ForegroundColor $clrSignificantData
                    Write-Host -NoNewline '. ' -ForegroundColor $clrINFO
                }
                else {
                    Write-Host -NoNewline $part, "" -ForegroundColor $clrSignificantData
                }

            }
            else {
                Write-Host -NoNewline $part, "" -ForegroundColor $clrINFO
            }
        }
    }
}

function Parse_pitspin_Keywords() {
    switch ($ActiveParser.ParsedLine.KeyWord) {
        "Money Pit Reward" {
            Write-Host -NoNewline $ActiveParser.ParsedLine.KeyWord, ": " -ForegroundColor $clrMoneyPitReward -Separator ""
            Highlight_Numbers($ActiveParser.ParsedLine.Parts[1])
        }
        # Fix for Daily Spin Rewards Not Highlighting numbers
        "Daily Spin Reward" {
            Write-Host -NoNewline $ActiveParser.ParsedLine.KeyWord, ": " -ForegroundColor $clrINFO -Separator ""
            Highlight_Numbers($ActiveParser.ParsedLine.Parts[1])
        }
        "You Gained" {
            Write-Host -NoNewline $ActiveParser.ParsedLine.KeyWord, ": " -ForegroundColor $clrINFO -Separator ""
            # Following lines are to be indented
            $ActiveParser.ParsedLine.IndentLevel = 1
        }
        default {
            # Fix for Incorrect number highlighting when no space separating value and Non-digit word
            $ActiveParser.ParsedLine.ActiveLine = $ActiveParser.ParsedLine.ActiveLine.Replace("%.", "%. ")
            if ($ActiveParser.ParsedLine.IndentLevel -eq 1) {
                Write-Host -NoNewline "  "
                Write-Host -NoNewline "          "
            }
            Highlight_Numbers($ActiveParser.ParsedLine.ActiveLine)
            # Detection of Lines needing indentaion extended
            if ($ActiveParser.ParsedLine.IndentLevel -eq 1 -and
                (
                    $ActiveParser.ParsedLine.ActiveLine.StartsWith('And') -or $ActiveParser.ParsedLine.ActiveLine.StartsWith('+')
                )
            ) {
                $ActiveParser.ParsedLine.IndentLevel = 0
            }
            # Clear indentation when necessary
            if ($ActiveParser.ParsedLine.ActiveLine.EndsWith('You also gain:') -or $ActiveParser.ParsedLine.ActiveLine.EndsWith('but you gain:')) {
                $ActiveParser.ParsedLine.IndentLevel = 1
            }
        }
    }
}

function CardsCastParser(){
    param (
        $CardsCastStr
    )

    $clrCost = $clrCardsField
    $clrQuality = $clrCardsField
    $clrType = $clrCardsField

    $CardsCastStr = $CardsCastStr -replace " Bonus Type", " BonusType"
    $SubParts = $CardsCastStr.split(" ").Trim()
    $TrashReason = ""    
    # Trashed Cards 
    if ($SubParts.count -gt 6)
    {
        $SubParts[5] = $SubParts[5].trim(",")
        $TrashReason = $SubParts[8]
        if ($global:CardsSmartDisplay){
            switch ($TrashReason) {
                "Cost" {
                    $clrCost = $clrSignificantData
                }
                "Quality" {
                    $clrQuality = $clrSignificantData
                }
                "trash" {
                    $clrType = $clrSignificantData
                }
            }
        }
    }
    $SubParts[3] = $SubParts[3] + " " * (12 - $SubParts[3].length)
    Write-Host -NoNewline $SubParts[0],"" -ForegroundColor $clrCost
    Write-Host -NoNewline $SubParts[1],""  -ForegroundColor $clrSignificantData
    Write-Host -NoNewline $SubParts[2],"" -ForegroundColor $clrQuality
    Write-Host -NoNewline $SubParts[3] -ForegroundColor $clrSignificantData
    Write-Host -NoNewline " Bonus Type:","" -ForegroundColor $clrType
    Write-Host -NoNewline $SubParts[5],"" -ForegroundColor $clrSignificantData

    if (-not $global:CardsSmartDisplay) {

        if ($TrashReason.length -gt 0) {
            if ($TrashReason -eq "trash"){
                $TrashReason = "All"
            }
            $Filler = " " * (15 - $SubParts[5].length)
            Write-Host -NoNewline $Filler," Reason:","" -ForegroundColor $clrStandard
            Write-Host -NoNewline $TrashReason -ForegroundColor $clrSignificantData
        }
    }
}
function Parse_cards_Keywords() {
    switch ($ActiveParser.ParsedLine.KeyWord) {
        "Cast Card" {
            Write-Host -NoNewline $ActiveParser.ParsedLine.KeyWord, ": " -ForegroundColor $clrMoneyPitReward -Separator ""
            CardsCastParser($ActiveParser.ParsedLine.Parts[1..4].trim() -join ": ")
        }
        "Trashed Card" {
            Write-Host -NoNewline $ActiveParser.ParsedLine.KeyWord, ": " -ForegroundColor $clrMoneyPitReward -Separator ""
            CardsCastParser($ActiveParser.ParsedLine.Parts[1..4].trim() -join ": ")
        }
        default {
            Write-Host -NoNewline $ActiveParser.ParsedLine.KeyWord -ForegroundColor $clrOperational
        }
    }
}

function Parse_loot_Keywords() {
    $Parts = $ActiveParser.ParsedLine.ActiveLine.trim().split("!")
    if ($Parts[0] -like "*also dropped *") {
        $splitstr = " also dropped "
    }
    else {
        $splitstr = " dropped "
    }
    if ($Parts.Count -gt 1) {
        $Hyperbole = $Parts[1].trim()
    }
    else {
        $Hyperbole = ""
    }
    $Parts = $Parts[0].trim().split($splitstr)
    $ActiveParser.ParsedLine.Merge = ($Parts[0] -eq $ActiveParser.ParsedLine.ActiveLine -and -not $ActiveParser.ParsedLine.Line1)
    if (-not $ActiveParser.ParsedLine.Merge) {
        if (-not $ActiveParser.ParsedLine.Line1) {
            $clrSection1 = $clrINFO
        }
        else {
            $clrSection1 = $clrOperational
            $ActiveParser.ParsedLine.Line1 = $false
        }

        Write-Host -NoNewline $Parts[0] -ForegroundColor $clrSection1
        if ($Parts.count -gt 1) {
            Write-Host -NoNewline $splitstr -ForegroundColor $clrStandard
            Write-Host -NoNewline $Parts[1] -ForegroundColor $clrSignificantData
            if ($Hyperbole -ne "") {
                Write-Host -NoNewline "", $Hyperbole, "" -ForegroundColor $clrHyperbole -Separator "! "
            }
        }
    }
}

function ProcessLines() {
    param (
        [Parameter(ValueFromPipeline = $true)]
        [string]$msg = $_
    )

    foreach ($line in $msg) {
        if ($global:ColoursChanged) {
            #Disable monitoring
            $global:watcher.EnableRaisingEvents = $false

            #Cancel the change notification
            $global:ColoursChanged = $false

            #Apply any valid changes
            CheckColoursFile           

            #Re-enable monitoring
            $global:watcher.EnableRaisingEvents = $true

        }

        if ("" -ne $ActiveParser.LineFilter) {
            #Detects end of Custom Allocation Block when Filter active
            if ($ActiveParser.ParsedLine.CustomAllocation) {
                if ($line.contains(':')) {
                    $ActiveParser.ParsedLine.CustomAllocation = $false
                    Write-Host
                }
            }
            #Detects end of Settings Block when Filter active
            if ($ActiveParser.ParsedLine.SettingsActive) {
                if ($line.contains("s):") -and -not $line.EndsWith("{") ) {
                    $ActiveParser.ParsedLine.SettingsActive = $false
                    $ActiveParser.ParsedLine.IndentLevel = 0
                }
            }
        }
        # Removes Blank line in Pitspin
        if (-not ($ActiveParser.BaseFile -eq $ValidFiles[1] -and $line -eq "")) {
            $ActiveParser.ParsedLine.Populate($line)

            # Fix for Issue 1
            $ActiveParser.ParsedLine.Line1 = ($ActiveParser.ParsedLine.KeyWord -eq "Starting Loot Writer")

            if ($ActiveParser.ParsedLine.Exception) {
                ExceptionParser
            }
            if ($ActiveParser.ParsedLine.Exception) {
                Write-Host
            }
            elseif ($ActiveParser.ParsedLine.CustomAllocation) {
                CustomAllocationParser
            }
            elseif ($ActiveParser.ParsedLine.SettingsActive) {
                SettingsParser
            }
            else {
                if (-not $ActiveParser.ParsedLine.Merge) {
                    if ($ActiveParser.ParsedLine.TimeStamp -ne $ActiveParser.LastTimeStamp) {
                        # Display New Minute
                        Write-Host -NoNewline $ActiveParser.ParsedLine.TimeStamp -ForegroundColor $clrStandard
                        # Store New value
                        $ActiveParser.LastTimeStamp = $ActiveParser.ParsedLine.TimeStamp
                    }
                    else {
                        Write-Host -NoNewline $ActiveParser.ParsedLine.filler
                    }
                    Write-Host -NoNewline ": " -ForegroundColor $clrStandard
                }
                # _dir
                # $"{(int)e.Item.Tag} - {e.Item.Checked}"
                # e.ToString()
                switch ($ActiveParser.BaseFile) {
                    $ValidFiles[0] {
                        Parse_inject_Keywords
                    }
                    $ValidFiles[1] {
                        Parse_pitspin_Keywords
                    }
                    $ValidFiles[2] {
                        Parse_loot_Keywords
                    }
                    $ValidFiles[3] {
                        Parse_cards_Keywords
                    }
                    Default {
                        Parse_inject_Keywords
                    }
                }
                if ( -not $ActiveParser.ParsedLine.Merge) {
                    Write-Host
                }
            }
        }
    }
}

function CapValues() {
    param (
        $strCompareValue
    )
    $Values = $strCompareValue -join "."
    $Values = $Values -replace " softcap", ""
    $Values = $Values.split("(").trim().split(")").trim()

    [double]$value = $Values[0]
    [double]$limit = $Values[1]
    $Values[1] = "(" + $Values[1] + " softcap)."
    $clrValue = $clrSignificantData

    if ($value -le $limit) {
        $clrValue = $clrSignificantData
    }
    else {
        $clrValue = $clrWarning
    }
    Write-Host -NoNewline $Values[0] -ForegroundColor $clrValue
    Write-Host -NoNewline "", $Values[1] -ForegroundColor $clrStandard
}

function SelectFromArray( ) {
    param (
        $s_Selected,
        $a_Array
    )
    ForEach ($s_item in $a_Array) {
        Write-Host -NoNewline " "
        If ( $s_item -eq $s_Selected ) {
            Write-Host -NoNewline $s_item -BackgroundColor White -ForegroundColor Black
        }
        else {
            Write-Host -NoNewline $s_item 
        }
    }
    Write-Host
}

function DisplayMenu() {
    Clear-Host
    Write-Host 
    Write-Host -NoNewline "M " -ForegroundColor $clrSignificantData; Write-Host -NoNewline "Change Mode:`t`t"; SelectFromArray $ActiveParser.DisplayMode $ValidModes
    Write-Host -NoNewline "F " -ForegroundColor $clrSignificantData; Write-Host -NoNewline "Change File:`t`t"; SelectFromArray $ActiveParser.BaseFile $ValidFiles
    Write-Host -NoNewline "E " -ForegroundColor $clrSignificantData; Write-Host -NoNewline "Enter Filter`t`t"
    if ($ActiveParser.LineFilter) {
        Write-Host $ActiveParser.LineFilter
    }
    else {
        Write-Host "NO FILTER ACTIVE"
    }
    Write-Host -NoNewline "H " -ForegroundColor $clrSignificantData; Write-Host "Help"
    Write-Host
    Write-Host -NoNewline "P " -ForegroundColor $clrSignificantData; Write-Host "Parse with Highlighted Options"
    Write-Host
    Write-Host -NoNewline "Q " -ForegroundColor $clrSignificantData; Write-Host "Quit"
    Write-Host
    Write-Host -NoNewline "`t`t`tIf no option selected for 10 seconds, Parsing will start with Highlighted Options" -ForegroundColor $clrSignificantData
    Write-Host
}

function Menu() {
    [string]$RunOpt = ''

    $ValidInput = @("M", "F", "E", "H", "P", "Q")
    $StopWatchRestartOptions = @("M", "F", "E")

    DisplayMenu
    $ActiveParser.StopWatch.Start()
    while ($RunOpt -eq '') {
        if ([console]::KeyAvailable) {

            $RunOpt = [System.Console]::ReadKey("NoEcho").KeyChar
            switch ($RunOpt.ToUpper()) {
                { $PSItem -in $StopWatchRestartOptions } {
                    $ActiveParser.StopWatch.stop()
                }
                'M' {
                    $ActiveParser.DisplayMode = $ValidModes[($ValidModes.indexof($ActiveParser.DisplayMode) + 1) % $ValidModes.length]
                }
                'F' {
                    $ActiveParser.BaseFile = $ValidFiles[($ValidFiles.indexof($ActiveParser.BaseFile) + 1) % $ValidFiles.length]
                }
                'E' {
                    $TempLineFilter = Read-Host -Prompt "Enter a filter"
                    $TempLineFilter = $TempLineFilter.TrimStart("*").TrimEnd("*")

                    if ($TempLineFilter -and $TempLineFilter -in $InvalidLineFilters) {
                        #Traps invalid/ridiculous entries
                        [console]::Beep(1000, 100)
                    }
                    elseif ($TempLineFilter -and $TempLineFilter -ne "") {
                        #Prepare regex search string
                        $ActiveParser.LineFilter = ParseLineFilter($TempLineFilter)
                    }
                    else {
                        $ActiveParser.LineFilter = $NULL
                    }

                }
                { $PSItem -in $StopWatchRestartOptions } {
                    $RunOpt = ''
                    DisplayMenu
                    $ActiveParser.StopWatch.Restart()
                }
                default {
                    if ($RunOpt -notin $ValidInput) {
                        [console]::Beep(1000, 100)
                        $RunOpt = ''
                    }
                }
            }
        }
        elseif ($ActiveParser.StopWatch.Elapsed.Seconds -ge 10) {
            $RunOpt = "P"
        }
    }
    Clear-Host
    return $RunOpt
}

function DisplayHelp() {
    Write-Host "This script attempts to pretty print the NGUIdleInjector log files"
    Write-Host
    Write-Host "There are 2 options"
    Write-Host
    Write-Host "1 - runs continuously displaying the last $MaxTailItems lines added. Exit by pressing Ctrl-C"
    Write-Host "2 - Processes the entire file"
    Write-Host
    Write-Host "Colours are defined using the clr... variables at the top of the script. Change these as you will."
    Write-Host
    Write-Host "clrSignificantData" -ForegroundColor $clrSignificantData -NoNewline; " - used to identify Significant Data (surprise!)"
    Write-Host "clrINFO" -ForegroundColor $clrINFO -NoNewline; "            - used to identify Information Labels"
    Write-Host "clrWarning" -ForegroundColor $clrWarning -NoNewline; "         - used to identify either Exception messages OR Significant Data exceeding the CAP "
    Write-Host "clrOperational" -ForegroundColor $clrOperational -NoNewline; "     - used to identify Operational Messages"
    Write-Host "clrSettings" -ForegroundColor $clrSettings -NoNewline; "        - used to identify Settings defined in profiles"
    Write-Host "clrException" -ForegroundColor $clrException -NoNewline; "       - used to identify details of an exception"
    Write-Host
    Write-Host "The Time-stamp fields have the seconds component removed, and only display when a change in time occurs."
    Write-Host
    Write-Host "When either the Cube Power or Toughness exceed the softcap, this will be highlighted with the clrWarning colour"
    Write-Host
    Write-Host "Any unknown command will be treated as an exception"
    Write-Host
    Write-Host "This is my first attempt at a <relatively minor> PS script, so forgive any clumsiness in the code. It requires PS7 "
    Write-Host "It requires PS 7, and will abort if run in any earlier version"
    Write-Host
    Read-Host -Prompt "Press Enter to Exit" -MaskInput
}

function Execute() {

    $host.ui.RawUI.WindowTitle = $ActiveParser.BaseFile
    if ($ActiveParser.LineFilter) {
        # Include No of terms and filter in title
        $NoTerms=$ActiveParser.LineFilter.split("|").count
        $Terms = $NoTerms, "term" -join " "
        if ($NoTerms -gt 1)
        {
            $Terms += "s"
        }
        $host.ui.RawUI.WindowTitle = $host.ui.RawUI.WindowTitle, $Terms, "- (", $ActiveParser.LineFilter, ")"
    }

    $global:watcher.EnableRaisingEvents = $true

    if ($ActiveParser.DisplayMode -eq $ValidModes[0]) {
        # Tail mode switch to -match to allow for regex
        if ($ActiveParser.LineFilter) {
            Get-Content $ActiveParser.Location() -Tail $MaxTailItems -Wait | Where-Object { $_ -match $ActiveParser.LineFilter } | ForEach-Object { ProcessLines }
        }
        else {
            Get-Content $ActiveParser.Location() -Tail $MaxTailItems -Wait | ForEach-Object { ProcessLines }
        }
    }
    else {
        $ActiveParser.StopWatch.Restart()
        # Full mode switch to Select-String to allow for regex - and faster processing
        if ($ActiveParser.LineFilter) {
            Select-String -Path $ActiveParser.Location() -Pattern $ActiveParser.LineFilter| ForEach-Object {ProcessLines($_.tostring().split(':')[3..10] -join ':')}
        }
        else {
            Select-String -Path $ActiveParser.Location() -Pattern '.*' | ForEach-Object {ProcessLines($_.tostring().split(':')[3..10] -join ':')}
        }
        Write-Host "File Processing time :", $ActiveParser.StopWatch.Elapsed
        Read-Host -Prompt "Press Enter to Exit" -MaskInput

    }
}

function run() {

    switch (Menu) {
        "P" {
            Execute
        }
        "H" {
            DisplayHelp
        }
        "Q" {}
    }
}
