using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Animation.Pipeline;

/// Where one layer's nodes sit on the editor's graph canvas.
///
/// EDITOR ONLY, and on the asset rather than the source, so none of it reaches the runtime
/// wire. The state positions run parallel to the layer's states and the page keeps them in step
/// as states come and go.
///
/// One record per layer rather than two parallel arrays: nothing depends on its stored
/// shape, and a pair of lists that have to stay the same length is a bug waiting to be
/// written.
[Serializable]
class AnimationGraphLayerLayout
{
	public List<Float2> StatePositions = new .() ~ delete _;

	/// The layer's "any state" pseudo node.
	public Float2 AnyStatePosition = .(0.0f, 0.0f);
}
