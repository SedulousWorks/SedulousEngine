namespace Sedulous.Net.HTTP.Tests;

using System;
using Sedulous.Net.HTTP;

class HttpMethodTests
{
	[Test]
	public static void Parse_GET()
	{
		Test.Assert(HttpMethod.Parse("GET") case .Ok(.GET));
	}

	[Test]
	public static void Parse_POST()
	{
		Test.Assert(HttpMethod.Parse("POST") case .Ok(.POST));
	}

	[Test]
	public static void Parse_CaseInsensitive()
	{
		Test.Assert(HttpMethod.Parse("get") case .Ok(.GET));
		Test.Assert(HttpMethod.Parse("Post") case .Ok(.POST));
		Test.Assert(HttpMethod.Parse("delete") case .Ok(.DELETE));
	}

	[Test]
	public static void Parse_AllMethods()
	{
		Test.Assert(HttpMethod.Parse("PUT") case .Ok(.PUT));
		Test.Assert(HttpMethod.Parse("DELETE") case .Ok(.DELETE));
		Test.Assert(HttpMethod.Parse("PATCH") case .Ok(.PATCH));
		Test.Assert(HttpMethod.Parse("HEAD") case .Ok(.HEAD));
		Test.Assert(HttpMethod.Parse("OPTIONS") case .Ok(.OPTIONS));
	}

	[Test]
	public static void Parse_Invalid()
	{
		Test.Assert(HttpMethod.Parse("INVALID") case .Err);
		Test.Assert(HttpMethod.Parse("") case .Err);
	}

	[Test]
	public static void ToString_Roundtrip()
	{
		let str = scope String();
		HttpMethod.GET.ToString(str);
		Test.Assert(str.Equals("GET"));
		Test.Assert(HttpMethod.Parse(str) case .Ok(.GET));
	}
}
