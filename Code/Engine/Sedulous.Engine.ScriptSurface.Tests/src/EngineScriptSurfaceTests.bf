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

	[Test]
	public static void TheCountIsATripwire()
	{
		let s = scope ScriptSurface();
		EngineScriptSurface.Populate(s);
		Test.Assert(s.Types.Count == EngineScriptSurface.TypeCount);
		// Bump deliberately when a type is marked or unmarked; a surprise here is a lost or
		// stray dependency of the root.
		Test.Assert(EngineScriptSurface.TypeCount == 157, scope $"the runtime surface has {EngineScriptSurface.TypeCount} types");
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
	public static void TheSubsystemsAreReachable()
	{
		let s = scope ScriptSurface();
		EngineScriptSurface.Populate(s);

		let physics = s.Find("Sedulous.Engine.Physics.PhysicsSceneSystem");
		Test.Assert((physics != null) && (physics.Role == .SceneSystem));
		let rayCast = Method(physics, "RayCast");
		Test.Assert((rayCast != null) && (rayCast.ReturnTypeName == "Sedulous.Engine.Physics.PhysicsHit"));

		let hit = s.Find("Sedulous.Engine.Physics.PhysicsHit");
		Test.Assert((hit != null) && hit.AllPublic && (hit.Fields.Count == 6));

		let float3 = s.Find("Sedulous.Core.Float3");
		Test.Assert((float3 != null) && (float3.Kind == .Struct) && float3.AllPublic);

		let core = s.Find("Sedulous.Core");
		Test.Assert((core != null) && (core.Kind == .Global) && (core.Methods.Count > 100), "the math free functions");

		let skeletal = s.Find("Sedulous.Engine.Animation.SkeletalAnimationComponent");
		Test.Assert((skeletal != null) && (skeletal.Role == .Component));
		Test.Assert(skeletal.ManagerTypeName == "Sedulous.Engine.Animation.SkeletalAnimationComponentManager");
		Test.Assert(skeletal.ComponentTypeId == "skeletal_animation");

		let audio = s.Find("Sedulous.Engine.Audio.AudioSubsystem");
		Test.Assert((audio != null) && (audio.Role == .Service));
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
