// Copyright (c) 2023 Roger Brown.
// Licensed under the MIT License.

using System.Net;
using System.Text.Json.Nodes;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace UnitTests
{
#if NET6_0_OR_GREATER
    [TestClass]
    public class TestApiTests
    {
        static readonly WebApplicationFactoryBuilder webClientFactoryBuilder = new WebApplicationFactoryBuilder("TestApi.dll");

        protected IWebApplicationFactory app;
        protected HttpClient client;

        [TestInitialize]
        public void Initialize()
        {
            app = webClientFactoryBuilder.Build();
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
            var response = await client.GetAsync("/HelloWorld");

            response.EnsureSuccessStatusCode();

            var content = await response.Content.ReadAsStringAsync();

            Assert.AreEqual("text/plain", response.Content.Headers.ContentType.ToString());
            Assert.AreEqual("Hello World", content);
        }

        [TestMethod]
        public async Task GetWeatherForecast()
        {
            var response = await client.GetAsync("/WeatherForecast");

            response.EnsureSuccessStatusCode();

            var content = await response.Content.ReadAsStringAsync();

            Assert.AreEqual("application/json; charset=utf-8", response.Content.Headers.ContentType.ToString());

            var result = JsonNode.Parse(content);

            Assert.IsInstanceOfType(result[0]["summary"].GetValue<string>(),typeof(string));
        }
    }
#endif
}
