using System;
using Sedulous.Content;
using Sedulous.GUI;

namespace Sedulous.Editor.App;

// Create Asset (Raptor's editor-gui spec, 5.2, layer 5): a window over its markup
// (Data/Editor/AssetCreate.gml) that names a new asset and the group it goes in, for any type: it
// creates nothing itself, its owner does with what Create answers. The group is a field that opens
// the group picker below it; the name is checked as it is typed (AssetNames, the rule Save As keeps
// too), Create waiting while it is refused and the line under the name saying why, else what it
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
		if (group.GetInstance(name) != null)
		{
			outWhy.AppendF("{} is already in ", name);
			GroupPicker.ShownName(group, outWhy);
			outWhy.Append('.');
		}
	}
}

class AssetCreate
{
	/// Its markup, under the data root.
	public const String cMarkupPath = "Editor/AssetCreate.gml";
	public const float cWidth = 440.0f;
	public const float cHeight = 220.0f;

	/// A reference of ours: its buttons close it from inside their own click, which may let the
	/// tree's reference go.
	private Sedulous.GUI.Window mWindow ~ _?.ReleaseRef();
	// The body's: the window holds them.
	private Sedulous.GUI.Button mGroupField;
	private TextField mName;
	private Sedulous.GUI.Label mWhy;
	private Sedulous.GUI.Button mCreate;
	// BORROWED: the owner's, kept while it is open.
	private SceneRoot mRoot;
	private ContentDatabase mSources;
	private Picker mPicker;
	/// The group it makes in now: the database's.
	private Group mGroup;
	private delegate void(Group group, StringView name) mOnCreate ~ delete _;
	/// Whether the picker is open for this: it answers here, so it closes when this goes.
	private bool mPicking = false;

	private this()
	{
	}

	/// Open as it goes, the group picker would answer into nothing and Create make into nothing.
	public ~this()
	{
		if (mPicking && mPicker.IsOpen)
			mPicker.Close();
		if (mWindow.IsOpen)
			mWindow.Close();
	}

	/// Opens it over `root` with `body` (the markup's), titled `title` ("New Material"), the group
	/// `group` of `sources` to start, the name `suggested`; `picker` picks another group. `create`
	/// is told the group and the name Create was pressed with (a name it takes), after it closes; it
	/// must not delete this, whose window's button is still on the stack. The caller's; deleted
	/// while open, it closes. Null when `body` lacks its parts. TAKES OWNERSHIP of a reference to
	/// `body` and of `create`, opened or not.
	public static AssetCreate Open(SceneRoot root, Node body, ContentDatabase sources, Group group, StringView title,
		StringView suggested, Picker picker, delegate void(Group group, StringView name) create)
	{
		if (body == null)
		{
			delete create;
			return null;
		}
		defer body.ReleaseRef(); // the window holds its own
		let groupField = body.FindElement("asset-create-group") as Sedulous.GUI.Button;
		let name = body.FindElement("asset-create-name") as TextField;
		let why = body.FindElement("asset-create-why") as Sedulous.GUI.Label;
		let createButton = body.FindElement("asset-create-create") as Sedulous.GUI.Button;
		let cancel = body.FindElement("asset-create-cancel") as Sedulous.GUI.Button;
		if ((groupField == null) || (name == null) || (why == null) || (createButton == null))
		{
			delete create;
			return null;
		}

		let dialog = new AssetCreate();
		dialog.mGroupField = groupField;
		dialog.mName = name;
		dialog.mWhy = why;
		dialog.mCreate = createButton;
		dialog.mRoot = root;
		dialog.mSources = sources;
		dialog.mPicker = picker;
		dialog.mGroup = group;
		dialog.mOnCreate = create;

		let window = new Sedulous.GUI.Window();
		dialog.mWindow = window;
		window.Title = title;
		window.AddClass("asset-create-window");
		window.Size = .(cWidth, cHeight);
		window.Content.AddChild(body);
		groupField.SetOnClick(new [=dialog] () => { dialog.PickGroup(); });
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

	/// The group field says the group; Create waits while the name is refused, the line under the
	/// name saying why (red), else what it makes.
	private void Check()
	{
		mGroupField.Text = GroupPicker.ShownName(mGroup, .. scope .());
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

	/// The group picker below the group field, the group now checked.
	private void PickGroup()
	{
		let request = GroupPicker.Request(mSources, mGroup);
		request.OnPicked = new (key) => { PickedGroup(key); };
		mPicking = mPicker.Open(mRoot, request, mGroupField);
	}

	private void PickedGroup(StringView key)
	{
		mPicking = false;
		if (let picked = GroupPicker.Find(mSources, key))
		{
			mGroup = picked;
			Check();
		}
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
