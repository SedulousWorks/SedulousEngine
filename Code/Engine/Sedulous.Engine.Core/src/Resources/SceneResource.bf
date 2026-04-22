namespace Sedulous.Engine.Core.Resources;

using System;
using Sedulous.Resources;
using Sedulous.Serialization;

/// A loadable scene asset.
/// Wraps the serialized scene data as a Resource for the async resource system.
class SceneResource : Resource
{
	private uint8[] mData ~ delete _;

	public override ResourceType ResourceType => .("Sedulous.Engine.Core.Resources.SceneResource");

	/// Gets the raw serialized scene data.
	public Span<uint8> Data => (mData != null) ? Span<uint8>(mData) : default;

	public override SerializationResult Serialize(Serializer serializer)
	{
		// Scene resources are loaded from files, not inline-serialized.
		// The resource manager handles loading the raw bytes.
		return .Ok;
	}

	public override int32 SerializationVersion => 1;

	/// Sets the scene data (called by resource loader).
	public void SetData(Span<uint8> data)
	{
		delete mData;
		mData = new uint8[data.Length];
		data.CopyTo(mData);
	}
}
