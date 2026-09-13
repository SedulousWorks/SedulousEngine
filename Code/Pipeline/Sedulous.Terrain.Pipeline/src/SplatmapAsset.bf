using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;

namespace Sedulous.Terrain.Pipeline;

/// The painted layer weights for a terrain.
///
/// TWO modes, told apart by the file name. Empty means the asset is EDITABLE: its two sidecars
/// are the truth, which is what painting saves. Set means it was IMPORTED from an image, and
/// re-importing deliberately resets whatever was painted.
[Serializable]
class SplatmapAsset : Asset
{
	/// The raster's resolution, which is an authoring choice independent of the heightfield's.
	public int32 Width = 1024;
	public int32 Height = 1024;
}
