﻿/**************************************************************************
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