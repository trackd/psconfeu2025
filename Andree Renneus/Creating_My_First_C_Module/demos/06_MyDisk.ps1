# hybrid functions example
function Get-MyDisk {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('DeviceId')]
        [int] $Number,
        [string] $FriendlyName
    )
    begin {
        if (-not ('Pinvoke.Win32Utils' -as [type])) {
        # don't recommend trying out pinvoke code.. it's annoying..
        # https://github.com/dahall/Vanara
        # or pinvoke.net
        Add-Type -TypeDefinition @'
        using System.Runtime.InteropServices;
        using System.Text;
        namespace pinvoke;
        public static class Win32Utils {
            [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
            public static extern uint QueryDosDevice(string lpDeviceName, StringBuilder lpTargetPath, int ucchMax);
        }
'@
        }
    }
    process {
        $sbDeviceName = [System.Text.StringBuilder]::new(1024)
        foreach ($Disk in (Get-Disk @PSBoundParameters)) {
            foreach ($Partition in (Get-Partition $Disk.Number)) {
                foreach ($Volume in (Get-Volume -Partition $Partition)) {
                    if ($Volume.DriveLetter) {
                        [void][PInvoke.Win32Utils]::QueryDosDevice(($Volume.DriveLetter + ':'), $sbDeviceName, $sbDeviceName.Capacity)
                    }
                    [PSCustomObject]@{
                        PSTypeName      = 'Custom.MyDisk'
                        Disk            = $Disk.Number
                        Health          = $Disk.HealthStatus
                        FilesystemLabel = $Volume.FilesystemLabel
                        DiskSizeGB      = [Math]::Round(($Volume.Size / 1GB), 2)
                        DiskfreeGB      = [Math]::Round(($Volume.SizeRemaining / 1GB), 2)
                        Partition       = $Partition.PartitionNumber
                        DriveLetter     = $Volume.DriveLetter
                        FriendlyName    = $Disk.FriendlyName
                        Harddiskvolume  = $sbDeviceName.ToString()
                        # Bootdisk        = $disk.BootFromDisk
                        # IsBoot          = $partition.IsBoot
                        # SystemPartition = $partition.IsSystem
                    }
                    [void]$sbDeviceName.Clear()
                }
            }
        }
    }
}
