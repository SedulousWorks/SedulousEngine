using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Content;
using Sedulous.Input;
using Sedulous.Input.Pipeline;
using Sedulous.Runtime.Client;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Input;

/// An input map on the GUI from its markup (Data/Editor/InputMapPage.xml; Raptor's editor-gui spec,
/// 5.4, layer 5, part 4; the user's choice among the designs mocked in the editor mock). The sets
/// and their actions a tree beside the grid; the tree's bar adds a set and removes the chosen row,
/// its search keeping the actions whose name or input matches. The grid shows the chosen set by its
/// fields (FieldPropertySource, the user's ruling): its name and priority, then its actions as the
/// grid's list (Add adds to this set), each opening in place to its kind, interaction, bindings and
/// processing, named and summed up in a line by the page (InputMapRows, through the field source's
/// describe hook); an action chosen in the tree opens there. A binding's input is captured by
/// pressing it (InputCaptureEditor, the page reading the devices each frame). Every edit is one undo
/// step. A map the game could not read says so over the rows, and Save refuses it.
///
/// Where the old page laid the map out two ways to compare, each a bespoke card language, this is
/// one layout of the grid's own rows.
class InputMapEditorPage : AssetObjectPage
{
	public const String cMarkupPath = "Editor/InputMapPage.xml";
	/// The grid's section the chosen set's rows are in: its paths are "set/" and the set's own.
	public const String cSetSection = "set";

	/// The set's own path of a grid row's ("set/Actions.0" is "Actions.0").
	public static StringView SetPath(StringView gridPath)
	{
		let skip = cSetSection.Length + 1; // "set/"
		if (gridPath.StartsWith(cSetSection) && (gridPath.Length >= skip) && (gridPath[skip - 1] == '/'))
			return gridPath.Substring(skip);
		return gridPath;
	}

	/// A row of the tree: a set's, or one of its actions'.
	private struct TreeRow
	{
		public int32 Set = -1;
		/// -1: the set's row.
		public int32 Action = -1;

		public this(int32 set, int32 action)
		{
			Set = set;
			Action = action;
		}
	}

	/// The chosen set's rows; the base's sections let go of them first (ClearSections).
	private FieldPropertySource mValues = null;
	private TreeModel mModel = new .() ~ delete _;
	/// The tree's rows, by node id.
	private List<TreeRow> mRows = new .() ~ delete _;
	private int32 mSet = -1;
	private TreeRow mChosen = .(-1, -1);
	/// Choosing from code: not the user's.
	private bool mShowing = false;
	private String mSearch = new .() ~ delete _;
	/// The row listened for (empty: none).
	private String mListenPath = new .() ~ delete _;
	private CaptureFilter mListenFilter = .();
	/// What the capture editors ask of the page; they borrow it.
	private InputCaptureServices mCapture = new .() ~ delete _;
	/// The markup's: the tree holds it.
	private TreeView mTree = null;

	/// It takes `services`.
	public this(EditorContext context, AssetPageServices services, Instance instance)
		: base(context, services, instance, typeof(InputMapAsset), cMarkupPath)
	{
		HideAssetRows(); // the map's rows are the chosen set's, beside the tree
		mTree = Find<TreeView>("input-tree");
		if (let add = Find<ButtonBase>("input-add-set"))
			add.SetOnClick(new [=this] () => { AddSet(); });
		if (let remove = Find<ButtonBase>("input-remove"))
			remove.SetOnClick(new [=this] () => { RemoveChosen(); });
		if (let search = Find<TextField>("input-search"))
			search.SetOnTextChanging(new [=this] (text) => { Search(text); });
		if (mTree != null)
		{
			mTree.Model = mModel;
			mTree.SetOnSelectionChanged(new [=this] (index) =>
				{
					if (mShowing || !index.IsValid)
						return;
					let node = (int)index.InternalId;
					if ((node < 0) || (node >= mRows.Count))
						return;
					let row = mRows[node];
					if (row.Action >= 0)
						ChooseAction(row.Set, row.Action);
					else
						ChooseSet(row.Set);
				});
		}

		// The capture's questions, answered by the page. The editor asks by the grid's path, the set's
		// section's ("set/Actions.0.Bindings.0.Code"): the page's are the set's own.
		mCapture.Describe = new [=this] (path, outText) =>
			{
				if (!BindingOf(SetPath(path), let action, let binding, let direction))
					return;
				let b = Map.Sets[mSet].Actions[action].Bindings[binding];
				if (direction < 0)
				{
					BindingNames.DescribeBinding(b, outText);
					return;
				}
				uint32[4] codes = .(b.NegX, b.PosX, b.NegY, b.PosY);
				if (codes[direction] != 0)
					BindingNames.KeyName(codes[direction], outText);
				else
					outText.Append("Not set");
			};
		mCapture.Toggle = new [=this] (path) => { ToggleListen(SetPath(path)); };
		mCapture.Listening = new [=this] (path) => !mListenPath.IsEmpty && (mListenPath == SetPath(path));
		mCapture.Cancel = new [=this] () => { StopListen(); };
		if (Grid != null)
			InputCaptureEditor.Register(Grid.Editors, mCapture);

		// The chosen set's rows: its fields, said as the page says them, each edit one undo step.
		mValues = new FieldPropertySource(typeof(ActionSet), 1,
			new [=this] (object) =>
			{
				let set = SetAt(mSet);
				return (set != null) ? Internal.UnsafeCastToPtr(set) : null;
			},
			new [=this] (apply) =>
			{
				let chosen = mSet;
				EditWhole("edit_input", scope [&] (object) =>
					{
						let map = ((InputMapAsset)object).Map;
						if ((chosen >= 0) && (chosen < map.Sets.Count))
							apply(0, Internal.UnsafeCastToPtr(map.Sets[chosen]));
					});
			}, context.Resources);
		mValues.SetOnDescribe(new [=this] (path, info) =>
			{
				if (let set = SetAt(mSet))
					InputMapRows.Describe(set, path, info);
			});
		AddSection(cSetSection, "Set", mValues);
		let map = Map;
		ChooseSet(((map != null) && !map.Sets.IsEmpty) ? 0 : -1);
		ShowValidity();
	}

	public ~this()
	{
		if (mTree != null)
			mTree.Model = null;
		// The grid's rows go first: their capture editors borrow mCapture, which goes before the base
		// lets go of the grid.
		if (Grid != null)
			Grid.Source = null;
		// The grid's sections let go of the rows before they go (the base's outlive these).
		ClearSections();
		delete mValues;
	}

	/// Refused while the map is one the game could not read (it says why).
	public override Result<void, ErrorCode> Save()
	{
		let map = Map;
		let error = scope String();
		if ((map != null) && !InputMapValidation.Validate(map, error))
		{
			Context.SetStatus(scope String()..AppendF("Not saved: the game cannot read this map yet: {}", error));
			return .Err(.InvalidArgument);
		}
		return base.Save();
	}

	/// The set the grid shows (-1: none, an empty map).
	public int32 ChosenSet => mSet;

	public void ChooseSet(int32 set)
	{
		StopListen();
		mSet = set;
		mChosen = .(set, -1);
		BindSet();
		ShowTree();
	}

	/// The action's set chosen, the action opened in place and brought into view.
	public void ChooseAction(int32 set, int32 action)
	{
		if (set != mSet)
			ChooseSet(set);
		mChosen = .(set, action);
		// Opened in place: its list, then it, brought into view.
		if (let grid = Grid)
		{
			grid.SetOpen(Sections.PathIn(cSetSection, "Actions", .. scope .()), true);
			let path = Sections.PathIn(cSetSection, scope String()..AppendF("Actions.{}", action), .. scope .());
			grid.SetOpen(path, true);
			let row = grid.FindRow(path);
			if (row >= 0)
				grid.ScrollToItem(row, .Start);
		}
		ShowTree();
	}

	/// A set added after the others, chosen.
	public void AddSet()
	{
		let map = Map;
		if (map == null)
			return;
		let name = scope String();
		for (int n = 1;; n++)
		{
			name.Clear();
			name.AppendF("Set {}", n);
			bool taken = false;
			for (let set in map.Sets)
				taken = taken || (set.Name == name);
			if (!taken)
				break;
		}
		EditWhole("edit_input", scope [&] (object) =>
			{
				let set = new ActionSet();
				set.Name.Set(name);
				((InputMapAsset)object).Map.Sets.Add(set);
			});
		ChooseSet((int32)Map.Sets.Count - 1);
	}

	/// The tree's chosen row taken out: an action, or a set with its actions.
	public bool RemoveChosen()
	{
		let map = Map;
		if ((map == null) || (mChosen.Set < 0) || (mChosen.Set >= map.Sets.Count))
			return false;
		let row = mChosen;
		StopListen();
		mChosen = .(row.Set, -1);
		EditWhole("edit_input", scope [&] (object) =>
			{
				let sets = ((InputMapAsset)object).Map.Sets;
				if (row.Action < 0)
				{
					delete sets[row.Set];
					sets.RemoveAt(row.Set);
				}
				else if (row.Action < sets[row.Set].Actions.Count)
				{
					delete sets[row.Set].Actions[row.Action];
					sets[row.Set].Actions.RemoveAt(row.Action);
				}
			});
		return true;
	}

	/// Keeps the actions whose name or input holds `text` (empty: every one).
	public void Search(StringView text)
	{
		var trimmed = text;
		trimmed.Trim();
		mSearch.Set(trimmed);
		ShowTree();
	}

	/// Listens for the input of the row `path` (a binding's, or one key of a four-key one), or stops.
	public void ToggleListen(StringView path)
	{
		if (mListenPath == path)
		{
			StopListen();
			return;
		}
		if (!BindingOf(path, let action, let binding, let direction))
			return;
		mListenPath.Set(path);
		// What the action's kind takes (one key for a four-key binding's direction).
		mListenFilter = InputMapEdit.FilterFor(Map.Sets[mSet].Actions[action].Kind, direction >= 0);
		Context.SetStatus("Listening: press the input to bind (click its button again to stop)");
		// The row's editor shows that it listens itself (a refresh here could take its focus).
	}

	/// Lands what the devices gave while listening (the page's frame does it from the shell's input).
	public void LandCapture(Binding captured)
	{
		let found = BindingOf(mListenPath, let action, let binding, let direction);
		let set = mSet;
		StopListen();
		if (!found)
			return;
		EditWhole("edit_input", scope [&] (object) =>
			{
				InputMapEdit.ApplyCapture(((InputMapAsset)object).Map, set, action, binding, direction, captured);
			});
		let said = scope String("Bound ");
		BindingNames.DescribeBinding(captured, said);
		Context.SetStatus(said);
	}

	public override void OnUpdate(IApplicationHost host, float dt)
	{
		base.OnUpdate(host, dt);
		if (mListenPath.IsEmpty)
			return;
		// The devices read as the game reads them (Escape is a key a game binds: not a cancel).
		let shellInput = (host.Shell != null) ? host.Shell.Input : null;
		if (shellInput == null)
			return;
		let devices = scope ShellInputSource(shellInput);
		if (BindingCapture.Capture(devices, mListenFilter, let captured))
			LandCapture(captured);
	}

	// === For tests ===

	/// The tree's rows, indented ("Gameplay\n  Move\n  Jump"), into `outText`.
	public void Tree(String outText)
	{
		let map = Map;
		for (let row in mRows)
		{
			if (!outText.IsEmpty)
				outText.Append('\n');
			let set = map.Sets[row.Set];
			if (row.Action < 0)
				outText.Append(set.Name);
			else
				outText.AppendF("  {}", set.Actions[row.Action].Name);
		}
	}

	public IPropertySource SetRows => mValues;
	public bool IsListening => !mListenPath.IsEmpty;
	public StringView ListenPath => mListenPath;
	public InputCaptureServices CaptureServices => mCapture;

	protected override void OnObjectChanged()
	{
		// A whole edit, or its undo: the set may be gone.
		let map = Map;
		if ((map != null) && ((mSet < 0) || (mSet >= map.Sets.Count)))
			mSet = map.Sets.IsEmpty ? -1 : (int32)map.Sets.Count - 1;
		if ((mChosen.Set != mSet) || ((mChosen.Action >= 0) && (map != null) && (mSet >= 0) && (mChosen.Action >= map.Sets[mSet].Actions.Count)))
			mChosen = .(mSet, -1);
		BindSet();
		ShowTree();
		ShowValidity();
	}

	private InputMap Map
	{
		get
		{
			let asset = ObjectAs<InputMapAsset>();
			return (asset != null) ? asset.Map : null;
		}
	}

	private ActionSet SetAt(int32 set)
	{
		let map = Map;
		return ((map != null) && (set >= 0) && (set < map.Sets.Count)) ? map.Sets[set] : null;
	}

	// The set's rows read again (the field source finds the set through its resolver each time).
	private void BindSet()
	{
		if (mValues != null)
			mValues.Refresh();
	}

	private void ShowTree()
	{
		let map = Map;
		if (map == null)
			return;
		mShowing = true;
		// A set the user folded stays folded through the rebuild (a choice, an edit, a search).
		let folded = scope List<int32>();
		if (mTree != null)
		{
			for (int node < mRows.Count)
			{
				if ((mRows[node].Action < 0) && !mTree.IsIdExpanded((ItemId)node))
					folded.Add(mRows[node].Set);
			}
		}
		mModel.Clear();
		mRows.Clear();
		int32 chosen = -1;
		let text = scope String();
		let shown = scope List<int32>();
		for (int32 s < (int32)map.Sets.Count)
		{
			let set = map.Sets[s];
			// A search keeps the actions whose name or input holds it, and the sets holding one.
			shown.Clear();
			for (int32 a < (int32)set.Actions.Count)
			{
				let action = set.Actions[a];
				var matches = mSearch.IsEmpty || action.Name.Contains(mSearch, true);
				for (let binding in action.Bindings)
				{
					text.Clear();
					BindingNames.DescribeBinding(binding, text);
					matches = matches || text.Contains(mSearch, true);
				}
				if (matches)
					shown.Add(a);
			}
			if (!mSearch.IsEmpty && shown.IsEmpty && !set.Name.Contains(mSearch, true))
				continue;
			let setNode = mModel.AddNode(TreeModel.Root, set.Name);
			mModel.SetIcon(setNode, "Editor/Icons/Types/InputMapAsset.svg", "cat-scripting");
			mRows.Add(.(s, -1));
			if ((mChosen.Set == s) && (mChosen.Action < 0))
				chosen = setNode;
			for (let a in shown)
			{
				let action = set.Actions[a];
				text.Clear();
				text.AppendF("{}   {}", action.Name, InputMapEdit.KindTitle(action.Kind));
				let node = mModel.AddNode(setNode, text);
				mModel.SetIcon(node, (action.Kind == .Button) ? "Editor/Icons/play.svg" : "Editor/Icons/move.svg");
				mRows.Add(.(s, a));
				if ((mChosen.Set == s) && (mChosen.Action == a))
					chosen = node;
			}
		}
		if (mTree != null)
		{
			for (int node < mRows.Count)
			{
				if (mRows[node].Action < 0)
					mTree.SetIdExpanded((ItemId)node, !folded.Contains(mRows[node].Set));
			}
			if (chosen >= 0)
			{
				ItemId[1] id = .((ItemId)chosen);
				mTree.SetSelectedIds(id);
			}
		}
		mShowing = false;
	}

	private void ShowValidity()
	{
		let map = Map;
		let error = scope String();
		let valid = (map == null) || InputMapValidation.Validate(map, error);
		SetNotice("invalid", valid ? "" : scope String()..AppendF("The game cannot read this map yet: {}", error));
		// What it holds, in a line (the old page's totals).
		if (map != null)
		{
			int actions = 0;
			int bindings = 0;
			for (let set in map.Sets)
			{
				for (let action in set.Actions)
				{
					actions++;
					bindings += action.Bindings.Count;
				}
			}
			let holds = scope String();
			Counted(holds, map.Sets.Count, "set", "sets");
			holds.Append(", ");
			Counted(holds, actions, "action", "actions");
			holds.Append(", ");
			Counted(holds, bindings, "binding", "bindings");
			SetFact("Holds", holds);
		}
	}

	private static void Counted(String outText, int count, StringView one, StringView many)
	{
		outText.AppendF("{} {}", count, (count == 1) ? one : many);
	}

	private void StopListen()
	{
		if (mListenPath.IsEmpty)
			return;
		mListenPath.Clear();
		// A values' refresh: the rows stay, their editors shown again (the one that listened too).
		if (Grid != null)
			Grid.OnValuesChanged();
	}

	/// The binding (and the four-key slot: 0..3, -1 the whole) `path` names in the chosen set.
	private bool BindingOf(StringView path, out int action, out int binding, out int direction)
	{
		action = 0;
		binding = 0;
		direction = -1;
		let set = SetAt(mSet);
		if (set == null)
			return false;
		StringView rest = default;
		let a = InputMapRows.IndexAfter(path, "Actions.", ref rest);
		StringView field = default;
		let b = (a >= 0) ? InputMapRows.IndexAfter(rest, "Bindings.", ref field) : -1;
		if ((a < 0) || (b < 0) || (a >= set.Actions.Count) || (b >= set.Actions[a].Bindings.Count))
			return false;
		action = a;
		binding = b;
		direction = (field == "NegX") ? 0 : ((field == "PosX") ? 1 : ((field == "NegY") ? 2 : ((field == "PosY") ? 3 : -1)));
		return true;
	}
}
