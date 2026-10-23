#This script takes in the exports from Lansweeper, Sophos, Microsoft Active Directory, Microsoft Intune, and Heimdal to identify machines with missing agents.
#James Preston of ANSecurity, jpreston@ansecurity.com www.ansecurity.com
#Last updated 23/10/2026 15:44
#Designed for PowerShell 7.x+

# Heimdal
## Heimdal needs multiple downloads set against timeframes to get all the clients (a known limitation), the script will handle multiple files with DeviceInfoStandardReport in the name and with duplicate data without any problems.
#https://dashboard.heimdalsecurity.com/activeclients > Download CSV > Standard.

# Sophos
#https://fusion.sophos.com/manage/endpoint/devices-list > Remove filter to include both computers and servers > Export to CSV.

# Lansweeper
#https://YOURLANSWEEPERSERVER/Report/report.aspx?det=web50repADAssetOverview&title=Active+Directory%3a+Assets+overview > Export to CSV.

# Active Directory Computers
# On a Domain Controller run the command below, copy the generated CSV into the C:\inventory folder.
# Get-ADComputer -Filter * -Property * | Select-Object -Property Name,OperatingSystem,OperatingSystemServicePack,OperatingSystemVersion | Export-Csv C:\Temp\adcomputers.csv -NoTypeInformation

# Intune
#https://intune.microsoft.com/#view/Microsoft_Intune_DeviceSettings/DevicesWindowsMenu/~/windowsDevices > Only include selected columns in the exported file > Yes
#Download and extract the provided ZIP file, name the CSV 'intune.csv' and place into the inventory folder.

#Declare the paths to the exports.
$lansweeperpath     = "C:\inventory\web50repADAssetOverview.csv"
$sophospath         = "C:\inventory\computers_and_servers.csv"
$adpath             = "C:\inventory\adcomputers.csv"
$intunepath         = "C:\inventory\intune.csv"

#Handle multiple Heimdal files
$heimdalfiles       = Get-ChildItem -Path C:\inventory | Where-Object -Property Name -Like "*DeviceInfoStandardReport*"

$heimdaldata = @()

foreach($heimdalfile in $heimdalfiles){
    $heimdaldata += Import-Csv $heimdalfile.FullName
}

#Declare the path to save the final data to.
$exportpath         = "C:\temp\agentreport.csv"

#Import the data.
$lansweeperdata     = Import-Csv $lansweeperpath -Delimiter ";" | Where-Object -Property Type -EQ "Windows" #You may want to expand this out to non-Windows devices.
$sophosdata         = Import-Csv $sophospath
$adclientsdata      = Import-Csv $adpath | Where-Object -Property OperatingSystem -Like "Windows *"
$intuneclientsdata  = Import-Csv $intunepath | Where-Object -Property Compliance -NE "Not Evaluated"

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
##Sophos.
foreach($item in $sophosdata){
    $myobj = New-Object -TypeName PSCustomObject
    Add-Member -InputObject $myobj -MemberType 'NoteProperty' -Name 'Title' -Value $item.Name.ToUpper().Trim()
    Add-Member -InputObject $myobj -MemberType 'NoteProperty' -Name 'Type' -Value "Sophos"
    $hosts.Add($myobj) | Out-Null
}
##AD.
foreach($item in $adclientsdata){
    $myobj = New-Object -TypeName PSCustomObject
    Add-Member -InputObject $myobj -MemberType 'NoteProperty' -Name 'Title' -Value $item.Name.ToUpper().Trim()
    Add-Member -InputObject $myobj -MemberType 'NoteProperty' -Name 'Type' -Value "AD"
    $hosts.Add($myobj) | Out-Null
}
##Heimdal.
foreach($item in $heimdaldata){
    $myobj = New-Object -TypeName PSCustomObject
    Add-Member -InputObject $myobj -MemberType 'NoteProperty' -Name 'Title' -Value $item.HOSTNAME.ToUpper().Trim()
    Add-Member -InputObject $myobj -MemberType 'NoteProperty' -Name 'Type' -Value "Heimdal"
    $hosts.Add($myobj) | Out-Null
}
##Intune.
foreach($item in $intuneclientsdata){
    $myobj = New-Object -TypeName PSCustomObject
    Add-Member -InputObject $myobj -MemberType 'NoteProperty' -Name 'Title' -Value $item.'Device name'.ToUpper().Trim()
    Add-Member -InputObject $myobj -MemberType 'NoteProperty' -Name 'Type' -Value "Intune"
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

    ##AD.
    if(($hosts | Where-Object -Property Type -EQ AD | Where-Object -Property Title -EQ $item.Title) -EQ $null){
        Add-Member -InputObject $myobj -MemberType 'NoteProperty' -Name 'AD' -Value "No"
    }
    else{
        Add-Member -InputObject $myobj -MemberType 'NoteProperty' -Name 'AD' -Value "Yes"
    }

    ##Heimdal.
    if(($hosts | Where-Object -Property Type -EQ Heimdal | Where-Object -Property Title -EQ $item.Title) -EQ $null){
        Add-Member -InputObject $myobj -MemberType 'NoteProperty' -Name 'Heimdal' -Value "No"
    }
    else{
        Add-Member -InputObject $myobj -MemberType 'NoteProperty' -Name 'Heimdal' -Value "Yes"
    }
    
    ##Intune.
    if(($hosts | Where-Object -Property Type -EQ Intune | Where-Object -Property Title -EQ $item.Title) -EQ $null){
        Add-Member -InputObject $myobj -MemberType 'NoteProperty' -Name 'Intune' -Value "No"
    }
    else{
        Add-Member -InputObject $myobj -MemberType 'NoteProperty' -Name 'Intune' -Value "Yes"
    }
    $inventory.Add($myobj) | Out-Null
}

#Export the data to CSV
$inventory | Export-Csv $exportpath
