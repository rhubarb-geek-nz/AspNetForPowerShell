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

using System.Reflection;

namespace UnitTests
{
    internal class WebClientFactory
    {
        readonly Assembly assemblyTestApp;
        readonly Type typeFactoryProgram;

        internal WebClientFactory(string appName)
        {
            assemblyTestApp = Assembly.LoadFrom(AppDomain.CurrentDomain.BaseDirectory + Path.DirectorySeparatorChar + appName);
            typeFactoryProgram = typeof(WebApplicationFactory<>).MakeGenericType(new[] { assemblyTestApp.GetType("Program") });
        }

        public IWebClient Create()
        {
            return new WebClient(typeFactoryProgram);
        }
    }

    internal class WebClient : IWebClient
    {
        readonly Type typeFactoryProgram;
        readonly PropertyInfo propertyServices;
        readonly MethodInfo methodCreateClient;
        readonly IDisposable factory;

        internal WebClient(Type t)
        {
            typeFactoryProgram = t;
            propertyServices = typeFactoryProgram.GetProperty("Services", typeof(IServiceProvider));
            methodCreateClient = typeFactoryProgram.GetMethod("CreateClient", Array.Empty<Type>());
            factory = (IDisposable)Activator.CreateInstance(typeFactoryProgram);
        }

        public IServiceProvider Services => (IServiceProvider)propertyServices.GetValue(factory);
        public HttpClient CreateClient() => (HttpClient)methodCreateClient.Invoke(factory,null);
        public void Dispose() => factory.Dispose();
    }
}
