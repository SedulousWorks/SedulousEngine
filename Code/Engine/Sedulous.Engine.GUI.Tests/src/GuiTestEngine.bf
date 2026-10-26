using System;
using Sedulous.Core;
using Sedulous.Engine.GUI;
using Sedulous.Engine.Scene;
using Sedulous.GUI;
using Sedulous.GUI.Resources;
using Sedulous.Runtime;
using Sedulous.Scene;
using Sedulous.VFS;

namespace Sedulous.Engine.GUI.Tests;

/// A context with the scene subsystem and the GUI's, started, the GUI reading its shaders and
/// built-in font through the data root.
class GuiTestEngine
{
	public Context Context = new .() ~ delete _;
	public SceneManager Scenes = new .() ~ delete _;
	public SceneSubsystem SceneSystems;
	/// Declared before the subsystem that borrows it, so it goes after.
	public NativeFileSystem DataMount ~ delete _;
	/// OWNED: RegisterSubsystem borrows, and the subsystem takes a constructor argument, so only
	/// the fixture can free it.
	public GuiSubsystem Gui ~ delete _;

	private SceneModule mGuiModule;

	public this()
	{
		SceneSystems = Context.AddSubsystem<SceneSubsystem>();
		SceneSystems.RegisterManager(Scenes);
		mGuiModule = SceneModule("gui", => GuiScene.AddGuiSceneManagers, null);
		let modules = scope SceneModule*[1](&mGuiModule);
		// TAKES OWNERSHIP of what it is given.
		SceneSystems.SetComposition(SceneComposition.Build(modules));

		let dataRoot = scope String();
		FindDataRoot(dataRoot);
		if (!dataRoot.IsEmpty)
			DataMount = new NativeFileSystem(dataRoot);
		Gui = new GuiSubsystem(DataMount);
		Context.RegisterSubsystem<GuiSubsystem>(Gui);
		Context.Startup();
	}

	public ~this()
	{
		// DISPOSE rather than shut down: unregistering has to happen while the borrowed subsystem
		// is still alive, and the field destructors run after this body.
		Context.Dispose();
	}

	/// A frame as the application runs one: the last one's end, then this one's opening lane,
	/// where the GUI's work runs.
	public void Frame()
	{
		Context.EndFrame();
		Context.BeginFrame(1.0f / 60.0f);
	}

	/// A document with this markup. The CALLER owns what comes back.
	public static GuiDocument MakeDocument(StringView markup)
	{
		let document = new GuiDocument();
		document.Markup.Set(markup);
		return document;
	}

	/// A 100 x 40 button at `at`, with the caller's reference.
	public static Button MakeButton(StringView id, Float2 at)
	{
		let button = new Button();
		button.Id = id;
		button.Position = at;
		button.Size = .(100.0f, 40.0f);
		return button;
	}

	/// A screen's content holding one button, with the caller's reference.
	public static UIWidget MakeMenu(StringView buttonId)
	{
		let menu = new UIWidget();
		let button = MakeButton(buttonId, .(20.0f, 20.0f));
		menu.AddChild(button);
		button.ReleaseRef(); // the menu holds it
		return menu;
	}
}
