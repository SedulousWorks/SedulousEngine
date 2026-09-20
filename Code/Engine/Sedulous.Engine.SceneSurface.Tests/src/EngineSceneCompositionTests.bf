using System;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Net.Replication;
using Sedulous.Engine.Animation;
using Sedulous.Engine.Audio;
using Sedulous.Engine.Render;
using Sedulous.Engine.Script;
using Sedulous.Engine.Spline;
using Sedulous.Engine.Terrain;
using Sedulous.Engine.UI;
using Sedulous.Engine.SceneSurface;

namespace Sedulous.Engine.SceneSurface.Tests;

/// The scene surface composition root: one per domain module list whose install entries ARE
/// the domains' own Add<Domain>SceneManagers functions, so a manager added to a domain cannot
/// be forgotten from a parallel headless list. Guarded here: every domain is present, and
/// the managers a hand kept copy of the list has dropped in the past resolve by type.
static class EngineSceneCompositionTests
{
	[Test]
	public static void TheFullCompositionCoversEveryDomain()
	{
		let composition = EngineSceneComposition.Build();
		defer delete composition;
		Test.Assert(composition.ModuleCount == 12, scope $"{composition.ModuleCount} modules");

		let scratch = scope Scene("surface");
		EngineSceneComposition.AddAllSceneManagers(scratch);

		// Each of these was missing from an export tool's private copy of the list at some
		// point in Raptor's history.
		Test.Assert(scratch.HasSystem<PropertyAnimatorComponentManager>());
		Test.Assert(scratch.HasSystem<PostProcessSystem>());
		Test.Assert(scratch.HasSystem<ScriptComponentManager>());
		Test.Assert(scratch.HasSystem<UICanvasComponentManager>());
		Test.Assert(scratch.HasSystem<AudioSourceComponentManager>());
		Test.Assert(scratch.HasSystem<NetworkComponentManager>());
		Test.Assert(scratch.HasSystem<TerrainComponentManager>());
		Test.Assert(scratch.HasSystem<SplineComponentManager>());
		// The runtime spawn rides the composition, so every composed scene can spawn by id.
		Test.Assert(scratch.HasSystem<PrefabSpawnSystem>());

		// Serialization routing: on disk type ids resolve to their managers.
		Test.Assert(scratch.FindManagerBySerializationId("net.Network") != null);
		Test.Assert(scratch.FindManagerBySerializationId("no.such.component") == null);
	}
}
