$StartTime = Get-Date
New-Item C:\ClusterInfo -Type directory 	#Create the workbench directory
New-Item C:\ClusterInfo\ScriptTime.txt -ItemType file
Add-Content C:\ClusterInfo\ScriptTime.txt "Started:  $StartTime"
Write-Progress -activity "Obtaining Cluster Information..." -status "Getting Cluster and Cluster Nodes Details..." -percentcomplete 5
Get-ClusterNode | SELECT Name | Export-Csv -LiteralPath C:\ClusterInfo\ClusterNodes1.Csv -Force -NoTypeInformation 	#Get all nodes of the cluster
(Get-Content C:\ClusterInfo\ClusterNodes1.Csv) | ForEach-Object {$_ -replace '"', ""} | Out-File -FilePath C:\ClusterInfo\ClusterNodes2.CSV -Force	#Remove Quotation Marks from above created file
(Get-Content C:\ClusterInfo\ClusterNodes2.Csv) | ForEach-Object {$_ -replace 'Name', ""} | Out-File -FilePath C:\ClusterInfo\ClusterNodes.CSV -Force	#Remove column title for above created file
Remove-Item C:\ClusterInfo\ClusterNodes1.Csv  
Remove-Item C:\ClusterInfo\ClusterNodes2.CSV
Rename-Item -Path C:\ClusterInfo\ClusterNodes.CSV -NewName C:\ClusterInfo\ClusterNodes.BAK
Select-String -Pattern "\w" -Path C:\ClusterInfo\ClusterNodes.BAK | ForEach-Object {$_.Line} | Set-Content -Path C:\ClusterInfo\ClusterNodes.CSV
Remove-Item C:\ClusterInfo\ClusterNodes.BAK
Write-Progress -activity "Obtaining Cluster Information..." -status "Getting Recent System Log Warning/Error Events..." -percentcomplete 67

$PartialPath = "\C$\Windows\System32\WinEvt\Logs\System.evtx"
Get-Content -Path C:\ClusterInfo\ClusterNodes.CSV | ForEach-Object {
$SourceFile = "\\"+$_+$PartialPath
$DestFile = "C:\ClusterInfo\System_" + $_ +".EVTX"
Copy-Item -Path $SourceFile -Destination $DestFile
}

New-Item C:\ClusterInfo\Combined_System_Event_Log.CSV -ItemType File
Add-Content C:\ClusterInfo\Combined_System_Event_Log.CSV '"LogName","LevelDisplayName","TimeCreated","ProviderName","Id","MachineName","Message"'
get-childItem "C:\ClusterInfo\*.evtx" | foreach {Get-WinEvent -FilterHashTable @{Path=$_; Level=5,4,3,2,1} |  Select LogName, LevelDisplayName, TimeCreated, ProviderName, Id, MachineName, 
@{n='Message';e={$_.Message -replace '\s+', " "}} | ConvertTo-Csv -NoTypeInformation | Select-Object -Skip 1 | Out-File -FilePath C:\ClusterInfo\Combined_System_Event_Log.CSV -Append -Encoding ascii}


Write-Progress -activity "Obtaining Cluster Information..." -status "Wrapping up..." -percentcomplete 99
Start-Sleep -s 5
$EndTime = Get-Date
Add-Content C:\ClusterInfo\ScriptTime.txt "Finished:  $EndTime"