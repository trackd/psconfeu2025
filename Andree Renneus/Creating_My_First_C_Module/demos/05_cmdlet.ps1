# binary cmdlet in less than 30 lines without code golfing.. useful? perhaps not.
$CmdletDefinition = @'
using System.Management.Automation;

namespace Testing;
[Cmdlet(VerbsDiagnostic.Test, "MyCmdlet")]
public sealed class MyCmdlet : PSCmdlet
{
    [Parameter(Position = 0, Mandatory = true)]
    public string Name { get; set; }

    protected override void EndProcessing()
    {
        WriteObject("Hello " + Name);
    }
}
'@

if (-not ('Testing.MyCmdlet' -as [type])) {
    $Module = New-Module -Name Test -ScriptBlock {
        $Assembly = Add-Type -TypeDefinition $CmdletDefinition -PassThru
        Import-Module -Assembly $Assembly[0].Assembly
        Export-ModuleMember -Cmdlet Test-MyCmdlet
    }
    Import-Module $Module
}
Test-MyCmdlet 'World'
Get-Command Test-MyCmdlet
