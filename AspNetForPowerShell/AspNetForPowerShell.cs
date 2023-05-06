// Copyright (c) 2023 Roger Brown.
// Licensed under the MIT License.

using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using System.Management.Automation;
using System.Management.Automation.Runspaces;

namespace RhubarbGeekNz.AspNetForPowerShell
{
    [Cmdlet(VerbsCommon.New,"AspNetForPowerShellRequestDelegate")]
    [OutputType(typeof(RequestDelegate))]
    public class NewRequestDelegate : PSCmdlet
    {
        [Parameter(Mandatory = true, Position = 0)]
        public string Script { get; set; }
        [Parameter(Mandatory = false, Position = 1)]
        public InitialSessionState InitialSessionState { get; set; }

        protected override void BeginProcessing()
        {
        }

        protected override void ProcessRecord()
        {
            PowerShellDelegate powerShellDelegate = InitialSessionState == null ? new PowerShellDelegate(Script) : new PowerShellDelegate(Script, InitialSessionState);
            RequestDelegate requestDelegate = powerShellDelegate.InvokeAsync;
            WriteObject(requestDelegate);
        }

        protected override void EndProcessing()
        {
        }
    }

#if NET6_0_OR_GREATER
    [Cmdlet(VerbsCommon.New, "AspNetForPowerShellWebApplication")]
    [OutputType(typeof(WebApplication))]
    public class NewWebApplication : PSCmdlet
    {
        [Parameter(Mandatory = false, Position = 0)]
        public string[] ArgumentList { get; set; }

        protected override void BeginProcessing()
        {
        }

        protected override void ProcessRecord()
        {
            WebApplication webApplication = WebApplication.Create(ArgumentList);
            WriteObject(webApplication);
        }

        protected override void EndProcessing()
        {
        }
    }
#endif
}
