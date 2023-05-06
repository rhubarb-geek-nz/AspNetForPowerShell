// Copyright (c) 2023 Roger Brown.
// Licensed under the MIT License.

namespace UnitTests
{
    [TestClass]
    public class TestPs1Tests : ClientTests
    {
        static readonly WebApplicationFactoryBuilder webClientFactoryBuilder = new WebApplicationFactoryBuilder("TestPs1.dll");
        protected override IWebApplicationFactory CreateWebApplicationFactory() => webClientFactoryBuilder.Build();
        [Ignore]
        public override Task GetWebRootPath() => Task.CompletedTask;
    }
}
