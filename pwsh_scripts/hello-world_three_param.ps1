param (
    [Parameter(Mandatory=$true)]
    [int]$Count,
    [string]$Message1 = 'default1',
    [string]$Message2 = 'default2'
)

for ($i=1; $i -le $count; $i++)
{
    Write-Host "$Message1"
    Write-Host "$Message2"
}