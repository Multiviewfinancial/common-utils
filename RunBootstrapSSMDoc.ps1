param(
    [Parameter(Mandatory=$true)]
    [string]$vmName,
    [Parameter(Mandatory=$true)]
    [string]$fileName,
    [Parameter(Mandatory=$true)]
    [string]$domainOwner,
    [Parameter(Mandatory=$true)]
    [string]$nameSpace,
    [Parameter(Mandatory=$true)]
    [string]$package,
    [Parameter(Mandatory=$true)]
    [string]$packageVersion,
    [Parameter(Mandatory=$true)]
    [string]$repository,
    [Parameter(Mandatory=$true)]
    [string]$scriptToRun,
    [Parameter(Mandatory=$true)]
    [string]$delimitedScriptParameters
)

#. .\CheckSsmResults.ps1

#print version of aws cli
aws --version

# $FileName = "{{ FileName }}" #this will be someting like package-1.0.20.zip
# $DomainOwner = "{{ DomainOwner }}"
# $NameSpace = "{{ NameSpace }}"
# $Package = "{{ Package }}" 
# $PackageVersion = "{{ PackageVersion }}"
# $Repository = "{{ Repository }}"
# $ScriptToRun = "{{ ScriptToRun }}"
# $DelimitedScriptParameters = "{{ DelimitedScriptParameters }}"

$targetTag = "Name"

Write-Output "aws ssm send-command --targets Key=tag:$targetTag,Values=$vmName --document-name arn:aws:ssm:us-east-1:$($accountID):document/Bootstrap --parameters ""FileName=$fileName, DomainOwner=$domainOwner, NameSpace=$nameSpace, Package=$package, PackageVersion=$packageVersion, Repository=$repository, ScriptToRun=$scriptToRun, DelimitedScriptParameters=$delimitedScriptParameters"" --region us-east-1"
$result = aws ssm send-command --targets "Key=tag:$targetTag,Values=$vmName" --document-name arn:aws:ssm:us-east-1:$($accountID):document/Bootstrap --parameters "FileName=$fileName, DomainOwner=$domainOwner, NameSpace=$nameSpace, Package=$package, PackageVersion=$packageVersion, Repository=$repository, ScriptToRun=$scriptToRun, DelimitedScriptParameters=$delimitedScriptParameters" --region us-east-1 | ConvertFrom-Json
Write-Output "Command created at: https://us-east-1.console.aws.amazon.com/systems-manager/run-command/$($result.Command.CommandId)?region=us-east-1"


#CheckSsmResults -results $resultsd