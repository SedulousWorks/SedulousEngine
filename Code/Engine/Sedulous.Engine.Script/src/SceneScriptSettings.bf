using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Resource;
using Sedulous.Script.Resource;

namespace Sedulous.Engine.Script;

/// The scene's own script: one `Level` class per scene, an enable flag, and the property
/// values the author changed from the class's defaults. Serialized with the scene through
/// the system settings seam.
// The inspector writes a field through RUNTIME reflection, so every field needs its
// data emitted; an attribute on a field forces that, a bare field has nothing to.
[Reflect(.Type | .NonStaticFields)]
[Scriptable]
class SceneScriptSettings : ISerializable
{
	/// The Level class; nil is none.
	public Ref<ScriptClass> Script = .(Guid());
	[Scriptable]
	public bool Enabled = true;
	[Hidden]
	public List<ScriptPropertyOverride> Overrides = new .() ~ DeleteContainerAndItems!(_);

	public ScriptPropertyOverride FindOverride(uint64 hash)
	{
		for (let entry in Overrides)
		{
			if (entry.Hash == hash)
				return entry;
		}
		return null;
	}

	public void SetOverride(uint64 hash, ScriptPropertyValue value)
	{
		var existing = FindOverride(hash);
		if (existing == null)
		{
			existing = new ScriptPropertyOverride();
			existing.Hash = hash;
			Overrides.Add(existing);
		}
		if (existing.Value.Text != null)
			delete existing.Value.Text;
		existing.Value = value;
	}

	public void RemoveOverride(uint64 hash)
	{
		for (int i = 0; i < Overrides.Count; i++)
		{
			if (Overrides[i].Hash == hash)
			{
				delete Overrides[i];
				Overrides.RemoveAt(i);
				return;
			}
		}
	}

	public void Serialize(ISerializer ar)
	{
		SerializeValue(ar, "script", ref Script.Id);
		SerializeValue(ar, "enabled", ref Enabled);
		ar.Key("overrides");
		SerializeList(ar, Overrides);
	}
}
