using System;
using System.Collections;
using Sedulous.Core.Serialization;
using Sedulous.Script.Resource;

namespace Sedulous.Script.Resource.Tests;

/// A cooked script record stamped with an older data version of BehaviorClassSource: what a cook
/// wrote before the current layout, which this build has to refuse rather than misread.
class StaleScriptRecord : ISerializable
{
	public uint32 Version;
	public String Language = new .() ~ delete _;
	public String ClassName = new .() ~ delete _;
	public String SourceName = new .() ~ delete _;
	public String Source = new .() ~ delete _;
	public List<BehaviorProperty> Properties = new .() ~ DeleteContainerAndItems!(_);

	public this(uint32 version)
	{
		Version = version;
	}

	public void Serialize(ISerializer ar)
	{
		Sedulous.Core.Serialization.BeginVersionedPayload(ar, BehaviorClassSource.TypeId, Version);
		ar.BeginObject();
		Sedulous.Core.Serialization.Serialize(ar, "language", Language);
		Sedulous.Core.Serialization.Serialize(ar, "className", ClassName);
		Sedulous.Core.Serialization.Serialize(ar, "sourceName", SourceName);
		Sedulous.Core.Serialization.Serialize(ar, "source", Source);
		ar.Key("properties");
		Sedulous.Core.Serialization.SerializeList(ar, Properties);
		ar.EndObject();
		Sedulous.Core.Serialization.EndVersionedPayload(ar);
	}
}
