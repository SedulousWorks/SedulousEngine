using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Animation.Resource;

namespace Sedulous.Editor.Scene;

/// The animation graph as nested objects, what the page edits. The authored record is
/// AnimationGraphSource, flat parallel arrays with index runs, which is the right wire and
/// the wrong thing to insert into; this loads from it and stores back to it around every
/// snapshot, so the flat form is always what is saved and undone.
class GraphDocument
{
	public List<GraphParam> Params = new .() ~ DeleteContainerAndItems!(_);
	public List<GraphLayer> Layers = new .() ~ DeleteContainerAndItems!(_);

	public bool HasLayer(int32 index) => (index >= 0) && (index < Layers.Count);
	public bool HasParam(int32 index) => (index >= 0) && (index < Params.Count);
	public GraphLayer Layer(int32 index) => HasLayer(index) ? Layers[index] : null;

	public GraphState State(int32 layer, int32 state)
	{
		let l = Layer(layer);
		return ((l != null) && l.HasState(state)) ? l.States[state] : null;
	}

	public GraphTransition Transition(int32 layer, int32 transition)
	{
		let l = Layer(layer);
		return ((l != null) && l.HasTransition(transition)) ? l.Transitions[transition] : null;
	}

	public void Clear()
	{
		ClearAndDeleteItems!(Params);
		ClearAndDeleteItems!(Layers);
	}

	public GraphLayer AddLayer(StringView name)
	{
		let layer = new GraphLayer();
		layer.Name.Set(name);
		Layers.Add(layer);
		return layer;
	}

	/// Never the last one.
	public bool RemoveLayer(int32 index)
	{
		if (!HasLayer(index) || (Layers.Count <= 1))
			return false;
		delete Layers[index];
		Layers.RemoveAt(index);
		return true;
	}

	public GraphParam AddParam(StringView name, uint8 type = 0)
	{
		let param = new GraphParam();
		param.Name.Set(name);
		param.Type = type;
		Params.Add(param);
		return param;
	}

	/// Removes a parameter and re-points every reference: a blend tree on it loses its
	/// parameter, a condition on it goes, and higher indices shift down.
	public bool RemoveParam(int32 index)
	{
		if (!HasParam(index))
			return false;
		delete Params[index];
		Params.RemoveAt(index);
		for (let layer in Layers)
		{
			for (let state in layer.States)
			{
				Remap(ref state.ParamIndex, index);
				Remap(ref state.ParamIndexX, index);
				Remap(ref state.ParamIndexY, index);
			}
			for (let transition in layer.Transitions)
			{
				for (int c = transition.Conditions.Count - 1; c >= 0; c--)
				{
					let condition = transition.Conditions[c];
					if (condition.ParamIndex == index)
					{
						delete condition;
						transition.Conditions.RemoveAt(c);
					}
					else if (condition.ParamIndex > index)
						condition.ParamIndex--;
				}
			}
		}
		return true;
	}

	private static void Remap(ref int32 paramIndex, int32 removed)
	{
		if (paramIndex == removed)
			paramIndex = -1;
		else if (paramIndex > removed)
			paramIndex--;
	}

	/// Rebuilds the model from the flat source. A run is clamped to its pool, as the runtime
	/// build clamps, so a hand edited record loads rather than trips.
	public void Load(AnimationGraphSource s)
	{
		Clear();
		for (int i < s.ParamName.Count)
		{
			let param = AddParam(s.ParamName[i], At(s.ParamType, i, (uint8)0));
			param.FloatValue = At(s.ParamFloat, i, 0.0f);
			param.IntValue = At(s.ParamInt, i, 0);
			param.BoolValue = At(s.ParamBool, i, false);
		}

		let layerCount = Math.Min(Math.Min(s.LayerName.Count, s.LayerDefaultState.Count), Math.Min(s.LayerStateStart.Count, s.LayerStateCount.Count));
		for (int l < layerCount)
		{
			let layer = AddLayer(s.LayerName[l]);
			layer.DefaultState = s.LayerDefaultState[l];
			layer.BlendMode = At(s.LayerBlendModeValue, l, (uint8)0);
			layer.Weight = At(s.LayerWeight, l, 1.0f);

			if ((l < s.LayerMaskStart.Count) && (l < s.LayerMaskCount.Count))
			{
				let from = Math.Min((int)s.LayerMaskStart[l], s.MaskWeight.Count);
				let to = Math.Min(from + (int)s.LayerMaskCount[l], s.MaskWeight.Count);
				for (int b = from; b < to; b++)
					layer.MaskWeights.Add(s.MaskWeight[b]);
			}

			let statePool = Math.Min(Math.Min(s.StateName.Count, s.StateNodeKind.Count), s.StateEntryStart.Count);
			let stateFrom = Math.Min((int)s.LayerStateStart[l], statePool);
			let stateTo = Math.Min(stateFrom + (int)s.LayerStateCount[l], statePool);
			for (int i = stateFrom; i < stateTo; i++)
			{
				let state = layer.AddState(s.StateName[i], s.StateNodeKind[i]);
				state.Speed = At(s.StateSpeed, i, 1.0f);
				state.Loop = At(s.StateLoop, i, true);
				state.ClipRef = At(s.StateNodeClip, i, Guid());
				state.ParamIndex = At(s.StateNodeParamIndex, i, (int32)-1);
				state.ParamIndexX = At(s.StateNodeParamIndexX, i, (int32)-1);
				state.ParamIndexY = At(s.StateNodeParamIndexY, i, (int32)-1);
				let entryFrom = Math.Min((int)s.StateEntryStart[i], s.EntryClip.Count);
				let entryTo = Math.Min(entryFrom + (int)At(s.StateEntryCount, i, (uint32)0), s.EntryClip.Count);
				for (int e = entryFrom; e < entryTo; e++)
				{
					state.EntryClips.Add(s.EntryClip[e]);
					state.EntryThresholds.Add(At(s.EntryThreshold, e, 0.0f));
					state.EntryPositions.Add(At(s.EntryPosition, e, Float2(0, 0)));
				}
			}

			if ((l < s.LayerTransitionStart.Count) && (l < s.LayerTransitionCount.Count))
			{
				let pool = Math.Min(Math.Min(s.TransitionSource.Count, s.TransitionDest.Count), Math.Min(s.TransitionConditionStart.Count, s.TransitionConditionCount.Count));
				let from = Math.Min((int)s.LayerTransitionStart[l], pool);
				let to = Math.Min(from + (int)s.LayerTransitionCount[l], pool);
				let conditionPool = Math.Min(Math.Min(s.ConditionParamIndex.Count, s.ConditionOp.Count), s.ConditionThreshold.Count);
				for (int t = from; t < to; t++)
				{
					let transition = layer.AddTransition(s.TransitionSource[t], s.TransitionDest[t]);
					transition.Duration = At(s.TransitionDuration, t, 0.25f);
					transition.HasExitTime = At(s.TransitionHasExitTime, t, false);
					transition.ExitTime = At(s.TransitionExitTime, t, 1.0f);
					transition.Priority = At(s.TransitionPriority, t, (int32)0);
					let cFrom = Math.Min((int)s.TransitionConditionStart[t], conditionPool);
					let cTo = Math.Min(cFrom + (int)s.TransitionConditionCount[t], conditionPool);
					for (int c = cFrom; c < cTo; c++)
					{
						let condition = new GraphCondition();
						condition.ParamIndex = s.ConditionParamIndex[c];
						condition.Op = s.ConditionOp[c];
						condition.Threshold = s.ConditionThreshold[c];
						transition.Conditions.Add(condition);
					}
				}
			}
		}
	}

	/// Writes the model over the flat source, every run laid out in order.
	public void Store(AnimationGraphSource s)
	{
		ClearAndDeleteItems!(s.ParamName);
		s.ParamType.Clear();
		s.ParamFloat.Clear();
		s.ParamInt.Clear();
		s.ParamBool.Clear();
		for (let param in Params)
		{
			s.ParamName.Add(new String(param.Name));
			s.ParamType.Add(param.Type);
			s.ParamFloat.Add(param.FloatValue);
			s.ParamInt.Add(param.IntValue);
			s.ParamBool.Add(param.BoolValue);
		}

		ClearAndDeleteItems!(s.LayerName);
		s.LayerDefaultState.Clear();
		s.LayerBlendModeValue.Clear();
		s.LayerWeight.Clear();
		s.LayerMaskStart.Clear();
		s.LayerMaskCount.Clear();
		s.LayerStateStart.Clear();
		s.LayerStateCount.Clear();
		s.LayerTransitionStart.Clear();
		s.LayerTransitionCount.Clear();
		s.MaskWeight.Clear();
		ClearAndDeleteItems!(s.StateName);
		s.StateSpeed.Clear();
		s.StateLoop.Clear();
		s.StateNodeKind.Clear();
		s.StateNodeClip.Clear();
		s.StateNodeParamIndex.Clear();
		s.StateNodeParamIndexX.Clear();
		s.StateNodeParamIndexY.Clear();
		s.StateEntryStart.Clear();
		s.StateEntryCount.Clear();
		s.EntryThreshold.Clear();
		s.EntryPosition.Clear();
		s.EntryClip.Clear();
		s.TransitionSource.Clear();
		s.TransitionDest.Clear();
		s.TransitionDuration.Clear();
		s.TransitionHasExitTime.Clear();
		s.TransitionExitTime.Clear();
		s.TransitionPriority.Clear();
		s.TransitionConditionStart.Clear();
		s.TransitionConditionCount.Clear();
		s.ConditionParamIndex.Clear();
		s.ConditionOp.Clear();
		s.ConditionThreshold.Clear();

		for (let layer in Layers)
		{
			s.LayerName.Add(new String(layer.Name));
			s.LayerDefaultState.Add(layer.DefaultState);
			s.LayerBlendModeValue.Add(layer.BlendMode);
			s.LayerWeight.Add(layer.Weight);
			s.LayerMaskStart.Add((uint32)s.MaskWeight.Count);
			s.LayerMaskCount.Add((uint32)layer.MaskWeights.Count);
			s.MaskWeight.AddRange(layer.MaskWeights);

			s.LayerStateStart.Add((uint32)s.StateName.Count);
			s.LayerStateCount.Add((uint32)layer.States.Count);
			for (let state in layer.States)
			{
				state.NormalizeEntries();
				s.StateName.Add(new String(state.Name));
				s.StateSpeed.Add(state.Speed);
				s.StateLoop.Add(state.Loop);
				s.StateNodeKind.Add(state.NodeKind);
				s.StateNodeClip.Add(state.ClipRef);
				s.StateNodeParamIndex.Add(state.ParamIndex);
				s.StateNodeParamIndexX.Add(state.ParamIndexX);
				s.StateNodeParamIndexY.Add(state.ParamIndexY);
				s.StateEntryStart.Add((uint32)s.EntryClip.Count);
				s.StateEntryCount.Add((uint32)state.EntryClips.Count);
				for (int e < state.EntryClips.Count)
				{
					s.EntryClip.Add(state.EntryClips[e]);
					s.EntryThreshold.Add(state.EntryThresholds[e]);
					s.EntryPosition.Add(state.EntryPositions[e]);
				}
			}

			s.LayerTransitionStart.Add((uint32)s.TransitionSource.Count);
			s.LayerTransitionCount.Add((uint32)layer.Transitions.Count);
			for (let transition in layer.Transitions)
			{
				s.TransitionSource.Add(transition.Src);
				s.TransitionDest.Add(transition.Dst);
				s.TransitionDuration.Add(transition.Duration);
				s.TransitionHasExitTime.Add(transition.HasExitTime);
				s.TransitionExitTime.Add(transition.ExitTime);
				s.TransitionPriority.Add(transition.Priority);
				s.TransitionConditionStart.Add((uint32)s.ConditionParamIndex.Count);
				s.TransitionConditionCount.Add((uint32)transition.Conditions.Count);
				for (let condition in transition.Conditions)
				{
					s.ConditionParamIndex.Add(condition.ParamIndex);
					s.ConditionOp.Add(condition.Op);
					s.ConditionThreshold.Add(condition.Threshold);
				}
			}
		}
	}

	private static T At<T>(List<T> list, int index, T fallback) => (index < list.Count) ? list[index] : fallback;
}
