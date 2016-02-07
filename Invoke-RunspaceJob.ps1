function Invoke-RunspaceJob
{
    <#
        .NOTES
            Author: Alexey Shuvalov
            DateCreated: 05.03.2013
            DateModified: 05.03.2013
            Version: 1.0 - Initial Release
    
        .SYNOPSIS
            Asynchronously performs an operation for each item in a collection of input objects.

        .DESCRIPTION
            Asynchronously performs an operation for each item in a collection of input objects,
            creating powershell runspaces to perform operations.
            Each runspace execution can be limited by timeout in minutes (shared for all runspace).
            Host runspace variables can be shared with child runspaces by specifieng their names.

        .PARAMETER InputObject
            Specifies the input objects. Invoke-RunspaceJob runs the script block or operation statement on each input object. 
            Enter a variable that contains the objects, or type a command or expression that gets the objects.

        .PARAMETER ScriptBlock
            Specifies the operation that is performed on each input object. Enter a script block that describes the operation.

        .PARAMETER ThrottleLimit
            Specifies the maximum number of concurrent runspaces that can be run by this command. If you omit this parameter, the default value 32 is used.

        .PARAMETER Timeout
            Determines the maximum wait time for each background runspace job, in minutes. The timing starts when scriptblock execution begins.

        .PARAMETER ShowProgress
            Shows progress bar.

        .PARAMETER SharedVariables
            Specifies the host variables by their names, that will be avaliable in background runspaces. If a variable is Synchronized like
            [HashTable]::Synchronized(@{}) all changes will be synchronized between all runspaces.

        .EXAMPLE
            PS C:\> 'comp1', 'comp2', 'comp3' | Invoke-RunspaceJob {Start-LongScript -Identity $_}

            Description
            -----------
            Run instance of Start-LongScript for every object in array.

        .EXAMPLE
            PS C:\> $server | Invoke-RunspaceJob {$_ ; add-pssnapin *e1020*; Get-EventLog application -ComputerName $_ -Newest 50 | where {($_.instanceid -eq 1012) -and ($_.TimeGenerated -gt "12/4/2013 9:30:00 AM")} | ft -a} -showprogress -ThrottleLimit 50 -Timeout 2

            Description
            -----------
            Run instance of Get-Eventlog for every object in array, with maximum 50 concurent thread and timeout 2 min for each scriptblock.

        .EXAMPLE
            PS C:\> Invoke-RunspaceJob {Start-LongScript -Identity $_ -Credential $Cred} -SharedVariables Cred -ShowProgress -InputObject ('comp1', 'comp2', 'comp3')

            Description
            -----------
            Run instance of Start-LongScript for every object in array. Share host variable $Cred with all runspace instances and show progress bar.
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   Position=1)]
        [ValidateNotNullOrEmpty()]
        [PSObject[]]
        $InputObject,

        [Parameter(Mandatory=$true, 
                   Position=0)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.ScriptBlock]
        $ScriptBlock,

        [Parameter(Position=2)]
        [Int32]
        $ThrottleLimit = 32,

        [Parameter(Position=3)]
        [Int32]
        $Timeout,

        [Parameter(Position=5)]
        [switch]
        $ShowProgress,

        [Parameter(Position=4)]
        [ValidateScript({$_ | ForEach-Object -Process {Get-Variable -Name $_}})]
        [string[]]
        $SharedVariables
    )

    Begin
    {
        #region Creating initial variables
        $runspacetimers = [HashTable]::Synchronized(@{})
        $SharedVariables += 'runspacetimers'
        $runspaces = New-Object -TypeName System.Collections.ArrayList
        $bgRunspaceCounter = 0
        #endregion Creating initial variables

        #region Creating initial session state and runspace pool
        Write-Verbose -Message "Creating initial session state"
        $iss = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        foreach ($ExternalVariable in $SharedVariables)
        {
            Write-Verbose -Message ('Adding variable ${0} to initial session state' -f $ExternalVariable)
            $iss.Variables.Add((New-Object -TypeName System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList $ExternalVariable, (Get-Variable -Name $ExternalVariable -ValueOnly), ''))
        }
        Write-Verbose "Creating runspace pool with Throttle Limit $ThrottleLimit"
        $rp = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, $ThrottleLimit, $iss, $Host)
        $rp.Open()
        #endregion Creating initial session state and runspace pool

        #region Append timeout tracking code at the begining of scriptblock
        $ScriptStart = {
            [CmdletBinding()]
            Param
            (
                [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   Position=0)]
                $_,

                [Parameter(Position=1)]
                [ValidateNotNullOrEmpty()]
                [int]
                $bgRunspaceID
            )
            $runspacetimers.$bgRunspaceID = Get-Date
        }

        $ScriptBlock = [System.Management.Automation.ScriptBlock]::Create($ScriptStart.ToString() + $ScriptBlock.ToString())
        #endregion Append timeout tracking code at the begining of scriptblock

        #region Runspace status tracking and result retrieval function
        function Get-Result
        {
            [CmdletBinding()]
            Param
            (
                [switch]$Wait
            )
            do
            {
                $More = $false
                foreach ($runspace in $runspaces)
                {
                    $StartTime = $runspacetimers.($runspace.ID)
                    if ($runspace.Handle.isCompleted)
                    {
                        Write-Verbose -Message ('Thread done for {0}' -f $runspace.IObject)
                        $runspace.PowerShell.EndInvoke($runspace.Handle)
                        $runspace.PowerShell.Dispose()
                        $runspace.PowerShell = $null
                        $runspace.Handle = $null
                    }
                    elseif ($runspace.Handle -ne $null)
                    {
                        $More = $true
                    }
                    if ($Timeout -and $StartTime)
                    {
                        if ((New-TimeSpan -Start $StartTime).TotalMinutes -ge $Timeout)
                        {
                            Write-Warning -Message ('Timeout {0}' -f $runspace.IObject)
                            $runspace.PowerShell.Dispose()
                            $runspace.PowerShell = $null
                            $runspace.Handle = $null
                        }
                    }
                }
                if ($More -and $PSBoundParameters['Wait'])
                {
                    Start-Sleep -Milliseconds 100
                }
                foreach ($threat in $runspaces.Clone())
                {
                    if ( -not $threat.handle)
                    {
                        Write-Verbose -Message ('Removing {0}' -f $threat.IObject)
                        $runspaces.Remove($threat)
                    }
                }
                if ($ShowProgress)
                {
                    $ProgressSplatting = @{
                        Activity = 'Working'
                        Status = 'Proccesing threads'
                        CurrentOperation = '{0} of {1} total threads done' -f ($bgRunspaceCounter - $runspaces.Count), $bgRunspaceCounter
                        PercentComplete = ($bgRunspaceCounter - $runspaces.Count) / $bgRunspaceCounter * 100
                    }
                    Write-Progress @ProgressSplatting
                }
            }
            while ($More -and $PSBoundParameters['Wait'])
        }
        #endregion Runspace status tracking and result retrieval function
    }
    Process
    {
        foreach ($Object in $InputObject)
        {
            $bgRunspaceCounter++
            $psCMD = [System.Management.Automation.PowerShell]::Create().AddScript($ScriptBlock).AddParameter('bgRunspaceID',$bgRunspaceCounter).AddArgument($Object)
            $psCMD.RunspacePool = $rp
            
            Write-Verbose -Message ('Starting {0}' -f $Object)
            [void]$runspaces.Add(@{
                Handle = $psCMD.BeginInvoke()
                PowerShell = $psCMD
                IObject = $Object
                ID = $bgRunspaceCounter
           })
            Get-Result
        }
    }
    End
    {
        Get-Result -Wait
        if ($ShowProgress)
        {
            Write-Progress -Activity 'Working' -Status 'Done' -Completed
        }
        Write-Verbose -Message "Closing runspace pool"
        $rp.Close()
        $rp.Dispose()
    }
}