using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Resource;

namespace Sedulous.Vegetation.Resource;

/// Builds a cooked mask, the metadata plus its density sidecar, into a runtime mask.
///
/// PURELY CPU, so the whole build runs on a worker.
class VegetationMaskFactory : IResourceFactory
{
	public uint64 ProductTypeId => ResourceManager.ProductTypeIdOf<VegetationMask>();

	public bool SupportsAsync => true;

	public Object Create(ResourceManager manager, Instance instance) => BuildFrom(instance);

	public Object DecodeStage(Instance instance) => BuildFrom(instance);

	public Object FinalizeStage(ResourceManager manager, Object decoded) => decoded;

	private Object BuildFrom(Instance instance)
	{
		let stored = instance.ReadObject();
		if (stored == null)
			return null;

		let source = stored as VegetationMaskSource;
		if (source == null)
		{
			// Something else was stored under this type name.
			delete stored;
			return null;
		}
		defer delete source;

		let densities = scope List<uint8>();
		ReadBlob(instance, VegetationMaskSource.DensityStream, densities);
		return source.Build(.(densities.Ptr, densities.Count));
	}

	/// A short read leaves the blob EMPTY, which the build then refuses: half a raster grows
	/// whatever the truncation happened to leave.
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
