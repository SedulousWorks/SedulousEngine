using System;
using Sedulous.Animation;
using Sedulous.Content;
using Sedulous.Resource;

namespace Sedulous.Animation.Resource;

/// Builds a cooked skeleton into the runtime hierarchy a player poses.
///
/// PURELY CPU: bones and matrices, with nothing to upload.
class SkeletonFactory : IResourceFactory
{
	public uint64 ProductTypeId => ResourceManager.ProductTypeIdOf<Skeleton>();

	public bool SupportsAsync => true;

	public Object Create(ResourceManager manager, Instance instance) => BuildFrom(instance);

	public Object DecodeStage(Instance instance) => BuildFrom(instance);

	public Object FinalizeStage(ResourceManager manager, Object decoded) => decoded;

	private Object BuildFrom(Instance instance)
	{
		let stored = instance.ReadObject();
		if (stored == null)
			return null;

		let source = stored as SkeletonSource;
		if (source == null)
		{
			// Something else was stored under this type name, so this is not a skeleton
			// rather than a skeleton that failed to read.
			delete stored;
			return null;
		}
		defer delete source;

		let skeleton = new Skeleton();
		source.FillSkeleton(skeleton);
		return skeleton;
	}
}
