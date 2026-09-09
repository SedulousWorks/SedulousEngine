using System;
using System.Collections;

namespace Sedulous.Animation;

/// The SHARED definition: the parameters and the layers. Several players run one graph, each
/// with its own parameter values.
class AnimationGraph
{
	public List<AnimationGraphParameter> Parameters = new .() ~ DeleteContainerAndItems!(_);
	public List<AnimationLayer> Layers = new .() ~ DeleteContainerAndItems!(_);

	/// Answers the index, which is what a condition and a blend tree point at: a name is
	/// resolved ONCE when the graph is built rather than on every comparison.
	public int32 AddParameter(StringView name, AnimationParameterType type)
	{
		let index = (int32)Parameters.Count;
		Parameters.Add(new AnimationGraphParameter(name, type));
		return index;
	}

	public int32 FindParameter(StringView name)
	{
		for (int32 i = 0; i < Parameters.Count; i++)
		{
			if (Parameters[i].Name == name)
				return i;
		}
		return -1;
	}

	public AnimationGraphParameter GetParameter(int32 index) =>
		((index >= 0) && (index < Parameters.Count)) ? Parameters[index] : null;

	/// TAKES OWNERSHIP.
	public int32 AddLayer(AnimationLayer layer)
	{
		let index = (int32)Layers.Count;
		Layers.Add(layer);
		return index;
	}
}
