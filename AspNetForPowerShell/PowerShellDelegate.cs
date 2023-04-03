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

using System;
using System.Text;
using System.Management.Automation;
using System.IO;
using System.Collections.Generic;
using System.Linq;
using Microsoft.AspNetCore.Http;
using System.Threading.Tasks;
using System.Management.Automation.Runspaces;

namespace AspNetForPowerShell
{
    internal class StreamEncoding
    {
        internal readonly Stream Stream;
        internal Encoding Encoding;
        internal StreamEncoding(Stream s, Encoding e)
        {
            Stream = s;
            Encoding = e;
        }
    }

    internal class TypeWriter
    {
        internal readonly Type Type;
        internal readonly Func<object, StreamEncoding, Task> Writer;
        internal TypeWriter(Type t, Func<object, StreamEncoding, Task> w)
        {
            Type = t;
            Writer = w;
        }
    }

    public class PowerShellDelegate
    {
        readonly string _script;
        readonly InitialSessionState _initialSessionState;

        readonly static TypeWriter[] TypeWriters =
        {
            new TypeWriter(typeof(byte[]),(o,e)=>{ byte[] ba=(byte[])o; return e.Stream.WriteAsync(ba,0,ba.Length); }),
            new TypeWriter(typeof(string),(o,e)=>WriteObject(e.Encoding.GetBytes((string)o),e)),
            new TypeWriter(typeof(char[]),(o,e)=>WriteObject(e.Encoding.GetBytes((char[])o),e)),
            new TypeWriter(typeof(byte),(o,e)=>WriteObject(new byte[]{(byte)o},e)),
            new TypeWriter(typeof(char),(o,e)=>WriteObject(new char[]{(char)o},e)),
            new TypeWriter(typeof(Encoding),(o,e)=>{ e.Encoding=(Encoding)o; return Task.CompletedTask; }),
            new TypeWriter(typeof(PSObject),(o,e)=>WriteObject(((PSObject)o).BaseObject,e)),
            new TypeWriter(typeof(IEnumerable<byte>),(o,e)=>WriteObject(((IEnumerable<byte>)o).ToArray(),e)),
            new TypeWriter(typeof(IEnumerable<char>),(o,e)=>WriteObject(((IEnumerable<char>)o).ToArray(),e)),
            new TypeWriter(typeof(IEnumerable<object>),async (o,e)=>{ foreach(var obj in ((IEnumerable<object>)o)) { await WriteObject(obj,e); } })
        };

        static Task WriteObject(object obj, StreamEncoding encoding)
        {
            if (obj!=null)
            {
                Type type = obj.GetType();

                foreach (var typeWriter in TypeWriters)
                {
                    if (typeWriter.Type.IsAssignableFrom(type))
                    {
                        return typeWriter.Writer(obj, encoding);
                    }
                }

                throw new InvalidDataException(type.FullName);
            }

            return Task.CompletedTask;
        }

        public PowerShellDelegate(string script)
        {
            _script = script;
        }

        public PowerShellDelegate(InitialSessionState initialSessionState, string script)
        {
            _initialSessionState = initialSessionState;
            _script = script;
        }

        public async Task InvokeAsync(HttpContext context)
        {
            using (PowerShell powerShell = _initialSessionState == null
                ? PowerShell.Create()
                : PowerShell.Create(_initialSessionState))
            {
                powerShell.AddScript(_script).AddParameter("HttpContext", context);

                MemoryStream memory = new MemoryStream();

                await context.Request.Body.CopyToAsync(memory);

                byte [] buffer = memory.ToArray();

                var output = await (buffer.Length > 0
                    ? powerShell.InvokeAsync(new PSDataCollection<byte[]>(new byte[][] { buffer }))
                    : powerShell.InvokeAsync());

                await WriteObject(output, new StreamEncoding(context.Response.Body, Encoding.UTF8));
            }
        }
    }
}
