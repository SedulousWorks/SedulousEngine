using System;
using Sedulous.Engine.Animation;
using Sedulous.Engine.Audio;
using Sedulous.Engine.Navigation;
using Sedulous.Engine.Net;
using Sedulous.Engine.Particles;
using Sedulous.Engine.Physics;
using Sedulous.Engine.Render;
using Sedulous.Engine.Spline;
using Sedulous.Engine.Terrain;
using Sedulous.Engine.UI;
using Sedulous.Scene;
using Sedulous.Scene.Resource;

namespace Sedulous.Engine.DefaultApp;

/// THE full scene composition: every domain's serializable component managers and settings
/// bearing systems, in one place.
///
/// A scene reader that meets a record whose manager is absent SKIPS it silently, so a
/// headless consumer loading an arbitrary scene needs the whole set present or it quietly
/// loses data. The runtime assembles from this SAME composition, which is what keeps the two
/// from drifting: every scene carries the full system set whether or not the matching
/// subsystem exists, and an absent subsystem simply leaves its systems unwired, as inert
/// pools and ticks that do nothing.
///
/// Raptor keeps this in a module of its own, so a tool can reach it without the application.
/// That module is out of scope, so it lives here, with the one consumer that is in scope. It
/// wants lifting out again when the export and validation tools arrive.
///
/// A manager added to a domain's own install function is picked up automatically: there is no
/// second list here to forget.
static class EngineSceneComposition
{
	/// Ordering alone, with no dependencies declared, exactly as Raptor has it: what matters
	/// is that the order is fixed, not that any domain needs another built first.
	private static SceneModule[11] sModules = .(
		.("prefabs", => PrefabSpawnScene.AddPrefabSpawnSceneManagers, null),
		.("render", => RenderScene.AddRenderSceneManagers, null),
		.("animation", => AnimationScene.AddAnimationSceneManagers, null),
		.("particles", => ParticleScene.AddParticleSceneManagers, null),
		.("physics", => PhysicsScene.AddPhysicsSceneManagers, null),
		.("terrain", => TerrainScene.AddTerrainSceneManagers, null),
		.("navigation", => NavigationScene.AddNavigationSceneManagers, null),
		.("audio", => AudioScene.AddAudioSceneManagers, null),
		.("ui", => UIScene.AddUISceneManagers, null),
		.("net", => NetworkScene.AddNetworkSceneManagers, null),
		.("spline", => SplineScene.AddSplineSceneManagers, null));

	/// No reflection registrars: Beef's own reflection replaces the tables Raptor registers
	/// per domain, so every module here declares none.
	public static SceneComposition Build()
	{
		let pointers = scope SceneModule*[sModules.Count];
		for (int i < sModules.Count)
			pointers[i] = &sModules[i];

		return SceneComposition.Build(pointers);
	}

	/// Adds EVERY manager to a scene, for a headless scratch scene that has to deserialize
	/// an arbitrary stream.
	public static void AddAllSceneManagers(Scene scene)
	{
		for (int i < sModules.Count)
			sModules[i].Install(scene);
	}
}
