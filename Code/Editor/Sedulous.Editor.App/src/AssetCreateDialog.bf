using System;
using Sedulous.Content;
using Sedulous.UI;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App;

/// The new-asset twin of the AssetPickerDialog: choose a group (the same tree) and an asset
/// name, with live validation refusing an empty name or one that already exists in the
/// chosen group. Type-agnostic: it never creates anything itself; Create fires OnCreate with
/// the group and name and the caller constructs its asset type, then typically loads it by
/// the new instance's guid. First consumer: the animation panel's Create Clip.
class AssetCreateDialog : Dialog
{
	/// Create confirmed: the chosen group and a validated name, non-empty and unique in the
	/// group. Fired once, before the dialog closes. Owned.
	public delegate void(Group group, StringView name) OnCreate ~ delete _;

	/// Borrowed.
	private EditorContext mContext;
	// Borrowed: the content owns them.
	private TreeView mTree;
	private EditText mNameEdit;
	private Label mValidationLabel;
	private Button mCreateButton = null;
	private GroupTreeAdapter mGroups = new .() ~ delete _;
	private Group mSelectedGroup = null;
	private bool mValid = false;

	public this(EditorContext context, StringView title, StringView namePlaceholder) : base(title)
	{
		mContext = context;
		MinWidth.Value = 420.0f;
		MinHeight.Value = 360.0f;
		MaxWidth.Value = 520.0f;
		MaxHeight.Value = 460.0f;

		let column = new FlexLayout();
		column.Direction = .Vertical;
		column.Spacing = 6;

		// The group tree, the picker's shape: one root, expanded.
		mTree = new TreeView();
		mTree.ItemHeight = 20.0f;
		mTree.OnItemClick.Add(new (info) =>
			{
				if (let group = mGroups.GroupAt(info.NodeId))
				{
					mSelectedGroup = group;
					Validate();
				}
			});
		var grow = LayoutStyle();
		grow.Width = SizeSpec.Match();
		grow.FlexGrow = 1.0f;
		column.AddView(mTree, grow);

		mNameEdit = new EditText();
		mNameEdit.Placeholder.Value.Set(namePlaceholder);
		mNameEdit.OnTextChanged.Add(new (edit) => { Validate(); });
		var match = LayoutStyle();
		match.Width = SizeSpec.Match();
		column.AddView(mNameEdit, match);

		// The validation line names the refusal; the Create button alone going dead would be
		// a silent no.
		mValidationLabel = new Label("");
		mValidationLabel.FontSize.Value = 11.0f;
		column.AddView(mValidationLabel, match);
		SetContent(column);

		mCreateButton = AddButton("Create", .None);
		mCreateButton.OnClick.Add(new (b) =>
			{
				if (!mValid)
					return; // the validation line says why
				if ((OnCreate != null) && (mSelectedGroup != null))
					OnCreate(mSelectedGroup, mNameEdit.Text);
				Close(.OK);
			});
		AddButton("Cancel", .Cancel);

		RebuildModel();
		Validate();
	}

	public ~this()
	{
		mTree.SetAdapter(null);
	}

	private void RebuildModel()
	{
		let root = (mContext.Project != null) ? mContext.Project.SourceDb.RootGroup : null;
		mGroups.Rebuild(root);
		if (mSelectedGroup == null)
			mSelectedGroup = root;
		mGroups.AttachExpanded(mTree);
	}

	private void Validate()
	{
		let name = mNameEdit.Text;
		mValid = false;
		let message = scope String();
		if (mSelectedGroup == null)
		{
			message.Set("no group selected");
		}
		else if (name.IsEmpty)
		{
			message.Set("enter a name");
		}
		else
		{
			bool exists = false;
			for (let instance in mSelectedGroup.Instances)
			{
				if (instance.Name == name)
				{
					exists = true;
					break;
				}
			}
			if (exists)
			{
				message.AppendF("'{}' already exists in this group", name);
			}
			else
			{
				mValid = true;
				let groupName = mSelectedGroup.Name;
				message.Append("create in ");
				message.Append(groupName.IsEmpty ? "Content" : groupName);
			}
		}
		mValidationLabel.SetText(message);
	}
}
