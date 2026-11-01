using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Messaging;
using Sedulous.Run;

namespace Sedulous.Run.Tests;

/// A run's services (owned, borrowed, replaced, per session), its sessions and their hooks, its id
/// never reused, and the registry announcing each transition once to every listener, clearing the
/// focus with a destroyed run, and letting a late listener catch up.
class RunTests
{
	/// What happened, in order, across services and listeners.
	private static List<String> sLog = new .() ~ DeleteContainerAndItems!(_);

	private static void Note(StringView line) => sLog.Add(new .(line));

	/// The log matches `expected` (printed when it does not), and is cleared.
	private static bool Logged(params StringView[] expected)
	{
		var same = sLog.Count == expected.Count;
		for (int i < Math.Min(sLog.Count, expected.Count))
			same = same && (sLog[i] == expected[i]);
		if (!same)
		{
			for (let line in sLog)
				Console.WriteLine(scope $"logged: {line}");
		}
		ClearAndDeleteItems!(sLog);
		return same;
	}

	private class Hooked : IRunService
	{
		private String mName = new .() ~ delete _;
		public this(StringView name) { mName.Set(name); }
		public ~this() { Note(scope $"~{mName}"); }
		public void OnRunPaused(IRun run, bool paused) => Note(scope $"{mName} paused {paused}");
		public void OnRunStopping(IRun run) => Note(scope $"{mName} stopping");
	}
	private class First : Hooked { public this() : base("first") {} }
	private class Second : Hooked { public this() : base("second") {} }
	private class Session : Hooked { public this() : base("session") {} }
	private class Plain { public int Value = 7; }

	private class Recorder : IRunListener
	{
		private String mName = new .() ~ delete _;
		public this(StringView name) { mName.Set(name); }
		public void OnRunCreated(IRun r) => Note(scope $"{mName} created {r.Name}");
		public void OnRunStarted(IRun r) => Note(scope $"{mName} started {r.Name}");
		public void OnRunPaused(IRun r, bool p) => Note(scope $"{mName} paused {r.Name} {p}");
		public void OnRunStopping(IRun r) => Note(scope $"{mName} stopping {r.Name}");
		public void OnRunDestroyed(IRun r) => Note(scope $"{mName} destroyed {r.Name}");
		public void OnFocusChanged(IRun r)
		{
			let line = scope String()..AppendF("{} focus ", mName);
			if (r != null)
				line.Append(r.Name);
			else
				line.Append("none");
			Note(line);
		}
	}

	private class TestRun : RunBase
	{
		public this(StringView name) : base(name) {}
	}

	[Test]
	public static void ServicesByTypeOwnedDeletedLastFirstBorrowedLeftAloneASecondOfATypeReplaces()
	{
		ClearAndDeleteItems!(sLog);
		let borrowed = scope Plain();
		{
			let run = scope TestRun("Game 1");
			run.Add(new First());
			run.Add(new Second());
			Test.Assert(run.Register(borrowed) == borrowed);
			Test.Assert(run.Has<First>());
			Test.Assert(run.Get<Plain>().Value == 7);
			Test.Assert(RunServices.Get<Plain>(run) == borrowed, "through IRun too");
			Test.Assert(run.Get<Session>() == null);
			run.Add(new First()); // replaces: the old one goes now
			Test.Assert(Logged("~first"));
			run.Remove<Plain>();
			Test.Assert(!run.Has<Plain>());
		}
		// Reverse order of registration: the replacement First was registered after Second.
		Test.Assert(Logged("~first", "~second"));
		Test.Assert(borrowed.Value == 7);
	}

	[Test]
	public static void SessionsStartPauseOncePerChangeStopWithHooksLastFirstAndPerSessionServicesGo()
	{
		ClearAndDeleteItems!(sLog);
		let run = scope TestRun("Game 1");
		run.Add(new First());
		run.AddForSession(new Session());
		run.Add(new Second());
		Test.Assert(run.State == .Idle);
		run.SetPaused(true); // no session: nothing
		run.Stop();
		Test.Assert(Logged());

		run.Start();
		Test.Assert(run.State == .Running);
		run.SetPaused(true);
		run.SetPaused(true); // the same value again: nothing
		Test.Assert(run.State == .Paused);
		run.SetPaused(false);
		Test.Assert(Logged("second paused True", "session paused True", "first paused True", "second paused False",
			"session paused False", "first paused False"));

		run.Stop();
		Test.Assert(run.State == .Idle);
		Test.Assert(Logged("second stopping", "session stopping", "first stopping", "~session"));
		Test.Assert(!run.Has<Session>());
		Test.Assert(run.Has<First>());

		// Play again: session-long services are the same objects, per-session ones come back fresh.
		let first = run.Get<First>();
		run.Start();
		run.AddForSession(new Session());
		Test.Assert(run.Get<First>() == first);
		run.Dispose(); // stops the session under way first (this session's Session came after Second)
		Test.Assert(run.State == .Disposed);
		Test.Assert(Logged("session stopping", "second stopping", "first stopping", "~session", "~second", "~first"));
		run.Dispose(); // idempotent
		Test.Assert(Logged());
	}

	[Test]
	public static void IdsAreNeverReusedAndEachRunHasItsOwnBus()
	{
		RunId first = 0;
		{
			let a = scope TestRun("a");
			first = a.Id;
			Test.Assert(first != 0);
		}
		let b = scope TestRun("b");
		let c = scope TestRun("c");
		Test.Assert(b.Id > first);
		Test.Assert(c.Id > b.Id);
		Test.Assert(b.Events !== c.Events);
		var heard = 0;
		b.Events.Subscribe(StringHash("ping"), scope [&] (payload) => { heard++; });
		b.Events.Publish(StringHash("ping"), Variant());
		c.Events.Drain();
		Test.Assert(heard == 0);
		b.Events.Drain();
		Test.Assert(heard == 1);
	}

	[Test]
	public static void EveryTransitionAnnouncedOnceInOrderToEveryListenerDestroyedRunsLeave()
	{
		ClearAndDeleteItems!(sLog);
		let registry = scope RunRegistry();
		let audio = scope Recorder("audio");
		let gui = scope Recorder("gui");
		registry.Subscribe(audio);
		registry.Subscribe(gui);
		registry.Subscribe(audio); // once only
		{
			let run = scope TestRun("Game 1");
			registry.Add(run);
			Test.Assert(registry.Count == 1);
			Test.Assert(registry.Find(run.Id) == run);
			run.Start();
			run.SetPaused(true);
			run.Stop();
			Test.Assert(Logged("audio created Game 1", "gui created Game 1", "audio started Game 1", "gui started Game 1",
				"audio paused Game 1 True", "gui paused Game 1 True", "audio stopping Game 1", "gui stopping Game 1"));
			registry.SetFocused(run);
			registry.SetFocused(run); // unchanged: nothing
			Test.Assert(Logged("audio focus Game 1", "gui focus Game 1"));
		}
		// The run's end took it out, the focus with it.
		Test.Assert(Logged("audio focus none", "gui focus none", "audio destroyed Game 1", "gui destroyed Game 1"));
		Test.Assert(registry.Count == 0);
		Test.Assert(registry.Focused == null);

		registry.Unsubscribe(gui);
		let next = scope TestRun("Game 2");
		registry.Add(next);
		Test.Assert(Logged("audio created Game 2"));
		next.Dispose();
		ClearAndDeleteItems!(sLog);
	}

	[Test]
	public static void ALateListenerCatchesUpByListingTheRunsARegistryGoneLeavesItsRunsAlone()
	{
		ClearAndDeleteItems!(sLog);
		let a = scope TestRun("A");
		let b = scope TestRun("B");
		{
			let registry = scope RunRegistry();
			registry.Add(a);
			b.Start();
			registry.Add(b); // added running: announced as created and started
			let late = scope Recorder("late");
			registry.Subscribe(late);
			let seen = scope List<String>();
			defer { ClearAndDeleteItems!(seen); }
			registry.ForEachRun(scope (run) => { seen.Add(new String(run.Name)); });
			Test.Assert(seen.Count == 2);
			Test.Assert(seen[0] == "A");
			Test.Assert(seen[1] == "B");
			registry.Unsubscribe(late);
		}
		ClearAndDeleteItems!(sLog);
		b.Stop(); // the registry is gone: nothing tells it
		a.Dispose();
		Test.Assert(Logged());
	}
}
