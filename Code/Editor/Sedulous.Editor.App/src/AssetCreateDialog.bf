using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.GUI;

namespace Sedulous.Editor.App;

// Create Asset: a window over its markup
// (Data/Editor/AssetCreate.xml) that names a new asset and the group it goes in, for any type: it
// creates nothing itself, its owner does with what Create answers. The groups are a tree in it,
// every one open, the group it starts in chosen and a click choosing another (the old dialog's); the
// name is checked as it is typed (AssetNames, the rule Save As keeps too), Create waiting while it is refused and the line under the name saying why, else what it
// will make. Enter in the name creates, Escape or Cancel closes.

/// The rule a new asset's name keeps, Create Asset's and Save As's: names are file names.
static class AssetNames
{
	/// What a file cannot hold in its name, on any platform the project is opened on.
	public const String cRefused = "/\\:*?\"<>|";

	/// Why `name` cannot name a new asset in `group` (empty, a character a file cannot hold, a
	/// space at an end or a dot at the end, taken there), appended to `outWhy`; nothing when it can.
	public static void Refusal(Group group, StringView name, String outWhy)
	{
		let start = outWhy.Length;
		FormRefusal(name, outWhy);
		if ((outWhy.Length == start) && (group.GetInstance(name) != null))
		{
			outWhy.AppendF("{} is already in ", name);
			GroupPicker.ShownName(group, outWhy);
			outWhy.Append('.');
		}
	}

	/// Why `name` cannot name a new group in `parent` (as Refusal, a group of that name being what
	/// takes it), appended to `outWhy`; nothing when it can.
	public static void GroupRefusal(Group parent, StringView name, String outWhy)
	{
		let start = outWhy.Length;
		FormRefusal(name, outWhy);
		if ((outWhy.Length == start) && (parent.GetGroup(name) != null))
		{
			GroupPicker.ShownName(parent, outWhy);
			outWhy.AppendF(" already has a group named {}.", name);
		}
	}

	/// Why `name` cannot name a file (empty, a character a file cannot hold, a space at an end, a
	/// dot at its end), appended to `outWhy`; nothing when it can.
	public static void FormRefusal(StringView name, String outWhy)
	{
		if (name.IsEmpty)
		{
			outWhy.Append("Enter a name.");
			return;
		}
		for (let c in name)
		{
			if (cRefused.Contains(c))
			{
				outWhy.AppendF("A name cannot hold {}.", c);
				return;
			}
		}
		if ((name[0] == ' ') || (name[name.Length - 1] == ' ') || (name[name.Length - 1] == '.'))
		{
			outWhy.Append("A name cannot start or end with a space, or end with a dot.");
			return;
		}
	}
}

class AssetCreate
{
	/// Its markup, under the data root.
	public const String cMarkupPath = "Editor/AssetCreate.xml";
	public const float cWidth = 440.0f;
	public const float cHeight = 420.0f;

	/// A reference of ours: its buttons close it from inside their own click, which may let the
	/// tree's reference go.
	private Sedulous.GUI.Window mWindow ~ _?.ReleaseRef();
	// The body's: the window holds them.
	private TreeView mTree;
	private TextField mName;
	private Sedulous.GUI.Label mWhy;
	private Sedulous.GUI.Button mCreate;
	/// The groups' tree, and its groups by node (the database's).
	private TreeModel mModel = new .() ~ delete _;
	private List<Group> mGroups = new .() ~ delete _;
	/// The group it makes in now: the database's.
	private Group mGroup;
	private delegate void(Group group, StringView name) mOnCreate ~ delete _;

	private this()
	{
	}

	/// Open as it goes, Create would make into nothing; its tree lets the model go first.
	public ~this()
	{
		if (mWindow.IsOpen)
			mWindow.Close();
		mTree.Model = null;
	}

	/// Opens it over `root` with `body` (the markup's), titled `title` ("New Material"), the group
	/// `group` of `sources` chosen in its tree to start, the name `suggested`. `create`
	/// is told the group and the name Create was pressed with (a name it takes), after it closes; it
	/// must not delete this, whose window's button is still on the stack. The caller's; deleted
	/// while open, it closes. Null when `body` lacks its parts. TAKES OWNERSHIP of a reference to
	/// `body` and of `create`, opened or not.
	public static AssetCreate Open(SceneRoot root, Node body, ContentDatabase sources, Group group, StringView title,
		StringView suggested, delegate void(Group group, StringView name) create)
	{
		if (body == null)
		{
			delete create;
			return null;
		}
		defer body.ReleaseRef(); // the window holds its own
		let tree = body.FindElement("asset-create-groups") as TreeView;
		let name = body.FindElement("asset-create-name") as TextField;
		let why = body.FindElement("asset-create-why") as Sedulous.GUI.Label;
		let createButton = body.FindElement("asset-create-create") as Sedulous.GUI.Button;
		let cancel = body.FindElement("asset-create-cancel") as Sedulous.GUI.Button;
		if ((tree == null) || (name == null) || (why == null) || (createButton == null) || (sources.RootGroup == null))
		{
			delete create;
			return null;
		}

		let dialog = new AssetCreate();
		dialog.mTree = tree;
		dialog.mName = name;
		dialog.mWhy = why;
		dialog.mCreate = createButton;
		dialog.mGroup = group;
		dialog.mOnCreate = create;

		let window = new Sedulous.GUI.Window();
		dialog.mWindow = window;
		window.Title = title;
		window.AddClass("asset-create-window");
		window.Size = .(cWidth, cHeight);
		window.Content.AddChild(body);
		dialog.AddGroups(sources.RootGroup, TreeModel.Root);
		tree.Model = dialog.mModel;
		// A tree has no size of its own: room for a few groups whatever the sheet says.
		tree.EditLayoutStyle(scope (s) => { s.MinHeight = LayoutLength.Px(160.0f); });
		for (int node < dialog.mGroups.Count)
			tree.SetIdExpanded((ItemId)node, true);
		for (int node < dialog.mGroups.Count)
		{
			if (dialog.mGroups[node] == group)
			{
				ItemId[1] id = .((ItemId)node);
				tree.SetSelectedIds(id);
			}
		}
		tree.SetOnSelectionChanged(new [=dialog] (index) => { dialog.ChoseGroup(index); });
		name.SetOnTextChanging(new [=dialog] (text) => { dialog.Check(); });
		name.SetOnSubmit(new [=dialog] (text) => { dialog.Commit(); });
		createButton.SetOnClick(new [=dialog] () => { dialog.Commit(); });
		if (cancel != null)
			cancel.SetOnClick(new [=window] () => { window.Close(); });
		name.Text = suggested;
		dialog.Check();
		window.OpenModal(root);
		name.FocusElement();
		name.SelectAll();
		return dialog;
	}

	/// Its window. Ours: a caller that keeps it takes a reference.
	public Sedulous.GUI.Window Window => mWindow;
	public bool IsOpen => mWindow.IsOpen;
	/// The group it makes in now.
	public Group TargetGroup => mGroup;

	/// Create waits while the name is refused, the line under the name saying why (red), else what
	/// it makes.
	private void Check()
	{
		let refused = AssetNames.Refusal(mGroup, mName.Text, .. scope .());
		mCreate.Enabled = refused.IsEmpty;
		if (refused.IsEmpty)
		{
			mWhy.RemoveClass("refused");
			let makes = scope String()..AppendF("Makes {} in ", mName.Text);
			GroupPicker.ShownName(mGroup, makes);
			makes.Append('.');
			mWhy.Text = makes;
		}
		else
		{
			mWhy.AddClass("refused");
			mWhy.Text = refused;
		}
	}

	/// `group` and every group under it (kept in name order by the database), by name ("Content"
	/// the top), each a node under `parent`.
	private void AddGroups(Group group, int32 parent)
	{
		let node = mModel.AddNode(parent, (group.Parent == null) ? (StringView)GroupPicker.cTop : group.Name);
		mModel.SetIcon(node, "Editor/Icons/folder.svg");
		while (mGroups.Count <= node)
			mGroups.Add(null);
		mGroups[node] = group;
		for (let child in group.Groups)
			AddGroups(child, node);
	}

	/// A row of the tree chosen: its group.
	private void ChoseGroup(ModelIndex index)
	{
		let node = index.IsValid ? (int)index.InternalId : mGroups.Count;
		if ((node < 0) || (node >= mGroups.Count))
			return;
		mGroup = mGroups[node];
		Check();
	}

	/// Create (or Enter in the name): a refused name waits, the line saying why; else it closes,
	/// then the owner is told what to make.
	private void Commit()
	{
		let chosen = scope String(mName.Text);
		if (!AssetNames.Refusal(mGroup, chosen, .. scope .()).IsEmpty)
			return; // Create waits; the line says why
		let made = mOnCreate;
		mOnCreate = null;
		defer delete made;
		let target = mGroup;
		mWindow.Close();
		if (made != null)
			made(target, chosen);
	}
}
