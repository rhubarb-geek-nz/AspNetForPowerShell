﻿/**************************************************************************
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

using System.Reflection;

namespace UnitTests
{
#if NET7_0_OR_GREATER
    [TestClass]
    public class TestPS1Tests : ClientTests
    {
        protected override IWebClient CreateWebClient() => new TestPS1WebClient();

        [Ignore]
        public override Task GetWebRootPath() => Task.CompletedTask;
    }
#endif
    class TestPS1WebClient : IWebClient
    {
        static readonly Assembly assemblyTestPS1 = Assembly.LoadFrom(AppDomain.CurrentDomain.BaseDirectory + Path.DirectorySeparatorChar + "TestPS1.dll");
        static readonly Type typeFactoryProgram = typeof(WebApplicationFactory<>).MakeGenericType(new [] { assemblyTestPS1.GetType("Program") });
        static readonly PropertyInfo propertyServices = typeFactoryProgram.GetProperty("Services", typeof(IServiceProvider));
        static readonly MethodInfo methodCreateClient = typeFactoryProgram.GetMethod("CreateClient", Array.Empty<Type>());

        readonly IDisposable factory = (IDisposable)Activator.CreateInstance(typeFactoryProgram);
        public IServiceProvider Services => (IServiceProvider)propertyServices.GetValue(factory);
        public HttpClient CreateClient() => (HttpClient)methodCreateClient.Invoke(factory,null);
        public void Dispose() => factory.Dispose();
    }
}
