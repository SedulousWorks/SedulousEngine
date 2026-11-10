using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Animation;
using Sedulous.Animation.Resource;
using Sedulous.Animation.Pipeline;
using Sedulous.GUI;

namespace Sedulous.Editor.Animation;

// An animation graph as a graph view reads it, no
// widget of its own. AnimationGraphStates is a graph source over one layer of an AnimationGraphAsset:
// its states are the nodes, and Any State a node of its own that only begins a transition; its
// transitions are node links (a state machine's, which the view draws as arrows between borders);
// where each sits is the asset's, as the old page kept it. Ids stay with what they name while states
// and transitions come and go (the asset addresses both by place, and a removal shifts the rest), so
// a view's selection survives an edit.
//
// Every change is one edit of the whole asset, through the page's Edit (its undo step); a move is a
// gesture, previewed in the asset and taken as one step when it ends. A state deleted takes its
// transitions with it and moves the indices after it down; a layer keeps one state. The graph edits
// that are not the view's (a layer or a parameter added or removed, the layout squared to the states)
// are AnimationGraphEdits', so the page's lists share them: a parameter removed takes the conditions
// on it away and clears the blend drivers that read it, those after it moving down.
//
// Sedulous-side: the asset's source is flat (parallel arrays with index runs); every edit goes
// through a GraphDocument loaded from it and stored back, and the source reads a document of its own,
// loaded again on each Refresh.

/// The node kinds a state may have, as the asset keeps them (GraphState.NodeKind).
enum AnimationStateKind : uint8
{
	Clip = 0,
	Blend1D = 1,
	Blend2D = 2,
}

/// The graph edits the page's lists and the graph source share, each on the whole asset.
static class AnimationGraphEdits
{
	/// `mutate` over the asset's source as nested objects (a document loaded from it), stored back.
	public static void Edit(AnimationGraphAsset asset, delegate void(GraphDocument doc) mutate)
	{
		let doc = scope GraphDocument();
		doc.Load(asset.Source);
		mutate(doc);
		doc.Store(asset.Source);
	}

	/// Every layer's positions as many as its states (a new state placed beside the last), and one
	/// Any State place per layer.
	public static void SquareLayout(AnimationGraphAsset asset)
	{
		let doc = scope GraphDocument();
		doc.Load(asset.Source);
		SquareLayout(asset, doc);
	}

	/// The same against `doc`, the asset's source as it is being edited.
	public static void SquareLayout(AnimationGraphAsset asset, GraphDocument doc)
	{
		let layouts = asset.LayerLayouts;
		while (layouts.Count < doc.Layers.Count)
		{
			let layout = new AnimationGraphLayerLayout();
			layout.AnyStatePosition = .(40.0f, 40.0f);
			layouts.Add(layout);
		}
		while (layouts.Count > doc.Layers.Count)
		{
			delete layouts[layouts.Count - 1];
			layouts.RemoveAt(layouts.Count - 1);
		}
		for (int l < doc.Layers.Count)
		{
			let positions = layouts[l].StatePositions;
			// A state with no place yet fans out to the right, five to a row.
			while (positions.Count < doc.Layers[l].States.Count)
				positions.Add(.(240.0f + 200.0f * (float)(positions.Count % 5), 90.0f + 110.0f * (float)(positions.Count / 5)));
			while (positions.Count > doc.Layers[l].States.Count)
				positions.RemoveAt(positions.Count - 1);
		}
	}

	/// A name among the layer's states not taken: `base`, else `base 2`, `base 3`..., appended.
	public static void UniqueStateName(GraphLayer layer, StringView @base, String outName)
	{
		Unique(@base, scope (name) =>
			{
				for (let state in layer.States)
				{
					if (state.Name == name)
						return true;
				}
				return false;
			}, outName);
	}

	/// Adds a state of `kind` named `name` at `at` to `layer`; its index (-1: no such layer).
	public static int32 AddState(AnimationGraphAsset asset, int32 layer, StringView name, AnimationStateKind kind, Float2 at)
	{
		int32 made = -1;
		Edit(asset, scope [&] (doc) => { made = AddState(asset, doc, layer, name, kind, at); });
		return made;
	}

	public static int32 AddState(AnimationGraphAsset asset, GraphDocument doc, int32 layer, StringView name, AnimationStateKind kind, Float2 at)
	{
		let data = doc.Layer(layer);
		if (data == null)
			return -1;
		SquareLayout(asset, doc);
		data.AddState(UniqueStateName(data, name, .. scope String()), (uint8)kind);
		asset.LayerLayouts[layer].StatePositions.Add(at);
		return (int32)data.States.Count - 1;
	}

	/// Removes `state` from `layer`: its transitions with it, the indices after it moved down (the
	/// transitions', the default state's, the positions'). False when it is the last.
	public static bool RemoveState(AnimationGraphAsset asset, int32 layer, int32 state)
	{
		bool removed = false;
		Edit(asset, scope [&] (doc) => { removed = RemoveState(asset, doc, layer, state); });
		return removed;
	}

	public static bool RemoveState(AnimationGraphAsset asset, GraphDocument doc, int32 layer, int32 state)
	{
		let data = doc.Layer(layer);
		if ((data == null) || !data.HasState(state) || (data.States.Count <= 1))
			return false;
		SquareLayout(asset, doc);
		data.DeleteState(state);
		asset.LayerLayouts[layer].StatePositions.RemoveAt(state);
		return true;
	}

	/// Adds a parameter of `type` named `name` (made unique); its index.
	public static int32 AddParameter(AnimationGraphAsset asset, StringView name, AnimationParameterType type)
	{
		int32 made = -1;
		Edit(asset, scope [&] (doc) =>
			{
				let unique = Unique(name, scope (candidate) =>
					{
						for (let taken in doc.Params)
						{
							if (taken.Name == candidate)
								return true;
						}
						return false;
					}, .. scope String());
				doc.AddParam(unique, (uint8)type);
				made = (int32)doc.Params.Count - 1;
			});
		return made;
	}

	/// Removes `parameter`: conditions on it go, blend drivers reading it clear, those after it move
	/// down.
	public static bool RemoveParameter(AnimationGraphAsset asset, int32 parameter)
	{
		bool removed = false;
		Edit(asset, scope [&] (doc) => { removed = doc.RemoveParam(parameter); });
		return removed;
	}

	/// Adds a layer named `name` (made unique) with one clip state; its index.
	public static int32 AddLayer(AnimationGraphAsset asset, StringView name)
	{
		int32 made = -1;
		Edit(asset, scope [&] (doc) =>
			{
				SquareLayout(asset, doc);
				let unique = Unique(name, scope (candidate) =>
					{
						for (let taken in doc.Layers)
						{
							if (taken.Name == candidate)
								return true;
						}
						return false;
					}, .. scope String());
				let layer = doc.AddLayer(unique);
				layer.AddState("State", (uint8)AnimationStateKind.Clip);
				SquareLayout(asset, doc);
				made = (int32)doc.Layers.Count - 1;
			});
		return made;
	}

	/// Removes `layer` and its places; false when it is the last.
	public static bool RemoveLayer(AnimationGraphAsset asset, int32 layer)
	{
		bool removed = false;
		Edit(asset, scope [&] (doc) =>
			{
				if (!doc.HasLayer(layer) || (doc.Layers.Count <= 1))
					return;
				SquareLayout(asset, doc);
				doc.RemoveLayer(layer);
				delete asset.LayerLayouts[layer];
				asset.LayerLayouts.RemoveAt(layer);
				removed = true;
			});
		return removed;
	}

	// `base`, else `base 2`, `base 3`... the first `taken` says is free, appended to `outName`.
	private static void Unique(StringView @base, delegate bool(StringView name) taken, String outName)
	{
		if (!taken(@base))
		{
			outName.Append(@base);
			return;
		}
		let name = scope String();
		for (int n = 2;; n++)
		{
			name.Clear();
			name.AppendF("{} {}", @base, n);
			if (!taken(name))
			{
				outName.Append(name);
				return;
			}
		}
	}
}

/// A graph source over one layer of an animation graph asset (see the file's head).
class AnimationGraphStates : IGraphSource
{
	/// Any State's node id, in every layer.
	public const GraphId cAnyState = 1;

	private delegate AnimationGraphAsset() mAsset ~ delete _;
	private delegate void(StringView typeId, delegate void(AnimationGraphAsset asset) mutate) mEdit ~ delete _;
	/// The asset's source as read at the last Refresh.
	private GraphDocument mDoc = new .() ~ delete _;
	private int32 mLayer = 0;
	/// By state index, in the layer shown.
	private List<GraphId> mStateIds = new .() ~ delete _;
	/// By transition index.
	private List<GraphId> mTransitionIds = new .() ~ delete _;
	/// Any State, then the states.
	private List<GraphNodeInfo> mNodes = new .() ~ DeleteContainerAndItems!(_);
	private GraphId mNext = cAnyState + 1;
	private bool mMoving = false;
	/// A move's: Any State's place, then each state's.
	private List<Float2> mBefore = new .() ~ delete _;
	private delegate void(Guid clip, String outName) mNameOf ~ delete _;

	/// Over the asset `asset` returns (asked each time: an undo makes it anew), changed through `edit`
	/// (the page's undo step, `mutate` applied to the asset); without one, changed in place. TAKES
	/// OWNERSHIP of both.
	public this(delegate AnimationGraphAsset() asset, delegate void(StringView typeId, delegate void(AnimationGraphAsset asset) mutate) edit)
	{
		mAsset = asset;
		mEdit = edit;
		Refresh();
	}

	/// What a clip's guid is called on a state's node ("idle"), appended; unset: the guid unnamed.
	/// OWNERSHIP transfers.
	public void SetNameOf(delegate void(Guid clip, String outName) nameOf)
	{
		delete mNameOf;
		mNameOf = nameOf;
	}

	/// The layer it shows (kept within the asset's).
	public void SetLayer(int32 layer)
	{
		if (layer == mLayer)
			return;
		mLayer = layer;
		mStateIds.Clear(); // another layer's states: ids of their own
		mTransitionIds.Clear();
		Refresh();
	}

	public int32 Layer => mLayer;

	/// The asset changed behind it (an undo, an edit of the page's): read again, the ids kept by
	/// place where the counts still match.
	public void Refresh()
	{
		let asset = (mAsset != null) ? mAsset() : null;
		if (asset != null)
		{
			mDoc.Load(asset.Source);
			mLayer = Math.Clamp(mLayer, 0, Math.Max((int32)mDoc.Layers.Count - 1, 0));
			AnimationGraphEdits.SquareLayout(asset, mDoc); // a place for each state before one is drawn
		}
		else
			mDoc.Clear();
		let layer = LayerData;
		let states = (layer != null) ? layer.States.Count : 0;
		let transitions = (layer != null) ? layer.Transitions.Count : 0;
		// Kept by place: this source's own edits keep the tables in step before they change the asset;
		// another's (an undo) may leave a count off, made good at the end.
		while (mStateIds.Count > states)
			mStateIds.PopBack();
		while (mStateIds.Count < states)
			mStateIds.Add(Next());
		while (mTransitionIds.Count > transitions)
			mTransitionIds.PopBack();
		while (mTransitionIds.Count < transitions)
			mTransitionIds.Add(Next());
		Build();
		NotifyGraphChanged();
	}

	public GraphId StateId(int32 state) => ((state >= 0) && (state < mStateIds.Count)) ? mStateIds[state] : 0;

	/// A state's index by its node id (-1: Any State, or none).
	public int32 StateOf(GraphId node)
	{
		for (int s < mStateIds.Count)
		{
			if (mStateIds[s] == node)
				return (int32)s;
		}
		return -1;
	}

	public GraphId TransitionId(int32 transition) => ((transition >= 0) && (transition < mTransitionIds.Count)) ? mTransitionIds[transition] : 0;

	/// A transition's index by its link id (-1: none).
	public int32 TransitionOf(GraphId link)
	{
		for (int t < mTransitionIds.Count)
		{
			if (mTransitionIds[t] == link)
				return (int32)t;
		}
		return -1;
	}

	// === What there is ===

	public override void GetNodes(List<GraphId> outNodes)
	{
		outNodes.Clear();
		for (let node in mNodes)
			outNodes.Add(node.Id);
	}

	public override GraphNodeInfo GetNode(GraphId node)
	{
		for (let at in mNodes)
		{
			if (at.Id == node)
				return at;
		}
		return null;
	}

	public override void GetLinks(List<GraphLinkInfo> outLinks)
	{
		outLinks.Clear();
		let layer = LayerData;
		if (layer == null)
			return;
		for (int t = 0; (t < layer.Transitions.Count) && (t < mTransitionIds.Count); t++)
		{
			let transition = layer.Transitions[t];
			var link = GraphLinkInfo();
			link.Id = mTransitionIds[t];
			link.Kind = .Nodes;
			link.FromNode = (transition.Src < 0) ? cAnyState : StateId(transition.Src);
			link.ToNode = StateId(transition.Dst);
			if ((link.FromNode != 0) && (link.ToNode != 0))
				outLinks.Add(link);
		}
	}

	/// A state machine keeps none.
	public override void GetFrames(List<GraphFrameInfo> outFrames)
	{
		ClearAndDeleteItems!(outFrames);
	}

	// === Moving ===

	public override void BeginMove()
	{
		let layout = Layout;
		if (layout == null)
			return;
		mMoving = true;
		mBefore.Clear();
		mBefore.Add(layout.AnyStatePosition);
		mBefore.AddRange(layout.StatePositions);
	}

	public override void PreviewMove(Span<GraphId> nodes, Span<GraphId> frames, Float2 delta)
	{
		let layout = Layout;
		if (!mMoving || (layout == null))
			return;
		// Live in the asset, each from where it was when the move began.
		for (let id in nodes)
		{
			if (id == cAnyState)
			{
				layout.AnyStatePosition = mBefore[0] + delta;
				continue;
			}
			let s = StateOf(id);
			if ((s >= 0) && (s + 1 < mBefore.Count) && (s < layout.StatePositions.Count))
				layout.StatePositions[s] = mBefore[s + 1] + delta;
		}
		Build();
		NotifyGraphChanged();
	}

	public override void CommitMove()
	{
		let layout = Layout;
		if (!mMoving || (layout == null))
			return;
		mMoving = false;
		let l = mLayer;
		// The step's before is where the move began; its after, where it ended.
		let anyAfter = layout.AnyStatePosition;
		let statesAfter = scope List<Float2>();
		statesAfter.AddRange(layout.StatePositions);
		layout.AnyStatePosition = mBefore[0];
		for (int s = 0; (s < statesAfter.Count) && (s + 1 < mBefore.Count); s++)
			layout.StatePositions[s] = mBefore[s + 1];
		Change("move_animgraph_states", scope [&] (asset, doc) =>
			{
				let changed = asset.LayerLayouts[l];
				changed.AnyStatePosition = anyAfter;
				changed.StatePositions.Clear();
				changed.StatePositions.AddRange(statesAfter);
			});
	}

	public override void CancelMove()
	{
		let layout = Layout;
		if (!mMoving || (layout == null))
			return;
		mMoving = false;
		layout.AnyStatePosition = mBefore[0];
		for (int s = 0; (s < layout.StatePositions.Count) && (s + 1 < mBefore.Count); s++)
			layout.StatePositions[s] = mBefore[s + 1];
		Build();
		NotifyGraphChanged();
	}

	// === Transitions ===

	public override void CheckLink(GraphLinkInfo link, GraphLinkCheck outCheck)
	{
		outCheck.Clear();
		if (link.Kind != .Nodes)
		{
			outCheck.Reason.Set("A transition goes from a state to a state");
			return;
		}
		let fromAny = link.FromNode == cAnyState;
		if (!fromAny && (StateOf(link.FromNode) < 0))
		{
			outCheck.Reason.Set("Not a state of this layer");
			return;
		}
		if (link.ToNode == 0)
		{
			outCheck.Allowed = true; // one may begin here
			return;
		}
		if (link.ToNode == cAnyState)
		{
			outCheck.Reason.Set("Any State only begins transitions: nothing goes into it");
			return;
		}
		if (StateOf(link.ToNode) < 0)
		{
			outCheck.Reason.Set("Not a state of this layer");
			return;
		}
		if (link.ToNode == link.FromNode)
		{
			outCheck.Reason.Set("A state cannot go into itself: it is already there");
			return;
		}
		outCheck.Allowed = true;
	}

	public override GraphId Connect(GraphLinkInfo link)
	{
		if (!Allowed(link) || (link.ToNode == 0))
			return 0;
		let src = (link.FromNode == cAnyState) ? -1 : StateOf(link.FromNode);
		let dst = StateOf(link.ToNode);
		let layer = mLayer;
		let id = Next();
		mTransitionIds.Add(id); // in step before the asset changes
		Change("add_animgraph_transition", scope [&] (asset, doc) => { doc.Layers[layer].AddTransition((int32)src, (int32)dst); });
		return id;
	}

	public override bool Relink(GraphId link, GraphLinkInfo to)
	{
		let transition = TransitionOf(link);
		if ((transition < 0) || !Allowed(to) || (to.ToNode == 0))
			return false;
		let src = (to.FromNode == cAnyState) ? -1 : StateOf(to.FromNode);
		let dst = StateOf(to.ToNode);
		let layer = mLayer;
		Change("edit_animgraph_transition", scope [&] (asset, doc) =>
			{
				let changed = doc.Layers[layer].Transitions[transition];
				changed.Src = (int32)src;
				changed.Dst = (int32)dst;
			});
		return true;
	}

	public override bool Disconnect(Span<GraphId> links)
	{
		let gone = scope List<int32>();
		for (let link in links)
		{
			let t = TransitionOf(link);
			if (t >= 0)
				gone.Add(t);
		}
		if (gone.IsEmpty)
			return false;
		// Highest first, so each removal leaves the others' places as they were.
		gone.Sort(scope (a, b) => b <=> a);
		for (let t in gone)
			mTransitionIds.RemoveAt(t);
		let layer = mLayer;
		Change("remove_animgraph_transition", scope [&] (asset, doc) =>
			{
				for (let t in gone)
					doc.Layers[layer].RemoveTransition(t);
			});
		return true;
	}

	// === States ===

	public override bool DeleteNodes(Span<GraphId> nodes)
	{
		let layer = LayerData;
		if (layer == null)
			return false;
		let gone = scope List<int32>();
		for (let node in nodes)
		{
			let s = StateOf(node);
			if (s >= 0)
				gone.Add(s);
		}
		gone.Sort(scope (a, b) => b <=> a);
		// A layer keeps one state: the first of them stays when all were asked for.
		while (!gone.IsEmpty && (gone.Count >= layer.States.Count))
			gone.PopBack();
		if (gone.IsEmpty)
			return false;
		// The ids in step: the states', and the transitions' that go with them.
		for (int t = layer.Transitions.Count - 1; t >= 0; t--)
		{
			var goes = false;
			for (let s in gone)
				goes = goes || (layer.Transitions[t].Src == s) || (layer.Transitions[t].Dst == s);
			if (goes && (t < mTransitionIds.Count))
				mTransitionIds.RemoveAt(t);
		}
		for (let s in gone)
			mStateIds.RemoveAt(s);
		let index = mLayer;
		Change("remove_animgraph_state", scope [&] (asset, doc) =>
			{
				for (let s in gone)
					AnimationGraphEdits.RemoveState(asset, doc, index, s);
			});
		return true;
	}

	public override void GetNodeTypes(GraphId fittingPin, List<GraphNodeType> outTypes)
	{
		ClearAndDeleteItems!(outTypes);
		outTypes.Add(new GraphNodeType("clip", "Clip State", "States"));
		outTypes.Add(new GraphNodeType("blend1d", "Blend by One Parameter", "States"));
		outTypes.Add(new GraphNodeType("blend2d", "Blend by Two Parameters", "States"));
	}

	public override GraphId CreateNode(StringView type, Float2 at, GraphId linkFrom)
	{
		if (LayerData == null)
			return 0;
		AnimationStateKind kind;
		if (type == "blend1d")
			kind = .Blend1D;
		else if (type == "blend2d")
			kind = .Blend2D;
		else if (type == "clip")
			kind = .Clip;
		else
			return 0;
		StringView name = (kind == .Clip) ? "State" : "Blend";
		let index = mLayer;
		let id = Next();
		mStateIds.Add(id); // in step before the asset changes
		Change("add_animgraph_state", scope [&] (asset, doc) => { AnimationGraphEdits.AddState(asset, doc, index, name, kind, at); });
		return id;
	}

	public override GraphId CreateFrame(GraphFrameInfo frame) => 0;
	public override bool EditFrame(GraphFrameInfo frame) => false;
	public override bool DeleteFrames(Span<GraphId> frames) => false;

	// Copying states is not offered: a state copied without the transitions and parameters it reads
	// would say little, and the page's own Add makes one.
	public override void CopyNodes(Span<GraphId> nodes, String outText) { }
	public override bool PasteNodes(StringView text, Float2 at, List<GraphId> made) => false;

	// === Inside ===

	private GraphLayer LayerData => mDoc.Layer(mLayer);

	private AnimationGraphLayerLayout Layout
	{
		get
		{
			let asset = (mAsset != null) ? mAsset() : null;
			if ((asset == null) || (LayerData == null) || (mLayer >= asset.LayerLayouts.Count))
				return null;
			return asset.LayerLayouts[mLayer];
		}
	}

	private GraphId Next() => mNext++;

	private bool Allowed(GraphLinkInfo link)
	{
		let check = scope GraphLinkCheck();
		CheckLink(link, check);
		return check.Allowed;
	}

	private void Change(StringView typeId, delegate void(AnimationGraphAsset asset, GraphDocument doc) mutate)
	{
		let current = (mAsset != null) ? mAsset() : null;
		if (current == null)
			return;
		// Named as the edit hook's parameter: a delegate's parameter names are part of its type.
		delegate void(AnimationGraphAsset asset) apply = scope (asset) =>
			{
				AnimationGraphEdits.Edit(asset, scope (doc) => { mutate(asset, doc); });
			};
		if (mEdit != null)
			mEdit(typeId, apply); // the page's step; it refreshes this after
		else
			apply(current);
		Refresh();
	}

	private void Build()
	{
		ClearAndDeleteItems!(mNodes);
		let asset = (mAsset != null) ? mAsset() : null;
		let layer = LayerData;
		if ((asset == null) || (layer == null))
			return;
		let layout = (mLayer < asset.LayerLayouts.Count) ? asset.LayerLayouts[mLayer] : null;
		let any = new GraphNodeInfo();
		any.Id = cAnyState;
		any.Type.Set("any");
		any.Title.Set("Any State");
		any.Subtitle.Set("Its transitions start from every state");
		any.Position = (layout != null) ? layout.AnyStatePosition : .(40.0f, 40.0f);
		any.HeaderColor = .(0.42f, 0.43f, 0.5f, 1.0f);
		any.Deletable = false;
		mNodes.Add(any);
		for (int s < layer.States.Count)
		{
			let state = layer.States[s];
			let node = new GraphNodeInfo();
			node.Id = mStateIds[s];
			if (state.Name.IsEmpty)
				node.Title.AppendF("State {}", s + 1);
			else
				node.Title.Set(state.Name);
			switch ((AnimationStateKind)state.NodeKind)
			{
			case .Blend1D:
				node.Type.Set("blend1d");
				node.Subtitle.AppendF("Blends {} by {}", state.EntryClips.Count, ParameterName(state.ParamIndex));
			case .Blend2D:
				node.Type.Set("blend2d");
				node.Subtitle.AppendF("Blends {} by {} and {}", state.EntryClips.Count, ParameterName(state.ParamIndexX), ParameterName(state.ParamIndexY));
			default:
				node.Type.Set("clip");
				if (state.ClipRef.IsNil)
					node.Subtitle.Set("No clip");
				else if (mNameOf != null)
					mNameOf(state.ClipRef, node.Subtitle);
				else
					node.Subtitle.Set("A clip");
			}
			// The state the layer starts in, apart from the rest.
			if (s == layer.DefaultState)
			{
				node.Subtitle.Insert(0, "Starts here · ");
				node.HeaderColor = .(0.24f, 0.55f, 0.36f, 1.0f);
			}
			node.Position = ((layout != null) && (s < layout.StatePositions.Count)) ? layout.StatePositions[s] : .(0.0f, 0.0f);
			mNodes.Add(node);
		}
	}

	private StringView ParameterName(int32 index) => mDoc.HasParam(index) ? (StringView)mDoc.Params[index].Name : "nothing";
}
