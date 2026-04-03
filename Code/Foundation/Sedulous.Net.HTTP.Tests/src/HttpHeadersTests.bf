namespace Sedulous.Net.HTTP.Tests;

using System;
using System.Collections;
using Sedulous.Net.HTTP;

class HttpHeadersTests
{
	[Test]
	public static void Set_And_Get()
	{
		let headers = scope HttpHeaders();
		headers.Set("Content-Type", "text/html");
		let val = scope String();
		Test.Assert(headers.Get("Content-Type", val));
		Test.Assert(val.Equals("text/html"));
	}

	[Test]
	public static void CaseInsensitive()
	{
		let headers = scope HttpHeaders();
		headers.Set("Content-Type", "text/html");
		let val = scope String();
		Test.Assert(headers.Get("content-type", val));
		Test.Assert(val.Equals("text/html"));
	}

	[Test]
	public static void Set_Replaces()
	{
		let headers = scope HttpHeaders();
		headers.Set("X-Custom", "first");
		headers.Set("X-Custom", "second");
		Test.Assert(headers.Count == 1);
		let val = scope String();
		headers.Get("X-Custom", val);
		Test.Assert(val.Equals("second"));
	}

	[Test]
	public static void Add_AllowsDuplicates()
	{
		let headers = scope HttpHeaders();
		headers.Add("Set-Cookie", "a=1");
		headers.Add("Set-Cookie", "b=2");
		Test.Assert(headers.Count == 2);

		let values = scope List<StringView>();
		headers.GetAll("Set-Cookie", values);
		Test.Assert(values.Count == 2);
	}

	[Test]
	public static void Remove()
	{
		let headers = scope HttpHeaders();
		headers.Set("X-Remove", "value");
		Test.Assert(headers.Contains("X-Remove"));
		headers.Remove("X-Remove");
		Test.Assert(!headers.Contains("X-Remove"));
		Test.Assert(headers.Count == 0);
	}

	[Test]
	public static void Contains()
	{
		let headers = scope HttpHeaders();
		Test.Assert(!headers.Contains("Missing"));
		headers.Set("Present", "yes");
		Test.Assert(headers.Contains("Present"));
		Test.Assert(headers.Contains("present")); // case-insensitive
	}

	[Test]
	public static void ContentLength()
	{
		let headers = scope HttpHeaders();
		Test.Assert(headers.ContentLength == -1);
		headers.ContentLength = 42;
		Test.Assert(headers.ContentLength == 42);
	}

	[Test]
	public static void WriteTo()
	{
		let headers = scope HttpHeaders();
		headers.Set("Host", "example.com");
		headers.Set("Content-Length", "0");
		let buf = scope String();
		headers.WriteTo(buf);
		Test.Assert(buf.Contains("Host: example.com\r\n"));
		Test.Assert(buf.Contains("Content-Length: 0\r\n"));
	}

	[Test]
	public static void Clear()
	{
		let headers = scope HttpHeaders();
		headers.Set("A", "1");
		headers.Set("B", "2");
		headers.Clear();
		Test.Assert(headers.Count == 0);
	}
}
