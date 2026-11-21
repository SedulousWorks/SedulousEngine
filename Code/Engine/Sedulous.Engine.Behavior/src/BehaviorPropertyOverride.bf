using System;
using System.Collections;
using Sedulous.Core.Serialization;
using Sedulous.Script.Resource;

namespace Sedulous.Engine.Behavior;

/// One authored value that differs from the class's harvested default, keyed by the
/// property's name hash so a rename is detectable rather than silently orphaning it.
class BehaviorPropertyOverride : ISerializable
{
	public uint64 Hash = 0;
	public BehaviorPropertyValue Value = .() ~ { if (_.Text != null) delete _.Text; };

	public void Serialize(ISerializer ar)
	{
		SerializeValue(ar, "nameHash", ref Hash);
		ar.Key("value");
		Value.Serialize(ar);
	}

	/// The assets `overrides` name, appended to `outIds` once each: a nil one names nothing,
	/// and an entity reference is a guid of the scene's, not an asset.
	public static void CollectAssetIds(List<BehaviorPropertyOverride> overrides, List<Guid> outIds)
	{
		for (let entry in overrides)
		{
			if ((entry.Value.Kind == .Asset) && entry.Value.Id.IsSet && !outIds.Contains(entry.Value.Id))
				outIds.Add(entry.Value.Id);
		}
	}
}
