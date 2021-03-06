# Author: Pradeep Adiga
# First cut: 6th March 2017

$starttime = Get-Date -format G
$servername= Read-Host -Prompt "Enter the server name"
$foldertoscan =Read-Host -Prompt "Enter the folder containing .blg files"
$blgfiles = New-Object System.Collections.ArrayList
$numbertocheck=0 # This variable is defined so that we don't pass more 32 .blg files to the $blgfiles ArrayList. Else Import-Counter will fail
$resultarray = @()
Get-ChildItem $foldertoscan *.blg -Recurse | % {$blgfiles.Add($_.FullName)}
if ($blgfiles.count -ge 32)
{
    $numbertocheck=31
}
else
{
    $numbertocheck=$blgfiles.count
}
$counterstocollect = @() # This array will hold the counters to be extracted from the .BLG files
$counterstocollect += '\\' + $servername +'\Processor(_Total)\% Processor Time'
$counterstocollect += '\\' + $servername +'\Memory\Available MBytes'
$counterstocollect += '\\' + $servername +'\PhysicalDisk(0 C:)\Disk Bytes/sec'
$counterstocollect += '\\' + $servername +'\PhysicalDisk(1 E:)\Disk Bytes/sec'
while (($blgfiles.count) -gt 0)
{
    $blgholder= New-Object System.Collections.ArrayList

      foreach ($j in $blgfiles)

        {
            $blgholder.Add($j)
            if ($blgholder.count -ge $numbertocheck) {break}
        }


    $data = Import-Counter -Path $blgholder -counter $counterstocollect
    foreach ($i in $data)
        {
            $counterobject = new-object PSObject
            Write-Host "Reading counters for " + $i.Timestamp
            $counterobject | add-member -name "timestamp" -Value $i.Timestamp  -membertype NoteProperty
            $counterobject | add-member -name  "CPU Utilization" -Value $i.Countersamples[0].CookedValue  -membertype NoteProperty
            $counterobject | add-member -name  "Memory" -Value $i.Countersamples[1].CookedValue  -membertype NoteProperty
            $counterobject | add-member -name  "C drive load" -Value $i.Countersamples[2].CookedValue  -membertype NoteProperty
            $counterobject | add-member -name  "E drive load" -Value $i.Countersamples[3].CookedValue  -membertype NoteProperty

            $resultarray += $counterobject

        }

#       The following loop is rough. I've created this to remove entries from the ArrayList and reduce the $numbertocheck counter
    for ($k=0; $k -le $blgholder.count; $k++)
        {
            $blgholder.RemoveAt($k)
            $blgfiles.RemoveAt($k)
            $numbertocheck = $numbertocheck-1
        }
}

$outputpath = Join-Path $foldertoscan  "\output.csv"
$resultarray | Export-Csv  $outputpath -force -noType
$endtime = Get-Date -format G
$totaltime = NEW-TIMESPAN –Start $starttime –End $endtime
Write-Host "Time taken" + $totaltime
Write-Host " "
Write-Host "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
Write-Host " "
Write-Host "All done. The output file is saved at " $outputpath
Write-Host " "
Write-Host "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
