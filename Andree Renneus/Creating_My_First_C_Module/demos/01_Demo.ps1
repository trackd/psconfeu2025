Import-Module PwshSpectreConsole #, Sixel

$image = '..\Presentations\Sixel\Assets\chibi_avatar.png'

'Spectre.Console.Canvas'
Get-SpectreImage -ImagePath $image -Format Canvas -Width 20
Read-Host 'Press Enter to continue...'
'PwshSpectreConsole Blocks'
Get-SpectreImageExperimental -ImagePath $image -Width 40 -WarningAction 0
Read-Host 'Press Enter to continue...'
'Sixel Module Blocks'
ConvertTo-Sixel -Path $image -Width 40 -Protocol Blocks
Read-Host 'Press Enter to continue...'
'InlineImageProtocol'
ConvertTo-Sixel -Path $image -Width 40 -Protocol InlineImageProtocol
Read-Host 'Press Enter to continue...'
'Sixel'
ConvertTo-Sixel -Path $image -Width 40 -Protocol Sixel


<#
gifs w/ module Websocket
$getWebSocketSplat = @{
    TimeOut      = [Timespan]'00:01:30'
    Watch        = $true
    ErrorAction  = 'Ignore'
    WebSocketUri = 'wss://jetstream2.us-west.bsky.network/subscribe?wantedCollections=app.bsky.feed.post'
}

Get-WebSocket @getWebSocketSplat | ForEach-Object {
    if ($_.commit.record.embed.external.uri -match '^https://media.tenor') {
        ConvertTo-SixelGif -Url $_.commit.record.embed.external.uri -LoopCount 1
    }
}
#>
