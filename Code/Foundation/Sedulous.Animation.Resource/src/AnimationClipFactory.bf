using System;
using Sedulous.Animation;
using Sedulous.Content;
using Sedulous.Resource;

namespace Sedulous.Animation.Resource;

/// Builds a cooked clip into the runtime one a player samples. PURELY CPU.
class AnimationClipFactory : IResourceFactory
{
	public uint64 ProductTypeId => ResourceManager.ProductTypeIdOf<AnimationClip>();

	public bool SupportsAsync => true;

	public Object Create(ResourceManager manager, Instance instance) => BuildFrom(instance);

	public Object DecodeStage(Instance instance) => BuildFrom(instance);

	public Object FinalizeStage(ResourceManager manager, Object decoded) => decoded;

	private Object BuildFrom(Instance instance)
	{
		let stored = instance.ReadObject();
		if (stored == null)
			return null;

		let source = stored as AnimationClipSource;
		if (source == null)
		{
			delete stored;
			return null;
		}
		defer delete source;

		let clip = new AnimationClip();
		source.FillClip(clip);
		return clip;
	}
}
