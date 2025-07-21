enum Terminals {
    MicrosoftTerminal
    MicrosoftTerminalPreview
    MicrosoftTerminalDev
    MicrosoftTerminalCanary
    MicrosoftConhost
    Kitty
    Iterm2
    WezTerm
    Ghostty
    VSCode
    Mintty
    Apple
    Alacritty
    xterm
    mlterm
}

enum ImageProtocol {
    Sixel
    InlineImageProtocol
    KittyGraphicsProtocol
    Unsupported
}

$mapping = @{
    [Terminals]::MicrosoftTerminal        = [ImageProtocol]::Unsupported
    [Terminals]::MicrosoftTerminalPreview = [ImageProtocol]::Sixel
    [Terminals]::MicrosoftTerminalDev     = [ImageProtocol]::Sixel
    [Terminals]::MicrosoftTerminalCanary  = [ImageProtocol]::Sixel
    [Terminals]::MicrosoftConhost         = [ImageProtocol]::Sixel
    [Terminals]::Kitty                    = [ImageProtocol]::KittyGraphicsProtocol
    [Terminals]::Iterm2                   = [ImageProtocol]::InlineImageProtocol
    [Terminals]::WezTerm                  = [ImageProtocol]::InlineImageProtocol
    [Terminals]::Ghostty                  = [ImageProtocol]::KittyGraphicsProtocol
    [Terminals]::VSCode                   = [ImageProtocol]::Sixel
    [Terminals]::Mintty                   = [ImageProtocol]::InlineImageProtocol
    [Terminals]::Apple                    = [ImageProtocol]::Sixel
    [Terminals]::Alacritty                = [ImageProtocol]::Unsupported
    [Terminals]::xterm                    = [ImageProtocol]::Sixel
    [Terminals]::mlterm                   = [ImageProtocol]::Sixel
}

$envVars = @{
    [Terminals]::MicrosoftTerminal        = 'WT_SESSION'
    [Terminals]::MicrosoftTerminalPreview = 'WT_SESSION'
    [Terminals]::MicrosoftTerminalDev     = 'WT_SESSION'
    [Terminals]::MicrosoftTerminalCanary  = 'WT_SESSION'
    [Terminals]::MicrosoftConhost         = 'WT_SESSION'
    [Terminals]::Kitty                    = 'KITTY_WINDOW_ID'
    [Terminals]::Iterm2                   = 'ITERM_SESSION_ID'
    [Terminals]::WezTerm                  = 'WEZTERM_EXECUTABLE'
    [Terminals]::Ghostty                  = 'GHOSTTY_RESOURCES_DIR'
    [Terminals]::VSCode                   = 'VSCODE_GIT_ASKPASS_MAIN'
    [Terminals]::Mintty                   = 'MINTTY'
    [Terminals]::Alacritty                = 'ALACRITTY_LOG'
}

function CheckTerminal {
    function GetTerminalProtocol {
        param(
            [Terminals] $Terminal
        )
        if ($mapping.ContainsKey($Terminal)) {
            [PSCustomObject]@{
                Terminal = $Terminal
                Protocol = $mapping[$Terminal]
            }
        }
    }
    function CheckParent {
        param(
            [int] $id
        )
        $Process = (Get-Process -Id $id).Parent
        $Edition = [regex]::match($Process.Path, 'Preview|Canary|Dev|system32', 'IgnoreCase').Value
        switch ($Edition) {
            'Preview' {
                return GetTerminalProtocol ([Terminals]::MicrosoftTerminalPreview)
            }
            'Canary' {
                return GetTerminalProtocol ([Terminals]::MicrosoftTerminalCanary)
            }
            'Dev' {
                return GetTerminalProtocol ([Terminals]::MicrosoftTerminalDev)
            }
            'system32' {
                return GetTerminalProtocol ([Terminals]::MicrosoftConhost)
            }
            default {
                return GetTerminalProtocol ([Terminals]::MicrosoftTerminal)
            }
        }
    }
    $vars = [System.Environment]::GetEnvironmentVariables()
    foreach ($key in $envVars.Get_Keys()) {
        if ($vars.ContainsKey($envVars[$key])) {
            if ($envVars[$key] -eq 'TERM_PROGRAM') {
                return  GetTerminalProtocol $vars[$envVars[$key]]
            }
            if ($envVars[$key] -eq 'WT_Session') {
                # Microsoft Terminal, detect which
                return CheckParent $PID
            }
            return GetTerminalProtocol $key
        }
    }
    if ($vars.ContainsKey('SESSIONNAME')) {
        # fallback for conhost, not sure how unique this is..
        return CheckParent $PID
    }
}
CheckTerminal
