Import-Module PwshSpectreConsole
$table = [Spectre.Console.Table]::new()
$table.Border = [Spectre.Console.TableBorder]::Double
$table.BorderStyle = [Spectre.Console.Style]::new([Spectre.Console.Color]::Blue)
$null = $table.AddColumn('Testing')
$null = 1..10 | ForEach-Object {
    [Spectre.Console.TableExtensions]::AddRow($table,
        [Spectre.Console.Text]::new(
            $_,
            [Spectre.Console.Style]::New(
                [Spectre.Console.Color]::DarkOliveGreen3
            )
        )
    )
}
$table


<#
vs
var simple = new Table()
    .Border(TableBorder.Double)
    .BorderColor(Color.Blue)
    .AddColumn(new TableColumn("Testing"))
    .AddRow("[DarkOliveGreen3]Hello[/]")
    .AddRow("[DarkOliveGreen3]Bonjour[/]")
    .AddRow("[DarkOliveGreen3]Hej[/]");
#>
