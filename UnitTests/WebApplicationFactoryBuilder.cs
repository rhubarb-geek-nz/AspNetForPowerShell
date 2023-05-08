// Copyright (c) 2023 Roger Brown.
// Licensed under the MIT License.

using System.Reflection;

namespace UnitTests
{
    internal class WebApplicationFactoryBuilder
    {
        readonly Assembly assemblyTestApp;
        readonly Type typeFactoryProgram;

        internal WebApplicationFactoryBuilder(string appName, string typeName = null)
        {
            assemblyTestApp = Assembly.LoadFrom(AppDomain.CurrentDomain.BaseDirectory + Path.DirectorySeparatorChar + appName);
            typeFactoryProgram = typeof(WebApplicationFactory<>).MakeGenericType(new[] { assemblyTestApp.GetType(typeName ?? "Program") });
        }

        public IWebApplicationFactory Build()
        {
            return new WebApplicationFactoryReflection(typeFactoryProgram);
        }
    }

    internal class WebApplicationFactoryReflection : IWebApplicationFactory
    {
        readonly Type typeFactoryProgram;
        readonly PropertyInfo propertyServices;
        readonly MethodInfo methodCreateClient;
        readonly object factory;

        internal WebApplicationFactoryReflection(Type t)
        {
            typeFactoryProgram = t;
            propertyServices = typeFactoryProgram.GetProperty("Services", typeof(IServiceProvider));
            methodCreateClient = typeFactoryProgram.GetMethod("CreateClient", Array.Empty<Type>());
            factory = Activator.CreateInstance(typeFactoryProgram);
        }

        public IServiceProvider Services => (IServiceProvider)propertyServices.GetValue(factory);
        public HttpClient CreateClient() => (HttpClient)methodCreateClient.Invoke(factory,null);
        public void Dispose() => (factory as IDisposable).Dispose();
        public ValueTask DisposeAsync() => (factory as IAsyncDisposable).DisposeAsync();
    }
}
