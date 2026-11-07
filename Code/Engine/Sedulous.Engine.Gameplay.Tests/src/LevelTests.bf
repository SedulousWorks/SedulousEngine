using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Run;
using Sedulous.Runtime;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Xml;
using Sedulous.Xml.Serialization;
using Sedulous.Engine.Composition;
using Sedulous.Engine.Gameplay;

namespace Sedulous.Engine.Gameplay.Tests;

/// A game's Engine part registering two levels, as a game's Load does.
class LevelProbePart : PluginPart
{
	public override StringView PluginId => "level_probe";
	public override PluginPartKind Kind => .Engine;

	public override void Load(PluginContext context)
	{
		let engine = context.Find<EnginePluginServices>();
		GameplayServices.AddLevel<Gauntlet>(engine);
		GameplayServices.AddLevel<Trial>(engine);
	}
}

/// A Level: a system of its scene whose settings block is itself, run while the scene simulates
/// and its Active is on, its edges settled at the top of each tick; saved, kept while absent,
/// and contributed to every scene by AddLevel.
class LevelTests
{
	private const float cDt = 1.0f / 60.0f;

	private static uint64 GauntletKey => GameplayServices.SystemTypeOf<Gauntlet>();
	private static uint64 TrialKey => GameplayServices.SystemTypeOf<Trial>();

	private static void ClearContributions()
	{
		let registry = SceneModuleContributions.Global;
		registry.Remove(TrialKey);
		registry.Remove(GauntletKey);
	}

	// ---- the block is the level ----

	/// Its settings block is the system itself, under its [Level] id, and it runs before the
	/// behaviours and scripts, in simulation alone.
	[Test]
	public static void ItsSettingsBlockIsItself()
	{
		let scene = scope Scene();
		let level = scene.AddSystem<Gauntlet>();
		Test.Assert(level.SettingsType == typeof(Gauntlet));
		Test.Assert(level.SettingsInstance == Internal.UnsafeCastToPtr(level));
		Test.Assert(level.SettingsId == "test.gauntlet");
		Test.Assert(level.SettingsDataVersion == 1);
		Test.Assert(level.UpdateOrder == -111);
		Test.Assert(level.UpdateOrder < BehaviourSystem.cUpdateOrder);
		Test.Assert(level.IsSimulationOnly);
		Test.Assert(!level.Active, "off until a scene turns it on");

		// Added after the behaviours' system, it still runs before it.
		let ordered = scope Scene();
		ordered.AddSystem<BehaviourSystem>();
		let first = ordered.AddSystem<Trial>();
		Test.Assert(ordered.Systems[0] === first, "first in the scene's order");
	}

	// ---- the lifecycle ----

	/// Nothing while it is inactive or the scene does not simulate. Once both, the next tick
	/// starts it and updates it; the fixed steps before that tick do not reach it, the ones
	/// after do.
	[Test]
	public static void ItRunsOnlyWhileActiveAndSimulating()
	{
		LifecycleLog.Text.Clear();
		let scene = scope Scene();
		let level = scene.AddSystem<Gauntlet>();

		scene.Update(cDt);
		scene.FixedUpdate(cDt);
		Test.Assert(LifecycleLog.Text.IsEmpty, "inactive: nothing");

		level.Active = true;
		scene.SetSimulationEnabled(false);
		scene.Update(cDt);
		scene.FixedUpdate(cDt);
		Test.Assert(LifecycleLog.Text.IsEmpty, "not simulating, as in edit mode: nothing");
		Test.Assert(!level.Started);

		scene.SetSimulationEnabled(true);
		scene.FixedUpdate(cDt);
		Test.Assert(LifecycleLog.Text.IsEmpty, "a fixed step before the first tick does not start it");

		scene.Update(cDt);
		Test.Assert(LifecycleLog.Text == "G.Start G.Update ", LifecycleLog.Text);
		Test.Assert(level.Started);

		LifecycleLog.Text.Clear();
		scene.FixedUpdate(cDt);
		scene.Update(cDt);
		Test.Assert(LifecycleLog.Text == "G.Fixed G.Update ", LifecycleLog.Text);
		Test.Assert(level.FixedCount == 1);
		Test.Assert(Math.Abs(level.Elapsed - 2.0f * cDt) < 1e-6f);
	}

	/// Turning Active off stops it at the next tick, after which nothing reaches it; turning it
	/// on again starts it again, its fields as they were left.
	[Test]
	public static void TurningActiveOffStopsItAndOnStartsItAgain()
	{
		LifecycleLog.Text.Clear();
		let scene = scope Scene();
		let level = scene.AddSystem<Gauntlet>();
		level.Active = true;
		scene.Update(cDt);
		Test.Assert(LifecycleLog.Text == "G.Start G.Update ", LifecycleLog.Text);

		LifecycleLog.Text.Clear();
		level.Active = false;
		scene.FixedUpdate(cDt);
		Test.Assert(LifecycleLog.Text.IsEmpty, "an inactive level's fixed step waits for nothing");
		scene.Update(cDt);
		Test.Assert(LifecycleLog.Text == "G.Stop ", LifecycleLog.Text);
		Test.Assert(!level.Started);
		scene.Update(cDt);
		scene.FixedUpdate(cDt);
		Test.Assert(LifecycleLog.Text == "G.Stop ", "nothing after the stop");

		LifecycleLog.Text.Clear();
		level.Active = true;
		scene.Update(cDt);
		Test.Assert(LifecycleLog.Text == "G.Start G.Update ", LifecycleLog.Text);
		Test.Assert(Math.Abs(level.Elapsed - 2.0f * cDt) < 1e-6f, "its state as it was left");
	}

	/// An OnStart that turns it off: no update that tick, and the stop at the next.
	[Test]
	public static void AnOnStartThatTurnsItOffStopsItAtTheNextTick()
	{
		LifecycleLog.Text.Clear();
		let scene = scope Scene();
		let level = scene.AddSystem<Gauntlet>();
		delegate void(Gauntlet level) hook = scope (started) => { started.Active = false; };
		Gauntlet.StartHook = hook;
		defer { Gauntlet.StartHook = null; }

		level.Active = true;
		scene.Update(cDt);
		Test.Assert(LifecycleLog.Text == "G.Start ", LifecycleLog.Text);
		scene.Update(cDt);
		Test.Assert(LifecycleLog.Text == "G.Start G.Stop ", LifecycleLog.Text);
	}

	/// The scene stopping stops a started level, once; one that never started gets no OnStop.
	/// The next play starts it again on its first tick.
	[Test]
	public static void TheScenesStopStopsItAndTheNextPlayStartsItAgain()
	{
		LifecycleLog.Text.Clear();
		let scene = scope Scene();
		let level = scene.AddSystem<Gauntlet>();
		level.Active = true;
		scene.Start();
		scene.Stop();
		Test.Assert(LifecycleLog.Text.IsEmpty, "never started: no stop");

		scene.Start();
		scene.Update(cDt);
		scene.Stop();
		Test.Assert(LifecycleLog.Text == "G.Start G.Update G.Stop ", LifecycleLog.Text);

		LifecycleLog.Text.Clear();
		scene.Start();
		scene.Update(cDt);
		Test.Assert(LifecycleLog.Text == "G.Start G.Update ", LifecycleLog.Text);
		scene.Stop();
	}

	/// A running level deleted (its scene torn down unstopped, or the level removed from it)
	/// gets no OnStop, its subclass's fields being gone by then, but its subscriptions end and
	/// its queued calls are dropped (ASan checks both: each holds the level).
	[Test]
	public static void ADeletedLevelLetsGoOfWhatItHeldWithoutOnStop()
	{
		LifecycleLog.Text.Clear();
		let run = scope RunBase("levels");
		{
			let scene = scope Scene();
			scene.SetRun(run);
			let system = scene.AddSystem<BehaviourSystem>();
			let level = scene.AddSystem<Gauntlet>();
			level.Active = true;
			scene.Update(cDt);
			Test.Assert(run.Events.SubscriberCount == 1);
			level.Post(new () => { LifecycleLog.Text.Append("never "); });
			Test.Assert(scene.RemoveSystem<Gauntlet>());
			Test.Assert(run.Events.SubscriberCount == 0, "its subscription ended");
			// Its call was dropped in place: the drain runs nothing of it.
			scene.Update(cDt);
			Test.Assert(system.PendingCallCount == 0);
		}
		Test.Assert(LifecycleLog.Text == "G.Start G.Update ", LifecycleLog.Text);

		LifecycleLog.Text.Clear();
		{
			let scene = scope Scene();
			scene.SetRun(run);
			let level = scene.AddSystem<Gauntlet>();
			level.Active = true;
			scene.Update(cDt);
		}
		Test.Assert(LifecycleLog.Text == "G.Start G.Update ", LifecycleLog.Text);
		Test.Assert(run.Events.SubscriberCount == 0, "ended as its scene was torn down");
	}

	/// Two levels in one scene: each runs on its own Active, so a scene runs the one it turned on.
	[Test]
	public static void EachLevelRunsOnItsOwnActive()
	{
		LifecycleLog.Text.Clear();
		let scene = scope Scene();
		let gauntlet = scene.AddSystem<Gauntlet>();
		let trial = scene.AddSystem<Trial>();
		trial.Active = true;
		scene.Update(cDt);
		Test.Assert(trial.Started && !gauntlet.Started);
		Test.Assert(LifecycleLog.Text.IsEmpty, LifecycleLog.Text);
	}

	// ---- events and queued calls ----

	/// Its listener hears its run's events while it runs: not while it is inactive (even before
	/// the stop edge), and the subscription ends at the stop, and at its deletion. A start
	/// after a stop listens again. Outside a run Listen answers false (ASan checks the delete).
	[Test]
	public static void ItsListenersEndAtTheStop()
	{
		LifecycleLog.Text.Clear();
		let run = scope RunBase("levels");
		{
			let scene = scope Scene();
			scene.SetRun(run);
			let level = scene.AddSystem<Gauntlet>();
			level.Active = true;
			scene.Update(cDt);
			Test.Assert(level.Listening);
			Test.Assert(run.Events.SubscriberCount == 1);

			LifecycleLog.Text.Clear();
			level.Emit(DoorOpened(3));
			Test.Assert(LifecycleLog.Text == "G.Door3 ", LifecycleLog.Text);

			level.Active = false;
			GameEvents.Emit(run, DoorOpened(4));
			Test.Assert(LifecycleLog.Text == "G.Door3 ", "inactive: not heard");
			scene.Update(cDt);
			Test.Assert(run.Events.SubscriberCount == 0, "ended at the stop");

			level.Post(DoorOpened(5));
			run.Events.Drain();
			Test.Assert(level.Doors == 3);

			level.Active = true;
			scene.Update(cDt);
			Test.Assert(run.Events.SubscriberCount == 1, "listening again");
		}
		Test.Assert(run.Events.SubscriberCount == 0, "ended as it was deleted");

		let scene = scope Scene();
		let level = scene.AddSystem<Gauntlet>();
		level.Active = true;
		scene.Update(cDt);
		Test.Assert(!level.Listening, "no run");
	}

	/// A call it queues runs at the end of the tick, after its own update (it ticks first); one
	/// queued before it stops is dropped. Without a BehaviourSystem nothing is queued (ASan
	/// checks the delete).
	[Test]
	public static void AQueuedCallRunsAtTheDrainUnlessItStopped()
	{
		LifecycleLog.Text.Clear();
		let scene = scope Scene();
		let system = scene.AddSystem<BehaviourSystem>();
		let level = scene.AddSystem<Gauntlet>();
		level.Active = true;
		scene.Update(cDt);

		LifecycleLog.Text.Clear();
		Test.Assert(level.Post(new () => { LifecycleLog.Text.Append("call "); }));
		scene.Update(cDt);
		Test.Assert(LifecycleLog.Text == "G.Update call ", LifecycleLog.Text);

		LifecycleLog.Text.Clear();
		Test.Assert(level.Post(new () => { LifecycleLog.Text.Append("never "); }));
		Test.Assert(system.PendingCallCount == 1);
		level.Active = false;
		scene.Update(cDt);
		Test.Assert(LifecycleLog.Text == "G.Stop ", LifecycleLog.Text);
		Test.Assert(system.PendingCallCount == 0);

		let bare = scope Scene();
		let alone = bare.AddSystem<Trial>();
		Test.Assert(!alone.Post(new () => { LifecycleLog.Text.Append("never "); }));
	}

	// ---- its block on disk ----

	private static void Populate(Scene scene)
	{
		scene.SetName("arena");
		let gauntlet = scene.AddSystem<Gauntlet>();
		let trial = scene.AddSystem<Trial>();
		gauntlet.Active = true;
		gauntlet.TimeLimit = 12.5f;
		gauntlet.Rounds = 7;
		gauntlet.Title.Set("final");
		trial.Laps = 5;
		// Runtime state, not saved.
		scene.Update(cDt);
		LifecycleLog.Text.Clear();
	}

	private static void CheckRestored(Scene scene)
	{
		let gauntlet = scene.GetSystem<Gauntlet>();
		let trial = scene.GetSystem<Trial>();
		Test.Assert((gauntlet != null) && (trial != null));
		Test.Assert(gauntlet.Active);
		Test.Assert(gauntlet.TimeLimit == 12.5f);
		Test.Assert(gauntlet.Rounds == 7);
		Test.Assert(gauntlet.Title == "final");
		Test.Assert(gauntlet.Elapsed == 0.0f, "runtime state is not saved");
		Test.Assert(!gauntlet.Started, "read, not started");
		Test.Assert(!trial.Active);
		Test.Assert(trial.Laps == 5);
	}

	private static void RoundTrip(Scene source, Scene target)
	{
		let buffer = scope MemoryStream();
		{
			let writer = scope BinarySerializer(buffer, .Write);
			SceneSerializer.SerializeScene(writer, source, .Referenced, true, .Binary);
			Test.Assert(writer.IsOk);
		}
		buffer.Seek(0, .Begin);
		let reader = scope BinarySerializer(buffer, .Read);
		SceneSerializer.SerializeScene(reader, target, .Referenced, true, .Binary);
		Test.Assert(reader.IsOk);
	}

	private static void WriteText(Scene scene, String outText)
	{
		let serializer = scope XmlSerializer();
		SceneSerializer.SerializeScene(serializer, scene, .Referenced, true, .Text);
		Test.Assert(serializer.IsOk);
		serializer.GetOutput(outText);
	}

	private static void ReadText(StringView text, Scene target)
	{
		let document = scope XmlDocument();
		Test.Assert(document.Parse(text) == .Ok, "the scene just written parses as XML");
		let reader = scope XmlSerializer(document);
		SceneSerializer.SerializeScene(reader, target, .Referenced, true, .Text);
		Test.Assert(reader.IsOk);
	}

	[Test]
	public static void ItsBlockSurvivesABinaryRoundTrip()
	{
		let source = scope Scene();
		Populate(source);
		let target = scope Scene();
		target.AddSystem<Gauntlet>();
		target.AddSystem<Trial>();
		RoundTrip(source, target);
		CheckRestored(target);
	}

	/// In text: under its id, Active first, then its public fields; its private state is not
	/// written.
	[Test]
	public static void ItsBlockSurvivesATextRoundTrip()
	{
		let source = scope Scene();
		Populate(source);
		let text = scope String();
		WriteText(source, text);
		Test.Assert(text.Contains(">test.gauntlet<"), "under its id");
		let active = text.IndexOf("\"active\"");
		let limit = text.IndexOf("\"timeLimit\"");
		Test.Assert((active >= 0) && (limit > active), "Active leads the block");
		Test.Assert(text.Contains("\"rounds\"") && text.Contains("\"title\""));
		Test.Assert(!text.Contains("elapsed", true) && !text.Contains("doors", true), "private state is not written");

		let target = scope Scene();
		target.AddSystem<Gauntlet>();
		target.AddSystem<Trial>();
		ReadText(text, target);
		CheckRestored(target);
	}

	/// A level's block whose level is ABSENT (its plugin not loaded) is kept and written back,
	/// in each encoding, then read into the level in a scene that has it.
	[Test]
	public static void AnAbsentLevelsBlockIsPreservedAndWrittenBack()
	{
		let source = scope Scene();
		Populate(source);

		let bare = scope Scene();
		bare.AddSystem<Trial>();
		RoundTrip(source, bare);
		Test.Assert(bare.UnresolvedSettingsRecords.Length == 1, "the gauntlet's block was kept");
		Test.Assert(bare.UnresolvedSettingsRecords[0].SystemId == "test.gauntlet");
		let restored = scope Scene();
		restored.AddSystem<Gauntlet>();
		restored.AddSystem<Trial>();
		RoundTrip(bare, restored);
		Test.Assert(restored.UnresolvedSettingsRecords.IsEmpty);
		CheckRestored(restored);

		let text = scope String();
		WriteText(source, text);
		let bareText = scope Scene();
		bareText.AddSystem<Trial>();
		ReadText(text, bareText);
		Test.Assert(bareText.UnresolvedSettingsRecords.Length == 1);
		let again = scope String();
		WriteText(bareText, again);
		let restoredText = scope Scene();
		restoredText.AddSystem<Gauntlet>();
		restoredText.AddSystem<Trial>();
		ReadText(again, restoredText);
		Test.Assert(restoredText.UnresolvedSettingsRecords.IsEmpty);
		CheckRestored(restoredText);
	}

	/// A level arriving in a scene that already holds its block (its plugin loading into an open
	/// scene) takes the block's values, as the live install's resolve gives them.
	[Test]
	public static void ALevelArrivingLateTakesItsKeptBlock()
	{
		let source = scope Scene();
		Populate(source);
		let scene = scope Scene();
		scene.AddSystem<Trial>();
		RoundTrip(source, scene);
		Test.Assert(scene.UnresolvedSettingsRecords.Length == 1);

		scene.AddSystem<Gauntlet>();
		SceneResolve.ResolveAllUnresolvedRecords(scene);
		Test.Assert(scene.UnresolvedSettingsRecords.IsEmpty);
		CheckRestored(scene);
	}

	// ---- AddLevel ----

	/// AddLevel contributes the level to every scene, once per type, and none without the
	/// engine's service; a scene alive as it is added gets it at once, and its removal deletes a
	/// running one from that scene.
	[Test]
	public static void AddLevelContributesItToEveryScene()
	{
		ClearContributions();
		let registry = SceneModuleContributions.Global;

		GameplayServices.AddLevel<Gauntlet>(null);
		Test.Assert(!registry.Contains(GauntletKey), "no service, nothing added");

		let recorded = scope List<uint64>();
		delegate void(uint64) observer = scope [&] (systemType) => { recorded.Add(systemType); };
		registry.SetRegistrationObserver(observer);
		let engine = scope EnginePluginServices();
		GameplayServices.AddLevel<Gauntlet>(engine);
		GameplayServices.AddLevel<Trial>(engine);
		GameplayServices.AddLevel<Trial>(engine);
		registry.SetRegistrationObserver(null);
		Test.Assert(recorded.Count == 2, "each level once");
		Test.Assert((recorded[0] == GauntletKey) && (recorded[1] == TrialKey));
		Test.Assert(!registry.Contains(GameplayServices.SystemTypeOf<BehaviourSystem>()), "a level brings no BehaviourSystem");

		{
			let scene = scope Scene("made");
			registry.InstallAll(scene);
			Test.Assert((scene.GetSystem<Gauntlet>() != null) && (scene.GetSystem<Trial>() != null));
			Test.Assert(!scene.GetSystem<Gauntlet>().Active, "inactive until the scene turns it on");
		}
		ClearContributions();

		LifecycleLog.Text.Clear();
		let live = scope Scene("live");
		delegate void(delegate void(Scene)) sink = scope [&] (visit) => { visit(live); };
		registry.SetLiveSceneSink(sink);
		defer registry.SetLiveSceneSink(null);
		GameplayServices.AddLevel<Gauntlet>(engine);
		let level = live.GetSystem<Gauntlet>();
		Test.Assert(level != null, "a live scene gets it at once");
		level.Active = true;
		live.Update(cDt);
		registry.Remove(GauntletKey);
		Test.Assert(live.GetSystem<Gauntlet>() == null, "deleted from the live scene");
		Test.Assert(LifecycleLog.Text == "G.Start G.Update ", LifecycleLog.Text);
	}

	/// Through a plugin host: the part's Load adds them, a scene made while it is loaded has them,
	/// and the unload takes them out.
	[Test]
	public static void APluginsLevelsArriveAndLeaveWithIt()
	{
		ClearContributions();
		let manifest = scope PluginManifest();
		manifest.Id.Set("level_probe");
		manifest.Version.Set("0.1.0");
		manifest.EngineVersion.Set("0.1");
		let part = new PluginManifestPart();
		part.Kind.Set("Engine");
		manifest.Parts.Add(part);
		let platform = new PluginPlatform();
		platform.Platform.Set(PluginHost.HostPlatform);
		manifest.Platforms.Add(platform);
		let xml = manifest.Write(.. scope .());
		let probe = scope LevelProbePart();

		let subsystems = scope SubsystemManager();
		let engine = scope EnginePluginServices();
		let host = scope PluginHost(subsystems, .Player, "0.1.0");
		Test.Assert(engine.Attach(host));
		PluginPart[1] parts = .(probe);
		Test.Assert(host.AddLinked(xml, parts) case .Ok);
		let report = scope PluginLoadReport();
		host.Load(scope StringView[]("level_probe"), report);
		Test.Assert(report.Loaded.Count == 1);

		let registry = SceneModuleContributions.Global;
		Test.Assert(registry.Contains(GauntletKey) && registry.Contains(TrialKey));
		{
			let scene = scope Scene("probe");
			registry.InstallAll(scene);
			Test.Assert((scene.GetSystem<Gauntlet>() != null) && (scene.GetSystem<Trial>() != null));
		}

		host.Unload();
		Test.Assert(!registry.Contains(GauntletKey) && !registry.Contains(TrialKey));
	}
}
