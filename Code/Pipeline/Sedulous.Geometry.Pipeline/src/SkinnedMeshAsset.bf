using Sedulous.Core.Serialization;
using Sedulous.Geometry;
using Sedulous.Pipeline.Core;

namespace Sedulous.Geometry.Pipeline;

/// An authored skinned mesh. Sidecar only, exactly as the static one is.
[Serializable]
class SkinnedMeshAsset : Asset
{
	[NotSerialized]
	public SkinnedMeshSource Source = new .() ~ delete _;
}
