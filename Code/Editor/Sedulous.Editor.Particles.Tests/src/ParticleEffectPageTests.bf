using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Particles;
using Sedulous.Particles.Pipeline;
using Sedulous.GUI;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;
using Sedulous.Editor.Project;
using Sedulous.Pipeline.Core;

namespace Sedulous.Editor.Particles.Tests;

/// The particle effect page over its markup (Data/Editor/ParticleEffectPage.xml) and a scratch
/// project, without a host (no preview): the default system the seed and Add System share; the
/// systems and their modules a tree; the chosen system's rows from its fields, each shown where its
/// render mode uses it, its modules added by type from what derives from the list's base, a curve one
/// value; a module chosen opening in place; each edit, a system added and a module or a system removed
/// one undo step; a system's sub-emitters; the preview started again only when the modules or the
/// systems change; and the creator.
class ParticleEffectPageTests
{
	static bool DataRoot(String outPath)
	{
		var dir = GetCurrentDirectory(.. scope .());
		for (int i < 8)
		{
			let data = PathJoin(dir, "Data", .. scope .());
			if (DirectoryExists(PathJoin(data, "Editor", .. scope .())))
			{
				outPath.Set(data);
				return true;
			}
			let parent = PathParent(dir, .. scope .());
			if (parent == dir)
				break;
			dir.Set(parent);
		}
		return false;
	}

	static Node LoadMarkup(StringView relative)
	{
		let data = scope String();
		Test.Assert(DataRoot(data));
		let text = scope String();
		Test.Assert(System.IO.File.ReadAllText(PathJoin(data, relative, .. scope .()), text) case .Ok);
		RegisterGuiElements();
		RegisterToolkitElements();
		let elements = ElementSet.All();
		defer delete elements;
		let loader = scope MarkupLoader(elements);
		return loader.LoadFromString(text);
	}

	/// A scratch project holding one effect: "Sparks", the default system, renamed, open in the page.
	private class Bed
	{
		public String Dir = new .("scratch_particle_page_project") ~ delete _;
		public EditorProject Project;
		public EditorContext Context = new .() ~ delete _;
		public ParticleEffectEditorPage Page;
		/// The project's: the database owns it.
		public Instance Asset;

		public this()
		{
			ParticleModules.RegisterModules();
			ParticlesPipeline.RegisterAll();
			RemoveDirectoryRecursive(Dir);
			Test.Assert(EditorProject.Create(Dir, "P") case .Ok);
			Project = EditorProject.Open(Dir);
			Test.Assert(Project != null);
			Context.SetProject(Project);
			let instance = Project.SourceDb.RootGroup.CreateInstance("Fountain", typeof(ParticleEffectAsset).GetFullName(.. scope .()));
			Asset = instance;
			Test.Assert(instance != null);
			let asset = scope ParticleEffectAsset();
			ParticleCreators.SeedDefaultEffect(asset.Effect);
			asset.Effect.GetSystem(0).Name.Set("Sparks");
			Test.Assert(instance.WriteObject(asset) case .Ok);
			let services = new AssetPageServices();
			services.LoadMarkup = new (path) => LoadMarkup(path);
			Page = new ParticleEffectEditorPage(Context, services, instance);
			Test.Assert(!Page.LoadFailed);
		}

		public ~this()
		{
			delete Page;
			Context.SetProject(null);
			delete Project;
			RemoveDirectoryRecursive(Dir);
		}

		public ParticleEffect Effect => Page.Effect;

		/// The row named `name` under `parent` of the system's rows (OWNED by the caller), or null.
		public PropertyInfo Info(StringView parent, StringView name, IPropertySource rows = null)
		{
			let list = scope List<PropertyInfo>();
			defer { ClearAndDeleteItems!(list); }
			(rows ?? Page.SystemRows).GetProperties(parent, list);
			for (let info in list)
			{
				if (info.Name != name)
					continue;
				let copy = new PropertyInfo();
				copy.Set(info);
				return copy;
			}
			return null;
		}

		public void Edit(StringView path, Sedulous.GUI.Variant value, IPropertySource rows = null)
		{
			let source = rows ?? Page.SystemRows;
			source.BeginEdit(path);
			source.CommitEdit(path, PropertyWrite(value));
		}

		public String Tree => Page.Tree(.. new String());

		public bool TreeHas(StringView text)
		{
			let tree = Page.Tree(.. scope String());
			return tree.Contains(text);
		}

	}

	[Test]
	public static void TheDefaultSystemTheSeedAndAddSystemShare()
	{
		let fx = scope ParticleEffect();
		ParticleCreators.SeedDefaultEffect(fx);
		Test.Assert(fx.SystemCount == 1);
		let added = ParticleCreators.AddDefaultSystem(fx);
		Test.Assert(fx.SystemCount == 2);
		Test.Assert(added == fx.GetSystem(1));
		Test.Assert(added.Emitter.Mode == .Continuous);
		Test.Assert(Math.Abs(added.Emitter.SpawnRate - 120.0f) < 1e-4f);
		Test.Assert(added.InitializerCount == 4);
		Test.Assert(added.BehaviorCount == 1);
	}

	[Test]
	public static void TheSystemsAndTheirModulesATreeTheChosenSystemsRowsFromItsFields()
	{
		let bed = scope Bed();
		Test.Assert(bed.Page.ChosenSystem == 0);
		let tree = bed.Tree;
		defer delete tree;
		Test.Assert(tree == "Sparks\n  Emitter\n  Initializers\n    Lifetime\n    Velocity\n    Size\n    Color\n  Behaviors\n    Gravity\n  Sub-emitters", tree);
		Test.Assert(bed.Page.Fact("Systems", .. scope .()) == "1");
		Test.Assert(bed.Page.Fact("Particle Budget", .. scope .()) == "2000");

		// Its modes named; its texture shown for a billboard, its mesh not; as a mesh, the other way.
		let render = bed.Info("", "RenderMode");
		defer delete render;
		Test.Assert((render != null) && (render.Kind == .Enum) && (render.Choices.Count == 7));
		{
			let texture = bed.Info("", "TextureRef");
			defer delete texture;
			let mesh = bed.Info("", "MeshRef");
			defer delete mesh;
			Test.Assert(texture.Visible && (texture.Kind == .Reference));
			Test.Assert(!mesh.Visible);
		}
		bed.Edit("RenderMode", Sedulous.GUI.Variant((int64)4));
		Test.Assert(bed.Effect.GetSystem(0).RenderMode == .Mesh);
		{
			let texture = bed.Info("", "TextureRef");
			defer delete texture;
			let mesh = bed.Info("", "MeshRef");
			defer delete mesh;
			Test.Assert(!texture.Visible);
			Test.Assert(mesh.Visible);
		}
		let budget = bed.Info("", "MaxParticles");
		defer delete budget;
		Test.Assert(budget != null, "the budget through its setter");

		// The modules' lists add by type, from what derives from their bases: no list in the page.
		let behaviors = bed.Info("", "mBehaviors");
		defer delete behaviors;
		Test.Assert((behaviors != null) && (behaviors.Kind == .List));
		bool sizeOverLifetime = false;
		for (let type in behaviors.ElementTypes)
			sizeOverLifetime = sizeOverLifetime || (type == "Size over Lifetime");
		Test.Assert(sizeOverLifetime);
		Test.Assert(behaviors.ElementTypes.Count >= 13);
	}

	[Test]
	public static void AModuleAddedByTypeItsCurveOneValueEachEditOneUndoStep()
	{
		let bed = scope Bed();
		let restarts = bed.Page.PreviewRestarts;
		let add = scope ListEdit(.Insert, 1);
		add.ElementType.Set("Size over Lifetime");
		Test.Assert(bed.Page.SystemRows.EditList("mBehaviors", add));
		Test.Assert(bed.Effect.GetSystem(0).BehaviorCount == 2);
		Test.Assert(bed.Effect.GetSystem(0).GetBehavior(1) is SizeOverLifetimeBehavior);
		Test.Assert(bed.TreeHas("    Size over Lifetime"));
		Test.Assert(bed.Page.PreviewRestarts == restarts + 1, "its modules changed");
		let size = bed.Info("mBehaviors.1", "Size");
		defer delete size;
		Test.Assert((size != null) && (size.Kind == .Curve));
		Test.Assert(size.MaxCount == (uint32)ParticleCurve.MaxKeys);

		// A value edited: the preview runs on (the same modules); undone, the value comes back.
		bed.Edit("Emitter.SpawnRate", Sedulous.GUI.Variant(30.0));
		Test.Assert(Math.Abs(bed.Effect.GetSystem(0).Emitter.SpawnRate - 30.0f) < 1e-4f);
		Test.Assert(bed.Page.PreviewRestarts == restarts + 1);
		bed.Page.Commands.Undo();
		Test.Assert(Math.Abs(bed.Effect.GetSystem(0).Emitter.SpawnRate - 120.0f) < 1e-4f);
		bed.Page.Commands.Undo();
		Test.Assert(bed.Effect.GetSystem(0).BehaviorCount == 1);
		Test.Assert(!bed.TreeHas("Size over Lifetime"));
	}

	[Test]
	public static void AModuleChosenIsRemovedAsOneStepASystemAddedAndRemovedAnEffectKeepingOne()
	{
		let bed = scope Bed();
		bed.Page.Choose(.(.Initializer, 0, 1)); // Velocity
		Test.Assert(bed.Page.RemoveChosen());
		Test.Assert(bed.Effect.GetSystem(0).InitializerCount == 3);
		{
			let tree = bed.Tree;
			defer delete tree;
			Test.Assert(tree == "Sparks\n  Emitter\n  Initializers\n    Lifetime\n    Size\n    Color\n  Behaviors\n    Gravity\n  Sub-emitters", tree);
		}
		bed.Page.Commands.Undo();
		Test.Assert(bed.Effect.GetSystem(0).InitializerCount == 4);

		// The one system stays.
		bed.Page.Choose(.(.System, 0, -1));
		Test.Assert(!bed.Page.RemoveChosen());
		Test.Assert(bed.Effect.SystemCount == 1);

		bed.Page.AddSystem();
		Test.Assert(bed.Effect.SystemCount == 2);
		Test.Assert(bed.Page.ChosenSystem == 1);
		Test.Assert(bed.Page.Fact("Systems", .. scope .()) == "2");
		Test.Assert(bed.TreeHas("\nSystem 2\n"));
		// The chosen system's name edited reaches the tree.
		bed.Edit("Name", Sedulous.GUI.Variant("Smoke"));
		Test.Assert(bed.TreeHas("\nSmoke\n"));
		Test.Assert(bed.Page.RemoveChosen());
		Test.Assert(bed.Effect.SystemCount == 1);
		Test.Assert(bed.Page.ChosenSystem == 0);
		bed.Page.Commands.Undo(); // the system back, its name with it
		Test.Assert(bed.Effect.SystemCount == 2);
		Test.Assert(bed.Effect.GetSystem(1).Name == "Smoke");
		bed.Page.Commands.Undo();
		bed.Page.Commands.Undo();
		Test.Assert(bed.Effect.SystemCount == 1);
		Test.Assert(bed.Page.ChosenSystem == 0);
	}

	[Test]
	public static void ASystemsSubEmittersEachIntoAnotherSystemChosenByNameInItsRowsAndItsTree()
	{
		let bed = scope Bed();
		bed.Page.AddSystem();
		bed.Edit("Name", Sedulous.GUI.Variant("Smoke")); // the system added, chosen
		bed.Page.Choose(.(.System, 0, -1)); // Sparks spawns into Smoke
		Test.Assert(bed.Page.SystemRows.EditList("SubEmitters", scope ListEdit(.Insert, 0)));
		Test.Assert(bed.Effect.GetSystem(0).SubEmitters.Count == 1);
		Test.Assert(bed.Effect.GetSystem(1).SubEmitters.IsEmpty, "the other system has none");

		// Where it spawns: the other systems by name, never itself.
		let into = bed.Info("SubEmitters.0", "ChildSystemIndex");
		defer delete into;
		Test.Assert((into != null) && (into.Kind == .Enum));
		Test.Assert(into.Choices.Count == 2);
		Test.Assert(into.Choices[0].Name == "Nothing");
		Test.Assert(into.Choices[1].Name == "Smoke");
		bed.Edit("SubEmitters.0.ChildSystemIndex", Sedulous.GUI.Variant((int64)1));
		Test.Assert(bed.Effect.GetSystem(0).SubEmitters[0].ChildSystemIndex == 1);
		let link = bed.Info("SubEmitters", "0");
		defer delete link;
		Test.Assert((link != null) && (link.DisplayName == "On death into Smoke"), link.DisplayName);
		// In the tree under the system that owns it, and chosen there, opened in place.
		Test.Assert(bed.TreeHas("  Sub-emitters\n    On death into Smoke\nSmoke"));
		bed.Page.Choose(.(.SubEmitter, 0, 0));
		Test.Assert(bed.Page.ChosenSystem == 0);

		// The system it spawns into removed: it does nothing, until the removal is undone.
		bed.Page.Choose(.(.System, 1, -1));
		Test.Assert(bed.Page.RemoveChosen());
		Test.Assert(bed.Effect.GetSystem(0).SubEmitters[0].ChildSystemIndex == -1);
		bed.Page.Commands.Undo();
		Test.Assert(bed.Effect.SystemCount == 2);
		Test.Assert(bed.Effect.GetSystem(0).SubEmitters[0].ChildSystemIndex == 1);

		// Taken away from the tree, as a module is.
		bed.Page.Choose(.(.SubEmitter, 0, 0));
		Test.Assert(bed.Page.RemoveChosen());
		Test.Assert(bed.Effect.GetSystem(0).SubEmitters.IsEmpty);
	}

	[Test]
	public static void TheAssetWrittenOutsideItShowsOnACleanPageUnsavedEditsAreKept()
	{
		let bed = scope Bed();
		// Written from outside: a second system, named.
		{
			let written = scope ParticleEffectAsset();
			ParticleCreators.SeedDefaultEffect(written.Effect);
			written.Effect.GetSystem(0).Name.Set("Shells");
			ParticleCreators.AddDefaultSystem(written.Effect).Name.Set("Sparks");
			Test.Assert(bed.Asset.WriteObject(written) case .Ok);
		}
		bed.Page.OnAssetExternallyModified();
		Test.Assert(bed.Effect.SystemCount == 2);
		Test.Assert(bed.TreeHas("\nSparks\n"));
		{
			let tree = bed.Tree;
			defer delete tree;
			Test.Assert(tree.StartsWith("Shells\n"), tree);
		}
		Test.Assert(bed.Page.Fact("Systems", .. scope .()) == "2");
		// The rows are over the effect read, not the one it replaced.
		Test.Assert(bed.Page.SystemRows.EditList("SubEmitters", scope ListEdit(.Insert, 0)));
		Test.Assert(bed.Effect.GetSystem(0).SubEmitters.Count == 1);

		// With unsaved edits, another write leaves the page as it is.
		Test.Assert(bed.Page.IsDirty);
		{
			let again = scope ParticleEffectAsset();
			ParticleCreators.SeedDefaultEffect(again.Effect);
			Test.Assert(bed.Asset.WriteObject(again) case .Ok);
		}
		bed.Page.OnAssetExternallyModified();
		Test.Assert(bed.Effect.SystemCount == 2);
		Test.Assert(bed.Effect.GetSystem(0).SubEmitters.Count == 1);
	}

	[Test]
	public static void ASystemFoldedInTheTreeStaysFoldedWhenAnotherRowIsChosenOrTheEffectChanges()
	{
		let bed = scope Bed();
		let tree = bed.Page.Content.FindElement("particle-tree") as TreeView;
		Test.Assert(tree != null);
		Test.Assert(tree.IsIdExpanded(0), "a system opens the first time it shows");
		tree.SetIdExpanded(0, false);
		bed.Page.Choose(.(.Emitter, 0, -1));
		Test.Assert(!tree.IsIdExpanded(0));
		bed.Edit("Emitter.SpawnRate", Sedulous.GUI.Variant(30.0)); // an edit rebuilds the tree
		Test.Assert(!tree.IsIdExpanded(0));
		bed.Page.AddSystem();
		Test.Assert(!tree.IsIdExpanded(0));
		// The new system's row opens.
		int added = 0;
		for (int node = 1; (node < 64) && (added == 0); node++)
		{
			if (tree.IsIdExpanded((ItemId)node))
				added = node;
		}
		Test.Assert(added > 0);
	}

	[Test]
	public static void WithoutAPreviewTheTransportHasNothingToPlay()
	{
		let bed = scope Bed();
		Test.Assert(!bed.Page.CanPlay);
		bed.Page.Stop(); // nothing to stop: the effect untouched
		Test.Assert(bed.Effect.GetSystem(0).Emitter.IsEmitting);
	}

	/// The domain's "Particle Effect" creator, as File > New runs it. Leaks nothing: the registry is
	/// static to the test class.
	private static AssetCreatorRegistry sCreators = null ~ delete _;
	private static AssetCreator Creator()
	{
		if (sCreators == null)
		{
			sCreators = new .();
			ParticleCreators.Register(sCreators);
		}
		return sCreators.FindByLabel("Particle Effect");
	}

	[Test]
	public static void TheDefaultSeedIsAOneSystemFountainWithTheCoreModules()
	{
		let fx = scope ParticleEffect();
		ParticleCreators.SeedDefaultEffect(fx);
		Test.Assert(fx.SystemCount == 1);
		let sys = fx.GetSystem(0);
		Test.Assert(sys != null);
		Test.Assert(sys.Emitter.Mode == .Continuous);
		Test.Assert(Math.Abs(sys.Emitter.SpawnRate - 120.0f) < 1e-4f);

		LifetimeInitializer life = null;
		VelocityInitializer vel = null;
		SizeInitializer size = null;
		ColorInitializer color = null;
		for (int32 i < sys.InitializerCount)
		{
			if (let p = sys.GetInitializer(i) as LifetimeInitializer) life = p;
			if (let p = sys.GetInitializer(i) as VelocityInitializer) vel = p;
			if (let p = sys.GetInitializer(i) as SizeInitializer) size = p;
			if (let p = sys.GetInitializer(i) as ColorInitializer) color = p;
		}
		Test.Assert((life != null) && (vel != null) && (size != null) && (color != null));
		Test.Assert(Math.Abs(life.Lifetime.Min - 1.5f) < 1e-4f);
		Test.Assert(Math.Abs(life.Lifetime.Max - 2.5f) < 1e-4f);
		Test.Assert(vel.BaseVelocity.Y == 5.0f);

		GravityBehavior grav = null;
		for (int32 i < sys.BehaviorCount)
		{
			if (let p = sys.GetBehavior(i) as GravityBehavior)
				grav = p;
		}
		Test.Assert(grav != null);
	}

	private static MenuItem ItemOf(Node menu, StringView text)
	{
		for (int i < menu.ChildCount)
		{
			let node = menu.GetChildAt(i);
			if (let item = node as MenuItem)
			{
				if (item.Text == text)
					return item;
			}
			if (let found = ItemOf(node, text))
				return found;
		}
		return null;
	}

	[Test]
	public static void ATreeRowsMenuAddsAModuleByTypeMovesOneDeletesItASystemRenamedInPlace()
	{
		let bed = scope Bed();
		let context = new GUIContext();
		let root = new SceneRoot(context);
		context.ReleaseRef(); // the root's keeps it
		defer root.ReleaseRef();
		root.Size = .(1200.0f, 800.0f);
		root.AddChild(bed.Page.Content);
		defer root.RemoveChild(bed.Page.Content);
		root.UpdateLayout();
		let owner = bed.Page.Content;

		// A module's: Move Down, one step, still chosen where it went.
		bed.Page.ShowRowMenu(.(.Initializer, 0, 0), owner, .(40.0f, 80.0f)); // Lifetime
		Test.Assert(bed.Page.RowMenu != null);
		let down = ItemOf(bed.Page.RowMenu, "Move Down");
		Test.Assert(down != null);
		Test.Assert(down.HandleActivate());
		let tree = bed.Tree;
		defer delete tree;
		Test.Assert(tree == "Sparks\n  Emitter\n  Initializers\n    Velocity\n    Lifetime\n    Size\n    Color\n  Behaviors\n    Gravity\n  Sub-emitters");
		bed.Page.Commands.Undo();
		Test.Assert(bed.TreeHas("Initializers\n    Lifetime\n    Velocity"));
		Test.Assert(!bed.Page.MoveModule(.(.Initializer, 0, 0), -1), "the first goes no higher");

		// A folder's: its modules by type; one added at the end, chosen.
		bed.Page.ShowRowMenu(.(.Behaviors, 0, -1), owner, .(40.0f, 80.0f));
		Test.Assert(bed.Page.RowMenu != null);
		let add = ItemOf(bed.Page.RowMenu, "Add Size over Lifetime");
		Test.Assert(add != null);
		Test.Assert(add.HandleActivate());
		Test.Assert(bed.Effect.GetSystem(0).BehaviorCount == 2);
		Test.Assert(bed.Effect.GetSystem(0).GetBehavior(1) is SizeOverLifetimeBehavior);

		// Delete on a module's menu.
		bed.Page.ShowRowMenu(.(.Behavior, 0, 1), owner, .(40.0f, 80.0f));
		Test.Assert(bed.Page.RowMenu != null);
		let remove = ItemOf(bed.Page.RowMenu, "Delete");
		Test.Assert(remove != null);
		Test.Assert(remove.HandleActivate());
		Test.Assert(bed.Effect.GetSystem(0).BehaviorCount == 1);

		// A system's: Delete off while it is the only one; renamed in place, one step.
		bed.Page.ShowRowMenu(.(.System, 0, -1), owner, .(40.0f, 80.0f));
		Test.Assert(bed.Page.RowMenu != null);
		let deleteSystem = ItemOf(bed.Page.RowMenu, "Delete System");
		Test.Assert(deleteSystem != null);
		Test.Assert(!deleteSystem.Enabled);
		bed.Page.RowMenu.Close();
		Test.Assert(bed.Page.BeginRename(0));
		Test.Assert(bed.Page.RenameSystem(0, "Embers"));
		Test.Assert(bed.Effect.GetSystem(0).Name == "Embers");
		Test.Assert(bed.TreeHas("Embers\n"));
		bed.Page.Commands.Undo();
		Test.Assert(bed.Effect.GetSystem(0).Name == "Sparks");
	}

	[Test]
	public static void TheCreatorSeedsAnEffectUnderParticleEffects()
	{
		ParticleModules.RegisterModules();
		ParticlesPipeline.RegisterAll();
		let dir = PathJoin(Directory.GetCurrentDirectory(.. scope .()), "scratch_editor_particle_creator_test", .. scope .());
		RemoveDirectoryRecursive(dir);
		defer RemoveDirectoryRecursive(dir);
		Test.Assert(EditorProject.Create(dir, "P") case .Ok);
		let project = EditorProject.Open(dir);
		Test.Assert(project != null);
		defer delete project;

		Test.Assert(Creator().Create(null, null, "") == null);

		let first = Creator().Create(null, project.SourceDb.RootGroup, "");
		Test.Assert(first != null);
		Test.Assert(first.GetPath(.. scope .()) == "ParticleEffects/ParticleEffect");
		Test.Assert(AssetTypeNames.Matches(first.TypeName, "ParticleEffectAsset"));
		let object = first.ReadObject();
		defer delete object;
		let asset = object as ParticleEffectAsset;
		Test.Assert(asset != null);
		Test.Assert(asset.Effect.SystemCount == 1);
		Test.Assert(asset.Effect.GetSystem(0).InitializerCount == 4);

		let second = Creator().Create(null, project.SourceDb.RootGroup, "");
		Test.Assert((second != null) && (second.GetPath(.. scope .()) == "ParticleEffects/ParticleEffect.2"));
	}
}
