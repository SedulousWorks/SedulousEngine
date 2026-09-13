using System;
using Sedulous.Engine.Scene;
using Sedulous.Engine.UI;
using Sedulous.Runtime;
using Sedulous.Scene;
using Sedulous.UI.Resource;

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
	public UISubsystem UI;

	private SceneModule mUIModule;

	public this()
	{
		SceneSystems = Context.AddSubsystem<SceneSubsystem>();
		SceneSystems.RegisterManager(Scenes);

		mUIModule = SceneModule("ui", => UIScene.AddUISceneManagers, null);
		let modules = scope SceneModule*[1](&mUIModule);
		// TAKES OWNERSHIP of what it is given.
		SceneSystems.SetComposition(SceneComposition.Build(modules));

		UI = Context.AddSubsystem<UISubsystem>();
		Context.Startup();
	}

	public ~this()
	{
		Context.Shutdown();
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
