// Copyright (c) 2023 Roger Brown.
// Licensed under the MIT License.

using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.DependencyInjection;
using System.Net;
using System.Text.Json.Nodes;

namespace UnitTests
{
    [TestClass]
    public class TestCgiTests
    {
        static readonly WebApplicationFactoryBuilder webClientFactoryBuilder = new WebApplicationFactoryBuilder("TestCgi.dll");

        protected IWebApplicationFactory app;
        protected IWebHostEnvironment env;
        protected HttpClient client;

        [TestInitialize]
        public void Initialize()
        {
            app = webClientFactoryBuilder.Build();
            env = app.Services.GetService<IWebHostEnvironment>();
            client = app.CreateClient();
        }

        [TestCleanup] 
        public Task Cleanup() 
        { 
            client.Dispose();
            return app.DisposeAsync().AsTask();
        }

        [TestMethod]
        public async Task GetNotFound()
        {
            var response = await client.GetAsync("/favicon.ico");

            Assert.AreEqual(HttpStatusCode.NotFound, response.StatusCode);
        }

        [TestMethod]
        public async Task GetHelloWorld()
        {
            var response = await client.GetAsync("/cgi-bin/HelloWorld.ps1");

            response.EnsureSuccessStatusCode();

            var content = await response.Content.ReadAsStringAsync();

            Assert.AreEqual("text/plain", response.Content.Headers.ContentType.ToString());
            Assert.AreEqual("Hello World", content);
        }

        [TestMethod]
        public async Task GetBlank()
        {
            var response = await client.GetAsync("/blank.txt");

            response.EnsureSuccessStatusCode();

            var content = await response.Content.ReadAsStringAsync();

            Assert.AreEqual("text/plain", response.Content.Headers.ContentType.ToString());
            Assert.AreEqual("This page is intentionally left blank", content.Trim());
        }
    }
}
