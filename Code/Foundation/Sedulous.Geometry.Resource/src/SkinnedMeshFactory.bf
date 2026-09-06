using System;
using Sedulous.Content;
using Sedulous.Core.Serialization;
using Sedulous.Geometry;
using Sedulous.Resource;

namespace Sedulous.Geometry;

/// Builds a cooked skinned mesh source into a runtime SkinnedMesh. Pure CPU, for the same
/// reason as StaticMeshFactory, so the decode stage does the whole build.
class SkinnedMeshFactory : IResourceFactory
{
	public uint64 ProductTypeId => ResourceManager.ProductTypeIdOf<SkinnedMesh>();

	public bool SupportsAsync => true;

	public Object Create(ResourceManager manager, Instance instance) => BuildMesh(instance);

	public Object DecodeStage(Instance instance) => BuildMesh(instance);

	public Object FinalizeStage(ResourceManager manager, Object decoded) => decoded;

	private Object BuildMesh(Instance instance)
	{
		let source = instance.ReadObject();
		if (source == null)
			return null;
		defer delete source;

		let skinned = source as SkinnedMeshSource;
		if (skinned == null)
			return null;

		// A stream that is not parallel to the vertices means the payload was read at the
		// wrong offset. Fail the build rather than animate garbage.
		if (!skinned.HasParallelSkinningStream)
			return null;

		let mesh = new SkinnedMesh();
		skinned.FillSkinned(mesh);
		return mesh;
	}
}
