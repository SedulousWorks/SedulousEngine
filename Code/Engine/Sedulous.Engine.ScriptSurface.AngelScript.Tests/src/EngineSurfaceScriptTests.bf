using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Script;
using Sedulous.Script.AngelScript;
using Sedulous.Engine.Composition;

namespace Sedulous.Engine.Composition.AngelScript.Tests;

/// The whole runtime surface in AngelScript: it binds, and a script drives a real scene.
static class EngineSurfaceScriptTests
{
	[Test]
	public static void TheRuntimeSurfaceBinds()
	{
		let s = scope ScriptSurface();
		EngineScriptSurface.Populate(s);
		let vm = scope AngelScriptRuntime();
		vm.Bind(s);

		// Whatever the language refused is written beside the listing, for reading.
		let report = scope String();
		for (let p in vm.Problems)
			report.AppendF("{}\n", p);
		let path = scope String();
		Path.GetAbsolutePath("../../build/engine-script-surface-angelscript.txt", Directory.GetCurrentDirectory(.. scope .()), path);
		File.WriteAllText(path, report).IgnoreError();
		Console.WriteLine("angelscript binding report: {} ({} problems)", path, vm.Problems.Count);

		// Every member the surface binds, the language binds: the lists cross as arrays.
		Test.Assert(vm.Problems.Count == 0, scope $"{vm.Problems.Count} members the language refused; see the report");

		// And what it bound, as a script spells it, beside the listing: the API a browser
		// or a completion shows.
		let api = scope List<ScriptApiType>();
		defer { ClearAndDeleteItems(api); }
		vm.DescribeBoundApi(api);
		let text = scope String();
		text.AppendF("angelscript bound api: {} types\n\n", api.Count);
		for (let t in api)
		{
			text.AppendF("{}{}{}\n", t.IsNamespace ? "namespace " : "", t.ScriptName.IsEmpty ? "<global>" : t.ScriptName, t.TypeFullName.IsEmpty ? "" : scope:: $" [{t.TypeFullName}]");
			for (let m in t.Members)
				text.AppendF("    {}\n", m.Signature);
			text.Append("\n");
		}
		let apiPath = scope String();
		Path.GetAbsolutePath("../../build/engine-script-api-angelscript.txt", Directory.GetCurrentDirectory(.. scope .()), apiPath);
		File.WriteAllText(apiPath, text).IgnoreError();
		// One bound type per surface type: the facades, the components, the values they pass,
		// the globals.
		Test.Assert(api.Count == 101, scope $"{api.Count} bound types");
		// Spot checks of the spelling at the engine's scale.
		var scene = (ScriptApiType)null;
		for (let t in api)
			if (t.ScriptName == "Scene")
				scene = t;
		Test.Assert(scene != null);
		bool physics = false;
		for (let m in scene.Members)
			if (m.Signature == "PhysicsFacade@ Scene.Physics")
				physics = true;
		Test.Assert(physics, "the scene's system property");
		// Runtime state a component keeps from the inspector ([Hidden]) and gives a script to
		// read: the navigation agent's arrival and its steering.
		let agentApi = scope String();
		for (let t in api)
			if (t.ScriptName == "NavAgentComponent")
				for (let m in t.Members)
					agentApi.AppendF("{}\n", m.Signature);
		Test.Assert(agentApi.Contains("bool NavAgentComponent.Finished (read only)"), agentApi);
		Test.Assert(agentApi.Contains("Float3 NavAgentComponent.DesiredVelocity (read only)"), agentApi);
	}

	[Test]
	public static void AScriptDrivesAScene()
	{
		let s = scope ScriptSurface();
		EngineScriptSurface.Populate(s);
		let vm = scope AngelScriptRuntime();
		vm.Bind(s);

		let ok = vm.Compile("game", "game.as", """
			float run(Scene@ scene)
			{
				Entity e = scene.CreateEntity("player");
				scene.SetLocalPosition(e, Float3(1, 2, 3));
				scene.SetLocalScale(e, Float3(2, 2, 2));
				scene.UpdateTransforms();
				Float3 p = scene.GetWorldPosition(e);
				Transform t = scene.GetLocalTransform(e);
				return p.Y + t.Scale.X + Length(Float3(3, 4, 0)) + float(scene.IsValid(e) ? 100 : 0);
			}
			// Two scenes: each entity resolves in its own, whatever the other is doing.
			int bodies(Scene@ a, Scene@ b)
			{
				Entity ea = a.CreateEntity("a");
				Entity eb = b.CreateEntity("b");
				b.SetLocalPosition(eb, Float3(0, 5, 0));
				b.UpdateTransforms();
				a.UpdateTransforms();
				// A list parameter is the script's own array, filled by the callee: no
				// bodies yet, so it stays empty, and the call itself is what is proven.
				array<Entity> hits;
				a.Physics.OverlapSphere(Float3(0, 0, 0), 5.0f, hits);
				return int(a.GetWorldPosition(ea).Y) * 10 + int(b.GetWorldPosition(eb).Y) + a.Physics.BodyCount + b.Physics.BodyCount + int(hits.length());
			}
			""");
		for (let p in vm.Problems)
			Console.WriteLine("  {}", p);
		Test.Assert(ok, "compiled against the engine surface");

		let scene = scope Scene();
		var arg = ScriptValue[1](.FromObject(scene));
		var r = ScriptValue.Nil;
		Test.Assert(vm.Call("game", "float run(Scene@)", arg, ref r), "ran");
		for (let p in vm.Problems)
			Console.WriteLine("  {}", p);
		Test.Assert(Math.Abs(r.AsFloat - (2 + 2 + 5 + 100)) < 1e-4, scope $"got {r.AsFloat}");
		Test.Assert(scene.EntityCount == 1);

		let a = scope Scene("a");
		let b = scope Scene("b");
		a.AddSystem<Sedulous.Engine.Physics.PhysicsSceneSystem>();
		b.AddSystem<Sedulous.Engine.Physics.PhysicsSceneSystem>();
		var two = ScriptValue[2](.FromObject(a), .FromObject(b));
		Test.Assert(vm.Call("game", "int bodies(Scene@, Scene@)", two, ref r), "two scenes at once");
		for (let p in vm.Problems)
			Console.WriteLine("  {}", p);
		Test.Assert(r.AsInt == 5, scope $"got {r.AsInt}");
		Test.Assert((a.EntityCount == 1) && (b.EntityCount == 1));
	}

	/// scene.Render.LightAt reads how lit a place is, with and without a group mask: a lamp with
	/// no range falloff delivers its whole intensity anywhere.
	[Test]
	public static void AScriptReadsHowLitAPlaceIs()
	{
		let s = scope ScriptSurface();
		EngineScriptSurface.Populate(s);
		let vm = scope AngelScriptRuntime();
		vm.Bind(s);

		let ok = vm.Compile("game", "game.as", """
			bool meter(Scene@ scene)
			{
				Float3 lit = scene.Render.LightAt(Float3(0.0f, 0.0f, 0.0f));
				Float3 masked = scene.Render.LightAt(Float3(0.0f, 0.0f, 0.0f), 1);
				return (lit.X > 3.99f) && (lit.X < 4.01f) && (masked.Y > 3.99f);
			}
			""");
		for (let p in vm.Problems)
			Console.WriteLine("  {}", p);
		Test.Assert(ok, "compiled against the engine surface");

		let scene = scope Scene();
		let lights = scene.AddSystem<Sedulous.Engine.Render.LightComponentManager>();
		let lampEntity = scene.CreateEntity("lamp");
		scene.SetLocalPosition(lampEntity, .(0.0f, 2.0f, 0.0f));
		let lamp = lights.Add(lampEntity);
		lamp.Type = .Point;
		lamp.Intensity = 4.0f;
		lamp.Range = 0.0f; // no falloff: the full 4 arrives anywhere
		scene.UpdateTransforms();

		var arg = ScriptValue[1](.FromObject(scene));
		var r = ScriptValue.Nil;
		Test.Assert(vm.Call("game", "bool meter(Scene@)", arg, ref r), "ran");
		for (let p in vm.Problems)
			Console.WriteLine("  {}", p);
		Test.Assert(r.AsBool, "the lamp's light reached the script");
	}

	/// A character controller through scene.Physics: the verbs write the intent the physics
	/// step consumes, and an entity with no character is a no-op rather than a fault.
	[Test]
	public static void AScriptSteersACharacterThroughThePhysicsFacade()
	{
		let s = scope ScriptSurface();
		EngineScriptSurface.Populate(s);
		let vm = scope AngelScriptRuntime();
		vm.Bind(s);

		let ok = vm.Compile("game", "game.as", """
			bool drive(Scene@ scene, const Entity &in rider, const Entity &in bystander)
			{
				scene.Physics.MoveCharacter(rider, 3.0f, -4.0f);
				scene.Physics.JumpCharacter(rider, 5.5f);
				scene.Physics.SetCharacterPosition(rider, Float3(1, 2, 3));
				// No character on the bystander: every verb quietly does nothing.
				scene.Physics.MoveCharacter(bystander, 9.0f, 9.0f);
				return scene.Physics.IsCharacterGrounded(rider) || scene.Physics.IsCharacterGrounded(bystander);
			}
			""");
		for (let p in vm.Problems)
			Console.WriteLine("  {}", p);
		Test.Assert(ok, "compiled against the engine surface");

		let scene = scope Scene("chars");
		defer Sedulous.Script.SceneFacades.Release(scene);
		scene.AddSystem<Sedulous.Engine.Physics.PhysicsSceneSystem>();
		let characters = scene.AddSystem<Sedulous.Engine.Physics.CharacterComponentManager>();
		let rider = scene.CreateEntity("rider");
		let bystander = scene.CreateEntity("bystander");
		characters.Add(rider);

		var args = ScriptValue[3](.FromObject(scene), .FromEntity(rider, scene), .FromEntity(bystander, scene));
		var r = ScriptValue.Nil;
		Test.Assert(vm.Call("game", "bool drive(Scene@, const Entity &in, const Entity &in)", args, ref r), "ran");
		for (let p in vm.Problems)
			Console.WriteLine("  {}", p);
		Test.Assert(!r.AsBool, "never stepped, so nothing is grounded");

		let character = characters.Get(rider);
		Test.Assert((character.MoveVelocity.X == 3.0f) && (character.MoveVelocity.Y == 0.0f) && (character.MoveVelocity.Z == -4.0f));
		Test.Assert(character.JumpSpeed == 5.5f);
		Test.Assert(character.TeleportPending && (character.TeleportTo.X == 1.0f) && (character.TeleportTo.Z == 3.0f));
		Test.Assert(!characters.Has(bystander), "a verb never adds a character");
	}

	/// The same character through its component: a script takes it from an entity, sets a
	/// field and calls its verbs, and the component the engine holds is the one it changed. An
	/// entity with no character refuses rather than reading anything.
	[Test]
	public static void AScriptDrivesACharacterThroughItsComponent()
	{
		let s = scope ScriptSurface();
		EngineScriptSurface.Populate(s);
		let vm = scope AngelScriptRuntime();
		vm.Bind(s);

		let ok = vm.Compile("game", "game.as", """
			float drive(const Entity &in rider)
			{
				CharacterComponent character = CharacterComponent(rider);
				character.StepUp = 0.6f;
				character.Move(3.0f, -4.0f);
				character.Jump(5.5f);
				return character.StepUp;
			}
			float probe(const Entity &in bystander)
			{
				return CharacterComponent(bystander).StepUp;
			}
			""");
		for (let p in vm.Problems)
			Console.WriteLine("  {}", p);
		Test.Assert(ok, "compiled against the engine surface");

		let scene = scope Scene("chars");
		defer Sedulous.Script.SceneFacades.Release(scene);
		scene.AddSystem<Sedulous.Engine.Physics.PhysicsSceneSystem>();
		let characters = scene.AddSystem<Sedulous.Engine.Physics.CharacterComponentManager>();
		let rider = scene.CreateEntity("rider");
		let bystander = scene.CreateEntity("bystander");
		characters.Add(rider);

		var args = ScriptValue[1](.FromEntity(rider, scene));
		var r = ScriptValue.Nil;
		Test.Assert(vm.Call("game", "float drive(const Entity &in)", args, ref r), "ran");
		for (let p in vm.Problems)
			Console.WriteLine("  {}", p);
		Test.Assert(Math.Abs(r.AsFloat - 0.6f) < 1e-5, scope $"read back {r.AsFloat}");
		let character = characters.Get(rider);
		Test.Assert(Math.Abs(character.StepUp - 0.6f) < 1e-5, "the field write reached the component");
		Test.Assert((character.MoveVelocity.X == 3.0f) && (character.MoveVelocity.Z == -4.0f));
		Test.Assert(character.JumpSpeed == 5.5f);

		var missing = ScriptValue[1](.FromEntity(bystander, scene));
		Test.Assert(!vm.Call("game", "float probe(const Entity &in)", missing, ref r), "no character: refused");
		Test.Assert(!characters.Has(bystander), "reading never adds a character");
	}

	/// A board's surface: the motion and the ground under the character read, never written
	/// (the tick measures them; here they are seeded), and the whole velocity driven, by
	/// components or by a Float3.
	[Test]
	public static void AScriptReadsACharactersMotionAndGroundAndDrivesItsVelocity()
	{
		let s = scope ScriptSurface();
		EngineScriptSurface.Populate(s);
		let vm = scope AngelScriptRuntime();
		vm.Bind(s);

		let ok = vm.Compile("board", "board.as", """
			void ride(const Entity &in rider)
			{
				CharacterComponent c = CharacterComponent(rider);
				Float3 v = c.Velocity;
				Float3 n = c.GroundNormal;
				c.Drive(v.X + n.X, v.Y + n.Y, v.Z + n.Z);
			}
			void push(const Entity &in rider)
			{
				CharacterComponent(rider).Drive(Float3(-5.0f, 0.0f, 1.0f));
			}
			""");
		for (let p in vm.Problems)
			Console.WriteLine("  {}", p);
		Test.Assert(ok, "compiled against the engine surface");

		let scene = scope Scene("board");
		defer Sedulous.Script.SceneFacades.Release(scene);
		scene.AddSystem<Sedulous.Engine.Physics.PhysicsSceneSystem>();
		let characters = scene.AddSystem<Sedulous.Engine.Physics.CharacterComponentManager>();
		let rider = scene.CreateEntity("rider");
		let character = characters.Add(rider);
		character.Velocity = .(1.0f, 2.0f, 3.0f);
		character.GroundNormal = .(0.0f, 0.0f, 1.0f);

		var args = ScriptValue[1](.FromEntity(rider, scene));
		var r = ScriptValue.Nil;
		Test.Assert(vm.Call("board", "void ride(const Entity &in)", args, ref r), "ran");
		Test.Assert(character.Driving);
		Test.Assert((character.DriveVelocity.X == 1.0f) && (character.DriveVelocity.Y == 2.0f) && (character.DriveVelocity.Z == 4.0f));
		Test.Assert(vm.Call("board", "void push(const Entity &in)", args, ref r), "ran");
		Test.Assert((character.DriveVelocity.X == -5.0f) && (character.DriveVelocity.Z == 1.0f));

		let writer = scope AngelScriptRuntime();
		writer.Bind(s);
		Test.Assert(!writer.Compile("w", "w.as", """
			void cheat(const Entity &in e) { CharacterComponent(e).Velocity = Float3(9.0f, 0.0f, 0.0f); }
			"""), "measured, not written: the assignment does not compile");
	}

	/// A network identity through its component: a script gates on Authority (the owning
	/// side drives) and reads Id; replication owns both, so an assignment never compiles.
	[Test]
	public static void AScriptReadsANetworkIdentityAndWritesNothing()
	{
		let s = scope ScriptSurface();
		EngineScriptSurface.Populate(s);
		let vm = scope AngelScriptRuntime();
		vm.Bind(s);

		let ok = vm.Compile("net", "net.as", """
			int gate(const Entity &in e)
			{
				NetworkComponent network = NetworkComponent(e);
				int owned = (network.Authority == NetworkAuthority::Server) ? 1000 : 0;
				return owned + int(network.Id.Value);
			}
			""");
		for (let p in vm.Problems)
			Console.WriteLine("  {}", p);
		Test.Assert(ok, "the reads compile");

		let scene = scope Scene("net");
		defer Sedulous.Script.SceneFacades.Release(scene);
		let networks = scene.AddSystem<Sedulous.Net.Replication.NetworkComponentManager>();
		let e = scene.CreateEntity("replicated");
		networks.Add(e);
		networks.Get(e).Id = .(42);

		var args = ScriptValue[1](.FromEntity(e, scene));
		var r = ScriptValue.Nil;
		Test.Assert(vm.Call("net", "int gate(const Entity &in)", args, ref r), "ran");
		Test.Assert(r.AsInt == 1042, scope $"read {r.AsInt}");
		Test.Assert(networks.Get(e).Authority == .Server, "read, untouched");

		let writer = scope AngelScriptRuntime();
		writer.Bind(s);
		Test.Assert(!writer.Compile("w", "w.as", """
			void flip(const Entity &in e) { NetworkComponent(e).Authority = NetworkAuthority::Client; }
			"""), "no setter: the assignment does not compile");
		Test.Assert(!writer.Compile("w2", "w2.as", """
			void renumber(const Entity &in e) { NetworkComponent network = NetworkComponent(e); network.Id = NetworkId(7); }
			"""), "Id has no setter either");
	}

	/// A script controls a playing voice through the Audio facade: it keeps the run's music
	/// voice in a variable, eases its pitch and volume, and stops it with a fade. What a game
	/// does to speed its music up as a clock runs down.
	[Test]
	public static void AScriptControlsAPlayingVoiceThroughTheAudioFacade()
	{
		let s = scope ScriptSurface();
		EngineScriptSurface.Populate(s);
		let vm = scope AngelScriptRuntime();
		vm.Bind(s);

		let ok = vm.Compile("game", "game.as", """
			VoiceHandle music;
			bool hurry()
			{
				music = Audio.MusicVoice();
				Audio.SetVoicePitch(music, 1.5f, 0.5f);
				Audio.SetVoiceVolume(music, 0.25f);
				return Audio.IsVoicePlaying(music);
			}
			void finish()
			{
				Audio.StopVoice(music, 0.2f);
			}
			""");
		for (let p in vm.Problems)
			Console.WriteLine("  {}", p);
		Test.Assert(ok, "compiled against the engine surface");

		let settings = new Sedulous.Audio.AudioEngineSettings();
		settings.Headless = true;
		settings.DedupeWindowSeconds = 0.0f;
		let audio = new Sedulous.Engine.Audio.AudioSubsystem(settings);
		let context = new Sedulous.Runtime.Context();
		context.RegisterSubsystem<Sedulous.Engine.Audio.AudioSubsystem>(audio);
		context.Startup();
		// The context drives a registered subsystem but does not own it: it goes first.
		defer { delete context; delete audio; }
		let engine = audio.Engine;

		let run = scope Object();
		let facade = scope Sedulous.Engine.Script.Facades.AudioFacade(audio, new () => (Sedulous.Resource.ResourceManager)null, run);
		vm.SetService(facade);

		let samples = scope List<int16>();
		for (int frame < 16000)
			samples.Add((int16)(0.5f * Math.Sin(2.0f * 3.14159265f * 440.0f * (float)frame / 8000.0f) * 32000.0f));
		let clip = new Sedulous.Audio.AudioClip();
		defer delete clip;
		Test.Assert(Sedulous.Audio.AudioCodec.EncodeWav(samples, 1, 8000, clip.EncodedData));
		Test.Assert(Sedulous.Audio.AudioCodec.Probe(clip.EncodedBytes, let metadata));
		clip.Channels = metadata.Channels;
		clip.SampleRate = metadata.SampleRate;
		clip.FrameCount = metadata.FrameCount;
		clip.DurationSeconds = metadata.DurationSeconds;
		let music = audio.PlayMusic(clip, 0.0f, 1.0f, audio.RunGroupFor(run));
		Test.Assert(music.IsValid);

		var r = ScriptValue.Nil;
		Test.Assert(vm.Call("game", "bool hurry()", default, ref r), "ran");
		Test.Assert(r.AsBool, "the run's music is playing");
		Test.Assert(engine.GetVoiceStatus(music, var status));
		Test.Assert(status.Pitch == 1.0f, "eased, so not there at once");
		Test.Assert(Math.Abs(status.Volume - 0.25f) < 1e-5f, "set at once");
		audio.Update(0.25f);
		audio.Update(0.25f);
		Test.Assert(engine.GetVoiceStatus(music, out status));
		Test.Assert(Math.Abs(status.Pitch - 1.5f) < 1e-4f);

		Test.Assert(vm.Call("game", "void finish()", default, ref r), "ran");
		Test.Assert(!engine.IsPlaying(music), "fading out");
		for (int i < 4)
			audio.Update(0.1f);
		Test.Assert(!engine.IsValidHandle(music));
		context.Shutdown();
	}
}
