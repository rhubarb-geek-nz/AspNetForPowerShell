// Copyright (c) 2023 Roger Brown.
// Licensed under the MIT License.

namespace UnitTests
{
#if NET7_0_OR_GREATER
    [TestClass]
    public class TestPS1Tests : ClientTests
    {
        static readonly WebApplicationFactoryBuilder webClientFactory = new WebApplicationFactoryBuilder("TestPS1.dll");
        protected override IWebApplicationFactory CreateWebApplicationFactory() => webClientFactory.Build();
        [Ignore]
        public override Task GetWebRootPath() => Task.CompletedTask;
    }
#endif
}
