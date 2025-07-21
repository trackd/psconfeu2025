# Get-ChildItem *.jpg | ForEach-Object {
#     $_ | ConvertTo-Sixel -Width 40 | Set-Content $_.FullName.replace($_.Extension, '.six')
# }
# Get-Content *.six

Get-XKCD -Latest
