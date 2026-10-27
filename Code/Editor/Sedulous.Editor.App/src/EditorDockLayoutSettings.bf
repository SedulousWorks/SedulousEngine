using System;
using System.Collections;
using Sedulous.Core.Serialization;
using Sedulous.GUI;

namespace Sedulous.Editor.App;

/// The dock's layout section of the per-project editor settings: the GUI dock's
/// DockLayoutDocument, captured from its DockController and applied through Adopt; panels by
/// their ids, a panel the layout names that is not registered keeping its place until it is.
/// Hand-written for its legacy reader: version 1 held Sedulous.UI's dock tree, which is read
/// once and set aside (it would not map onto the GUI's dock reliably), so the dock starts from
/// its default, the open pages still reopening.
class EditorDockLayoutSettings : ISerializable
{
	/// The identity version 1 was stored under, kept so its records are known as this type.
	public const uint64 TypeId = 0x2D4D3B1B4A3D2B7EUL;
	public const uint32 DataVersion = 2;
	/// Version 1 still reads, to be set aside: a legacy reader one version back, removed once
	/// projects have saved past it.
	public const uint32 MinReadDataVersion = 1;

	/// Whether a layout was captured; false, the caller keeps its default layout.
	public bool Captured = false;
	public DockLayoutDocument Document = new .() ~ delete _;

	public void Serialize(ISerializer ar)
	{
		BeginVersionedPayload(ar, TypeId, DataVersion, MinReadDataVersion);
		if (!ar.IsPayloadOk)
		{
			EndVersionedPayload(ar);
			return;
		}
		ar.BeginObject();
		if ((ar.Mode == .Read) && (ar.Version == 1))
		{
			var hasRoot = false;
			ar.Key("hasRoot");
			Sedulous.Core.Serialization.Serialize(ar, ref hasRoot);
			if (hasRoot)
			{
				ar.Key("root");
				SkipLegacyLayoutNode(ar);
			}
			Captured = false;
		}
		else
		{
			ar.Key("captured");
			Sedulous.Core.Serialization.Serialize(ar, ref Captured);
			if (Captured)
			{
				ar.Key("layout");
				ar.BeginObject();
				Document.Serialize(ar);
				ar.EndObject();
			}
		}
		ar.EndObject();
		EndVersionedPayload(ar);
	}

	/// One node of version 1's tree, read only to be passed: a tab group (its panels) or a split
	/// (its two children), each child behind a presence flag. Read whole so a positional backend
	/// lands where the next value starts.
	private static void SkipLegacyLayoutNode(ISerializer ar)
	{
		ar.BeginObject();
		uint8 type = 0;
		uint8 direction = 0;
		float ratio = 0.0f;
		int32 activeTab = 0;
		let panels = scope List<String>();
		defer { ClearAndDeleteItems!(panels); }
		ar.Key("type");
		Sedulous.Core.Serialization.Serialize(ar, ref type);
		ar.Key("direction");
		Sedulous.Core.Serialization.Serialize(ar, ref direction);
		ar.Key("ratio");
		Sedulous.Core.Serialization.Serialize(ar, ref ratio);
		ar.Key("activeTab");
		Sedulous.Core.Serialization.Serialize(ar, ref activeTab);
		ar.Key("panels");
		SerializeList(ar, panels);
		var hasFirst = false;
		var hasSecond = false;
		ar.Key("hasFirst");
		Sedulous.Core.Serialization.Serialize(ar, ref hasFirst);
		ar.Key("hasSecond");
		Sedulous.Core.Serialization.Serialize(ar, ref hasSecond);
		if (hasFirst)
		{
			ar.Key("first");
			SkipLegacyLayoutNode(ar);
		}
		if (hasSecond)
		{
			ar.Key("second");
			SkipLegacyLayoutNode(ar);
		}
		ar.EndObject();
	}
}
