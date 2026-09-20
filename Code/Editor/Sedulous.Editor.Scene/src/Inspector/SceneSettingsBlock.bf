using System;
using System.Collections;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Scene;

namespace Sedulous.Editor.Scene;

/// A settings block as bytes: the versioned payload the scene file stores it as, so a body
/// can gate on the version in both directions.
static class SceneSettingsBlock
{
	public static void Capture(SceneSystem system, List<uint8> outBlob)
	{
		let buffer = scope MemoryStream();
		{
			let ar = scope BinarySerializer(buffer, .Write);
			Serialize(system, ar);
		}
		outBlob.Clear();
		outBlob.AddRange(buffer.Bytes);
	}

	public static bool Apply(SceneSystem system, List<uint8> blob)
	{
		let buffer = scope MemoryStream();
		if (buffer.Write(blob) != blob.Count)
			return false;
		buffer.Seek(0, .Begin);
		let ar = scope BinarySerializer(buffer, .Read);
		Serialize(system, ar);
		return ar.IsPayloadOk;
	}

	private static void Serialize(SceneSystem system, ISerializer ar)
	{
		let id = scope String(system.SettingsId);
		BeginVersionedPayload(ar, TypeIdOf(id), system.SettingsDataVersion);
		system.SerializeSettings(ar);
		EndVersionedPayload(ar);
	}
}
