/**************************************************************************
 *
 *  Copyright 2023, Roger Brown
 *
 *  This file is part of rhubarb-geek-nz/AspNetForPowerShell.
 *
 *  This program is free software: you can redistribute it and/or modify it
 *  under the terms of the GNU Lesser General Public License as published by the
 *  Free Software Foundation, either version 3 of the License, or (at your
 *  option) any later version.
 * 
 *  This program is distributed in the hope that it will be useful, but WITHOUT
 *  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 *  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 *  more details.
 *
 *  You should have received a copy of the GNU Lesser General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>
 *
 */

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
