// Copyright (c) 2023 Roger Brown.
// Licensed under the MIT License.

namespace UnitTests
{
#if NET6_0_OR_GREATER
    [TestClass]
    public class TestPS1Tests : ClientTests
    {
        static readonly WebApplicationFactoryBuilder webClientFactoryBuilder = new WebApplicationFactoryBuilder("TestPS1.dll");
        protected override IWebApplicationFactory CreateWebApplicationFactory() => webClientFactoryBuilder.Build();
        [Ignore]
        public override Task GetWebRootPath() => Task.CompletedTask;
    }
#endif
}
