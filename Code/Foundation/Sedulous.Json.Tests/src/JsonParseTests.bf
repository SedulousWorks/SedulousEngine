using System;
using Sedulous.Json;

namespace Sedulous.Json.Tests;

/// Parsing: scalars, escapes, containers, and what a malformed document produces.
class JsonParseTests
{
	private static bool Near(double a, double b, double epsilon = 0.0001) =>
		((a - b) <= epsilon) && ((b - a) <= epsilon);

	[Test]
	public static void ScalarsParse()
	{
		let result = scope JsonParseResult();

		JsonParser.Parse("null", result);
		Test.Assert(result.Ok && result.Value.IsNull);

		JsonParser.Parse("true", result);
		Test.Assert(result.Ok && result.Value.IsBool);
		Test.Assert(result.Value.AsBool());

		JsonParser.Parse("false", result);
		Test.Assert(!result.Value.AsBool());

		// Leading and trailing whitespace, a sign and an exponent.
		JsonParser.Parse("  -12.5e2 ", result);
		Test.Assert(result.Ok && result.Value.IsNumber);
		Test.Assert(Near(result.Value.AsNumber(), -1250.0));

		JsonParser.Parse("42", result);
		Test.Assert(result.Value.AsInt() == 42);

		JsonParser.Parse("\"hi\"", result);
		Test.Assert(result.Ok && result.Value.IsString);
		Test.Assert(result.Value.AsString() == "hi");
	}

	[Test]
	public static void TheSimpleEscapesDecode()
	{
		let result = scope JsonParseResult();

		JsonParser.Parse("\"a\\nb\"", result);
		Test.Assert(result.Value.AsString() == "a\nb");

		JsonParser.Parse("\"tab\\tend\"", result);
		Test.Assert(result.Value.AsString() == "tab\tend");

		JsonParser.Parse("\"q\\\"q\"", result);
		Test.Assert(result.Value.AsString() == "q\"q");

		// A solidus may be escaped, and decodes to itself.
		JsonParser.Parse("\"sl\\/sl\"", result);
		Test.Assert(result.Value.AsString() == "sl/sl");
	}

	[Test]
	public static void ABmpEscapeDecodesToUtf8()
	{
		let result = scope JsonParseResult();
		// U+00E9, which is two bytes in UTF-8.
		JsonParser.Parse("\"\\u00e9\"", result);
		Test.Assert(result.Ok);

		let text = result.Value.AsString();
		Test.Assert(text.Length == 2);
		Test.Assert((uint8)text[0] == 0xC3);
		Test.Assert((uint8)text[1] == 0xA9);
	}

	[Test]
	public static void ASurrogatePairDecodesToOneCodepoint()
	{
		let result = scope JsonParseResult();
		// U+1F600, which only fits in JSON as a surrogate pair and in UTF-8 as four bytes.
		JsonParser.Parse("\"\\ud83d\\ude00\"", result);
		Test.Assert(result.Ok);
		Test.Assert(result.Value.AsString().Length == 4);
	}

	[Test]
	public static void ALoneSurrogateIsRejected()
	{
		let result = scope JsonParseResult();

		JsonParser.Parse("\"\\ud83d\"", result);
		Test.Assert(!result.Ok);

		JsonParser.Parse("\"\\ude00\"", result);
		Test.Assert(!result.Ok);
	}

	[Test]
	public static void ArraysParseAndNest()
	{
		let result = scope JsonParseResult();
		JsonParser.Parse("[1, 2, [3, 4], null]", result);

		Test.Assert(result.Ok && result.Value.IsArray);
		Test.Assert(result.Value.Count == 4);
		Test.Assert(Near(result.Value.At(0).AsNumber(), 1.0));
		Test.Assert(result.Value.At(2).IsArray);
		Test.Assert(result.Value.At(2).At(1).AsInt() == 4);
		Test.Assert(result.Value.At(3).IsNull);
		// Out of range is null rather than a crash.
		Test.Assert(result.Value.At(99) == null);
	}

	[Test]
	public static void ObjectsParseAndKeepTheirOrder()
	{
		let result = scope JsonParseResult();
		JsonParser.Parse("{\"name\":\"sedulous\",\"n\":3,\"nested\":{\"ok\":true}}", result);

		Test.Assert(result.Ok && result.Value.IsObject);
		Test.Assert(result.Value.Count == 3);
		Test.Assert(result.Value.Has("name"));
		Test.Assert(result.Value.Get("name").AsString() == "sedulous");
		Test.Assert(result.Value.Get("n").AsInt() == 3);
		Test.Assert(result.Value.Get("nested").Get("ok").AsBool());
		// Absent is null, which is distinguishable from a member that IS null.
		Test.Assert(result.Value.Get("missing") == null);
		Test.Assert(result.Value.KeyAt(0) == "name");
		Test.Assert(result.Value.KeyAt(2) == "nested");
	}

	[Test]
	public static void EmptyContainersParse()
	{
		let result = scope JsonParseResult();

		JsonParser.Parse("[]", result);
		Test.Assert(result.Ok && result.Value.IsArray && (result.Value.Count == 0));

		JsonParser.Parse("{}", result);
		Test.Assert(result.Ok && result.Value.IsObject && (result.Value.Count == 0));
	}

	[Test]
	public static void MalformedInputGivesACleanNullAndAMessage()
	{
		let bad = scope String[](
			"", "{", "[1,]", "{\"a\":}", "nul", "\"open", "[1 2]", "{a:1}", "1 2",
			"\"bad\\x\"", "-", "01", "[", "}");

		let result = scope JsonParseResult();
		for (let text in bad)
		{
			JsonParser.Parse(text, result);
			Test.Assert(!result.Ok);
			// Never a half built document.
			Test.Assert(result.Value.IsNull);
			Test.Assert(!result.Error.IsEmpty);
		}
	}

	[Test]
	public static void TheFirstErrorIsTheOneReported()
	{
		let result = scope JsonParseResult();
		// The inner failure is what explains the document; everything after it is the unwind.
		JsonParser.Parse("[[[\"unterminated]]]", result);
		Test.Assert(!result.Ok);
		Test.Assert(result.Error == "unterminated string");
	}

	[Test]
	public static void DeepNestingIsRefusedRatherThanRunningOffTheStack()
	{
		let deep = scope String();
		for (int i = 0; i < 5000; i++)
			deep.Append('[');

		let result = scope JsonParseResult();
		JsonParser.Parse(deep, result);
		Test.Assert(!result.Ok);
		Test.Assert(result.Error == "maximum nesting depth exceeded");
	}

	/// RFC 8259: a number may not carry a leading zero. The malformed list above catches the
	/// bare case, but not a nested one, and not the half that actually bites.
	///
	/// That half is the legitimate zero forms. A leading-zero rule written one character too
	/// wide rejects `0`, `-0`, `0.5` and `0e2`, all of which are valid JSON, and the failure
	/// then looks like arithmetic going wrong rather than parsing.
	[Test]
	public static void ALeadingZeroIsNotANumberButZeroItselfIs()
	{
		let result = scope JsonParseResult();

		// Nested as well as bare: a scanner that only checks the first token misses these.
		let bad = scope String[]("01", "-01", "[1, 007]", "{\"a\": 00}");
		for (let text in bad)
		{
			JsonParser.Parse(text, result);
			Test.Assert(!result.Ok, scope $"{text} is not a number");
		}

		for (let text in scope String[]("0", "-0", "0e2", "[0, 10, 100]"))
		{
			JsonParser.Parse(text, result);
			Test.Assert(result.Ok, scope $"{text} is valid JSON");
		}

		JsonParser.Parse("0.5", result);
		Test.Assert(result.Ok && Near(result.Value.AsNumber(), 0.5));
	}
}
