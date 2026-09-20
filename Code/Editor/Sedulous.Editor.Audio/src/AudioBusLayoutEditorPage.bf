using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.Audio.Pipeline;
using Sedulous.Runtime.Client;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Audio;

/// The bus layout page: the bus tree on the left (the four fixed buses, custom slots
/// under whatever they name as parent), an inspector for the selected bus on the right:
/// its mix, filter, delay and reverb rows, and for a custom bus its name, parent and
/// removal. Every edit is a whole asset snapshot command.
class AudioBusLayoutEditorPage : UIEditorPage
{
	/// Borrowed.
	private EditorContext mContext;
	private String mTitle = new .() ~ delete _;
	/// Owned; null when the read failed and the page opened empty.
	private AudioBusLayoutAsset mAsset = null ~ delete _;

	/// Borrowed: the content owns them.
	private DraggableTreeView mTree = null;
	private PropertyGrid mGrid = null;
	private Label mInspectorTitle = null;
	private View mContent = null ~ { if (_ != null) _.ReleaseRef(); };
	private PageToolbar mToolbar = null;

	private BusTreeSnapshot mSnapshot = new .() ~ delete _;
	private BusLayoutTreeAdapter mAdapter = null ~ delete _;
	/// Master by default.
	private int32 mSelectedNode = 0;
	private List<uint8> mUndoBaseline = new .() ~ delete _;
	/// What the in place rows report through; borrowed by every row.
	private InPlaceRows.Commit mCommit = new => CommitEdit ~ delete _;

	public this(EditorContext context, Instance instance)
	{
		mContext = context;
		mTitle.Set(instance.Name);
		InstanceId = instance.Id;
		let object = instance.ReadObject();
		mAsset = object as AudioBusLayoutAsset;
		if ((object != null) && (mAsset == null))
			delete object;
		if (mAsset == null)
			GlobalLog(.Error, "Editor: bus layout '{}' failed to read, page opens empty", mTitle);
		Snapshot(mUndoBaseline);

		mAdapter = new BusLayoutTreeAdapter(mSnapshot);
		mAdapter.SetAsset(mAsset);
		mTree = new DraggableTreeView();
		mTree.ItemHeight = 22.0f;
		mTree.DragEnabled = false;
		mAdapter.SetTree(mTree.InternalTreeView);
		mTree.SetAdapter(mAdapter);
		mTree.InternalTreeView.OnItemClick.Add(new [=this](info) =>
			{
				if (!mSnapshot.InRange(info.NodeId))
					return;
				mSelectedNode = info.NodeId;
				if (let ctx = Ctx)
					ctx.MutationQueue.QueueAction(new [=this]() => { RebuildInspector(); });
				else
					RebuildInspector();
			});
		let addBus = new Button("+ Add Bus");
		addBus.OnClick.Add(new [=this](btn) =>
			{
				QueueStructural("add-bus", new [=this]() =>
					{
						if (AudioBusLayoutEdit.AddBus(mAsset) < 0)
							GlobalLog(.Warning, "Editor: bus layout: all {} custom slots in use", AudioBusLayoutAsset.cCustomBusSlotCount);
					});
			});
		let leftColumn = new FlexLayout();
		leftColumn.Direction = .Vertical;
		leftColumn.Spacing = 4.0f;
		leftColumn.Padding = .(6, 4);
		var growMatch = LayoutStyle();
		growMatch.FlexGrow = 1.0f;
		growMatch.Width = SizeSpec.Match();
		leftColumn.AddView(mTree, growMatch);
		var buttonStyle = LayoutStyle();
		buttonStyle.Width = SizeSpec.Match();
		buttonStyle.Height = SizeSpec.Fixed(Unit.Dp(26.0f));
		leftColumn.AddView(addBus, buttonStyle);

		mGrid = new PropertyGrid();
		mInspectorTitle = new Label();
		mInspectorTitle.FontSize.Value = 12.0f;
		let rightColumn = new FlexLayout();
		rightColumn.Direction = .Vertical;
		rightColumn.Spacing = 4.0f;
		rightColumn.Padding = .(6, 4);
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		rightColumn.AddView(mInspectorTitle, match);
		rightColumn.AddView(mGrid, growMatch);

		let split = new SplitView();
		split.SplitRatio = 0.34f;
		split.SetPanes(leftColumn, rightColumn);
		mToolbar = new PageToolbar(this);
		let column = new FlexLayout();
		column.Direction = .Vertical;
		column.AddView(mToolbar, match);
		column.AddView(split, growMatch);
		mContent = column;
		RebuildTree();
		RebuildInspector();
	}

	public ~this()
	{
		if (mTree != null)
			mTree.SetAdapter(null);
	}

	public override StringView Title => mTitle;
	public override View ContentView => mContent;
	public AudioBusLayoutAsset Asset => mAsset;
	public BusTreeSnapshot Tree => mSnapshot;
	public int32 SelectedNode => mSelectedNode;

	private UIContext Ctx => ((mTree != null) && (mTree.InternalTreeView != null)) ? mTree.InternalTreeView.Context : null;

	public override void OnUpdate(IApplicationHost host, float dt)
	{
		if (mToolbar != null)
			mToolbar.Refresh();
	}

	public override void OnClose()
	{
		if (mTree != null)
			mTree.SetAdapter(null);
	}

	public override Result<void, ErrorCode> Save()
	{
		if ((mAsset == null) || (mContext.Project == null))
			return .Err(.NotFound);
		let instance = mContext.Project.SourceDb.GetInstance(InstanceId);
		if (instance == null)
			return .Err(.NotFound);
		let saved = instance.WriteObject(mAsset);
		if (saved case .Ok)
		{
			ClearDirty();
			mContext.RequestCook(false);
			GlobalLog(.Information, "Editor: saved bus layout '{}'", mTitle);
		}
		return saved;
	}

	/// The node table from the asset, every node expanded.
	private void RebuildTree()
	{
		mSnapshot.Rebuild(mAsset);
		if (mSelectedNode >= mSnapshot.Nodes.Count)
			mSelectedNode = 0;
		mTree.SetAdapter(mAdapter);
		if (let flat = mTree.InternalTreeView.FlatAdapter)
		{
			for (int32 i < (int32)mSnapshot.Nodes.Count)
			{
				if (!mSnapshot.Nodes[i].Children.IsEmpty)
					flat.Expand(i);
			}
		}
		mTree.InternalTreeView.InternalListView.NotifyDataChanged();
	}

	private void RebuildInspector()
	{
		mGrid.Clear();
		if ((mAsset == null) || !mSnapshot.InRange(mSelectedNode))
		{
			mInspectorTitle.SetText("");
			return;
		}
		let node = mSnapshot.Nodes[mSelectedNode];
		let bus = BusTreeSnapshot.BusOf(mAsset, node);
		if (bus == null)
		{
			mInspectorTitle.SetText("");
			return;
		}
		if (node.Fixed)
			mInspectorTitle.SetText(AudioBusLayoutEdit.FixedNames[node.FixedIndex]);
		else
			BuildCustomRows(node.SlotIndex);
		BusRows(bus);
	}

	/// The custom bus's name, parent and removal.
	private void BuildCustomRows(int32 slotIndex)
	{
		let slot = mAsset.Custom[slotIndex];
		mInspectorTitle.SetText(slot.Name);
		mGrid.AddProperty(new StringEditor("Name", slot.Name, new [=this, =slotIndex](v) =>
			{
				if (v.IsEmpty || AudioBusLayoutEdit.IsFixedBusName(v) || (AudioBusLayoutEdit.FindSlotByName(mAsset, v) >= 0))
					return; // invalid or a duplicate: the old name stays
				let name = new String(v);
				QueueStructural("bus-rename", new [=this, =slotIndex, =name]() => { AudioBusLayoutEdit.RenameBus(mAsset, slotIndex, name); } ~ delete name);
			}, "Bus"));

		// The parents on offer: the fixed buses, then every other named slot that would not
		// loop back to this one.
		let owned = new List<String>();
		for (let fixedName in AudioBusLayoutEdit.FixedNames)
			owned.Add(new String(fixedName));
		for (int32 i < (int32)mAsset.Custom.Count)
		{
			if ((i == slotIndex) || mAsset.Custom[i].Name.IsEmpty)
				continue;
			if (AudioBusLayoutEdit.WouldCycle(mAsset, slotIndex, mAsset.Custom[i].Name))
				continue;
			owned.Add(new String(mAsset.Custom[i].Name));
		}
		let items = scope List<StringView>();
		for (let s in owned)
			items.Add(s);
		int32 current = 0;
		for (int32 i < (int32)owned.Count)
		{
			if ((StringView.Compare(owned[i], slot.Parent, true) == 0))
			{
				current = i;
				break;
			}
		}
		mGrid.AddProperty(new EnumEditor("Parent", current, items, new [=this, =slotIndex, =owned](v) =>
			{
				if ((v < 0) || (v >= owned.Count))
					return;
				let parent = new String(owned[v]);
				QueueStructural("bus-parent", new [=this, =slotIndex, =parent]() => { mAsset.Custom[slotIndex].Parent.Set(parent); } ~ delete parent);
			} ~ DeleteContainerAndItems!(owned), "Bus"));
		mGrid.AddProperty(new ButtonEditor("Remove Bus", new [=this, =slotIndex]() =>
			{
				QueueStructural("bus-remove", new [=this, =slotIndex]() =>
					{
						AudioBusLayoutEdit.RemoveBus(mAsset, slotIndex);
						mSelectedNode = 0;
					});
			}, "Bus"));
	}

	/// The rows every bus has: mix, filter, delay and reverb, edited in place.
	private void BusRows(AudioBusAuthoring bus)
	{
		let g = mGrid;
		InPlaceRows.Float(g, "Volume", &bus.Volume, "Mix", mCommit, 0.0, 2.0, 0.01);
		InPlaceRows.Bool(g, "Muted", &bus.Muted, "Mix", mCommit);
		InPlaceRows.Float(g, "Lowpass Hz (0 = off)", &bus.LowpassHz, "Filter", mCommit, 0.0, 22000.0, 10.0);
		InPlaceRows.Float(g, "Highpass Hz (0 = off)", &bus.HighpassHz, "Filter", mCommit, 0.0, 22000.0, 10.0);
		InPlaceRows.Float(g, "Delay s (0 = off)", &bus.DelaySeconds, "Delay", mCommit, 0.0, 2.0, 0.01);
		InPlaceRows.Float(g, "Delay Decay", &bus.DelayDecay, "Delay", mCommit, 0.0, 1.0, 0.01);
		InPlaceRows.Float(g, "Reverb Wet (0 = off)", &bus.ReverbWet, "Reverb", mCommit, 0.0, 1.0, 0.01);
		InPlaceRows.Float(g, "Reverb Room Size", &bus.ReverbRoomSize, "Reverb", mCommit, 0.0, 1.0, 0.01);
		InPlaceRows.Float(g, "Reverb Damping", &bus.ReverbDamping, "Reverb", mCommit, 0.0, 1.0, 0.01);
	}

	/// A shape change: runs `mutate` off the tree's own event, commits, then rebuilds the
	/// tree and the inspector. `mutate` is consumed.
	private void QueueStructural(StringView undoKey, delegate void() mutate)
	{
		let key = new String(undoKey);
		delegate void() run = new [=this, =mutate, =key]() =>
			{
				mutate();
				CommitEdit(key);
				RebuildTree();
				RebuildInspector();
			} ~ { delete mutate; delete key; };
		if (let ctx = Ctx)
			ctx.MutationQueue.QueueAction(run);
		else
		{
			run();
			delete run;
		}
	}

	private void Snapshot(List<uint8> outBlob)
	{
		outBlob.Clear();
		if (mAsset != null)
			AudioBusLayoutEdit.Snapshot(mAsset, outBlob);
	}

	/// Restores a snapshot, the undo and redo path; the panels rebuild, deferred.
	public void ApplyAssetBlob(List<uint8> blob)
	{
		if ((mAsset == null) || !AudioBusLayoutEdit.Apply(mAsset, blob))
			return;
		mUndoBaseline.Clear();
		mUndoBaseline.AddRange(blob);
		if (let ctx = Ctx)
		{
			ctx.MutationQueue.QueueAction(new [=this]() =>
				{
					RebuildTree();
					RebuildInspector();
				});
		}
		else
		{
			RebuildTree();
			RebuildInspector();
		}
		MarkDirty();
	}

	public void CommitEdit(StringView mergeKey)
	{
		let after = scope List<uint8>();
		Snapshot(after);
		Commands.Execute(new EditBusLayoutCommand(this, mergeKey, mUndoBaseline, after));
		mUndoBaseline.Clear();
		mUndoBaseline.AddRange(after);
		MarkDirty();
	}
}
