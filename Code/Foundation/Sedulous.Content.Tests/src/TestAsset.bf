using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Content.Tests;

/// A stored object. Nothing here describes its data: the fields are the description.
[Serializable]
class TestAsset
{
	public int32 Width;
	public int32 Height;
	public float Scale;
	public Float3 Tint;
}
