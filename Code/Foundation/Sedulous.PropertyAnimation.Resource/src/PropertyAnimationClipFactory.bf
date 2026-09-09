using System;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.PropertyAnimation;
using Sedulous.Resource;

namespace Sedulous.PropertyAnimation.Resource;

/// Builds a cooked clip into an evaluate ready runtime one.
///
/// PURELY CPU, so the whole build runs on a worker: a property clip is data and reflection
/// alone, with nothing to upload.
class PropertyAnimationClipFactory : IResourceFactory
{
	public uint64 ProductTypeId => ResourceManager.ProductTypeIdOf<PropertyAnimationClip>();

	public bool SupportsAsync => true;

	public Object Create(ResourceManager manager, Instance instance) => BuildFrom(instance);

	public Object DecodeStage(Instance instance) => BuildFrom(instance);

	/// Nothing is left for the main thread: the decode already produced the finished clip.
	public Object FinalizeStage(ResourceManager manager, Object decoded) => decoded;

	private Object BuildFrom(Instance instance)
	{
		let stored = instance.ReadObject();
		if (stored == null)
			return null;

		let source = stored as PropertyAnimationClipSource;
		if (source == null)
		{
			// Something else was stored under this type name, so this is not a clip rather
			// than a clip that failed to read.
			delete stored;
			return null;
		}
		defer delete source;

		let clip = new PropertyAnimationClip();
		source.FillClip(clip);
		return clip;
	}
}
