function Start-NativeExecution {
    param(
        [Alias('sb')]
        [Parameter(Mandatory=$true)]
        [scriptblock]$ScriptBlock,
        [switch]$IgnoreExitcode,
        [switch]$VerboseOutputOnError
    )

    $backupEAP = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    Write-Verbose "Executing: $ScriptBlock"
    try {
        if ($VerboseOutputOnError.IsPresent) {
            $output = & $ScriptBlock 2>&1
        } else {
            & $ScriptBlock
        }

        # note, if $ScriptBlock doesn't have a native invocation, $LASTEXITCODE will
        # point to the obsolete value
        if ($LASTEXITCODE -ne 0 -and -not $IgnoreExitcode) {
            if ($VerboseOutputOnError.IsPresent -and $output) {
                $output | Out-String | Write-Verbose -Verbose
            }

            # Get caller location for easier debugging
            $caller = Get-PSCallStack -ErrorAction SilentlyContinue
            if ($caller) {
                $callerLocationParts = $caller[1].Location -split ":\s*line\s*"
                $callerFile = $callerLocationParts[0]
                $callerLine = $callerLocationParts[1]

                $errorMessage = "Execution of {$ScriptBlock} by ${callerFile}: line $callerLine failed with exit code $LASTEXITCODE"
                throw $errorMessage
            }
            throw "Execution of {$ScriptBlock} failed with exit code $LASTEXITCODE"
        }
    } finally {
        $ErrorActionPreference = $backupEAP
    }
}

function Get-MyDirectory {
    Start-NativeExecution 'Get-ChildItem -Path C:\Users\annavied\Documents'
}

# Note filtering of functions here that only exports 'Get-MyDirectory' when this .psm1 is imported.
Export-ModuleMember -Function 'Get-MyDirectory'