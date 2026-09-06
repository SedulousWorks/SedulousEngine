using System;
using Sedulous.Content;
using Sedulous.Core.Serialization;
using Sedulous.Geometry;
using Sedulous.Resource;

namespace Sedulous.Geometry;

/// Builds a cooked mesh source into a runtime StaticMesh.
///
/// The product is PURE CPU: vertex and index arrays and a submesh table, with the renderer
/// uploading to GPU buffers separately. So the whole build, blob copy included, happens in
/// the decode stage on a worker, and finalize just hands the result over. That is the
/// cheapest possible shape for the two stage path, and it is only safe because nothing
/// here touches the manager: the content database opens its own stream per read, and the
/// types were registered on the main thread at startup.
class StaticMeshFactory : IResourceFactory
{
	public uint64 ProductTypeId => ResourceManager.ProductTypeIdOf<StaticMesh>();

	public bool SupportsAsync => true;

	public Object Create(ResourceManager manager, Instance instance) => BuildMesh(instance);

	public Object DecodeStage(Instance instance) => BuildMesh(instance);

	public Object FinalizeStage(ResourceManager manager, Object decoded) => decoded;

	/// A SkinnedMeshSource IS a StaticMeshSource, so a reference typed as StaticMesh can
	/// legitimately name a skinned asset. Build the REAL SkinnedMesh in that case: filling
	/// only the static half would silently drop the skin stream, and the mesh could then
	/// never animate while looking perfectly fine.
	private Object BuildMesh(Instance instance)
	{
		let source = instance.ReadObject();
		if (source == null)
			return null;
		defer delete source;

		if (let skinned = source as SkinnedMeshSource)
		{
			if (!skinned.HasParallelSkinningStream)
				return null;

			let mesh = new SkinnedMesh();
			skinned.FillSkinned(mesh);
			return mesh;
		}

		if (let staticSource = source as StaticMeshSource)
		{
			let mesh = new StaticMesh();
			staticSource.FillStatic(mesh);
			return mesh;
		}

		return null;
	}
}
