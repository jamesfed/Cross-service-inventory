#This script takes in the exports from Lansweeper, Sophos, and Heimdal to identify machines with missing agents.
#James Preston of ANSecurity, jpreston@ansecurity.com www.ansecurity.com
#Last updated 19/03/2025 09:33
#Designed for PowerShell 7.x+

#Heimdal
#https://dashboard.heimdalsecurity.com/activeclients > Download CSV.

#Sophos
#https://central.sophos.com/manage/endpoint/computers-list > Select either Recently online or all > Export to CSV.
#https://central.sophos.com/manage/server/servers-list > Select either Recently online or all > Export to CSV.

# Lansweeper
#https://YOURLANSWEEPERSERVER/Report/report.aspx?det=web50repADAssetOverview&title=Active+Directory%3a+Assets+overview > Export to CSV.

#Declare the paths to the exports.
$lansweeperpath     = "PATHTOCSV"
$sophosserverspath  = "PATHTOCSV"
$sophosclientspath  = "PATHTOCSV"
$heimdalpath        = "PATHTOCSV"

#Declare the path to save the final data to.
$exportpath         = "C:\temp\agentreport.csv"

#Import the data.
$lansweeperdata     = Import-Csv $lansweeperpath -Delimiter ";" | Where-Object -Property Type -EQ "Windows" #You may want to expand this out to non-Windows devices.
$sophosserversdata  = Import-Csv $sophosserverspath
$sophosclientsdata  = Import-Csv $sophosclientspath
$heimdaldata        = Import-Csv $heimdalpath

#Get a list of all the unique hostname.

##Create an array to store the data.
$hosts = [System.Collections.ArrayList]::new()

##Lansweeper.
foreach($item in $lansweeperdata){
    $myobj = New-Object -TypeName PSCustomObject
    Add-Member -InputObject $myobj -MemberType 'NoteProperty' -Name 'Title' -Value $item.AssetName.ToUpper().Trim()
    Add-Member -InputObject $myobj -MemberType 'NoteProperty' -Name 'Type' -Value "Lansweeper"
    $hosts.Add($myobj) | Out-Null
}
##Sophos Servers.
foreach($item in $sophosserversdata){
    $myobj = New-Object -TypeName PSCustomObject
    Add-Member -InputObject $myobj -MemberType 'NoteProperty' -Name 'Title' -Value $item.Name.ToUpper().Trim()
    Add-Member -InputObject $myobj -MemberType 'NoteProperty' -Name 'Type' -Value "Sophos"
    $hosts.Add($myobj) | Out-Null
}
##Sophos Computers.
foreach($item in $sophosclientsdata){
    $myobj = New-Object -TypeName PSCustomObject
    Add-Member -InputObject $myobj -MemberType 'NoteProperty' -Name 'Title' -Value $item.Name.ToUpper().Trim()
    Add-Member -InputObject $myobj -MemberType 'NoteProperty' -Name 'Type' -Value "Sophos"
    $hosts.Add($myobj) | Out-Null
}
##Heimdal.
foreach($item in $heimdaldata){
    $myobj = New-Object -TypeName PSCustomObject
    Add-Member -InputObject $myobj -MemberType 'NoteProperty' -Name 'Title' -Value $item.HOSTNAME.ToUpper().Trim()
    Add-Member -InputObject $myobj -MemberType 'NoteProperty' -Name 'Type' -Value "Heimdal"
    $hosts.Add($myobj) | Out-Null
}

##Filter, sort, and get the unique items from the data.
$uniquehosts = $hosts | Select-Object -Property Title | Sort-Object -Property Title -Unique

#Now it gets fun, loop over all the unique values and see which data sources they appear in.
##Create an array to store our final data. 
$inventory = [System.Collections.ArrayList]::new()

##Loop over every unique host and find where else it appears.
foreach($item in $uniquehosts){
    $myobj = New-Object -TypeName PSCustomObject
    Add-Member -InputObject $myobj -MemberType 'NoteProperty' -Name 'Computer name' -Value $item.Title

    ##Lansweeper.
    if(($hosts | Where-Object -Property Type -EQ Lansweeper | Where-Object -Property Title -EQ $item.Title) -EQ $null){
        Add-Member -InputObject $myobj -MemberType 'NoteProperty' -Name 'Lansweeper' -Value "No"
    }
    else{
        Add-Member -InputObject $myobj -MemberType 'NoteProperty' -Name 'Lansweeper' -Value "Yes"
    }

    ##Sophos.
    if(($hosts | Where-Object -Property Type -EQ Sophos | Where-Object -Property Title -EQ $item.Title) -EQ $null){
        Add-Member -InputObject $myobj -MemberType 'NoteProperty' -Name 'Sophos' -Value "No"
    }
    else{
        Add-Member -InputObject $myobj -MemberType 'NoteProperty' -Name 'Sophos' -Value "Yes"
    }

    ##Heimdal.
    if(($hosts | Where-Object -Property Type -EQ Heimdal | Where-Object -Property Title -EQ $item.Title) -EQ $null){
        Add-Member -InputObject $myobj -MemberType 'NoteProperty' -Name 'Heimdal' -Value "No"
    }
    else{
        Add-Member -InputObject $myobj -MemberType 'NoteProperty' -Name 'Heimdal' -Value "Yes"
    }
    $inventory.Add($myobj) | Out-Null
}

#Export the data to CSV
$inventory | Export-Csv $exportpath