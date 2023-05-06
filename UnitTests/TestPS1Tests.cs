// Copyright (c) 2023 Roger Brown.
// Licensed under the MIT License.

namespace UnitTests
{
#if NET7_0_OR_GREATER
    [TestClass]
    public class TestPS1Tests : ClientTests
    {
        static readonly WebClientFactory webClientFactory = new WebClientFactory("TestPS1.dll");
        protected override IWebClient CreateWebClient() => webClientFactory.Create();
        [Ignore]
        public override Task GetWebRootPath() => Task.CompletedTask;
    }
#endif
}
