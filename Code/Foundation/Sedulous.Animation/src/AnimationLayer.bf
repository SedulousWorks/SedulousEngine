namespace Sedulous.Animation;

using System;
using System.Collections;

/// How a layer's output is combined with the layers below it.
enum LayerBlendMode
{
	/// Replaces the base pose per-bone, weighted by layer weight * bone mask.
	Override,
	/// Adds the layer's delta (from bind pose) on top of the base.
	Additive
}

/// A single animation layer containing states and transitions.
/// Layer 0 is the base layer; additional layers blend on top.
class AnimationLayer
{
	/// Display name of this layer.
	public String Name ~ delete _;

	/// States in this layer (owned).
	public List<AnimationGraphState> States = new .() ~ DeleteContainerAndItems!(_);

	/// Transitions between states (owned).
	public List<AnimationGraphTransition> Transitions = new .() ~ DeleteContainerAndItems!(_);

	/// Index of the default state (entered when the layer starts).
	public int32 DefaultStateIndex;

	/// Blend mode for combining with layers below.
	public LayerBlendMode BlendMode = .Override;

	/// Overall weight of this layer (0 = no effect, 1 = full).
	public float Weight = 1.0f;

	/// Optional bone mask for per-bone weighting. Null means all bones at full weight.
	public BoneMask Mask;

	/// Whether the layer owns the bone mask.
	public bool OwnsMask;

	public this(StringView name)
	{
		Name = new .(name);
	}

	public ~this()
	{
		if (OwnsMask && Mask != null)
			delete Mask;
	}

	/// Adds a state and returns its index.
	public int32 AddState(AnimationGraphState state)
	{
		let idx = (int32)States.Count;
		States.Add(state);
		return idx;
	}

	/// Adds a transition between states.
	public void AddTransition(AnimationGraphTransition transition)
	{
		Transitions.Add(transition);
	}

	/// Gets a state by index, or null if out of range.
	public AnimationGraphState GetState(int32 index)
	{
		if (index >= 0 && index < States.Count)
			return States[index];
		return null;
	}
}
