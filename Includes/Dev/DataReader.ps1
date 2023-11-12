Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Text;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
namespace InProcess
{
    public class InMemoryJob : System.Management.Automation.Job
    {
        public InMemoryJob(PowerShell PowerShell, string name)
        {
            _PowerShell = PowerShell;
            SetUpStreams(name);
        }
        private void SetUpStreams(string name)
        {
            _PowerShell.Streams.Verbose = this.Verbose;
            _PowerShell.Streams.Error = this.Error;
            _PowerShell.Streams.Debug = this.Debug;
            _PowerShell.Streams.Warning = this.Warning;
            _PowerShell.Streams.Information = this.Information;
            _PowerShell.Runspace.AvailabilityChanged += new EventHandler<RunspaceAvailabilityEventArgs>(Runspace_AvailabilityChanged);
            int id = System.Threading.Interlocked.Add(ref InMemoryJobNumber, 1);
            if (!string.IsNullOrEmpty(name))
            {
                this.Name = name;
            }
            else
            {
                this.Name = "InProcessJob" + id;
            }
        }
        void Runspace_AvailabilityChanged(object sender, RunspaceAvailabilityEventArgs e)
        {
            if (e.RunspaceAvailability == RunspaceAvailability.Available)
            {
                this.SetJobState(JobState.Completed);
            }
        }
        PowerShell _PowerShell;
        static int InMemoryJobNumber = 0;
        public override bool HasMoreData
        {
            get {
                return (Output.Count > 0);
            }
        }
        public override string Location
        {
            get { return "In Process"; }
        }
        public override string StatusMessage
        {
            get { return "A new status message"; }
        }
        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                if (!isDisposed)
                {
                    isDisposed = true;
                    try
                    {
                        if (!IsFinishedState(JobStateInfo.State))
                        {
                            StopJob();
                        }
                        foreach (Job job in ChildJobs)
                        {
                            job.Dispose();
                        }
                    }
                    finally
                    {
                        base.Dispose(disposing);
                    }
                }
            }
        }
        private bool isDisposed = false;
        internal bool IsFinishedState(JobState state)
        {
            return (state == JobState.Completed || state == JobState.Failed || state == JobState.Stopped);
        }
        public override void StopJob()
        {
            _PowerShell.Stop();
            _PowerShell.EndInvoke(_asyncResult);
            SetJobState(JobState.Stopped);
        }
        public void Start()
        {
            _asyncResult = _PowerShell.BeginInvoke<PSObject, PSObject>(null, Output);
            SetJobState(JobState.Running);
        }
        IAsyncResult _asyncResult;
        public void WaitJob()
        {
            _asyncResult.AsyncWaitHandle.WaitOne();
        }
        public void WaitJob(TimeSpan timeout)
        {
            _asyncResult.AsyncWaitHandle.WaitOne(timeout);
        }
    }
}
'@

function Start-JobInProcess { 
    [CmdletBinding()]
    Param
    (
        [ScriptBlock] $ScriptBlock,
        $ArgumentList,
        [String] $Name
    )

    Function Get-JobRepository { 
        [CmdletBinding()]
        Param()
        $PScmdlet.JobRepository
    }

    Function Add-Job { 
        [CmdletBinding()]
        Param
        (
            $Job
        )
        $PScmdlet.JobRepository.Add($Job)
    }

    $PowerShell = [PowerShell]::Create().AddScript($ScriptBlock)

    if ($ArgumentList) { 
        $ArgumentList | ForEach-Object { 
            $PowerShell.AddArgument($_)
        }
    }

    $MemoryJob = New-Object InProcess.InMemoryJob $PowerShell, $Name

    $MemoryJob.Start()
    Add-Job $MemoryJob
    $MemoryJob
}
