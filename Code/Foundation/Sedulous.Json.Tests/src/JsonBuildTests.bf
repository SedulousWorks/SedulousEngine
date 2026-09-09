using System;
using Sedulous.Json;

namespace Sedulous.Json.Tests;

/// Building a document by hand, and what ownership means here.
class JsonBuildTests
{
	[Test]
	public static void AnObjectKeepsInsertionOrderThroughAnOverwrite()
	{
		let object = JsonValue.MakeObject();
		defer delete object;

		object.Set("id", JsonValue.MakeNumber(7));
		object.Set("name", JsonValue.MakeString("tool"));

		let arguments = JsonValue.MakeArray();
		arguments.Add(JsonValue.MakeNumber(1));
		arguments.Add(JsonValue.MakeString("two"));
		object.Set("args", arguments);

		// Overwriting replaces the value and KEEPS the position.
		object.Set("id", JsonValue.MakeNumber(8));

		Test.Assert(object.Get("id").AsInt() == 8);
		Test.Assert(object.Get("args").Count == 2);
		Test.Assert(object.ToString(.. scope String())
			== "{\"id\":8,\"name\":\"tool\",\"args\":[1,\"two\"]}");
	}

	[Test]
	public static void AFreshValueCoercesOnItsFirstSetOrAdd()
	{
		let object = scope JsonValue();
		Test.Assert(object.IsNull);
		object.Set("k", JsonValue.MakeBool(true));
		Test.Assert(object.IsObject);

		let array = scope JsonValue();
		array.Add(JsonValue.MakeNumber(1));
		Test.Assert(array.IsArray);
		Test.Assert(array.Count == 1);
	}

	[Test]
	public static void CoercingAValueDropsWhatItHeld()
	{
		let value = scope JsonValue("was a string");
		value.Add(JsonValue.MakeNumber(1));
		Test.Assert(value.IsArray);
		Test.Assert(value.AsString().IsEmpty);
	}

	[Test]
	public static void GetHandsBackTheLiveChild()
	{
		let object = JsonValue.MakeObject();
		defer delete object;
		object.Set("args", JsonValue.MakeArray());

		// BORROWED, not a copy: this is where Beef parts company with Raptor, whose
		// accessors return an owned value because theirs cross into a script VM.
		object.Get("args").Add(JsonValue.MakeNumber(1));
		Test.Assert(object.Get("args").Count == 1);
	}

	[Test]
	public static void CloneIsIndependent()
	{
		let object = JsonValue.MakeObject();
		defer delete object;
		object.Set("args", JsonValue.MakeArray());
		object.Get("args").Add(JsonValue.MakeNumber(1));

		let copy = object.Get("args").Clone();
		defer delete copy;
		copy.Add(JsonValue.MakeNumber(2));

		Test.Assert(copy.Count == 2);
		// The original is untouched, which is what makes Clone the answer when a caller
		// needs a value that outlives or diverges from its document.
		Test.Assert(object.Get("args").Count == 1);
	}

	[Test]
	public static void ADeepCloneCopiesEveryLevel()
	{
		let object = JsonValue.MakeObject();
		defer delete object;
		object.Set("nested", JsonValue.MakeObject());
		object.Get("nested").Set("value", JsonValue.MakeNumber(1));

		let copy = object.Clone();
		defer delete copy;
		copy.Get("nested").Set("value", JsonValue.MakeNumber(2));

		Test.Assert(object.Get("nested").Get("value").AsInt() == 1);
		Test.Assert(copy.Get("nested").Get("value").AsInt() == 2);
	}

	[Test]
	public static void RemoveDropsAMemberAndItsValue()
	{
		let object = JsonValue.MakeObject();
		defer delete object;
		object.Set("a", JsonValue.MakeNumber(1));
		object.Set("b", JsonValue.MakeNumber(2));

		Test.Assert(object.Remove("a"));
		Test.Assert(!object.Remove("a"));
		Test.Assert(object.Count == 1);
		Test.Assert(object.KeyAt(0) == "b");
	}

	[Test]
	public static void TheTypedReadsFallBackRatherThanFailing()
	{
		let value = scope JsonValue("not a number");
		// A wire field of the wrong type reads as the default, so one bad field does not take
		// the whole message down.
		Test.Assert(value.AsNumber(-1.0) == -1.0);
		Test.Assert(value.AsInt(-1) == -1);
		Test.Assert(value.AsBool(true));
	}
}
