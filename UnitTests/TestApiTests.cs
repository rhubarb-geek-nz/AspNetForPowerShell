// Copyright (c) 2023 Roger Brown.
// Licensed under the MIT License.

using System.Net;
using System.Text.Json.Nodes;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.DependencyInjection;

namespace UnitTests
{
#if NET6_0_OR_GREATER
    [TestClass]
    public class TestApiTests
    {
        static readonly WebApplicationFactoryBuilder webClientFactory = new WebApplicationFactoryBuilder("TestApi.dll");
        protected IWebApplicationFactory CreateWebApplicationFactory() => webClientFactory.Build();

        [TestMethod]
        public async Task GetNotFound()
        {
            using var app = CreateWebApplicationFactory();
            using var client = app.CreateClient();

            var response = await client.GetAsync("/favicon.ico");

            Assert.AreEqual(HttpStatusCode.NotFound, response.StatusCode);
        }

        [TestMethod]
        public async Task GetHelloWorld()
        {
            using var app = CreateWebApplicationFactory();
            var env = app.Services.GetService<IWebHostEnvironment>();
            using var client = app.CreateClient();

            var response = await client.GetAsync("/HelloWorld");

            response.EnsureSuccessStatusCode();

            var content = await response.Content.ReadAsStringAsync();

            Assert.AreEqual("text/plain", response.Content.Headers.ContentType.ToString());
            Assert.AreEqual("Hello World", content);
        }

        [TestMethod]
        public async Task GetWeatherForecast()
        {
            using var app = CreateWebApplicationFactory();

            using var client = app.CreateClient();

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
