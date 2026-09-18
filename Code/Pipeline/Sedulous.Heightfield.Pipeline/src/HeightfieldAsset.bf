using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;

namespace Sedulous.Heightfield.Pipeline;

/// A square heightfield over an XZ footprint, its samples mapped onto a world height range.
///
/// A file name means a sixteen bit heightmap resampled onto the grid. WITHOUT one the grid is
/// authored in place: the heights sidecar is then the truth, which is what a sculpt save
/// writes.
[Category("Terrain")]
[DisplayName("Heightfield")]
[Serializable]
class HeightfieldAsset : Asset
{
	/// The grid's side, which has to be a multiple of sixty four plus one.
	[DisplayName("Grid Size (64k+1)")]
	public int32 Size = 257;
	/// The XZ footprint, in metres.
	[DisplayName("World Size (XZ)")]
	public Float2 WorldSize = .(256.0f, 256.0f);
	/// The world height at sample nought.
	[DisplayName("Min Height")]
	public float MinY = 0.0f;
	/// The world height at the largest sample.
	[DisplayName("Max Height")]
	public float MaxY = 64.0f;
}
