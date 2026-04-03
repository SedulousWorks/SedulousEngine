namespace Sedulous.Net.HTTP.Tests;

using System;
using Sedulous.Net.HTTP;

class HttpStatusCodeTests
{
	[Test]
	public static void IntValues()
	{
		Test.Assert((int32)HttpStatusCode.OK == 200);
		Test.Assert((int32)HttpStatusCode.NotFound == 404);
		Test.Assert((int32)HttpStatusCode.InternalServerError == 500);
		Test.Assert((int32)HttpStatusCode.Created == 201);
		Test.Assert((int32)HttpStatusCode.BadRequest == 400);
	}

	[Test]
	public static void ReasonPhrase_OK()
	{
		let phrase = scope String();
		HttpStatusCode.OK.GetReasonPhrase(phrase);
		Test.Assert(phrase.Equals("OK"));
	}

	[Test]
	public static void ReasonPhrase_NotFound()
	{
		let phrase = scope String();
		HttpStatusCode.NotFound.GetReasonPhrase(phrase);
		Test.Assert(phrase.Equals("Not Found"));
	}

	[Test]
	public static void ReasonPhrase_InternalServerError()
	{
		let phrase = scope String();
		HttpStatusCode.InternalServerError.GetReasonPhrase(phrase);
		Test.Assert(phrase.Equals("Internal Server Error"));
	}

	[Test]
	public static void ReasonPhrase_SwitchingProtocols()
	{
		let phrase = scope String();
		HttpStatusCode.SwitchingProtocols.GetReasonPhrase(phrase);
		Test.Assert(phrase.Equals("Switching Protocols"));
	}
}
