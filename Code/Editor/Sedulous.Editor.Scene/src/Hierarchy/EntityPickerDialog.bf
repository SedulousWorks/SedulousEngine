using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.UI;

namespace Sedulous.Editor.Scene;

/// Picks an entity from the scene's tree, with a name filter: what an EntityRef field's
/// picker opens. Select, Clear (a nil reference) or Cancel. The scene is borrowed.
class EntityPickerDialog : Dialog
{
	public delegate void(Guid) OnPicked ~ delete _;

	private Sedulous.Scene.Scene mScene;
	private Guid mCurrent;
	private TreeView mTree;
	private EditText mFilterEdit;
	private EntityTreeSnapshot mSnapshot = new .() ~ delete _;
	private EntityTreeAdapter mAdapter ~ delete _;
	private int32 mSelected = -1;

	public this(Sedulous.Scene.Scene scene, Guid current) : base("Select entity")
	{
		mScene = scene;
		mCurrent = current;
		MinWidth.Value = 360.0f;
		MinHeight.Value = 380.0f;
		MaxWidth.Value = 520.0f;
		MaxHeight.Value = 560.0f;

		let column = new FlexLayout();
		column.Direction = .Vertical;
		column.Spacing = 6;

		mFilterEdit = new EditText();
		mFilterEdit.SetPlaceholder("Filter...");
		mFilterEdit.OnTextChanged.Add(new [=this](edit) =>
		{
			mSnapshot.Filter.Set(edit.Text);
			RebuildTree();
		});
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		column.AddView(mFilterEdit, match);

		mAdapter = new EntityTreeAdapter(mSnapshot);
		mTree = new TreeView();
		mTree.ItemHeight = 20.0f;
		mAdapter.SetTree(mTree);
		mTree.SetAdapter(mAdapter);
		mTree.OnItemClick.Add(new [=this](info) =>
		{
			if (mSnapshot.InRange(info.NodeId))
			{
				mSelected = info.NodeId;
				if (info.ClickCount >= 2)
					Confirm(mSnapshot.Nodes[info.NodeId].Id);
			}
		});
		var grow = LayoutStyle();
		grow.Width = SizeSpec.Match();
		grow.FlexGrow = 1.0f;
		column.AddView(mTree, grow);
		SetContent(column);

		let select = AddButton("Select", .None);
		select.OnClick.Add(new [=this](b) =>
		{
			if (mSnapshot.InRange(mSelected))
				Confirm(mSnapshot.Nodes[mSelected].Id);
		});
		let clear = AddButton("Clear", .None);
		clear.OnClick.Add(new [=this](b) => { Confirm(.()); });
		AddButton("Cancel", .Cancel);

		RebuildTree();
	}

	public ~this()
	{
		mTree.SetAdapter(null);
	}

	public int NodeCount => mSnapshot.Count;
	public int32 SelectedNode => mSelected;

	private void Confirm(Guid id)
	{
		if (OnPicked != null)
			OnPicked(id);
		Close(.OK);
	}

	private void RebuildTree()
	{
		mSnapshot.Rebuild(mScene);
		mSelected = mSnapshot.IndexOf(mCurrent);
		if (let flat = mTree.FlatAdapter)
		{
			for (int32 i < (int32)mSnapshot.Count)
				flat.Expand(i); // parents only take effect
			flat.RebuildVisibleList(); // repopulate from the source and notify the list
		}
	}
}
