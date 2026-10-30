using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Core.Serialization;
using Sedulous.Content;
using Sedulous.GUI;
using Sedulous.Runtime.Client;
using Sedulous.Pipeline.Core;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App;

// What a page over one asset does whatever its asset is (Raptor's editor-gui spec, 5.4), so a page
// adds only what is its own (a picture, a preview). It reads the asset when it opens; its markup
// (the page's) has the kit's bar, whose `page-save`, `page-undo`, `page-redo`, `page-discard`,
// `page-cook` and `page-rebuild` it binds to the actions over the page, a grid (`page-grid`) and
// the state a page shows when its asset did not read (`page-state`, in place of the grid), and
// names its asset's kind in `page-kind`. The grid holds the asset's fields under its type's name
// (through FieldPropertySource, the user's ruling) and, under "Source", what the page says of it as
// read-only rows (a file, a size), never as fields that do nothing when typed into (the catalog's
// inconsistency 8). A page that lays out its own rows (a material's, by its shader) hides the
// asset's (HideAssetRows) and clears its own sections to lay them again (ClearSections). Every edit
// is one undo step on the page's stack, the asset's whole state before and after, after which, and
// after its undo and redo, the page is told (OnObjectChanged) so its preview follows; an edit made
// by code (a preset) is one step too (EditWhole), and so is an edit a page follows with more
// (FollowEdit: a texture's usage sets its colour space). What a page warns of (a texture's data
// stored as sRGB) is a notice row over the rest, shown while it has something to say (SetNotice).
// Save writes the asset and asks for a cook, so what uses it takes the new one; something else
// writing it (a scene's save writing a profile) has it read again (ReadAgain).

/// An asset's source file as its row shows it: the path as the asset names it (the page that holds
/// the asset says it), never typed (a typo would cook a dangling reference); with `browse`, a Browse
/// button picking another file of the project's (a font's source, relinked).
class SourcePathEditor : PropertyEditor
{
	public const String cHint = "SourcePath";

	private delegate void(String outPath) mPath ~ delete _;
	private delegate void() mBrowse ~ delete _;
	private Sedulous.GUI.Label mText ~ _.ReleaseRef();
	private Sedulous.GUI.Button mButton ~ _.ReleaseRef();

	/// Takes `path`, which says the path, and `browse` (null: no Browse).
	public this(delegate void(String outPath) path, delegate void() browse = null)
	{
		mPath = path;
		mBrowse = browse;
		AddClass("source-path");
		EditLayoutStyle(scope (s) =>
			{
				s.Direction = .Row;
				s.AlignItems = .Center;
				s.ColumnGap = 6.0f;
			});
		mText = new Sedulous.GUI.Label();
		mText.AddClass("source-path-text");
		mText.EditLayoutStyle(scope (s) =>
			{
				s.Grow = 1.0f;
				s.Shrink = 1.0f;
			});
		AddChild(mText);
		mButton = new Sedulous.GUI.Button();
		mButton.AddClass("source-path-browse");
		mButton.Text = "Browse...";
		mButton.Tooltip = "Pick another file of the project's as its source";
		mButton.SetOnClick(new [=this] () =>
			{
				if (mBrowse != null)
					mBrowse();
			});
		mButton.Displayed = mBrowse != null;
		AddChild(mButton);
	}

	public StringView Text => mText.Text;
	/// Its Browse; null when it has none.
	public Sedulous.GUI.Button BrowseButton => (mBrowse != null) ? mButton : null;

	protected override void OnBind(PropertyInfo info, PropertyValue value)
	{
		let path = scope String();
		if (mPath != null)
			mPath(path);
		mText.Text = path;
		mButton.Enabled = !IsReadOnly;
	}

	protected override void OnTextStyleChange()
	{
		ShareTextStyle(mText);
		ShareTextStyle(mButton);
	}
}

abstract class AssetObjectPage : UIEditorPage
{
	public const String cFactsTitle = "Source";
	public const String cNoticesTitle = "Check";

	private struct OwnSection
	{
		public String Key;
		public String Title;
		/// The page's, which outlives its sections.
		public IPropertySource Source;
	}

	private EditorContext mContext;
	private AssetPageServices mServices ~ delete _;
	private String mTitle = new .() ~ delete _;
	/// Owned; null when the read failed.
	private ISerializable mObject = null ~ delete _;
	/// One reference, the page's.
	private Node mContent = null ~ { if (_ != null) _.ReleaseRef(); };
	/// The markup's: the tree holds it.
	private PropertyGrid mGrid = null;
	private PageActionBar mBar = null ~ delete _;
	private FieldPropertySource mProperties = null ~ delete _;
	private Sedulous.GUI.PropertyBag mFacts = new .() ~ delete _;
	private Sedulous.GUI.PropertyBag mNotices = new .() ~ delete _;
	private PropertySections mSections = new .() ~ delete _;
	/// The asset as the last step left it: a followed edit's before, and an edit made by code's.
	private List<uint8> mBaseline = new .() ~ delete _;
	/// The page's sections (AddSection).
	private List<OwnSection> mOwn = new .() ~ { for (let own in _) { delete own.Key; delete own.Title; } delete _; };
	private String mAssetTitle = new .() ~ delete _;
	/// False once a page lays out its own rows (HideAssetRows).
	private bool mShowsAssetRows = true;

	/// The page over `instance`, an asset of `type` (or one derived from it), from the markup at
	/// `markupPath`. It takes `services`.
	public this(EditorContext context, AssetPageServices services, Instance instance, Type type, StringView markupPath)
	{
		mContext = context;
		mServices = services;
		mTitle.Set(instance.Name);
		InstanceId = instance.Id;
		let object = instance.ReadObject();
		if ((object != null) && object.GetType().IsSubtypeOf(type))
			mObject = object;
		else
		{
			delete object;
			GlobalLog(.Error, "Editor: asset '{}' failed to read, its page shows why", mTitle);
		}

		if (mObject != null)
		{
			let objectType = mObject.GetType();
			mProperties = new FieldPropertySource(objectType, 1,
				new [=this] (index) => (mObject != null) ? Internal.UnsafeCastToPtr(mObject) : null,
				new [=this] (apply) => { Changed(apply); }, context.Resources);
			if (objectType.GetCustomAttribute<DisplayNameAttribute>() case .Ok(let named))
				mAssetTitle.Set(named.Name);
			else
				mAssetTitle.Set("Properties");
			StackSections();
			ObjectSnapshot.Take(mObject, mBaseline);
		}

		mContent = (mServices.LoadMarkup != null) ? mServices.LoadMarkup(markupPath) : null;
		if (mContent == null)
			return;
		mBar = new PageActionBar(context.Actions, this);
		mBar.Bind(Find<ButtonBase>("page-save"), "file.save");
		mBar.Bind(Find<ButtonBase>("page-undo"), "edit.undo");
		mBar.Bind(Find<ButtonBase>("page-redo"), "edit.redo");
		mBar.Bind(Find<ButtonBase>("page-discard"), "page.discardChanges");
		mBar.Bind(Find<ButtonBase>("page-cook"), "build.cookPage");
		mBar.Bind(Find<ButtonBase>("page-rebuild"), "build.rebuildPage");
		if (let kind = Find<Sedulous.GUI.Label>("page-kind"))
			kind.Text = (mObject != null) ? (StringView)mAssetTitle : "";
		if (let state = Find<Node>("page-state"))
			state.Displayed = mObject == null;
		mGrid = Find<PropertyGrid>("page-grid");
		if (mGrid != null)
		{
			mGrid.Displayed = mObject != null;
			if (mServices.Refs != null)
				ResourceRefEditor.Register(mGrid.Editors, mServices.Refs);
			PropertyExtras.Register(mGrid.Editors); // the notices
			mGrid.Editors.RegisterHint(SourcePathEditor.cHint, new [=this] () =>
				{
					let kinds = scope List<StringView>();
					SourceExtensions(kinds);
					delegate void() browse = null;
					if (!kinds.IsEmpty && (mServices.Pick != null))
						browse = new [=this] () => { BrowseSource(); };
					return new SourcePathEditor(new [=this] (outPath) => { SourceFile(outPath); }, browse);
				}, true);
			mGrid.Source = mSections;
		}
	}

	public ~this()
	{
		if (mGrid != null)
			mGrid.Source = null;
	}

	public override StringView Title => mTitle;
	public override Node Content => mContent;

	public override void OnUpdate(IApplicationHost host, float dt)
	{
		Refresh();
	}

	/// The asset written outside the page (an agent's asset_data_write, page_reload): a clean page
	/// shows what is stored now, its undo let go; one with unsaved edits keeps them and says so, as
	/// the scene page does.
	public override void OnAssetExternallyModified()
	{
		if (IsDirty)
		{
			mContext.Notify(.Warning, scope $"'{mTitle}' changed on disk but has unsaved edits here - not refreshed.");
			return;
		}
		ReadAgain();
	}

	public override Result<void, ErrorCode> Save()
	{
		if ((mObject == null) || (mContext.Project == null))
			return .Err(.NotFound);
		let instance = mContext.Project.SourceDb.GetInstance(InstanceId);
		if (instance == null)
			return .Err(.NotFound);
		let saved = instance.WriteObject(mObject);
		if (saved case .Ok)
		{
			ClearDirty();
			mContext.RequestCook(false);
			GlobalLog(.Information, "Editor: saved asset '{}'", mTitle);
		}
		return saved;
	}

	/// Once a frame: the bar as the actions are over the page.
	public virtual void Refresh()
	{
		if (mBar != null)
			mBar.Sync();
	}

	// === For tests ===

	public bool LoadFailed => mObject == null;
	public ISerializable AssetObject => mObject;
	public PropertyGrid Grid => mGrid;
	/// The kit's bar: Save, Undo, Redo, Discard Changes, Cook and Rebuild, each an action over the page.
	public PageActionBar Bar => mBar;
	/// The asset's rows; null when it did not read.
	public FieldPropertySource Properties => mProperties;
	public Sedulous.GUI.PropertyBag Facts => mFacts;
	public PropertySections Sections => mSections;

	/// The asset's source file as its row says it ("Not set": embedded, or not a source asset).
	public void SourceFile(String outPath)
	{
		let asset = ObjectRef as Asset;
		if ((asset != null) && !asset.FileName.IsEmpty)
			outPath.Append(asset.FileName.Value);
		else
			outPath.Append("Not set");
	}

	/// The kinds of file its source may be relinked to (".ttf"), appended; none: its source row only
	/// says it (the default).
	public virtual void SourceExtensions(List<StringView> outExtensions)
	{
	}

	/// The source row's Browse: the files under the project's sources of those kinds, the current
	/// one checked; a pick relinks it.
	public void BrowseSource()
	{
		let asset = ObjectRef as Asset;
		let project = (mContext != null) ? mContext.Project : null;
		if ((asset == null) || (mServices.Pick == null) || (project == null))
			return;
		let kinds = scope List<StringView>();
		SourceExtensions(kinds);
		let request = PathPicker.Request(project.SourcesRoot(.. scope .()), kinds, asset.FileName.Value);
		delete request.OnPicked;
		request.OnPicked = new [=this] (picked) => { RelinkSource(picked); };
		mServices.Pick(request);
	}

	/// Names `path` (under the project's sources) as the asset's source, one undo step; the page's
	/// rows read it again.
	public void RelinkSource(StringView path)
	{
		if (((ObjectRef as Asset) == null) || path.IsEmpty)
			return;
		EditWhole("asset_page.source", scope [&] (object) =>
			{
				if (let asset = Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object)) as Asset)
					asset.FileName.Set(path);
			});
	}

	/// What the notice `key` says (empty when it is not shown), appended.
	public void Notice(StringView key, String outText)
	{
		let path = FactPath(key, .. scope .());
		let info = mNotices.FindInfo(path);
		if ((info == null) || !info.Visible)
			return;
		var value = mNotices.GetValue(path, 0);
		outText.Append(value.AsString);
		value.Dispose();
	}

	/// The value of the read-only row `name` (empty when there is none), appended.
	public void Fact(StringView name, String outText)
	{
		var value = mFacts.GetValue(FactPath(name, .. scope .()), 0);
		outText.Append(value.AsString);
		value.Dispose();
	}

	/// An edit of the asset's property `path` to `write`, as the grid commits one.
	public void Edit(StringView path, PropertyWrite write)
	{
		if (mProperties == null)
			return;
		mProperties.BeginEdit(path);
		mProperties.CommitEdit(path, write);
	}

	protected T ObjectAs<T>() where T : class => ObjectRef as T;

	// The asset as an object: an interface reaches a class only through its pointer.
	private Object ObjectRef => (mObject != null) ? Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(mObject)) : null;
	protected EditorContext Context => mContext;
	protected AssetPageServices Services => mServices;

	/// A button of the page's own bound to the action `id` over the page, as the kit's bar's are (a
	/// clip's transport to the playback actions): enabled, checked and its tooltip following the
	/// action each frame.
	protected void BindAction(ButtonBase button, StringView id)
	{
		if (mBar != null)
			mBar.Bind(button, id);
	}

	/// The content's part with this id, as a T; null when it has none.
	protected T Find<T>(StringView id) where T : Node
	{
		return (mContent != null) ? (mContent.FindElement(id) as T) : null;
	}

	/// Shows `value` in the read-only row `name` under "Source", in the order first set.
	protected void SetFact(StringView name, StringView value)
	{
		let path = FactPath(name, .. scope .());
		if (mFacts.FindInfo(path) == null)
		{
			let info = mFacts.Add(path, .String, Sedulous.GUI.Variant(value));
			info.DisplayName.Set(name);
			info.ReadOnly = true;
			mFacts.PropertiesChanged(); // Add told the grid before its name was set
			return;
		}
		var shown = mFacts.GetValue(path, 0);
		defer shown.Dispose();
		if (shown.AsString != value)
			mFacts.SetValue(path, 0, Sedulous.GUI.Variant(value));
	}

	/// A section of the page's own (rows the asset's fields do not show: a font's size ramp) after
	/// the asset's and before the facts; `source` is the page's and outlives it.
	protected void AddSection(StringView key, StringView title, IPropertySource source)
	{
		OwnSection own;
		own.Key = new String(key);
		own.Title = new String(title);
		own.Source = source;
		mOwn.Add(own);
		if (mObject != null)
			StackSections();
	}

	/// The asset read again from its source (something else wrote it: a scene's save writing a
	/// profile's values); its undo let go, as its steps named the asset it had. False when it did
	/// not read, the page keeping what it had.
	protected bool ReadAgain()
	{
		let project = mContext.Project;
		let instance = (project != null) ? project.SourceDb.GetInstance(InstanceId) : null;
		let object = (instance != null) ? instance.ReadObject() : null;
		if ((mObject == null) || (object == null) || (object.GetType() != mObject.GetType()))
		{
			delete object;
			return false;
		}
		delete mObject;
		mObject = object; // the field source reads it through its resolver
		mProperties.Refresh();
		ObjectSnapshot.Take(mObject, mBaseline);
		Commands.Clear();
		ClearDirty();
		OnObjectChanged();
		return true;
	}

	/// The page's own sections let go (they are laid out again: a material's rows follow its
	/// shader). A page whose sources go before this base calls it from its destructor, so the
	/// sections never reach a source that has gone.
	protected void ClearSections()
	{
		for (let own in mOwn)
		{
			delete own.Key;
			delete own.Title;
		}
		mOwn.Clear();
		if (mObject != null)
			StackSections();
		else
			mSections.Clear();
	}

	/// The asset's own rows left out: a page whose asset holds what no row should show (a
	/// material's source, a property table in parallel arrays) gives the grid its own.
	protected void HideAssetRows()
	{
		mShowsAssetRows = false;
		if (mObject != null)
			StackSections();
	}

	/// Shows `text` as the notice `key` (a warning over the asset's rows); empty hides it.
	protected void SetNotice(StringView key, StringView text)
	{
		let path = FactPath(key, .. scope .());
		let info = mNotices.FindInfo(path);
		if (info == null)
		{
			let added = mNotices.Add(path, .String, Sedulous.GUI.Variant(text));
			added.Hint.Set(NoticePropertyEditor.cHint);
			added.ReadOnly = true;
			added.Visible = !text.IsEmpty;
			mNotices.PropertiesChanged(); // Add told the grid before the rest was set
			return;
		}
		if (info.Visible != !text.IsEmpty)
		{
			info.Visible = !text.IsEmpty;
			mNotices.PropertiesChanged();
		}
		var shown = mNotices.GetValue(path, 0);
		defer shown.Dispose();
		if (shown.AsString != text)
			mNotices.SetValue(path, 0, Sedulous.GUI.Variant(text));
	}

	/// An edit of `path` (the grid's) has just landed in `object`: a page that follows it with more
	/// (a texture's usage setting its colour space) does so here and says true, and the whole of it
	/// is one undo step.
	protected virtual bool FollowEdit(StringView path, ISerializable object) => false;

	/// An edit made by code that moves many values at once (a preset): `mutate` changes the asset,
	/// the whole of it before and after kept as one undo step.
	protected void EditWhole(StringView typeId, delegate void(ISerializable object) mutate)
	{
		if (mObject == null)
			return;
		// The asset as it is (not the last step of the base's own: a page's own rows edit it too).
		let before = scope List<uint8>();
		ObjectSnapshot.Take(mObject, before);
		mutate(mObject);
		Step(typeId, before);
	}

	/// The asset changed: an edit, its undo or redo. The page's preview follows it.
	protected virtual void OnObjectChanged() {}

	// A row's path: its name without what a path may not hold.
	private static void FactPath(StringView name, String outPath)
	{
		for (let c in name)
		{
			if ((c != '.') && (c != '/') && (c != ' '))
				outPath.Append(c);
		}
	}

	// The field source's commit: `apply` writes the edit into the asset, which a page may follow
	// with more; the whole of it one step.
	private void Changed(delegate void(int object, void* value) apply)
	{
		if (mObject == null)
			return;
		let path = scope String(mProperties.EditPath);
		apply(0, Internal.UnsafeCastToPtr(mObject));
		FollowEdit(path, mObject);
		Step("asset_properties");
		MarkDirty();
	}

	// The asset as it is now, after the baseline, as one undo step (its Execute puts back what is
	// already there, then tells the page).
	private void Step(StringView typeId) => Step(typeId, mBaseline);

	// The asset as it is now, after `before`, as one undo step.
	private void Step(StringView typeId, Span<uint8> before)
	{
		let after = scope List<uint8>();
		ObjectSnapshot.Take(mObject, after);
		Commands.Execute(new ObjectSnapshotCommand(new [=this] () => mObject, before, after, typeId, new [=this] () => { Applied(); }));
	}

	// The sections in their order: the notices, the asset's, the page's own, the facts.
	private void StackSections()
	{
		mSections.Clear();
		mSections.Add("notices", cNoticesTitle, mNotices);
		if (mShowsAssetRows)
			mSections.Add("asset", mAssetTitle, mProperties);
		for (let own in mOwn)
			mSections.Add(own.Key, own.Title, own.Source);
		mSections.Add("facts", cFactsTitle, mFacts);
	}

	private void Applied()
	{
		ObjectSnapshot.Take(mObject, mBaseline); // what the next step starts from
		mProperties.Refresh(); // an undo or a preset wrote it behind the source
		MarkDirty();
		OnObjectChanged();
	}
}
