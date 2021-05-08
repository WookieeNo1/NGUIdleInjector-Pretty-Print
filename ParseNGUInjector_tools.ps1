#########################################
## Requires NGUInjectorPrettyPrint.ps1 ##
## Requires NGUInjectorPrettyPrint.ps1 ##
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

$clrSignificantData = 10
$clrINFO = 11
$clrWarning = 12
$clrOperational = 14
$clrSettings = 3
$clrException = 4

#Allows for Inject, PitSpin and Loot logs
$BaseFile="inject.log"

class LogParserSettings {
    [string]$LastTimeStamp = ""
    [string]$filler = ""
}

function MergeParser
{
    param (
        $MergeStr
    )
    $Parts=$MergeStr.trim().split(" in slot ",2)
    Write-Host -NoNewline $Parts[0] -ForegroundColor $clrSignificantData
    Write-Host -NoNewline " in slot "
    Write-Host -NoNewline $Parts[1] -ForegroundColor $clrSignificantData
}

function MissingParser
{
    param (
        $MergeStr
    )
    $Parts=$MergeStr.trim().split(" with ID ",2)
    Write-Host -NoNewline $Parts[0] -ForegroundColor $clrSignificantData
    Write-Host -NoNewline " with ID "
    Write-Host -NoNewline $Parts[1] -ForegroundColor $clrSignificantData
}

Function ButteringParser() 
{
    param (
        $ButterStr
    )
    $Parts=$ButterStr.trim().split(" ",2)
    Write-Host -NoNewline " "
    Write-Host -NoNewline $Parts[0] -ForegroundColor $clrSignificantData
    Write-Host -NoNewline " "
    Write-Host -NoNewline $Parts[1] -ForegroundColor $clrINFO

}
Function RemovingParser() 
{
    param (
        $RemovingStr
    )
    $Parts=$RemovingStr.trim().split(" ")
    Write-Host -NoNewline $Parts[0..3] -ForegroundColor $clrINFO
    Write-Host -NoNewline " "
    Write-Host -NoNewline $Parts[4] -ForegroundColor $clrSignificantData
}

Function SettingsParser() 
{
    #remove date string if present - fudge
    if ( $ParsedLine.Raw -like "*:*" -and $ParsedLine.SettingsFirst)
    {
        $ParsedLine.ActiveLine=$ParsedLine.Raw.split(":")[2]
        $ParsedLine.Populate($ParsedLine.ActiveLine)
        $ParsedLine.Raw=$ParsedLine.ActiveLine
    }

    $SettingsFiller = "          " * $ParsedLine.IndentLevel

    Write-Host -NoNewline $ParsedLine.filler

    if ($ParsedLine.SettingsFirst)
    {
        $ParsedLine.SettingsFirst = $false

        Write-Host -NoNewline "  "
        Write-Host -NoNewline $SettingsFiller
        Write-Host -NoNewline $ParsedLine.Parts[0] -ForegroundColor $clrSettings

        $ParsedLine.IndentLevel=$ParsedLine.IndentLevel + 1
    }
    elseif ($ParsedLine.SettingsArray) 
    {
        if ($ParsedLine.Parts[0].trim().StartsWith("]"))
        {
            $ParsedLine.IndentLevel=$ParsedLine.IndentLevel - 1
            $SettingsFiller = "          " * $ParsedLine.IndentLevel
            $ParsedLine.SettingsArray=$false
            $clrArray = $clrSettings
        }
        else
        {
            $clrArray = $clrSignificantData
        }

        Write-Host -NoNewline $SettingsFiller
        Write-Host -NoNewline $ParsedLine.Parts[0].trim().split(",") -ForegroundColor $clrArray -Separator ""
        if ($ParsedLine.Parts[0].trim().EndsWith(",")) 
        {
            Write-Host -NoNewline "," -ForegroundColor $clrSettings -Separator ""
        }
    }
    else 
    {
        if ($ParsedLine.Parts[0] -eq "}")
        {
            $ParsedLine.IndentLevel=0
            $ParsedLine.SettingsActive = $false

            Write-Host -NoNewline "  "
            Write-Host -NoNewline $ParsedLine.Parts[0] -ForegroundColor $clrSettings
        }
        elseif ($ParsedLine.Parts.count -eq 2) {
            Write-Host -NoNewline $SettingsFiller
            Write-Host -NoNewline $ParsedLine.Parts[0],": " -ForegroundColor $clrSettings -Separator ""
            if ($ParsedLine.Parts[1].Trim() -eq "[")
            {
                $ParsedLine.SettingsArray=$true
                $ParsedLine.IndentLevel=$ParsedLine.IndentLevel + 1
                Write-Host -NoNewline $ParsedLine.Parts[1] -ForegroundColor $clrINFO -Separator ""
            }
            else 
            {
                if ($ParsedLine.Parts[1].Trim() -eq "[],")
                {
                    $clrItem = $clrSettings
                }
                else
                {
                    $clrItem = $clrSignificantData
                }

                Write-Host -NoNewline $ParsedLine.Parts[1].Trim().split(",") -ForegroundColor $clrItem -Separator ""
                if ($ParsedLine.Parts[1].EndsWith(",")) 
                {
                    Write-Host -NoNewline "," -ForegroundColor $clrSettings -Separator ""
                }
            }
        }
        else 
        {
            Write-Host -NoNewline $Parts.split(",") -ForegroundColor $clrSignificantData -Separator ""
            if ($Parts.EndsWith(",")) 
            {
                Write-Host -NoNewline "," -ForegroundColor $clrSettings -Separator ""
            }
        }
    }
    Write-Host
}
Function CustomAllocationParser() 
{
    $Parts = $ParsedLine.Parts[0].split(" ",2).Trim()
    if ($ParsedLine.KeyWord -eq "Challenge targets")
    {
        Write-Host
        Write-Host -NoNewline $ParsedLine.filler, $ParsedLine.filler -Separator ""
        Write-Host -NoNewline $ParsedLine.KeyWord,": " -ForegroundColor $clrINFO -Separator ""
    }
    elseif ($ParsedLine.KeyWord -eq "Rebirthing") {
        Write-Host -NoNewline $ParsedLine.filler, $ParsedLine.filler -Separator ""
        Write-Host -NoNewline $ParsedLine.KeyWord,"" -ForegroundColor $clrINFO -Separator " "
    }
    else {
        Write-Host -NoNewline $ParsedLine.filler, $ParsedLine.filler -Separator ""
        Write-Host -NoNewline $Parts[0],"" -ForegroundColor $clrSignificantData
    }

    if ($ParsedLine.KeyWord -eq "Rebirthing") 
    {
        $SubParts = $ParsedLine.ActiveLine.split(" ").Trim()
        if ($ParsedLine.Raw.StartsWith("Rebirth Disabled.")){
            # "Rebirth Disabled."
            Write-Host -NoNewline $SubParts[1] -ForegroundColor $clrSettings
        }
        elseif ($ParsedLine.Raw.StartsWith("Rebirthing at")){
            # "Rebirthing at {trb.RebirthTime} seconds"
            Write-Host -NoNewline $SubParts[1],"" -ForegroundColor $clrSettings
            Write-Host -NoNewline $SubParts[2],"" -ForegroundColor $clrSignificantData
            Write-Host -NoNewline $SubParts[3],"" -ForegroundColor $clrSettings
        }        
        elseif ($ParsedLine.Raw.StartsWith("Rebirthing when number bonus is"))
        {
            # "Rebirthing when number bonus is {nrb.MultTarget}x previous number"
            Write-Host -NoNewline $SubParts[1..4],"" -ForegroundColor $clrSettings -Separator " "
            Write-Host -NoNewline $SubParts[5],"" -ForegroundColor $clrSignificantData
            Write-Host -NoNewline $SubParts[6..7],"" -ForegroundColor $clrSettings -Separator " "
        }        
        elseif ($ParsedLine.Raw.StartsWith("Rebirthing when number allows you")){
            # "Rebirthing when number allows you +{brb.NumBosses} bosses"
            Write-Host -NoNewline $SubParts[1..4],"" -ForegroundColor $clrSettings -Separator " "
            Write-Host -NoNewline $SubParts[5],"" -ForegroundColor $clrSignificantData
            Write-Host -NoNewline $SubParts[6..7],"" -ForegroundColor $clrSettings -Separator " "
        }
    }
    elseif ($ParsedLine.KeyWord -eq "Challenge targets"){
        $SubParts = $ParsedLine.Parts[1].split(",").Trim()
        foreach($Challenge in $SubParts)
        {
            Write-Host
            Write-Host -NoNewline $ParsedLine.filler, $ParsedLine.filler, $ParsedLine.filler -Separator ""
            Write-Host -NoNewline $Challenge,"" -ForegroundColor $clrSignificantData -Separator ""
            if ($Challenge -ne $SubParts[$SubParts.Count -1])
            {
                Write-Host -NoNewline "," -ForegroundColor $clrSettings -Separator ""
            }
        }
    }
    else 
    {
        Write-Host $Parts[1] -ForegroundColor $clrSettings
    }

    if ($ParsedLine.Raw -eq "")
    {
        $ParsedLine.CustomAllocation = $false
    }
}

function LoadedParser
{
    param (
        $LoadedStr
    )
    $Parts=$LoadedStr.trim().split(" ")
    Write-Host -NoNewline $Parts[0..4],"" -ForegroundColor $clrINFO -Separator " "
    Write-Host -NoNewline " "
    Write-Host -NoNewline $Parts[5] -ForegroundColor $clrSignificantData
}

function CastParser
{
    param (
        $CastStr
    )
    $Parts=$CastStr.trim().split(" ")
    Write-Host -NoNewline $Parts[0..1],"" -ForegroundColor $clrINFO -Separator " "
    Write-Host -NoNewline $Parts[2] -ForegroundColor $clrSignificantData
    Write-Host -NoNewline " "
    Write-Host -NoNewline $Parts[3],"" -ForegroundColor $clrINFO -Separator " "
    Write-Host -NoNewline $Parts[4] -ForegroundColor $clrSignificantData
    Write-Host -NoNewline
}

function BoostParser
{
    param (
        [string]$BoostStr
    )

    $SplitStr = ', '

    $Boosts=$BoostStr.trim().split($SplitStr).trim()
	$MaxBoosts=$Boosts.length - 1

    foreach($ActiveBoost in $Boosts)
    {
        $ThisBoost=$ActiveBoost.trim().split()

        Write-Host -NoNewline $ThisBoost[0] -ForegroundColor $clrSignificantData
        Write-Host -NoNewline " "
        Write-Host -NoNewline $ThisBoost[1]

        if ([array]::indexof($Boosts,$ActiveBoost) -lt $MaxBoosts)
		{
			Write-Host -NoNewline $SplitStr
		}
    }
}

function ExceptionParser()
{
#    param ([Parameter(Mandatory=$true)][ref]$ExceptionStr)

    if ($ParsedLine.Parts[0].TrimStart().StartsWith( "at "))
    {
        Write-host -NoNewline $ParsedLine.Parts[0] -ForegroundColor $clrException
    }
    else 
    {
        $ParsedLine.Exception = $false
    }
}

class LogLine {
    [string]$Raw=""
    [string]$TimeStamp=""
    [string]$Filler=""
    [string]$KeyWord=""
    [string]$ActiveLine=""
    [System.Collections.ArrayList]$Parts
    [bool]$SettingsActive = $false
    [bool]$SettingsFirst = $false
    [bool]$SettingsArray = $false
    [int]$IndentLevel = 0
    [bool]$CustomAllocation = $false
    [bool]$Exception = $false
    [bool]$Merge = $false
    [bool]$Line1 = $true

    [void] Populate([string]$str)
    {
        [bool]$DateStripped = $false
        $str= $str.Replace("<b>", "")
        $str= $str.Replace("</b>", "")

        $this.Raw = $str
        $this.Parts = @($str.trim().split(":"))
        if ($this.Parts.Count -gt 2) {
            # Remove Seconds component - output will only show changes in minutes, filling with space within the same minute
            $this.TimeStamp = $this.Parts[0].trim()+":"+$this.Parts[1].trim()
            $this.TimeStamp = $this.TimeStamp.split("(").trim()[0]
            #Timestamp is now fixed length
            $this.TimeStamp = $this.TimeStamp + " " * (19 - $this.TimeStamp.length)
            $DateStripped = $true
            $this.filler = " " * $this.TimeStamp.length
            $this.Parts.RemoveRange(0,2)
            if ($this.Exception){
                $this.Parts[0]="  "+($this.Parts -Join ":").ToString().TrimStart(" ")
                while ($this.Parts.Count -gt 1){
                    $this.Parts.RemoveRange($this.Parts.Count-1,1)
                }
            }
        }
        if ($this.Merge)
        {
            $this.Parts[0] = $this.KeyWord.trim()+" "+$this.Parts[0].trim()
            $this.ActiveLine = $this.Parts[0]
        }
        elseif ($this.Exception -and -not $DateStripped)
        {
            $this.Parts[0]=$this.Raw
            while ($this.Parts.Count -gt 1){
                $this.Parts.RemoveRange($this.Parts.Count-1,1)
            }
        }
        elseif ($this.Parts.Count -gt 1) {
            $this.KeyWord = $this.Parts[0].trim()
            $this.ActiveLine=$this.Parts.Trim() -join ":" 
        }
        else {
            $this.KeyWord = $this.Parts[0].ToString().Trim()
            $this.ActiveLine = $this.Parts[0].ToString().Trim()
        }
        switch($this.KeyWord.split(" ")[0]){
            "Casting" {
                $this.KeyWord = "Casting Failed"
                $this.Parts[0] = $this.KeyWord
                $this.Parts.Add($this.ActiveLine.split(" - ",2)[0])
                $this.Parts[1]=$this.Parts[1].Replace($this.KeyWord,"").Trim()
                $this.Parts.Add($this.ActiveLine.split(" - ",2)[1])
            }
            "Merging"{
                $this.Parts=$this.ActiveLine.split(" ",2)
            }
            # $"Missing item {Controller.itemInfo.itemName[itemId]} with ID {itemId}"
            "Missing" {
                $this.KeyWord = "Missing item"
                $this.Parts[0]=$this.Parts[0].Replace($this.KeyWord,"").Trim()
            }
            "Rebirthing"{
                $this.KeyWord = "Rebirthing"
                $this.Parts[0]=$this.Parts[0].Replace($this.KeyWord,"").Trim()
            }
            "Removing"{
                $this.Parts=$this.ActiveLine.split(" ")
            }
            "Saved" {
                if ($this.ActiveLine.split(" ")[1] -eq "Loadout")
                {
                    $this.KeyWord = "Saved Loadout"
                    $this.Parts[0] = $this.KeyWord
                    $this.Parts.Add($this.ActiveLine.split(" ",3)[2])
                }
            }
            "Upgrading"{
                $this.KeyWord = "Upgrading Digger"
                $this.Parts[0] = $this.KeyWord
                $this.Parts.Add($this.ActiveLine.split(" ",3)[2])
            }
            default {}
        }
    }
}

function Parse_inject_Keywords{

    switch ($ParsedLine.KeyWord)
    {
        # $"Boosts Needed to Green: {needed.Power} Power, {needed.Toughness} Toughness, {needed.Special} Special"
        "Boosts Needed to Green" { 
            Write-Host -NoNewline $ParsedLine.KeyWord,": " -ForegroundColor $clrINFO -Separator ""
            BoostParser($ParsedLine.Parts[1])
        }
        # "Casting Failed Blood MacGuffin A Spell - Insufficient Power " + mcguffA +" of " + Main.Settings.BloodMacGuffinAThreshold
        # "Casting Failed Blood MacGuffin B Spell - Insufficient Power " + mcguffB +" of " + Main.Settings.BloodMacGuffinBThreshold
        # "Casting Failed Iron Blood Spell - Insufficient Power " + iron + " of " + Main.Settings.IronPillThreshold
        "Casting Failed" {
            Write-Host -NoNewline $ParsedLine.KeyWord," " -ForegroundColor $clrINFO -Separator ""
            Write-Host -NoNewline $ParsedLine.Parts[1] -ForegroundColor $clrSignificantData
            Write-Host -NoNewline " - " -ForegroundColor $clrINFO
            CastParser($ParsedLine.Parts[2])
        }

        # $"Cube Power: {cube.Power} ({_character.inventoryController.cubePowerSoftcap()} softcap). Cube Toughness: {cube.Toughness} ({_character.inventoryController.cubeToughnessSoftcap()} softcap)"
        "Cube Power" {
            #Power Toughness
            $CubePower =$ParsedLine.Parts[1].trim().split(".")
            $CubeTough =$ParsedLine.Parts[2].trim().split(".")

            Write-Host -NoNewline "Cube Power: " -ForegroundColor $clrINFO -Separator ""
            CapValues($CubePower[0..2].trim())

            Write-Host -NoNewline " Cube Toughness: " -ForegroundColor $clrINFO -Separator ""
            CapValues($CubeTough[0..2].trim())
        }
        # output
        #     Cube Progress: ... Power. Average Per Minute: ...
        "Cube Progress" {
            Write-Host -NoNewline $ParsedLine.KeyWord,": " -ForegroundColor $clrINFO -Separator ""
            Write-Host -NoNewline $ParsedLine.Parts[1..2].trim() -ForegroundColor $clrSignificantData -Separator ":"
        }
        # $"Equipping Diggers: {string.Join(",", diggers.Select(x => x.ToString()).ToArray())}"
        "Equipping Diggers" {
            Write-Host -NoNewline $ParsedLine.KeyWord,": " -ForegroundColor $clrINFO -Separator ""
            Write-Host -NoNewline $ParsedLine.Parts[1].trim() -ForegroundColor $clrSignificantData
        }
        # $"Equipped Items: {items}"
        "Equipped Items" {
            Write-Host -NoNewline $ParsedLine.KeyWord,": " -ForegroundColor $clrINFO -Separator ""
            Write-Host -NoNewline $ParsedLine.Parts[1].trim() -ForegroundColor $clrSignificantData
        }

        # $"Failed to load quicksave: {e.Message}" ---- NOT YET DONE
        # $"Failed to read quicksave: {e.Message}" ---- NOT YET DONE

        # "Injected"
        "Injected" {
            Write-Host -NoNewline $ParsedLine.KeyWord -ForegroundColor $clrOperational 
        }
        # $"Key: {index}"
        "Key" {
            Write-Host -NoNewline $ParsedLine.KeyWord,": " -ForegroundColor $clrINFO -Separator ""
            Write-Host -NoNewline $ParsedLine.Parts[1].trim() -ForegroundColor $clrSignificantData
        }
        # $"Last Minute: {diff}." ---- NOT YET DONE
        # $"Last Minute: {diff}. Average Per Minute: {average:0}. ETA: {eta:0} minutes."
        "Last Minute" { 
            Write-Host -NoNewline $ParsedLine.KeyWord,": " -ForegroundColor $clrINFO -Separator ""
            Write-Host -NoNewline $ParsedLine.Parts[1..2].trim(),"" -Separator ": "
            $Parts=$ParsedLine.Parts[3].trim().split(" ")
            Write-Host -NoNewline $Parts[0].trim(),"" -ForegroundColor $clrSignificantData
            Write-Host -NoNewline $Parts[1].trim(),""
        }
        # "Loaded Settings"
        "Loaded Settings" {
            Write-Host -NoNewline $ParsedLine.KeyWord -ForegroundColor $clrOperational
            $ParsedLine.SettingsActive=$true
            $ParsedLine.SettingsFirst=$true
        }

        # $"Loaded Zone Overrides: {string.Join(",", overrides.ToArray())}"
        "Loaded Zone Overrides" { 
            Write-Host -NoNewline $ParsedLine.KeyWord,": " -ForegroundColor $clrINFO -Separator ""
            Write-Host -NoNewline $ParsedLine.Parts[1].trim() -ForegroundColor $clrSignificantData
        }
        # $"Missing item {Controller.itemInfo.itemName[itemId]} with ID {itemId}"
        "Missing item" {
            Write-Host -NoNewline $ParsedLine.KeyWord,": " -ForegroundColor $clrINFO -Separator ""
            MissingParser($ParsedLine.Parts[0])
        }

        # $"Received New Gear: {string.Join(",", gearIds.Select(x => x.ToString()).ToArray())}"
        "Received New Gear" {
            Write-Host -NoNewline $ParsedLine.KeyWord,": " -ForegroundColor $clrINFO -Separator ""
            Write-Host -NoNewline $ParsedLine.Parts[1].trim() -ForegroundColor $clrSignificantData
        }
        # $"Saved Loadout {string.Join(",", _savedLoadout.Select(x => x.ToString()).ToArray())}"
        # $"Saved Loadout {string.Join(",", _tempLoadout.Select(x => x.ToString()).ToArray())}"
        "Saved Loadout" {
            Write-Host -NoNewline $ParsedLine.KeyWord,": " -ForegroundColor $clrINFO -Separator ""
            Write-Host -NoNewline $ParsedLine.Parts[1].trim() -ForegroundColor $clrSignificantData
        }
        # "Upgrading Digger " + _cheapestDigger
        "Upgrading Digger" {
            Write-Host -NoNewline $ParsedLine.KeyWord,"" -ForegroundColor $clrINFO
            Write-Host -NoNewline $ParsedLine.Parts[1].trim() -ForegroundColor $clrSignificantData
        }

        default {
            $ParsedLine.KeyWord = $ParsedLine.ActiveLine.trim().split(" ",2)[0].TRIM()

            $ParseSub=$ParsedLine.ActiveLine.split(" ",2)

            switch ($ParsedLine.KeyWord)
            {
# "Bad save version"

# $"Buying {numPurchases} {t} purchases"

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
                    Write-Host -NoNewline $ParsedLine.ActiveLine -ForegroundColor $clrINFO
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
                    Write-Host -NoNewline $ParsedLine.ActiveLine -ForegroundColor $clrINFO
                }
                # "Failed to load allocation file. Resave to reload"
                "Failed" {
                    Write-Host -NoNewline $ParsedLine.ActiveLine -ForegroundColor $clrINFO
                }
                # "Finished equipping gear"
                "Finished" {
                    Write-Host -NoNewline $ParsedLine.ActiveLine -ForegroundColor $clrINFO
                }
                # "Gold Loadout kill done. Turning off setting and swapping gear"
                "Gold" {
                    Write-Host -NoNewline $ParsedLine.ActiveLine -ForegroundColor $clrINFO
                }
                # "Harvesting without swap because threshold not met"
                "Harvesting" {
                    Write-Host -NoNewline $ParsedLine.ActiveLine -ForegroundColor $clrINFO
                }
                #Loaded Custom Allocation from profile
                "Loaded" {
                    LoadedParser($ParsedLine.Parts)
                    $ParsedLine.CustomAllocation = $true
                }

# "Loading quicksave"

                # $"Merging {SanitizeName(target.name)} in slot {target.slot}"
                # $"Merging {target.name} in slot {target.slot}"
                "Merging" {
                    Write-Host -NoNewline $ParsedLine.KeyWord,"" -ForegroundColor $clrINFO 
                    MergeParser($ParsedLine.Parts[1])
                }
# $"Moving to ITOPOD to idle."

                # "Normal Rebirth Engaged"
                "Normal" {
                    Write-Host -NoNewline $ParsedLine.ActiveLine -ForegroundColor $clrINFO
                }

# "Quicksave doesn't exist"

# $"Rebirthing into {rbType}"
                "Rebirthing" {
                    Write-Host -NoNewline $ParsedLine.KeyWord -ForegroundColor $clrWarning
                    $Parts=$ParsedLine.ActiveLine.trim().split(" into ",2)
                    Write-Host -NoNewline " into " -ForegroundColor $clrINFO
                    Write-Host -NoNewline $Parts[1] -ForegroundColor $clrSignificantData
                }
                # $"Removing energy for fruit {i}"
                # $"Removing magic for fruit {i}"
                "Removing" {
                    Write-Host -NoNewline $ParsedLine.Parts[0],"" -ForegroundColor $clrINFO -Separator " "
                    Write-Host -NoNewline $ParsedLine.Parts[1],"" -ForegroundColor $clrSignificantData -Separator " "
                    Write-Host -NoNewline $ParsedLine.Parts[2..3],"" -ForegroundColor $clrINFO -Separator " "
                    Write-Host -NoNewline $ParsedLine.Parts[4] -ForegroundColor $clrSignificantData
                }
                # $"Restoring original loadout"
                # "Restoring Previous Loadout"
                "Restoring" {
                    Write-Host -NoNewline $ParsedLine.ActiveLine -ForegroundColor $clrINFO
                }

# $"Running money loadout for {bossId}"

                # "Saving Settings"
                "Saving" {
                    Write-Host -NoNewline $ParsedLine.ActiveLine -ForegroundColor $clrOperational 
                }

                # "Time Machine Gold is 0. Lets reset gold snipe zone."
                "Time" {
                    Write-Host -NoNewline $ParsedLine.ActiveLine -ForegroundColor $clrINFO
                }

                # $"Turning in {questItems.Length} quest items"
                # "Turning in quest"
                "Turning" {
                    Write-Host -NoNewline $ParsedLine.ActiveLine -ForegroundColor $clrINFO
                }

# "Unable to harvest now"

                # "Writing quicksave and json"
                "Writing" {
                    Write-Host -NoNewline $ParsedLine.ActiveLine -ForegroundColor $clrOperational 
                }

                default
                {
##############################################################
##   Assume ANYTHING unknown is the start of an exception   ##
##############################################################
                    Write-Host -NoNewline $ParsedLine.ActiveLine -ForegroundColor $clrWarning -Separator ":"
                    $ParsedLine.Exception = $true
                }
            }
        }
    }    
}

function Highlight_Numbers()
{
    $Numeric=@(0,1,2,3,4,5,6,7,8,9,"+")
    if ($args[0] -ne "")
    {
        $Parts=$args[0].trim().ToString().split(" ")
        foreach($part in $Parts)
        {
            if ($part.Substring(0,1) -in $Numeric) 
            {
                Write-Host -NoNewline $part,"" -ForegroundColor $clrSignificantData
            }
            else {
                Write-Host -NoNewline $part,"" -ForegroundColor $clrINFO
            }
        }
    }
}

function Parse_pitspin_Keywords()
{
    switch ($ParsedLine.KeyWord) {
        "Money Pit Reward"
        {
            Write-Host -NoNewline $ParsedLine.KeyWord,": " -ForegroundColor $clrINFO -Separator ""
            Highlight_Numbers($ParsedLine.Parts[1])
        }
        "You Gained"
        {
            Write-Host -NoNewline $ParsedLine.KeyWord,": " -ForegroundColor $clrINFO -Separator ""
        }
        default{
            Highlight_Numbers($ParsedLine.ActiveLine)
        }
    }
}

function Parse_loot_Keywords()
{
    $Parts=$ParsedLine.ActiveLine.trim().split("!")
    if ($Parts[0] -like "*also dropped *")
    {
        $splitstr=" also dropped "
    }
    else {
        $splitstr=" dropped "
    }
    if ($Parts.Count -gt 1){
        $Hyperbole = $Parts[1].trim()
    }
    else{
        $Hyperbole = ""
    }
    $Parts=$Parts[0].trim().split($splitstr)
    $ParsedLine.Merge = ($Parts[0] -eq $ParsedLine.ActiveLine -and -not $ParsedLine.Line1)
    if (-not $ParsedLine.Merge)
    {
        if  (-not $ParsedLine.Line1)
        {
            $clrSection1 = $clrINFO
        }
        else {
            $clrSection1 = $clrOperational
            $ParsedLine.Line1 = $false
        }

        Write-Host -NoNewline $Parts[0] -ForegroundColor $clrSection1
        if ($Parts.count -gt 1)
        {
            Write-Host -NoNewline $splitstr
            Write-Host -NoNewline $Parts[1] -ForegroundColor $clrSignificantData
            if ($Hyperbole -ne ""){
                Write-Host -NoNewline "",$Hyperbole,"" -ForegroundColor $clrException -Separator "! "
            }
        }
    }
}

function ProcessLines()
{
    param (
        [Parameter(ValueFromPipeline = $true)]
        [string]$msg=$_
    )

    foreach ($line in $msg) 
    {

        $ParsedLine.Populate($line)

        #Fix for Issue 1
        $ParsedLine.Line1=($ParsedLine.KeyWord -eq "Starting Loot Writer")

        if ($ParsedLine.Exception)
        {
            ExceptionParser
        }
        if ($ParsedLine.Exception)
        {
            Write-host
        }
        elseif($ParsedLine.CustomAllocation)
        {
            CustomAllocationParser
        }
        elseif ($ParsedLine.SettingsActive) 
        {
            SettingsParser
        }
        else
        {
            if (-not $ParsedLine.Merge) 
            {
                if ($ParsedLine.TimeStamp -ne $ActiveSettings.LastTimeStamp)
                {
                    #Display New Minute
                    Write-host -NoNewline $ParsedLine.TimeStamp
                    #Store New value
                    $ActiveSettings.LastTimeStamp = $ParsedLine.TimeStamp
                }
                else
                {
                    Write-host -NoNewline $ParsedLine.filler
                }
                Write-host -NoNewline ": "
            }
# _dir
# $"{(int)e.Item.Tag} - {e.Item.Checked}"
# e.ToString()
            switch ($BaseFile) {
                "inject.log" { 
                    Parse_inject_Keywords  
                }
                "pitspin.log" { 
                    Parse_pitspin_Keywords  
                }
                "loot.log" { 
                    Parse_loot_Keywords  
                }
                Default {
                    Parse_inject_Keywords  
                }
            }
            if ( -not $ParsedLine.Merge){
                Write-host
            }
        }
    }
}

function CapValues(){
    param (
        $strCompareValue
    )
    $Values= $strCompareValue -join "."
    $Values=$Values -replace " softcap",""
    $Values=$Values.split("(").trim().split(")").trim()

    [double]$value =$Values[0]
    [double]$limit =$Values[1]
    $Values[1]= "("+$Values[1]+" softcap)."
    $clrValue=$clrSignificantData

    if($value -le $limit)
    {
        $clrValue=$clrSignificantData
    }
    else 
    {
        $clrValue=$clrWarning
    }
    Write-Host -NoNewline $Values[0] -ForegroundColor $clrValue
    Write-Host -NoNewline "",$Values[1]
}

function Menu()
{
    $ValidInput = @("1", "2", "h","q")

    Clear-Host
    Write-Host -NoNewline "1 " -ForegroundColor $clrSignificantData;Write-Host "Show last 2 lines with wait (default in 5 5seconds) "
    Write-Host -NoNewline "2 " -ForegroundColor $clrSignificantData;Write-Host "Parse Full File"
    Write-Host -NoNewline "h " -ForegroundColor $clrSignificantData;Write-Host "help"
    Write-Host
    Write-Host -NoNewline "q " -ForegroundColor $clrSignificantData;Write-Host "exit"
    Write-Host

    $RunOpt = ''
    $stopWatch.Start()
    while ($RunOpt -eq '') {
        if ([console]::KeyAvailable){

            $RunOpt = [System.Console]::ReadKey("NoEcho").KeyChar
            if ($RunOpt -eq 'p') {
            }
            if ($RunOpt -notin $ValidInput) {
                [console]::Beep(1000, 100)
                $RunOpt = ''
            }
        }
        elseif ($stopWatch.Elapsed.Seconds -ge 5){
            $RunOpt = "1"
        }
    }
    Clear-Host
    return $RunOpt
}
function DisplayHelp()
{
    Write-Host "This script attempts to pretty print the NGUIdleInjector Inject.log file"
    Write-Host
    Write-Host "There are 2 options"
    Write-Host
    Write-Host "1 - runs continuously displaying the last 2 lines added. Exit by pressing Ctrl-C"
    Write-Host "2 - Processes the entire file"
    Write-Host
    Write-Host "Colours are defined using the clr... variables at the top of the script. Change these as you will."
    Write-Host
    Write-Host "clrSignificantData" -ForegroundColor $clrSignificantData -NoNewline; " - used to identify Significant Data (surpise!)"
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
}

function run()
{
    if ($PSVersionTable.PSversion.major -lt 7) 
    {
        Clear-Host
        Write-Host "Requires PowerShell v 7"
        exit
    }

    $FileName = $Env:Userprofile+"\Desktop\NGUInjector\logs\"+$BaseFile

    switch (Menu) 
    {
        "1" { 
            $host.ui.RawUI.WindowTitle = $BaseFile+“ Parser”
            Get-Content $FileName -Tail 2 -Wait| ForEach-Object{ ProcessLines ($_) } 
        }
        "2" { 
            $stopWatch.Restart()
            $host.ui.RawUI.WindowTitle = $BaseFile+“ Parser”
            Get-Content $FileName | ForEach-Object{ ProcessLines ($_) } 

            Write-Host  "File Processing time :",$stopWatch.Elapsed
            Read-Host -Prompt "Press Enter to Exit" -MaskInput
            }
        "h" { 
            DisplayHelp
            Read-Host -Prompt "Press Enter to Exit" -MaskInput
        }
        "q" {}
    }
}
