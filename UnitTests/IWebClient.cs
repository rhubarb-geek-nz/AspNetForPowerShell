// Copyright (c) 2023 Roger Brown.
// Licensed under the MIT License.

namespace UnitTests
{
    public interface IWebClient : IDisposable
    {
        HttpClient CreateClient();
        IServiceProvider Services { get; }
    }
}
