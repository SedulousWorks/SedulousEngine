using System;
using Sedulous.Content;
using Sedulous.UI;

namespace Sedulous.Editor.App;

/// The AssetPickerDialog's sibling for content groups: a modal picker over the project's
/// group hierarchy, shown as the same left-hand group tree the asset picker uses. Used to
/// choose an import destination group; the current group is preselected. Single-click
/// selects, double-click or Select confirms, Cancel and Escape dismiss. The result is
/// delivered through OnPicked before the dialog closes; Cancel fires nothing.
class GroupPickerDialog : Dialog
{
	/// The pick result, the chosen group. Fired once, before close. Owned.
	public delegate void(Group group) OnPicked ~ delete _;

	/// Borrowed: the content owns it.
	private TreeView mTree;
	private GroupTreeAdapter mGroups = new .() ~ delete _;
	private Group mSelectedGroup = null;

	public this(StringView title, Group root, Group preselect) : base(title)
	{
		mSelectedGroup = preselect;
		MinWidth.Value = 420.0f;
		MinHeight.Value = 340.0f;
		MaxWidth.Value = 520.0f;
		MaxHeight.Value = 420.0f;

		let column = new FlexLayout();
		column.Direction = .Vertical;
		column.Spacing = 6;

		mTree = new TreeView();
		mTree.ItemHeight = 20.0f;
		mTree.OnItemClick.Add(new (info) =>
			{
				if (let group = mGroups.GroupAt(info.NodeId))
				{
					mSelectedGroup = group;
					if (info.ClickCount >= 2)
						Confirm();
				}
			});
		var grow = LayoutStyle();
		grow.Width = SizeSpec.Match();
		grow.FlexGrow = 1.0f;
		column.AddView(mTree, grow);
		SetContent(column);

		let select = AddButton("Select", .None);
		select.OnClick.Add(new (b) => { Confirm(); });
		AddButton("Cancel", .Cancel);

		mGroups.Rebuild(root);
		if (mSelectedGroup == null)
			mSelectedGroup = root;
		mGroups.AttachExpanded(mTree);
	}

	public ~this()
	{
		mTree.SetAdapter(null);
	}

	private void Confirm()
	{
		if (OnPicked != null)
			OnPicked(mSelectedGroup);
		Close(.OK);
	}
}
