using Sedulous.Animation.Resource;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;

namespace Sedulous.Animation.Pipeline;

/// The authored clip, whose source IS the cooked wire.
[Serializable]
class AnimationClipAsset : Asset
{
	public AnimationClipSource Source = new .() ~ delete _;
}
