using System;
using Sedulous.Animation.Resource;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;

namespace Sedulous.Animation.Pipeline;

/// The authored clip, whose source is the cooked wire, baked for root motion when the clip asks.
///
/// Appended (root-motion.md P0), for the root motion cook: the skeleton the clip's bone indices
/// address (a named root resolves against it), and the armature's rest transform (its own
/// channels, the clip's model tracks, are turned into model space by its inverse). The importer
/// sets both.
[Serializable]
class AnimationClipAsset : Asset
{
	public AnimationClipSource Source = new .() ~ delete _;
	[Appended]
	public Guid Skeleton = .();
	[Appended]
	public Float3 RestPosition = .(0, 0, 0);
	[Appended]
	public Quaternion RestRotation = .Identity;
	[Appended]
	public Float3 RestScale = .(1, 1, 1);

	public Transform ModelRest => .(RestPosition, RestRotation, RestScale);
}
