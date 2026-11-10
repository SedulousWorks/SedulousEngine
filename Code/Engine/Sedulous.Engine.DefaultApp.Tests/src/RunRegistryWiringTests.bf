using System;
using Sedulous.Core;
using Sedulous.Run;
using Sedulous.Engine.DefaultApp;

namespace Sedulous.Engine.DefaultApp.Tests;

/// The runs: the app's instances are its runs, listed by its run
/// manager, which every subsystem finds on the subsystem manager; an instance released is announced
/// gone and leaves; the focused one, when it goes, takes the focus with it.
class RunRegistryWiringTests
{
	/// What a listener heard.
	private class Heard : IRunListener
	{
		public int Created = 0;
		public int Destroyed = 0;
		public int FocusCleared = 0;

		public void OnRunCreated(IRun run) { Created++; }
		public void OnRunDestroyed(IRun run) { Destroyed++; }
		public void OnFocusChanged(IRun focused) { FocusCleared += (focused == null) ? 1 : 0; }
	}

	[Test]
	public static void ItsInstancesAreTheRunsOnTheSubsystemManagerForEverySubsystem()
	{
		let host = scope StubHost();
		let app = scope DefaultApplication();
		// The host's order: configured, the subsystem manager started, then the application.
		app.Configure(host);
		host.Subsystems.Startup();
		app.OnStartup(host);
		let runs = host.Subsystems.RunManager;
		Test.Assert(runs != null);
		Test.Assert((Object)runs === (Object)app.Runs);
		Test.Assert((Object)runs.Find(app.Instance.Id) === app.Instance, "the primary instance is a run");

		let heard = scope Heard();
		runs.Subscribe(heard);
		let extra = app.CreateInstance(true);
		Test.Assert(extra != null);
		Test.Assert(heard.Created == 1);
		Test.Assert(extra.Name == "Game 2");
		let id = extra.Id;
		Test.Assert((Object)runs.Find(id) === extra);
		runs.SetFocused(extra);

		app.ReleaseInstance(extra);
		Test.Assert(heard.Destroyed == 1);
		Test.Assert(heard.FocusCleared == 1);
		Test.Assert(runs.Find(id) == null);
		Test.Assert(runs.Focused == null);
		let next = app.CreateInstance(true);
		Test.Assert(next != null);
		Test.Assert(next.Id != id, "ids are not reused");
		runs.Unsubscribe(heard);
		app.ReleaseInstance(next);

		// The host's order again; after the application's shutdown no run manager is left on it.
		host.Subsystems.Shutdown();
		app.OnShutdown(host);
		Test.Assert(host.Subsystems.RunManager == null);
		host.Subsystems.Dispose();
	}
}
