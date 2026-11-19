using System;
using Sedulous.Core;
using Sedulous.Engine.DefaultApp;

namespace Sedulous.Engine.DefaultApp.Tests;

/// An application run released or shut down tells the aware subsystems its scenes are gone, so the
/// script subsystem keeps no scene system it would reach freed at shutdown (it did: the scenes
/// were cleared after their manager was unregistered, which takes away the uninstaller).
class InstanceTeardownTests
{
	[Test]
	public static void AReleasedInstancesScenesAreGoneBeforeShutdown()
	{
		let host = scope StubHost();
		let app = scope DefaultApplication();
		// The host's order: configured, the context started, then the application.
		app.Configure(host);
		host.Subsystems.Startup();
		app.OnStartup(host);
		let instance = app.CreateInstance(true);
		Test.Assert(instance != null);
		Test.Assert(instance.Scenes.CreateScene("released") != null);
		app.ReleaseInstance(instance);
		// The host's order again: the context down (the script subsystem's shutdown is where a
		// freed system was reached), the application, then the context disposed while the
		// subsystems the application registered are still alive.
		host.Subsystems.Shutdown();
		app.OnShutdown(host);
		host.Subsystems.Dispose();
	}

	[Test]
	public static void ShutdownTellsOfEveryInstancesScenes()
	{
		let host = scope StubHost();
		let app = scope DefaultApplication();
		// The host's order: configured, the context started, then the application.
		app.Configure(host);
		host.Subsystems.Startup();
		app.OnStartup(host);
		let instance = app.CreateInstance(true);
		Test.Assert(instance != null);
		Test.Assert(instance.Scenes.CreateScene("extra") != null);
		Test.Assert(app.Instance.Scenes.CreateScene("primary") != null);
		// The host's order again: the context down (the script subsystem's shutdown is where a
		// freed system was reached), the application, then the context disposed while the
		// subsystems the application registered are still alive.
		host.Subsystems.Shutdown();
		app.OnShutdown(host);
		host.Subsystems.Dispose();
	}

	/// The player's host shuts the subsystems down before it calls OnShutdown, where the scenes
	/// went: their teardown reached physics, audio and the rest after those had shut down.
	[Test]
	public static void LeavingPlayTakesTheRunsScenesWhileTheSubsystemsAreAlive()
	{
		let host = scope StubHost();
		let app = scope DefaultApplication();
		app.Configure(host);
		host.Subsystems.Startup();
		app.OnStartup(host);
		let instance = app.CreateInstance(true);
		Test.Assert(instance != null);
		Test.Assert(instance.Scenes.CreateScene("extra") != null);
		Test.Assert(app.Instance.Scenes.CreateScene("level") != null);
		app.OnExit(host); // the host calls this before it shuts the subsystems down
		Test.Assert(app.Instance.Scenes.SceneCount == 0, "the primary's scenes are gone");
		Test.Assert(instance.Scenes.SceneCount == 0, "and every other run's");
		host.Subsystems.Shutdown();
		app.OnShutdown(host);
		host.Subsystems.Dispose();
	}
}
