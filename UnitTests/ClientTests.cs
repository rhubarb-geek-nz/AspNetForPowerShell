// Copyright (c) 2023 Roger Brown.
// Licensed under the MIT License.

using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.DependencyInjection;
using System.Net;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;

namespace UnitTests
{
    public abstract class ClientTests
    {
        protected abstract IWebApplicationFactory CreateWebApplicationFactory();

        [TestMethod]
        public async Task GetFoo()
        {
            using var app = CreateWebApplicationFactory();
            string url = "/foo";

            using var client = app.CreateClient();

            var response = await client.GetAsync(url);

            response.EnsureSuccessStatusCode();

            var content = await response.Content.ReadAsStringAsync();

            Assert.AreEqual("text/plain", response.Content.Headers.ContentType.ToString());

            Assert.AreEqual($"GET {url} ", content);
        }

        [TestMethod]
        public async Task GetHeaders()
        {
            using var app = CreateWebApplicationFactory();

            using var client = app.CreateClient();

            var response = await client.GetAsync("/Headers");

            response.EnsureSuccessStatusCode();

            var content = await response.Content.ReadAsStringAsync();

            Assert.AreEqual("application/json", response.Content.Headers.ContentType.ToString());

            var result = JsonNode.Parse(content);

            Assert.AreEqual("Host", result["Key"].ToString());
            Assert.AreEqual("localhost", result["Value"][0].ToString());
        }

        [TestMethod]
        public async Task GetQuery()
        {
            using var app = CreateWebApplicationFactory();

            using var client = app.CreateClient();

            var response = await client.GetAsync("/Query?a=b");

            response.EnsureSuccessStatusCode();

            var content = await response.Content.ReadAsStringAsync();

            Assert.AreEqual("application/json", response.Content.Headers.ContentType.ToString());

            var result = JsonNode.Parse(content);

            Assert.AreEqual("a", result["Key"].ToString());
            Assert.AreEqual("b", result["Value"][0].ToString());
        }

        [TestMethod]
        public async Task GetContentRootPath()
        {
            using var app = CreateWebApplicationFactory();
            var env = app.Services.GetService<IWebHostEnvironment>();
            using var client = app.CreateClient();

            var response = await client.GetAsync("/ContentRootPath");

            response.EnsureSuccessStatusCode();

            var content = await response.Content.ReadAsStringAsync();

            Assert.AreEqual("text/plain", response.Content.Headers.ContentType.ToString());
            Assert.AreEqual(env.ContentRootPath, content);
        }

        [TestMethod]
        public virtual async Task GetWebRootPath()
        {
            using var app = CreateWebApplicationFactory();
            var env = app.Services.GetService<IWebHostEnvironment>();
            using var client = app.CreateClient();

            var response = await client.GetAsync("/WebRootPath");

            response.EnsureSuccessStatusCode();

            var content = await response.Content.ReadAsStringAsync();

            Assert.AreEqual("text/plain", response.Content.Headers.ContentType.ToString());
            Assert.AreEqual(env.WebRootPath, content);
        }

        [TestMethod]
        public async Task GetLogger()
        {
            using var app = CreateWebApplicationFactory();
            var env = app.Services.GetService<IWebHostEnvironment>();
            using var client = app.CreateClient();

            var response = await client.GetAsync("/Logger");

            response.EnsureSuccessStatusCode();

            var content = await response.Content.ReadAsStringAsync();

            Assert.AreEqual("text/plain", response.Content.Headers.ContentType.ToString());
            Assert.AreEqual("ok", content);
        }

        [TestMethod]
        public async Task GetNotFound()
        {
            using var app = CreateWebApplicationFactory();
            using var client = app.CreateClient();

            var response = await client.GetAsync("/favicon.ico");

            Assert.AreEqual(HttpStatusCode.NotFound, response.StatusCode);

            var content = await response.Content.ReadAsStringAsync();

            Assert.AreEqual("text/plain", response.Content.Headers.ContentType.ToString());
            Assert.AreEqual("not found", content);
        }

        [TestMethod]
        public async Task GetFault()
        {
            using var app = CreateWebApplicationFactory();
            using var client = app.CreateClient();
            bool fault;

            try
            {
                var response = await client.GetAsync("/Fault");

                fault = response.StatusCode == HttpStatusCode.InternalServerError;
            } 
            catch (AggregateException)
            {
                fault = true;
            }

            Assert.IsTrue(fault,"exception should have been thrown");
        }


        [TestMethod]
        public async Task GetPSVersionTable()
        {
            using var app = CreateWebApplicationFactory();

            using var client = app.CreateClient();

            var response = await client.GetAsync("/PSVersionTable");

            response.EnsureSuccessStatusCode();

            var content = await response.Content.ReadAsStringAsync();

            Assert.AreEqual("application/json", response.Content.Headers.ContentType.ToString());

            var result = JsonNode.Parse(content);

            Assert.AreEqual("Core", result["PSEdition"].ToString());
        }

        [TestMethod]
        public async Task PostForm()
        {
            using var app = CreateWebApplicationFactory();
            string url = "/bar";

            using var client = app.CreateClient();

            HttpContent body = new StringContent("a=b", Encoding.UTF8, "application/x-www-form-urlencoded");

            var response = await client.PostAsync(url, body);

            response.EnsureSuccessStatusCode();

            var content = await response.Content.ReadAsStringAsync();

            Assert.AreEqual("application/json", response.Content.Headers.ContentType.ToString());

            var result = JsonNode.Parse(content);

            Assert.AreEqual("a", result["Key"].ToString());
            Assert.AreEqual("b", result["Value"][0].ToString());
        }

        [TestMethod]
        public async Task PostString()
        {
            using var app = CreateWebApplicationFactory();
            string url = "/bar";
            string data = "foo";

            using var client = app.CreateClient();

            HttpContent body = new StringContent(data, Encoding.ASCII, "text/plain");

            var response = await client.PostAsync(url, body);

            response.EnsureSuccessStatusCode();

            var content = await response.Content.ReadAsStringAsync();

            Assert.AreEqual("application/json", response.Content.Headers.ContentType.ToString());

            var result = JsonSerializer.Deserialize<string>(content);

            Assert.AreEqual(data, result);
        }

        [TestMethod]
        public async Task PostBinary()
        {
            using var app = CreateWebApplicationFactory();
            string url = "/bar";
            byte [] data = Encoding.ASCII.GetBytes("foo");

            using var client = app.CreateClient();

            HttpContent body = new ByteArrayContent(data);

            body.Headers.ContentType = new MediaTypeHeaderValue("application/binary");

            var response = await client.PostAsync(url, body);

            response.EnsureSuccessStatusCode();

            var content = await response.Content.ReadAsStringAsync();

            Assert.AreEqual("application/json", response.Content.Headers.ContentType.ToString());

            var result = JsonNode.Parse(content);

            Assert.AreEqual(data.Length, result.AsArray().Count);

            for (int i = 0; i < data.Length; i++)
            {
                Assert.AreEqual(data[i], (byte)result[i].AsValue());
            }
        }

        [TestMethod]
        public async Task PostQueryString()
        {
            using var app = CreateWebApplicationFactory();

            using var client = app.CreateClient();

            var response = await client.PostAsync("/bar?a=b", null);

            response.EnsureSuccessStatusCode();

            var content = await response.Content.ReadAsStringAsync();

            Assert.AreEqual("text/plain", response.Content.Headers.ContentType.ToString());

            Assert.AreEqual("POST /bar ?a=b",content);
        }
    }
}
