using System;
using System.Collections;

namespace Sedulous.Animation;

/// One layer of a graph: its states, its transitions, and the mask that confines it.
///
/// Layer nought is the BASE and writes the pose outright; every layer above it blends on
/// top, in order.
class AnimationLayer
{
	private String mName = new .() ~ delete _;

	public int32 DefaultStateIndex = 0;
	public LayerBlendMode BlendMode = .Override;
	public float Weight = 1.0f;

	public List<AnimationGraphState> States = new .() ~ DeleteContainerAndItems!(_);
	public List<AnimationGraphTransition> Transitions = new .() ~ DeleteContainerAndItems!(_);

	private BoneMask mMask = null ~ delete _;

	public this(StringView name)
	{
		mName.Set(name);
	}

	public String Name => mName;
	public BoneMask Mask => mMask;

	/// TAKES OWNERSHIP, replacing whatever was there.
	public void SetMask(BoneMask mask)
	{
		delete mMask;
		mMask = mask;
	}

	/// TAKES OWNERSHIP. Answers the index, which is what a transition points at.
	public int32 AddState(AnimationGraphState state)
	{
		let index = (int32)States.Count;
		States.Add(state);
		return index;
	}

	/// TAKES OWNERSHIP.
	public void AddTransition(AnimationGraphTransition transition)
	{
		Transitions.Add(transition);
	}

	public AnimationGraphState GetState(int32 index) =>
		((index >= 0) && (index < States.Count)) ? States[index] : null;

	public int32 FindStateIndex(StringView name)
	{
		for (int32 i = 0; i < States.Count; i++)
		{
			if (States[i].Name == name)
				return i;
		}
		return -1;
	}
}
