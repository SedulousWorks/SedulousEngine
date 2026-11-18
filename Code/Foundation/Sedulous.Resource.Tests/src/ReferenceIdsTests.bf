using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Resource.Tests;

/// What a holder reads out of a value by reflection: every Ref<T> id, in a nested struct, in a
/// List<> field's elements (an element object's fields too), never a nil id, and never through a
/// [Hidden] list.
class ReferenceIdsTests
{
	[Reflect(.NonStaticFields)]
	private struct Nested
	{
		public Ref<TestProduct> Inner;
		public int32 Count;
	}

	[Reflect(.NonStaticFields)]
	private class Layer
	{
		public Ref<TestProduct> Texture;
	}

	[Reflect(.NonStaticFields)]
	private struct Holder
	{
		public Ref<TestProduct> Mesh;
		public Ref<TestProduct> Unset;
		public Nested Nested;
		public List<Ref<TestProduct>> Materials;
		public List<Layer> Layers;
		[Hidden]
		public List<Ref<TestProduct>> Runtime;
		public float Scale;
	}

	[Test]
	public static void EveryReferenceIsFoundNestedAndInListsAndNoneThroughAHiddenList()
	{
		let ids = scope Guid[6];
		for (int i < ids.Count)
			ids[i] = Guid.Create();
		var holder = Holder();
		holder.Mesh = .(ids[0]);
		holder.Unset = .(Guid.Empty);
		holder.Nested.Inner = .(ids[1]);
		holder.Materials = scope .();
		holder.Materials.Add(.(ids[2]));
		holder.Materials.Add(.(ids[3]));
		holder.Layers = scope .();
		let layer = scope Layer();
		layer.Texture = .(ids[4]);
		holder.Layers.Add(layer);
		holder.Layers.Add(null);
		holder.Runtime = scope .();
		holder.Runtime.Add(.(ids[5]));

		let found = scope HashSet<Guid>();
		ReferenceIds.Collect(typeof(Holder), &holder, found);
		for (int i < 5)
			Test.Assert(found.Contains(ids[i]), scope $"reference {i}");
		Test.Assert(!found.Contains(ids[5]), "a [Hidden] list is runtime state");
		Test.Assert(!found.Contains(Guid.Empty), "a nil id is no reference");
		Test.Assert(found.Count == 5);

		// A Ref<T> on its own.
		let alone = scope HashSet<Guid>();
		ReferenceIds.Collect(typeof(Ref<TestProduct>), &holder.Mesh, alone);
		Test.Assert((alone.Count == 1) && alone.Contains(ids[0]));
	}
}
