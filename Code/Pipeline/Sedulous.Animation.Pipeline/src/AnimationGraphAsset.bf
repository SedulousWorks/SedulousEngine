using System.Collections;
using Sedulous.Animation.Resource;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;

namespace Sedulous.Animation.Pipeline;

/// The authored graph: a state machine with its blend trees and clip references.
///
/// The canvas layout rides on the ASSET, not the source, so the builder cooks the source alone
/// and no editor state reaches the runtime.
[Serializable]
class AnimationGraphAsset : Asset
{
	public AnimationGraphSource Source = new .() ~ delete _;

	/// One entry per layer of the source, in the same order.
	public List<AnimationGraphLayerLayout> LayerLayouts = new .() ~ DeleteContainerAndItems!(_);
}
