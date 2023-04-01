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
    internal class OutputEncoding
    {
        internal Encoding Encoding = Encoding.UTF8;
    }

    public class PowerShellDelegate
    {
        readonly string _script;
        readonly static byte[] EMPTY = Array.Empty<byte>();
        readonly InitialSessionState _initialSessionState;

        static Func<object, OutputEncoding, byte[]> []Converters =
        {
            ConvertFromByteArray,
            ConvertFromByteIEnumerable,
            ConvertFromObjectIEnumerable,
            ConvertFromByte,
            ConvertFromString,
            ConvertFromEncoding,
            ConvertFromFailed
        };

        static byte[] ConvertFromByteArray(object output, OutputEncoding encoding)
        {
            if (output is byte[])
            {
                return (byte[])output;
            }

            return null;
        }

        static byte[] ConvertFromByteIEnumerable(object output, OutputEncoding encoding)
        {
            if (output is IEnumerable<byte>)
            {
                return ((IEnumerable<byte>)output).ToArray();
            }

            return null;
        }

        static byte[] ConvertFromObjectIEnumerable(object output, OutputEncoding encoding)
        {
            if (output is IEnumerable<object>)
            {
                IEnumerable<object> list = (IEnumerable<object>)output;
                bool allBytes = true;
                int count = 0;
                foreach (var obj in list)
                {
                    allBytes &= obj is byte;
                    count++;
                }
                if (allBytes)
                {
                    byte[] ba = new byte[count];
                    int i = 0;
                    foreach (var obj in list)
                    {
                        ba[i++] = (byte)obj;
                    }
                    return ba;
                }
            }

            return null;
        }

        static byte[] ConvertFromByte(object output, OutputEncoding encoding)
        {
            if (output is byte)
            {
                return new byte[] { (byte)output };
            }

            return null;
        }

        static byte[] ConvertFromString(object output, OutputEncoding encoding)
        {
            if (output is string)
            {
                return encoding.Encoding.GetBytes((string)output);
            }

            return null;
        }

        static byte[] ConvertFromEncoding(object output, OutputEncoding encoding)
        {
            if (output is Encoding)
            {
                encoding.Encoding = (Encoding)output;
                return EMPTY;
            }

            return null;
        }

        static byte[] ConvertFromFailed(object output, OutputEncoding encoding)
        {
            throw new InvalidDataException();
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

                OutputEncoding encoding = new OutputEncoding();

                var stream = context.Response.Body;

                foreach (var item in output)
                {
                    var bo = item.BaseObject;

                    foreach (var fn in Converters)
                    {
                        byte[] ba = fn(bo, encoding);

                        if (ba != null)
                        {
                            if (ba.Length > 0)
                            {
                                await stream.WriteAsync(ba);
                            }

                            break;
                        }
                    }
                }
            }
        }
    }
}
