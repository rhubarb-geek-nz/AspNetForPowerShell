// Copyright (c) 2023 Roger Brown.
// Licensed under the MIT License.

namespace UnitTests
{
    public interface IWebApplicationFactory : IDisposable
    {
        HttpClient CreateClient();
        IServiceProvider Services { get; }
    }
}
