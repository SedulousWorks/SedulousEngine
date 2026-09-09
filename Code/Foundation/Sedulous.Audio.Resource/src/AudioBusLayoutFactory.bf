using System;
using Sedulous.Content;
using Sedulous.Resource;

namespace Sedulous.Audio.Resource;

/// Builds a cooked mixer layout into the product an engine applies.
///
/// PURELY CPU: a layout is data, with nothing to upload.
class AudioBusLayoutFactory : IResourceFactory
{
	public uint64 ProductTypeId => ResourceManager.ProductTypeIdOf<AudioBusLayoutResource>();

	public bool SupportsAsync => true;

	public Object Create(ResourceManager manager, Instance instance) => BuildFrom(instance);

	public Object DecodeStage(Instance instance) => BuildFrom(instance);

	public Object FinalizeStage(ResourceManager manager, Object decoded) => decoded;

	private Object BuildFrom(Instance instance)
	{
		let stored = instance.ReadObject();
		if (stored == null)
			return null;

		let source = stored as AudioBusLayoutSource;
		if (source == null)
		{
			delete stored;
			return null;
		}
		defer delete source;

		let resource = new AudioBusLayoutResource();
		source.FillLayout(resource.Layout);
		return resource;
	}
}
