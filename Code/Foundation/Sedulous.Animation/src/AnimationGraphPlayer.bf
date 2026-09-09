using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Animation;

/// Runs a graph for ONE skeleton instance: the state machines, one per layer, and the blend
/// that combines them.
///
/// The graph and the skeleton are BORROWED. The parameters are COPIED, because every
/// instance drives its own: two characters running one graph must not share a speed.
class AnimationGraphPlayer
{
	/// A blend tree and the parameter that drives it, resolved ONCE at construction so the
	/// per frame sync is a walk of a flat list rather than a search of every state.
	private struct Link1D
	{
		public BlendTree1D Tree;
		public int32 ParamIndex;
	}

	private struct Link2D
	{
		public BlendTree2D Tree;
		public int32 ParamIndexX;
		public int32 ParamIndexY;
	}

	private AnimationGraph mGraph;
	private Skeleton mSkeleton;

	private List<AnimationGraphLayerRuntime> mLayerRuntimes = new .() ~ DeleteContainerAndItems!(_);
	private List<AnimationGraphParameter> mParameters = new .() ~ DeleteContainerAndItems!(_);

	private List<BoneTransform> mFinalPoses = new .() ~ delete _;
	private List<Float4x4> mSkinningMatrices = new .() ~ delete _;
	private List<Float4x4> mPrevSkinningMatrices = new .() ~ delete _;
	private bool mMatricesDirty = true;

	/// OWNED.
	private AnimationEventHandler mEventHandler = null ~ delete _;

	private List<Link1D> mLinks1D = new .() ~ delete _;
	private List<Link2D> mLinks2D = new .() ~ delete _;

	public this(AnimationGraph graph, Skeleton skeleton)
	{
		mGraph = graph;
		mSkeleton = skeleton;

		let boneCount = skeleton.BoneCount;
		mFinalPoses.Count = boneCount;
		mSkinningMatrices.Count = boneCount;
		mPrevSkinningMatrices.Count = boneCount;
		for (int i < boneCount)
		{
			mSkinningMatrices[i] = Float4x4.Identity();
			mPrevSkinningMatrices[i] = Float4x4.Identity();
		}

		// Each player's OWN parameter values, index aligned with the graph's so a condition's
		// index means the same thing in both.
		for (let parameter in graph.Parameters)
		{
			let copy = new AnimationGraphParameter();
			copy.CopyFrom(parameter);
			mParameters.Add(copy);
		}

		for (let layer in graph.Layers)
		{
			let runtime = new AnimationGraphLayerRuntime();
			runtime.Init(boneCount);
			runtime.Reset(layer.DefaultStateIndex);
			mLayerRuntimes.Add(runtime);
		}

		// The blend trees are linked to their parameters once, here.
		for (let layer in graph.Layers)
		{
			for (let state in layer.States)
			{
				let node = state.Node;
				if (node == null)
					continue;

				if (let tree = node as BlendTree1D)
				{
					if (tree.ParameterIndex >= 0)
						mLinks1D.Add(.() { Tree = tree, ParamIndex = tree.ParameterIndex });
				}
				else if (let tree = node as BlendTree2D)
				{
					if ((tree.ParameterIndexX >= 0) || (tree.ParameterIndexY >= 0))
						mLinks2D.Add(.()
							{
								Tree = tree,
								ParamIndexX = tree.ParameterIndexX,
								ParamIndexY = tree.ParameterIndexY
							});
				}
			}
		}

		ResetToBind();
	}

	public Skeleton GetSkeleton => mSkeleton;
	public AnimationGraph GetGraph => mGraph;

	// ==================== parameters ====================

	public void SetFloat(int32 index, float value)
	{
		if (Valid(index))
			mParameters[index].FloatValue = value;
	}

	public void SetFloat(StringView name, float value) => SetFloat(mGraph.FindParameter(name), value);

	public float GetFloat(int32 index) => Valid(index) ? mParameters[index].FloatValue : 0.0f;

	public void SetInt(int32 index, int32 value)
	{
		if (Valid(index))
			mParameters[index].IntValue = value;
	}

	public void SetInt(StringView name, int32 value) => SetInt(mGraph.FindParameter(name), value);

	public int32 GetInt(int32 index) => Valid(index) ? mParameters[index].IntValue : 0;

	public void SetBool(int32 index, bool value)
	{
		if (Valid(index))
			mParameters[index].BoolValue = value;
	}

	public void SetBool(StringView name, bool value) => SetBool(mGraph.FindParameter(name), value);

	public bool GetBool(int32 index) => Valid(index) ? mParameters[index].BoolValue : false;

	/// Sets a trigger, which the NEXT update consumes.
	public void SetTrigger(int32 index)
	{
		if (Valid(index))
			mParameters[index].BoolValue = true;
	}

	public void SetTrigger(StringView name) => SetTrigger(mGraph.FindParameter(name));

	/// TAKES OWNERSHIP, replacing whatever was there.
	public void SetEventHandler(AnimationEventHandler handler)
	{
		delete mEventHandler;
		mEventHandler = handler;
	}

	// ==================== the frame ====================

	public void Update(float deltaTime)
	{
		// This frame's matrices become last frame's before anything moves.
		for (int i < mSkinningMatrices.Count)
			mPrevSkinningMatrices[i] = mSkinningMatrices[i];

		SyncBlendTreeParameters();

		for (int i = 0; (i < mGraph.Layers.Count) && (i < mLayerRuntimes.Count); i++)
			UpdateLayer(mGraph.Layers[i], mLayerRuntimes[i], deltaTime);

		// AFTER the layers, so every state machine saw the trigger before it is cleared.
		for (let parameter in mParameters)
			parameter.ConsumeTrigger();

		CombineLayers();
		mMatricesDirty = true;
	}

	public Span<Float4x4> GetSkinningMatrices()
	{
		if (mMatricesDirty)
		{
			mSkeleton.ComputeSkinningMatrices(mFinalPoses, mSkinningMatrices);
			mMatricesDirty = false;
		}
		return mSkinningMatrices;
	}

	public Span<Float4x4> GetPrevSkinningMatrices() => mPrevSkinningMatrices;

	public Span<BoneTransform> GetLocalPoses() => mFinalPoses;

	// ==================== state ====================

	public int32 GetCurrentStateIndex(int32 layerIndex = 0) =>
		((layerIndex >= 0) && (layerIndex < mLayerRuntimes.Count))
			? mLayerRuntimes[layerIndex].CurrentStateIndex : -1;

	public bool IsTransitioning(int32 layerIndex = 0) =>
		((layerIndex >= 0) && (layerIndex < mLayerRuntimes.Count))
			? mLayerRuntimes[layerIndex].IsTransitioning : false;

	public float GetCurrentNormalizedTime(int32 layerIndex = 0) =>
		((layerIndex >= 0) && (layerIndex < mLayerRuntimes.Count))
			? mLayerRuntimes[layerIndex].CurrentTime : 0.0f;

	public void ResetToBind()
	{
		for (int32 i = 0; (i < mSkeleton.BoneCount) && (i < mFinalPoses.Count); i++)
		{
			let bone = mSkeleton.GetBone(i);
			mFinalPoses[i] = (bone != null) ? bone.LocalBindPose : BoneTransform();
		}
		mMatricesDirty = true;
	}

	/// Jumps straight to a state, cancelling any fade in flight. What a respawn uses.
	public void ForceState(int32 stateIndex, int32 layerIndex = 0)
	{
		if ((layerIndex < 0) || (layerIndex >= mLayerRuntimes.Count))
			return;

		let runtime = mLayerRuntimes[layerIndex];
		runtime.CurrentStateIndex = stateIndex;
		runtime.CurrentTime = 0.0f;
		runtime.IsTransitioning = false;
		runtime.PreviousStateIndex = -1;
	}

	// ==================== the machinery ====================

	private bool Valid(int32 index) => (index >= 0) && (index < mParameters.Count);

	private void UpdateLayer(AnimationLayer layer, AnimationGraphLayerRuntime runtime,
		float deltaTime)
	{
		if ((runtime.CurrentStateIndex < 0) || (runtime.CurrentStateIndex >= layer.States.Count))
			return;

		var currentState = layer.GetState(runtime.CurrentStateIndex);

		// A transition is only looked for while not already in one: a fade runs to its end
		// rather than being interrupted by the next condition to come true.
		if (!runtime.IsTransitioning)
			EvaluateTransitions(layer, runtime);

		let prevNorm = runtime.CurrentTime;

		if (runtime.IsTransitioning)
		{
			AdvanceStateTime(currentState, ref runtime.CurrentTime, deltaTime);

			// The state being faded OUT keeps playing, so a walk does not freeze mid stride
			// while the run fades in over it.
			let previousState = layer.GetState(runtime.PreviousStateIndex);
			if (previousState != null)
				AdvanceStateTime(previousState, ref runtime.PreviousTime, deltaTime);

			currentState = layer.GetState(runtime.CurrentStateIndex);
			if ((mEventHandler != null) && (currentState != null) && (currentState.Node != null))
				currentState.Node.FireEvents(prevNorm, runtime.CurrentTime, currentState.Loop,
					mEventHandler);

			runtime.TransitionElapsed += deltaTime;
			if (runtime.TransitionElapsed >= runtime.TransitionDuration)
			{
				runtime.IsTransitioning = false;
				runtime.PreviousStateIndex = -1;
			}
		}
		else
		{
			AdvanceStateTime(currentState, ref runtime.CurrentTime, deltaTime);
			if ((mEventHandler != null) && (currentState.Node != null))
				currentState.Node.FireEvents(prevNorm, runtime.CurrentTime, currentState.Loop,
					mEventHandler);
		}

		SampleLayerPoses(layer, runtime);
	}

	/// Advances a state's NORMALISED clock. A state with no duration does not move at all,
	/// rather than dividing by nothing.
	private void AdvanceStateTime(AnimationGraphState state, ref float normalizedTime,
		float deltaTime)
	{
		if (state.Duration <= 0.0f)
			return;

		normalizedTime += (deltaTime * state.Speed) / state.Duration;
		if (state.Loop)
		{
			while (normalizedTime >= 1.0f)
				normalizedTime -= 1.0f;
			while (normalizedTime < 0.0f)
				normalizedTime += 1.0f;
		}
		else
		{
			normalizedTime = Clamp(normalizedTime, 0.0f, 1.0f);
		}
	}

	private void EvaluateTransitions(AnimationLayer layer, AnimationGraphLayerRuntime runtime)
	{
		AnimationGraphTransition best = null;
		var bestPriority = int32.MaxValue;

		for (let transition in layer.Transitions)
		{
			// Minus one is any state.
			if ((transition.SourceStateIndex != -1)
				&& (transition.SourceStateIndex != runtime.CurrentStateIndex))
				continue;
			// A transition to where it already is would restart the state every frame.
			if (transition.DestStateIndex == runtime.CurrentStateIndex)
				continue;
			if (transition.HasExitTime && (runtime.CurrentTime < transition.ExitTime))
				continue;
			if (!transition.EvaluateConditions(mParameters))
				continue;

			if (transition.Priority < bestPriority)
			{
				bestPriority = transition.Priority;
				best = transition;
			}
		}

		if (best == null)
			return;

		runtime.PreviousStateIndex = runtime.CurrentStateIndex;
		runtime.PreviousTime = runtime.CurrentTime;
		runtime.CurrentStateIndex = best.DestStateIndex;
		runtime.CurrentTime = 0.0f;
		runtime.TransitionElapsed = 0.0f;
		// A floor on the duration, so an instant transition is still a division.
		runtime.TransitionDuration = Max(best.Duration, 0.001f);
		runtime.IsTransitioning = true;
	}

	private void SampleLayerPoses(AnimationLayer layer, AnimationGraphLayerRuntime runtime)
	{
		if (runtime.CurrentStateIndex < 0)
			return;

		let currentState = layer.GetState(runtime.CurrentStateIndex);
		if ((currentState == null) || (currentState.Node == null))
			return;

		if (runtime.IsTransitioning && (runtime.PreviousStateIndex >= 0))
		{
			let previousState = layer.GetState(runtime.PreviousStateIndex);
			if ((previousState != null) && (previousState.Node != null))
			{
				previousState.Node.Evaluate(mSkeleton, runtime.PreviousTime, runtime.PrevPoses);
				currentState.Node.Evaluate(mSkeleton, runtime.CurrentTime, runtime.Poses);
				let blend = Clamp(runtime.TransitionElapsed / runtime.TransitionDuration, 0.0f,
					1.0f);
				AnimationSampler.BlendPoses(runtime.PrevPoses, runtime.Poses, blend,
					runtime.Poses);
				return;
			}
		}

		currentState.Node.Evaluate(mSkeleton, runtime.CurrentTime, runtime.Poses);
	}

	private void SyncBlendTreeParameters()
	{
		for (let link in mLinks1D)
		{
			if (Valid(link.ParamIndex))
				link.Tree.Parameter = mParameters[link.ParamIndex].FloatValue;
		}
		for (let link in mLinks2D)
		{
			if (Valid(link.ParamIndexX))
				link.Tree.ParameterX = mParameters[link.ParamIndexX].FloatValue;
			if (Valid(link.ParamIndexY))
				link.Tree.ParameterY = mParameters[link.ParamIndexY].FloatValue;
		}
	}

	private void CombineLayers()
	{
		if (mLayerRuntimes.IsEmpty)
			return;

		// The base layer WRITES rather than blends: there is nothing underneath it.
		let baseLayer = mLayerRuntimes[0];
		for (int i = 0; (i < mFinalPoses.Count) && (i < baseLayer.Poses.Count); i++)
			mFinalPoses[i] = baseLayer.Poses[i];

		for (int layerIndex = 1;
			(layerIndex < mLayerRuntimes.Count) && (layerIndex < mGraph.Layers.Count);
			layerIndex++)
		{
			let layer = mGraph.Layers[layerIndex];
			let runtime = mLayerRuntimes[layerIndex];
			if (layer.Weight <= 0.0f)
				continue;

			let mask = layer.Mask;

			if (layer.BlendMode == .Override)
			{
				for (int b = 0; (b < mFinalPoses.Count) && (b < runtime.Poses.Count); b++)
				{
					let weight = layer.Weight * ((mask != null) ? mask.GetWeight((int32)b) : 1.0f);
					if (weight > 0.0f)
						mFinalPoses[b] = BoneTransform.Lerp(mFinalPoses[b], runtime.Poses[b],
							weight);
				}
				continue;
			}

			// Additive: what the layer's pose DIFFERS from the bind pose by, applied on top.
			for (int b = 0; (b < mFinalPoses.Count) && (b < runtime.Poses.Count); b++)
			{
				let weight = layer.Weight * ((mask != null) ? mask.GetWeight((int32)b) : 1.0f);
				if (weight <= 0.0f)
					continue;

				let bone = mSkeleton.GetBone((int32)b);
				let bind = (bone != null) ? bone.LocalBindPose : BoneTransform();

				let deltaPosition = runtime.Poses[b].Position - bind.Position;
				let deltaRotation = runtime.Poses[b].Rotation * Inverse(bind.Rotation);
				let deltaScale = runtime.Poses[b].Scale / bind.Scale;

				mFinalPoses[b].Position = mFinalPoses[b].Position + deltaPosition * weight;
				mFinalPoses[b].Rotation =
					Slerp(Quaternion.Identity, deltaRotation, weight) * mFinalPoses[b].Rotation;
				mFinalPoses[b].Scale =
					mFinalPoses[b].Scale * Lerp(Float3.One, deltaScale, weight);
			}
		}
	}
}
