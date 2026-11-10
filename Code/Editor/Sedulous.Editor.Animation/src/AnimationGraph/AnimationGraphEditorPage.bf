using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Content;
using Sedulous.Resource;
using Sedulous.Animation;
using Sedulous.Animation.Resource;
using Sedulous.Animation.Pipeline;
using Sedulous.Runtime.Client;
using Sedulous.Graphics;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Animation;

/// What the graph page's grid shows.
enum GraphChoiceKind : uint8
{
	Layer,
	Parameter,
	State,
	Transition,
}

struct GraphChoice : IEquatable<GraphChoice>
{
	public GraphChoiceKind Kind = .Layer;
	/// The parameter's, the state's or the transition's (in the layer shown).
	public int32 Index = 0;

	public this() { }

	public this(GraphChoiceKind kind, int32 index)
	{
		Kind = kind;
		Index = index;
	}

	public bool Equals(GraphChoice other) => (Kind == other.Kind) && (Index == other.Index);
}

/// An animation graph on the GUI from its markup (Data/Editor/AnimationGraphPage.xml). The graph's
/// layers and parameters are lists, each with its
/// bar (a parameter added by its type); the chosen layer is on the graph view (AnimationGraphStates:
/// its states the nodes, Any State one more, its transitions arrows; a state added from the view's
/// menu, a transition dragged from a state's edge); under it the preview plays the graph on the rig
/// the clip page has (a skeleton and a skinned mesh, kept per graph; never shown before, the skeleton
/// its first clip's import names), with the kit's transport, the state it plays lit on the graph and
/// named beside the transport.
///
/// The grid shows what is chosen: a layer (its name, blend, weight and the state it starts in), a
/// parameter (its name, type and default), a state (its name, speed, looping and what it plays: a
/// clip, or a blend by one or two parameters of entries, each a clip at a threshold or a place) or a
/// transition (where it goes, its blend time, its exit time, its priority and its conditions, each a
/// parameter compared with a value). The asset keeps its kinds as numbers and its lists in parallel
/// arrays, so the rows are the page's own. Each edit is one undo step of the whole asset. Under them,
/// the preview's parameters: what the graph plays on, set here to try it (a trigger fired), the page's
/// alone and never the graph's.
///
/// Sedulous-side: the asset's source is flat; the page reads it as a GraphDocument (Doc, read again
/// as the asset changes) and every edit goes through AnimationGraphEdits.Edit.
class AnimationGraphEditorPage : AssetObjectPage, IPlaybackPage
{
	public const String cMarkupPath = "Editor/AnimationGraphPage.xml";
	private const String cEntries = "entries";
	private const String cConditions = "conditions";
	private static readonly StringView[4] cParameterTypes = .("Float", "Int", "Bool", "Trigger");
	private static readonly StringView[2] cBlendModes = .("Override", "Additive");
	private static readonly StringView[3] cStateKinds = .("A clip", "A blend by one parameter", "A blend by two parameters");
	private static readonly StringView[6] cComparisons = .("equals", "differs from", "is above", "is below", "is at least", "is at most");

	private AnimationGraphStates mStates ~ delete _;
	/// The asset's source as nested objects, read again as it changes.
	private GraphDocument mDoc = new .() ~ delete _;
	private int32 mLayer = 0;
	private GraphChoice mChosen = .();
	/// Choosing from code: not the user's.
	private bool mShowing = false;

	/// The rows; the base's sections let go of them first (ClearSections).
	private Sedulous.GUI.PropertyBag mLayerRows = null;
	private Sedulous.GUI.PropertyBag mParameterRows = null;
	private Sedulous.GUI.PropertyBag mStateRows = null;
	private Sedulous.GUI.PropertyBag mTransitionRows = null;
	/// Made again as the parameters change.
	private Sedulous.GUI.PropertyBag mLiveRows = null;
	/// The parameters it was made for.
	private int mLiveCount = -1;

	// The markup's (its tree holds them).
	private GraphView mView = null;
	private TreeView mLayerTree = null;
	private TreeView mParameterTree = null;
	/// A list row's menu (a reference of ours).
	private Sedulous.GUI.Menu mListMenu = null ~ _?.ReleaseRef();
	private uint32 mLayerMenuListener = 0;
	private uint32 mParameterMenuListener = 0;
	private Sedulous.GUI.Label mState = null;
	private ButtonBase mTravelButton = null;
	private TreeModel mLayerModel = new .() ~ delete _;
	private TreeModel mParameterModel = new .() ~ delete _;

	private PreviewPane mPane = null;
	private AnimationPreviewRig mRig = null;
	/// The player borrows it.
	private AnimationGraph mGraph = null;
	private AnimationGraphPlayer mPlayer = null;
	/// What the player was made for.
	private Skeleton mPlayerSkeleton = null;
	/// The graph changed: a new player.
	private bool mRebuild = true;
	/// The preview's parameter values.
	private List<double> mLive = new .() ~ delete _;
	private bool mPlaying = true;
	private bool mTravel = false;
	private Float3 mTravelPosition = .(0.0f, 0.0f, 0.0f);
	private float mTravelYaw = 0.0f;
	/// The node lit as the state played.
	private GraphId mLit = 0;
	/// The view framed to the layer's states, once it has a size.
	private bool mGraphFramed = false;

	/// It takes `services`.
	public this(EditorContext context, AssetPageServices services, Instance instance)
		: base(context, services, instance, typeof(AnimationGraphAsset), cMarkupPath)
	{
		HideAssetRows(); // parallel arrays and kinds kept as numbers: the rows are the page's own
		ReadDoc();
		mStates = new AnimationGraphStates(new [=this] () => Graph, new [=this] (typeId, mutate) =>
			{
				EditWhole(typeId, scope (object) => { mutate((AnimationGraphAsset)object); });
			});
		mStates.SetNameOf(new [=this] (clip, outName) => { ClipName(clip, outName); });
		mStates.Refresh(); // the clips named on their states
		BuildRows();

		mLayerTree = Find<TreeView>("graph-layers");
		if (mLayerTree != null)
		{
			mLayerTree.Model = mLayerModel;
			mLayerTree.SetOnSelectionChanged(new [=this] (index) =>
				{
					if (!mShowing && index.IsValid)
						ChooseLayer((int32)index.InternalId);
				});
		}
		mParameterTree = Find<TreeView>("graph-parameters");
		if (mParameterTree != null)
		{
			mParameterTree.Model = mParameterModel;
			mParameterTree.SetOnSelectionChanged(new [=this] (index) =>
				{
					if (!mShowing && index.IsValid)
						Choose(.(.Parameter, (int32)index.InternalId));
				});
		}
		// A row's menu: the row chosen, then Delete (the old page's; the bars' trash does the same).
		if (mLayerTree != null)
			mLayerMenuListener = mLayerTree.AddEventListener(.ContextMenu, new [=this] (e) => { RowMenu(mLayerTree, true, e); });
		if (mParameterTree != null)
			mParameterMenuListener = mParameterTree.AddEventListener(.ContextMenu, new [=this] (e) => { RowMenu(mParameterTree, false, e); });
		if (let add = Find<ButtonBase>("graph-add-layer"))
			add.SetOnClick(new [=this] () => { AddLayer(); });
		if (let remove = Find<ButtonBase>("graph-remove-layer"))
			remove.SetOnClick(new [=this] () => { RemoveLayer(); });
		if (let add = Find<ToolMenuButton>("graph-add-parameter"))
		{
			for (int t < 4)
			{
				let type = (AnimationParameterType)t;
				add.Menu.AddItem(cParameterTypes[t], new [=this, =type] () => { AddParameter(type); });
			}
		}
		if (let remove = Find<ButtonBase>("graph-remove-parameter"))
			remove.SetOnClick(new [=this] () => { RemoveParameter(); });

		mView = Find<GraphView>("graph-view");
		if (mView != null)
		{
			mView.Source = mStates;
			mView.SetOnSelectionChanged(new [=this] () => { FollowView(); });
		}

		if (Content != null)
		{
			mPane = new PreviewPane(Content, Services, "animgraph.preview");
			mPane.OnFrame = new [=this] () => { FramePreview(); };
			mRig = new AnimationPreviewRig(Context, Services, mPane);
			mRig.SetOnPicked(new [=this] () =>
				{
					SavePreviewPref();
					mRebuild = true;
				});
			mRig.SetOnFirstShown(new [=this] () => { FramePreview(); });
			BindAction(Find<ButtonBase>("graph-restart"), "playback.restart");
			BindAction(Find<ButtonBase>("graph-play"), "playback.play");
			BindAction(Find<ButtonBase>("graph-stop"), "playback.stop");
			mState = Find<Sedulous.GUI.Label>("graph-state");
			mTravelButton = Find<ButtonBase>("graph-travel");
			if (mTravelButton != null)
			{
				mTravelButton.SetOnClick(new [=this] () =>
					{
						mTravel = !mTravel;
						mTravelButton.Checked = mTravel;
						mTravelPosition = .(0.0f, 0.0f, 0.0f);
						mTravelYaw = 0.0f;
					});
			}
		}
		LoadPreviewPref();
		BuildLiveRows();
		ShowLists();
		Choose(.(.Layer, 0));
		ShowFacts();
	}

	public ~this()
	{
		if (mView != null)
			mView.Source = null;
		if ((mListMenu != null) && mListMenu.IsOpen)
			mListMenu.Close();
		if (mLayerTree != null)
		{
			mLayerTree.RemoveEventListener(mLayerMenuListener);
			mLayerTree.Model = null;
		}
		if (mParameterTree != null)
		{
			mParameterTree.RemoveEventListener(mParameterMenuListener);
			mParameterTree.Model = null;
		}
		// Torn down in order: the player borrows the graph; the rig before its pane.
		DeleteAndNullify!(mPlayer);
		DeleteAndNullify!(mGraph);
		DeleteAndNullify!(mRig);
		DeleteAndNullify!(mPane);
		// The grid's sections let go of the rows before they go (the base's outlive these).
		ClearSections();
		DeleteAndNullify!(mLayerRows);
		DeleteAndNullify!(mParameterRows);
		DeleteAndNullify!(mStateRows);
		DeleteAndNullify!(mTransitionRows);
		DeleteAndNullify!(mLiveRows);
	}

	public AnimationGraphAsset Graph => ObjectAs<AnimationGraphAsset>();
	/// The graph as it is now, as nested objects.
	public GraphDocument Doc => mDoc;

	// === IPlaybackPage: the preview's, never the graph's ===

	public bool CanPlay => mPlayer != null;
	public bool IsPlaying => mPlaying;
	public void Play() { mPlaying = true; }
	public void Pause() { mPlaying = false; }

	public void Stop()
	{
		// Back to where the graph starts: a player made anew, its parameters as the preview set them.
		mPlaying = false;
		mTravelPosition = .(0.0f, 0.0f, 0.0f);
		mTravelYaw = 0.0f;
		mRebuild = true;
	}

	public void Restart()
	{
		Stop();
		mPlaying = true;
	}

	// === Choosing ===

	/// The layer on the graph view.
	public void ChooseLayer(int32 layer)
	{
		if (mDoc.Layers.IsEmpty)
			return;
		mLayer = Math.Clamp(layer, 0, (int32)mDoc.Layers.Count - 1);
		mStates.SetLayer(mLayer);
		mLit = 0;
		mGraphFramed = false; // another layer's states, framed once shown
		Choose(.(.Layer, mLayer));
	}

	public int32 Layer => mLayer;

	/// What the grid shows; the lists and the view follow.
	public void Choose(GraphChoice choice)
	{
		mChosen = choice;
		if (mChosen.Kind == .Layer)
			mChosen.Index = mLayer;
		ShowSections();
		ShowRows();
		ShowLists();
		// The view chooses the state too (a choice from a list or from code).
		if ((mView != null) && (mChosen.Kind == .State))
		{
			mShowing = true;
			GraphId[1] node = .(mStates.StateId(mChosen.Index));
			mView.SetSelectedLinks(.());
			mView.SetSelectedNodes(node);
			mShowing = false;
		}
	}

	public GraphChoice Chosen => mChosen;

	public void AddLayer()
	{
		int32 made = -1;
		EditWhole("add_animgraph_layer", scope [&] (object) => { made = AnimationGraphEdits.AddLayer((AnimationGraphAsset)object, "Layer"); });
		if (made >= 0)
			ChooseLayer(made);
	}

	/// A layer's (`layers`) or a parameter's row menu at `at` over `owner` (its list): the row
	/// chosen, then Delete.
	public void ShowListMenu(bool layers, int32 index, Node owner, Float2 at)
	{
		if (layers)
			ChooseLayer(index);
		else
			Choose(.(.Parameter, index));
		if (mListMenu != null)
		{
			if (mListMenu.IsOpen)
				mListMenu.Close();
			mListMenu.ReleaseRef();
		}
		mListMenu = new Sedulous.GUI.Menu();
		let remove = mListMenu.AddItem(layers ? "Delete Layer" : "Delete Parameter", new [=this, =layers] () =>
			{
				if (layers)
					RemoveLayer();
				else
					RemoveParameter();
			});
		remove.Enabled = !layers || (mDoc.Layers.Count > 1); // the last layer stays
		mListMenu.Open(owner, owner.RootNode.ConvertToNodeSpace(at)); // `at` is a pointer's, in world space
	}

	/// That menu, while it is open.
	public Sedulous.GUI.Menu ListMenu => ((mListMenu != null) && mListMenu.IsOpen) ? mListMenu : null;

	private void RowMenu(TreeView tree, bool layers, Event e)
	{
		let at = ((MouseEvent)e).Position;
		let item = tree.ItemAt(at);
		if (item < 0)
			return;
		ShowListMenu(layers, (int32)tree.GetItemIndex(item).InternalId, tree, at);
		e.Handled = true;
	}

	public bool RemoveLayer()
	{
		if (mDoc.Layers.Count <= 1)
			return false;
		let layer = mLayer;
		EditWhole("remove_animgraph_layer", scope [&] (object) => { AnimationGraphEdits.RemoveLayer((AnimationGraphAsset)object, layer); });
		ChooseLayer(Math.Max(layer - 1, 0));
		return true;
	}

	public void AddParameter(AnimationParameterType type)
	{
		int32 made = -1;
		StringView name = (type == .Trigger) ? "Trigger" : "Parameter";
		EditWhole("add_animgraph_parameter", scope [&] (object) => { made = AnimationGraphEdits.AddParameter((AnimationGraphAsset)object, name, type); });
		if (made >= 0)
			Choose(.(.Parameter, made));
	}

	public bool RemoveParameter()
	{
		if ((mChosen.Kind != .Parameter) || !mDoc.HasParam(mChosen.Index))
			return false;
		let parameter = mChosen.Index;
		EditWhole("remove_animgraph_parameter", scope [&] (object) => { AnimationGraphEdits.RemoveParameter((AnimationGraphAsset)object, parameter); });
		Choose(.(.Layer, mLayer));
		return true;
	}

	/// A preview parameter's value, by the parameter's index (a trigger fires): the page's alone.
	public void SetLive(int32 parameter, double value)
	{
		if ((parameter < 0) || (parameter >= mLive.Count) || !mDoc.HasParam(parameter))
			return;
		if (mDoc.Params[parameter].Type == 3)
		{
			if (mPlayer != null)
				mPlayer.SetTrigger(parameter);
			return;
		}
		mLive[parameter] = value;
		ApplyLive();
	}

	// === For tests ===

	public AnimationGraphStates States => mStates;
	public Sedulous.GUI.PropertyBag LayerRows => mLayerRows;
	public Sedulous.GUI.PropertyBag ParameterRows => mParameterRows;
	public Sedulous.GUI.PropertyBag StateRows => mStateRows;
	public Sedulous.GUI.PropertyBag TransitionRows => mTransitionRows;
	public Sedulous.GUI.PropertyBag LiveRows => mLiveRows;
	public AnimationPreviewRig Rig => mRig;

	/// The layers' list, a name a line, appended.
	public void LayerList(String outText)
	{
		for (let layer in mDoc.Layers)
		{
			if (!outText.IsEmpty)
				outText.Append('\n');
			outText.Append(layer.Name);
		}
	}

	/// The parameters' list ("Speed  Float"), one a line, appended.
	public void ParameterList(String outText)
	{
		for (let param in mDoc.Params)
		{
			if (!outText.IsEmpty)
				outText.Append('\n');
			outText.AppendF("{}  {}", param.Name, cParameterTypes[Math.Min(param.Type, 3)]);
		}
	}

	// === The rows ===

	private void BuildRows()
	{
		mLayerRows = new Sedulous.GUI.PropertyBag();
		Row(mLayerRows, "name", .String, .(""), "Name", "What the layer is called");
		Choices(Row(mLayerRows, "blend", .Enum, .((int64)0), "Blend", "Over the layers under it (Override), or added to them (Additive)"), cBlendModes);
		let weight = Row(mLayerRows, "weight", .Float, .(1.0), "Weight", "How much of it shows over the layers under it");
		weight.HasRange = true;
		weight.Min = 0.0;
		weight.Max = 1.0;
		weight.Step = 0.01;
		weight.Hint.Set("slider");
		Row(mLayerRows, "start", .Enum, .((int64)0), "Starts in", "The state the layer plays first");
		mLayerRows.SetOnDescribe(new [=this] (path, info) =>
			{
				if (path != "start")
					return;
				ClearAndDeleteItems!(info.Choices);
				let layer = mDoc.Layer(mLayer);
				if (layer == null)
					return;
				for (int s < layer.States.Count)
					info.AddChoice(layer.States[s].Name, s);
			});

		mParameterRows = new Sedulous.GUI.PropertyBag();
		Row(mParameterRows, "name", .String, .(""), "Name", "What a script sets it by");
		Choices(Row(mParameterRows, "type", .Enum, .((int64)0), "Type", "A number, a whole number, on or off, or a trigger (on for one step, then off)"), cParameterTypes);
		Row(mParameterRows, "float", .Float, .(0.0), "Default", "Its value when the graph starts");
		Row(mParameterRows, "int", .Integer, .((int64)0), "Default", "Its value when the graph starts");
		Row(mParameterRows, "bool", .Bool, .(false), "Default", "Its value when the graph starts");
		mParameterRows.SetOnDescribe(new [=this] (path, info) =>
			{
				// The default of its type alone; a trigger has none.
				let type = mDoc.HasParam(mChosen.Index) ? mDoc.Params[mChosen.Index].Type : 0;
				if (path == "float")
					info.Visible = type == 0;
				else if (path == "int")
					info.Visible = type == 1;
				else if (path == "bool")
					info.Visible = type == 2;
			});

		mStateRows = new Sedulous.GUI.PropertyBag();
		Row(mStateRows, "name", .String, .(""), "Name", "What the state is called");
		Row(mStateRows, "speed", .Float, .(1.0), "Speed", "How fast it plays (1: as authored)").Step = 0.05;
		Row(mStateRows, "loop", .Bool, .(true), "Loops", "Whether it plays again from its start when it ends; else it holds its last pose");
		Choices(Row(mStateRows, "kind", .Enum, .((int64)0), "Plays", "One clip, or a blend of clips by one parameter or by two"), cStateKinds);
		Row(mStateRows, "clip", .Reference, .(""), "Clip", "The clip it plays").ReferenceType = typeof(AnimationClip);
		Row(mStateRows, "driver", .Enum, .((int64)-1), "By", "The parameter the blend follows");
		Row(mStateRows, "driverX", .Enum, .((int64)-1), "Across by", "The parameter across the blend's plane");
		Row(mStateRows, "driverY", .Enum, .((int64)-1), "Up by", "The parameter up the blend's plane");
		let entries = mStateRows.AddList(cEntries, .Group, .());
		entries.DisplayName.Set("Entries");
		entries.Description.Set("The clips it blends between, each where it plays alone");
		entries.ListOps = PropertyListAdd | PropertyListRemove;
		if (let field = mStateRows.AddElementField(cEntries, "clip", .Reference, .("")))
		{
			field.DisplayName.Set("Clip");
			field.ReferenceType = typeof(AnimationClip);
		}
		if (let field = mStateRows.AddElementField(cEntries, "threshold", .Float, .(0.0)))
		{
			field.DisplayName.Set("At");
			field.Description.Set("The parameter's value where this clip plays alone");
		}
		if (let field = mStateRows.AddElementField(cEntries, "x", .Float, .(0.0)))
			field.DisplayName.Set("Across");
		if (let field = mStateRows.AddElementField(cEntries, "y", .Float, .(0.0)))
			field.DisplayName.Set("Up");
		mStateRows.SetOnDescribe(new [=this] (path, info) =>
			{
				let state = (mChosen.Kind == .State) ? mDoc.State(mLayer, mChosen.Index) : null;
				let kind = (state != null) ? state.NodeKind : 0;
				// Each row shown where what it plays uses it.
				if (path == "clip")
					info.Visible = kind == 0;
				else if (path == "driver")
					info.Visible = kind == 1;
				else if ((path == "driverX") || (path == "driverY"))
					info.Visible = kind == 2;
				else if (path == cEntries)
					info.Visible = kind != 0;
				if (path.StartsWith("driver"))
				{
					ClearAndDeleteItems!(info.Choices);
					info.AddChoice("Nothing", -1);
					for (int p < mDoc.Params.Count)
						info.AddChoice(mDoc.Params[p].Name, p);
				}
				let entry = ElementOf(path, cEntries);
				if ((entry < 0) || (state == null))
					return;
				let field = LastSegment(path);
				if (field == "threshold")
					info.Visible = kind == 1;
				else if ((field == "x") || (field == "y"))
					info.Visible = kind == 2;
				else if ((ParentPropertyPath(path) == cEntries) && (entry < state.EntryClips.Count))
				{
					// Closed, an entry says its clip and where it plays alone.
					let id = state.EntryClips[entry];
					info.DisplayName.Clear();
					if (id.IsNil)
						info.DisplayName.AppendF("Entry {}", entry + 1);
					else
						ClipName(id, info.DisplayName);
					if ((kind == 1) && (entry < state.EntryThresholds.Count))
					{
						info.Summary.Clear();
						info.Summary.AppendF("at {}", state.EntryThresholds[entry]);
					}
				}
			});

		mTransitionRows = new Sedulous.GUI.PropertyBag();
		Row(mTransitionRows, "from", .String, .(""), "From", "The state it leaves (Any State: every state)").ReadOnly = true;
		Row(mTransitionRows, "to", .String, .(""), "To", "The state it goes to").ReadOnly = true;
		Row(mTransitionRows, "duration", .Float, .(0.25), "Blend time", "How long the two states are blended across, in seconds").Step = 0.05;
		Row(mTransitionRows, "exit", .Bool, .(false), "Waits to exit", "Whether it waits for the state to play so far before it may go (with its conditions, if any)");
		let exitTime = Row(mTransitionRows, "exitTime", .Float, .(1.0), "Exits at", "How far through the state it may go, from 0 (its start) to 1 (its end)");
		exitTime.HasRange = true;
		exitTime.Min = 0.0;
		exitTime.Max = 1.0;
		exitTime.Step = 0.01;
		exitTime.Hint.Set("slider");
		Row(mTransitionRows, "priority", .Integer, .((int64)0), "Priority", "Which goes when several could: the lowest first");
		let conditions = mTransitionRows.AddList(cConditions, .Group, .());
		conditions.DisplayName.Set("Conditions");
		conditions.Description.Set("What must all hold for it to go (none: it goes as soon as it may)");
		conditions.ListOps = PropertyListAdd | PropertyListRemove;
		if (let field = mTransitionRows.AddElementField(cConditions, "parameter", .Enum, .((int64)0)))
			field.DisplayName.Set("Parameter");
		if (let field = mTransitionRows.AddElementField(cConditions, "compare", .Enum, .((int64)0)))
		{
			field.DisplayName.Set("Holds when it");
			Choices(field, cComparisons);
		}
		if (let field = mTransitionRows.AddElementField(cConditions, "value", .Float, .(1.0)))
		{
			field.DisplayName.Set("Value");
			field.Description.Set("What it is compared with (on and off: 1 and 0)");
		}
		mTransitionRows.SetOnDescribe(new [=this] (path, info) =>
			{
				if (path == "exitTime")
				{
					var exit = mTransitionRows.GetValue("exit", 0);
					defer exit.Dispose();
					info.Visible = exit.AsBool;
					return;
				}
				let condition = ElementOf(path, cConditions);
				if (condition < 0)
					return;
				if (LastSegment(path) == "parameter")
				{
					ClearAndDeleteItems!(info.Choices);
					for (int p < mDoc.Params.Count)
						info.AddChoice(mDoc.Params[p].Name, p);
					return;
				}
				if (ParentPropertyPath(path) != cConditions)
					return;
				// Closed, a condition reads as what it says ("Speed is above 0.5").
				var p = mTransitionRows.GetValue(JoinPropertyPath(path, "parameter", .. scope String()), 0);
				defer p.Dispose();
				var op = mTransitionRows.GetValue(JoinPropertyPath(path, "compare", .. scope String()), 0);
				defer op.Dispose();
				var value = mTransitionRows.GetValue(JoinPropertyPath(path, "value", .. scope String()), 0);
				defer value.Dispose();
				let parameter = (int32)p.AsInt;
				info.DisplayName.Clear();
				info.DisplayName.AppendF("Condition {}", condition + 1);
				info.Summary.Clear();
				info.Summary.AppendF("{} {} {}", mDoc.HasParam(parameter) ? (StringView)mDoc.Params[parameter].Name : "Nothing",
					cComparisons[(int)Math.Clamp(op.AsInt, 0, 5)], value.AsFloat);
			});

		for (let rows in Sedulous.GUI.PropertyBag[4](mLayerRows, mParameterRows, mStateRows, mTransitionRows))
		{
			rows.SetOnCommit(new [=this, =rows] (commit) =>
				{
					if (!commit.After.IsEmpty)
						Committed(rows, commit.Path, commit.After[0]);
				});
			rows.SetOnListEdited(new [=this, =rows] (path, edit) => { ListEdited(rows, path, edit); });
			rows.PropertiesChanged(); // Add told the grid before the rows' names were set
		}
	}

	private void BuildLiveRows()
	{
		// Made again whenever the parameters change: a row a parameter, by its type.
		let count = mDoc.Params.Count;
		if ((count == mLiveCount) && (mLiveRows != null))
			return;
		mLiveCount = count;
		ClearSections(); // the grid lets the old rows go before they do
		DeleteAndNullify!(mLiveRows);
		mLiveRows = new Sedulous.GUI.PropertyBag();
		mLive.Count = count;
		let path = scope String();
		for (int p < count)
		{
			let param = mDoc.Params[p];
			let type = param.Type;
			mLive[p] = (type == 0) ? (double)param.FloatValue : (type == 1) ? (double)param.IntValue : ((type == 2) && param.BoolValue) ? 1.0 : 0.0;
			path.Clear();
			path.AppendF("p{}", p);
			let kind = (type == 0) ? PropertyKind.Float : (type == 1) ? PropertyKind.Integer : PropertyKind.Bool;
			let value = (type == 0) ? Sedulous.GUI.Variant(mLive[p]) : (type == 1) ? Sedulous.GUI.Variant((int64)mLive[p]) : Sedulous.GUI.Variant(mLive[p] != 0.0);
			let info = mLiveRows.Add(path, kind, value);
			if (type == 3)
				info.DisplayName.AppendF("Fire {}", param.Name);
			else
				info.DisplayName.Set(param.Name);
			info.Description.Set((type == 3) ? "Ticked, the trigger fires once in the preview" : "Its value in the preview: this page's alone, never the graph's");
			if (type == 0)
				info.Step = 0.05;
		}
		mLiveRows.SetOnCommit(new [=this] (commit) =>
			{
				if (!commit.After.IsEmpty)
					LiveCommitted(commit.Path, commit.After[0]);
			});
		mLiveRows.PropertiesChanged();
		ShowSections();
	}

	private void ShowSections()
	{
		ClearSections();
		switch (mChosen.Kind)
		{
		case .Layer: AddSection("layer", "Layer", mLayerRows);
		case .Parameter: AddSection("parameter", "Parameter", mParameterRows);
		case .State: AddSection("state", "State", mStateRows);
		case .Transition: AddSection("transition", "Transition", mTransitionRows);
		}
		if (mLiveRows != null)
			AddSection("preview", "Preview parameters", mLiveRows);
	}

	private void ShowRows()
	{
		let layer = mDoc.Layer(mLayer);
		if (layer == null)
			return;
		let path = scope String();
		switch (mChosen.Kind)
		{
		case .Layer:
			mLayerRows.SetValue("name", 0, .(layer.Name));
			mLayerRows.SetValue("blend", 0, .((int64)layer.BlendMode));
			mLayerRows.SetValue("weight", 0, .((double)layer.Weight));
			mLayerRows.SetValue("start", 0, .((int64)layer.DefaultState));
			mLayerRows.PropertiesChanged();
		case .Parameter:
			if (!mDoc.HasParam(mChosen.Index))
				return;
			let param = mDoc.Params[mChosen.Index];
			mParameterRows.SetValue("name", 0, .(param.Name));
			mParameterRows.SetValue("type", 0, .((int64)param.Type));
			mParameterRows.SetValue("float", 0, .((double)param.FloatValue));
			mParameterRows.SetValue("int", 0, .((int64)param.IntValue));
			mParameterRows.SetValue("bool", 0, .(param.BoolValue));
			mParameterRows.PropertiesChanged();
		case .State:
			let state = mDoc.State(mLayer, mChosen.Index);
			if (state == null)
				return;
			state.NormalizeEntries();
			mStateRows.SetValue("name", 0, .(state.Name));
			mStateRows.SetValue("speed", 0, .((double)state.Speed));
			mStateRows.SetValue("loop", 0, .(state.Loop));
			mStateRows.SetValue("kind", 0, .((int64)state.NodeKind));
			mStateRows.SetValue("clip", 0, .(GuidText(state.ClipRef, .. scope String())));
			mStateRows.SetValue("driver", 0, .((int64)state.ParamIndex));
			mStateRows.SetValue("driverX", 0, .((int64)state.ParamIndexX));
			mStateRows.SetValue("driverY", 0, .((int64)state.ParamIndexY));
			mStateRows.ResizeList(cEntries, 0, state.EntryClips.Count);
			for (int e < state.EntryClips.Count)
			{
				path.Clear();
				path.AppendF("{}.{}.clip", cEntries, e);
				mStateRows.SetValue(path, 0, .(GuidText(state.EntryClips[e], .. scope String())));
				path.Clear();
				path.AppendF("{}.{}.threshold", cEntries, e);
				mStateRows.SetValue(path, 0, .((double)state.EntryThresholds[e]));
				path.Clear();
				path.AppendF("{}.{}.x", cEntries, e);
				mStateRows.SetValue(path, 0, .((double)state.EntryPositions[e].X));
				path.Clear();
				path.AppendF("{}.{}.y", cEntries, e);
				mStateRows.SetValue(path, 0, .((double)state.EntryPositions[e].Y));
			}
			mStateRows.PropertiesChanged();
		case .Transition:
			let transition = mDoc.Transition(mLayer, mChosen.Index);
			if (transition == null)
				return;
			mTransitionRows.SetValue("from", 0, .(StateName(layer, transition.Src)));
			mTransitionRows.SetValue("to", 0, .(StateName(layer, transition.Dst)));
			mTransitionRows.SetValue("duration", 0, .((double)transition.Duration));
			mTransitionRows.SetValue("exit", 0, .(transition.HasExitTime));
			mTransitionRows.SetValue("exitTime", 0, .((double)transition.ExitTime));
			mTransitionRows.SetValue("priority", 0, .((int64)transition.Priority));
			mTransitionRows.ResizeList(cConditions, 0, transition.Conditions.Count);
			for (int c < transition.Conditions.Count)
			{
				let condition = transition.Conditions[c];
				path.Clear();
				path.AppendF("{}.{}.parameter", cConditions, c);
				mTransitionRows.SetValue(path, 0, .((int64)condition.ParamIndex));
				path.Clear();
				path.AppendF("{}.{}.compare", cConditions, c);
				mTransitionRows.SetValue(path, 0, .((int64)condition.Op));
				path.Clear();
				path.AppendF("{}.{}.value", cConditions, c);
				mTransitionRows.SetValue(path, 0, .((double)condition.Threshold));
			}
			mTransitionRows.PropertiesChanged();
		}
	}

	private void ShowFacts()
	{
		int states = 0;
		int transitions = 0;
		for (let layer in mDoc.Layers)
		{
			states += layer.States.Count;
			transitions += layer.Transitions.Count;
		}
		SetFact("Layers", scope String()..AppendF("{}", mDoc.Layers.Count));
		SetFact("States", scope String()..AppendF("{}", states));
		SetFact("Transitions", scope String()..AppendF("{}", transitions));
		SetFact("Parameters", scope String()..AppendF("{}", mDoc.Params.Count));
	}

	private void Committed(Sedulous.GUI.PropertyBag rows, StringView path, Sedulous.GUI.Variant value)
	{
		if (Graph == null)
			return;
		let l = mLayer;
		let at = Math.Max(mChosen.Index, 0);
		let text = scope String(value.AsString);
		let number = value.AsInt;
		let real = value.AsFloat;
		let on = value.AsBool;
		if (rows === mLayerRows)
		{
			Edit("edit_animgraph_layer", scope [&] (doc) =>
				{
					let layer = doc.Layers[l];
					if (path == "name")
						layer.Name.Set(text);
					else if (path == "blend")
						layer.BlendMode = (uint8)Math.Clamp(number, 0, 1);
					else if (path == "weight")
						layer.Weight = (float)Math.Clamp(real, 0.0, 1.0);
					else if (path == "start")
						layer.DefaultState = (int32)Math.Clamp(number, 0, (int64)layer.States.Count - 1);
				});
			return;
		}
		if (rows === mParameterRows)
		{
			if (!mDoc.HasParam(at))
				return;
			Edit("edit_animgraph_parameter", scope [&] (doc) =>
				{
					let param = doc.Params[at];
					if (path == "name")
						param.Name.Set(text);
					else if (path == "type")
						param.Type = (uint8)Math.Clamp(number, 0, 3);
					else if (path == "float")
						param.FloatValue = (float)real;
					else if (path == "int")
						param.IntValue = (int32)number;
					else if (path == "bool")
						param.BoolValue = on;
				});
			return;
		}
		if (rows === mStateRows)
		{
			if (mDoc.State(l, at) == null)
				return;
			let id = GuidOf(text);
			let entry = ElementOf(path, cEntries);
			let field = LastSegment(path);
			Edit("edit_animgraph_state", scope [&] (doc) =>
				{
					let state = doc.Layers[l].States[at];
					if (entry >= 0)
					{
						state.NormalizeEntries();
						if (entry >= state.EntryClips.Count)
							return;
						if (field == "clip")
							state.EntryClips[entry] = id;
						else if (field == "threshold")
							state.EntryThresholds[entry] = (float)real;
						else if (field == "x")
							state.EntryPositions[entry].X = (float)real;
						else if (field == "y")
							state.EntryPositions[entry].Y = (float)real;
						return;
					}
					if (path == "name")
						state.Name.Set(text);
					else if (path == "speed")
						state.Speed = (float)real;
					else if (path == "loop")
						state.Loop = on;
					else if (path == "kind")
						state.NodeKind = (uint8)Math.Clamp(number, 0, 2);
					else if (path == "clip")
						state.ClipRef = id;
					else if (path == "driver")
						state.ParamIndex = (int32)number;
					else if (path == "driverX")
						state.ParamIndexX = (int32)number;
					else if (path == "driverY")
						state.ParamIndexY = (int32)number;
				});
			return;
		}
		if (rows === mTransitionRows)
		{
			if (mDoc.Transition(l, at) == null)
				return;
			let condition = ElementOf(path, cConditions);
			let field = LastSegment(path);
			Edit("edit_animgraph_transition", scope [&] (doc) =>
				{
					let transition = doc.Layers[l].Transitions[at];
					if (condition >= 0)
					{
						if (condition >= transition.Conditions.Count)
							return;
						let changed = transition.Conditions[condition];
						if (field == "parameter")
							changed.ParamIndex = (int32)number;
						else if (field == "compare")
							changed.Op = (uint8)Math.Clamp(number, 0, 5);
						else if (field == "value")
							changed.Threshold = (float)real;
						return;
					}
					if (path == "duration")
						transition.Duration = (float)Math.Max(real, 0.0);
					else if (path == "exit")
						transition.HasExitTime = on;
					else if (path == "exitTime")
						transition.ExitTime = (float)Math.Clamp(real, 0.0, 1.0);
					else if (path == "priority")
						transition.Priority = (int32)number;
				});
		}
	}

	private void ListEdited(Sedulous.GUI.PropertyBag rows, StringView path, ListEdit edit)
	{
		let l = mLayer;
		let at = Math.Max(mChosen.Index, 0);
		let insert = edit.Kind == .Insert;
		let index = edit.Index;
		if ((rows === mStateRows) && (path == cEntries) && (mDoc.State(l, at) != null))
		{
			if (!insert && (edit.Kind != .Remove))
				return;
			Edit("edit_animgraph_state", scope [&] (doc) =>
				{
					let state = doc.Layers[l].States[at];
					state.NormalizeEntries();
					if (insert)
					{
						// After the last, a step past it.
						let threshold = state.EntryThresholds.IsEmpty ? 0.0f : state.EntryThresholds.Back + 1.0f;
						state.AddEntry();
						state.EntryThresholds[state.EntryThresholds.Count - 1] = threshold;
					}
					else
						state.RemoveEntry(index);
				});
		}
		else if ((rows === mTransitionRows) && (path == cConditions) && (mDoc.Transition(l, at) != null))
		{
			if (!insert && (edit.Kind != .Remove))
				return;
			Edit("edit_animgraph_transition", scope [&] (doc) =>
				{
					let conditions = doc.Layers[l].Transitions[at].Conditions;
					if (insert)
					{
						let condition = new GraphCondition();
						condition.ParamIndex = 0;
						condition.Threshold = 1.0f;
						conditions.Add(condition);
					}
					else if ((index >= 0) && (index < conditions.Count))
					{
						delete conditions[index];
						conditions.RemoveAt(index);
					}
				});
		}
		ShowRows(); // the list as the graph holds it (a move, which these lists do not offer, goes back)
	}

	private void LiveCommitted(StringView path, Sedulous.GUI.Variant value)
	{
		if (!path.StartsWith("p"))
			return;
		int32 p = -1;
		if (int32.Parse(path.Substring(1)) case .Ok(let parsed))
			p = parsed;
		if ((p < 0) || !mDoc.HasParam(p))
			return;
		let type = mDoc.Params[p].Type;
		if (type == 3)
		{
			if (value.AsBool)
				SetLive(p, 1.0);
			mLiveRows.SetValue(path, 0, .(false)); // ready to fire again
			return;
		}
		SetLive(p, (type == 2) ? (value.AsBool ? 1.0 : 0.0) : (type == 1) ? (double)value.AsInt : value.AsFloat);
	}

	/// `mutate` over the graph as nested objects: one undo step of the whole asset.
	private void Edit(StringView typeId, delegate void(GraphDocument doc) mutate)
	{
		EditWhole(typeId, scope (object) => { AnimationGraphEdits.Edit((AnimationGraphAsset)object, mutate); });
	}

	protected override void OnObjectChanged()
	{
		// An edit, its undo or redo: the view, the lists and the rows read again, the preview made anew.
		ReadDoc();
		if (!mDoc.Layers.IsEmpty && (mLayer >= mDoc.Layers.Count))
		{
			mLayer = (int32)mDoc.Layers.Count - 1;
			mStates.SetLayer(mLayer);
		}
		mStates.Refresh();
		// What was chosen may be gone.
		if (let layer = mDoc.Layer(mLayer))
		{
			let count = (mChosen.Kind == .Parameter) ? mDoc.Params.Count : (mChosen.Kind == .State) ? layer.States.Count
				: (mChosen.Kind == .Transition) ? layer.Transitions.Count : mDoc.Layers.Count;
			if ((mChosen.Index < 0) || (mChosen.Index >= count))
				mChosen = .(.Layer, mLayer);
		}
		BuildLiveRows();
		ShowSections();
		ShowLists();
		ShowRows();
		ShowFacts();
		mRebuild = true;
	}

	// === The lists and the view ===

	private void ShowLists()
	{
		mShowing = true;
		mLayerModel.Clear();
		for (let layer in mDoc.Layers)
		{
			let node = mLayerModel.AddNode(TreeModel.Root, layer.Name.IsEmpty ? "Layer" : (StringView)layer.Name);
			mLayerModel.SetIcon(node, "Editor/Icons/layers.svg");
		}
		mParameterModel.Clear();
		let text = scope String();
		for (let param in mDoc.Params)
		{
			text.Clear();
			text.AppendF("{}   {}", param.Name, cParameterTypes[Math.Min(param.Type, 3)]);
			mParameterModel.AddNode(TreeModel.Root, text);
		}
		if (mLayerTree != null)
		{
			ItemId[1] id = .((ItemId)mLayer);
			mLayerTree.SetSelectedIds(id);
		}
		if (mParameterTree != null)
		{
			if (mChosen.Kind == .Parameter)
			{
				ItemId[1] id = .((ItemId)mChosen.Index);
				mParameterTree.SetSelectedIds(id);
			}
			else
				mParameterTree.SetSelectedIds(.());
		}
		mShowing = false;
	}

	private void FollowView()
	{
		if (mShowing || (mView == null))
			return;
		let nodes = mView.SelectedNodes;
		let links = mView.SelectedLinks;
		if ((nodes.Length == 1) && links.IsEmpty && (mStates.StateOf(nodes[0]) >= 0))
			Choose(.(.State, mStates.StateOf(nodes[0])));
		else if ((links.Length == 1) && nodes.IsEmpty && (mStates.TransitionOf(links[0]) >= 0))
			Choose(.(.Transition, mStates.TransitionOf(links[0])));
		else if (nodes.IsEmpty && links.IsEmpty)
			Choose(.(.Layer, mLayer));
	}

	// === The preview ===

	private void LoadPreviewPref()
	{
		if (mRig == null)
			return;
		var skeleton = Guid();
		var mesh = Guid();
		if (GraphPreviewPrefs.Load(Context.ProjectEditorSettings, InstanceId, ref skeleton, ref mesh))
		{
			mRig.SetSkeleton(skeleton);
			mRig.SetMesh(mesh);
			return;
		}
		// Never shown before: on the skeleton its first clip's import names.
		skeleton = .();
		for (let layer in mDoc.Layers)
		{
			for (let state in layer.States)
			{
				if (skeleton.IsNil)
					skeleton = SkeletonOf(state.ClipRef);
				for (let entry in state.EntryClips)
				{
					if (skeleton.IsNil)
						skeleton = SkeletonOf(entry);
				}
			}
		}
		mRig.SetSkeleton(skeleton);
		mRig.SetMesh(.());
	}

	private void SavePreviewPref()
	{
		if ((mRig != null) && GraphPreviewPrefs.Save(Context.ProjectEditorSettings, InstanceId, mRig.SkeletonId, mRig.MeshId))
			Context.RequestProjectEditorSettingsSave();
	}

	// The skeleton a clip's import names (empty: none, or no such clip).
	private Guid SkeletonOf(Guid clip)
	{
		let db = (Context.Project != null) ? Context.Project.SourceDb : null;
		let instance = ((db != null) && !clip.IsNil) ? db.GetInstance(clip) : null;
		let object = (instance != null) ? instance.ReadObject() : null;
		defer delete object;
		let asset = object as AnimationClipAsset;
		return (asset != null) ? asset.Skeleton : .();
	}

	private void RebuildPlayer()
	{
		// Torn down in order: the player borrows the graph and the skeleton.
		DeleteAndNullify!(mPlayer);
		DeleteAndNullify!(mGraph);
		mPlayerSkeleton = (mRig != null) ? mRig.CookedSkeleton : null;
		mLit = 0;
		let asset = Graph;
		if ((asset == null) || (Context.Resources == null) || (mPlayerSkeleton == null) || (mPlayerSkeleton.BoneCount <= 0))
			return;
		mGraph = new AnimationGraph();
		asset.Source.BuildInto(Context.Resources, mGraph); // the clips bound by their guids, as the game binds them
		if (mGraph.Layers.IsEmpty)
			return;
		mPlayer = new AnimationGraphPlayer(mGraph, mPlayerSkeleton);
		ApplyLive();
	}

	private void ApplyLive()
	{
		if (mPlayer == null)
			return;
		for (int32 p = 0; (p < mLive.Count) && (p < mDoc.Params.Count); p++)
		{
			let type = mDoc.Params[p].Type;
			if (type == 0)
				mPlayer.SetFloat(p, (float)mLive[p]);
			else if (type == 1)
				mPlayer.SetInt(p, (int32)mLive[p]);
			else if (type == 2)
				mPlayer.SetBool(p, mLive[p] != 0.0);
		}
	}

	private void Pose(float dt)
	{
		if (mRig == null)
			return;
		if (mRebuild || (mRig.CookedSkeleton !== mPlayerSkeleton))
		{
			mRebuild = false;
			RebuildPlayer();
		}
		if (mPane != null)
		{
			if (mRig.CookedSkeleton == null)
				mPane.ShowEmpty("No skeleton to play it on", "Pick the skeleton its clips belong to on the preview's bar.");
			else
				mPane.Show();
		}
		if (mPlayer == null)
		{
			mRig.Show(.(), .Identity());
			return;
		}
		if (mPlaying)
			mPlayer.Update(dt);
		// Its root motion read every frame, so it never piles up; applied while it travels, and back
		// to the middle once it has gone a few metres.
		let moved = mPlayer.ConsumeRootMotion();
		if (mTravel)
		{
			mTravelPosition = mTravelPosition + RotateVector(Quaternion.FromAxisAngle(.(0.0f, 1.0f, 0.0f), mTravelYaw), moved.Translation);
			mTravelYaw += moved.Yaw;
			if (Length(Float3(mTravelPosition.X, 0.0f, mTravelPosition.Z)) > 6.0f)
				mTravelPosition = .(0.0f, 0.0f, 0.0f);
		}
		let placement = Transform(mTravelPosition, Quaternion.FromAxisAngle(.(0.0f, 1.0f, 0.0f), mTravelYaw), .(1.0f, 1.0f, 1.0f)).ToMatrix();
		mRig.Show(mPlayer.GetLocalPoses(), placement);

		// The state it plays lit on the graph.
		let layers = (int32)mGraph.Layers.Count;
		let current = mPlayer.GetCurrentStateIndex(Math.Min(mLayer, layers - 1));
		let lit = (current >= 0) ? mStates.StateId(current) : 0;
		if ((lit != mLit) && (mView != null))
		{
			mLit = lit;
			GraphId[1] shown = .(mLit);
			mView.SetHighlightedNodes((lit != 0) ? shown : .());
		}
	}

	private void ShowTransport()
	{
		if (mState == null)
			return;
		let text = scope String();
		if (mPlayer == null)
			text.Set(((mRig != null) && (mRig.CookedSkeleton == null)) ? "No skeleton" : "Not cooked yet");
		else
		{
			let layers = (int32)mGraph.Layers.Count;
			let layer = Math.Min(mLayer, layers - 1);
			let current = mPlayer.GetCurrentStateIndex(layer);
			let state = mDoc.State(mLayer, current);
			text.Set((state != null) ? (StringView)state.Name : "No state");
			if (mPlayer.IsTransitioning(layer))
				text.Append(" (blending in)");
		}
		if (mState.Text != text)
			mState.Text = text;
		if (mPlaying)
		{
			mState.AddClass("playing");
			mState.RemoveClass("paused");
		}
		else
		{
			mState.AddClass("paused");
			mState.RemoveClass("playing");
		}
	}

	private void FramePreview()
	{
		if ((mRig != null) && mRig.Frame())
			return;
		if ((mPane != null) && (mPane.Viewport != null))
		{
			mPane.Viewport.Camera.Position = .(0.0f, 1.4f, 3.2f);
			mPane.Viewport.Camera.LookAt(.(0.0f, 0.9f, 0.0f));
		}
	}

	public override void OnUpdate(IApplicationHost host, float dt)
	{
		base.OnUpdate(host, dt);
		// The layer's states in view once the view has its size (the first frame it is laid out).
		if (!mGraphFramed && (mView != null) && (mView.ContentBounds.Width > 0.0f))
		{
			mGraphFramed = true;
			mView.FrameAll();
		}
		Pose(dt);
		ShowTransport();
		if (mPane != null)
			mPane.Update(dt);
	}

	public override void OnRenderWindow(IApplicationHost host, ref FrameContext frame)
	{
		if (mPane != null)
			mPane.Render(ref frame);
	}

	public override void OnClose()
	{
		if (mPane != null)
			mPane.Close();
	}

	// === Helpers ===

	private void ReadDoc()
	{
		if (let graph = Graph)
			mDoc.Load(graph.Source);
		else
			mDoc.Clear();
	}

	// What a clip's guid is called (its asset's name), appended.
	private void ClipName(Guid id, String outName)
	{
		let instance = (Context.Project != null) ? Context.Project.SourceDb.GetInstance(id) : null;
		outName.Append((instance != null) ? instance.Name : "A missing clip");
	}

	private static StringView StateName(GraphLayer layer, int32 state)
	{
		if (state < 0)
			return "Any State";
		return layer.HasState(state) ? (StringView)layer.States[state].Name : "Nothing";
	}

	private static PropertyInfo Row(Sedulous.GUI.PropertyBag rows, StringView path, PropertyKind kind, Sedulous.GUI.Variant value, StringView shown, StringView about)
	{
		let info = rows.Add(path, kind, value);
		info.DisplayName.Set(shown);
		info.Description.Set(about);
		return info;
	}

	private static void Choices(PropertyInfo info, Span<StringView> names)
	{
		ClearAndDeleteItems!(info.Choices);
		for (int i < names.Length)
			info.AddChoice(names[i], i);
	}

	private static void GuidText(Guid id, String outText)
	{
		if (!id.IsNil)
			id.ToString(outText);
	}

	private static Guid GuidOf(StringView text)
	{
		var trimmed = text;
		trimmed.Trim();
		if (!trimmed.IsEmpty && (Guid.Parse(trimmed) case .Ok(let id)))
			return id;
		return .();
	}

	private static StringView LastSegment(StringView path)
	{
		let dot = path.LastIndexOf('.');
		return (dot >= 0) ? path.Substring(dot + 1) : path;
	}

	// The element a path is in ("entries.2.clip" in "entries": 2), or -1.
	private static int32 ElementOf(StringView path, StringView list)
	{
		if (!path.StartsWith(list) || (path.Length <= list.Length + 1) || (path[list.Length] != '.'))
			return -1;
		var rest = path.Substring(list.Length + 1);
		let dot = rest.IndexOf('.');
		if (dot >= 0)
			rest = rest.Substring(0, dot);
		if (int32.Parse(rest) case .Ok(let index))
			return (index >= 0) ? index : -1;
		return -1;
	}
}
