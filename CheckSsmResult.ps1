function CheckSsmResult {
    param (
        [Parameter(Mandatory = $true)]
        [string]$commandId
    )
    $hasError = $false;

    $report=@{}
    $instanceCount=0
    do {
        $commands = aws ssm list-command-invocations --command-id $commandId | ConvertFrom-Json
        Start-Sleep -Seconds 10
        foreach ($instance in $commands.CommandInvocations)
        {
            $status=$instance.StatusDetails
            $InstanceId=$instance.InstanceId
            if ($status -ne "Pending" -and $status -ne "InProgress" -and $status -ne "Delayed") {
                if($report[$status].count -eq 0 -or (-Not $report[$status].contains($InstanceId)))
                {
                    $getError=''
                    if($status -ne "Success" -and $status -ne "InvalidPlatform")
                    {
                        Write-Output "Logging error because status was  $status"
                        $hasError = $true;
                        $getError= aws ssm get-command-invocation --command-id $commandId --instance-id $InstanceId | ConvertFrom-Json
                        $getError=$getError.StandardErrorContent
                    }
                    Write-Output "Done instance $InstanceId : $status"
                    $report[$status]+=@{$InstanceId=$getError}
                    $instanceCount++
                }
            } else {
                Write-Output "Waiting on instance $InstanceId : $status"
            }
        }
    } while ($instanceCount -lt $commands.CommandInvocations.Count)
    foreach ($status in $report.keys)
    {
        Write-Output ''
        $asterisk=''
        Write-Output "$($status.ToUpper()) INSTANCES"
        $asterisk_len=$status.length+10
        for($i=0;$i -lt $asterisk_len;$i++)
        {
            $asterisk+='*'
        }
        Write-Output $asterisk
        Write-Output ''
        foreach ($instance in $report.$status.keys)
        {
            Write-Output "ID: $($instance)"
            if($report.$status.$instance -ne '')
            {
                Write-Output "Error: $($report.$status.$instance)"
                Write-Output ''
            }
        }
    }
    if ($hasError){
    exit 2;
    }
}
