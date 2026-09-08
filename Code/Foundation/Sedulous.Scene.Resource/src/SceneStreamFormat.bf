using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;

namespace Sedulous.Scene.Resource;

/// The scene stream's shape: its header, and the small pieces every section is built from.
///
/// ONE format. Raptor still reads its v1 and v2 streams and the three retired prefab
/// section layouts; nothing has ever been written in those here, so this reads and writes
/// the current form only and refuses anything else by name. A version field stays in the
/// header so a future change has somewhere to say so.
static class SceneStreamFormat
{
	/// A sentinel chosen so it cannot be mistaken for a length prefix.
	public const uint32 cMagic = 0xD5C35CEE;
	public const uint32 cVersion = 3;

	/// The prefab section's tag. Referenced carries the nesting links, the sibling order
	/// and the placement flag; expanded carries the member maps and baselines.
	public const uint8 cPrefabWireReferenced = 4;
	public const uint8 cPrefabWireExpanded = 3;

	public static void WriteHeader(ISerializer ar)
	{
		var magic = cMagic;
		var version = cVersion;
		SerializeValue(ar, "magic", ref magic);
		SerializeValue(ar, "version", ref version);
	}

	/// Reads and CHECKS the header, failing the payload when it is not this format. A
	/// stream that is not ours must stop here rather than be parsed as though it were: the
	/// next thing read would be a count, and a garbage count allocates.
	public static Result<void> ReadHeader(ISerializer ar)
	{
		uint32 magic = 0;
		SerializeValue(ar, "magic", ref magic);
		if (magic != cMagic)
		{
			ar.FailPayload(.InvalidArgument);
			return .Err;
		}

		uint32 version = 0;
		SerializeValue(ar, "version", ref version);
		if (version != cVersion)
		{
			ar.FailPayload(.InvalidArgument);
			return .Err;
		}
		return .Ok;
	}

	/// The first non whitespace byte says which encoding a stream is in: a text stream
	/// opens with '<' and a binary one opens with the magic. Leaves the stream where it
	/// found it, so a caller can sniff and then read.
	public static SceneStreamEncoding DetectEncoding(IStream stream)
	{
		let start = stream.Tell();
		var encoding = SceneStreamEncoding.Binary;

		uint8 byte = 0;
		while (stream.Read(.(&byte, 1)) == 1)
		{
			if ((byte == (uint8)' ') || (byte == (uint8)'\t') || (byte == (uint8)'\r')
				|| (byte == (uint8)'\n'))
				continue;
			encoding = (byte == (uint8)'<') ? .Text : .Binary;
			break;
		}

		stream.Seek(start, .Begin);
		return encoding;
	}

	public static void SerializeTransform(ISerializer ar, ref Transform transform)
	{
		SerializeValue(ar, "position", ref transform.Position);
		SerializeValue(ar, "rotation", ref transform.Rotation);
		SerializeValue(ar, "scale", ref transform.Scale);
	}

	/// A pre order subtree walk: parents before children, siblings in list order.
	public static void CollectSubtree(Scene scene, EntityHandle root, List<EntityHandle> outEntities)
	{
		let stack = scope List<EntityHandle>();
		stack.Add(root);

		while (!stack.IsEmpty)
		{
			let entity = stack.PopBack();
			outEntities.Add(entity);

			// Pushed REVERSED so they pop in list order.
			let children = scope List<EntityHandle>();
			var child = scene.GetFirstChild(entity);
			while (child.IsAssigned)
			{
				children.Add(child);
				child = scene.GetNextSibling(child);
			}
			for (int i = children.Count - 1; i >= 0; i--)
				stack.Add(children[i]);
		}
	}

	/// One component's bytes, always through the BINARY backend.
	///
	/// A baseline capture and a save time diff both compare bytes, so both have to be
	/// produced the same way whatever the surrounding stream is encoded as.
	public static void ComponentToBlob(ComponentManagerBase manager, EntityHandle owner,
		List<uint8> outBlob)
	{
		let buffer = scope MemoryStream();
		{
			let ar = scope BinarySerializer(buffer, .Write);
			manager.WriteComponent(ar, owner);
		}
		outBlob.Clear();
		outBlob.AddRange(buffer.Bytes);
	}

	public static void ComponentFromBlob(ComponentManagerBase manager, EntityHandle owner,
		Span<uint8> blob)
	{
		let buffer = scope MemoryStream();
		buffer.Write(blob);
		buffer.Seek(0, .Begin);
		let ar = scope BinarySerializer(buffer, .Read);
		manager.ReadComponent(ar, owner);
	}

	public static bool BlobsEqual(Span<uint8> a, Span<uint8> b)
	{
		if (a.Length != b.Length)
			return false;
		for (int i < a.Length)
		{
			if (a[i] != b[i])
				return false;
		}
		return true;
	}
}
