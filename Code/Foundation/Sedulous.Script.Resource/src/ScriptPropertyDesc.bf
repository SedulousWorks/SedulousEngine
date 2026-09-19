using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Script.Resource;

/// One authored property the cook harvested from a script class: its name, kind, default,
/// and what the inspector shows for it.
class ScriptPropertyDesc : ISerializable
{
	public String Name = new .() ~ delete _;
	/// A stable hash of the name: what an override is keyed by, so a rename is detectable
	/// rather than silently orphaning the value.
	public uint64 Hash = 0;
	public ScriptPropertyType Type = .None;
	/// Asset only: the product type name, "AudioClip".
	public String AssetType = new .() ~ delete _;
	public ScriptPropertyValue Default = .() ~ { if (_.Text != null) delete _.Text; };
	/// The inspector tooltip.
	public String Description = new .() ~ delete _;

	public void Serialize(ISerializer ar)
	{
		Sedulous.Core.Serialization.Serialize(ar, "name", Name);
		uint8 type = (uint8)Type;
		SerializeValue(ar, "type", ref type);
		Type = (ScriptPropertyType)type;
		Sedulous.Core.Serialization.Serialize(ar, "assetType", AssetType);
		ar.Key("default");
		Default.Serialize(ar);
		Sedulous.Core.Serialization.Serialize(ar, "description", Description);
		if (ar.Mode == .Read)
			Hash = ScriptPropertyNames.HashOf(Name);
	}
}
