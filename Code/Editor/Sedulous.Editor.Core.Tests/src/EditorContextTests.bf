using System;
using System.Collections;
using System.IO;
using System.Threading;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Content;
using Sedulous.VFS;
using Sedulous.Xml.Serialization;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Core.Tests;

/// The context: page dispatch and lifetime, the seams the app wires, interception,
/// selection, notices, the debugger state and the pending asset edits.
static class EditorContextTests
{
	private class Db
	{
		public String Dir = new .() ~ delete _;
		public NativeFileSystem Mount ~ delete _;
		public SerializerFactory Factory ~ delete _;
		public ContentDatabase Database ~ delete _;

		public this(StringView name)
		{
			PathJoin(Directory.GetCurrentDirectory(.. scope .()), name, Dir);
			RemoveDirectoryRecursive(Dir);
			CreateDirectory(Dir);
			Mount = new NativeFileSystem(Dir);
			Factory = XmlSerializerFactory();
			Database = new ContentDatabase(Mount, Factory, "xasset");
		}

		public ~this()
		{
			RemoveDirectoryRecursive(Dir);
		}
	}

	private static void FullName(Type type, String outName) => type.GetFullName(outName);

	[Test]
	public static void TheRegistryDispatchesByNearestType()
	{
		let registry = scope EditorPageRegistry();
		registry.Register(new TestPageFactory(typeof(BaseAsset), "base"));
		// The base factory serves the derived type, along the base chain...
		var found = registry.FindFactory(typeof(DerivedAsset));
		Test.Assert((found != null) && (found.PrimaryType == typeof(BaseAsset)));
		// ...until a MORE SPECIFIC factory wins the distance contest.
		registry.Register(new TestPageFactory(typeof(DerivedAsset), "derived"));
		found = registry.FindFactory(typeof(DerivedAsset));
		Test.Assert((found != null) && (found.PrimaryType == typeof(DerivedAsset)));
		// The base type still dispatches to the base factory.
		found = registry.FindFactory(typeof(BaseAsset));
		Test.Assert((found != null) && (found.PrimaryType == typeof(BaseAsset)));
		// No factory covers an unrelated chain, and a name resolves the same way.
		Test.Assert(registry.FindFactory(typeof(UnrelatedAsset)) == null);
		let byName = registry.FindFactory(FullName(typeof(DerivedAsset), .. scope .()));
		Test.Assert((byName != null) && (byName.PrimaryType == typeof(DerivedAsset)));
	}

	/// A preview factory for one type that shows nothing.
	private class TestPreviewFactory : IImportPreviewFactory
	{
		private Type mType;

		public this(Type type)
		{
			mType = type;
		}

		public Type AssetType => mType;
		public IImportPreview Create(ImportPreviewSource file, ImportPreviewReader reader) => null;
	}

	[Test]
	public static void TheNearestTypesPreviewIsFoundByTheTypeOrItsName()
	{
		let context = scope EditorContext();
		let registry = context.ImportPreviews;
		registry.Register(new TestPreviewFactory(typeof(BaseAsset)));
		// The base's preview serves the derived type until a nearer one is registered.
		Test.Assert(registry.Find(typeof(DerivedAsset)).AssetType == typeof(BaseAsset));
		registry.Register(new TestPreviewFactory(typeof(DerivedAsset)));
		Test.Assert(registry.Find(typeof(DerivedAsset)).AssetType == typeof(DerivedAsset));
		Test.Assert(registry.Find(typeof(BaseAsset)).AssetType == typeof(BaseAsset));
		Test.Assert(registry.Find(typeof(UnrelatedAsset)) == null);
		// By full name, as an importer names the type it lists a file by.
		let byName = registry.FindByName(FullName(typeof(DerivedAsset), .. scope .()));
		Test.Assert((byName != null) && (byName.AssetType == typeof(DerivedAsset)));
		Test.Assert(registry.FindByName("NoSuchAssetType") == null);
		Test.Assert(registry.FindByName("") == null);
		registry.Register(new TestPreviewFactory(null));
		Test.Assert(registry.Count == 2, "one with no type is dropped");
	}

	/// A read runs off the main thread and is handed back only in Pump; one cancelled meanwhile (its
	/// preview gone) is dropped.
	[Test]
	public static void AReadRunsOffTheMainThreadAndIsHandedBackInPumpACancelledOneIsDropped()
	{
		let reader = scope ImportPreviewReader();
		int32 reads = 0;
		int handed = 0;
		let kept = reader.Read(new [&reads] () => { Interlocked.Increment(ref reads); }, new [&handed] () => { handed++; });
		let dropped = reader.Read(new [&reads] () => { Interlocked.Increment(ref reads); }, new [&handed] () => { handed += 10; });
		dropped.Cancel(); // the preview went before its read came back
		Test.Assert(reader.InFlight == 2);
		Test.Assert(handed == 0, "nothing is handed back outside Pump");
		reader.Finish();
		Test.Assert(handed == 1, "only the kept read's result");
		Test.Assert(reader.InFlight == 0);
		Test.Assert(reads >= 1, "the cancelled read may have started before it was cancelled");
		kept.ReleaseRef();
		dropped.ReleaseRef();
	}

	[Test]
	public static void OpenFocusAndClosePages()
	{
		let db = scope Db("scratch_editor_ctx_db");
		let a = db.Database.RootGroup.CreateInstance("a", FullName(typeof(BaseAsset), .. scope .()));
		let b = db.Database.RootGroup.CreateInstance("b", FullName(typeof(DerivedAsset), .. scope .()));
		let c = db.Database.RootGroup.CreateInstance("c", FullName(typeof(UnrelatedAsset), .. scope .()));
		Test.Assert((a != null) && (b != null) && (c != null));

		let context = scope EditorContext();
		int pagesChanged = 0;
		context.OnPagesChanged = new [&pagesChanged]() => { pagesChanged++; };
		context.Pages.Register(new TestPageFactory(typeof(BaseAsset), "base"));

		let pageA = context.OpenPage(a);
		Test.Assert(pageA != null);
		Test.Assert((context.ActivePage == pageA) && (context.OpenPages.Count == 1) && (pagesChanged == 1));
		// The derived instance dispatches through the base factory.
		let pageB = context.OpenPage(b);
		Test.Assert((pageB != null) && (context.ActivePage == pageB) && (context.OpenPages.Count == 2));
		// Re-opening the same instance focuses the existing page.
		Test.Assert(context.OpenPage(a) == pageA);
		Test.Assert((context.ActivePage == pageA) && (context.OpenPages.Count == 2));
		// No factory for the unrelated type.
		Test.Assert(context.OpenPage(c) == null);
		// Closing the active page activates a surviving neighbour.
		context.ClosePage(pageA);
		Test.Assert((context.OpenPages.Count == 1) && (context.ActivePage == pageB));
		context.ClosePage(pageB);
		Test.Assert((context.OpenPages.Count == 0) && (context.ActivePage == null));
	}

	/// RevealPage makes a page active and then asks the application to raise its panel; headless
	/// (no hook) it is SetActivePage; null clears the active page and raises nothing.
	[Test]
	public static void RevealPageActivatesThenRaisesAndNullRaisesNothing()
	{
		let db = scope Db("scratch_editor_ctx_reveal");
		let a = db.Database.RootGroup.CreateInstance("a", FullName(typeof(BaseAsset), .. scope .()));
		let b = db.Database.RootGroup.CreateInstance("b", FullName(typeof(BaseAsset), .. scope .()));
		let context = scope EditorContext();
		context.Pages.Register(new TestPageFactory(typeof(BaseAsset), "base"));
		let one = context.OpenPage(a);
		let two = context.OpenPage(b);
		Test.Assert((one != null) && (two != null) && (context.ActivePage == two));

		// Headless: no hook, RevealPage is SetActivePage.
		context.RevealPage(one);
		Test.Assert(context.ActivePage == one);
		// With the application's hook: the page is active first, then raised; a repeat raises again.
		let shown = scope List<EditorPage>();
		context.OnRevealPage = new [&](page) =>
			{
				Test.Assert(context.ActivePage == page);
				shown.Add(page);
			};
		context.RevealPage(two);
		context.RevealPage(two);
		Test.Assert((shown.Count == 2) && (shown[0] == two));
		context.RevealPage(null);
		Test.Assert(context.ActivePage == null);
		Test.Assert(shown.Count == 2, "nothing to raise");
		context.ClosePage(one);
		context.ClosePage(two);
	}

	[Test]
	public static void NotifyProjectSettingsChangedFiresTheSubscribedHook()
	{
		let context = scope EditorContext();
		int fired = 0;
		context.NotifyProjectSettingsChanged();
		context.OnProjectSettingsChanged = new [&fired]() => { fired++; };
		context.NotifyProjectSettingsChanged();
		context.NotifyProjectSettingsChanged();
		Test.Assert(fired == 2);
	}

	[Test]
	public static void IsCookBusyDefaultsToNotBusyAndReadsTheWiredQuery()
	{
		let context = scope EditorContext();
		Test.Assert(!context.IsCookBusy, "unwired is never busy, so a deferred start never hangs");
		bool busy = true;
		context.CookBusy = new [&busy]() => busy;
		Test.Assert(context.IsCookBusy);
		busy = false;
		Test.Assert(!context.IsCookBusy);
		delete context.CookBusy;
		context.CookBusy = null;
		Test.Assert(!context.IsCookBusy);
	}

	[Test]
	public static void OpenAssetInterceptorsClaimNewestFirstAndUnregisterCleanly()
	{
		let db = scope Db("scratch_editor_ctx_intercept");
		let a = db.Database.RootGroup.CreateInstance("a", FullName(typeof(BaseAsset), .. scope .()));
		let context = scope EditorContext();
		Test.Assert(!context.TryInterceptOpenAsset(a), "no interceptors: not claimed");

		let order = scope List<int>();
		let first = context.AddOpenAssetInterceptor(new [&order](instance) => { order.Add(1); return true; });
		let second = context.AddOpenAssetInterceptor(new [&order](instance) => { order.Add(2); return false; });
		Test.Assert(context.TryInterceptOpenAsset(a));
		Test.Assert((order.Count == 2) && (order[0] == 2) && (order[1] == 1), "newest first, then the fall through");

		// A true answer short circuits.
		order.Clear();
		context.RemoveOpenAssetInterceptor(second);
		let third = context.AddOpenAssetInterceptor(new [&order](instance) => { order.Add(3); return true; });
		Test.Assert(context.TryInterceptOpenAsset(a));
		Test.Assert((order.Count == 1) && (order[0] == 3));

		context.RemoveOpenAssetInterceptor(first);
		context.RemoveOpenAssetInterceptor(third);
		Test.Assert(!context.TryInterceptOpenAsset(a));
	}

	[Test]
	public static void AdoptedInstanceLessPagesShareTheOwnershipFlow()
	{
		let context = scope EditorContext();
		let page = context.AdoptPage(new TestPage("Game"));
		Test.Assert(page != null);
		Test.Assert((context.OpenPages.Count == 1) && (context.ActivePage == page));
		Test.Assert(!page.InstanceId.IsSet);
		context.ClosePage(page);
		Test.Assert((context.OpenPages.Count == 0) && (context.ActivePage == null));
		Test.Assert(context.AdoptPage(null) == null);
		Test.Assert(context.OpenPages.Count == 0);
	}

	[Test]
	public static void APageOwnsItsCommandStackAndTheActivePageIsTheOneEditActsOn()
	{
		let db = scope Db("scratch_editor_ctx_undo");
		let a = db.Database.RootGroup.CreateInstance("a", FullName(typeof(BaseAsset), .. scope .()));
		let context = scope EditorContext();
		Test.Assert(context.ActivePage == null, "no active page: nothing to undo anywhere");
		context.Pages.Register(new TestPageFactory(typeof(BaseAsset), "base"));
		let page = context.OpenPage(a);
		Test.Assert(page != null);

		bool flag = false;
		Test.Assert(page.Commands.Execute(new FlipCommand(&flag)));
		Test.Assert(flag);
		Test.Assert(page.IsDirty, "a command marks the page dirty");
		// Edit > Undo and Redo are the edit.undo and edit.redo actions over the active page's
		// stack (the application declares them); the page owns the stack.
		Test.Assert(context.ActivePage == page);
		Test.Assert(page.Commands.CanUndo);
		page.Commands.Undo();
		Test.Assert(!flag);
		Test.Assert(page.Commands.CanRedo);
		page.Commands.Redo();
		Test.Assert(flag);
		Test.Assert(page.Save() case .Ok);
		Test.Assert(!page.IsDirty);
	}

	[Test]
	public static void SelectionSetsDedupsKeepsAPrimaryAndToggles()
	{
		let selection = scope Selection<int32>();
		int changes = 0;
		selection.OnChanged = new [&changes]() => { changes++; };
		Test.Assert(selection.IsEmpty);
		selection.Set(5);
		Test.Assert((selection.Count == 1) && (selection.Primary == 5) && (changes == 1));
		int32[4] items = .(3, 7, 3, 9);
		selection.Set(items);
		Test.Assert((selection.Count == 3) && (selection.Primary == 3), "the duplicate 3 removed, the first stays primary");
		selection.Toggle(7);
		Test.Assert((selection.Count == 2) && !selection.Contains(7));
		selection.Toggle(7);
		Test.Assert(selection.Contains(7) && (selection.Primary == 3), "added at the back, the primary unchanged");
		selection.Clear();
		Test.Assert(selection.IsEmpty);
		let after = changes;
		selection.Clear();
		Test.Assert(changes == after, "clearing an empty selection does not notify");
	}

	/// The GUI's clipboard, in memory.
	private class TestClipboard : Sedulous.GUI.IClipboard
	{
		public String Stored = new .() ~ delete _;

		public bool HasText => !Stored.IsEmpty;
		public void GetText(String outText) { outText.Append(Stored); }
		public void SetText(StringView text) { Stored.Set(text); }
	}

	/// A copy the user asks for says so; with no clipboard to reach (a headless view) it warns.
	[Test]
	public static void ACopyAnnouncesItselfAndWarnsWithoutAClipboard()
	{
		let context = scope EditorContext();
		let notices = scope List<String>();
		defer { ClearAndDeleteItems!(notices); }
		context.OnNotice = new [&](kind, message) => { notices.Add(new $"{kind}: {message}"); };
		let clipboard = scope TestClipboard();

		Test.Assert(context.CopyText(clipboard, "1234", "GUID"));
		Test.Assert((clipboard.Stored == "1234") && (notices.Back == "Success: Copied GUID"));
		Test.Assert(!context.CopyText(null, "x", "path"));
		Test.Assert(notices.Back == "Warning: Could not copy path to the clipboard");
		Test.Assert(clipboard.Stored == "1234");
	}

	[Test]
	public static void NotifyRoutesToOnNoticeAndFallsBackToTheStatusBar()
	{
		let context = scope EditorContext();
		let statuses = scope List<String>();
		defer { ClearAndDeleteItems(statuses); }
		context.OnStatus = new [&statuses](text) => { statuses.Add(new String(text)); };
		context.Notify(.Info, "hello");
		Test.Assert((statuses.Count == 1) && (statuses[0] == "hello"), "unwired OnNotice falls back to status");

		NoticeKind gotKind = .Info;
		let gotMessage = scope String();
		context.OnNotice = new [&gotKind, &gotMessage](kind, message) => { gotKind = kind; gotMessage.Set(message); };
		context.Notify(.Error, "cook failed");
		Test.Assert((gotKind == .Error) && (gotMessage == "cook failed"));
		Test.Assert(statuses.Count == 1, "a wired notice does not double post the status");
	}

	[Test]
	public static void TheScriptExecutionPointSetsClearsAndStampsVersions()
	{
		let context = scope EditorContext();
		Test.Assert(!context.ScriptExecution.Active);
		let v0 = context.ScriptExecutionVersion;
		context.SetScriptExecutionPoint("game.script", 12);
		Test.Assert(context.ScriptExecution.Active && (context.ScriptExecution.File == "game.script") && (context.ScriptExecution.Line == 12));
		Test.Assert(context.ScriptExecutionVersion != v0);
		let v1 = context.ScriptExecutionVersion;
		context.SetScriptExecutionPoint("game.script", 13);
		Test.Assert(context.ScriptExecutionVersion != v1);
		let v2 = context.ScriptExecutionVersion;
		context.ClearScriptExecutionPoint();
		Test.Assert(!context.ScriptExecution.Active && (context.ScriptExecutionVersion != v2));
		let v3 = context.ScriptExecutionVersion;
		context.ClearScriptExecutionPoint();
		Test.Assert(context.ScriptExecutionVersion == v3, "clearing while clear is version quiet");
	}

	[Test]
	public static void TheScriptValueProbeSlot()
	{
		let context = scope EditorContext();
		Test.Assert(context.ScriptValueProbe == null, "absent by default");
		context.ScriptValueProbe = new (identifier, outText) => { if (identifier == "speed") outText.Set("4.5 : float"); };
		let text = scope String();
		context.ScriptValueProbe("speed", text);
		Test.Assert(text == "4.5 : float");
		text.Clear();
		context.ScriptValueProbe("unknown", text);
		Test.Assert(text.IsEmpty);
		delete context.ScriptValueProbe;
		context.ScriptValueProbe = null;
	}

	[Test]
	public static void ThePendingAssetEditRegistryReplacesIgnoresNilDrainsAndRecooks()
	{
		let db = scope Db("scratch_editor_ctx_assetedit");
		let context = scope EditorContext();
		bool cooked = false;
		context.OnCookRequested = new [&cooked](rebuild) => { cooked = true; };
		let a = Guid.Parse("00000000-0000-0000-0000-000000000001").Get();
		let b = Guid.Parse("00000000-0000-0000-0000-000000000002").Get();
		int runsA = 0;
		int runsB = 0;
		Test.Assert(!context.HasPendingAssetEdits);
		context.RegisterAssetEdit(a, new [&runsA](database) => { runsA++; return Result<void, ErrorCode>.Ok; });
		context.RegisterAssetEdit(a, new [&runsA](database) => { runsA++; return Result<void, ErrorCode>.Ok; });
		context.RegisterAssetEdit(b, new [&runsB](database) => { runsB++; return Result<void, ErrorCode>.Ok; });
		context.RegisterAssetEdit(.Empty, new (database) => { return Result<void, ErrorCode>.Ok; });
		Test.Assert(context.HasPendingAssetEdits);
		Test.Assert(context.DrainAssetEdits(db.Database) case .Ok);
		Test.Assert((runsA == 1) && (runsB == 1), "the same guid replaced, so ran once");
		Test.Assert(cooked, "a successful drain requests a recook");
		Test.Assert(!context.HasPendingAssetEdits);
		cooked = false;
		Test.Assert(context.DrainAssetEdits(db.Database) case .Ok);
		Test.Assert(!cooked, "an empty drain is a no-op");
	}

	[Test]
	public static void McpToolContributionsRegisterAtBootAndApplyToAHostsServerInOrder()
	{
		let context = scope EditorContext();
		Test.Assert(context.McpToolContributionCount == 0);
		let order = scope List<String>();
		defer ClearAndDeleteItems(order);
		context.RegisterMcpToolContribution(new [&order](server) =>
			{
				order.Add(new .("scene"));
				server.RegisterTool("selection_get", "x", scope Sedulous.Mcp.SchemaBuilder().Build(), .ReadOnly,
					new (arguments, outResult, outError) => true);
			});
		context.RegisterMcpToolContribution(new [&order](server) => { order.Add(new .("other")); });
		Test.Assert(context.McpToolContributionCount == 2);

		let server = scope Sedulous.Mcp.McpServer();
		context.ApplyMcpToolContributions(server);
		Test.Assert(server.ToolCount == 1);
		Test.Assert(order.Count == 2);
		Test.Assert(order[0] == "scene");
		Test.Assert(order[1] == "other");
		// Applying to a second host serves the same contributions again (one per project open).
		let another = scope Sedulous.Mcp.McpServer();
		context.ApplyMcpToolContributions(another);
		Test.Assert(another.ToolCount == 1);
	}

	class WatchingPage : EditorPage
	{
		public int Told = 0;

		public this(Guid asset)
		{
			InstanceId = asset;
		}

		public override StringView Title => "watching";
		public override Result<void, ErrorCode> Save() => .Ok;
		public override void OnAssetExternallyModified() { Told++; }
	}

	[Test]
	public static void AnAssetChangedOutsideItsPageTellsEveryOpenPageEditingItAndNoOther()
	{
		var rng = Sedulous.Core.Random(11);
		let edited = Guid.Generate(ref rng);
		let other = Guid.Generate(ref rng);
		let context = scope EditorContext();
		let first = new WatchingPage(edited);
		let second = new WatchingPage(edited);
		let elsewhere = new WatchingPage(other);
		context.AdoptPage(first);
		context.AdoptPage(second);
		context.AdoptPage(elsewhere);

		Test.Assert(context.NotifyAssetExternallyModified(edited) == 2);
		Test.Assert(first.Told == 1);
		Test.Assert(second.Told == 1);
		Test.Assert(elsewhere.Told == 0);
		// An asset no page edits: nothing told, nothing wrong.
		Test.Assert(context.NotifyAssetExternallyModified(Guid.Generate(ref rng)) == 0);
	}
}
