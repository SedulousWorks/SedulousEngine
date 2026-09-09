using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Resource;

namespace Sedulous.Terrain.Resource;

/// Builds cooked splat weights, the metadata plus its two rasters, into a runtime raster.
///
/// PURELY CPU, so the whole build runs on a worker.
class SplatWeightsFactory : IResourceFactory
{
	public uint64 ProductTypeId => ResourceManager.ProductTypeIdOf<SplatWeights>();

	public bool SupportsAsync => true;

	public Object Create(ResourceManager manager, Instance instance) => BuildFrom(instance);

	public Object DecodeStage(Instance instance) => BuildFrom(instance);

	public Object FinalizeStage(ResourceManager manager, Object decoded) => decoded;

	private Object BuildFrom(Instance instance)
	{
		let stored = instance.ReadObject();
		if (stored == null)
			return null;

		let source = stored as SplatWeightsSource;
		if (source == null)
		{
			// Something else was stored under this type name.
			delete stored;
			return null;
		}
		defer delete source;

		let weights = scope List<uint8>();
		let indices = scope List<uint8>();
		ReadBlob(instance, SplatWeightsSource.WeightStream, weights);
		ReadBlob(instance, SplatWeightsSource.IndexStream, indices);

		return source.Build(.(indices.Ptr, indices.Count), .(weights.Ptr, weights.Count));
	}

	/// A short read leaves the blob EMPTY, which the build then refuses: half a raster paints
	/// the terrain with whatever the truncation happened to leave.
	private static void ReadBlob(Instance instance, StringView stream, List<uint8> outBlob)
	{
		let handle = instance.ReadData(stream);
		if (handle == null)
			return;
		defer delete handle;

		let size = handle.Size();
		if (size <= 0)
			return;

		outBlob.Resize((int)size);
		if (handle.Read(.(outBlob.Ptr, (int)size)) != (int)size)
			outBlob.Clear();
	}
}
