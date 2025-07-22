using namespace System.Management.Automation
using namespace System.Collections.Generic
using namespace System.Text

$OutputEncoding = [console]::InputEncoding = [console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
$env:Pager = 'less'
$env:LESS = '--quiet --raw-control-chars --quit-on-intr --ignore-case --prompt :'
$env:LESSCHARSET = 'utf-8'
$env:BAT_THEME = 'Visual Studio Dark+'
$env:editor = 'code'
$env:CLASS_EXPLORER_TRUE_CHARACTER = [char]0x2713
if ((Test-Path -Path 'C:\Program Files\Git\usr\bin') -And
    $env:Path -split ';' -notcontains 'C:\Program Files\Git\usr\bin') {
    $env:Path += ';C:\Program Files\Git\usr\bin'
}

if ((Test-Path -Path 'C:\Files\apps\dnSpy') -And
    $env:Path -split ';' -notcontains 'C:\Files\apps\dnSpy') {
    $env:Path += ';C:\Files\apps\dnSpy'
}

Import-Module ClassExplorer
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineKeyHandler -Chord 'Ctrl+d,Ctrl+c' -Function CaptureScreen
Set-PSReadLineKeyHandler -Chord F1 -Function ShowCommandHelp
Set-PSReadLineKeyHandler -Key Alt+d -Function ShellKillWord
Set-PSReadLineKeyHandler -Key Alt+Backspace -Function ShellBackwardKillWord
Set-PSReadLineKeyHandler -Key Alt+b -Function ShellBackwardWord
Set-PSReadLineKeyHandler -Key Alt+f -Function ShellForwardWord
Set-PSReadLineKeyHandler -Key Alt+B -Function SelectShellBackwardWord
Set-PSReadLineKeyHandler -Key Alt+F -Function SelectShellForwardWord
Set-PSReadLineKeyHandler -Chord F2 -Function SwitchPredictionView
Set-PSReadLineKeyHandler -Chord 'Enter' -Function AcceptLine
Set-PSReadLineKeyHandler Ctrl+r ReverseSearchHistory
Set-PSReadLineOption -HistoryNoDuplicates:$false -MaximumHistoryCount 8kb -EditMode Windows -PredictionViewStyle ListView -ContinuationPrompt '    '
$PSStyle.Formatting.TableHeader = $PSStyle.Foreground.Cyan + $PSStyle.Bold

Set-PSReadLineOption -Colors @{
    Member             = '#e4e4e4'
    Parameter          = '#e4e4e4'
    Default            = '#e4e4e4'
    ContinuationPrompt = '#5a5a5a'
    Operator           = '#c5c5c5'
    Keyword            = '#c586c0'
    Command            = '#dcdcaa'
    Emphasis           = '#ff0000'
    inlinePrediction   = 'Gray'
    Selection          = $PSStyle.Background.FromRgb('#264F78')
    Type               = '#4ec9b0'
    Variable           = '#7cdcfe'
    String             = '#ce9178'
    Comment            = '#608b4e'
    Number             = '#93cea8'
    Error              = '#8b0000'
}
function .. {
    Set-Location -Path .. -PassThru
}
class CommandInfoTransformAttribute : ArgumentTransformationAttribute {
    [object] Transform(
        [EngineIntrinsics] $engineIntrinsics,
        [object] $inputObject
    ) {

        if ($inputObject -isnot [CommandInfo]) {
            $inputObject = Get-Command "$inputObject" | Select-Object -First 1
        }

        if ($inputObject -is [AliasInfo]) {
            $inputObject = $inputObject.ResolvedCommand
        }

        return $inputObject
    }
}
class CommandInfoCompleterAttribute : ArgumentCompleter, IArgumentCompleter, IArgumentCompleterFactory {
    [IEnumerable[CompletionResult]] CompleteArgument(
        [string] $commandName,
        [string] $parameterName,
        [string] $wordToComplete,
        [Language.CommandAst] $commandAst,
        [Collections.IDictionary] $fakeBoundParameters
    ) {
        if ([String]::IsNullOrWhiteSpace($wordToComplete)) {
            $wordToComplete = '*'
        }

        $filter = [CommandTypes]::All
        if ($commandName -in 'Edit-VSCode', 'ev') {
            # we cannot edit Applications or Cmdlets
            $filter = $filter -bxor [CommandTypes]'Application,Cmdlet' # 343
        }

        elseif ($commandName -in 'Get-CommandParameter', 'gcp', 'Resolve-Command', 'rc') {
            # we cannot get parameters for Applications.
            $filter = $filter -bxor [CommandTypes]::Application # 351
        }

        $results = [CompletionCompleters]::CompleteCommand($wordToComplete, $null, $filter)
        # just return the first 10 results
        return [Linq.Enumerable]::Take($results, 10)
    }
    [IArgumentCompleter] Create() {
        return $this
    }
}
function Resolve-Command {
    <#
    .DESCRIPTION
    Show the source code of a command.
    .PARAMETER Command
    The command to resolve.
    .EXAMPLE
    Resolve-Command Get-ChildItem
    .EXAMPLE
    'Get-ChildItem' | Resolve-Command
    .LINK
    https://github.com/trackd
    #>
    [CmdletBinding()]
    [Alias('rc')]
    param(
        [Parameter(ValueFromPipeline, Mandatory, Position = 0)]
        [CommandInfoCompleter()]
        [CommandInfoTransform()]
        [CommandInfo] $Command
    )
    begin {
        $isLast = $MyInvocation.PipelinePosition -eq $MyInvocation.PipelineLength
        $bat = $ExecutionContext.InvokeCommand.GetCommand('bat', 'Application')
        $batPS = @(
            '-l'
            'powershell'
            '--style'
            'grid,numbers,snip'
        )
        $batCS = @(
            '-l'
            'cs'
            '--style'
            'grid,numbers,snip'
        )
    }
    process {
        if ($Command -is [ApplicationInfo]) {
            return $Command
        }
        if ($Command -is [CmdletInfo]) {
            $ilspy = $ExecutionContext.InvokeCommand.GetCommand('ilspycmd', 'Application')
            if ($ilspy) {
                <#
                dotnet tool install ilspycmd -g
                winget install sharkdp.bat
                #>
                $outCS = @(
                    '--type'
                    $Command.ImplementingType
                    $Command.DLL
                )
                try {
                    if (-not $bat) {
                        return & $ilspy $outCS
                    }
                    return (& $ilspy $outCS) | & $bat $batCS
                }
                catch {
                    # silence is golden
                }
            }
            Write-Warning 'This command is a cmdlet, you need ilspy/dnspy or something similar to decompile the code, output is a proxyfunction'
            $outProxy = @(
                if ($isLast) {
                    '<#'
                    'File: {0}' -f $Command.DLL
                    '#>'
                }
                'function {0} {1}' -f $Command.Name, '{'
                [System.Management.Automation.ProxyCommand]::Create($Command)
                '}'
            )
            if (-not $bat) {
                return $outProxy
            }
            $outProxy | & $bat $batPS
        }
        if ($Command.ScriptBlock.Ast) {
            $outPS = @(
                if ($isLast) {
                    '<#'
                    'File: {0}' -f $Command.ScriptBlock.File
                    '#>'
                }
                $Command.ScriptBlock.Ast.Extent.Text
            )
            if (-not $bat) {
                return $outPS
            }
            $outPS | & $bat $batPS
        }
    }
}
function Edit-VSCode {
    <#
    .SYNOPSIS
    Edit a command in VSCode.
    .PARAMETER Command
    CommandName or CommandInfo to edit.
    .PARAMETER Editor
    Editor to use, defaults to $env:editor
    .EXAMPLE
    Edit-VSCode Edit-VSCode
    .EXAMPLE
    Edit-VSCode Edit-VSCode -Editor code
    .LINK
    https://github.com/trackd
    #>
    [Alias('ev')]
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline, Mandatory, Position = 0)]
        [CommandInfoCompleter()]
        [CommandInfoTransform()]
        [CommandInfo] $Command,
        [ArgumentCompletions('code', 'code-insiders')]
        [String] $Editor = $env:editor,
        [Switch] $UseNewEnvironment
    )
    if ($Command -is [CmdletInfo] -or $Command -is [ApplicationInfo]) {
        $PSCmdlet.ThrowTerminatingError(
            [ErrorRecord]::new(
                <# Exception     #> [PSNotSupportedException]::new('Editing {0} not supported' -f $Command.CommandType),
                <# errorId       #> 'TypeNotSupported',
                <# ErrorCategory #> [ErrorCategory]::InvalidType,
                <# targetObject  #> $Command
            )
        )
    }
    $code = $ExecutionContext.InvokeCommand.GetCommand($Editor, 'Application')
    if (-not $code) {
        $PSCmdlet.ThrowTerminatingError(
            [ErrorRecord]::new(
                <# Exception     #> [CommandNotFoundException]::new('Editor Not Found: {0}, use -Editor or $env:editor' -f $Editor),
                <# errorId       #> 'EditorNotFound',
                <# ErrorCategory #> [ErrorCategory]::NotInstalled,
                <# targetObject  #> $Editor
            )
        )
    }
    if (-not $Command.ScriptBlock.File) {
        $PSCmdlet.ThrowTerminatingError(
            [ErrorRecord]::new(
                <# Exception     #> [ItemNotFoundException]::new('File not found'),
                <# errorId       #> 'FileNotFound',
                <# ErrorCategory #> [ErrorCategory]::ObjectNotFound,
                <# targetObject  #> $Command
            )
        )
    }
    $Arguments = @(
        '--goto'
        '{0}:{1}:{2}' -f $Command.ScriptBlock.File,
        $Command.ScriptBlock.StartPosition.StartLine,
        $Command.ScriptBlock.StartPosition.StartLine.StartColumn
        '--reuse-window'
    )
    if (-not $UseNewEnvironment.IsPresent) {
        # this has issues that $env:WT_SESSION inherits from the terminal..
        & $code $Arguments
        return
    }
    $procParams = @{
        FilePath          = $code.Source
        ArgumentList      = $Arguments
        UseNewEnvironment = $true
        NoNewWindow       = $true
        # Verb            = 'RunAs'
        # Wait            = $true
        # PassThru        = $true
    }
    $null = Start-Process @procParams
}
function Expand-MemberInfo {
    <#
    from seeminglyscience
    https://gist.github.com/SeeminglyScience/1ba55937bd296276a976723c39c23179
    #>
    [Alias('emi')]
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline, Mandatory)]
        [Alias('Member')]
        [psobject] $InputObject,

        [Parameter()]
        [ValidateSet('IL', 'CSharp', 'VisualBasic')]
        [string] $Language = 'CSharp',

        [switch] $NoAnonymousMethods,
        [switch] $NoExpressionTrees,
        [switch] $NoYield,
        [switch] $NoAsync,
        [switch] $NoAutomaticProperties,
        [switch] $NoAutomaticEvents,
        [switch] $NoUsingStatements,
        [switch] $NoForEachStatements,
        [switch] $NoLockStatements,
        [switch] $NoSwitchOnString,
        [switch] $NoUsingDeclarations,
        [switch] $NoQueryExpressions,
        [switch] $DontClarifySameNameTypes,
        [switch] $UseFullnamespace,
        [switch] $DontUseVariableNamesFromSymbols,
        [switch] $NoObjectOrCollectionInitializers,
        [switch] $NoInlineXmlDocumentation,
        [switch] $DontRemoveEmptyDefaultConstructors,
        [switch] $DontUseIncrementOperators,
        [switch] $DontUseAssignmentExpressions,
        [switch] $AlwaysCreateExceptionVariables,
        [switch] $SortMembers,
        [switch] $ShowTokens,
        [switch] $ShowBytes,
        [switch] $ShowPdbInfo
    )
    begin {
        $dnSpy = Get-Command -CommandType Application -Name dnSpy.Console.exe -ErrorAction Stop

        $argumentList = & {
            if ($NoAnonymousMethods.IsPresent) {
                '--no-anon-methods'
            }

            if ($NoExpressionTrees.IsPresent) {
                '--no-expr-trees'
            }

            if ($NoYield.IsPresent) {
                '--no-yield'
            }

            if ($NoAsync.IsPresent) {
                '--no-async'
            }

            if ($NoAutomaticProperties.IsPresent) {
                '--no-auto-props'
            }

            if ($NoAutomaticEvents.IsPresent) {
                '--no-auto-events'
            }

            if ($NoUsingStatements.IsPresent) {
                '--no-using-stmt'
            }

            if ($NoForEachStatements.IsPresent) {
                '--no-foreach-stmt'
            }

            if ($NoLockStatements.IsPresent) {
                '--no-lock-stmt'
            }

            if ($NoSwitchOnString.IsPresent) {
                '--no-switch-string'
            }

            if ($NoUsingDeclarations.IsPresent) {
                '--no-using-decl'
            }

            if ($NoQueryExpressions.IsPresent) {
                '--no-query-expr'
            }

            if ($DontClarifySameNameTypes.IsPresent) {
                '--no-ambig-full-names'
            }

            if ($UseFullnamespace.IsPresent) {
                '--full-names'
            }

            if ($DontUseVariableNamesFromSymbols.IsPresent) {
                '--use-debug-syms'
            }

            if ($NoObjectOrCollectionInitializers.IsPresent) {
                '--no-obj-inits'
            }

            if ($NoInlineXmlDocumentation.IsPresent) {
                '--no-xml-doc'
            }

            if ($DontRemoveEmptyDefaultConstructors.IsPresent) {
                '--dont-remove-empty-ctors'
            }

            if ($DontUseIncrementOperators.IsPresent) {
                '--no-inc-dec'
            }

            if ($DontUseAssignmentExpressions.IsPresent) {
                '--dont-make-assign-expr'
            }

            if ($AlwaysCreateExceptionVariables.IsPresent) {
                '--always-create-ex-var'
            }

            if ($SortMembers.IsPresent) {
                '--sort-members'
            }

            if ($ShowBytes.IsPresent) {
                '--bytes'
            }

            if ($ShowPdbInfo.IsPresent) {
                '--pdb-info'
            }

            if ($Language -ne 'CSharp') {
                $languageGuid = switch ($Language) {
                    IL { '{a4f35508-691f-4bd0-b74d-d5d5d1d0e8e6}' }
                    CSharp { '{bba40092-76b2-4184-8e81-0f1e3ed14e72}' }
                    VisualBasic { '{a4f35508-691f-4bd0-b74d-d5d5d1d0e8e6}' }
                }

                "-l ""$languageGuid"""
            }

            '--spaces 4'
        }

        if ($argumentList.Count -gt 1) {
            $arguments = $argumentList -join ' '
            return
        }

        $arguments = [string]$argumentList
    }
    process {
        if ($InputObject -is [PSMethod]) {
            $null = $PSBoundParameters.Remove('InputObject')
            return $InputObject.ReflectionInfo | & $MyInvocation.MyCommand @PSBoundParameters
        }

        if ($InputObject -is [type]) {
            $assembly = $InputObject.Assembly
        }
        else {
            $assembly = $InputObject.DeclaringType.Assembly
        }

        $sb = [StringBuilder]::new([string]$arguments)
        if ($sb.Length -gt 0) {
            $null = $sb.Append(' ')
        }

        if (-not $ShowTokens.IsPresent) {
            $null = $sb.Append('--no-tokens ')
        }

        try {
            # Use the special name accessor as PowerShell ignores property exceptions.
            $metadataToken = $InputObject.get_MetadataToken()
        }
        catch [InvalidOperationException] {
            $exception = [PSArgumentException]::new(
                ('Unable to get the metadata token of member "{0}". Ensure ' -f $InputObject) +
                'the target is not dynamically generated and then try the command again.',
                $PSItem)

            $PSCmdlet.WriteError(
                [ErrorRecord]::new(
                    <# exception:     #> $exception,
                    <# errorId:       #> 'CannotGetMetadataToken',
                    <# errorCategory: #> [ErrorCategory]::InvalidArgument,
                    <# targetObject:  #> $InputObject))

            return
        }


        $null = $sb.
        AppendFormat('--md {0} ', $metadataToken).
        AppendFormat('"{0}"', $assembly.Location)
        $sb.ToString() | Write-Debug
        & ([scriptblock]::Create(('& "{0}" {1}' -f $dnSpy.Source, $sb.ToString())))
    }
}

function cs {
    param()
    end {
        $input | bat -l cs --style grid, numbers, snip
    }
}
function ps1 {
    param()
    end {
        $input | bat -l ps1 --style grid, numbers, snip
    }
}
