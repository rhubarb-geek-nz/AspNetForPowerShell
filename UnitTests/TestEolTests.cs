// Copyright (c) 2023 Roger Brown.
// Licensed under the MIT License.

namespace UnitTests
{
    [TestClass]
    public class TestEolTests : ClientTests
    {
        protected override IWebApplicationFactory CreateWebApplicationFactory() => new WebApplicationFactoryWithInterface<TestEol.Program>();
    }

    class WebApplicationFactoryWithInterface<T> : WebApplicationFactory<T>, IWebApplicationFactory where T : class
    {
    }
}
