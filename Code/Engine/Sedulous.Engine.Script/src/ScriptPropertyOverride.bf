using System;
using Sedulous.Core.Serialization;
using Sedulous.Script.Resource;

namespace Sedulous.Engine.Script;

/// One authored value that differs from the class's harvested default, keyed by the
/// property's name hash so a rename is detectable rather than silently orphaning it.
class ScriptPropertyOverride : ISerializable
{
	public uint64 Hash = 0;
	public ScriptPropertyValue Value = .() ~ { if (_.Text != null) delete _.Text; };

	public void Serialize(ISerializer ar)
	{
		SerializeValue(ar, "nameHash", ref Hash);
		ar.Key("value");
		Value.Serialize(ar);
	}
}
