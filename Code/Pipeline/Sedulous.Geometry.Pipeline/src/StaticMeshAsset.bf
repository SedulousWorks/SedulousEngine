using Sedulous.Core.Serialization;
using Sedulous.Geometry;
using Sedulous.Pipeline.Core;

namespace Sedulous.Geometry.Pipeline;

/// An authored static mesh.
///
/// The geometry ALWAYS travels in a sidecar stream, never in the envelope, which holds only
/// the file name. A reader calls MeshAssetStorage.EnsureSourceLoaded after reading the
/// envelope.
///
/// The incident behind that: an imported scene produced a 170 MB text envelope, vertex arrays
/// and all, and every project open parsed the whole thing to read three header fields. Text is
/// for AUTHORED data; machine generated bulk follows the texture pixels into a binary stream.
[Serializable]
class StaticMeshAsset : Asset
{
	[NotSerialized]
	public StaticMeshSource Source = new .() ~ delete _;
}
