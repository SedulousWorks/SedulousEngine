using System;
using Sedulous.Json;

namespace Sedulous.Json.Tests;

/// Writing, and the round trip through it.
class JsonWriteTests
{
	private static void Text(JsonValue value, String outText, bool pretty = false) =>
		value.ToString(outText, pretty);

	[Test]
	public static void ScalarsWrite()
	{
		let number = scope JsonValue(42.0);
		// A whole number keeps its integer form rather than gaining a decimal point.
		Test.Assert(Text(number, .. scope String()) == "42");

		let nothing = scope JsonValue();
		Test.Assert(Text(nothing, .. scope String()) == "null");

		let flag = scope JsonValue(true);
		Test.Assert(Text(flag, .. scope String()) == "true");

		let fraction = scope JsonValue(0.5);
		Test.Assert(Text(fraction, .. scope String()) == "0.5");
	}

	[Test]
	public static void StringsAreEscaped()
	{
		let value = scope JsonValue("a\"b\n");
		Test.Assert(Text(value, .. scope String()) == "\"a\\\"b\\n\"");
	}

	[Test]
	public static void AControlCharacterBecomesAUnicodeEscape()
	{
		let value = scope JsonValue("a\x01b");
		Test.Assert(Text(value, .. scope String()) == "\"a\\u0001b\"");
	}

	[Test]
	public static void NonFiniteNumbersDegradeToNull()
	{
		// JSON cannot represent either, and writing them raw would make the output
		// unparseable.
		let notANumber = scope JsonValue(double.NaN);
		Test.Assert(Text(notANumber, .. scope String()) == "null");

		let infinite = scope JsonValue(double.PositiveInfinity);
		Test.Assert(Text(infinite, .. scope String()) == "null");
	}

	[Test]
	public static void ADocumentRoundTripsByteForByte()
	{
		let source = "{\"a\":1,\"b\":[true,null,\"x\"],\"c\":{}}";

		let value = JsonValue.Parse(source);
		defer delete value;
		Test.Assert(Text(value, .. scope String()) == source);
	}

	[Test]
	public static void ThePrettyFormReparsesToTheSameDocument()
	{
		let source = "{\"a\":1,\"b\":[true,null,\"x\"],\"c\":{}}";

		let value = JsonValue.Parse(source);
		defer delete value;

		let pretty = Text(value, .. scope String(), true);
		Test.Assert(pretty.Length > source.Length);

		let reparsed = JsonValue.Parse(pretty);
		defer delete reparsed;
		Test.Assert(Text(reparsed, .. scope String()) == source);
	}

	[Test]
	public static void EmptyContainersWriteCompactInBothForms()
	{
		let array = JsonValue.MakeArray();
		defer delete array;
		Test.Assert(Text(array, .. scope String(), true) == "[]");

		let object = JsonValue.MakeObject();
		defer delete object;
		Test.Assert(Text(object, .. scope String(), true) == "{}");
	}
}
