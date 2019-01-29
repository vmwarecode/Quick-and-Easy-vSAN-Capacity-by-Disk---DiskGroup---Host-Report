# Enumerate the cluster and store it
$Cluster = Get-Cluster -Name “vSAN”
 
# Write the cluster name
Write-Host "Cluster: $Cluster"

# Enumerate the hosts and loop through them
Foreach ($VMHost in ($Cluster|Get-VMHost)) {

  # Write the host we're reporting from 
  Write-Host "-$VMHost"

  # Zero out counter for Disk Groups
  $counter = 0

  # Zero out Host total
  $HostCapacity = 0
  $HostUsed = 0

  # Enumerate and Loop through the disk groups
  Foreach ($DiskGroup in ($VMHost | Get-VsanDiskGroup)) {

    # Write the disk group we're reporting from 
    Write-Host "--($Counter) $DiskGroup"

    # Zero out Disk Group Totals for the current Disk Group
    $DiskGroupCapacity = 0
    $DiskGroupUsed = 0

    # Enumerate and store the disks in the current disk group
    $Disks = $DiskGroup | Get-VsanDisk | Where-Object {$_.IsCacheDisk -eq $false}

    # Loop through each of the capacity disks
    Foreach ($Disk in $Disks) {

      # Set the color for the Used Percentage based on our thresholds
      switch ($Disk.UsedPercent) {
        {$_ -ge 0 -and $_ -le 70} {$UsedPctColor="Green"}
        {$_ -ge 70 -and $_ -le 85} {$UsedPctColor="Yellow"}
        {$_ -ge 85 -and $_ -le 101} {$UsedPcColor="Red"}
      }

      # Output the Disk, Capacity, and the Used Percentage
      Write-Host "-- --Disk: $Disk"

      $DiskGroupCapacity += $Disk.CapacityGB

      Write-Host "-- -- --Capacity: " $Disk.CapacityGB.ToString("#.##") 

      # Calculate used GB by multiplying Capacity by Used % 
      $UsedGB = [math]::abs($Disk.CapacityGB*($Disk.UsedPercent/100))

      $DiskGroupUsed += $UsedGB

      Write-Host "-- -- --Used GB: " $UsedGB.ToString("#.##")
      Write-Host "-- -- --Used Percent:" $Disk.UsedPercent.ToString("#.##") -ForegroundColor $UsedPctColor 
      Write-Host " "
    }
    Write-Host "Disk Group $Counter Capacity (in GB):"$DiskGroupCapacity.ToString("#.##")
    Write-Host "Disk Group $Counter Used (in GB):"$DiskGroupUsed.ToString("#.##")

    $HostCapacity += $DiskGroupCapacity
    $HostUsed += $DiskGroupUsed

    $Counter += 1
  } 
  Write-Host "-----------------------------------------------------"
  Write-Host "Host Capacity (in GB):"$HostCapacity.ToString("#.##")
  Write-Host "Host Used (in GB):"$HostUsed.ToString("#.##")
  Write-Host ""
  Write-Host "-----------------------------------------------------"
}
