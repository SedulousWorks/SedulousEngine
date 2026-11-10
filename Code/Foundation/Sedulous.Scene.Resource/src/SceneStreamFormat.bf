using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;

namespace Sedulous.Scene.Resource;

/// The scene stream's shape: its header, and the small pieces every section is built from.
///
/// One layout, read from cMinReadVersion to cVersion and refused otherwise. Version 4 is
/// version 3's layout: what changed is that a version 3 stream may hold the records of the
/// scripts the engine no longer runs (cRetiredScriptId), which a reader drops rather than
/// keeps, so a scene saved again is written without them.
static class SceneStreamFormat
{
	/// A sentinel chosen so it cannot be mistaken for a length prefix.
	public const uint32 cMagic = 0xD5C35CEE;
	public const uint32 cVersion = 4;
	/// The oldest version still read.
	public const uint32 cMinReadVersion = 3;

	/// The wire id the scripts' records were stored under, both the Script component's and
	/// the scene's script settings block. A stream older than cVersion that carries one has
	/// it dropped as it reads, with a warning (cRetiredScriptWarning): no build has their code
	/// any more, and a record kept unread would be written back into every scene saved again.
	/// A stream at cVersion keeps a record of this id as it keeps any other it has no code for.
	public const String cRetiredScriptId = "script";

	/// What a reader logs, once per stream, for each kind of script record it drops: the
	/// `{}` is what was dropped (the component records, the settings block).
	public const String cRetiredScriptWarning = "{}: scripts no longer run in this engine; a game's code is native, so the scene's script {} were dropped (saving the scene writes it without them)";

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

	/// Reads and CHECKS the header, failing the payload when it is not this format, and
	/// answers the version the stream was written at. A stream that is not ours must stop
	/// here rather than be parsed as though it were: the next thing read would be a count,
	/// and a garbage count allocates.
	public static Result<uint32> ReadHeader(ISerializer ar)
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
		if ((version < cMinReadVersion) || (version > cVersion))
		{
			ar.FailPayload(.InvalidArgument);
			return .Err;
		}
		return .Ok(version);
	}

	/// Whether a record of `id` read from a stream at `version` is a retired script record,
	/// dropped rather than kept.
	public static bool IsRetiredRecord(uint32 version, StringView id) =>
		(version < cVersion) && (id == cRetiredScriptId);

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
