using Sedulous.Geometry;

namespace Sedulous.Geometry.Pipeline;

/// Capturing a mesh built in code into an asset.
///
/// NOT an IFileImporter: a mesh reaches the pipeline through the model importer or through a
/// primitive built in the editor, never as a file dropped on its own.
static class MeshImporter
{
	public static void Import(StaticMesh mesh, StaticMeshAsset outAsset)
		=> StaticMeshSource.FromMesh(mesh, outAsset.Source);

	public static void Import(SkinnedMesh mesh, SkinnedMeshAsset outAsset)
		=> SkinnedMeshSource.FromMesh(mesh, outAsset.Source);
}
