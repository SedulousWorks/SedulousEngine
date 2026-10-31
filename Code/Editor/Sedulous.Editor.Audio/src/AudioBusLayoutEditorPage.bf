using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Content;
using Sedulous.Audio.Pipeline;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Audio;

/// The mixer's buses, on the GUI from its markup (Data/Editor/BusLayoutPage.xml; Raptor's editor-gui
/// spec, 5.4, layer 5). The buses' tree (the four fixed ones, Master and Effects, Music and UI under
/// it, and the custom ones under their parents) on the GUI's tree beside the grid, which shows the
/// chosen bus: a custom one's name and parent (only the parents that make no cycle offered), then its
/// mix (volume, mute), its filters, its delay and its reverb (each off at 0). The tree's bar and a
/// row's menu add a bus and remove a custom one. Each edit is one undo step, where the old page kept
/// its own blob commands; the rules they keep (a name a bus's own, children following a rename,
/// moving to Master when their parent goes) are BusLayoutModel's. A layout whose buses make a cycle
/// (one the cook refuses) says so.
class AudioBusLayoutEditorPage : AssetObjectPage
{
	public const String cMarkupPath = "Editor/BusLayoutPage.xml";

	/// A bus's setting as a row: its path, its name, its group (a section of the grid), what it says
	/// of itself, and its range (a number's; a flag has none).
	private struct EffectRow
	{
		public StringView Path;
		public StringView Shown;
		public int Group;
		public StringView Description;
		public double Min;
		public double Max;
		public double Step;
		public bool Flag;

		public this(StringView path, StringView shown, int group, StringView description, double min, double max, double step, bool flag = false)
		{
			Path = path;
			Shown = shown;
			Group = group;
			Description = description;
			Min = min;
			Max = max;
			Step = step;
			Flag = flag;
		}
	}

	/// The settings' groups, each a section of the grid, in order.
	public static readonly StringView[4] cGroups = .("Mix", "Filters", "Delay", "Reverb");

	private static readonly EffectRow[9] cEffects = .(
		.("volume", "Volume", 0, "", 0.0, 2.0, 0.01),
		.("muted", "Muted", 0, "", 0.0, 0.0, 0.0, true),
		.("lowpassHz", "Lowpass (Hz)", 1, "Cuts what is above it; 0 is off", 0.0, 22000.0, 10.0),
		.("highpassHz", "Highpass (Hz)", 1, "Cuts what is below it; 0 is off", 0.0, 22000.0, 10.0),
		.("delaySeconds", "Delay (s)", 2, "The echo's delay; 0 is off", 0.0, 2.0, 0.01),
		.("delayDecay", "Decay", 2, "How much of each echo comes back", 0.0, 1.0, 0.01),
		.("reverbWet", "Wet", 3, "How much reverb is heard; 0 is off", 0.0, 1.0, 0.01),
		.("reverbRoomSize", "Room Size", 3, "", 0.0, 1.0, 0.01),
		.("reverbDamping", "Damping", 3, "How fast its high end fades", 0.0, 1.0, 0.01));

	private TreeModel mModel = new .() ~ delete _;
	/// The tree's rows, by node id.
	private List<BusRow> mRows = new .() ~ DeleteContainerAndItems!(_);
	private BusRef mSelected = BusRef.Master;
	/// Selecting from code: not the user's choice.
	private bool mShowing = false;
	/// The rows; the base's sections let go of them first (ClearSections).
	private Sedulous.GUI.PropertyBag mBusRows = null;
	private Sedulous.GUI.PropertyBag[4] mEffectRows = .(null, null, null, null);
	// The markup's: the tree holds them.
	private TreeView mTree = null;
	private ButtonBase mRemove = null;
	private uint32 mMenuListener = 0;
	/// The page's reference; open over the tree while shown.
	private Sedulous.GUI.Menu mMenu = null ~ _?.ReleaseRef();

	/// It takes `services`.
	public this(EditorContext context, AssetPageServices services, Instance instance)
		: base(context, services, instance, typeof(AudioBusLayoutAsset), cMarkupPath)
	{
		HideAssetRows(); // the layout's fields are a fixed bank of buses: its rows are the chosen bus's
		mTree = Find<TreeView>("bus-tree");
		mRemove = Find<ButtonBase>("bus-remove");
		if (let add = Find<ButtonBase>("bus-add"))
			add.SetOnClick(new [=this] () => { AddBus(); });
		if (mRemove != null)
			mRemove.SetOnClick(new [=this] () => { RemoveSelected(); });
		if (mTree != null)
		{
			mTree.Model = mModel;
			mTree.SetOnSelectionChanged(new [=this] (index) =>
				{
					if (mShowing || !index.IsValid)
						return;
					let row = (int)index.InternalId;
					if ((row >= 0) && (row < mRows.Count))
						Select(mRows[row].Bus);
				});
			mMenuListener = mTree.AddEventListener(.ContextMenu, new [=this] (e) =>
				{
					let at = ((MouseEvent)e).Position;
					ShowMenu(mTree.ItemAt(at), at);
					e.Handled = true;
				});
		}
		BuildRows();
		ShowTree();
		ShowBus();
	}

	public ~this()
	{
		if ((mMenu != null) && mMenu.IsOpen)
			mMenu.Close();
		if (mTree != null)
		{
			mTree.RemoveEventListener(mMenuListener);
			mTree.Model = null;
		}
		// The grid's sections let go of the rows before they go (the base's outlive these).
		ClearSections();
		delete mBusRows;
		for (let rows in mEffectRows)
			delete rows;
	}

	/// The bus the grid shows (Master when the page opens).
	public BusRef Selected => mSelected;

	public void Select(BusRef bus)
	{
		mSelected = bus;
		ShowTree();
		ShowBus();
	}

	/// A bus under Master in the first free slot, chosen; false when every slot is in use.
	public bool AddBus()
	{
		let layout = Layout;
		if (layout == null)
			return false;
		bool room = false;
		for (let slot in layout.Custom)
			room = room || slot.Name.IsEmpty;
		if (!room)
		{
			Context.SetStatus("Every custom bus slot is in use: remove one to add another.");
			return false;
		}
		int32 added = -1;
		EditWhole("edit_buslayout", scope [&] (object) => { added = BusLayoutModel.AddBus((AudioBusLayoutAsset)object); });
		if (added >= 0)
			Select(BusRef.OfSlot(added));
		return added >= 0;
	}

	/// The chosen bus taken out (a custom one; its children move to Master), Master chosen.
	public bool RemoveSelected()
	{
		if ((Layout == null) || mSelected.IsFixed || !mSelected.IsValid)
			return false;
		let slot = mSelected.Slot;
		mSelected = BusRef.Master;
		EditWhole("edit_buslayout", scope [&] (object) => { BusLayoutModel.RemoveBus((AudioBusLayoutAsset)object, slot); });
		return true;
	}

	// === For tests ===

	/// The tree's rows, indented by depth ("Master\n  Effects\n    Footsteps"), into `outText`.
	public void Tree(String outText)
	{
		for (let row in mRows)
		{
			if (!outText.IsEmpty)
				outText.Append('\n');
			for (int32 d < row.Depth)
				outText.Append("  ");
			outText.Append(row.Name);
		}
	}

	public Sedulous.GUI.PropertyBag BusRows => mBusRows;

	/// The chosen bus's settings of one group: "Mix", "Filters", "Delay" or "Reverb".
	public Sedulous.GUI.PropertyBag EffectRows(StringView group) => mEffectRows[GroupOf(group)];

	/// An edit of a row as the grid commits one (`rows` one of the page's bags).
	public void EditRow(Sedulous.GUI.PropertyBag rows, StringView path, Sedulous.GUI.Variant value)
	{
		rows.SetValue(path, 0, value); // as the grid's commit leaves it
		Committed(rows, path, value);
	}

	protected override void OnObjectChanged()
	{
		ShowTree();
		ShowBus();
	}

	private AudioBusLayoutAsset Layout => ObjectAs<AudioBusLayoutAsset>();

	private static int GroupOf(StringView group)
	{
		for (int g < cGroups.Count)
		{
			if (cGroups[g] == group)
				return g;
		}
		return 0;
	}

	private void BuildRows()
	{
		mBusRows = new Sedulous.GUI.PropertyBag();
		for (int g < mEffectRows.Count)
			mEffectRows[g] = new Sedulous.GUI.PropertyBag();
		let name = mBusRows.Add("name", .String);
		name.DisplayName.Set("Name");
		name.Description.Set("Its own: not a fixed bus's nor another's; its children follow it");
		let parent = mBusRows.Add("parent", .Enum);
		parent.DisplayName.Set("Parent");
		parent.Description.Set("The bus it mixes into: a fixed one, or a custom one that is not under it");
		for (let effect in cEffects)
		{
			let info = mEffectRows[effect.Group].Add(effect.Path, effect.Flag ? .Bool : .Float);
			info.DisplayName.Set(effect.Shown);
			if (!effect.Description.IsEmpty)
				info.Description.Set(effect.Description);
			if (!effect.Flag)
			{
				info.HasRange = true;
				info.Min = effect.Min;
				info.Max = effect.Max;
				info.Step = effect.Step;
				info.Hint.Set("slider");
			}
		}
		for (let rows in Sedulous.GUI.PropertyBag[5](mBusRows, mEffectRows[0], mEffectRows[1], mEffectRows[2], mEffectRows[3]))
		{
			rows.SetOnCommit(new [=this, =rows] (commit) =>
				{
					if (!commit.After.IsEmpty)
						Committed(rows, commit.Path, commit.After[0]);
				});
			rows.PropertiesChanged(); // Add told the grid before the rows' names were set
		}
		AddSection("bus", "Bus", mBusRows);
		for (int g < cGroups.Count)
			AddSection(cGroups[g], cGroups[g], mEffectRows[g]);
	}

	/// The tree from the layout, the chosen bus's row selected.
	private void ShowTree()
	{
		let layout = Layout;
		if (layout == null)
			return;
		ClearAndDeleteItems!(mRows);
		BusLayoutModel.BusTree(layout, mRows);
		bool found = false;
		for (let row in mRows)
			found = found || (row.Bus == mSelected);
		if (!found)
			mSelected = BusRef.Master; // gone (removed, an undo): Master
		mShowing = true;
		mModel.Clear();
		let parents = scope List<int32>(); // the last node at each depth
		int32 chosen = -1;
		for (let row in mRows)
		{
			let parent = ((row.Depth > 0) && (row.Depth - 1 < parents.Count)) ? parents[row.Depth - 1] : TreeModel.Root;
			let node = mModel.AddNode(parent, row.Name);
			mModel.SetIcon(node, "Editor/Icons/speaker.svg");
			while (parents.Count > row.Depth)
				parents.PopBack();
			parents.Add(node);
			if (row.Bus == mSelected)
				chosen = node;
		}
		if (mTree != null)
		{
			for (int node < mRows.Count)
				mTree.SetIdExpanded((ItemId)node, true);
			if (chosen >= 0)
			{
				ItemId[1] id = .((ItemId)chosen);
				mTree.SetSelectedIds(id);
			}
		}
		mShowing = false;
		if (mRemove != null)
			mRemove.Enabled = !mSelected.IsFixed;
		SetNotice("cycle", BusLayoutModel.HasBusCycle(layout)
			? "Some buses are under each other in a loop: the cook refuses the layout until one moves to a fixed bus." : "");
	}

	/// The chosen bus's rows: its name and parent shown for a custom one, its values.
	private void ShowBus()
	{
		let layout = Layout;
		if ((layout == null) || (mBusRows == null))
			return;
		let bus = BusLayoutModel.BusSettings(layout, mSelected);
		if (bus == null)
			return;
		// A custom bus's name and parent; a fixed one has neither to change.
		let custom = !mSelected.IsFixed;
		let name = mBusRows.FindInfo("name");
		let parent = mBusRows.FindInfo("parent");
		name.Visible = custom;
		parent.Visible = custom;
		ClearAndDeleteItems!(parent.Choices);
		if (custom)
		{
			let choices = scope List<String>();
			defer { ClearAndDeleteItems!(choices); }
			BusLayoutModel.BusParentChoices(layout, mSelected.Slot, choices);
			int64 current = 0;
			let own = (StringView)layout.Custom[mSelected.Slot].Parent;
			for (int i < choices.Count)
			{
				parent.AddChoice(choices[i], i);
				if (BusLayoutModel.NamesMatch(choices[i], own.IsEmpty ? BusLayoutModel.cFixedNames[0] : own))
					current = i;
			}
			mBusRows.PropertiesChanged();
			mBusRows.SetValue("name", 0, Sedulous.GUI.Variant(BusLayoutModel.BusName(layout, mSelected)));
			mBusRows.SetValue("parent", 0, Sedulous.GUI.Variant(current));
		}
		else
			mBusRows.PropertiesChanged();
		for (let effect in cEffects)
			mEffectRows[effect.Group].SetValue(effect.Path, 0, ReadEffect(bus, effect.Path));
	}

	private void Committed(Sedulous.GUI.PropertyBag rows, StringView path, Sedulous.GUI.Variant value)
	{
		let layout = Layout;
		if (layout == null)
			return;
		let bus = mSelected;
		if (rows === mBusRows)
		{
			if (bus.IsFixed)
				return;
			if (path == "name")
			{
				var trimmed = value.AsString;
				trimmed.Trim();
				let name = scope String(trimmed);
				// Refused (empty, a fixed bus's, another's): the row shows the name it has.
				let owner = BusLayoutModel.FindBusSlot(layout, name);
				if (name.IsEmpty || BusLayoutModel.IsFixedBusName(name) || ((owner >= 0) && (owner != bus.Slot)))
				{
					Context.SetStatus(scope String()..AppendF("\"{}\" cannot name this bus: a name is a bus's own, and not a fixed bus's.", name));
					ShowBus();
					return;
				}
				EditWhole("edit_buslayout", scope [&] (object) => { BusLayoutModel.RenameBus((AudioBusLayoutAsset)object, bus.Slot, name); });
			}
			else if (path == "parent")
			{
				let choices = scope List<String>();
				defer { ClearAndDeleteItems!(choices); }
				BusLayoutModel.BusParentChoices(layout, bus.Slot, choices);
				let index = value.AsInt;
				if ((index < 0) || (index >= choices.Count))
					return;
				let chosen = choices[(int)index];
				EditWhole("edit_buslayout", scope [&] (object) => { BusLayoutModel.ReparentBus((AudioBusLayoutAsset)object, bus.Slot, chosen); });
			}
			return;
		}
		for (let effect in cEffects)
		{
			if (path != effect.Path)
				continue;
			let flag = value.AsBool;
			let number = (float)value.AsFloat;
			let field = effect.Path;
			EditWhole("edit_buslayout", scope [&] (object) =>
				{
					if (let settings = BusLayoutModel.BusSettings((AudioBusLayoutAsset)object, bus))
						WriteEffect(settings, field, flag, number);
				});
			return;
		}
	}

	private static Sedulous.GUI.Variant ReadEffect(AudioBusAuthoring bus, StringView path)
	{
		switch (path)
		{
		case "volume": return .((double)bus.Volume);
		case "muted": return .(bus.Muted);
		case "lowpassHz": return .((double)bus.LowpassHz);
		case "highpassHz": return .((double)bus.HighpassHz);
		case "delaySeconds": return .((double)bus.DelaySeconds);
		case "delayDecay": return .((double)bus.DelayDecay);
		case "reverbWet": return .((double)bus.ReverbWet);
		case "reverbRoomSize": return .((double)bus.ReverbRoomSize);
		case "reverbDamping": return .((double)bus.ReverbDamping);
		default: return .();
		}
	}

	private static void WriteEffect(AudioBusAuthoring bus, StringView path, bool flag, float number)
	{
		switch (path)
		{
		case "volume": bus.Volume = number;
		case "muted": bus.Muted = flag;
		case "lowpassHz": bus.LowpassHz = number;
		case "highpassHz": bus.HighpassHz = number;
		case "delaySeconds": bus.DelaySeconds = number;
		case "delayDecay": bus.DelayDecay = number;
		case "reverbWet": bus.ReverbWet = number;
		case "reverbRoomSize": bus.ReverbRoomSize = number;
		case "reverbDamping": bus.ReverbDamping = number;
		}
	}

	/// The menu of the row at item `item` (-1: the background's) at `at`, where the press was.
	private void ShowMenu(int32 item, Float2 at)
	{
		if (mTree == null)
			return;
		// A press on a row chooses it first, so Remove acts on it.
		if (item >= 0)
		{
			let index = mTree.GetItemIndex(item);
			let row = (int)index.InternalId;
			if (index.IsValid && (row >= 0) && (row < mRows.Count))
				Select(mRows[row].Bus);
		}
		if (mMenu != null)
		{
			if (mMenu.IsOpen)
				mMenu.Close();
			mMenu.ReleaseRef();
		}
		mMenu = new Sedulous.GUI.Menu();
		mMenu.AddItem("Add Bus", new [=this] () => { AddBus(); });
		if (!mSelected.IsFixed)
			mMenu.AddItem("Remove Bus", new [=this] () => { RemoveSelected(); });
		mMenu.Open(mTree, at);
	}
}
