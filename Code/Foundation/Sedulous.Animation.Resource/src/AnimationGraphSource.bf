using System;
using System.Collections;
using Sedulous.Animation;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Resource;

namespace Sedulous.Animation.Resource;

/// The cooked WIRE for a graph: FLAT PARALLEL ARRAYS all the way down, so the serializer
/// never nests.
///
/// A layer indexes runs of the state and transition pools, a state indexes a run of the
/// blend entry pool, and a transition indexes a run of the condition pool: arrays of
/// structs holding arrays, flattened into what this serializer can carry.
///
/// The graph is AUTHORED, unlike a skeleton or a clip which are captured from a model, so
/// this record is the authoritative form rather than a derived one.
[Serializable]
class AnimationGraphSource
{
	// The parameters.
	public List<String> ParamName = new .() ~ DeleteContainerAndItems!(_);
	public List<uint8> ParamType = new .() ~ delete _;
	public List<float> ParamFloat = new .() ~ delete _;
	public List<int32> ParamInt = new .() ~ delete _;
	public List<bool> ParamBool = new .() ~ delete _;

	// The layers.
	public List<String> LayerName = new .() ~ DeleteContainerAndItems!(_);
	public List<int32> LayerDefaultState = new .() ~ delete _;
	public List<uint8> LayerBlendModeValue = new .() ~ delete _;
	public List<float> LayerWeight = new .() ~ delete _;
	public List<uint32> LayerMaskStart = new .() ~ delete _;
	/// Nought is NO MASK, which is a layer that reaches every bone.
	public List<uint32> LayerMaskCount = new .() ~ delete _;
	public List<uint32> LayerStateStart = new .() ~ delete _;
	public List<uint32> LayerStateCount = new .() ~ delete _;
	public List<uint32> LayerTransitionStart = new .() ~ delete _;
	public List<uint32> LayerTransitionCount = new .() ~ delete _;

	/// The shared mask weight pool.
	public List<float> MaskWeight = new .() ~ delete _;

	// The state pool.
	public List<String> StateName = new .() ~ DeleteContainerAndItems!(_);
	public List<float> StateSpeed = new .() ~ delete _;
	public List<bool> StateLoop = new .() ~ delete _;
	/// Nought is a clip, one a one dimensional tree, two a two dimensional one.
	public List<uint8> StateNodeKind = new .() ~ delete _;
	public List<Guid> StateNodeClip = new .() ~ delete _;
	public List<int32> StateNodeParamIndex = new .() ~ delete _;
	public List<int32> StateNodeParamIndexX = new .() ~ delete _;
	public List<int32> StateNodeParamIndexY = new .() ~ delete _;
	public List<uint32> StateEntryStart = new .() ~ delete _;
	public List<uint32> StateEntryCount = new .() ~ delete _;

	// The blend entry pool. A one dimensional tree reads the threshold and a two dimensional
	// one the position; both read the clip.
	public List<float> EntryThreshold = new .() ~ delete _;
	public List<Float2> EntryPosition = new .() ~ delete _;
	public List<Guid> EntryClip = new .() ~ delete _;

	// The transition pool.
	public List<int32> TransitionSource = new .() ~ delete _;
	public List<int32> TransitionDest = new .() ~ delete _;
	public List<float> TransitionDuration = new .() ~ delete _;
	public List<bool> TransitionHasExitTime = new .() ~ delete _;
	public List<float> TransitionExitTime = new .() ~ delete _;
	public List<int32> TransitionPriority = new .() ~ delete _;
	public List<uint32> TransitionConditionStart = new .() ~ delete _;
	public List<uint32> TransitionConditionCount = new .() ~ delete _;

	// The condition pool.
	public List<int32> ConditionParamIndex = new .() ~ delete _;
	public List<uint8> ConditionOp = new .() ~ delete _;
	public List<float> ConditionThreshold = new .() ~ delete _;

	/// Builds a runtime graph, resolving each clip through the manager.
	///
	/// The BIND is what records the graph to clip edge, which is what keeps a clip alive
	/// while the graph is bound: a node holds its clip BORROWED.
	public void BuildInto(ResourceManager manager, AnimationGraph graph)
	{
		BuildParameters(graph);

		let layerCount = Min(Min(LayerName.Count, LayerDefaultState.Count),
			Min(LayerStateStart.Count, LayerStateCount.Count));

		for (int i = 0; i < layerCount; i++)
		{
			let layer = new AnimationLayer(LayerName[i]);
			layer.DefaultStateIndex = LayerDefaultState[i];
			uint8 blendModeValue = (i < LayerBlendModeValue.Count) ? LayerBlendModeValue[i] : 0;
			layer.BlendMode = (LayerBlendMode)blendModeValue;
			layer.Weight = (i < LayerWeight.Count) ? LayerWeight[i] : 1.0f;

			BuildMask(layer, i);
			BuildStates(manager, layer, i);
			BuildTransitions(layer, i);

			graph.AddLayer(layer);
		}
	}

	private void BuildParameters(AnimationGraph graph)
	{
		for (int i = 0; i < ParamName.Count; i++)
		{
			uint8 typeValue = (i < ParamType.Count) ? ParamType[i] : 0;
			let type = (AnimationParameterType)typeValue;
			let index = graph.AddParameter(ParamName[i], type);

			let parameter = graph.GetParameter(index);
			if (parameter == null)
				continue;

			// The defaults, so a graph starts where it was authored to rather than at zero.
			if (i < ParamFloat.Count)
				parameter.FloatValue = ParamFloat[i];
			if (i < ParamInt.Count)
				parameter.IntValue = ParamInt[i];
			if (i < ParamBool.Count)
				parameter.BoolValue = ParamBool[i];
		}
	}

	private void BuildMask(AnimationLayer layer, int layerIndex)
	{
		if ((layerIndex >= LayerMaskStart.Count) || (layerIndex >= LayerMaskCount.Count))
			return;

		let from = Min((int)LayerMaskStart[layerIndex], MaskWeight.Count);
		let to = Min(from + (int)LayerMaskCount[layerIndex], MaskWeight.Count);
		if (to <= from)
			return;

		// Built at NOUGHT and filled, so a mask shorter than the skeleton confines the layer
		// rather than opening it up.
		let mask = new BoneMask((int32)(to - from), 0.0f);
		for (int b = from; b < to; b++)
			mask.SetWeight((int32)(b - from), MaskWeight[b]);
		layer.SetMask(mask);
	}

	private void BuildStates(ResourceManager manager, AnimationLayer layer, int layerIndex)
	{
		let pool = Min(Min(StateName.Count, StateNodeKind.Count), StateEntryStart.Count);
		let from = Min((int)LayerStateStart[layerIndex], pool);
		let to = Min(from + (int)LayerStateCount[layerIndex], pool);

		for (int s = from; s < to; s++)
		{
			// The state OWNS its node, since nothing else refers to it.
			let state = new AnimationGraphState(StateName[s], BuildNode(manager, s), true);
			state.Speed = (s < StateSpeed.Count) ? StateSpeed[s] : 1.0f;
			state.Loop = (s < StateLoop.Count) ? StateLoop[s] : true;
			layer.AddState(state);
		}
	}

	private IAnimationStateNode BuildNode(ResourceManager manager, int stateIndex)
	{
		let kind = StateNodeKind[stateIndex];

		// The clip is the one field every entry must have, so the pool is as long as that
		// array and a missing threshold or position falls back rather than truncating.
		let from = Min((int)StateEntryStart[stateIndex], EntryClip.Count);
		let to = Min(from + ((stateIndex < StateEntryCount.Count)
			? (int)StateEntryCount[stateIndex] : 0), EntryClip.Count);

		if (kind == 1)
		{
			let tree = new BlendTree1D();
			tree.ParameterIndex = (stateIndex < StateNodeParamIndex.Count)
				? StateNodeParamIndex[stateIndex] : -1;
			for (int i = from; i < to; i++)
				tree.AddEntry((i < EntryThreshold.Count) ? EntryThreshold[i] : 0.0f,
					ResolveClip(manager, EntryClip[i]));
			return tree;
		}

		if (kind == 2)
		{
			let tree = new BlendTree2D();
			tree.ParameterIndexX = (stateIndex < StateNodeParamIndexX.Count)
				? StateNodeParamIndexX[stateIndex] : -1;
			tree.ParameterIndexY = (stateIndex < StateNodeParamIndexY.Count)
				? StateNodeParamIndexY[stateIndex] : -1;
			for (int i = from; i < to; i++)
				tree.AddEntry((i < EntryPosition.Count) ? EntryPosition[i] : Float2(0, 0),
					ResolveClip(manager, EntryClip[i]));
			return tree;
		}

		let clipId = (stateIndex < StateNodeClip.Count) ? StateNodeClip[stateIndex] : Guid();
		return new ClipStateNode(ResolveClip(manager, clipId));
	}

	private void BuildTransitions(AnimationLayer layer, int layerIndex)
	{
		if ((layerIndex >= LayerTransitionStart.Count)
			|| (layerIndex >= LayerTransitionCount.Count))
			return;

		let pool = Min(Min(TransitionSource.Count, TransitionDest.Count),
			Min(TransitionConditionStart.Count, TransitionConditionCount.Count));
		let from = Min((int)LayerTransitionStart[layerIndex], pool);
		let to = Min(from + (int)LayerTransitionCount[layerIndex], pool);

		let conditionPool = Min(Min(ConditionParamIndex.Count, ConditionOp.Count),
			ConditionThreshold.Count);

		for (int t = from; t < to; t++)
		{
			let transition = new AnimationGraphTransition();
			transition.SourceStateIndex = TransitionSource[t];
			transition.DestStateIndex = TransitionDest[t];
			transition.Duration = (t < TransitionDuration.Count) ? TransitionDuration[t] : 0.25f;
			transition.HasExitTime = (t < TransitionHasExitTime.Count)
				? TransitionHasExitTime[t] : false;
			transition.ExitTime = (t < TransitionExitTime.Count) ? TransitionExitTime[t] : 1.0f;
			transition.Priority = (t < TransitionPriority.Count) ? TransitionPriority[t] : 0;

			let conditionFrom = Min((int)TransitionConditionStart[t], conditionPool);
			let conditionTo = Min(conditionFrom + (int)TransitionConditionCount[t], conditionPool);
			for (int c = conditionFrom; c < conditionTo; c++)
				transition.Conditions.Add(.(ConditionParamIndex[c], (ComparisonOp)ConditionOp[c],
					ConditionThreshold[c]));

			layer.AddTransition(transition);
		}
	}

	/// A nil id is a node with NO clip, which evaluates to nothing rather than failing the
	/// whole graph: an authored gap is not an error.
	private static AnimationClip ResolveClip(ResourceManager manager, Guid id)
	{
		if (id == Guid())
			return null;
		return manager.Bind<AnimationClip>(id).Get;
	}
}
