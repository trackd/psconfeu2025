Import-Module PwshSpectreConsole
$table = [Spectre.Console.Table]::new()
$table | Find-Member

Find-Type -Namespace Spectre.Console -Name TableColumn | Find-Member
Find-Type '*Uri*'

# Get-Member on steroids.

[datetime] | Find-Member #-Force
$date = Get-Date
[datetime]::new($Date.AddDays(2).Ticks)
[datetime]::new($date.year, $date.month, $date.day)


# ILSpy, DNSpy, dotpeek
# show decompiled code
rc Invoke-RestMethod
[Microsoft.PowerShell.Commands.WebRequestPSCmdlet] | emi | cs

# find methods that take an AST as a parameter
Find-Type -Interface -Namespace System.Management.Automation {
    Find-Member -InputObject $_ -ParameterType System.Management.Automation.Language.Ast
}
