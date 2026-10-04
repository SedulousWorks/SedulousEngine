using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Engine.GameInstance;
using Sedulous.Input;
using Sedulous.Messaging;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Shell;

namespace Sedulous.Engine.GameInstance.Tests;

/// The running game as an object: its scene group, its bus, its input, and the load
/// orchestration it owns.
class GameInstanceTests
{
	/// A map with one button action bound to one key.
	private static InputMap MakeFireMap(KeyCode key)
	{
		let map = new InputMap();

		let set = new ActionSet();
		set.Name.Set("S");

		let action = new InputAction();
		action.Name.Set("fire");
		action.Kind = .Button;

		var binding = Binding();
		binding.Source = .Key;
		binding.Code = (uint32)key;
		action.Bindings.Add(binding);

		set.Actions.Add(action);
		map.Sets.Add(set);
		return map;
	}

	[Test]
	public static void AFreshInstanceIsIdleAndOwnsAUsableGroup()
	{
		let instance = scope GameInstance();
		Test.Assert(instance.InstanceTimeScale == 1.0f);

		instance.InstanceTimeScale = 0.5f;
		Test.Assert(instance.InstanceTimeScale == 0.5f);
		Test.Assert(instance.GetScene() == null);
		Test.Assert(!instance.SceneReady);

		Test.Assert(instance.Scenes.SceneCount == 0);
		let level = instance.Scenes.CreateScene("L1");
		Test.Assert(level != null);
		Test.Assert(instance.Scenes.SceneCount == 1);
		Test.Assert(instance.Scenes.CurrentScene === level);
	}

	[Test]
	public static void EachInstancesInputReadsOnlyItsOwnSource()
	{
		// Each instance has its OWN runtime bound to its OWN source, so one surface's keys
		// never reach another's game. The same map and the same key, two sources, and only
		// the one actually holding it fires.
		let a = scope GameInstance();
		let b = scope GameInstance();

		let sourceA = scope OneKeySource();
		sourceA.Key = .H;
		sourceA.Down = true;

		let sourceB = scope OneKeySource();
		sourceB.Key = .H;
		sourceB.Down = false;

		let mapA = MakeFireMap(.H);
		defer delete mapA;
		let mapB = MakeFireMap(.H);
		defer delete mapB;

		a.SetInputSource(sourceA);
		a.SetInputMap(mapA);
		b.SetInputSource(sourceB);
		b.SetInputMap(mapB);

		a.DriveInput(0.016f, 1.0f);
		b.DriveInput(0.016f, 1.0f);

		Test.Assert(a.InputRuntime.IsDown(a.InputRuntime.Resolve("fire")));
		Test.Assert(!b.InputRuntime.IsDown(b.InputRuntime.Resolve("fire")));

		// And the other way round, so this is isolation rather than an accident of order.
		sourceA.Down = false;
		sourceB.Down = true;

		a.DriveInput(0.016f, 1.0f);
		b.DriveInput(0.016f, 1.0f);

		Test.Assert(!a.InputRuntime.IsDown(a.InputRuntime.Resolve("fire")));
		Test.Assert(b.InputRuntime.IsDown(b.InputRuntime.Resolve("fire")));
	}

	[Test]
	public static void AScriptedTimelineDrivesOnlyItsOwnInstancesActions()
	{
		// A playtest's timeline through the project's map, as a player's keys would go: the
		// scripted instance's action follows the timeline, the other instance never sees it.
		let a = scope GameInstance();
		let b = scope GameInstance();
		let scripted = scope ScriptedInputSource();
		let idle = scope OneKeySource();
		idle.Key = .H;
		let mapA = MakeFireMap(.H);
		defer delete mapA;
		let mapB = MakeFireMap(.H);
		defer delete mapB;
		a.SetInputSource(scripted);
		a.SetInputMap(mapA);
		b.SetInputSource(idle);
		b.SetInputMap(mapB);

		// Names are the enums' own, any case.
		KeyCode key;
		Test.Assert(ScriptedInputSource.ParseKey("h", out key) && (key == .H));
		Test.Assert(ScriptedInputSource.ParseKey("Space", out key) && (key == .Space));
		Test.Assert(ScriptedInputSource.ParseKey("leftshift", out key) && (key == .LeftShift));
		Test.Assert(!ScriptedInputSource.ParseKey("Hyper", out key));
		GamepadAxis axis;
		Test.Assert(ScriptedInputSource.ParsePadAxis("LeftX", out axis) && (axis == .LeftX));

		var down = ScriptedInput();
		down.Kind = .Key;
		down.Key = .H;
		down.Down = true;
		down.At = 0.1;
		var up = down;
		up.Down = false;
		up.At = 0.3;
		Test.Assert(scripted.Add(up)); // out of order on purpose: the timeline sorts
		Test.Assert(scripted.Add(down));
		var badPad = ScriptedInput();
		badPad.Kind = .PadAxis;
		badPad.Gamepad = ScriptedInputSource.cMaxGamepads;
		Test.Assert(!scripted.Add(badPad));

		let fireA = a.InputRuntime.Resolve("fire");
		let fireB = b.InputRuntime.Resolve("fire");
		scripted.Advance(0.05);
		a.DriveInput(0.016f, 1.0f);
		b.DriveInput(0.016f, 1.0f);
		Test.Assert(!a.InputRuntime.IsDown(fireA), "not yet");
		scripted.Advance(0.12);
		a.DriveInput(0.016f, 1.0f);
		b.DriveInput(0.016f, 1.0f);
		Test.Assert(a.InputRuntime.IsDown(fireA));
		Test.Assert(a.InputRuntime.WasPressed(fireA));
		Test.Assert(scripted.Events.Length == 1 && (scripted.Events[0].Kind == .KeyDown));
		Test.Assert(!b.InputRuntime.IsDown(fireB), "the other instance never sees the timeline");
		scripted.Advance(0.2);
		a.DriveInput(0.016f, 1.0f);
		Test.Assert(a.InputRuntime.IsDown(fireA) && !a.InputRuntime.WasPressed(fireA), "held, no new edge");
		scripted.Advance(0.31);
		a.DriveInput(0.016f, 1.0f);
		Test.Assert(!a.InputRuntime.IsDown(fireA));
		Test.Assert(scripted.Finished);

		// A press and its release inside one frame still reads as a press.
		let quick = scope ScriptedInputSource();
		var tap = down;
		tap.At = 0.01;
		var untap = up;
		untap.At = 0.02;
		quick.Add(tap);
		quick.Add(untap);
		quick.Advance(0.025); // both inside one frame
		Test.Assert(quick.Keyboard.IsKeyPressed(.H) && quick.Keyboard.IsKeyReleased(.H) && !quick.Keyboard.IsKeyDown(.H));
		Test.Assert(quick.Events.Length == 2);

		// A run that ends holding a key lets go of it.
		let held = scope ScriptedInputSource();
		held.Add(down);
		held.Advance(1.0);
		Test.Assert(held.Keyboard.IsKeyDown(.H));
		held.ReleaseAll();
		Test.Assert(!held.Keyboard.IsKeyDown(.H) && held.Keyboard.IsKeyReleased(.H));
		Test.Assert(held.Events.Length == 1 && (held.Events[0].Kind == .KeyUp));
	}

	[Test]
	public static void TheRunBusDefersDeliversInOrderAndStaysPerInstance()
	{
		let instance = scope GameInstance();
		let bus = instance.RunEvents;

		let order = scope List<int32>();
		var received = 0;

		bus.Subscribe(StringHash("Ping"), scope [&] (payload) =>
			{
				order.Add(1);
				received = payload.Get<int32>();
			});
		bus.Subscribe(StringHash("Ping"), scope [&] (payload) =>
			{
				order.Add(2);
			});

		bus.Publish(StringHash("Ping"), Variant.Create<int32>(42));
		// Nothing fires before the drain: delivery is DEFERRED.
		Test.Assert(order.IsEmpty);

		instance.DrainRunEvents();
		Test.Assert(order.Count == 2);
		Test.Assert(order[0] == 1);
		Test.Assert(order[1] == 2);
		Test.Assert(received == 42);

		// A handler's own publish lands within the SAME drain.
		var cascaded = false;
		bus.Subscribe(StringHash("First"), scope [&] (payload) =>
			{
				bus.Publish(StringHash("Second"), Variant());
			});
		bus.Subscribe(StringHash("Second"), scope [&] (payload) =>
			{
				cascaded = true;
			});

		bus.Publish(StringHash("First"), Variant());
		instance.DrainRunEvents();
		Test.Assert(cascaded);

		// Two instances own INDEPENDENT buses.
		let other = scope GameInstance();
		var hitsA = 0;
		var hitsB = 0;

		instance.RunEvents.Subscribe(StringHash("Only"), scope [&] (payload) => { hitsA++; });
		other.RunEvents.Subscribe(StringHash("Only"), scope [&] (payload) => { hitsB++; });

		instance.RunEvents.Publish(StringHash("Only"), Variant());
		instance.DrainRunEvents();
		other.DrainRunEvents();

		Test.Assert(hitsA == 1);
		Test.Assert(hitsB == 0);
	}

	[Test]
	public static void CreatedScenesShareTheRunBus()
	{
		// Every scene the instance creates BORROWS the run bus, so a scene's events and the
		// run's are one object. A subscriber in one scene hears an emit from another with no
		// relay at all, delivered exactly once by the instance's drain: the borrowing scenes
		// never drain it themselves.
		let instance = scope GameInstance();
		let a = instance.CreateScene("A");
		let b = instance.CreateScene("B");
		Test.Assert(a != null);
		Test.Assert(b != null);
		Test.Assert(a.Events === instance.RunEvents);
		Test.Assert(b.Events === instance.RunEvents);

		var hits = 0;
		a.Events.Subscribe(StringHash("Ping"), scope [&] (payload) => { hits++; });
		b.Events.Publish(StringHash("Ping"), Variant());

		// Ticking the BORROWING scenes must not deliver it.
		a.Update(0.016f);
		b.Update(0.016f);
		Test.Assert(hits == 0);

		instance.DrainRunEvents();
		Test.Assert(hits == 1);
	}

	[Test]
	public static void ClearScenesResetsTheGroupTimeScale()
	{
		let instance = scope GameInstance();
		instance.Scenes.CreateScene("L1");

		// A game paused and then stopped: the group survives the stop on a persistent
		// instance, so a run scoped scale must not leak into the next play.
		instance.Scenes.TimeScale = 0.0f;
		Test.Assert(instance.Scenes.TimeScale == 0.0f);

		instance.ClearScenes();
		Test.Assert(instance.Scenes.SceneCount == 0);
		Test.Assert(instance.Scenes.TimeScale == 1.0f);
	}

	/// An instance IS its scenes' run: the scenes it creates and the ones it adopts carry it
	/// as their run key, which is what run scoped systems (audio) group them by.
	[Test]
	public static void AnInstanceIsItsScenesRun()
	{
		let instance = scope GameInstance();
		let created = instance.CreateScene("Created");
		Test.Assert(created.Run === instance);

		let adopted = scope Scene("Adopted");
		Test.Assert(adopted.Run == null);
		instance.SetScene(adopted);
		Test.Assert(adopted.Run === instance);
		instance.SetScene(created); // not left holding the scoped scene
	}
}
