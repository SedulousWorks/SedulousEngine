using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;

namespace Sedulous.Core.Tests;

/// The names a generated body stores its fields under.
///
/// These ARE the format for any text backend, and they have to agree with what a
/// hand-written body writes, which has always been camelCase. Binary ignores keys, so
/// nothing already cooked depends on this, but a text envelope a person opens does.
class WireKeyTests
{
	private static void Join(List<String> keys, String outText)
	{
		for (let key in keys)
		{
			if (!outText.IsEmpty)
				outText.Append(", ");
			outText.Append(key);
		}
	}

	private static void CaptureKeys(ISerializable value, List<String> outKeys)
	{
		let buffer = scope MemoryStream();
		let recorder = scope KeyRecordingSerializer(buffer, .Write);
		value.Serialize(recorder);

		for (let key in recorder.Keys)
			outKeys.Add(new String(key));
	}

	/// The first letter is lowered and nothing else is touched, so an inner capital
	/// survives: a field named Id2 stores as "id2", not "id_2" or "ID2".
	[Test]
	public static void AGeneratedKeyIsTheFieldNameWithALowerFirstLetter()
	{
		let sample = scope SerializableSample();
		let keys = scope List<String>();
		defer { ClearAndDeleteItems!(keys); }
		CaptureKeys(sample, keys);

		// Position is a type that describes ITSELF, so its own hand-written body nests
		// x, y and z under the generated key. Both halves are camelCase, which is the
		// point: a text envelope reads the same whoever wrote the body.
		let expected = scope String[](
			"id", "weight", "enabled", "kind", "position", "x", "y", "z", "id2", "name");
		Test.Assert(keys.Count == expected.Count, scope $"emitted: {Join(keys, .. scope String())}");

		for (int i = 0; i < expected.Count; i++)
			Test.Assert(keys[i] == expected[i], scope $"key {i} was '{keys[i]}'");
	}

	/// And they come out in DECLARATION order, which is the binary format: a reader is
	/// positional, so a reordered field silently reinterprets every one after it.
	[Test]
	public static void TheKeysFollowDeclarationOrder()
	{
		let sample = scope SerializableSample();
		let keys = scope List<String>();
		defer { ClearAndDeleteItems!(keys); }
		CaptureKeys(sample, keys);

		Test.Assert(keys[0] == "id", "the first field declared");
		Test.Assert(keys[keys.Count - 1] == "name", "and the last");
	}

	/// A derived type writes the BASE's fields first, under the same convention: the base
	/// state is part of what the object is, and a positional reader needs it in one order.
	[Test]
	public static void AnInheritedFieldKeysTheSameWay()
	{
		let sample = scope InheritedLeaf();
		let keys = scope List<String>();
		defer { ClearAndDeleteItems!(keys); }
		CaptureKeys(sample, keys);

		let expected = scope String[](
			"rootId", "rootName", "middleWeight", "leafPosition", "x", "y", "z", "leafEnabled");
		Test.Assert(keys.Count == expected.Count,
			scope $"emitted: {Join(keys, .. scope String())}");
		for (int i = 0; i < expected.Count; i++)
			Test.Assert(keys[i] == expected[i], scope $"key {i} was '{keys[i]}'");
	}

	/// A list field keys the same way, and the elements inside it carry no keys of their
	/// own: an array is positional.
	[Test]
	public static void AListFieldKeysOnlyItself()
	{
		let sample = scope ListSample();
		sample.Counts.Add(1);
		sample.Counts.Add(2);

		let keys = scope List<String>();
		defer { ClearAndDeleteItems!(keys); }
		CaptureKeys(sample, keys);

		let expected = scope String[]("head", "blob", "counts", "weights", "points", "tail");
		Test.Assert(keys.Count == expected.Count,
			scope $"emitted: {Join(keys, .. scope String())}");
		for (int i = 0; i < expected.Count; i++)
			Test.Assert(keys[i] == expected[i], scope $"key {i} was '{keys[i]}'");
	}
}
