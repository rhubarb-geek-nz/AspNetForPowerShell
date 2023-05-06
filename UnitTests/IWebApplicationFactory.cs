// Copyright (c) 2023 Roger Brown.
// Licensed under the MIT License.

namespace UnitTests
{
    public interface IWebApplicationFactory : IDisposable,IAsyncDisposable
    {
        HttpClient CreateClient();
        IServiceProvider Services { get; }
    }
}
