using System;
using System.Collections;
using Sedulous.Render;

namespace Sedulous.Render.Tests;

/// The sort keys, and the sort over them.
class SortKeyTests
{
	/// The fields are ordered by SIGNIFICANCE, so one ascending sort gives the frame's order:
	/// category first, then the state clustering, then depth.
	[Test]
	public static void TheCategoryDominatesThenStateThenDepth()
	{
		let opaqueLate = SortKeys.MakeSortKey(RenderCategories.Opaque, 0xFFFFFF, 0xFFFFFF);
		let transparentEarly = SortKeys.MakeSortKey(RenderCategories.Transparent, 0, 0);
		Test.Assert(opaqueLate < transparentEarly, "the category outranks everything");

		let lowState = SortKeys.MakeSortKey(RenderCategories.Opaque, 1, 0xFFFFFF);
		let highState = SortKeys.MakeSortKey(RenderCategories.Opaque, 2, 0);
		Test.Assert(lowState < highState, "then the state clustering");

		let nearer = SortKeys.MakeSortKey(RenderCategories.Opaque, 1, 10);
		let further = SortKeys.MakeSortKey(RenderCategories.Opaque, 1, 20);
		Test.Assert(nearer < further, "and then depth");
	}

	/// A field wider than its slot is MASKED rather than spilling into the one above it.
	[Test]
	public static void TheFieldsCannotSpillIntoEachOther()
	{
		let overflowing = SortKeys.MakeSortKey(RenderCategories.Opaque, 0xFFFFFFFF, 0xFFFFFFFF);
		let saturated = SortKeys.MakeSortKey(RenderCategories.Opaque, 0xFFFFFF, 0xFFFFFF);
		Test.Assert(overflowing == saturated);
	}

	[Test]
	public static void DepthQuantisesAcrossTheWholeRange()
	{
		Test.Assert(SortKeys.QuantizeDepth(0.0f, false) == 0);
		Test.Assert(SortKeys.QuantizeDepth(1.0f, false) == (1 << SortKeys.DepthBits) - 1);
		Test.Assert(SortKeys.QuantizeDepth(-5.0f, false) == 0, "clamped below");
		Test.Assert(SortKeys.QuantizeDepth(5.0f, false) == (1 << SortKeys.DepthBits) - 1);
	}

	/// Inverting is what turns a front to back key into a back to front one, which is the
	/// only difference between an opaque draw's key and a blended one's.
	[Test]
	public static void InvertingReversesTheDepthOrder()
	{
		let near = SortKeys.QuantizeDepth(0.25f, false);
		let far = SortKeys.QuantizeDepth(0.75f, false);
		Test.Assert(near < far);

		let nearInverted = SortKeys.QuantizeDepth(0.25f, true);
		let farInverted = SortKeys.QuantizeDepth(0.75f, true);
		Test.Assert(nearInverted > farInverted);
	}

	/// The batch key folds two identities together and stays inside the state field, so it
	/// cannot disturb the category above it.
	[Test]
	public static void TheBatchKeyStaysWithinItsField()
	{
		var a = 1;
		var b = 2;
		let key = SortKeys.BatchKey(&a, &b);

		Test.Assert(key < (1U << SortKeys.StateBits));
		Test.Assert(SortKeys.BatchKey(&a, &b) == key, "and it is stable");
		Test.Assert(SortKeys.BatchKey(&b, &a) != key, "while the order of the pair matters");
	}

	[Test]
	public static void TheSortIsAscending()
	{
		let items = scope List<DrawItem>();
		items.Add(.(500, null));
		items.Add(.(3, null));
		items.Add(.(0xFFFFFFFFFFUL, null));
		items.Add(.(42, null));

		let scratch = scope List<DrawItem>();
		DrawItemSorter.RadixSortDrawItems(items, scratch);

		for (int i = 1; i < items.Count; i++)
			Test.Assert(items[i - 1].Key <= items[i].Key);
		Test.Assert(items[0].Key == 3);
	}

	/// STABLE: two draws with equal keys keep the order extraction gave them, so a frame does
	/// not flicker between two orderings of the same scene.
	[Test]
	public static void EqualKeysKeepTheirOrder()
	{
		let first = scope MeshRenderData();
		let second = scope MeshRenderData();
		let third = scope MeshRenderData();

		let items = scope List<DrawItem>();
		items.Add(.(7, first));
		items.Add(.(7, second));
		items.Add(.(7, third));

		let scratch = scope List<DrawItem>();
		DrawItemSorter.RadixSortDrawItems(items, scratch);

		Test.Assert(items[0].Data == first);
		Test.Assert(items[1].Data == second);
		Test.Assert(items[2].Data == third);
	}

	[Test]
	public static void SortingNothingIsFine()
	{
		let items = scope List<DrawItem>();
		let scratch = scope List<DrawItem>();

		DrawItemSorter.RadixSortDrawItems(items, scratch);
		Test.Assert(items.IsEmpty);

		items.Add(.(1, null));
		DrawItemSorter.RadixSortDrawItems(items, scratch);
		Test.Assert(items.Count == 1);
	}
}
