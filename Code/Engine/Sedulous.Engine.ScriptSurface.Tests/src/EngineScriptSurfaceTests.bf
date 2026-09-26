using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.Script;
using Sedulous.Script.Null;
using Sedulous.Engine.ScriptSurface;

namespace Sedulous.Engine.ScriptSurface.Tests;

/// The runtime surface as a whole: the tripwire count, a few types that must be on it, and
/// the listing written out for reading.
static class EngineScriptSurfaceTests
{
	/// Where the listing goes: the workspace build directory, which the tests run two levels
	/// below. Read it to see what a script sees.
	public const String cDumpFile = "../../build/engine-script-surface.txt";

	private static ScriptMethodInfo Method(ScriptTypeInfo t, StringView name)
	{
		for (let m in t.Methods)
			if (m.ScriptName == name)
				return m;
		return null;
	}

	private static ScriptFieldInfo Field(ScriptTypeInfo t, StringView name)
	{
		for (let f in t.Fields)
			if (f.Name == name)
				return f;
		return null;
	}

	[Test]
	public static void TheCountIsATripwire()
	{
		let s = scope ScriptSurface();
		EngineScriptSurface.Populate(s);
		Test.Assert(s.Types.Count == EngineScriptSurface.TypeCount);
		// Bump deliberately when a type is marked or unmarked; a surprise here is a lost or
		// stray dependency of the root.
		Test.Assert(EngineScriptSurface.TypeCount == 88, scope $"the runtime surface has {EngineScriptSurface.TypeCount} types");
	}

	[Test]
	public static void OnlyTheRuntimeDomainIsPresent()
	{
		let s = scope ScriptSurface();
		EngineScriptSurface.Populate(s);
		let domains = scope List<String>();
		defer { ClearAndDeleteItems(domains); }
		s.CollectDomains(domains);
		Test.Assert((domains.Count == 1) && (domains[0] == ScriptDomains.Runtime));
	}

	[Test]
	public static void TheFacadesAreReachableAndTheEngineIsNot()
	{
		let s = scope ScriptSurface();
		EngineScriptSurface.Populate(s);

		// The facades, by role and name, with their verbs in script shape.
		let physics = s.Find("Sedulous.Engine.Script.Facades.PhysicsFacade");
		Test.Assert((physics != null) && (physics.Role == .SceneFacade) && (physics.DisplayName == "Physics"));
		let rayCast = Method(physics, "RayCast");
		Test.Assert((rayCast != null) && (rayCast.ReturnTypeName == "Sedulous.Engine.Physics.PhysicsHit"));
		let applyImpulse = Method(physics, "ApplyImpulse");
		Test.Assert((applyImpulse != null) && applyImpulse.OnEntity, "on the entity by request");
		for (let name in scope String[]("Animation", "Audio", "Particles", "Render", "Debug", "Splines", "Scripts", "Prefabs"))
		{
			bool found = false;
			for (let t in s.Types)
				if ((t.Role == .SceneFacade) && (t.DisplayName == name))
					found = true;
			Test.Assert(found, name);
		}
		let audio = s.Find("Sedulous.Engine.Script.Facades.AudioFacade");
		Test.Assert((audio != null) && (audio.Role == .Service) && (audio.DisplayName == "Audio"));
		let input = s.Find("Sedulous.Engine.Script.Facades.InputFacade");
		Test.Assert((input != null) && (input.Role == .Service) && (input.DisplayName == "Input"));
		Test.Assert(s.Find("Sedulous.Engine.GameInstance.GameInstance").Role == .Service, "Run");
		Test.Assert(s.Find("Sedulous.Engine.UI.Script.UiScript").Role == .Service, "Ui");

		// What the facades reach: the values they pass.
		let hit = s.Find("Sedulous.Engine.Physics.PhysicsHit");
		Test.Assert((hit != null) && hit.AllPublic && (hit.Fields.Count == 6));
		let float3 = s.Find("Sedulous.Core.Float3");
		Test.Assert((float3 != null) && (float3.Kind == .Struct) && float3.AllPublic);
		let core = s.Find("Sedulous.Core");
		Test.Assert((core != null) && (core.Kind == .Global) && (core.Methods.Count > 100), "the math free functions");
		Test.Assert(s.Find("Sedulous.Scene.Scene") != null, "the scene, the facades' home");

		// The components, as data with their few verbs: a script takes one from an entity,
		// `CharacterComponent(self)`, and reaches its fields through the manager.
		let character = s.Find("Sedulous.Engine.Physics.CharacterComponent");
		Test.Assert((character != null) && (character.Role == .Component));
		Test.Assert(Method(character, "Move") != null);
		Test.Assert(s.Find("Sedulous.Engine.Animation.SkeletalAnimationComponent").Role == .Component);
		// An asset field is what a script sets, never the runtime object behind it.
		let sprite = s.Find("Sedulous.Engine.Render.SpriteComponent");
		Test.Assert(Field(sprite, "TextureAsset") != null);
		Test.Assert(Field(sprite, "Texture") == null);
		Test.Assert(Field(s.Find("Sedulous.Engine.Particles.ParticleEffectComponent"), "Effect") == null);

		// And what the engine keeps to itself: no subsystem or manager is a script contract by
		// being linked, and neither is a component with nothing for gameplay code.
		Test.Assert(s.Find("Sedulous.Engine.Physics.PhysicsSceneSystem") == null);
		Test.Assert(s.Find("Sedulous.Engine.Animation.SkeletalAnimationComponentManager") == null);
		Test.Assert(s.Find("Sedulous.Engine.Audio.AudioSubsystem") == null);
		Test.Assert(s.Find("Sedulous.Engine.Render.RenderSubsystem") == null);
		for (let excluded in StringView[?]("Sedulous.Engine.Script.ScriptComponent", "Sedulous.Net.Replication.NetworkComponent",
			"Sedulous.Net.Replication.NetworkedTransform", "Sedulous.Engine.Navigation.NavMeshZoneComponent"))
			Test.Assert(s.Find(excluded) == null, scope String(excluded));
		for (let t in s.Types)
			Test.Assert((t.Role != .SceneSystem) && (t.Role != .ComponentManager), t.FullName);

		// The surface blocks nothing: a member the frame cannot carry is a surface bug.
		for (let t in s.Types)
		{
			for (let f in t.Fields)
				Test.Assert(f.Unsupported.IsEmpty, scope $"{t.FullName}.{f.Name}: {f.Unsupported}");
			for (let m in t.Methods)
				Test.Assert(m.Unsupported.IsEmpty, scope $"{t.FullName}.{m.Name}: {m.Unsupported}");
		}
	}

	[Test]
	public static void TheListingIsWrittenForReading()
	{
		let s = scope ScriptSurface();
		EngineScriptSurface.Populate(s);
		let vm = scope NullScriptRuntime();
		vm.Bind(s);
		let text = scope String();
		vm.Describe(text);

		let path = scope String();
		Path.GetAbsolutePath(cDumpFile, Directory.GetCurrentDirectory(.. scope .()), path);
		Test.Assert(File.WriteAllText(path, text) case .Ok, "could not write the listing");
		Console.WriteLine("script surface listing: {}", path);
	}
}
