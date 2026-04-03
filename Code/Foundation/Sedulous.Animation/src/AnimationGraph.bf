namespace Sedulous.Animation;

using System;
using System.Collections;

/// Definition of an animation graph: parameters + layers with states and transitions.
/// This is a shared configuration object — multiple AnimationGraphPlayers can reference
/// the same graph. The graph does not own animation clips; those are owned by the resource system.
class AnimationGraph
{
	/// Parameters that drive transitions and blend trees.
	public List<AnimationGraphParameter> Parameters = new .() ~ DeleteContainerAndItems!(_);

	/// Layers in evaluation order (layer 0 = base).
	public List<AnimationLayer> Layers = new .() ~ DeleteContainerAndItems!(_);

	/// Adds a parameter and returns its index.
	public int32 AddParameter(StringView name, AnimationParameterType type)
	{
		let idx = (int32)Parameters.Count;
		Parameters.Add(new .(name, type));
		return idx;
	}

	/// Finds a parameter by name, returns its index or -1.
	public int32 FindParameter(StringView name)
	{
		for (int i = 0; i < Parameters.Count; i++)
		{
			if (StringView.Compare(Parameters[i].Name, name, false) == 0)
				return (int32)i;
		}
		return -1;
	}

	/// Gets a parameter by index, or null if out of range.
	public AnimationGraphParameter GetParameter(int32 index)
	{
		if (index >= 0 && index < Parameters.Count)
			return Parameters[index];
		return null;
	}

	/// Adds a layer and returns its index.
	public int32 AddLayer(AnimationLayer layer)
	{
		let idx = (int32)Layers.Count;
		Layers.Add(layer);
		return idx;
	}
}
