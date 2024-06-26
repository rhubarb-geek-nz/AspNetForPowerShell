// Copyright (c) 2023 Roger Brown.
// Licensed under the MIT License.

using System;
using System.Text;
using System.Management.Automation;
using System.IO;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Management.Automation.Runspaces;
using System.Net.Mime;
using Microsoft.AspNetCore.Http;

namespace RhubarbGeekNz.AspNetForPowerShell
{
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

    internal class StreamEncoding
    {
        private readonly Stream stream;
        private Encoding encoding;
        internal readonly TaskCompletionSource<bool> taskCompletionSource = new TaskCompletionSource<bool>();
        internal Exception invokeException;
        private readonly PSDataCollection<object> outputPipeline;
        private readonly object mutex = new object();
        private int head, tail;
        private bool isCompleted, isFaulted, isWritable;
        internal StreamEncoding(Stream s, Encoding e, PSDataCollection<object> o)
        {
            stream = s;
            encoding = e;
            outputPipeline = o;

            outputPipeline.DataAdded += DataAdded;
            outputPipeline.Completed += Completed;
        }

        private readonly static TypeWriter[] TypeWriters =
        {
            new TypeWriter(typeof(byte[]),(o,e)=>{ byte[] ba=(byte[])o; return e.stream.WriteAsync(ba,0,ba.Length); }),
            new TypeWriter(typeof(string),(o,e)=>e.WriteObject(e.encoding.GetBytes((string)o))),
            new TypeWriter(typeof(char[]),(o,e)=>e.WriteObject(e.encoding.GetBytes((char[])o))),
            new TypeWriter(typeof(byte),(o,e)=>e.WriteObject(new byte[]{(byte)o})),
            new TypeWriter(typeof(char),(o,e)=>e.WriteObject(new char[]{(char)o})),
            new TypeWriter(typeof(Encoding),(o,e)=>{ e.encoding=(Encoding)o; return Task.CompletedTask; }),
            new TypeWriter(typeof(PSObject),(o,e)=>e.WriteObject(((PSObject)o).BaseObject)),
            new TypeWriter(typeof(IEnumerable<byte>),(o,e)=>e.WriteObject(((IEnumerable<byte>)o).ToArray())),
            new TypeWriter(typeof(IEnumerable<char>),(o,e)=>e.WriteObject(((IEnumerable<char>)o).ToArray())),
            new TypeWriter(typeof(IEnumerable<object>),async (o,e)=>{ foreach(var obj in ((IEnumerable<object>)o)) { await e.WriteObject(obj); } })
        };

        private Task WriteObject(object obj)
        {
            if (obj != null)
            {
                Type type = obj.GetType();

                foreach (var typeWriter in TypeWriters)
                {
                    if (typeWriter.Type.IsAssignableFrom(type))
                    {
                        return typeWriter.Writer(obj, this);
                    }
                }

                throw new InvalidDataException(type.FullName);
            }

            return Task.CompletedTask;
        }

        private void WriteNext()
        {
            int next = head;
            object value = outputPipeline[next++];

            head = next;

            try
            {
                WriteObject(value).ContinueWith((t) =>
                {
                    ContinueWith(t, next);
                });
            }
            catch (Exception ex)
            {
                if (!isCompleted)
                {
                    isFaulted = isCompleted = true;

                    taskCompletionSource.SetException(ex);
                }
            }
        }

        private void DataAdded(object sender, DataAddedEventArgs e)
        {
            lock (mutex)
            {
                if (isWritable && head == tail && head == e.Index && !isFaulted)
                {
                    WriteNext();
                }
            }
        }

        private void ContinueWith(Task task, int next)
        {
            lock (mutex)
            {
                if (task.IsFaulted)
                {
                    if (!isCompleted && !isFaulted)
                    {
                        isFaulted = isCompleted = true;

                        taskCompletionSource.SetException(task.Exception);
                    }
                }
                else
                {
                    tail = next;

                    if (next == outputPipeline.Count)
                    {
                        if (isCompleted && !isFaulted)
                        {
                            taskCompletionSource.SetResult(true);
                        }
                    }
                    else
                    {
                        if (next == head && !isFaulted)
                        {
                            WriteNext();
                        }
                    }
                }
            }
        }

        private void Completed(object sender, EventArgs e)
        {
            lock (mutex)
            {
                isCompleted = true;

                if (head == tail && head == outputPipeline.Count && isWritable && !isFaulted)
                {
                    taskCompletionSource.SetResult(true);
                }
            }
        }

        internal void IsWritable()
        {
            lock (mutex)
            {
                isWritable = true;

                if (head == outputPipeline.Count)
                {
                    if (isCompleted && !isFaulted)
                    {
                        taskCompletionSource.SetResult(true);
                    }
                }
                else
                {
                    WriteNext();
                }
            }
        }
    }

    public class PowerShellDelegate
    {
        readonly ScriptBlock _scriptBlock;
        readonly InitialSessionState _initialSessionState;

        private readonly static Dictionary<string, Encoding> ContentTypeEncodings = new Dictionary<string, Encoding>()
        {
            { MediaTypeNames.Application.Json, Encoding.UTF8},
            { MediaTypeNames.Text.Plain, Encoding.ASCII }
        };

        public PowerShellDelegate(ScriptBlock scriptBlock)
        {
            _scriptBlock = scriptBlock;
        }

        public PowerShellDelegate(ScriptBlock scriptBlock, InitialSessionState initialSessionState)
        {
            _scriptBlock = scriptBlock;
            _initialSessionState = initialSessionState;
        }

        public Task InvokeAsync(HttpContext context)
        {
            PSDataCollection<object> inputPipeline = new PSDataCollection<object>();
            PSDataCollection<object> outputPipeline = new PSDataCollection<object>();
            StreamEncoding streamEncoding = new StreamEncoding(context.Response.Body, Encoding.UTF8, outputPipeline);

            ReadInputPipeline(context, streamEncoding, inputPipeline);

            PowerShell powerShell = _initialSessionState == null
                ? PowerShell.Create()
                : PowerShell.Create(_initialSessionState);

            powerShell
                .AddScript("param($script,$context,[Parameter(ValueFromPipeline=$True)]$input) $input | & $script $context")
                .AddArgument(_scriptBlock)
                .AddArgument(context);

            IDisposable registration = context.RequestAborted.Register(() =>
            {
                powerShell.StopAsync((t) =>
                {
                }, context).ContinueWith((t) =>
                {
                });
            });

            Task invokeTask = powerShell.InvokeAsync(inputPipeline, outputPipeline).ContinueWith((t) =>
            {
                registration.Dispose();

                if (t.IsFaulted)
                {
                    streamEncoding.invokeException = t.Exception;
                }

                outputPipeline.Complete();
            });

            return Task.WhenAll(invokeTask, streamEncoding.taskCompletionSource.Task).ContinueWith((t) =>
            {
                powerShell.Dispose();

                if (streamEncoding.invokeException != null && !context.RequestAborted.IsCancellationRequested)
                {
                    throw streamEncoding.invokeException;
                }

                if (t.IsFaulted)
                {
                    throw t.Exception;
                }
            });
        }

        private void ReadInputPipeline(HttpContext context, StreamEncoding streamEncoding, PSDataCollection<object> inputPipeline)
        {
            HttpRequest request = context.Request;

            if (request.HasFormContentType)
            {
                request.ReadFormAsync().ContinueWith((t) =>
                {
                    ContinueWith(t, context, streamEncoding, inputPipeline);
                });
            }
            else
            {
                string contentType = request.ContentType;

                if (contentType == null)
                {
                    streamEncoding.IsWritable();
                    inputPipeline.Complete();
                }
                else
                {
                    ContentType ct = new ContentType(contentType);
                    Encoding encoding = ct.CharSet == null ? null : Encoding.GetEncoding(ct.CharSet);

                    if (encoding == null)
                    {
                        if (ContentTypeEncodings.TryGetValue(contentType, out Encoding enc))
                        {
                            encoding = enc;
                        }
                    }

                    if (encoding == null)
                    {
                        CopyToByteArrayAsync(request.Body).ContinueWith((t) =>
                        {
                            ContinueWith(t, context, streamEncoding, inputPipeline);
                        });
                    }
                    else
                    {
                        CopyToStringAsync(request.Body, encoding).ContinueWith((t) =>
                        {
                            ContinueWith(t, context, streamEncoding, inputPipeline);
                        });
                    }
                }
            }
        }

        private void ContinueWith<T>(Task<T> task, HttpContext context, StreamEncoding streamEncoding, PSDataCollection<object> inputPipeline)
        {
            try
            {
                streamEncoding.IsWritable();

                if (task.IsFaulted)
                {
                    inputPipeline.Add(new ErrorRecord(task.Exception, GetType().FullName + ".InvokeAsync", ErrorCategory.InvalidData, context));
                }
                else
                {
                    inputPipeline.Add(task.Result);
                }
            }
            finally
            {
                inputPipeline.Complete();
            }
        }

        private async Task<byte[]> CopyToByteArrayAsync(Stream stream)
        {
            MemoryStream memory = new MemoryStream();

            await stream.CopyToAsync(memory);

            return memory.ToArray();
        }

        private Task<string> CopyToStringAsync(Stream stream, Encoding encoding)
        {
            var reader = new StreamReader(stream, encoding);

            return reader.ReadToEndAsync();
        }
    }
}
