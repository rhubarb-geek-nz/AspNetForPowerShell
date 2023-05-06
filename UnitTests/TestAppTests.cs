// Copyright (c) 2023 Roger Brown.
// Licensed under the MIT License.

namespace UnitTests
{
    [TestClass]
    public class TestAppTests : ClientTests
    {
        static readonly WebClientFactory webClientFactory = new WebClientFactory("TestApp.dll");
        protected override IWebClient CreateWebClient() => webClientFactory.Create();
    }
}
