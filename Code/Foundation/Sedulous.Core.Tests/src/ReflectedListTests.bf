using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Core.Tests;

/// IReflectedList over List<T>: the count, the element type and each element's address, read
/// from a list known only as an Object, and written through the address.
class ReflectedListTests
{
	[Test]
	public static void AListKnownOnlyAsAnObjectGivesItsCountTypeAndElements()
	{
		let floats = scope List<float>() { 1.5f, 2.5f, 3.5f };
		Object opaque = floats;
		let list = opaque as IReflectedList;
		Test.Assert(list != null, "every List<T> is one");
		Test.Assert(list.Count == 3);
		Test.Assert(list.ElementType == typeof(float));
		Test.Assert(*(float*)list.ElementAddress(1) == 2.5f);
		*(float*)list.ElementAddress(2) = 9.0f;
		Test.Assert(floats[2] == 9.0f, "the address is the list's own storage");

		// A struct element and an object element: the address is where the element lives, so
		// an object element's address holds the reference.
		let vectors = scope List<Float3>() { .(1, 2, 3) };
		let strings = scope List<String>() { "a" };
		Test.Assert(((Object)vectors as IReflectedList).ElementType == typeof(Float3));
		Test.Assert((*(Float3*)((Object)vectors as IReflectedList).ElementAddress(0)).Z == 3.0f);
		Test.Assert(*(String*)((Object)strings as IReflectedList).ElementAddress(0) == strings[0]);

		let empty = scope List<int>();
		Test.Assert(((Object)empty as IReflectedList).Count == 0);
		Test.Assert((Object)scope String() as IReflectedList == null, "not a list");
	}
}
