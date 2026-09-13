using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;

namespace Sedulous.Heightfield.Pipeline;

/// A square heightfield over an XZ footprint, its samples mapped onto a world height range.
///
/// A file name means a sixteen bit heightmap resampled onto the grid. WITHOUT one the grid is
/// authored in place: the heights sidecar is then the truth, which is what a sculpt save
/// writes.
[Serializable]
class HeightfieldAsset : Asset
{
	/// The grid's side, which has to be a multiple of sixty four plus one.
	public int32 Size = 257;
	/// The XZ footprint, in metres.
	public Float2 WorldSize = .(256.0f, 256.0f);
	/// The world height at sample nought.
	public float MinY = 0.0f;
	/// The world height at the largest sample.
	public float MaxY = 64.0f;
}
