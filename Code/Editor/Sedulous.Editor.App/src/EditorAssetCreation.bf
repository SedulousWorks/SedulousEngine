using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Content;
using Sedulous.Pipeline.Core;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.App;

/// What an EditorAssetCreation works over. The services are borrowed for its life; the
/// delegates are its own.
class EditorAssetCreationServices
{
	/// Where a create that cannot run says why.
	public EditorContext Context = null;
	/// The mutation gate a create waits on, and the cook a builder-backed asset gets.
	public EditorCookService Cook = null;
	public BuilderRegistry Builders = null;
	/// Opens the new asset's page. Owned.
	public delegate void(Instance instance) OnOpenPage ~ delete _;
	/// A new asset exists: the assets view rebuilds to show its row, since the File menu's
	/// path bypasses the view's own rebuild. Owned.
	public delegate void(Instance instance) OnCreated ~ delete _;
}

/// File > New's create-and-open, out of the application (Raptor's editor-gui spec, 5.1, layer
/// 3). A creator writes the new asset into a group (its default group, else the root, when
/// none is picked); a scene becomes the project's default when the settings name none; the
/// assets view shows the new row and an asset a builder cooks is cooked at once, so it can be
/// picked; then its page opens. While a cook reads the databases (their structure frozen) the
/// create waits and runs when the cook is done.
///
/// A queued create holds this object and its creator, so the owner shuts the cook service
/// down (which drops the queue) before either goes.
class EditorAssetCreation
{
	private EditorAssetCreationServices mServices ~ delete _;
	/// Borrowed: the session's.
	private EditorProject mProject = null;

	/// TAKES OWNERSHIP of the services.
	public this(EditorAssetCreationServices services)
	{
		mServices = services;
	}

	/// The project assets are created in; null between projects.
	public void SetProject(EditorProject project)
	{
		mProject = project;
	}

	/// `creator` writes a new asset into `group` (the creator's choice when null) and its page
	/// opens.
	public void CreateAndOpen(AssetCreator creator, Group group = null)
	{
		let context = mServices.Context;
		// The cook gate: the plan worker reads the databases with their structure frozen.
		if (mServices.Cook.MutationLocked)
		{
			mServices.Cook.RunWhenIdle(new [=creator, =group, =this]() => { CreateAndOpen(creator, group); });
			context.Notify(.Info, "Create queued until the current cook finishes.");
			return;
		}
		if (mProject == null)
		{
			context.Notify(.Error, "Create failed: no project is open.");
			return;
		}
		let instance = creator.Create(group, mProject.SourceDb.RootGroup, mProject.SourcesRoot(.. scope .()));
		if (instance == null)
		{
			context.Notify(.Error, scope $"Create failed: the {creator.Label} could not be written.");
			return;
		}
		AfterCreate(creator, instance);
		if (mServices.OnOpenPage != null)
			mServices.OnOpenPage(instance);
	}

	/// File > New <creator>: an item per creator of the context's registry, in registration
	/// order, each creating and opening; a creator with a category goes in a submenu of that name
	/// (the categories after the plain items, by name). The menu bar's File menu leads with these.
	public void AddNewItems(Sedulous.GUI.Menu file)
	{
		AddCreatorItems(file, mServices.Context.Creators, false, scope [=this] (into, creator, inCategory) =>
			{
				if (inCategory)
					into.AddItem(creator.Label, new [=creator, =this]() => { CreateAndOpen(creator); });
				else
					into.AddItem(scope $"New {creator.Label}", new [=creator, =this]() => { CreateAndOpen(creator); });
			});
	}

	/// The creators as menu items, File > New's and the assets browser's New: `add` puts each
	/// into `menu` (a creator with no category, in registration order) or into the submenu of its
	/// category (`inCategory`), the categories after the plain items (`separated`: past a
	/// separator), by name, each holding its creators in registration order.
	public static void AddCreatorItems(Sedulous.GUI.Menu menu, AssetCreatorRegistry creators, bool separated,
		delegate void(Sedulous.GUI.Menu into, AssetCreator creator, bool inCategory) add)
	{
		let categories = scope List<StringView>();
		for (let creator in creators)
		{
			if (creator.Category.IsEmpty)
			{
				add(menu, creator, false);
				continue;
			}
			if (!categories.Contains(creator.Category))
				categories.Add(creator.Category);
		}
		categories.Sort(scope (a, b) => a <=> b);
		if (separated && !categories.IsEmpty)
			menu.AddSeparator();
		for (let category in categories)
		{
			let submenu = menu.AddSubMenu(category);
			for (let creator in creators)
			{
				if (creator.Category == category)
					add(submenu, creator, true);
			}
		}
	}

	/// What follows every creation, File > New's and asset_create's alike: a first scene
	/// becomes the project's default, the assets view shows the new row, and a type a builder
	/// cooks is cooked so it is pickable at once.
	public void AfterCreate(AssetCreator creator, Instance instance)
	{
		if (creator.SetsDefaultScene && (mProject != null) && !mProject.Settings.DefaultSceneId.IsSet && mProject.Settings.DefaultScene.IsEmpty)
		{
			mProject.Settings.DefaultSceneId = instance.Id;
			instance.GetPath(mProject.Settings.DefaultScene..Clear());
			mProject.SaveSettings().IgnoreError();
		}
		if (mServices.OnCreated != null)
			mServices.OnCreated(instance);
		if (mServices.Builders.FindByTypeName(instance.TypeName) != null)
			mServices.Cook.RequestCook(false);
	}
}
