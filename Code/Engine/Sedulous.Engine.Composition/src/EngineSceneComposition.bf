using System;
using System.Collections;
using Sedulous.Engine.Domain;
using Sedulous.Scene;

namespace Sedulous.Engine.Composition;

/// THE full scene composition, the scene facet of EngineComposition: every domain's
/// serializable component managers and settings bearing systems, in one place.
///
/// A scene reader that meets a record whose manager is absent SKIPS it silently, so a
/// headless consumer loading an arbitrary scene needs the whole set present or it quietly
/// loses data. The runtime assembles from this SAME composition, which is what keeps the two
/// from drifting: every scene carries the full system set whether or not the matching
/// subsystem exists, and an absent subsystem simply leaves its systems unwired, as inert
/// pools and ticks that do nothing.
///
/// A manager added to a domain's own install function is picked up automatically, and a
/// domain is listed once, in EngineComposition: there is no second list here to forget.
static class EngineSceneComposition
{
	/// Ordering alone, with no dependencies declared: what matters is that the order is
	/// fixed, not that any domain needs another built first. No reflection registrars: Beef's
	/// own reflection is the table.
	public static SceneComposition Build()
	{
		let scenes = scope List<SceneModule*>();
		for (let domain in EngineComposition.Modules)
		{
			if (domain.HasScene)
				scenes.Add(domain.Scene);
		}
		return SceneComposition.Build(scenes);
	}

	/// Adds EVERY manager to a scene, for a headless scratch scene that has to deserialize
	/// an arbitrary stream.
	public static void AddAllSceneManagers(Scene scene)
	{
		for (let domain in EngineComposition.Modules)
		{
			if (domain.HasScene)
				domain.Scene.Install(scene);
		}
	}
}
