using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Scene;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// Replaces a whole settings block from its serialized form: the old bytes are captured on
/// the first Execute and undo reads them back through the same versioned payload.
class SetSceneSettingsBlockCommand : EditorCommand
{
	private SceneEditContext mCtx;
	private Type mSettingsType;
	private List<uint8> mNew ~ delete _;
	private List<uint8> mOld = new .() ~ delete _;

	/// CONSUMES `newBlob`.
	public this(SceneEditContext ctx, Type settingsType, List<uint8> newBlob)
	{
		mCtx = ctx;
		mSettingsType = settingsType;
		mNew = newBlob;
	}

	public override bool Execute()
	{
		let system = mCtx.FindSystemBySettingsType(mSettingsType);
		if (system == null)
			return false;
		if (mOld.IsEmpty)
			Capture(system, mOld);
		return Apply(system, mNew);
	}

	public override void Undo()
	{
		let system = mCtx.FindSystemBySettingsType(mSettingsType);
		if (system != null)
			Apply(system, mOld);
	}

	public override StringView TypeId => "set_scene_settings_block";

	/// The block as the scene file stores it: a versioned payload around the fields, so a
	/// body can gate on the version in both directions.
	public static void Capture(SceneSystem system, List<uint8> outBlob)
	{
		let buffer = scope MemoryStream();
		{
			let ar = scope BinarySerializer(buffer, .Write);
			SerializeSettings(system, ar);
		}
		outBlob.Clear();
		outBlob.AddRange(buffer.Bytes);
	}

	private static bool Apply(SceneSystem system, List<uint8> blob)
	{
		let buffer = scope MemoryStream();
		if (buffer.Write(blob) != blob.Count)
			return false;
		buffer.Seek(0, .Begin);
		let ar = scope BinarySerializer(buffer, .Read);
		SerializeSettings(system, ar);
		return ar.IsPayloadOk;
	}

	private static void SerializeSettings(SceneSystem system, ISerializer ar)
	{
		let id = scope String(system.SettingsId);
		BeginVersionedPayload(ar, TypeIdOf(id), system.SettingsDataVersion);
		system.SerializeSettings(ar);
		EndVersionedPayload(ar);
	}
}
