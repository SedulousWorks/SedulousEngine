using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;

namespace Sedulous.Core.Tests;

/// A generated body covers the INHERITED fields as well as the declared ones.
///
/// It did not, and that failed silently: a derived type wrote only its own fields, and a
/// binary read is positional, so the base state was gone with nothing reporting a
/// problem. Raptor leans on this shape throughout, so it is worth pinning down rather
/// than trusting.
class InheritedSerializeTests
{
	[Test]
	public static void EveryLevelOfTheChainRoundTrips()
	{
		let stream = scope MemoryStream();
		let source = scope InheritedLeaf();
		source.RootId = 7;
		source.RootName.Set("root");
		source.MiddleWeight = 2.5f;
		source.LeafPosition = .(1.0f, 2.0f, 3.0f);
		source.LeafEnabled = true;

		{
			let writer = scope BinarySerializer(stream, .Write);
			Serialize(writer, (ISerializable)source);
			Test.Assert(writer.IsOk);
		}

		Test.Assert(stream.Seek(0, .Begin) == 0);
		let target = scope InheritedLeaf();
		let reader = scope BinarySerializer(stream, .Read);
		Serialize(reader, (ISerializable)target);
		Test.Assert(reader.IsOk);

		Test.Assert(target.RootId == 7, "the root level survived");
		Test.Assert(target.RootName == "root");
		Test.Assert(target.MiddleWeight == 2.5f, "and the middle level");
		Test.Assert(target.LeafPosition == Float3(1.0f, 2.0f, 3.0f));
		Test.Assert(target.LeafEnabled);
	}

	/// An inherited field is written ONCE, not once per level below it. Every type
	/// reports its inherited fields, so a walk without the declaring filter writes the
	/// root's fields three times over in this chain.
	[Test]
	public static void AnInheritedFieldIsWrittenExactlyOnce()
	{
		let leaf = scope MemoryStream();
		{
			let source = scope InheritedLeaf();
			let writer = scope BinarySerializer(leaf, .Write);
			Serialize(writer, (ISerializable)source);
		}

		let middle = scope MemoryStream();
		{
			let source = scope InheritedMiddle();
			let writer = scope BinarySerializer(middle, .Write);
			Serialize(writer, (ISerializable)source);
		}

		let root = scope MemoryStream();
		{
			let source = scope InheritedRoot();
			let writer = scope BinarySerializer(root, .Write);
			Serialize(writer, (ISerializable)source);
		}

		// Each level adds exactly its own fields: middle adds one float over root, and
		// leaf adds a Float3 and a bool over middle.
		Test.Assert(middle.Size() == root.Size() + 4,
			scope $"root {root.Size()}, middle {middle.Size()}");
		Test.Assert(leaf.Size() == middle.Size() + 12 + 1,
			scope $"middle {middle.Size()}, leaf {leaf.Size()}");
	}

	/// The base's fields come FIRST. A positional format has no names to resynchronise
	/// on, so the order the chain is walked in is part of the format: reading a leaf's
	/// bytes as its own base must produce the base's values rather than garbage.
	[Test]
	public static void TheBaseIsWrittenBeforeTheDerivedFields()
	{
		let stream = scope MemoryStream();
		{
			let source = scope InheritedLeaf();
			source.RootId = 99;
			source.RootName.Set("prefix");
			source.MiddleWeight = 4.5f;

			let writer = scope BinarySerializer(stream, .Write);
			Serialize(writer, (ISerializable)source);
		}

		// Read the leaf's payload as the MIDDLE type. It is a prefix of the leaf's, so
		// every field the middle knows about lands correctly and the leaf's extra bytes
		// are simply left unread.
		Test.Assert(stream.Seek(0, .Begin) == 0);
		let target = scope InheritedMiddle();
		let reader = scope BinarySerializer(stream, .Read);
		Serialize(reader, (ISerializable)target);

		Test.Assert(reader.IsOk);
		Test.Assert(target.RootId == 99, "the root fields lead the payload");
		Test.Assert(target.RootName == "prefix");
		Test.Assert(target.MiddleWeight == 4.5f);
	}
}
