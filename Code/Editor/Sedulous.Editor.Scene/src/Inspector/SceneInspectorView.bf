using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Scene;

// The inspector inside a scene page, one per page, on the GUI's property grid (Raptor's editor-gui
// spec, 5.3, layer 4). It shows the page's selection: its head (the type icon, the name, the kind;
// several selected say how many), and one grid of sections (the editor's PropertySections): the
// entity's Active, its Transform (a copy of each entity's, its rotation in Euler degrees), then
// each component every selected entity has, its reflected rows with the editors by hint (an asset
// reference a slot taking what the builders make, an entity reference a slot over the scene's
// entities: EntityRef taken as a reference by its id). Several entities are edited at once, a row
// differing among them shown mixed.
//   - Every edit is one undo step on the page's stack: a component's as its edit context's paste
//     of each entity's component as the edit left it (the components found again by entity and
//     type), the transform's and Active's through the edit context's commands.
//   - A component's header has its verbs: copy, paste over it, reset to its defaults, revert to
//     its prefab (while it overrides it), remove; Add Component is the picker over the component
//     types the selection lacks, by category, each with its icon and its description.
//   - A component's extras, asked of its type (InspectorExtrasRegistry): its notices, its actions
//     and sections of their own, under its header.
//   - The scene selected (its hierarchy row), the scene's settings: a section per system's block,
//     each property showing and editing where it lands (the block's own values, or its profile's
//     while it uses one), a block's profile actions under its header (open it, make one from these
//     values, copy its values into the scene).
//   - A search narrows the rows. While the page simulates the grid is read only, and says so.
//   - Built again when the selection, the scene's shape or the components change; otherwise only
//     the values are shown again, so a gizmo's drag or an undo shows as it happens.
// Its components are read through their run time reflection (FieldPropertySource), not the
// toolkit's reflected source: that one reflects the GUI's own objects.

/// What a scene inspector asks of its page and the editor.
class SceneInspectorServices
{
	public EditorContext Context = null;
	/// The page whose selection it shows.
	public EditorPage Page = null;
	/// The entities' type icons; null: none.
	public EditorIcons Icons = null;
	/// The asset slots' (null: none). Not owned.
	public ResourceRefServices Refs = null;
	/// What a reference written binds through; null: on its next resolve. Not owned.
	public ResourceManager Resources = null;
	/// Opens the picker for a request (Add Component); OWNERSHIP of the request transfers.
	public delegate void(PickerRequest request) Pick ~ delete _;
	/// Opens the entity picker for a request (an entity slot's pick); OWNERSHIP of the request
	/// transfers.
	public delegate void(EntityPickRequest request) PickEntity ~ delete _;
	/// Whether the page simulates (the grid read only meanwhile).
	public delegate bool() Simulating ~ delete _;
	/// Whether the scene's own row is selected (ruling 12: then the scene's settings show).
	public delegate bool() SceneSelected ~ delete _;
	/// The scene's icon (a prefab's or a scene's document) and name, for its head.
	public String SceneIcon = new .() ~ delete _;
	public delegate StringView() SceneName ~ delete _;
}

class SceneInspectorView
{
	private const String cActiveKey = "e";
	private const String cTransformKey = "t";

	private class ComponentSection
	{
		public String Key = new .() ~ delete _;
		public String Title = new .() ~ delete _;
		public Type Type;
		public FieldPropertySource Source ~ delete _;
		/// Null: none.
		public Extras Extras ~ delete _;
	}

	// A component's extras: a bag under its header, its notices asked again as values show, its
	// actions run on their rows' commits.
	private class Extras : InspectorExtras
	{
		private class Notice
		{
			public String Name = new .() ~ delete _;
			public delegate void(String outMessage) Message ~ delete _;
			public String Said = new .() ~ delete _;
		}

		private class Action
		{
			public String Name = new .() ~ delete _;
			public delegate void() Run ~ delete _;
			/// Null: always shown.
			public delegate bool() Shown ~ delete _;
		}

		private class Section
		{
			public IPropertySource Source ~ delete _;
			public delegate void() Refresh ~ delete _;
		}

		public Sedulous.GUI.PropertyBag Bag ~ delete _;
		private SceneInspectorView mView;
		// A settings block's: no entities.
		private bool mOfEntities;
		private List<Section> mSources = new .() ~ DeleteContainerAndItems!(_);
		private List<Notice> mNotices = new .() ~ DeleteContainerAndItems!(_);
		private List<Action> mActions = new .() ~ DeleteContainerAndItems!(_);

		/// A component's over the view's entities, or a settings block's (`ofEntities` false: one
		/// object, no entities).
		public this(SceneInspectorView view, bool ofEntities)
		{
			mView = view;
			mOfEntities = ofEntities;
			Bag = new .(ofEntities ? view.mEntities.Count : 1);
			Bag.SetOnCommit(new (commit) =>
				{
					for (let action in mActions)
					{
						if ((action.Name == commit.Path) && (action.Run != null))
							action.Run();
					}
				});
		}

		public override SceneEditContext Edit => mView.mEdit;
		public override EditorContext Context => mView.mServices.Context;
		public override Span<Guid> Entities => mOfEntities ? mView.mEntities : default;

		public override void AddNotice(StringView name, delegate void(String outMessage) message)
		{
			let info = Bag.Add(name, .String, Sedulous.GUI.Variant(""));
			info.Hint.Set(NoticePropertyEditor.cHint);
			info.ReadOnly = true;
			info.Visible = false; // until it says something
			let notice = new Notice();
			notice.Name.Set(name);
			notice.Message = message;
			mNotices.Add(notice);
		}

		public override void AddAction(StringView name, StringView label, StringView description, delegate void() run)
		{
			let info = Bag.Add(name, .String, Sedulous.GUI.Variant(label));
			info.Hint.Set(ActionPropertyEditor.cHint);
			info.Description.Set(description);
			for (int i < Bag.ObjectCount)
				Bag.SetValue(name, i, Sedulous.GUI.Variant(label));
			let action = new Action();
			action.Name.Set(name);
			action.Run = run;
			mActions.Add(action);
		}

		/// An action shown only while `shown` (taken) says so.
		public void AddShownAction(StringView name, StringView label, StringView description, delegate void() run, delegate bool() shown)
		{
			AddAction(name, label, description, run);
			mActions.Back.Shown = shown;
			if (let info = Bag.FindInfo(name))
				info.Visible = shown();
		}

		public bool IsShown(StringView name)
		{
			let info = Bag.FindInfo(name);
			return (info != null) && info.Visible;
		}

		public override void AddSection(IPropertySource source, delegate void() refresh)
		{
			let section = new Section();
			section.Source = source;
			section.Refresh = refresh;
			mSources.Add(section);
		}

		public bool HasRows => !mNotices.IsEmpty || !mActions.IsEmpty;
		public bool IsEmpty => !HasRows && mSources.IsEmpty;
		public int SourceCount => mSources.Count;
		public IPropertySource SourceAt(int i) => mSources[i].Source;

		/// Each notice as it says now; shown while it says something.
		public void Refresh()
		{
			for (let section in mSources)
			{
				if (section.Refresh != null)
					section.Refresh();
			}
			var shown = false;
			let message = scope String();
			for (let notice in mNotices)
			{
				message.Clear();
				if (notice.Message != null)
					notice.Message(message);
				if (message != notice.Said)
				{
					notice.Said.Set(message);
					for (int i < Bag.ObjectCount)
						Bag.SetValue(notice.Name, i, Sedulous.GUI.Variant(message));
				}
				let info = Bag.FindInfo(notice.Name);
				if ((info != null) && (info.Visible == message.IsEmpty))
				{
					info.Visible = !message.IsEmpty;
					shown = true;
				}
			}
			for (let action in mActions)
			{
				if (action.Shown == null)
					continue;
				let visible = action.Shown();
				let info = Bag.FindInfo(action.Name);
				if ((info != null) && (info.Visible != visible))
				{
					info.Visible = visible;
					shown = true;
				}
			}
			if (shown)
				Bag.PropertiesChanged();
		}

		/// A notice's text as it says now, or an action's label; appended.
		public void Text(StringView name, String outText)
		{
			for (let notice in mNotices)
			{
				if (notice.Name == name)
				{
					outText.Append(notice.Said);
					return;
				}
			}
			for (let action in mActions)
			{
				if (action.Name == name)
				{
					var value = Bag.GetValue(name, 0);
					defer value.Dispose();
					outText.Append(value.AsString);
					return;
				}
			}
		}

		public bool Run(StringView name)
		{
			for (let action in mActions)
			{
				if ((action.Name == name) && (action.Run != null))
				{
					action.Run();
					return true;
				}
			}
			return false;
		}
	}

	private SceneEditContext mEdit;
	private SceneInspectorServices mServices ~ delete _;
	private Node mPane;
	private PropertyGrid mGrid = null;
	private TextField mName = null;
	private PropertySections mSections = new .() ~ delete _;
	// What the entity slots ask (the grid's registry borrows it).
	private EntityRefServices mEntityRefs = new .() ~ delete _;
	// The selection it shows, in order.
	private List<Guid> mEntities = new .() ~ delete _;
	// Active: a value per entity.
	private Sedulous.GUI.PropertyBag mActive = null ~ delete _;
	// Transform: a copy of each entity's, the source's objects; an edit sets them back.
	private List<Transform> mTransforms = new .() ~ delete _;
	private FieldPropertySource mTransform = null ~ delete _;
	private List<ComponentSection> mComponents = new .() ~ DeleteContainerAndItems!(_);

	// The scene's settings while it is selected: a source per block, a block's profile actions.
	private class SettingsSection
	{
		public String Key = new .() ~ delete _;
		public String Title = new .() ~ delete _;
		public SceneSettingsSource Source ~ delete _;
		/// Null: the block has no profile.
		public Extras Profile ~ delete _;
		/// Null: none.
		public Extras Extras ~ delete _;
	}

	private List<SettingsSection> mSettings = new .() ~ DeleteContainerAndItems!(_);
	private String mFilter = new .() ~ delete _;
	private uint64 mSignature = ~(uint64)0;
	private bool mReadOnly = false;
	/// Paste Component's overwrite question (a reference of ours).
	private Sedulous.GUI.MessageBox mPasteConfirm = null ~ _?.ReleaseRef();
	// The transform and component edits made, each a group of its own.
	private uint64 mEdits = 0;

	/// The inspector over `edit`'s selection in `pane` (the markup's `inspector-icon`,
	/// `inspector-name`, `inspector-kind`, `inspector-search`, `inspector-add`, `inspector-grid`,
	/// `inspector-state`, `inspector-note`, by id). `edit` and `pane` are borrowed and outlive it;
	/// `services` it takes.
	public this(SceneEditContext edit, SceneInspectorServices services, Node pane)
	{
		mEdit = edit;
		mServices = services;
		mPane = pane;
		mGrid = Find<PropertyGrid>("inspector-grid");
		if (mGrid != null)
		{
			if (mServices.Refs != null)
				ResourceRefEditor.Register(mGrid.Editors, mServices.Refs);
			// An entity reference: a slot over this scene's entities, chosen before the asset slot.
			mEntityRefs.Edit = mEdit;
			mEntityRefs.Icons = mServices.Icons;
			if (mServices.PickEntity != null)
				mEntityRefs.Pick = new (request) => { mServices.PickEntity(request); };
			EntityRefEditor.Register(mGrid.Editors, mEntityRefs);
			BoneNameEditor.Register(mGrid.Editors, mEdit); // a bone name picked from the animator's skeleton
			CollisionMatrixEditor.Register(mGrid.Editors); // the physics block's groups, a grid
			PropertyExtras.Register(mGrid.Editors); // a component's notices and actions
			mGrid.Source = mSections;
			mGrid.SetOnRowMenu(new (menu, row) => { HeaderMenu(menu, row); });
		}
		if (let search = Find<TextField>("inspector-search"))
			search.SetOnTextChanging(new (text) => { Search(text); });
		if (let paste = Find<Sedulous.GUI.Button>("inspector-paste"))
		{
			paste.SetOnClick(new [=this] () => { PasteComponent(); });
			paste.Displayed = false;
		}
		if (let add = Find<Sedulous.GUI.Button>("inspector-add"))
			add.SetOnClick(new [=this] () => { OpenAddComponent(); });
		mName = Find<TextField>("inspector-name");
		// Enter, or the focus leaving with a new name: one entity's rename (several name no one).
		if (mName != null)
			mName.SetOnTextChanged(new (text) =>
				{
					if ((mEntities.Count == 1) && (text.Length != 0))
						mEdit.RenameEntity(mEntities[0], text);
				});
		if (let note = Find<Node>("inspector-note"))
			note.Displayed = false;
		Refresh();
	}

	/// Lets the grid and the pane's controls go, then its sources, before the scene goes.
	public ~this()
	{
		if (mGrid != null)
		{
			mGrid.Source = null;
			mGrid.SetOnRowMenu(null);
		}
		if (let search = Find<TextField>("inspector-search"))
			search.SetOnTextChanging(null);
		if (let add = Find<Sedulous.GUI.Button>("inspector-add"))
			add.SetOnClick(null);
		if (let paste = Find<Sedulous.GUI.Button>("inspector-paste"))
			paste.SetOnClick(null);
		if ((mPasteConfirm != null) && mPasteConfirm.IsOpen)
			mPasteConfirm.Close(); // its answer would reach a gone view
		if (mName != null)
			mName.SetOnTextChanged(null);
		Clear();
	}

	/// Once a frame: built again when what it shows changed; else its values shown again.
	public void Refresh()
	{
		let readOnly = (mServices.Simulating != null) && mServices.Simulating();
		if (readOnly != mReadOnly)
		{
			mReadOnly = readOnly;
			mSections.ReadOnly = readOnly;
			if (let note = Find<Node>("inspector-note"))
				note.Displayed = readOnly;
			// Refused visibly: a component cannot be added while the scene simulates.
			if (let add = Find<Sedulous.GUI.Button>("inspector-add"))
				add.Enabled = !readOnly;
		}
		let signature = Signature();
		if (signature != mSignature)
		{
			mSignature = signature;
			Build();
			return;
		}
		// The values as they are now (a gizmo's drag, an undo): the transforms read again, the
		// notices asked again, the grid told, except while it is editing one (its row is the
		// gesture's).
		ShowPaste();
		PullTransforms();
		RefreshExtras();
		// Each frame: the grid hears only of a source whose values moved, so an entity at rest costs
		// its rows nothing.
		if ((mGrid != null) && !mGrid.IsEditing)
		{
			for (let section in mComponents)
			{
				if (!section.Source.Editing)
					section.Source.RefreshIfChanged();
			}
		}
	}

	/// The search over the rows, as typing it does.
	public void Search(StringView text)
	{
		mFilter.Set(text);
		if (mGrid != null)
			mGrid.Filter = text;
	}

	/// Add Component's picker.
	public void OpenAddComponent()
	{
		if ((mServices.Pick == null) || mEntities.IsEmpty || mReadOnly)
			return;
		let request = new PickerRequest();
		request.Placeholder.Set("Search components");
		let names = scope List<String>();
		defer { ClearAndDeleteItems!(names); }
		AddableComponents(names);
		for (let name in names)
		{
			let type = ComponentTypeNamed(name);
			let item = request.Add(name, (type != null) ? TitleOf(type, .. scope String()) : name);
			if (type == null)
				continue;
			if (type.GetCustomAttribute<CategoryAttribute>() case .Ok(let category))
				item.Section.Set(category.Name);
			else
				item.Section.Set("Other");
			if (type.GetCustomAttribute<DescriptionAttribute>() case .Ok(let description))
				item.Description.Set(description.Text); // a sentence: the foot's, not the row's
			if (mServices.Icons != null)
			{
				let icon = mServices.Icons.For(type, "Component");
				item.Glyph.Set(icon.Source);
				item.GlyphClass.Set(icon.Class);
			}
		}
		// Sections show where their first item is: sorted, each category's rows together (by the
		// categories' names, then the components').
		request.Items.Sort(scope (a, b) =>
			{
				let section = String.Compare(a.Section, b.Section, false);
				return (section != 0) ? section : String.Compare(a.Name, b.Name, false);
			});
		request.EmptyTitle.Set("Nothing more to add");
		request.EmptyText.Set("Every component the scene knows is on the selection.");
		request.OnPicked = new (key) => { AddComponent(key); };
		mServices.Pick(request);
	}

	/// What Add Component offers the selection now, by type name, appended (the caller deletes
	/// them).
	public void AddableComponents(List<String> outNames)
	{
		let scene = mEdit.Scene;
		scene.ForEachManager(scope [&] (manager) =>
			{
				let type = manager.ComponentType;
				if (type == null)
					return;
				// What an entity of the selection lacks.
				var lacking = false;
				for (let entity in mEntities)
					lacking = lacking || !manager.HasComponent(scene.FindEntity(entity));
				if (lacking)
					outNames.Add(type.GetName(.. new String()));
			});
	}

	/// Whether a copied component waits on the clipboard for the entities selected (Paste
	/// Component's button shows then).
	public bool CanPasteComponent => !mReadOnly && !mEntities.IsEmpty && (mServices.Context != null) &&
		!mServices.Context.ClipboardData("component").IsEmpty;

	private void ShowPaste()
	{
		if (let paste = Find<Node>("inspector-paste"))
			paste.Displayed = CanPasteComponent;
	}

	/// Paste Component: the copied component onto every selected entity, one undo step; when one
	/// has that component already, asked first (it is overwritten). False: nothing to do.
	public bool PasteComponent()
	{
		if (!CanPasteComponent)
			return false;
		// Over a component an entity has, it overwrites it: asked first (the old inspector's).
		let clip = mServices.Context.ClipboardData("component");
		let scene = mEdit.Scene;
		let typeId = SceneEditContext.PeekComponentTypeId(clip, .. scope .());
		let manager = scene.FindManagerBySerializationId(typeId);
		var overwrites = false;
		for (let entity in mEntities)
			overwrites = overwrites || ((manager != null) && manager.HasComponent(scene.FindEntity(entity)));
		let root = (mPane != null) ? mPane.RootNode : null;
		if (!overwrites || (manager == null) || !(root is SceneRoot))
			return PasteComponentNow();
		let title = scope String();
		if (manager.ComponentType != null)
			TitleOf(manager.ComponentType, title);
		else
			title.Append("component");
		if (mPasteConfirm != null)
		{
			if (mPasteConfirm.IsOpen)
				mPasteConfirm.Close();
			mPasteConfirm.ReleaseRef();
		}
		let question = new Sedulous.GUI.MessageBox();
		mPasteConfirm = question;
		question.Configure("Overwrite Component?", scope $"{(mEntities.Count == 1) ? "This entity" : "An entity selected"} has a {title} component already. Pasting overwrites it (you can undo).", .Ok);
		question.ClearButtons();
		question.AddButton("Cancel", "cancel", .Cancel);
		question.AddButton("Overwrite", "overwrite", .Primary);
		question.AddEventListener(.Changed, new [=this, =question] (e) =>
			{
				if (question.ResultName == "overwrite")
					PasteComponentNow();
			});
		question.OpenModal(root);
		return true;
	}

	/// The same without asking (the confirm's yes).
	public bool PasteComponentNow()
	{
		if (!CanPasteComponent)
			return false;
		let clip = mServices.Context.ClipboardData("component");
		mEdit.Commands.BeginGroup("inspector.paste");
		var pasted = false;
		for (let entity in mEntities)
			pasted = mEdit.PasteComponent(entity, clip) || pasted;
		mEdit.Commands.EndGroup();
		return pasted;
	}

	/// The overwrite question, while it is open.
	public Sedulous.GUI.MessageBox PasteConfirm => ((mPasteConfirm != null) && mPasteConfirm.IsOpen) ? mPasteConfirm : null;

	/// Adds a component of the type named `typeName` to every selected entity, one undo step.
	public bool AddComponent(StringView typeName)
	{
		let type = ComponentTypeNamed(typeName);
		if ((type == null) || mEntities.IsEmpty || mReadOnly)
			return false;
		let manager = mEdit.FindManager(type);
		mEdit.Commands.BeginGroup("inspector.add");
		for (let entity in mEntities)
		{
			if ((manager != null) && !manager.HasComponent(mEdit.Resolve(entity)))
				mEdit.AddComponent(entity, type);
		}
		mEdit.Commands.EndGroup();
		return true;
	}

	// === For tests ===

	/// A section's extras' row at `name` (a notice's text, an action's label), appended; nothing
	/// when there is none or it is hidden.
	public void ExtraText(StringView title, StringView name, String outText)
	{
		if (let extras = ExtrasOf(title))
			extras.Text(name, outText);
	}

	/// Runs a section's action `name`, as its button does.
	public bool RunExtra(StringView title, StringView name)
	{
		let extras = ExtrasOf(title);
		return (extras != null) && extras.Run(name);
	}

	/// A section's extras' source `index` (a script component's behaviours, a block's collision
	/// groups); null: none.
	public IPropertySource ExtraSource(StringView title, int index)
	{
		let extras = ExtrasOf(title);
		return ((extras != null) && (index < extras.SourceCount)) ? extras.SourceAt(index) : null;
	}

	/// A settings block's section by its title; null: none.
	public SceneSettingsSource SettingsOf(StringView title)
	{
		for (let section in mSettings)
		{
			if (section.Title == title)
				return section.Source;
		}
		return null;
	}

	/// A settings block's profile action `name` ("Open Profile", "Make Profile", "Copy Into
	/// Scene"): whether it shows now; RunProfileAction runs it.
	public bool ShowsProfileAction(StringView title, StringView name)
	{
		for (let section in mSettings)
		{
			if ((section.Title == title) && (section.Profile != null))
				return section.Profile.IsShown(name);
		}
		return false;
	}

	public bool RunProfileAction(StringView title, StringView name)
	{
		for (let section in mSettings)
		{
			if ((section.Title == title) && (section.Profile != null))
				return section.Profile.Run(name);
		}
		return false;
	}

	private Extras ExtrasOf(StringView title)
	{
		for (let section in mComponents)
		{
			if (section.Title == title)
				return section.Extras;
		}
		for (let section in mSettings)
		{
			if (section.Title == title)
				return section.Extras;
		}
		return null;
	}

	public PropertyGrid Grid => mGrid;
	public PropertySections Sections => mSections;

	/// The sections' titles in order, by " | ", appended.
	public void SectionTitles(String outText)
	{
		if (mActive != null)
			outText.Append("Entity");
		if (mTransform != null)
			outText.Append(" | Transform");
		for (let section in mComponents)
			outText.AppendF(" | {}", section.Title);
		for (let section in mSettings)
		{
			if (!outText.IsEmpty)
				outText.Append(" | ");
			outText.Append(section.Title);
		}
	}

	/// The grid's path of `property` in the section titled `title`, appended; nothing when there
	/// is no such section.
	public void PathOf(StringView title, StringView property, String outPath)
	{
		if (title == "Entity")
		{
			mSections.PathIn(cActiveKey, property, outPath);
			return;
		}
		if (title == "Transform")
		{
			mSections.PathIn(cTransformKey, property, outPath);
			return;
		}
		for (let section in mComponents)
		{
			if (section.Title == title)
			{
				mSections.PathIn(section.Key, property, outPath);
				return;
			}
		}
		// A settings block's: its own rows, else an extra source's (the collision groups).
		for (let section in mSettings)
		{
			if (section.Title != title)
				continue;
			if (Holds(section.Source, property))
			{
				mSections.PathIn(section.Key, property, outPath);
				return;
			}
			for (int i < ((section.Extras != null) ? section.Extras.SourceCount : 0))
			{
				if (Holds(section.Extras.SourceAt(i), property))
				{
					mSections.PathIn(scope $"y{section.Key}.{i}", property, outPath);
					return;
				}
			}
		}
	}

	// Whether `source` has a top-level row named `property`.
	private static bool Holds(IPropertySource source, StringView property)
	{
		let top = scope List<PropertyInfo>();
		defer { ClearAndDeleteItems!(top); }
		source.GetProperties(default, top);
		for (let info in top)
		{
			if (info.Name == property)
				return true;
		}
		return false;
	}

	/// The component a section's header path ("#Light") stands for; null: none.
	public Type ComponentOf(StringView headerPath)
	{
		let key = mSections.SectionOf(headerPath);
		for (let section in mComponents)
		{
			if (section.Key == key)
				return section.Type;
		}
		return null;
	}

	/// A header's menu as the grid builds it, at `headerPath`.
	public bool OpenHeaderMenu(StringView headerPath)
	{
		if (mGrid == null)
			return false;
		let row = mGrid.FindRow(headerPath);
		return (row >= 0) && mGrid.OpenRowMenu(row, .(10.0f, 10.0f));
	}

	public StringView Kind
	{
		get
		{
			let kind = Find<Label>("inspector-kind");
			return (kind != null) ? kind.Text : default;
		}
	}

	// === Building ===

	private uint64 Signature()
	{
		let scene = mEdit.Scene;
		var hash = Mix(14695981039346656037UL, scene.Revision);
		hash = Mix(hash, ShowsScene ? 1 : 0);
		for (let entity in mEdit.EntitySelection.Items)
		{
			hash = Mix(hash, (uint64)entity.GetHashCode());
			let e = scene.FindEntity(entity);
			uint64 bit = 1;
			scene.ForEachManager(scope [&] (manager) =>
				{
					if (e.IsAssigned && manager.HasComponent(e))
						hash = Mix(hash, bit);
					bit <<= 1;
				});
		}
		return hash;
	}

	private static uint64 Mix(uint64 hash, uint64 value) => (hash ^ value) &* 1099511628211UL;

	private void Clear()
	{
		mSections.Clear();
		ClearAndDeleteItems!(mComponents);
		ClearAndDeleteItems!(mSettings);
		DeleteAndNullify!(mTransform);
		DeleteAndNullify!(mActive);
		mTransforms.Clear();
		mEntities.Clear();
	}

	private void Build()
	{
		Clear();
		let scene = mEdit.Scene;
		for (let entity in mEdit.EntitySelection.Items)
		{
			if (scene.FindEntity(entity).IsAssigned)
				mEntities.Add(entity);
		}
		let any = !mEntities.IsEmpty;
		let sceneShown = !any && ShowsScene;
		if (let state = Find<Node>("inspector-state"))
			state.Displayed = !any && !sceneShown;
		if (mGrid != null)
			mGrid.Displayed = any || sceneShown;
		if (let add = Find<Node>("inspector-add"))
			add.Displayed = any; // a scene has settings, not components
		ShowPaste();
		BuildHead();
		if (sceneShown)
		{
			BuildScene();
			if ((mGrid != null) && !mFilter.IsEmpty)
				mGrid.Filter = mFilter;
			return;
		}
		if (!any)
			return;

		// Active: a bag of one bool, a value per entity; a change is each entity's command.
		mActive = new Sedulous.GUI.PropertyBag(mEntities.Count);
		let active = mActive.Add("active", .Bool, Sedulous.GUI.Variant(true));
		active.DisplayName.Set("Active");
		active.Description.Set("Off: the entity and everything under it neither show nor run");
		for (int i < mEntities.Count)
			mActive.SetValue("active", i, Sedulous.GUI.Variant(scene.IsActive(scene.FindEntity(mEntities[i]))));
		mActive.SetOnCommit(new (commit) =>
			{
				mEdit.Commands.BeginGroup("inspector.active");
				for (int i < Math.Min(mEntities.Count, commit.After.Count))
					mEdit.SetEntityActive(mEntities[i], commit.After[i].AsBool);
				mEdit.Commands.EndGroup();
			});
		mSections.Add(cActiveKey, "Entity", mActive);
		BuildTransform();
		BuildComponents();
		if ((mGrid != null) && !mFilter.IsEmpty)
			mGrid.Filter = mFilter;
	}

	private void BuildHead()
	{
		let scene = mEdit.Scene;
		let kind = Find<Label>("inspector-kind");
		let icon = Find<Image>("inspector-icon");
		let count = mEntities.Count;
		if ((count == 0) && ShowsScene)
		{
			if (mName != null)
			{
				mName.Text = (mServices.SceneName != null) ? mServices.SceneName() : "";
				mName.Enabled = false; // the asset's name: Save As names another
			}
			if (kind != null)
				kind.Text = "Scene";
			if (icon != null)
				icon.Source = mServices.SceneIcon.IsEmpty ? "Editor/Icons/Types/SceneDocument.svg" : (StringView)mServices.SceneIcon;
			return;
		}
		if (mName != null)
		{
			mName.Text = (count == 1) ? scene.GetEntityName(scene.FindEntity(mEntities[0])) : "";
			mName.Enabled = count == 1;
		}
		if (kind != null)
		{
			if (count == 0)
				kind.Text = "";
			else if (count == 1)
				kind.Text = "Entity";
			else
				kind.Text = scope $"{count} entities";
		}
		if (icon != null)
		{
			let source = scope String("Editor/Icons/cube.svg");
			if ((count == 1) && (mServices.Icons != null))
			{
				let e = scene.FindEntity(mEntities[0]);
				var found = false;
				scene.ForEachManager(scope [&] (manager) =>
					{
						if (found || (manager.ComponentType == null) || !manager.HasComponent(e))
							return;
						let typeIcon = mServices.Icons.For(manager.ComponentType, default);
						if (!typeIcon.Source.IsEmpty)
						{
							source.Set(typeIcon.Source);
							found = true;
						}
					});
			}
			icon.Source = source;
		}
	}

	private void BuildTransform()
	{
		// A copy of each entity's local transform is the source's object; an edit sets them back
		// through the edit context, one undo step for the selection.
		PullTransforms();
		mTransform = new FieldPropertySource(typeof(Transform), mEntities.Count,
			new (object) => (object < mTransforms.Count) ? &mTransforms[object] : null,
			new (apply) =>
			{
				for (int i < mTransforms.Count)
					apply(i, &mTransforms[i]);
				// Never coalesced with the last.
				mEdit.Commands.BeginGroup(scope $"inspector.transform.{++mEdits}");
				for (int i < Math.Min(mEntities.Count, mTransforms.Count))
					mEdit.SetLocalTransform(mEntities[i], mTransforms[i]);
				mEdit.Commands.EndGroup();
			});
		mSections.Add(cTransformKey, "Transform", mTransform);
	}

	private void PullTransforms()
	{
		let scene = mEdit.Scene;
		if (mTransforms.Count != mEntities.Count)
			mTransforms.Count = mEntities.Count;
		// The row being edited is the gesture's.
		if (((mGrid != null) && mGrid.IsEditing) || ((mTransform != null) && mTransform.Editing))
			return;
		for (int i < mEntities.Count)
			mTransforms[i] = scene.GetLocalTransform(scene.FindEntity(mEntities[i]));
		if (mTransform != null)
			mTransform.RefreshIfChanged();
	}

	private void BuildComponents()
	{
		// Each component every selected entity has, in the scene's order of managers.
		let scene = mEdit.Scene;
		scene.ForEachManager(scope [&] (manager) =>
			{
				let type = manager.ComponentType;
				if (type == null)
					return;
				for (let entity in mEntities)
				{
					if (!manager.HasComponent(scene.FindEntity(entity)))
						return;
				}
				let section = new ComponentSection();
				section.Key.AppendF("c{}", mComponents.Count);
				TitleOf(type, section.Title);
				section.Type = type;
				section.Source = new FieldPropertySource(type, mEntities.Count,
					new [=this, =type] (object) => ComponentAddress(type, object),
					new [=this, =type] (apply) => { CommitComponent(type, apply); },
					mServices.Resources);
				mSections.Add(section.Key, section.Title, section.Source);
				section.Extras = BuildExtras(type, section.Key, section.Title, true);
				mComponents.Add(section);
			});
	}

	// A type's extras (a component's over the entities, a settings block's) under its section; null:
	// none. The caller takes them.
	private Extras BuildExtras(Type type, StringView key, StringView title, bool ofEntities)
	{
		let extras = new Extras(this, ofEntities);
		InspectorExtrasRegistry.ForEach(type, scope [&] (provider) => { provider(extras); });
		if (extras.IsEmpty)
		{
			delete extras;
			return null;
		}
		extras.Refresh();
		// Under the section's header: the grid groups a title's rows together.
		if (extras.HasRows)
			mSections.Add(scope $"x{key}", title, extras.Bag);
		for (int i < extras.SourceCount)
			mSections.Add(scope $"y{key}.{i}", title, extras.SourceAt(i));
		return extras;
	}

	private bool ShowsScene => (mServices.SceneSelected != null) && mServices.SceneSelected();

	// The scene's settings: a section per system's block, a block that can use a profile with the
	// profile's verbs over it.
	private void BuildScene()
	{
		let context = mServices.Context;
		let edit = mEdit;
		let types = scope List<Type>();
		for (let system in mEdit.Scene.Systems)
		{
			if (system.SettingsType != null)
				types.Add(system.SettingsType);
		}
		for (let type in types)
		{
			let section = new SettingsSection();
			TitleOf(type, section.Title);
			if (section.Title.EndsWith(" Settings"))
				section.Title.RemoveFromEnd(9);
			section.Source = new SceneSettingsSource(mEdit, type);
			section.Key.AppendF("s{}", mSettings.Count);
			// A block that can use a profile: where its values are, and the profile's verbs.
			let system = mEdit.FindSystemBySettingsType(type);
			if ((system != null) && (system.SettingsProfileType != null) && (context != null))
			{
				let profile = new Extras(this, false);
				profile.AddShownAction("Open Profile", "Open Profile", "The values below are this profile's: an edit changes every scene using it (written to the profile on save).",
					new [=context, =edit, =type] () =>
					{
						let inUse = ProfileInUse(edit, type);
						if ((context.OpenAsset != null) && !inUse.IsNil)
							context.OpenAsset(inUse);
					},
					new [=edit, =type] () => !ProfileInUse(edit, type).IsNil);
				let profileName = new String()..AppendF("{} {}", mEdit.Scene.Name, section.Title);
				profile.AddShownAction("Make Profile", "Make Profile", "Saves these values as a new profile asset, and this scene uses it.",
					new [=context, =edit, =type, =profileName] () =>
					{
						if (let made = SettingsProfiles.Make(context, edit, type, profileName))
							context.Notify(.Success, scope $"Made profile '{made.Name}'; this scene uses it.");
					} ~ delete profileName,
					new [=edit, =type] () => ProfileInUse(edit, type).IsNil);
				profile.AddShownAction("Copy Into Scene", "Copy Into Scene", "Copies the profile's values into this scene, which then uses its own (the profile is unchanged).",
					new [=edit, =type] () => { edit.MutateSceneSettings(type, scope (s) => { s.CopySettingsProfileIntoScene(); }); },
					new [=edit, =type] () => !ProfileInUse(edit, type).IsNil);
				mSections.Add(scope $"p{section.Key}", section.Title, profile.Bag);
				section.Profile = profile;
			}
			mSections.Add(section.Key, section.Title, section.Source);
			section.Extras = BuildExtras(type, section.Key, section.Title, false);
			mSettings.Add(section);
		}
	}

	// The profile a block uses now; nil: its own values.
	private static Guid ProfileInUse(SceneEditContext edit, Type type)
	{
		let system = edit.FindSystemBySettingsType(type);
		return (system != null) ? system.SettingsProfile : .Empty;
	}

	private void RefreshExtras()
	{
		for (let section in mSettings)
		{
			section.Source.Refresh();
			if (section.Profile != null)
				section.Profile.Refresh();
			if (section.Extras != null)
				section.Extras.Refresh();
		}
		for (let section in mComponents)
		{
			if (section.Extras != null)
				section.Extras.Refresh();
		}
	}

	// Object `object`'s live component of `type`, found again (a pool moves).
	private void* ComponentAddress(Type type, int object)
	{
		if ((object < 0) || (object >= mEntities.Count))
			return null;
		let manager = mEdit.FindManager(type);
		let e = mEdit.Resolve(mEntities[object]);
		return ((manager != null) && e.IsAssigned) ? manager.GetComponentAddress(e) : null;
	}

	// A component edit, one undo step: each entity's component changed by `apply`, kept as its
	// edit context's paste of it (undone by putting each one's back).
	private void CommitComponent(Type type, delegate void(int object, void* value) apply)
	{
		mEdit.Commands.BeginGroup(scope $"inspector.component.{++mEdits}"); // never coalesced with the last
		for (int i < mEntities.Count)
		{
			let target = scope ComponentTarget(mEdit, mEntities[i], type);
			let object = i;
			target.Mutate(scope [&] (instance) => { apply(object, instance); });
		}
		mEdit.Commands.EndGroup();
	}

	private Type ComponentTypeNamed(StringView name)
	{
		Type found = null;
		mEdit.Scene.ForEachManager(scope [&] (manager) =>
			{
				let type = manager.ComponentType;
				if ((type != null) && (found == null) && (type.GetName(.. scope String()) == name))
					found = type;
			});
		return found;
	}

	/// A component type's title: its [DisplayName], else its name without "Component", made
	/// readable; appended.
	private static void TitleOf(Type type, String outTitle)
	{
		if (type.GetCustomAttribute<DisplayNameAttribute>() case .Ok(let shown))
		{
			outTitle.Append(shown.Name);
			return;
		}
		var name = StringView(type.GetName(.. scope String()));
		if (name.EndsWith("Component") && (name.Length > 9))
			name = name.Substring(0, name.Length - 9);
		ReadablePropertyName(name, outTitle);
	}

	private void HeaderMenu(Sedulous.GUI.Menu menu, PropertyRow row)
	{
		if (!row.Category)
			return;
		let type = ComponentOf(row.Path);
		if ((type == null) || mReadOnly)
			return;
		let context = mServices.Context;
		// Copy: the first entity's; paste: over each selected entity's.
		if (context != null)
		{
			menu.AddItem("Copy Component", new [=this, =type, =context] () =>
				{
					if (mEntities.IsEmpty)
						return;
					let blob = scope List<uint8>();
					mEdit.CopyComponent(mEntities[0], type, blob);
					if (!blob.IsEmpty)
						context.CopyToEditorClipboard("component", blob, "component");
				});
			let paste = menu.AddItem("Paste Component Values", new [=this, =context] () =>
				{
					let clip = context.ClipboardData("component");
					mEdit.Commands.BeginGroup("inspector.paste");
					for (let entity in mEntities)
						mEdit.PasteComponent(entity, clip);
					mEdit.Commands.EndGroup();
				});
			paste.Enabled = !context.ClipboardData("component").IsEmpty;
			menu.AddSeparator();
		}
		// Reset: the type's defaults, one step.
		for (let section in mComponents)
		{
			if (section.Type == type)
			{
				let source = section.Source;
				menu.AddItem("Reset", new [=source] () => { source.Revert(""); });
			}
		}
		// Revert to Prefab: while a prefab's member overrides it.
		if (mEntities.Count == 1)
		{
			let manager = mEdit.FindManager(type);
			var member = PrefabMemberInfo();
			if ((manager != null) && PrefabOverrides.FindMember(mEdit.Scene, mEntities[0], out member))
			{
				let revert = menu.AddItem("Revert to Prefab", new [=this, =type] () => { mEdit.RevertComponentToBaseline(mEntities[0], type); });
				revert.Enabled = PrefabOverrides.IsComponentOverridden(mEdit.Scene, member, manager);
			}
		}
		menu.AddSeparator();
		menu.AddItem("Remove Component", new [=this, =type] () =>
			{
				mEdit.Commands.BeginGroup("inspector.remove");
				for (let entity in mEntities)
					mEdit.RemoveComponent(entity, type);
				mEdit.Commands.EndGroup();
			});
	}

	private T Find<T>(StringView id) where T : Node
	{
		let pending = scope List<Node>();
		pending.Add(mPane);
		while (!pending.IsEmpty)
		{
			let node = pending.PopBack();
			if (let widget = node as UIWidget)
			{
				if (widget.Id == id)
					return node as T;
			}
			for (int i < node.ChildCount)
				pending.Add(node.GetChildAt(i));
		}
		return null;
	}
}
