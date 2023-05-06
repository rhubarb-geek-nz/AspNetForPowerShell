// Copyright (c) 2023 Roger Brown.
// Licensed under the MIT License.

namespace UnitTests
{
    [TestClass]
    public class TestAppTests : ClientTests
    {
        static readonly WebApplicationFactoryBuilder webClientFactoryBuilder = new WebApplicationFactoryBuilder("TestApp.dll");
        protected override IWebApplicationFactory CreateWebApplicationFactory() => webClientFactoryBuilder.Build();
    }
}
