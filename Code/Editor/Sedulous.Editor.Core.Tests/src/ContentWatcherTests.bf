using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.VFS;
using Sedulous.Pipeline.Core;
using Sedulous.Engine.Project;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.Core.Tests;

/// The Content/ watcher: a file written outside the editor taken in only once it has settled, a
/// burst one refresh with each record told once, settled paths held back only so long by one that
/// keeps changing, the editor's own writes never reported, a deleted record reported with where it
/// lived, an unreadable envelope tried again until it reads; the cook service polling it, held off
/// while a reader has the databases and at once when the window comes back; and an open page of a
/// deleted asset kept, told, and written back by its save.
static class ContentWatcherTests
{
	/// A project, and an outside writer over its Content/: a database of its own on a mount of its
	/// own, whose writes the project never hears of.
	class Bed
	{
		public String Dir = new .() ~ delete _;
		public EditorProject Project;
		public NativeFileSystem OutsideMount;
		public ContentDatabase Outside;
		public String TypeName = new .() ~ delete _;

		public this(StringView name)
		{
			TestSerializables.RegisterAll();
			PathJoin(Directory.GetCurrentDirectory(.. scope .()), name, Dir);
			RemoveDirectoryRecursive(Dir);
			Test.Assert(EditorProject.Create(Dir, "Watched") case .Ok);
			Project = EditorProject.Open(Dir);
			Test.Assert(Project != null);
			OutsideMount = new NativeFileSystem(PathJoin(Dir, ProjectLayout.ContentDir, .. scope .()));
			Outside = new ContentDatabase(OutsideMount, Project.SourceDb.Serializers, ProjectLayout.SourceAssetExtension);
			typeof(TestMaterial).GetFullName(TypeName);
		}

		public ~this()
		{
			delete Outside;
			delete OutsideMount;
			delete Project;
			RemoveDirectoryRecursive(Dir);
		}

		/// Writes "group/name" from outside, a record of its own or one it wrote before; the
		/// shininess decides the envelope's size, so each write can be told from the last.
		public Guid WriteOutside(StringView group, StringView name, int32 shininess)
		{
			let instance = Outside.RootGroup.CreateGroup(group).CreateInstance(name, TypeName);
			let material = scope TestMaterial();
			material.Shininess = shininess;
			Test.Assert(instance.WriteObject(material) case .Ok);
			return instance.Id;
		}

		/// A file under Content/, by its mount relative path.
		public void ContentPath(StringView relative, String outPath)
		{
			PathJoin(PathJoin(Dir, ProjectLayout.ContentDir, .. scope .()), relative, outPath);
		}

		/// Deletes a file under Content/ from outside.
		public void DeleteOutside(StringView relative)
		{
			Test.Assert(System.IO.File.Delete(ContentPath(relative, .. scope .())) case .Ok);
		}
	}

	class CountingPage : EditorPage
	{
		public int Modified = 0;
		public int Deleted = 0;

		public this(Guid asset)
		{
			InstanceId = asset;
		}

		public override StringView Title => "counting";
		public override Result<void, ErrorCode> Save() => .Ok;
		public override void OnAssetExternallyModified() { Modified++; }
		public override void OnAssetDeleted() { Deleted++; }
	}

	/// Saves its asset as a page does: into the record the source database has by its id.
	class SavingPage : CountingPage
	{
		private EditorContext mContext;

		public this(EditorContext context, Guid asset) : base(asset)
		{
			mContext = context;
		}

		public override Result<void, ErrorCode> Save()
		{
			let instance = mContext.Project.SourceDb.GetInstance(InstanceId);
			if (instance == null)
				return .Err(.NotFound);
			let material = scope TestMaterial();
			material.Shininess = 8;
			if (instance.WriteObject(material) case .Err(let error))
				return .Err(error);
			ClearDirty();
			return .Ok;
		}
	}

	/// Two looks that find nothing to do and nothing waiting.
	private static void AssertQuiet(ContentWatcher watcher, ContentChanges changes, StringView why)
	{
		let message = scope String(why);
		Test.Assert(!watcher.Poll(changes) && changes.IsEmpty, message);
		Test.Assert(!watcher.Poll(changes) && changes.IsEmpty, message);
		Test.Assert(watcher.PendingCount == 0, message);
	}

	[Test]
	public static void AFileWrittenOutsideIsTakenInOnlyOnceItHasSettled()
	{
		let bed = scope Bed("scratch_content_watch_settle");
		let watcher = scope ContentWatcher(bed.Project);
		let changes = scope ContentChanges();
		AssertQuiet(watcher, changes, "nothing changed since it took Content/ in");

		let id = bed.WriteOutside("mats", "steel", 7);
		Test.Assert(!watcher.Poll(changes), "seen once: it may still be being written");
		Test.Assert(watcher.PendingCount == 1);
		Test.Assert(bed.Project.SourceDb.GetInstance(id) == null, "not read yet");
		// Written again before it settled: it waits again.
		bed.WriteOutside("mats", "steel", 123456);
		Test.Assert(!watcher.Poll(changes));
		Test.Assert(bed.Project.SourceDb.GetInstance(id) == null);
		Test.Assert(watcher.Poll(changes), "the same on two looks: settled");
		Test.Assert((changes.Added.Count == 1) && (changes.Added[0] == id));
		Test.Assert(changes.Changed.IsEmpty && changes.Removed.IsEmpty);
		let instance = bed.Project.SourceDb.GetInstanceByPath("mats/steel");
		Test.Assert((instance != null) && (instance.Id == id));
		AssertQuiet(watcher, changes, "taken in: told once");
	}

	[Test]
	public static void ABurstOverSeveralPollsIsOneRefreshAndEachRecordIsToldOnce()
	{
		let bed = scope Bed("scratch_content_watch_burst");
		let watcher = scope ContentWatcher(bed.Project);
		let changes = scope ContentChanges();
		let context = scope EditorContext();

		let a = bed.WriteOutside("burst", "a", 1);
		let b = bed.WriteOutside("burst", "b", 2);
		Test.Assert(!watcher.Poll(changes));
		// More of a, its envelope again and a data stream, while b has settled.
		let words = "pulled";
		Test.Assert(bed.Outside.GetInstance(a).WriteData("scene", .((uint8*)words.Ptr, words.Length), .Text) case .Ok);
		bed.WriteOutside("burst", "a", 22222);
		Test.Assert(!watcher.Poll(changes), "b settled, held for a, still changing");
		Test.Assert(bed.Project.SourceDb.GetInstance(b) == null);
		Test.Assert(watcher.Poll(changes), "everything settled: one refresh");
		Test.Assert(changes.Added.Count == 2);
		Test.Assert(changes.Added.Contains(a) && changes.Added.Contains(b));
		Test.Assert(changes.Changed.IsEmpty, "a's two files are one record, told once");

		let pageA = new CountingPage(a);
		let pageB = new CountingPage(b);
		context.AdoptPage(pageA);
		context.AdoptPage(pageB);
		context.ApplyContentChanges(changes, watcher.RemovedRecords);
		Test.Assert((pageA.Modified == 1) && (pageB.Modified == 1));
		AssertQuiet(watcher, changes, "nothing more");

		// A data stream alone: its record changed.
		let more = "pulled again";
		Test.Assert(bed.Outside.GetInstance(a).WriteData("scene", .((uint8*)more.Ptr, more.Length), .Text) case .Ok);
		Test.Assert(!watcher.Poll(changes));
		Test.Assert(watcher.Poll(changes));
		Test.Assert((changes.Changed.Count == 1) && (changes.Changed[0] == a) && changes.Added.IsEmpty);
		context.ApplyContentChanges(changes, watcher.RemovedRecords);
		Test.Assert((pageA.Modified == 2) && (pageB.Modified == 1));
	}

	[Test]
	public static void AFileThatKeepsChangingHoldsTheSettledBackOnlySoLong()
	{
		let bed = scope Bed("scratch_content_watch_hold");
		let watcher = scope ContentWatcher(bed.Project);
		let changes = scope ContentChanges();

		let busy = bed.WriteOutside("hold", "busy", 1);
		let quiet = bed.WriteOutside("hold", "quiet", 2);
		Test.Assert(!watcher.Poll(changes));
		// Each poll finds busy grown again (a digit more each time), quiet as it was.
		int32 shininess = 10;
		for (int i < ContentWatcher.cMaxHoldPolls)
		{
			bed.WriteOutside("hold", "busy", shininess);
			shininess *= 10;
			Test.Assert(!watcher.Poll(changes), "quiet held while busy changes");
		}
		bed.WriteOutside("hold", "busy", shininess);
		Test.Assert(watcher.Poll(changes), "held long enough: quiet goes");
		Test.Assert((changes.Added.Count == 1) && (changes.Added[0] == quiet));
		Test.Assert(bed.Project.SourceDb.GetInstance(busy) == null, "busy still changing");
		Test.Assert(watcher.PendingCount == 1);
		Test.Assert(watcher.Poll(changes), "busy stopped: settled");
		Test.Assert((changes.Added.Count == 1) && (changes.Added[0] == busy));
	}

	[Test]
	public static void TheEditorsOwnWritesAreNeverReported()
	{
		let bed = scope Bed("scratch_content_watch_own");
		let watcher = scope ContentWatcher(bed.Project);
		let changes = scope ContentChanges();
		let db = bed.Project.SourceDb;

		let material = scope TestMaterial();
		let mine = db.RootGroup.CreateGroup("mine").CreateInstance("brass", bed.TypeName);
		let id = mine.Id;
		Test.Assert(mine.WriteObject(material) case .Ok);
		let words = "notes";
		Test.Assert(mine.WriteData("notes", .((uint8*)words.Ptr, words.Length), .Text) case .Ok);
		AssertQuiet(watcher, changes, "written");
		material.Shininess = 4096;
		Test.Assert(mine.WriteObject(material) case .Ok);
		Test.Assert(mine.DeleteData("notes") case .Ok);
		AssertQuiet(watcher, changes, "written again, a stream deleted");
		Test.Assert(db.RenameInstance(id, "bronze") case .Ok);
		AssertQuiet(watcher, changes, "renamed");
		Test.Assert(db.MoveInstance(id, db.RootGroup.CreateGroup("moved")) case .Ok);
		AssertQuiet(watcher, changes, "moved to a new folder");
		Test.Assert(db.RenameGroup(db.RootGroup.GetGroup("moved"), "renamed") case .Ok);
		AssertQuiet(watcher, changes, "its group renamed");
		Test.Assert(db.GetInstanceByPath("renamed/bronze").Id == id);

		// An outside write beside one of the editor's: only the outside one is told.
		let outside = bed.WriteOutside("theirs", "tin", 3);
		material.Shininess = 77;
		Test.Assert(db.GetInstance(id).WriteObject(material) case .Ok);
		Test.Assert(!watcher.Poll(changes));
		Test.Assert(watcher.Poll(changes));
		Test.Assert((changes.Added.Count == 1) && (changes.Added[0] == outside) && changes.Changed.IsEmpty);

		Test.Assert(db.DeleteInstance(id) case .Ok);
		AssertQuiet(watcher, changes, "deleted");
	}

	[Test]
	public static void ARecordDeletedOutsideIsReportedRemovedWithWhereItLived()
	{
		let bed = scope Bed("scratch_content_watch_delete");
		let watcher = scope ContentWatcher(bed.Project);
		let changes = scope ContentChanges();
		let db = bed.Project.SourceDb;
		let id = bed.WriteOutside("mats", "steel", 7);
		Test.Assert(!watcher.Poll(changes));
		Test.Assert(watcher.Poll(changes) && (changes.Added.Count == 1));

		bed.DeleteOutside("mats/steel.xasset");
		Test.Assert(!watcher.Poll(changes));
		Test.Assert(db.GetInstance(id) != null, "not yet: it may be a rewrite under way");
		Test.Assert(watcher.Poll(changes));
		Test.Assert((changes.Removed.Count == 1) && (changes.Removed[0] == id));
		Test.Assert(changes.Added.IsEmpty && changes.Changed.IsEmpty);
		Test.Assert(watcher.RemovedRecords.Length == 1);
		let place = watcher.RemovedRecords[0];
		Test.Assert((place.Id == id) && (place.Former != null));
		Test.Assert(place.Path == "mats/steel");
		Test.Assert(place.TypeName == bed.TypeName);
		Test.Assert((db.GetInstance(id) == null) && (db.GetInstanceByPath("mats/steel") == null));
		AssertQuiet(watcher, changes, "told once");
		Test.Assert(watcher.RemovedRecords.IsEmpty, "the last poll's only");
	}

	[Test]
	public static void AnUnreadableEnvelopeIsTriedAgainUntilItReads()
	{
		let bed = scope Bed("scratch_content_watch_unreadable");
		let watcher = scope ContentWatcher(bed.Project);
		let changes = scope ContentChanges();
		let db = bed.Project.SourceDb;
		let id = bed.WriteOutside("mats", "steel", 7);
		Test.Assert(!watcher.Poll(changes));
		Test.Assert(watcher.Poll(changes));

		// Cut off inside its header, as a file still being written is.
		let whole = scope String();
		Test.Assert(System.IO.File.ReadAllText(bed.ContentPath("mats/steel.xasset", .. scope .()), whole) case .Ok);
		let typeAt = whole.IndexOf("typeName");
		Test.Assert(typeAt > 0, whole);
		Test.Assert(bed.OutsideMount.Save("mats/steel.xasset", .((uint8*)whole.Ptr, typeAt)) case .Ok);
		Test.Assert(!watcher.Poll(changes));
		Test.Assert(!watcher.Poll(changes), "settled, but it does not read: nothing told");
		Test.Assert(changes.Unreadable.Count == 1);
		Test.Assert(watcher.PendingCount == 1, "kept to try again");
		Test.Assert(db.GetInstance(id) != null, "the record kept as it was");
		Test.Assert(!watcher.Poll(changes));
		Test.Assert(changes.Unreadable.Count == 1, "tried again");

		// Written whole again: read once it settles.
		bed.WriteOutside("mats", "steel", 123456);
		Test.Assert(!watcher.Poll(changes));
		Test.Assert(watcher.Poll(changes));
		Test.Assert((changes.Changed.Count == 1) && (changes.Changed[0] == id) && changes.Unreadable.IsEmpty);
		AssertQuiet(watcher, changes, "read");
	}

	[Test]
	public static void TheCookServiceLooksAtContentHeldOffWhileARunnerReadsAndAtOnceOnFocus()
	{
		let bed = scope Bed("scratch_content_watch_cook");
		let builders = scope BuilderRegistry();
		let cook = scope EditorCookService();
		cook.Initialize(bed.Project, builders);
		int heard = 0;
		Guid added = .Empty;
		cook.OnContentChanged = new [&heard, &added] (changes, removed) =>
			{
				heard++;
				if (changes.Added.Count == 1)
					added = changes.Added[0];
			};
		bool busy = true;
		cook.ExternalMutationLock = new [&busy]() => busy;

		let id = bed.WriteOutside("mats", "steel", 7);
		Test.Assert(!cook.PollContent() && !cook.PollContent(), "held off while a reader has the databases");
		Test.Assert(bed.Project.SourceDb.GetInstance(id) == null);
		busy = false;
		// The window coming back has the next Update look, whatever its clock says.
		cook.PollContentSoon();
		cook.Update();
		Test.Assert(heard == 0, "seen once");
		cook.PollContentSoon();
		cook.Update();
		Test.Assert((heard == 1) && (added == id));
		Test.Assert(bed.Project.SourceDb.GetInstance(id) != null);
		cook.Shutdown();
	}

	[Test]
	public static void APageOfAnAssetDeletedOutsideStaysToldAndItsSaveWritesItBack()
	{
		let bed = scope Bed("scratch_content_watch_page");
		let db = bed.Project.SourceDb;
		let record = db.RootGroup.CreateGroup("mats").CreateInstance("steel", bed.TypeName);
		let material = scope TestMaterial();
		material.Shininess = 7;
		Test.Assert(record.WriteObject(material) case .Ok);
		let id = record.Id;
		let full = bed.ContentPath("mats/steel.xasset", .. scope .());

		let watcher = scope ContentWatcher(bed.Project);
		let changes = scope ContentChanges();
		let context = scope EditorContext();
		context.SetProject(bed.Project);
		let said = scope String();
		context.OnNotice = new [&said](kind, message) => { said.Set(message); };
		let page = new SavingPage(context, id);
		context.AdoptPage(page);
		var rng = Sedulous.Core.Random(5);
		let other = new CountingPage(Guid.Generate(ref rng));
		context.AdoptPage(other);
		context.AssetSelection.Set(record);

		bed.DeleteOutside("mats/steel.xasset");
		Test.Assert(!watcher.Poll(changes));
		Test.Assert(watcher.Poll(changes));
		context.ApplyContentChanges(changes, watcher.RemovedRecords);
		Test.Assert((page.Deleted == 1) && (other.Deleted == 0));
		Test.Assert(context.OpenPages.Contains(page), "kept open, never closed under the user");
		Test.Assert(page.IsAssetDeleted && page.IsDirty, "its content unsaved now");
		Test.Assert(page.DeletedRecordPath == "mats/steel");
		Test.Assert(page.DeletedTypeName == bed.TypeName);
		Test.Assert(context.AssetSelection.IsEmpty, "the selection let the record go");
		Test.Assert(said.Contains("deleted on disk"), said);

		// Its own save finds no record; the context's puts it back first.
		Test.Assert(page.Save() case .Err(.NotFound));
		Test.Assert(context.SavePage(page) case .Ok);
		Test.Assert(!page.IsAssetDeleted && !page.IsDirty);
		let back = db.GetInstance(id);
		Test.Assert((back != null) && (back.TypeName == bed.TypeName));
		Test.Assert(back.GetPath(.. scope .()) == "mats/steel");
		Test.Assert(FileExists(full));
		AssertQuiet(watcher, changes, "the save is the editor's own write");

		// Gone again, and another asset in its place: the save refuses, the content kept.
		bed.DeleteOutside("mats/steel.xasset");
		Test.Assert(!watcher.Poll(changes));
		Test.Assert(watcher.Poll(changes));
		context.ApplyContentChanges(changes, watcher.RemovedRecords);
		Test.Assert(page.IsAssetDeleted && (page.Deleted == 2));
		let usurper = bed.WriteOutside("mats", "steel", 99);
		Test.Assert(usurper != id, "the outside writer never knew the editor's record");
		Test.Assert(!watcher.Poll(changes));
		Test.Assert(watcher.Poll(changes) && (changes.Added.Count == 1) && (changes.Added[0] == usurper));
		context.ApplyContentChanges(changes, watcher.RemovedRecords);
		Test.Assert(page.IsAssetDeleted, "another asset came, not this one");
		Test.Assert(context.SavePage(page) case .Err(.AlreadyExists));
		Test.Assert(said.Contains("another asset"), said);
		Test.Assert(page.IsAssetDeleted && page.IsDirty);
		Test.Assert(db.GetInstance(usurper) != null, "the other asset untouched");
	}
}
