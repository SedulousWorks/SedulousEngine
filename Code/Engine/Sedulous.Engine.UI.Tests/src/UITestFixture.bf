using System;
using Sedulous.Engine.Input;
using Sedulous.Engine.Scene;
using Sedulous.Engine.UI;
using Sedulous.Runtime;
using Sedulous.Scene;
using Sedulous.UI.Resource;
using Sedulous.VFS;

namespace Sedulous.Engine.UI.Tests;

/// A context with the scene and UI subsystems up, and one scene group registered on it.
///
/// Headless throughout: there is no device, so nothing here draws. What these cases measure
/// is the TREE and the ROUTING, which is exactly what a null device can answer and what the
/// on screen smoke tests cannot isolate.
class UITestFixture
{
	public Context Context = new .() ~ delete _;
	public SceneManager Scenes = new .() ~ delete _;
	public SceneSubsystem SceneSystems;
	/// The data root, when a case asked for the UI's shaders. Declared before the subsystem
	/// that borrows it, so it goes after.
	public NativeFileSystem DataMount ~ delete _;
	/// OWNED: RegisterSubsystem borrows, so the fixture frees it.
	public UISubsystem UI ~ delete _;

	/// Null unless the case asked for input. The CONTEXT never owns this one, since the
	/// subsystem takes a constructor argument and only a default constructible one can be
	/// added by type, so the fixture frees it.
	public InputSubsystem Input ~ delete _;

	private SceneModule mUIModule;

	public this(bool withInput = false, bool withShaders = false)
	{
		SceneSystems = Context.AddSubsystem<SceneSubsystem>();
		SceneSystems.RegisterManager(Scenes);

		mUIModule = SceneModule("ui", => UIScene.AddUISceneManagers, null);
		let modules = scope SceneModule*[1](&mUIModule);
		// TAKES OWNERSHIP of what it is given.
		SceneSystems.SetComposition(SceneComposition.Build(modules));

		if (withInput)
		{
			Input = new InputSubsystem(null);
			Context.RegisterSubsystem(Input);
		}

		// No data mount unless asked: the fixture drives the subsystem's logic, not its
		// shaders or its built in font, and both degrade rather than fail without one.
		if (withShaders)
		{
			let dataRoot = scope String();
			FindDataRoot(dataRoot);
			if (!dataRoot.IsEmpty)
				DataMount = new NativeFileSystem(dataRoot);
		}
		UI = new UISubsystem(DataMount);
		Context.RegisterSubsystem<UISubsystem>(UI);
		Context.Startup();
	}

	public ~this()
	{
		// DISPOSE rather than shut down: unregistering has to happen while the borrowed
		// input subsystem is still alive, and the field destructors run after this body.
		Context.Dispose();
	}

	/// One frame of the opening lane, which is where the UI's work runs.
	public void Frame(float deltaTime = 1.0f / 60.0f) => Context.BeginFrame(deltaTime);

	/// A document with this markup. The CALLER owns what comes back.
	public static UIDocument MakeDocument(StringView markup)
	{
		let document = new UIDocument();
		document.Markup.Set(markup);
		return document;
	}
}
