function WaitForJobToFinish([string]$JobName)
{ 
    
    $job = Get-SPTimerJob | ?{ $_.Name -like $JobName }
    if ($job -eq $null) 
    {
        Write-Host 'Timer job not found'
    }
    else
    {
        $JobLastRunTime = $job.LastRunTime
        Write-Host -NoNewLine "Waiting to finish job $JobFullName last run on $JobLastRunTime"
        
        while ($job.LastRunTime -eq $JobLastRunTime) 
        {
            Write-Host -NoNewLine .
            Start-Sleep -Seconds 2
        }
        Write-Host  "Finished waiting for job.."
    }
}