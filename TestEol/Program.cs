// Copyright (c) 2023 Roger Brown.
// Licensed under the MIT License.

using System.Threading.Tasks;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Hosting;

namespace TestEol
{
    public class Program
    {
        public static Task Main(string[] args)
        {
            return Host.CreateDefaultBuilder(args).ConfigureWebHostDefaults(
                webBuilder => webBuilder.UseStartup<Startup>()
            ).Build().RunAsync();
        }
    }
}
