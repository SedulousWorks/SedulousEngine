using Sedulous.Animation.Resource;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;

namespace Sedulous.Animation.Pipeline;

/// The authored skeleton, whose source IS the cooked wire. The file name is a note about which
/// model it came from rather than something the build reads.
[Serializable]
class SkeletonAsset : Asset
{
	public SkeletonSource Source = new .() ~ delete _;
}
