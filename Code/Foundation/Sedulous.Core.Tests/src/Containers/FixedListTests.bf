using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Core.Tests;

/// The inline fixed capacity list.
class FixedListTests
{
	private typealias Small = FixedList<int, const 4>;

	[Test]
	public static void ItStartsEmptyAndFillsToCapacity()
	{
		var list = Small();
		Test.Assert(list.IsEmpty);
		Test.Assert(list.Count == 0);
		Test.Assert(Small.Capacity == 4);

		for (int i < 4)
			list.Add((int)(i + 1));

		Test.Assert(!list.IsEmpty);
		Test.Assert(list.Count == 4);
		Test.Assert(list[0] == 1);
		Test.Assert(list[3] == 4);
		Test.Assert(list.Back == 4);
	}

	/// PopBack returns the LAST element and shortens by one.
	///
	/// Worth its own case: the obvious way to write it reads one past the end before
	/// decrementing, which returns whatever the next slot happens to hold and looks right
	/// on a zeroed array.
	[Test]
	public static void PopBackReturnsTheLastElement()
	{
		var list = Small();
		list.Add(10);
		list.Add(20);
		list.Add(30);

		Test.Assert(list.PopBack() == 30, "the last element, not the slot after it");
		Test.Assert(list.Count == 2);
		Test.Assert(list.Back == 20);

		Test.Assert(list.PopBack() == 20);
		Test.Assert(list.PopBack() == 10);
		Test.Assert(list.IsEmpty);
	}

	[Test]
	public static void ConstructingFromOneItemAndFromASpan()
	{
		var single = Small(7);
		Test.Assert(single.Count == 1);
		Test.Assert(single[0] == 7);

		int[3] source = .(1, 2, 3);
		var fromSpan = Small(Span<int>(&source[0], 3));
		Test.Assert(fromSpan.Count == 3);
		Test.Assert(fromSpan[2] == 3);
	}

	[Test]
	public static void AddRangeAppendsAndSetRangeReplaces()
	{
		var list = Small();
		int[2] first = .(1, 2);
		int[2] second = .(3, 4);

		list.AddRange(.(&first[0], 2));
		list.AddRange(.(&second[0], 2));
		Test.Assert(list.Count == 4);
		Test.Assert(list[3] == 4);

		list.SetRange(.(&second[0], 2));
		Test.Assert(list.Count == 2, "SetRange replaces rather than appending");
		Test.Assert(list[0] == 3);
	}

	/// Clearing zeroes the storage as well as the count, so a cleared list holds no stale
	/// reference to something the caller then freed.
	[Test]
	public static void ClearForgetsTheContents()
	{
		var list = Small();
		list.Add(1);
		list.Add(2);
		list.Clear();

		Test.Assert(list.IsEmpty);
		Test.Assert(list.Count == 0);

		list.Count = 2; // reach past the live range at the storage
		Test.Assert(list[0] == 0, "and the storage was zeroed");
		Test.Assert(list[1] == 0);
	}

	[Test]
	public static void IndexingWritesThrough()
	{
		var list = Small();
		list.Add(1);
		list.Add(2);

		list[0] = 99;
		Test.Assert(list[0] == 99);

		list[1]++; // through the ref accessor
		Test.Assert(list[1] == 3);
	}

	[Test]
	public static void EnumeratingWalksOnlyTheLiveRange()
	{
		var list = Small();
		list.Add(5);
		list.Add(6);
		list.Add(7);

		let seen = scope List<int>();
		for (let value in list)
			seen.Add(value);

		Test.Assert(seen.Count == 3, scope $"walked {seen.Count} of a 4 capacity list holding 3");
		Test.Assert(seen[0] == 5);
		Test.Assert(seen[2] == 7);

		// And an empty list yields nothing rather than its zeroed capacity.
		var empty = Small();
		int count = 0;
		for (let value in empty)
			count++;
		Test.Assert(count == 0);
	}

	/// A copy is INDEPENDENT: the storage is inline, so mutating one must not touch the
	/// other. This is what makes it safe to hold one by value in a descriptor.
	[Test]
	public static void ACopyDoesNotShareStorage()
	{
		var original = Small();
		original.Add(1);
		original.Add(2);

		var copy = original;
		copy.Add(3);
		copy[0] = 99;

		Test.Assert(original.Count == 2, "the original kept its own count");
		Test.Assert(original[0] == 1, "and its own elements");
		Test.Assert(copy.Count == 3);
		Test.Assert(copy[0] == 99);
	}

	[Test]
	public static void EqualityComparesTheLiveRange()
	{
		var a = Small();
		a.Add(1); a.Add(2);
		var b = Small();
		b.Add(1); b.Add(2);
		var c = Small();
		c.Add(1);

		Test.Assert(a == b);
		Test.Assert(!(a == c), "a different count is not equal");

		c.Add(3);
		Test.Assert(!(a == c), "same count, different contents");
	}

	/// The span sees the live range and writes through to the list's own storage.
	[Test]
	public static void AsSpanCoversTheLiveRange()
	{
		var list = Small();
		list.Add(1); list.Add(2); list.Add(3);

		var span = list.AsSpan();
		Test.Assert(span.Length == 3);
		span[0] = 42;
		Test.Assert(list[0] == 42, "the span writes through");
	}
}
