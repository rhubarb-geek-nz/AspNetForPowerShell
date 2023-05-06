// Copyright (c) 2023 Roger Brown.
// Licensed under the MIT License.

using TestEol;

namespace UnitTests
{
    [TestClass]
    public class TestEolTests : ClientTests
    {
        protected override IWebClient CreateWebClient() => new TestEolWebClient();
    }

    class TestEolWebClient : WebApplicationFactory<Program>, IWebClient { }
}
