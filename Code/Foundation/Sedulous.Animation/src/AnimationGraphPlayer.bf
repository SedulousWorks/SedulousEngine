namespace Sedulous.Animation;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;

/// Per-layer runtime state tracking for the animation graph player.
class AnimationGraphLayerRuntime
{
	/// Index of the current active state in the layer.
	public int32 CurrentStateIndex = -1;

	/// Normalized playback time [0..1] for the current state.
	public float CurrentTime;

	/// Index of the previous state during a transition (or -1 if no transition).
	public int32 PreviousStateIndex = -1;

	/// Normalized playback time for the previous state during a transition.
	public float PreviousTime;

	/// Elapsed transition time in seconds.
	public float TransitionElapsed;

	/// Total duration of the active transition in seconds.
	public float TransitionDuration;

	/// Whether a cross-fade transition is in progress.
	public bool IsTransitioning;

	/// Bone transforms output for this layer (owned).
	public BoneTransform[] Poses ~ delete _;

	/// Temporary poses for the previous state during transition (owned).
	public BoneTransform[] PrevPoses ~ delete _;

	public this(int32 boneCount)
	{
		Poses = new BoneTransform[boneCount];
		PrevPoses = new BoneTransform[boneCount];
	}

	/// Resets this layer to its initial state.
	public void Reset(int32 defaultStateIndex)
	{
		CurrentStateIndex = defaultStateIndex;
		CurrentTime = 0;
		PreviousStateIndex = -1;
		PreviousTime = 0;
		TransitionElapsed = 0;
		TransitionDuration = 0;
		IsTransitioning = false;
	}
}

/// Evaluates an AnimationGraph, producing skinning matrices for a skeleton.
/// Each entity gets its own AnimationGraphPlayer instance, while the AnimationGraph
/// definition can be shared.
class AnimationGraphPlayer
{
	private AnimationGraph mGraph;
	private Skeleton mSkeleton;

	/// Per-layer runtime state (owned).
	private List<AnimationGraphLayerRuntime> mLayerRuntimes = new .() ~ DeleteContainerAndItems!(_);

	/// Runtime parameter values (separate from graph definition so multiple players can share a graph).
	private List<AnimationGraphParameter> mParameters = new .() ~ DeleteContainerAndItems!(_);

	/// Final blended bone transforms (owned).
	private BoneTransform[] mFinalPoses ~ delete _;

	/// Final skinning matrices for GPU upload (owned).
	private Matrix[] mSkinningMatrices ~ delete _;

	/// Previous frame skinning matrices for motion blur (owned).
	private Matrix[] mPrevSkinningMatrices ~ delete _;

	/// Whether skinning matrices need recomputing.
	private bool mMatricesDirty = true;

	/// Animation event callback (owned).
	private AnimationEventHandler mEventHandler ~ delete _;

	/// Creates a graph player for the given graph and skeleton.
	public this(AnimationGraph graph, Skeleton skeleton)
	{
		mGraph = graph;
		mSkeleton = skeleton;

		let boneCount = skeleton.BoneCount;
		mFinalPoses = new BoneTransform[boneCount];
		mSkinningMatrices = new Matrix[boneCount];
		mPrevSkinningMatrices = new Matrix[boneCount];

		// Copy parameters from graph definition (each player has its own runtime values)
		for (let param in graph.Parameters)
		{
			let runtimeParam = new AnimationGraphParameter(param.Name, param.Type);
			runtimeParam.FloatValue = param.FloatValue;
			runtimeParam.IntValue = param.IntValue;
			runtimeParam.BoolValue = param.BoolValue;
			mParameters.Add(runtimeParam);
		}

		// Create per-layer runtimes
		for (let layer in graph.Layers)
		{
			let runtime = new AnimationGraphLayerRuntime(boneCount);
			runtime.Reset(layer.DefaultStateIndex);
			mLayerRuntimes.Add(runtime);
		}

		// Initialize to bind pose
		ResetToBind();
	}

	/// The skeleton this player animates.
	public Skeleton Skeleton => mSkeleton;

	/// The graph definition.
	public AnimationGraph Graph => mGraph;

	// ==================== Parameter Access ====================

	/// Sets a float parameter by index.
	public void SetFloat(int32 paramIndex, float value)
	{
		if (paramIndex >= 0 && paramIndex < mParameters.Count)
			mParameters[paramIndex].FloatValue = value;
	}

	/// Sets a float parameter by name.
	public void SetFloat(StringView name, float value)
	{
		let idx = mGraph.FindParameter(name);
		if (idx >= 0)
			SetFloat(idx, value);
	}

	/// Gets a float parameter by index.
	public float GetFloat(int32 paramIndex)
	{
		if (paramIndex >= 0 && paramIndex < mParameters.Count)
			return mParameters[paramIndex].FloatValue;
		return 0;
	}

	/// Sets an int parameter by index.
	public void SetInt(int32 paramIndex, int32 value)
	{
		if (paramIndex >= 0 && paramIndex < mParameters.Count)
			mParameters[paramIndex].IntValue = value;
	}

	/// Sets an int parameter by name.
	public void SetInt(StringView name, int32 value)
	{
		let idx = mGraph.FindParameter(name);
		if (idx >= 0)
			SetInt(idx, value);
	}

	/// Gets an int parameter by index.
	public int32 GetInt(int32 paramIndex)
	{
		if (paramIndex >= 0 && paramIndex < mParameters.Count)
			return mParameters[paramIndex].IntValue;
		return 0;
	}

	/// Sets a bool parameter by index.
	public void SetBool(int32 paramIndex, bool value)
	{
		if (paramIndex >= 0 && paramIndex < mParameters.Count)
			mParameters[paramIndex].BoolValue = value;
	}

	/// Sets a bool parameter by name.
	public void SetBool(StringView name, bool value)
	{
		let idx = mGraph.FindParameter(name);
		if (idx >= 0)
			SetBool(idx, value);
	}

	/// Gets a bool parameter by index.
	public bool GetBool(int32 paramIndex)
	{
		if (paramIndex >= 0 && paramIndex < mParameters.Count)
			return mParameters[paramIndex].BoolValue;
		return false;
	}

	/// Sets a trigger parameter (auto-resets after consumption).
	public void SetTrigger(int32 paramIndex)
	{
		if (paramIndex >= 0 && paramIndex < mParameters.Count)
			mParameters[paramIndex].BoolValue = true;
	}

	/// Sets a trigger parameter by name.
	public void SetTrigger(StringView name)
	{
		let idx = mGraph.FindParameter(name);
		if (idx >= 0)
			SetTrigger(idx);
	}

	/// Sets the animation event handler. The player takes ownership of the delegate.
	public void SetEventHandler(AnimationEventHandler handler)
	{
		delete mEventHandler;
		mEventHandler = handler;
	}

	// ==================== Update ====================

	/// Updates the animation graph by the given delta time.
	public void Update(float deltaTime)
	{
		// Store previous matrices for motion blur
		mSkinningMatrices.CopyTo(mPrevSkinningMatrices);

		// Sync blend tree parameters
		SyncBlendTreeParameters();

		// Update each layer
		for (int i = 0; i < mGraph.Layers.Count && i < mLayerRuntimes.Count; i++)
		{
			UpdateLayer(mGraph.Layers[i], mLayerRuntimes[i], deltaTime);
		}

		// Consume triggers after all layers have processed
		for (let param in mParameters)
			param.ConsumeTrigger();

		// Combine layers into final pose
		CombineLayers();

		mMatricesDirty = true;
	}

	/// Updates a single layer: advance time, evaluate transitions, sample poses.
	private void UpdateLayer(AnimationLayer layer, AnimationGraphLayerRuntime runtime, float deltaTime)
	{
		if (runtime.CurrentStateIndex < 0 || runtime.CurrentStateIndex >= layer.States.Count)
			return;

		let currentState = layer.States[runtime.CurrentStateIndex];

		// Evaluate transitions
		if (!runtime.IsTransitioning)
		{
			EvaluateTransitions(layer, runtime);
		}

		// Advance time
		if (runtime.IsTransitioning)
		{
			// Capture previous normalized time for event detection (current/destination state only)
			let prevNormTime = runtime.CurrentTime;

			// Advance both states during transition
			AdvanceStateTime(currentState, ref runtime.CurrentTime, deltaTime);

			if (runtime.PreviousStateIndex >= 0 && runtime.PreviousStateIndex < layer.States.Count)
			{
				let prevState = layer.States[runtime.PreviousStateIndex];
				AdvanceStateTime(prevState, ref runtime.PreviousTime, deltaTime);
			}

			// Fire events for the destination state
			if (mEventHandler != null && currentState.Node != null)
				currentState.Node.FireEvents(prevNormTime, runtime.CurrentTime, currentState.Loop, mEventHandler);

			// Advance transition
			runtime.TransitionElapsed += deltaTime;

			if (runtime.TransitionElapsed >= runtime.TransitionDuration)
			{
				// Transition complete
				runtime.IsTransitioning = false;
				runtime.PreviousStateIndex = -1;
			}
		}
		else
		{
			let prevNormTime = runtime.CurrentTime;
			AdvanceStateTime(currentState, ref runtime.CurrentTime, deltaTime);

			// Fire events for the current state
			if (mEventHandler != null && currentState.Node != null)
				currentState.Node.FireEvents(prevNormTime, runtime.CurrentTime, currentState.Loop, mEventHandler);
		}

		// Sample poses
		SampleLayerPoses(layer, runtime);
	}

	/// Advances normalized time for a state, handling looping.
	private void AdvanceStateTime(AnimationGraphState state, ref float normalizedTime, float deltaTime)
	{
		if (state.Duration <= 0)
			return;

		let normalizedDelta = (deltaTime * state.Speed) / state.Duration;
		normalizedTime += normalizedDelta;

		if (state.Loop)
		{
			while (normalizedTime >= 1.0f)
				normalizedTime -= 1.0f;
			while (normalizedTime < 0.0f)
				normalizedTime += 1.0f;
		}
		else
		{
			normalizedTime = Math.Clamp(normalizedTime, 0.0f, 1.0f);
		}
	}

	/// Evaluates transitions for a layer and starts the highest-priority valid one.
	private void EvaluateTransitions(AnimationLayer layer, AnimationGraphLayerRuntime runtime)
	{
		AnimationGraphTransition bestTransition = null;
		int32 bestPriority = int32.MaxValue;

		for (let transition in layer.Transitions)
		{
			// Check source state matches (-1 = Any State)
			if (transition.SourceStateIndex != -1 && transition.SourceStateIndex != runtime.CurrentStateIndex)
				continue;

			// Don't transition to self (unless from Any State)
			if (transition.SourceStateIndex != -1 && transition.DestStateIndex == runtime.CurrentStateIndex)
				continue;

			// Check exit time gate
			if (transition.HasExitTime && runtime.CurrentTime < transition.ExitTime)
				continue;

			// Check conditions
			if (!transition.EvaluateConditions(mParameters))
				continue;

			// Pick highest priority (lowest number)
			if (transition.Priority < bestPriority)
			{
				bestPriority = transition.Priority;
				bestTransition = transition;
			}
		}

		if (bestTransition != null)
		{
			// Start transition
			runtime.PreviousStateIndex = runtime.CurrentStateIndex;
			runtime.PreviousTime = runtime.CurrentTime;
			runtime.CurrentStateIndex = bestTransition.DestStateIndex;
			runtime.CurrentTime = 0;
			runtime.TransitionElapsed = 0;
			runtime.TransitionDuration = Math.Max(bestTransition.Duration, 0.001f);
			runtime.IsTransitioning = true;
		}
	}

	/// Samples the poses for a layer, handling cross-fade if transitioning.
	private void SampleLayerPoses(AnimationLayer layer, AnimationGraphLayerRuntime runtime)
	{
		if (runtime.CurrentStateIndex < 0)
			return;

		let currentState = layer.GetState(runtime.CurrentStateIndex);
		if (currentState?.Node == null)
			return;

		if (runtime.IsTransitioning && runtime.PreviousStateIndex >= 0)
		{
			let prevState = layer.GetState(runtime.PreviousStateIndex);
			if (prevState?.Node != null)
			{
				// Sample both states
				prevState.Node.Evaluate(mSkeleton, runtime.PreviousTime, runtime.PrevPoses);
				currentState.Node.Evaluate(mSkeleton, runtime.CurrentTime, runtime.Poses);

				// Cross-fade blend
				let blendFactor = Math.Clamp(runtime.TransitionElapsed / runtime.TransitionDuration, 0.0f, 1.0f);
				AnimationSampler.BlendPoses(runtime.PrevPoses, runtime.Poses, blendFactor, runtime.Poses);
				return;
			}
		}

		// No transition - just sample current state
		currentState.Node.Evaluate(mSkeleton, runtime.CurrentTime, runtime.Poses);
	}

	/// Pushes runtime parameter values into linked blend tree nodes.
	private void SyncBlendTreeParameters()
	{
		for (let link in mBlendTree1DLinks)
			SyncBlendTree1D(link.Tree, link.ParameterIndex);
		for (let link in mBlendTree2DLinks)
			SyncBlendTree2D(link.Tree, link.ParameterIndexX, link.ParameterIndexY);
	}

	/// Syncs a 1D blend tree's parameter from a graph parameter.
	public void SyncBlendTree1D(BlendTree1D tree, int32 parameterIndex)
	{
		if (tree != null && parameterIndex >= 0 && parameterIndex < mParameters.Count)
			tree.Parameter = mParameters[parameterIndex].FloatValue;
	}

	/// Syncs a 2D blend tree's parameters from graph parameters.
	public void SyncBlendTree2D(BlendTree2D tree, int32 parameterIndexX, int32 parameterIndexY)
	{
		if (tree == null)
			return;

		if (parameterIndexX >= 0 && parameterIndexX < mParameters.Count)
			tree.ParameterX = mParameters[parameterIndexX].FloatValue;
		if (parameterIndexY >= 0 && parameterIndexY < mParameters.Count)
			tree.ParameterY = mParameters[parameterIndexY].FloatValue;
	}

	/// Registers a 1D blend tree to auto-sync with a parameter by index.
	/// Call this after setting up the graph to establish the link.
	public void LinkBlendTree1D(BlendTree1D tree, int32 parameterIndex)
	{
		if (tree == null || parameterIndex < 0)
			return;

		// Store the mapping
		mBlendTree1DLinks.Add(.(tree, parameterIndex));
	}

	/// Registers a 2D blend tree to auto-sync with parameters by index.
	public void LinkBlendTree2D(BlendTree2D tree, int32 parameterIndexX, int32 parameterIndexY)
	{
		if (tree == null)
			return;

		mBlendTree2DLinks.Add(.(tree, parameterIndexX, parameterIndexY));
	}

	private struct BlendTree1DLink
	{
		public BlendTree1D Tree;
		public int32 ParameterIndex;

		public this(BlendTree1D tree, int32 paramIndex)
		{
			Tree = tree;
			ParameterIndex = paramIndex;
		}
	}

	private struct BlendTree2DLink
	{
		public BlendTree2D Tree;
		public int32 ParameterIndexX;
		public int32 ParameterIndexY;

		public this(BlendTree2D tree, int32 paramIndexX, int32 paramIndexY)
		{
			Tree = tree;
			ParameterIndexX = paramIndexX;
			ParameterIndexY = paramIndexY;
		}
	}

	private List<BlendTree1DLink> mBlendTree1DLinks = new .() ~ delete _;
	private List<BlendTree2DLink> mBlendTree2DLinks = new .() ~ delete _;

	/// Combines all layer outputs into the final pose.
	private void CombineLayers()
	{
		if (mLayerRuntimes.Count == 0)
			return;

		// Layer 0 = base layer (writes directly to final poses)
		if (mLayerRuntimes.Count > 0)
		{
			let baseRuntime = mLayerRuntimes[0];
			for (int i = 0; i < mFinalPoses.Count && i < baseRuntime.Poses.Count; i++)
				mFinalPoses[i] = baseRuntime.Poses[i];
		}

		// Additional layers blend on top
		for (int layerIdx = 1; layerIdx < mLayerRuntimes.Count && layerIdx < mGraph.Layers.Count; layerIdx++)
		{
			let layer = mGraph.Layers[layerIdx];
			let runtime = mLayerRuntimes[layerIdx];

			if (layer.Weight <= 0)
				continue;

			switch (layer.BlendMode)
			{
			case .Override:
				for (int b = 0; b < mFinalPoses.Count && b < runtime.Poses.Count; b++)
				{
					let maskWeight = layer.Mask != null ? layer.Mask.GetWeight((int32)b) : 1.0f;
					let effectiveWeight = layer.Weight * maskWeight;

					if (effectiveWeight > 0)
						mFinalPoses[b] = BoneTransform.Lerp(mFinalPoses[b], runtime.Poses[b], effectiveWeight);
				}

			case .Additive:
				// Compute delta from bind pose and apply additively
				for (int b = 0; b < mFinalPoses.Count && b < runtime.Poses.Count; b++)
				{
					let maskWeight = layer.Mask != null ? layer.Mask.GetWeight((int32)b) : 1.0f;
					let effectiveWeight = layer.Weight * maskWeight;

					if (effectiveWeight > 0)
					{
						let bone = mSkeleton.GetBone((int32)b);
						let bindPose = bone != null ? bone.LocalBindPose : BoneTransform.Identity;

						// Delta = layer pose - bind pose (applied additively)
						let deltaPos = runtime.Poses[b].Position - bindPose.Position;
						let deltaRot = runtime.Poses[b].Rotation * Quaternion.Inverse(bindPose.Rotation);
						let deltaScale = runtime.Poses[b].Scale / bindPose.Scale;

						mFinalPoses[b].Position = mFinalPoses[b].Position + deltaPos * effectiveWeight;
						mFinalPoses[b].Rotation = Quaternion.Slerp(.Identity, deltaRot, effectiveWeight) * mFinalPoses[b].Rotation;
						mFinalPoses[b].Scale = mFinalPoses[b].Scale * Vector3.Lerp(.One, deltaScale, effectiveWeight);
					}
				}
			}
		}
	}

	// ==================== Output ====================

	/// Returns the current animation pose as a view.
	public AnimationPose GetPose()
	{
		return .(mFinalPoses);
	}

	/// Gets the current skinning matrices for GPU upload.
	public Span<Matrix> GetSkinningMatrices()
	{
		if (mMatricesDirty)
		{
			mSkeleton.ComputeSkinningMatrices(mFinalPoses, mSkinningMatrices);
			mMatricesDirty = false;
		}
		return mSkinningMatrices;
	}

	/// Gets the previous frame's skinning matrices for motion blur.
	public Span<Matrix> GetPrevSkinningMatrices()
	{
		return mPrevSkinningMatrices;
	}

	/// Gets the current local bone transforms.
	public Span<BoneTransform> GetLocalPoses()
	{
		return mFinalPoses;
	}

	// ==================== State Query ====================

	/// Gets the current state index for a layer.
	public int32 GetCurrentStateIndex(int32 layerIndex = 0)
	{
		if (layerIndex >= 0 && layerIndex < mLayerRuntimes.Count)
			return mLayerRuntimes[layerIndex].CurrentStateIndex;
		return -1;
	}

	/// Gets the current state name for a layer.
	public StringView GetCurrentStateName(int32 layerIndex = 0)
	{
		if (layerIndex >= 0 && layerIndex < mLayerRuntimes.Count && layerIndex < mGraph.Layers.Count)
		{
			let runtime = mLayerRuntimes[layerIndex];
			let state = mGraph.Layers[layerIndex].GetState(runtime.CurrentStateIndex);
			if (state != null)
				return state.Name;
		}
		return default;
	}

	/// Gets whether a layer is currently transitioning.
	public bool IsTransitioning(int32 layerIndex = 0)
	{
		if (layerIndex >= 0 && layerIndex < mLayerRuntimes.Count)
			return mLayerRuntimes[layerIndex].IsTransitioning;
		return false;
	}

	/// Gets the normalized time of the current state for a layer.
	public float GetCurrentNormalizedTime(int32 layerIndex = 0)
	{
		if (layerIndex >= 0 && layerIndex < mLayerRuntimes.Count)
			return mLayerRuntimes[layerIndex].CurrentTime;
		return 0;
	}

	/// Resets all poses to the skeleton's bind pose.
	public void ResetToBind()
	{
		for (int i = 0; i < mSkeleton.BoneCount; i++)
		{
			let bone = mSkeleton.Bones[i];
			if (bone != null)
				mFinalPoses[i] = bone.LocalBindPose;
			else
				mFinalPoses[i] = .Identity;
		}
		mMatricesDirty = true;
	}

	/// Forces transition to a specific state on the given layer.
	public void ForceState(int32 stateIndex, int32 layerIndex = 0)
	{
		if (layerIndex >= 0 && layerIndex < mLayerRuntimes.Count)
		{
			let runtime = mLayerRuntimes[layerIndex];
			runtime.CurrentStateIndex = stateIndex;
			runtime.CurrentTime = 0;
			runtime.IsTransitioning = false;
			runtime.PreviousStateIndex = -1;
		}
	}
}
