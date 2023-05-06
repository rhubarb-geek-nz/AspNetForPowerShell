// Copyright (c) 2023 Roger Brown.
// Licensed under the MIT License.

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
