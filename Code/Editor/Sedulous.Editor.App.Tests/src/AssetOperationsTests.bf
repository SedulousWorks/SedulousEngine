using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Content;
using Sedulous.Pipeline.Core;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.App;

namespace Sedulous.Editor.App.Tests;

/// A stored object for the operations' assets, so a duplicate has something to copy.
[Serializable]
class OpsAsset
{
	public int32 Value;
}

/// The registry of this project's serializable types, generated from the declarations.
[SerializableRegistry]
static class AppTestSerializables
{
}

/// What can be done to a project's assets and groups, over a scratch project: a rename kept by the
/// name rule (refused saying why, the default scene's path mirror following), a group's rename; a
/// duplicate beside its source; a new group a folder on disk at once; a delete naming what goes, its
/// pages closed first and the default scene let go with it; a group's delete with all it holds; and
/// the export flag kept with the project. Then what Sedulous adds so each behaviour has a test: the
/// cooked product's name and group following a rename, the path mirror of a manifest with no guid,
/// a delete run after the event that asked, an agent's delete at once, and every operation waiting
/// for a cook that reads the databases, saying so, then running.
static class AssetOperationsTests
{
	/// Content (Crate, Barrel, Town (Bell)), each written, open in an editor context; the
	/// operations over it, the pages they close in Closed (ClosedWhileThere counting the ones
	/// closed before their asset went), the notices in Said, the status lines in Statuses. With a
	/// cook over no builders, its mutation lock the bed's Locked (`withCook`); with the work an
	/// operation runs later held in Waiting until RunLater (`deferred`), else run at once.
	private class Bed
	{
		public String Dir = new .() ~ delete _;
		public String TypeName = new .() ~ delete _;
		public EditorProject Project;
		public EditorContext Context = new .();
		public BuilderRegistry Builders = null;
		public EditorCookService Cook = null;
		public bool Locked = false;
		public AssetOperations Ops;
		public List<Guid> Closed = new .() ~ delete _;
		public int ClosedWhileThere = 0;
		public List<String> Said = new .() ~ DeleteContainerAndItems!(_);
		public List<String> Statuses = new .() ~ DeleteContainerAndItems!(_);
		public List<delegate void()> Waiting = new .() ~ DeleteContainerAndItems!(_);
		/// The group a group's delete said to show next.
		public Group ShownNext = null;
		// The project's.
		public Group Top;
		public Group Town;
		public Instance Crate;
		public Instance Barrel;
		public Instance Bell;

		public this(StringView dir, bool withCook = false, bool deferred = false)
		{
			AppTestSerializables.RegisterAll();
			Dir.Set(dir);
			RemoveDirectoryRecursive(Dir);
			Test.Assert(EditorProject.Create(Dir, "Ops") case .Ok);
			Project = EditorProject.Open(Dir);
			Test.Assert(Project != null);
			typeof(OpsAsset).GetFullName(TypeName);
			Top = Project.SourceDb.RootGroup;
			Crate = Top.CreateInstance("Crate", TypeName);
			Barrel = Top.CreateInstance("Barrel", TypeName);
			Town = Top.CreateGroup("Town");
			Bell = Town.CreateInstance("Bell", TypeName);
			Test.Assert((Crate != null) && (Barrel != null) && (Bell != null));
			Write(Crate);
			Write(Barrel);
			Write(Bell);
			Context.SetProject(Project);
			let bed = this;
			Context.OnNotice = new [=bed] (kind, message) => { bed.Said.Add(new String(message)); };
			Context.OnStatus = new [=bed] (text) => { bed.Statuses.Add(new String(text)); };
			if (withCook)
			{
				Builders = new .();
				Cook = new .();
				Cook.ExternalMutationLock = new [=bed] () => bed.Locked;
				Cook.Initialize(Project, Builders);
			}
			let services = new AssetOperationsServices();
			services.Context = Context;
			services.Cook = Cook;
			services.ClosePages = new [=bed] (id) =>
				{
					bed.Closed.Add(id);
					if (bed.Project.SourceDb.GetInstance(id) != null)
						bed.ClosedWhileThere++;
				};
			if (deferred)
				services.Later = new [=bed] (work) => { bed.Waiting.Add(work); };
			Ops = new AssetOperations(services);
		}

		public ~this()
		{
			// The cook first (it drops what waits on it), then the operations it held, the context
			// before the project it borrows.
			if (Cook != null)
			{
				Cook.Shutdown();
				delete Cook;
			}
			delete Builders;
			delete Ops;
			Context.SetProject(null);
			delete Context;
			delete Project;
			RemoveDirectoryRecursive(Dir);
		}

		/// `instance` holding an OpsAsset of 7.
		public void Write(Instance instance)
		{
			let asset = scope OpsAsset();
			asset.Value = 7;
			Test.Assert(instance.WriteObject(asset) case .Ok);
		}

		/// Runs the work given to run later, as the GUI's drain does.
		public void RunLater()
		{
			let work = scope List<delegate void()>();
			work.AddRange(Waiting);
			Waiting.Clear();
			for (let w in work)
			{
				w();
				delete w;
			}
		}

		public StringView LastSaid => Said.IsEmpty ? "" : Said.Back;
		public StringView LastStatus => Statuses.IsEmpty ? "" : Statuses.Back;
	}

	/// A rename keeps the name rule, saying why not; its cooked product's name and the default
	/// scene's path follow, saved with the manifest.
	[Test]
	public static void ARenameKeepsTheNameRuleSayingWhyNotTheCookedNameAndTheDefaultScenesPathFollow()
	{
		let bed = scope Bed("scratch_asset_ops_rename");
		let ops = bed.Ops;
		let why = scope String();
		Test.Assert(!ops.Rename(bed.Crate.Id, "Barrel", why));
		Test.Assert(why == "Barrel is already in Content.");
		why.Clear();
		Test.Assert(!ops.Rename(bed.Crate.Id, "a/b", why));
		Test.Assert(why == "A name cannot hold /.");
		why.Clear();
		Test.Assert(!ops.Rename(bed.Crate.Id, "", why));
		Test.Assert(why == "Enter a name.");
		why.Clear();
		Test.Assert(!ops.Rename(Guid(9, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0), "Box", why));
		Test.Assert(why == "That asset is gone.");
		Test.Assert(bed.Crate.Name == "Crate");
		why.Clear();
		Test.Assert(ops.Rename(bed.Crate.Id, "Crate", why) && why.IsEmpty, "its own name: nothing to do");

		let cooked = bed.Project.CookedDb.RootGroup.CreateInstanceWithId(bed.Crate.Id, "Crate", bed.TypeName);
		Test.Assert(cooked != null);
		bed.Project.Settings.DefaultSceneId = bed.Crate.Id;
		bed.Project.Settings.DefaultScene.Set("Crate");
		Test.Assert(ops.Rename(bed.Crate.Id, "Box", why) && why.IsEmpty);
		Test.Assert(bed.Crate.Name == "Box");
		Test.Assert(cooked.Name == "Box", "its product's name in step");
		Test.Assert(bed.Project.Settings.DefaultScene == "Box");
		{
			let again = EditorProject.Open(bed.Dir);
			Test.Assert(again != null);
			defer delete again;
			Test.Assert(again.Settings.DefaultScene == "Box", "the manifest saved");
			Test.Assert(again.SourceDb.RootGroup.GetInstance("Box") != null, "its file moved");
		}

		// A manifest with only the path takes the guid with the new one.
		bed.Project.Settings.DefaultSceneId = .Empty;
		bed.Project.Settings.DefaultScene.Set("Barrel");
		Test.Assert(ops.Rename(bed.Barrel.Id, "Keg", why) && why.IsEmpty);
		Test.Assert(bed.Project.Settings.DefaultSceneId == bed.Barrel.Id);
		Test.Assert(bed.Project.Settings.DefaultScene == "Keg");
	}

	/// A group renames, not the top one, by the folder's rule; the cooked group of its path and
	/// the default scene's path follow, from its guid, or from its path in a manifest with none.
	[Test]
	public static void AGroupRenamesItsCookedGroupAndTheDefaultScenesPathFollow()
	{
		let bed = scope Bed("scratch_asset_ops_rename_group");
		let ops = bed.Ops;
		let why = scope String();
		Test.Assert(!ops.RenameGroup(bed.Top, "Top", why));
		Test.Assert(why == "Content cannot be renamed.");
		why.Clear();
		Test.Assert(!ops.RenameGroup(bed.Town, "a:b", why));
		Test.Assert(why == "A name cannot hold :.");
		why.Clear();
		Test.Assert(!ops.RenameGroup(bed.Town, "", why));
		Test.Assert(why == "Enter a name.");
		why.Clear();
		Test.Assert(bed.Top.CreateGroup("Market") != null);
		Test.Assert(!ops.RenameGroup(bed.Town, "Market", why));
		Test.Assert(why == "Market is already there.");
		why.Clear();
		Test.Assert(bed.Town.Name == "Town");

		let cooked = bed.Project.CookedDb.RootGroup.CreateGroup("Town");
		Test.Assert(cooked != null);
		bed.Project.Settings.DefaultSceneId = bed.Bell.Id;
		bed.Project.Settings.DefaultScene.Set("Town/Bell");
		Test.Assert(ops.RenameGroup(bed.Town, "Village", why) && why.IsEmpty);
		Test.Assert(bed.Town.Name == "Village");
		Test.Assert(bed.Bell.GetPath(.. scope .()) == "Village/Bell");
		Test.Assert(bed.Project.CookedDb.RootGroup.GetGroup("Village") === cooked, "the cooked group in step");
		Test.Assert(bed.Project.Settings.DefaultScene == "Village/Bell");

		// No guid: the path under the group moves with it.
		bed.Project.Settings.DefaultSceneId = .Empty;
		Test.Assert(ops.RenameGroup(bed.Town, "Hamlet", why) && why.IsEmpty);
		Test.Assert(bed.Project.Settings.DefaultScene == "Hamlet/Bell");
		{
			let again = EditorProject.Open(bed.Dir);
			Test.Assert(again != null);
			defer delete again;
			Test.Assert(again.Settings.DefaultScene == "Hamlet/Bell", "the manifest saved");
			Test.Assert(again.SourceDb.RootGroup.GetGroup("Hamlet") != null, "its folder moved");
		}
	}

	/// A duplicate lands beside its source, a copy of it by the next free name, said; a new group
	/// is a folder at once, so a project opened again has it while it is empty.
	[Test]
	public static void ADuplicateLandsBesideItsSourceANewGroupIsAFolderAtOnce()
	{
		let bed = scope Bed("scratch_asset_ops_make");
		let ops = bed.Ops;
		let copy = ops.Duplicate(bed.Crate.Id);
		Test.Assert(copy != null);
		Test.Assert(copy.OwningGroup === bed.Top);
		Test.Assert(copy.Name == "Crate.2");
		Test.Assert(copy.Id != bed.Crate.Id);
		let read = copy.ReadObject();
		Test.Assert(read != null);
		defer delete read;
		Test.Assert(((OpsAsset)read).Value == 7, "a copy of it");
		Test.Assert(bed.LastStatus == "Duplicated as Crate.2.");
		let third = ops.Duplicate(bed.Crate.Id);
		Test.Assert((third != null) && (third.Name == "Crate.3"));
		Test.Assert(ops.Duplicate(Guid(9, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0)) == null);

		let made = ops.CreateGroup(bed.Town);
		Test.Assert(made != null);
		Test.Assert(made.Name == "Group");
		Test.Assert(made.Parent === bed.Town);
		Test.Assert(bed.Project.SourceDb.Mount.Exists("Town/Group"), "on disk while empty");
		let second = ops.CreateGroup(bed.Town);
		Test.Assert(second != null);
		Test.Assert(second.Name == "Group.2");
		{
			let again = EditorProject.Open(bed.Dir);
			Test.Assert(again != null);
			defer delete again;
			let town = again.SourceDb.RootGroup.GetGroup("Town");
			Test.Assert((town != null) && (town.GetGroup("Group") != null), "a project opened again has it");
		}
	}

	/// A delete names what goes; it runs after the event that asked, its pages closed first, and
	/// lets the default scene go with it, saying how many went. A group goes with all it holds,
	/// what showed it moved to its parent first; the top group is never deleted. An agent's delete
	/// runs at once.
	[Test]
	public static void ADeleteNamesWhatGoesClosesItsPagesFirstAndLetsTheDefaultSceneGo()
	{
		let bed = scope Bed("scratch_asset_ops_delete", false, true);
		let ops = bed.Ops;
		let anvil = bed.Top.CreateInstance("Anvil", bed.TypeName);
		Test.Assert(anvil != null);
		Guid[5] ids = .(bed.Crate.Id, bed.Barrel.Id, bed.Bell.Id, anvil.Id, Guid(9, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0));
		Test.Assert(ops.Names(Span<Guid>(&ids[0], 1), .. scope .()) == "Crate");
		Test.Assert(ops.Names(Span<Guid>(&ids[0], 2), .. scope .()) == "Crate and Barrel");
		Test.Assert(ops.Names(Span<Guid>(&ids[0], 3), .. scope .()) == "Crate, Barrel and Bell");
		Test.Assert(ops.Names(Span<Guid>(&ids[0], 4), .. scope .()) == "Crate, Barrel and 2 more");
		Test.Assert(ops.Names(Span<Guid>(&ids[4], 1), .. scope .()).IsEmpty, "one not there is not named");

		let crate = bed.Crate.Id;
		let barrel = bed.Barrel.Id;
		bed.Project.Settings.DefaultSceneId = crate;
		ops.Delete(Span<Guid>(&ids[0], 2));
		Test.Assert(bed.Project.SourceDb.GetInstance(crate) != null, "after the event that asked");
		Test.Assert(bed.Closed.IsEmpty);
		Test.Assert(bed.Waiting.Count == 1);
		bed.RunLater();
		Test.Assert(bed.Project.SourceDb.GetInstance(crate) == null);
		Test.Assert(bed.Project.SourceDb.GetInstance(barrel) == null);
		Test.Assert((bed.Closed.Count == 2) && (bed.Closed[0] == crate) && (bed.Closed[1] == barrel));
		Test.Assert(bed.ClosedWhileThere == 2, "its pages closed before it went");
		Test.Assert(!bed.Project.Settings.DefaultSceneId.IsSet && bed.Project.Settings.DefaultScene.IsEmpty, "gone with it");
		Test.Assert(bed.LastStatus == "Deleted 2 assets.");
		{
			let again = EditorProject.Open(bed.Dir);
			Test.Assert(again != null);
			defer delete again;
			Test.Assert(!again.Settings.DefaultSceneId.IsSet, "the manifest saved");
			Test.Assert(again.SourceDb.RootGroup.GetInstance("Crate") == null, "its file gone");
		}

		// A group with all it holds, all the way down; what showed it is moved to its parent first.
		let inner = bed.Town.CreateGroup("Inner");
		let gong = inner.CreateInstance("Gong", bed.TypeName);
		Test.Assert(gong != null);
		let bell = bed.Bell.Id;
		let gongId = gong.Id;
		bed.Project.Settings.DefaultSceneId = gongId;
		Test.Assert(AssetOperations.CountAssets(bed.Town) == 2);
		let collected = scope List<Guid>();
		AssetOperations.CollectAssets(bed.Town, collected);
		Test.Assert((collected.Count == 2) && collected.Contains(bell) && collected.Contains(gongId));
		let b = bed;
		ops.DeleteGroup(bed.Town, new [=b] (next) => { b.ShownNext = next; });
		Test.Assert(bed.Top.GetGroup("Town") != null, "after the event that asked");
		bed.RunLater();
		Test.Assert(bed.ShownNext === bed.Top);
		Test.Assert(bed.Top.GetGroup("Town") == null);
		Test.Assert(bed.Project.SourceDb.GetInstance(bell) == null);
		Test.Assert(bed.Project.SourceDb.GetInstance(gongId) == null);
		Test.Assert(bed.Closed.Count == 4);
		Test.Assert(bed.ClosedWhileThere == 4);
		Test.Assert(!bed.Project.Settings.DefaultSceneId.IsSet);
		Test.Assert(bed.LastStatus == "Deleted Town.");
		Test.Assert(!bed.Project.SourceDb.Mount.Exists("Town"), "its folder gone");
		ops.DeleteGroup(bed.Top, new [=b] (next) => { b.ShownNext = null; });
		Test.Assert(bed.Waiting.IsEmpty, "Content is not deleted");
		Test.Assert(bed.ShownNext === bed.Top);

		// An agent's: at once, its page closed, the default scene let go; not there, false.
		bed.Project.Settings.DefaultSceneId = anvil.Id;
		let anvilId = anvil.Id;
		Test.Assert(ops.DeleteOne(anvilId));
		Test.Assert(bed.Waiting.IsEmpty);
		Test.Assert(bed.Project.SourceDb.GetInstance(anvilId) == null);
		Test.Assert((bed.Closed.Count == 5) && (bed.Closed[4] == anvilId) && (bed.ClosedWhileThere == 5));
		Test.Assert(!bed.Project.Settings.DefaultSceneId.IsSet);
		Test.Assert(!ops.DeleteOne(anvilId));
		Test.Assert(bed.Closed.Count == 5);
	}

	/// The export flag on an asset and on a group's contents, said, kept with the project.
	[Test]
	public static void TheExportFlagOnAnAssetAndOnAGroupsContentsKeptWithTheProject()
	{
		let bed = scope Bed("scratch_asset_ops_export");
		let ops = bed.Ops;
		Test.Assert(!ops.IsAlwaysExported(bed.Crate.Id));
		ops.ToggleAlwaysExport(bed.Crate.Id);
		Test.Assert(ops.IsAlwaysExported(bed.Crate.Id));
		Test.Assert(bed.LastSaid == "Crate is always exported.");
		Test.Assert(!ops.IsAlwaysExported(bed.Town));
		ops.ToggleAlwaysExport(bed.Town);
		Test.Assert(ops.IsAlwaysExported(bed.Town));
		Test.Assert(bed.LastSaid == "Everything in Town is always exported.");
		{
			let again = EditorProject.Open(bed.Dir);
			Test.Assert(again != null);
			defer delete again;
			Test.Assert(again.ExportRoots.HasInstance(bed.Crate.Id));
			Test.Assert(again.ExportRoots.HasGroup("Town"));
		}
		ops.ToggleAlwaysExport(bed.Crate.Id);
		Test.Assert(!ops.IsAlwaysExported(bed.Crate.Id));
		Test.Assert(bed.LastSaid == "Crate is exported when reached.");
		ops.ToggleAlwaysExport(bed.Town);
		Test.Assert(!ops.IsAlwaysExported(bed.Town));
		Test.Assert(bed.LastSaid == "Town is exported when reached.");
		{
			let again = EditorProject.Open(bed.Dir);
			Test.Assert(again != null);
			defer delete again;
			Test.Assert(again.ExportRoots.IsEmpty);
		}
	}

	/// While a cook reads the databases every change waits, said, nothing changed; once the cook is
	/// idle each runs, in the order asked. A cook asked for is the cook service's.
	[Test]
	public static void EachChangeWaitsForACookSayingSoThenRuns()
	{
		let bed = scope Bed("scratch_asset_ops_wait", true);
		let ops = bed.Ops;
		let market = bed.Top.CreateGroup("Market");
		let stall = market.CreateInstance("Stall", bed.TypeName);
		Test.Assert(stall != null);
		bed.Locked = true;
		let why = scope String();
		Test.Assert(ops.Rename(bed.Crate.Id, "Box", why) && why.IsEmpty);
		Test.Assert(ops.RenameGroup(bed.Town, "Village", why) && why.IsEmpty);
		Test.Assert(ops.CreateGroup(bed.Top) == null);
		var barrel = bed.Barrel.Id;
		ops.Delete(Span<Guid>(&barrel, 1));
		let b = bed;
		ops.DeleteGroup(market, new [=b] (next) => { b.ShownNext = next; });
		Test.Assert(ops.Duplicate(bed.Crate.Id) == null);
		Test.Assert(bed.Said.Count == 6);
		Test.Assert(bed.Said[0] == "Rename waits for the cook to finish.");
		Test.Assert(bed.Said[1] == "Rename waits for the cook to finish.");
		Test.Assert(bed.Said[2] == "New group waits for the cook to finish.");
		Test.Assert(bed.Said[3] == "Delete waits for the cook to finish.");
		Test.Assert(bed.Said[4] == "Delete waits for the cook to finish.");
		Test.Assert(bed.Said[5] == "Duplicate waits for the cook to finish.");
		// Nothing changed while the cook reads.
		Test.Assert(bed.Crate.Name == "Crate");
		Test.Assert(bed.Town.Name == "Town");
		Test.Assert(bed.Top.GetGroup("Group") == null);
		Test.Assert(bed.Project.SourceDb.GetInstance(bed.Barrel.Id) != null);
		Test.Assert(bed.Top.GetGroup("Market") != null);
		Test.Assert(bed.Top.GetInstance("Crate.2") == null);
		Test.Assert(bed.Closed.IsEmpty);

		bed.Locked = false;
		let barrelId = bed.Barrel.Id;
		let stallId = stall.Id;
		bed.Cook.Update();
		Test.Assert(bed.Crate.Name == "Box");
		Test.Assert(bed.Bell.GetPath(.. scope .()) == "Village/Bell");
		Test.Assert(bed.Top.GetGroup("Group") != null);
		Test.Assert(bed.Project.SourceDb.GetInstance(barrelId) == null);
		Test.Assert(bed.Project.SourceDb.GetInstance(stallId) == null);
		Test.Assert(bed.Top.GetGroup("Market") == null);
		Test.Assert(bed.ShownNext === bed.Top);
		Test.Assert(bed.Top.GetInstance("Box.2") != null, "after the rename asked before it");
		Test.Assert((bed.Closed.Count == 2) && (bed.Closed[0] == barrelId) && (bed.Closed[1] == stallId));
	}

	/// Cook asks the cook service for the assets (a group's, all the way down), nothing when there
	/// are none; Cook All for everything.
	[Test]
	public static void ACookIsTheCookServicesForTheAssetsAGroupHoldsOrAll()
	{
		{
			let bed = scope Bed("scratch_asset_ops_cook", true);
			let ops = bed.Ops;
			// Asked while locked, so no cook starts: what is asked waits, and the service is not idle.
			bed.Locked = true;
			ops.Cook(Span<Guid>(), false);
			let empty = bed.Top.CreateGroup("Empty");
			ops.CookGroup(empty, true);
			bed.Locked = false;
			Test.Assert(bed.Cook.IsIdle, "nothing to cook: nothing asked");
			bed.Locked = true;
			ops.CookGroup(bed.Town, false);
			bed.Locked = false;
			Test.Assert(!bed.Cook.IsIdle, "the group's assets asked for");
		}
		{
			let bed = scope Bed("scratch_asset_ops_cook_all", true);
			bed.Locked = true;
			bed.Ops.CookAll(false);
			bed.Locked = false;
			Test.Assert(!bed.Cook.IsIdle, "everything asked for");
		}
	}
}
