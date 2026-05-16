using System;
using System.IO;
using System.Collections;
using Sedulous.Resources;
using Sedulous.Serialization;
using Sedulous.Animation;

using static Sedulous.Resources.ResourceSerializerExtensions;

namespace Sedulous.Animation.Resources;

/// Node type identifiers for serialization.
enum AnimationStateNodeType : int32
{
	Clip = 0,
	BlendTree1D = 1,
	BlendTree2D = 2
}

/// Resource wrapping an AnimationGraph with full serialization support.
/// Clip references are stored as ResourceRefs on each state node and must be
/// resolved at runtime via ResolveClips() before the graph can be used.
class AnimationGraphResource : Resource
{
	public const int32 FileVersion = 1;
	public override ResourceType ResourceType => .("animationgraph");

	private AnimationGraph mGraph;
	private bool mOwnsGraph;

	/// Loaded clip resource handles (kept alive for the lifetime of this resource).
	private List<ResourceHandle<AnimationClipResource>> mClipHandles = new .() ~ {
		for (var h in _) h.Release();
		delete _;
	};

	/// The underlying animation graph.
	public AnimationGraph Graph => mGraph;

	public this()
	{
		mGraph = null;
		mOwnsGraph = false;
	}

	public this(AnimationGraph graph, bool ownsGraph = false)
	{
		mGraph = graph;
		mOwnsGraph = ownsGraph;
	}

	public ~this()
	{
		if (mOwnsGraph && mGraph != null)
			delete mGraph;
	}

	/// Sets the graph. Takes ownership if ownsGraph is true.
	public void SetGraph(AnimationGraph graph, bool ownsGraph = false)
	{
		if (mOwnsGraph && mGraph != null)
			delete mGraph;
		mGraph = graph;
		mOwnsGraph = ownsGraph;
	}

	/// Resolves clip ResourceRefs on each state node to actual AnimationClip pointers
	/// via the resource system. Call this after loading and before creating a player.
	public bool ResolveClips(ResourceSystem resourceSystem)
	{
		if (resourceSystem == null || mGraph == null)
			return false;

		// Clear any previous handles
		for (var h in mClipHandles)
			h.Release();
		mClipHandles.Clear();

		bool allResolved = true;

		for (let layer in mGraph.Layers)
		{
			for (let state in layer.States)
			{
				if (let clipNode = state.Node as ClipStateNode)
				{
					if (clipNode.ClipRef.IsValid)
					{
						if (resourceSystem.LoadByRef<AnimationClipResource>(clipNode.ClipRef) case .Ok(let handle))
						{
							clipNode.Clip = handle.Resource?.Clip;
							mClipHandles.Add(handle);
						}
						else
							allResolved = false;
					}
				}
				else if (let blend1D = state.Node as BlendTree1D)
				{
					for (let entry in blend1D.Entries)
					{
						if (entry.ClipRef.IsValid)
						{
							if (resourceSystem.LoadByRef<AnimationClipResource>(entry.ClipRef) case .Ok(let handle))
							{
								entry.Clip = handle.Resource?.Clip;
								mClipHandles.Add(handle);
							}
							else
								allResolved = false;
						}
					}
				}
				else if (let blend2D = state.Node as BlendTree2D)
				{
					for (let entry in blend2D.Entries)
					{
						if (entry.ClipRef.IsValid)
						{
							if (resourceSystem.LoadByRef<AnimationClipResource>(entry.ClipRef) case .Ok(let handle))
							{
								entry.Clip = handle.Resource?.Clip;
								mClipHandles.Add(handle);
							}
							else
								allResolved = false;
						}
					}
				}
			}
		}

		return allResolved;
	}

	// ---- Hot-reload ----

	/// In-place reload: clears existing graph state and clip handles, then re-reads.
	/// The AnimationGraph object itself stays alive (same pointer), so any
	/// AnimationGraphPlayer holding it won't get a dangling reference.
	/// Players must be recreated after reload (detected via Generation counter).
	public override Result<void, ResourceLoadError> Reload(Serializer s)
	{
		if (mGraph == null)
			return .Err(.InvalidFormat);

		// Clear existing graph state (parameters, layers, states, transitions)
		mGraph.ClearForReload();

		// Release clip handles from previous load
		for (var h in mClipHandles)
			h.Release();
		mClipHandles.Clear();

		// Re-read
		let result = Serialize(s);
		if (result != .Ok)
			return .Err(.InvalidFormat);

		return .Ok;
	}

	// ---- Serialization ----

	public override int32 SerializationVersion => FileVersion;

	protected override SerializationResult OnSerialize(Serializer s)
	{
		if (s.IsWriting)
			return SerializeWrite(s);
		else
			return SerializeRead(s);
	}

	private SerializationResult SerializeWrite(Serializer s)
	{
		if (mGraph == null)
			return .InvalidData;

		// Parameters
		int32 paramCount = (int32)mGraph.Parameters.Count;
		s.Int32("parameterCount", ref paramCount);

		if (paramCount > 0)
		{
			s.BeginObject("parameters");
			for (int32 i = 0; i < paramCount; i++)
			{
				let param = mGraph.Parameters[i];
				s.BeginObject(scope $"p{i}");

				String name = scope String(param.Name);
				s.String("name", name);

				int32 type = (int32)param.Type;
				s.Int32("type", ref type);

				float fVal = param.FloatValue;
				s.Float("floatValue", ref fVal);

				int32 iVal = param.IntValue;
				s.Int32("intValue", ref iVal);

				bool bVal = param.BoolValue;
				s.Bool("boolValue", ref bVal);

				s.EndObject();
			}
			s.EndObject();
		}

		// Layers
		int32 layerCount = (int32)mGraph.Layers.Count;
		s.Int32("layerCount", ref layerCount);

		if (layerCount > 0)
		{
			s.BeginObject("layers");
			for (int32 li = 0; li < layerCount; li++)
			{
				let layer = mGraph.Layers[li];
				s.BeginObject(scope $"l{li}");

				String layerName = scope String(layer.Name);
				s.String("name", layerName);

				int32 blendMode = (int32)layer.BlendMode;
				s.Int32("blendMode", ref blendMode);

				float weight = layer.Weight;
				s.Float("weight", ref weight);

				int32 defaultState = layer.DefaultStateIndex;
				s.Int32("defaultState", ref defaultState);

				// Bone mask
				bool hasMask = layer.Mask != null;
				s.Bool("hasMask", ref hasMask);

				if (hasMask && layer.Mask != null)
				{
					s.BeginObject("mask");
					int32 boneCount = layer.Mask.BoneCount;
					s.Int32("boneCount", ref boneCount);

					float[] weights = scope float[boneCount];
					for (int32 b = 0; b < boneCount; b++)
						weights[b] = layer.Mask.GetWeight(b);
					s.FixedFloatArray("weights", &weights[0], boneCount);

					s.EndObject();
				}

				// States
				int32 stateCount = (int32)layer.States.Count;
				s.Int32("stateCount", ref stateCount);

				if (stateCount > 0)
				{
					s.BeginObject("states");
					for (int32 si = 0; si < stateCount; si++)
					{
						let state = layer.States[si];
						s.BeginObject(scope $"s{si}");

						String stateName = scope String(state.Name);
						s.String("name", stateName);

						float speed = state.Speed;
						s.Float("speed", ref speed);

						bool loop = state.Loop;
						s.Bool("loop", ref loop);

						// Node type
						int32 nodeType;
						if (state.Node is BlendTree1D)
							nodeType = (int32)AnimationStateNodeType.BlendTree1D;
						else if (state.Node is BlendTree2D)
							nodeType = (int32)AnimationStateNodeType.BlendTree2D;
						else
							nodeType = (int32)AnimationStateNodeType.Clip;
						s.Int32("nodeType", ref nodeType);

						WriteNode(s, state.Node);

						s.EndObject();
					}
					s.EndObject();
				}

				// Transitions
				int32 transCount = (int32)layer.Transitions.Count;
				s.Int32("transitionCount", ref transCount);

				if (transCount > 0)
				{
					s.BeginObject("transitions");
					for (int32 ti = 0; ti < transCount; ti++)
					{
						let trans = layer.Transitions[ti];
						s.BeginObject(scope $"t{ti}");

						int32 srcState = trans.SourceStateIndex;
						s.Int32("sourceState", ref srcState);

						int32 dstState = trans.DestStateIndex;
						s.Int32("destState", ref dstState);

						float duration = trans.Duration;
						s.Float("duration", ref duration);

						bool hasExitTime = trans.HasExitTime;
						s.Bool("hasExitTime", ref hasExitTime);

						float exitTime = trans.ExitTime;
						s.Float("exitTime", ref exitTime);

						int32 priority = trans.Priority;
						s.Int32("priority", ref priority);

						// Conditions
						int32 condCount = (int32)trans.Conditions.Count;
						s.Int32("conditionCount", ref condCount);

						if (condCount > 0)
						{
							s.BeginObject("conditions");
							for (int32 ci = 0; ci < condCount; ci++)
							{
								let cond = trans.Conditions[ci];
								s.BeginObject(scope $"c{ci}");

								int32 paramIdx = cond.ParameterIndex;
								s.Int32("paramIndex", ref paramIdx);

								int32 op = (int32)cond.Op;
								s.Int32("op", ref op);

								float threshold = cond.Threshold;
								s.Float("threshold", ref threshold);

								s.EndObject();
							}
							s.EndObject();
						}

						s.EndObject();
					}
					s.EndObject();
				}

				s.EndObject();
			}
			s.EndObject();
		}

		return .Ok;
	}

	private void WriteNode(Serializer s, IAnimationStateNode node)
	{
		if (let clipNode = node as ClipStateNode)
		{
			s.BeginObject("clipNode");
			var clipRef = clipNode.ClipRef;
			s.ResourceRef("clipRef", ref clipRef);
			s.EndObject();
		}
		else if (let blend1D = node as BlendTree1D)
		{
			s.BeginObject("blendTree1D");

			int32 entryCount = (int32)blend1D.Entries.Count;
			s.Int32("entryCount", ref entryCount);

			for (int32 ei = 0; ei < entryCount; ei++)
			{
				s.BeginObject(scope $"e{ei}");

				float threshold = blend1D.Entries[ei].Threshold;
				s.Float("threshold", ref threshold);

				var clipRef = blend1D.Entries[ei].ClipRef;
				s.ResourceRef("clipRef", ref clipRef);

				s.EndObject();
			}

			s.EndObject();
		}
		else if (let blend2D = node as BlendTree2D)
		{
			s.BeginObject("blendTree2D");

			int32 entryCount = (int32)blend2D.Entries.Count;
			s.Int32("entryCount", ref entryCount);

			for (int32 ei = 0; ei < entryCount; ei++)
			{
				s.BeginObject(scope $"e{ei}");

				float posX = blend2D.Entries[ei].Position.X;
				s.Float("posX", ref posX);

				float posY = blend2D.Entries[ei].Position.Y;
				s.Float("posY", ref posY);

				var clipRef = blend2D.Entries[ei].ClipRef;
				s.ResourceRef("clipRef", ref clipRef);

				s.EndObject();
			}

			s.EndObject();
		}
	}

	private SerializationResult SerializeRead(Serializer s)
	{
		// Reuse existing graph on reload (in-place hot-reload pattern).
		// On first load mGraph is null, so we create a new one.
		let graph = (mGraph != null) ? mGraph : new AnimationGraph();

		// Parameters
		int32 paramCount = 0;
		s.Int32("parameterCount", ref paramCount);

		if (paramCount > 0)
		{
			s.BeginObject("parameters");
			for (int32 i = 0; i < paramCount; i++)
			{
				s.BeginObject(scope $"p{i}");

				String name = scope String();
				s.String("name", name);

				int32 type = 0;
				s.Int32("type", ref type);

				let param = new AnimationGraphParameter(name, (AnimationParameterType)type);

				float fVal = 0;
				s.Float("floatValue", ref fVal);
				param.FloatValue = fVal;

				int32 iVal = 0;
				s.Int32("intValue", ref iVal);
				param.IntValue = iVal;

				bool bVal = false;
				s.Bool("boolValue", ref bVal);
				param.BoolValue = bVal;

				graph.Parameters.Add(param);

				s.EndObject();
			}
			s.EndObject();
		}

		// Layers
		int32 layerCount = 0;
		s.Int32("layerCount", ref layerCount);

		if (layerCount > 0)
		{
			s.BeginObject("layers");
			for (int32 li = 0; li < layerCount; li++)
			{
				s.BeginObject(scope $"l{li}");

				String layerName = scope String();
				s.String("name", layerName);

				int32 blendMode = 0;
				s.Int32("blendMode", ref blendMode);

				float weight = 1.0f;
				s.Float("weight", ref weight);

				int32 defaultState = 0;
				s.Int32("defaultState", ref defaultState);

				let layer = new AnimationLayer(layerName);
				layer.BlendMode = (LayerBlendMode)blendMode;
				layer.Weight = weight;
				layer.DefaultStateIndex = defaultState;

				// Bone mask
				bool hasMask = false;
				s.Bool("hasMask", ref hasMask);

				if (hasMask)
				{
					s.BeginObject("mask");

					int32 boneCount = 0;
					s.Int32("boneCount", ref boneCount);

					let mask = new BoneMask(boneCount, 0.0f);
					float[] weights = scope float[boneCount];
					s.FixedFloatArray("weights", &weights[0], boneCount);
					for (int32 b = 0; b < boneCount; b++)
						mask.SetWeight(b, weights[b]);

					layer.Mask = mask;
					layer.OwnsMask = true;

					s.EndObject();
				}

				// States
				int32 stateCount = 0;
				s.Int32("stateCount", ref stateCount);

				if (stateCount > 0)
				{
					s.BeginObject("states");
					for (int32 si = 0; si < stateCount; si++)
					{
						s.BeginObject(scope $"s{si}");

						String stateName = scope String();
						s.String("name", stateName);

						float speed = 1.0f;
						s.Float("speed", ref speed);

						bool loop = true;
						s.Bool("loop", ref loop);

						int32 nodeType = 0;
						s.Int32("nodeType", ref nodeType);

						IAnimationStateNode node = ReadNode(s, (AnimationStateNodeType)nodeType);

						let state = new AnimationGraphState(stateName, node, ownsNode: true);
						state.Speed = speed;
						state.Loop = loop;
						layer.AddState(state);

						s.EndObject();
					}
					s.EndObject();
				}

				// Transitions
				int32 transCount = 0;
				s.Int32("transitionCount", ref transCount);

				if (transCount > 0)
				{
					s.BeginObject("transitions");
					for (int32 ti = 0; ti < transCount; ti++)
					{
						s.BeginObject(scope $"t{ti}");

						let trans = new AnimationGraphTransition();

						int32 srcState = -1;
						s.Int32("sourceState", ref srcState);
						trans.SourceStateIndex = srcState;

						int32 dstState = 0;
						s.Int32("destState", ref dstState);
						trans.DestStateIndex = dstState;

						float duration = 0.25f;
						s.Float("duration", ref duration);
						trans.Duration = duration;

						bool hasExitTime = false;
						s.Bool("hasExitTime", ref hasExitTime);
						trans.HasExitTime = hasExitTime;

						float exitTime = 1.0f;
						s.Float("exitTime", ref exitTime);
						trans.ExitTime = exitTime;

						int32 priority = 0;
						s.Int32("priority", ref priority);
						trans.Priority = priority;

						// Conditions
						int32 condCount = 0;
						s.Int32("conditionCount", ref condCount);

						if (condCount > 0)
						{
							s.BeginObject("conditions");
							for (int32 ci = 0; ci < condCount; ci++)
							{
								s.BeginObject(scope $"c{ci}");

								int32 paramIdx = 0;
								s.Int32("paramIndex", ref paramIdx);

								int32 op = 0;
								s.Int32("op", ref op);

								float threshold = 0;
								s.Float("threshold", ref threshold);

								trans.Conditions.Add(.(paramIdx, (ComparisonOp)op, threshold));

								s.EndObject();
							}
							s.EndObject();
						}

						layer.AddTransition(trans);

						s.EndObject();
					}
					s.EndObject();
				}

				graph.AddLayer(layer);

				s.EndObject();
			}
			s.EndObject();
		}

		// On first load, set ownership. On reload, mGraph == graph so skip SetGraph
		// to avoid deleting the graph we just repopulated.
		if (mGraph != graph)
			SetGraph(graph, true);
		return .Ok;
	}

	private IAnimationStateNode ReadNode(Serializer s, AnimationStateNodeType nodeType)
	{
		switch (nodeType)
		{
		case .Clip:
			s.BeginObject("clipNode");
			var clipRef = ResourceRef();
			s.ResourceRef("clipRef", ref clipRef);
			s.EndObject();
			let node = new ClipStateNode(null, clipRef);
			clipRef.Dispose();
			return node;

		case .BlendTree1D:
			s.BeginObject("blendTree1D");
			int32 entryCount = 0;
			s.Int32("entryCount", ref entryCount);

			let blend1D = new BlendTree1D();
			for (int32 ei = 0; ei < entryCount; ei++)
			{
				s.BeginObject(scope $"e{ei}");

				float threshold = 0;
				s.Float("threshold", ref threshold);

				var clipRef1D = ResourceRef();
				s.ResourceRef("clipRef", ref clipRef1D);

				blend1D.AddEntry(threshold, null, clipRef1D);
				clipRef1D.Dispose();

				s.EndObject();
			}
			s.EndObject();
			return blend1D;

		case .BlendTree2D:
			s.BeginObject("blendTree2D");
			int32 entryCount2D = 0;
			s.Int32("entryCount", ref entryCount2D);

			let blend2D = new BlendTree2D();
			for (int32 ei = 0; ei < entryCount2D; ei++)
			{
				s.BeginObject(scope $"e{ei}");

				float posX = 0;
				s.Float("posX", ref posX);

				float posY = 0;
				s.Float("posY", ref posY);

				var clipRef2D = ResourceRef();
				s.ResourceRef("clipRef", ref clipRef2D);

				blend2D.AddEntry(posX, posY, null, clipRef2D);
				clipRef2D.Dispose();

				s.EndObject();
			}
			s.EndObject();
			return blend2D;
		}
	}

}
