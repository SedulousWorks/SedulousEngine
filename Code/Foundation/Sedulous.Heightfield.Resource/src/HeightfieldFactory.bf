using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Heightfield;
using Sedulous.Resource;

namespace Sedulous.Heightfield.Resource;

/// Builds a cooked heightfield, its metadata plus its sample stream, into a runtime grid.
///
/// PURELY CPU: the terrain renderer owns the height texture and caches it per resource, so
/// nothing here touches a device and the whole build runs on a worker.
class HeightfieldFactory : IResourceFactory
{
	public uint64 ProductTypeId => ResourceManager.ProductTypeIdOf<Heightfield>();

	public bool SupportsAsync => true;

	public Object Create(ResourceManager manager, Instance instance) => BuildFrom(instance);

	public Object DecodeStage(Instance instance) => BuildFrom(instance);

	/// Nothing is left to do on the main thread, since the decode already produced the
	/// finished grid.
	public Object FinalizeStage(ResourceManager manager, Object decoded) => decoded;

	private Object BuildFrom(Instance instance)
	{
		let stored = instance.ReadObject();
		if (stored == null)
			return null;

		let source = stored as HeightfieldSource;
		if (source == null)
		{
			// Something else was stored under this type name, so this is not a heightfield
			// rather than a heightfield that failed to read.
			delete stored;
			return null;
		}
		defer delete source;

		let heights = scope List<uint8>();
		let holes = scope List<uint8>();
		ReadStream(instance, HeightfieldSource.HeightStream, heights);
		ReadStream(instance, HeightfieldSource.HoleStream, holes);
		return source.Build(.(heights.Ptr, heights.Count), .(holes.Ptr, holes.Count));
	}

	/// One sidecar stream. An absent or short stream leaves the blob EMPTY, which the
	/// source's build then refuses: a partial grid is worse than no grid, because it looks
	/// like terrain.
	private static void ReadStream(Instance instance, StringView name, List<uint8> outBlob)
	{
		let stream = instance.ReadData(name);
		if (stream == null)
			return;
		defer delete stream;

		let size = stream.Size();
		if (size <= 0)
			return;

		outBlob.Resize((int)size);
		if (stream.Read(.(outBlob.Ptr, (int)size)) != (int)size)
			outBlob.Clear();
	}
}
