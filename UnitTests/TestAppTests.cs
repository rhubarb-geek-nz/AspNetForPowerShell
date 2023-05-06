// Copyright (c) 2023 Roger Brown.
// Licensed under the MIT License.

namespace UnitTests
{
    [TestClass]
    public class TestAppTests : ClientTests
    {
        static readonly WebApplicationFactoryBuilder webClientFactory = new WebApplicationFactoryBuilder("TestApp.dll");
        protected override IWebApplicationFactory CreateWebApplicationFactory() => webClientFactory.Build();
    }
}
