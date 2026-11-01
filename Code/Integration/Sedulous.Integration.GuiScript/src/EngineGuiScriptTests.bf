using System;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Engine.GUI;
using Sedulous.GUI.Resources;
using Sedulous.Resource;
using Sedulous.Script;
using Sedulous.Script.AngelScript;
using Sedulous.VFS;
using Sedulous.GUI.Gamekit.ScriptSurface;

namespace Sedulous.Integration.GuiScript;

/// A project holding one cooked document (a pausing screen with a Label "status"), and the
/// engine's GUI over it, headless: a context with the GUI's subsystem alone, as Raptor's bed has.
class CookedMenuBed
{
	private const String cFolder = "scratch_engine_gui_script";

	private SerializableRegistry mSerializables;
	private SerializerFactory mSerializers;
	private NativeFileSystem mMount;
	private ContentDatabase mDatabase;
	private GuiDocumentFactory mDocuments;
	private ResourceManager mResources;
	private NativeFileSystem mDataMount;
	private Sedulous.Runtime.SubsystemManager mContext;

	public GuiSubsystem Gui;
	/// The cooked document's guid.
	public Guid Menu;

	public this()
	{
		RemoveDirectoryRecursive(cFolder);
		CreateDirectory(cFolder);
		mSerializables = new SerializableRegistry();
		GuiResources.RegisterAll(mSerializables);
		mMount = new NativeFileSystem(cFolder);
		mSerializers = new (stream, mode) => new BinarySerializerContext(stream, mode);
		mDatabase = new ContentDatabase(mMount, mSerializers, "asset", mSerializables);
		mDocuments = new GuiDocumentFactory();
		mResources = new ResourceManager(mDatabase);
		mResources.AddFactory(mDocuments);
		let instance = mDatabase.RootGroup.CreateInstance("menu", "Sedulous.GUI.Resources.GuiDocumentSource");
		let source = scope GuiDocumentSource();
		source.Markup.Set("<Screen pauses=\"true\"><Label id=\"status\" text=\"Ready\"/></Screen>");
		Test.Assert(instance.WriteObject(source) case .Ok);
		Menu = instance.Id;

		// The GUI reads its shaders and built-in font through the data root.
		let dataRoot = FindDataRoot(.. scope String());
		if (!dataRoot.IsEmpty)
			mDataMount = new NativeFileSystem(dataRoot);
		mContext = new Sedulous.Runtime.SubsystemManager();
		Gui = new GuiSubsystem(mDataMount);
		mContext.RegisterSubsystem<GuiSubsystem>(Gui);
		mContext.Startup();
		Gui.SetResourceManager(mResources);
	}

	public ~this()
	{
		// The GUI lets go of the project first; the context unregisters the subsystem while it is
		// alive (DISPOSE, not shut down); then what the project read through, the mount last.
		Gui.SetResourceManager(null);
		mContext.Dispose();
		delete Gui;
		delete mContext;
		delete mDataMount;
		delete mResources;
		delete mDocuments;
		delete mDatabase;
		delete mSerializers;
		delete mMount;
		delete mSerializables;
		RemoveDirectoryRecursive(cFolder);
	}

	/// The document's guid as a script names it, "{guid}".
	public void Braced(String outText)
	{
		outText.Append('{');
		Menu.ToString(outText);
		outText.Append('}');
	}
}

/// The engine's GUI from a script (E8 of Raptor's gui-lab-evolution-3.md), Raptor's
/// EngineGuiScriptTests in its AngelScript half: through the subsystem's facade, `Gui.Root()` is the
/// screen tier's root, its `screens` the gamekit's stack, which pushes a cooked document by its
/// asset guid through the engine's resource provider. That a run's `Gui.Root()` finds the screens
/// is Sedulous.Engine.GUI.Tests' (GuiScriptTests); this is the push.
static class EngineGuiScriptTests
{
	private const String cScript = """
		ScreenStack@ stack;
		Screen@ menu;
		void main() { @stack = ScreenStack::Of(Gui.Root().Find("screens")); }
		bool isScreenRoot() { return stack !is null; }
		bool pushMenu() { @menu = stack.Push("{MENU}"); return menu !is null; }
		bool hasStatus() { return menu.Find("status") !is null; }
		""";

	private static bool Run(AngelScriptRuntime vm, StringView decl)
	{
		var r = ScriptValue.Nil;
		let ok = vm.Call("menu", decl, default, ref r);
		for (let p in vm.Problems)
			Console.WriteLine("  {}", p);
		Test.Assert(ok, scope $"{decl} ran");
		return r.AsBool;
	}

	[Test]
	public static void AScriptFindsTheScreenTierAtGuiRootAndPushesACookedDocumentByItsGuid()
	{
		// DECLARED FIRST so it goes LAST: the runtime borrows its facade.
		let bed = scope CookedMenuBed();
		// What the runtime is bound to: it points into the surface, so the surface outlives it.
		let surface = scope Sedulous.Script.ScriptSurface();
		GamekitScriptSurface.Populate(surface);
		let vm = scope AngelScriptRuntime();
		vm.Bind(surface);
		bed.Gui.ExposeToScript(vm);
		// The script's source with the document's guid where it says {MENU}.
		let source = scope String(cScript);
		source.Replace("{MENU}", bed.Braced(.. scope String()));
		let ok = vm.Compile("menu", "menu.as", source);
		for (let p in vm.Problems)
			Console.WriteLine("  {}", p);
		Test.Assert(ok && vm.Problems.IsEmpty, "compiled, with nothing to say");

		Run(vm, "void main()");
		Test.Assert(Run(vm, "bool isScreenRoot()"), "Gui.Root() is the screen tier's");
		Test.Assert(Run(vm, "bool pushMenu()"), "the document, by its guid");
		Test.Assert(bed.Gui.Screens.Count == 1);
		Test.Assert(bed.Gui.Screens.IsPaused);
		Test.Assert(Run(vm, "bool hasStatus()"), "its label found on the pushed screen");
		Test.Assert(vm.Problems.IsEmpty);
		vm.DiscardModule("menu");
	}
}
