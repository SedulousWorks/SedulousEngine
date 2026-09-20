using System;
using System.Collections;

namespace Sedulous.Editor.Scene;

/// One layer in the edit model: its states, its transitions and an optional bone mask.
class GraphLayer
{
	public String Name = new .() ~ delete _;
	public int32 DefaultState = 0;
	/// LayerBlendMode: 0 override, 1 additive.
	public uint8 BlendMode = 0;
	public float Weight = 1.0f;
	/// Empty is no mask.
	public List<float> MaskWeights = new .() ~ delete _;
	public List<GraphState> States = new .() ~ DeleteContainerAndItems!(_);
	public List<GraphTransition> Transitions = new .() ~ DeleteContainerAndItems!(_);

	public bool HasState(int32 index) => (index >= 0) && (index < States.Count);
	public bool HasTransition(int32 index) => (index >= 0) && (index < Transitions.Count);

	/// A state's name for a route label; Any State for -1.
	public StringView StateLabel(int32 index)
	{
		if (index < 0)
			return "Any State";
		return HasState(index) ? StringView(States[index].Name) : "?";
	}

	public GraphState AddState(StringView name, uint8 kind)
	{
		let state = new GraphState();
		state.Name.Set(name);
		state.NodeKind = kind;
		States.Add(state);
		return state;
	}

	/// Removes a state along with every transition touching it, re-pointing the rest and
	/// the default; false when the index is out of range.
	public bool DeleteState(int32 index)
	{
		if (!HasState(index))
			return false;
		delete States[index];
		States.RemoveAt(index);
		for (int t = Transitions.Count - 1; t >= 0; t--)
		{
			let tr = Transitions[t];
			if ((tr.Src == index) || (tr.Dst == index))
			{
				delete tr;
				Transitions.RemoveAt(t);
				continue;
			}
			if (tr.Src > index)
				tr.Src--;
			if (tr.Dst > index)
				tr.Dst--;
		}
		if (DefaultState == index)
			DefaultState = 0;
		else if (DefaultState > index)
			DefaultState--;
		return true;
	}

	public GraphTransition AddTransition(int32 src, int32 dst)
	{
		let transition = new GraphTransition();
		transition.Src = src;
		transition.Dst = dst;
		Transitions.Add(transition);
		return transition;
	}

	public bool RemoveTransition(int32 index)
	{
		if (!HasTransition(index))
			return false;
		delete Transitions[index];
		Transitions.RemoveAt(index);
		return true;
	}
}
