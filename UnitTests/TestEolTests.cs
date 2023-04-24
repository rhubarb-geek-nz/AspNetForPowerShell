/**************************************************************************
 *
 *  Copyright 2023, Roger Brown
 *
 *  This file is part of rhubarb-geek-nz/AspNetForPowerShell.
 *
 *  This program is free software: you can redistribute it and/or modify it
 *  under the terms of the GNU Lesser General Public License as published by the
 *  Free Software Foundation, either version 3 of the License, or (at your
 *  option) any later version.
 * 
 *  This program is distributed in the hope that it will be useful, but WITHOUT
 *  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 *  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 *  more details.
 *
 *  You should have received a copy of the GNU Lesser General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>
 *
 */

using System.Text;
using TestEol;

namespace UnitTests
{
    [TestClass]
    public class TestEolTests
    {
        [TestMethod]
        public async Task SimpleGet()
        {
            using var app = new WebApplicationFactory<Program>();
            string url = "/foo";

            using var client = app.CreateClient();

            var response = await client.GetAsync(url);

            response.EnsureSuccessStatusCode();

            var content = await response.Content.ReadAsStringAsync();
            
            Assert.IsTrue(content.Contains(url),$"Contains {url}");

            Assert.AreEqual("text/plain", response.Content.Headers.ContentType.ToString());
        }

        [TestMethod]
        public async Task SimpleFormPost()
        {
            using var app = new WebApplicationFactory<Program>();
            string url = "/bar";

            using var client = app.CreateClient();

            HttpContent body = new StringContent("a=b", Encoding.UTF8, "application/x-www-form-urlencoded");

            var response = await client.PostAsync(url, body);

            response.EnsureSuccessStatusCode();

            var content = await response.Content.ReadAsStringAsync();

            Assert.AreEqual("application/json", response.Content.Headers.ContentType.ToString());
        }

        [TestMethod]
        public async Task SimpleStringPost()
        {
            using var app = new WebApplicationFactory<Program>();
            string url = "/bar";

            using var client = app.CreateClient();

            HttpContent body = new StringContent("a=b", Encoding.ASCII, "text/plain");

            var response = await client.PostAsync(url, body);

            response.EnsureSuccessStatusCode();

            var content = await response.Content.ReadAsStringAsync();

            Assert.AreEqual("application/json", response.Content.Headers.ContentType.ToString());
        }
    }
}