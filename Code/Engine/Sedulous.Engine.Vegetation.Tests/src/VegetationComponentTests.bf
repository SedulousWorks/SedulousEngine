using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Geometry;
using Sedulous.Heightfield;
using Sedulous.Render;
using Sedulous.Scene;
using Sedulous.Terrain;
using Sedulous.Terrain.Resource;
using Sedulous.Vegetation;
using Sedulous.Vegetation.Resource;
using Sedulous.Engine.Terrain;
using Sedulous.Engine.Vegetation;

namespace Sedulous.Engine.Vegetation.Tests;

/// The layer manager: one set per layer and chunk in range, the splat picking the chunks, the
/// fade prefix, region scoped regrow, the build budget, and what extracts nothing.
class VegetationComponentTests
{
	/// Two by two chunks.
	private const int32 cGrid = 129;
	/// A metre per quad, so the chunks are 64 by 64 metres, centred on the origin.
	private const float cWorld = 128.0f;

	private static bool Near(float a, float b, float epsilon = 0.01f) => Math.Abs(a - b) <= epsilon;

	private static Heightfield MakeFlat(float height)
	{
		let grid = new Heightfield(cGrid, .(cWorld, cWorld), 0.0f, 40.0f);
		let sample = grid.WorldYToSample(height);
		for (int32 z = 0; z < cGrid; z++)
			for (int32 x = 0; x < cGrid; x++)
				grid.SetSample(x, z, sample);
		return grid;
	}

	/// Palette layer nought one hot on the left half, base on the right.
	private static SplatWeights MakeHalfSplat()
	{
		const int32 n = 64;
		let sw = new SplatWeights(n, n);
		let idx = sw.Indices;
		let wts = sw.Weights;
		for (int32 y = 0; y < n; y++)
		{
			for (int32 x = 0; x < n / 2; x++)
			{
				let at = sw.TexelOffset(x, y);
				idx[at + 0] = 0;
				wts[at + 0] = 255;
			}
		}
		sw.BumpVersion();
		return sw;
	}

	/// A scene with a terrain entity and one grass layer entity under it.
	private class Fixture
	{
		public Scene Scene = new .() ~ delete _;
		public Heightfield Grid ~ delete _;
		public SplatWeights Splat ~ delete _;
		public TerrainResource Resource = new .() ~ delete _;
		public StaticMesh Mesh ~ delete _;
		public EntityHandle Terrain = .();
		public TerrainVegetationComponentManager Manager = null;

		public this(bool withSplat = true)
		{
			TerrainScene.AddTerrainSceneManagers(Scene);
			VegetationScene.AddVegetationSceneManagers(Scene);
			Manager = Scene.GetSystem<TerrainVegetationComponentManager>();
			Test.Assert(Manager != null);

			Grid = MakeFlat(2.0f);
			Resource.Heightfield.SetDirect(Grid);
			if (withSplat)
			{
				Splat = MakeHalfSplat();
				Resource.Weights.SetDirect(Splat);
			}

			Terrain = Scene.CreateEntity("terrain");
			Scene.GetSystem<TerrainComponentManager>().Add(Terrain).Terrain.SetDirect(Resource);

			Mesh = Primitives.Cube(0.5f);
			// The layers live in slots on the TERRAIN entity's vegetation component.
			let component = Manager.Add(Terrain);
			let c = new ProceduralVegetationLayer();
			c.Name.Set("Grass");
			c.Mesh.SetDirect(Mesh);
			c.Placement = withSplat ? .Splat : .Uniform;
			c.SplatLayer = 0;
			c.Density = 0.25f; // 1024 candidates per chunk
			c.MaxSlopeDegrees = 90.0f;
			c.FadeStart = 40.0f;
			c.FadeEnd = 80.0f;
			component.ProceduralLayers.Add(c);
			Scene.Start();
		}

		public TerrainVegetationComponent* Component => Manager.Get(Terrain);
		public ProceduralVegetationLayer Layer => Component.ProceduralLayers[0];
		public PropVegetationLayer PropLayer => Component.PropLayers[0];

		/// A prop layer carrying the fixture's mesh, which is what a prop test paints into.
		public PropVegetationLayer AddPropLayer()
		{
			let layer = new PropVegetationLayer();
			layer.Name.Set("Props");
			layer.Mesh.SetDirect(Mesh);
			layer.MaxSlopeDegrees = 90.0f;
			layer.FadeStart = 40.0f;
			layer.FadeEnd = 80.0f;
			Component.PropLayers.Add(layer);
			return layer;
		}

		/// Extracts with the view at an origin, or headless, collecting the emitted sets.
		public void Extract(ExtractedScene snapshot, Float3* origin, List<MultiMeshRenderData> outSets)
		{
			snapshot.Reset();
			if (origin != null)
				snapshot.SetViewOrigin(*origin);
			Manager.ExtractRenderData(snapshot);

			outSets.Clear();
			for (let item in snapshot.Items)
			{
				let mm = item as MultiMeshRenderData;
				Test.Assert(mm != null);
				outSets.Add(mm);
			}
		}
	}

	private static uint32 TotalInstances(List<MultiMeshRenderData> sets)
	{
		var n = (uint32)0;
		for (let s in sets)
			n += s.InstanceCount;
		return n;
	}

	[Test]
	public static void OneSetPerLayerAndChunkInRangeAndTheSplatPicksTheChunks()
	{
		let f = scope Fixture();
		f.Manager.SetBuildBudget(100);
		let snapshot = scope ExtractedScene();
		let sets = scope List<MultiMeshRenderData>();

		// Headless: every chunk is in range, and only the painted half grows, so the two
		// chunks on that side emit while the other two scatter to nothing.
		f.Extract(snapshot, null, sets);
		Test.Assert(f.Manager.BuildCount == 4); // all four chunks scattered
		Test.Assert(sets.Count == 2);
		Test.Assert(f.Manager.BuiltSetCount == 2);
		Test.Assert((uint32)f.Manager.InstanceCount == TotalInstances(sets));
		for (let s in sets)
		{
			Test.Assert(s.Key != 0);
			// The layer's window, which the vertex shaders dissolve against per instance.
			Test.Assert(Near(s.FadeStart, 40.0f));
			Test.Assert(Near(s.FadeEnd, 80.0f));
			// The splat share is one on the painted half, so every candidate is kept.
			Test.Assert(s.InstanceCount == 1024);
			Test.Assert(s.Transforms != null);
			Test.Assert(s.Mesh === f.Mesh);
			Test.Assert(s.Version > 0);
			Test.Assert(!s.CastShadows); // the grass default
			Test.Assert(s.Category == RenderCategories.Opaque);
			Test.Assert(s.WorldCenter.X < 0.0f); // the painted chunks
			Test.Assert(s.WorldRadius > 32.0f);
			Test.Assert(EntityTag.Index(s.EntityId) == f.Terrain.Index);
			for (uint32 i = 0; i < s.InstanceCount; i++)
			{
				Test.Assert(s.Transforms[i].M[3][0] < 0.0f);
				Test.Assert(Near(s.Transforms[i].M[3][1], 2.0f, 0.05f));
			}
		}
		Test.Assert(sets[0].Key != sets[1].Key);

		// A rock layer casts.
		f.Layer.CastShadows = true;
		f.Extract(snapshot, null, sets);
		Test.Assert(sets.Count == 2);
		Test.Assert(sets[0].CastShadows);
		Test.Assert(f.Manager.BuildCount == 4); // a fade or shadow change never rescatters

		// A second extraction re-emits the same sets: the same keys and versions, so the
		// renderer re-uploads nothing.
		let key0 = sets[0].Key;
		let version0 = sets[0].Version;
		f.Extract(snapshot, null, sets);
		Test.Assert(sets.Count == 2);
		Test.Assert(sets[0].Key == key0);
		Test.Assert(sets[0].Version == version0);
	}

	[Test]
	public static void TheFadePrefixThinsByDistanceAndOutOfRangeChunksAreAbsent()
	{
		let f = scope Fixture(false); // Uniform, so all four chunks grow
		f.Manager.SetBuildBudget(100);
		let snapshot = scope ExtractedScene();
		let sets = scope List<MultiMeshRenderData>();

		// The view over one chunk's centre: that chunk is at no distance, the diagonal one is
		// inside the fade, so it draws a partial prefix while the near ones are full.
		var near = Float3(-32.0f, 12.0f, -32.0f);
		f.Extract(snapshot, &near, sets);
		Test.Assert(sets.Count == 4);
		var full = 0;
		var partial = 0;
		for (let s in sets)
		{
			Test.Assert(s.InstanceCount > 0);
			Test.Assert(s.InstanceCount <= 1024);
			if (s.InstanceCount == 1024)
				full++;
			else
				partial++;
		}
		Test.Assert(full >= 1);
		Test.Assert(partial >= 1);

		// Far away nothing is in range and nothing new is built: a hidden viewport never
		// grows anything.
		let builds = f.Manager.BuildCount;
		var far = Float3(2000.0f, 12.0f, 0.0f);
		f.Extract(snapshot, &far, sets);
		Test.Assert(sets.IsEmpty);
		Test.Assert(f.Manager.BuildCount == builds);
		Test.Assert(f.Manager.BuiltSetCount == 4); // the sets stay cached for the return

		// Back in range: the cached sets return without a rebuild.
		f.Extract(snapshot, &near, sets);
		Test.Assert(sets.Count == 4);
		Test.Assert(f.Manager.BuildCount == builds);
	}

	[Test]
	public static void AVersionBumpRegrowsOnlyTheTouchedChunksWhenARegionSaysWhich()
	{
		let f = scope Fixture(false);
		f.Manager.SetBuildBudget(100);
		let snapshot = scope ExtractedScene();
		let sets = scope List<MultiMeshRenderData>();
		f.Extract(snapshot, null, sets);
		Test.Assert(sets.Count == 4);
		Test.Assert(f.Manager.BuildCount == 4);

		let versions = scope List<uint32>();
		let keys = scope List<uint64>();
		for (let s in sets)
		{
			versions.Add(s.Version);
			keys.Add(s.Key);
		}

		// A sculpt inside ONE chunk: the bump plus the region rebuilds only it, so its
		// version moves and the other three keep theirs.
		f.Grid.BumpVersion();
		var region = HeightfieldRegion();
		region.MinX = 10;
		region.MaxX = 20;
		region.MinZ = 10;
		region.MaxZ = 20;
		f.Manager.InvalidateRegion(region);
		f.Extract(snapshot, null, sets);
		Test.Assert(sets.Count == 4);
		Test.Assert(f.Manager.BuildCount == 5);
		var bumped = 0;
		for (let s in sets)
		{
			for (int i < keys.Count)
			{
				if (keys[i] == s.Key)
					bumped += (s.Version != versions[i]) ? 1 : 0;
			}
		}
		Test.Assert(bumped == 1);

		// A bump with NO region notice regrows everything, the conservative fallback.
		f.Grid.BumpVersion();
		f.Extract(snapshot, null, sets);
		Test.Assert(f.Manager.BuildCount == 9);

		// A new splat identity regrows every chunk, and a scatter parameter change resets the
		// whole layer.
		let splat = MakeHalfSplat();
		defer delete splat;
		f.Resource.Weights.SetDirect(splat);
		f.Extract(snapshot, null, sets);
		Test.Assert(f.Manager.BuildCount == 13);
		f.Layer.Density = 0.5f;
		f.Extract(snapshot, null, sets);
		Test.Assert(f.Manager.BuildCount == 17);
		for (let s in sets)
			Test.Assert(s.InstanceCount == 2048);

		// Moving the terrain entity RECOMPOSES, so the versions move without a rescatter.
		f.Scene.SetLocalPosition(f.Terrain, .(100.0f, 0.0f, 0.0f));
		f.Scene.UpdateTransforms();
		f.Extract(snapshot, null, sets);
		Test.Assert(f.Manager.BuildCount == 17);
		Test.Assert(sets.Count == 4);
		for (let s in sets)
		{
			Test.Assert(s.WorldCenter.X > 30.0f); // shifted along
			Test.Assert(s.Transforms[0].M[3][0] > 30.0f);
		}
	}

	[Test]
	public static void TheBuildBudgetSpreadsAColdStartOverExtractions()
	{
		let f = scope Fixture(false);
		f.Manager.SetBuildBudget(1);
		let snapshot = scope ExtractedScene();
		let sets = scope List<MultiMeshRenderData>();

		f.Extract(snapshot, null, sets);
		Test.Assert(sets.Count == 1);
		Test.Assert(f.Manager.BuildCount == 1);
		f.Extract(snapshot, null, sets);
		Test.Assert(sets.Count == 2);
		f.Extract(snapshot, null, sets);
		f.Extract(snapshot, null, sets);
		Test.Assert(sets.Count == 4);
		Test.Assert(f.Manager.BuildCount == 4);
		f.Extract(snapshot, null, sets);
		Test.Assert(f.Manager.BuildCount == 4); // warm, so no more builds
	}

	[Test]
	public static void NoLayerHiddenOffTerrainOrNoMeshExtractsNothing()
	{
		let bare = scope Scene();
		TerrainScene.AddTerrainSceneManagers(bare);
		VegetationScene.AddVegetationSceneManagers(bare);
		let bareManager = bare.GetSystem<TerrainVegetationComponentManager>();
		Test.Assert(bareManager != null);
		bare.Start();
		let snapshot = scope ExtractedScene();
		bareManager.ExtractRenderData(snapshot);
		Test.Assert(snapshot.IsEmpty);

		let f = scope Fixture(false);
		f.Manager.SetBuildBudget(100);
		let sets = scope List<MultiMeshRenderData>();
		f.Layer.Visible = false;
		f.Extract(snapshot, null, sets);
		Test.Assert(sets.IsEmpty);
		f.Layer.Visible = true;
		f.Extract(snapshot, null, sets);
		Test.Assert(sets.Count == 4);

		// A hidden COMPONENT draws nothing either, and its layers keep their caches.
		f.Component.Visible = false;
		f.Extract(snapshot, null, sets);
		Test.Assert(sets.IsEmpty);
		Test.Assert(f.Manager.BuiltSetCount == 4, "a hidden component keeps its sets");
		f.Component.Visible = true;

		// An inactive entity is absent.
		f.Scene.SetActive(f.Terrain, false);
		f.Extract(snapshot, null, sets);
		Test.Assert(sets.IsEmpty);
		f.Scene.SetActive(f.Terrain, true);
		f.Extract(snapshot, null, sets);
		Test.Assert(sets.Count == 4);

		// No mesh: nothing to instance.
		f.Layer.Mesh.SetDirect(null);
		f.Extract(snapshot, null, sets);
		Test.Assert(sets.IsEmpty);

		// A removed component drops every cache.
		f.Layer.Mesh.SetDirect(f.Mesh);
		f.Extract(snapshot, null, sets);
		Test.Assert(f.Manager.BuiltSetCount == 4);
		f.Manager.Remove(f.Terrain);
		f.Extract(snapshot, null, sets);
		Test.Assert(sets.IsEmpty);
		Test.Assert(f.Manager.BuiltSetCount == 0);
	}

	/// Two layer slots are two independent families of sets, and removing one slot drops
	/// exactly its caches while the other keeps drawing.
	[Test]
	public static void TwoLayerSlotsAreTwoFamiliesAndARemovedSlotDropsItsSets()
	{
		let f = scope Fixture(false); // Uniform, so all four chunks grow
		f.Manager.SetBuildBudget(100);
		let snapshot = scope ExtractedScene();
		let sets = scope List<MultiMeshRenderData>();

		let second = new ProceduralVegetationLayer();
		second.Name.Set("Rocks");
		second.Mesh.SetDirect(f.Mesh);
		second.Placement = .Uniform;
		second.Density = 0.1f;
		second.MaxSlopeDegrees = 90.0f;
		second.CastShadows = true;
		f.Component.ProceduralLayers.Add(second);

		f.Extract(snapshot, null, sets);
		Test.Assert(sets.Count == 8, "four chunks each, for two slots");
		Test.Assert(f.Manager.BuiltSetCount == 8);

		// The slots' keys never collide: the seed hashes the slot index too.
		let keys = scope List<uint64>();
		for (let s in sets)
		{
			Test.Assert(!keys.Contains(s.Key), "every set has its own key");
			keys.Add(s.Key);
		}

		// Each family keeps its own draw state.
		var casting = 0;
		for (let s in sets)
			casting += s.CastShadows ? 1 : 0;
		Test.Assert(casting == 4, "only the rock slot casts");

		// A hidden SLOT keeps its sets and stops drawing; the other is untouched.
		second.Visible = false;
		f.Extract(snapshot, null, sets);
		Test.Assert(sets.Count == 4);
		Test.Assert(f.Manager.BuiltSetCount == 8, "the hidden slot keeps its sets");
		second.Visible = true;

		// Removing the slot drops exactly its caches.
		f.Component.ProceduralLayers.RemoveAt(1);
		delete second;
		f.Extract(snapshot, null, sets);
		Test.Assert(sets.Count == 4);
		Test.Assert(f.Manager.BuiltSetCount == 4, "the removed slot's sets are gone");
	}

	/// A mask bump regrows like a splat bump, and a footprint rect regrows only the chunks it
	/// covers: that is what a brush stamp sends, so painting one corner never rescatters the
	/// whole terrain.
	[Test]
	public static void AMaskBumpRegrowsAndAFootprintRectScopesIt()
	{
		let f = scope Fixture(false); // Uniform, so all four chunks grow
		f.Manager.SetBuildBudget(100);
		let snapshot = scope ExtractedScene();
		let sets = scope List<MultiMeshRenderData>();

		let mask = scope VegetationMask(64, 64, 1);
		for (int32 y = 0; y < 64; y++)
			for (int32 x = 0; x < 64; x++)
				mask.SetDensity(0, x, y, 255);
		f.Component.Mask.SetDirect(mask);
		f.Layer.Placement = .Mask;
		f.Layer.MaskPlane = 0;

		f.Extract(snapshot, null, sets);
		Test.Assert(sets.Count == 4);
		let built = f.Manager.BuildCount;

		// A mask version bump with no region notice regrows every chunk.
		mask.BumpVersion();
		f.Extract(snapshot, null, sets);
		Test.Assert(f.Manager.BuildCount == built + 4);

		// A footprint rect over ONE corner regrows only the chunks it touches.
		let scoped = f.Manager.BuildCount;
		mask.BumpVersion();
		f.Manager.InvalidateFootprint(0.02f, 0.02f, 0.08f, 0.08f, f.Grid.Size);
		f.Extract(snapshot, null, sets);
		Test.Assert(f.Manager.BuildCount == scoped + 1, "one chunk regrew, not four");

		// A degenerate rect or a degenerate grid is a no op, so nothing regrows at all.
		let quiet = f.Manager.BuildCount;
		mask.BumpVersion();
		f.Manager.InvalidateFootprint(0.5f, 0.5f, 0.1f, 0.1f, f.Grid.Size); // inverted
		f.Extract(snapshot, null, sets);
		Test.Assert(f.Manager.BuildCount == quiet + 4, "an unusable rect falls back to everything");
	}

	/// A PROP layer draws what was placed, bucketed by position, and re-buckets when the
	/// placed set changes.
	[Test]
	public static void APropLayerBucketsItsPlacedInstancesAndReBucketsOnAChange()
	{
		let f = scope Fixture(false);
		f.Manager.SetBuildBudget(100);
		f.Layer.Visible = false; // the grass out of the way: the props are what is measured
		let rocks = f.AddPropLayer();
		rocks.ScaleRange = .(1.0f, 1.0f);
		// Three props in the negative chunk and one in the positive one; the other two chunks
		// hold none.
		rocks.Instances.Add(Float4x4.Translation(.(-40.0f, 2.0f, -40.0f)));
		rocks.Instances.Add(Float4x4.Translation(.(-10.0f, 2.0f, -50.0f)));
		rocks.Instances.Add(Float4x4.Translation(.(-30.0f, 2.0f, -1.0f)));
		rocks.Instances.Add(Float4x4.Translation(.(20.0f, 2.0f, 20.0f)));

		let snapshot = scope ExtractedScene();
		let sets = scope List<MultiMeshRenderData>();
		f.Extract(snapshot, null, sets);
		Test.Assert(sets.Count == 2, "only the two chunks holding props emit");

		var three = 0;
		var one = 0;
		for (let set in sets)
		{
			if (set.InstanceCount == 3)
			{
				three++;
				Test.Assert(set.WorldCenter.X < 0.0f);
				Test.Assert(set.WorldCenter.Z < 0.0f);
				for (uint32 i < 3)
					Test.Assert(set.Transforms[(int)i].M[3][0] < 0.0f, "each prop in its own chunk");
			}
			else if (set.InstanceCount == 1)
			{
				one++;
				Test.Assert(Near(set.Transforms[0].M[3][0], 20.0f));
			}
		}
		Test.Assert(three == 1);
		Test.Assert(one == 1);
		Test.Assert(f.Manager.BuildCount == 4, "every chunk is bucketed once");

		// Unchanged instances rebuild nothing; a stroke, which is a new instance, re-buckets
		// the whole layer.
		f.Extract(snapshot, null, sets);
		Test.Assert(f.Manager.BuildCount == 4);
		rocks.Instances.Add(Float4x4.Translation(.(50.0f, 2.0f, -50.0f)));
		f.Extract(snapshot, null, sets);
		Test.Assert(f.Manager.BuildCount == 8, "a content change re-buckets every chunk");
		Test.Assert(sets.Count == 3);

		// Erasing back to the old content is another hash and another re-bucket.
		rocks.Instances.RemoveAt(4);
		f.Extract(snapshot, null, sets);
		Test.Assert(sets.Count == 2);

		// The fade prefix applies as it does to any set: a distant view thins the props away.
		var far = Float3(2000.0f, 5.0f, 0.0f);
		f.Extract(snapshot, &far, sets);
		Test.Assert(sets.IsEmpty);
	}

	/// The authored props ride the wire with their layer.
	[Test]
	public static void TheAuthoredInstancesRoundTrip()
	{
		let blob = scope MemoryStream();
		{
			let authored = scope PropVegetationLayer();
			authored.Name.Set("Rocks");
			authored.MaxSlopeDegrees = 12.5f;
			authored.Instances.Add(Float4x4.Translation(.(1.0f, 2.0f, 3.0f)));
			authored.Instances.Add(Float4x4.Translation(.(7.0f, 2.0f, 3.0f)));

			let writer = scope BinarySerializer(blob, .Write);
			authored.Serialize(writer);
			Test.Assert(writer.IsOk);
		}

		blob.Seek(0, .Begin);
		let loaded = scope PropVegetationLayer();
		let reader = scope BinarySerializer(blob, .Read);
		loaded.Serialize(reader);
		Test.Assert(reader.IsOk);

		Test.Assert(loaded.Name == "Rocks");
		Test.Assert(Near(loaded.MaxSlopeDegrees, 12.5f));
		Test.Assert(loaded.Instances.Count == 2);
		Test.Assert(Near(loaded.Instances[1].M[3][0], 7.0f));
	}

	/// An invalidated set keeps drawing what it had until its rebuild's turn comes, so a
	/// brush stroke never blinks the ground out from under itself; props rebuild whole.
	[Test]
	public static void AnInvalidatedSetKeepsDrawingUntilItsRebuildLands()
	{
		let f = scope Fixture(false);
		f.Manager.SetBuildBudget(100);
		let snapshot = scope ExtractedScene();
		let sets = scope List<MultiMeshRenderData>();

		f.Extract(snapshot, null, sets);
		Test.Assert(sets.Count == 4, "warm");
		Test.Assert(f.Manager.BuildCount == 4);

		// A sculpt, which dirties every chunk, under a budget of one: every frame still draws
		// all four sets, the three not yet rebuilt showing what they had, while one rebuilds
		// per extraction.
		f.Manager.SetBuildBudget(1);
		f.Grid.BumpVersion();
		for (uint32 frame = 1; frame <= 4; frame++)
		{
			f.Extract(snapshot, null, sets);
			Test.Assert(sets.Count == 4);
			Test.Assert(f.Manager.BuildCount == (4 + frame));
		}
		f.Extract(snapshot, null, sets);
		Test.Assert(f.Manager.BuildCount == 8, "all caught up");

		// A COLD set, never built, still waits its turn: a fresh layer under the same budget.
		let flowers = new ProceduralVegetationLayer();
		flowers.Name.Set("Flowers");
		flowers.Mesh.SetDirect(f.Mesh);
		flowers.Placement = .Uniform;
		flowers.Density = f.Layer.Density;
		flowers.MaxSlopeDegrees = 90.0f;
		flowers.FadeStart = f.Layer.FadeStart;
		flowers.FadeEnd = f.Layer.FadeEnd;
		f.Component.ProceduralLayers.Add(flowers);
		f.Extract(snapshot, null, sets);
		Test.Assert(sets.Count == 5, "the four grass sets and the one flower chunk built here");

		// Authored props re-bucket outside the budget, so a stroke lands whole in one
		// extraction.
		f.Component.ProceduralLayers.RemoveAt(1);
		delete flowers;
		f.Layer.Visible = false; // the grass out of the way: the props are what is measured
		let props = f.AddPropLayer();
		for (int32 i < 4)
		{
			props.Instances.Add(Float4x4.Translation(
				.(((i % 2) == 0) ? -30.0f : 30.0f, 2.0f, (i < 2) ? -30.0f : 30.0f)));
		}
		// A fresh layer buckets all four chunks on its first extraction.
		f.Extract(snapshot, null, sets);
		Test.Assert(sets.Count == 4);

		let builds = f.Manager.BuildCount;
		props.Instances.Add(Float4x4.Translation(.(-31.0f, 2.0f, -31.0f)));
		f.Extract(snapshot, null, sets);
		Test.Assert(sets.Count == 4);
		Test.Assert(f.Manager.BuildCount == (builds + 4), "every chunk re-bucketed, budget one");
		Test.Assert(TotalInstances(sets) == 5);
	}

	/// A freshly added PROCEDURAL layer follows the plane you paint: exactly what the
	/// inspector's add button makes, plus a mesh, grows nothing until that plane has paint.
	[Test]
	public static void AFreshProceduralLayerGrowsNothingUntilItsPlaneIsPainted()
	{
		// The splat has palette nought painted, so a Splat default would grow at once.
		let f = scope Fixture();
		f.Manager.SetBuildBudget(100);

		let fresh = new ProceduralVegetationLayer();
		fresh.Mesh.SetDirect(f.Mesh);
		fresh.MaxSlopeDegrees = 90.0f;
		Test.Assert(fresh.Placement == .Mask, "a new layer follows the plane you paint");
		Test.Assert(fresh.ToScatterLayer().Placement == .Mask);
		f.Component.ProceduralLayers.Add(fresh);

		let snapshot = scope ExtractedScene();
		let sets = scope List<MultiMeshRenderData>();
		f.Extract(snapshot, null, sets);
		Test.Assert(sets.Count == 2, "the fixture's grass alone; there is no mask to read");

		// Choosing a source it can actually read makes it grow like the grass.
		fresh.Placement = .Splat;
		f.Extract(snapshot, null, sets);
		Test.Assert(sets.Count == 4);
	}

	/// The instances inside a disc about the origin, which is where the cuts below are made.
	private static uint32 CountInside(List<MultiMeshRenderData> sets, float radius,
		bool leftHalfOnly = false)
	{
		var n = (uint32)0;
		for (let set in sets)
		{
			for (uint32 i = 0; i < set.InstanceCount; i++)
			{
				let x = set.Transforms[i].M[3][0];
				let z = set.Transforms[i].M[3][2];
				if (leftHalfOnly && (x >= 0.0f))
					continue;
				if (((x * x) + (z * z)) < (radius * radius))
					n++;
			}
		}
		return n;
	}

	/// Cutting a hole bumps the version, so every set regrows, and the regrown scatter leaves
	/// the cut cells bare. Uniform and splat placed alike.
	[Test]
	public static void CuttingAHoleRegrowsTheLayerWithNothingInsideTheCut()
	{
		for (let withSplat in scope bool[](false, true))
		{
			let f = scope:: Fixture(withSplat);
			f.Manager.SetBuildBudget(100);
			let snapshot = scope:: ExtractedScene();
			let sets = scope:: List<MultiMeshRenderData>();

			// The splat half is x < 0, so only two of the four chunks grow there.
			let grown = withSplat ? 2 : 4;
			f.Extract(snapshot, null, sets);
			Test.Assert(sets.Count == grown);
			let before = TotalInstances(sets);
			Test.Assert(before > 0);
			Test.Assert(CountInside(sets, 10.0f, withSplat) > 0, "grass grew where the cut goes");

			HeightfieldHoles.Cut(f.Grid, 0.0f, 0.0f, 12.0f); // 24 across the centre, all chunks
			Test.Assert(f.Grid.HasHoles);

			f.Extract(snapshot, null, sets);
			Test.Assert(sets.Count == grown);
			// All four chunks are scattered either way; only the ones that grew anything
			// emit a set, so the build count is four and then four again.
			Test.Assert(f.Manager.BuildCount == 8, "every chunk regrew");
			// A two metre margin in from the rim, so no rounding sits on the boundary.
			Test.Assert(CountInside(sets, 10.0f) == 0, "and nothing grew inside the cut");
			Test.Assert(TotalInstances(sets) < before);
		}
	}

	/// A STAMPED prop over a cut does not draw, and comes back with the fill.
	///
	/// The authored list is left alone, a terrain brush not being an editor of vegetation
	/// data, so the eraser can still reach the prop through the hole; the bucketed set simply
	/// leaves it out while its cell is cut.
	[Test]
	public static void AStampedPropOverACutDoesNotDrawAndComesBackWithTheFill()
	{
		let f = scope Fixture(false);
		f.Manager.SetBuildBudget(100);
		f.Layer.Visible = false; // the grass out of the way: the props are what is measured

		let rocks = f.AddPropLayer();
		rocks.ScaleRange = .(1.0f, 1.0f);
		rocks.Instances.Add(Float4x4.Translation(.(-40.0f, 2.0f, -40.0f)));
		rocks.Instances.Add(Float4x4.Translation(.(-20.0f, 2.0f, -20.0f)));
		rocks.Instances.Add(Float4x4.Translation(.(20.0f, 2.0f, 20.0f)));

		let snapshot = scope ExtractedScene();
		let sets = scope List<MultiMeshRenderData>();
		f.Extract(snapshot, null, sets);
		Test.Assert(TotalInstances(sets) == 3);

		HeightfieldHoles.Cut(f.Grid, -20.0f, -20.0f, 3.0f); // under the second prop alone
		f.Extract(snapshot, null, sets);
		Test.Assert(TotalInstances(sets) == 2);
		Test.Assert(f.PropLayer.Instances.Count == 3, "the placed data keeps it");
		for (let set in sets)
		{
			for (uint32 i = 0; i < set.InstanceCount; i++)
				Test.Assert(set.Transforms[i].M[3][0] != -20.0f);
		}

		HeightfieldHoles.Fill(f.Grid, -20.0f, -20.0f, 3.0f);
		f.Extract(snapshot, null, sets);
		Test.Assert(TotalInstances(sets) == 3, "and the fill brings it back");
	}

	/// A hand written VERSION ONE payload, the single list layout, splits into the two lists
	/// and re-saves as version two.
	///
	/// The bytes are laid out here rather than captured from an old build, so the test
	/// describes the layout it claims to read: a chain of one entry at version 1, then the
	/// mask, then the layer array in version 1's field order, then visible.
	[Test]
	public static void AVersionOnePayloadSplitsIntoTheTwoLists()
	{
		let blob = scope MemoryStream();
		{
			let writer = scope BinarySerializer(blob, .Write);
			// The envelope the component manager would have written under version 1.
			SerializedDataVersion[1] chain = .(.(TypeIdOf("terrainVegetation"), 1));
			BeginVersionedPayload(writer, .(&chain[0], 1));

			Guid maskId = default;
			SerializeValue(writer, "mask", ref maskId);

			var count = (uint32)2;
			writer.Key("layers");
			writer.BeginArray(ref count);
			WriteLayerV1(writer, "Grass", 1, 7); // Splat: a procedural layer
			WriteLayerV1(writer, "Rocks", 3, 0); // the retired Scattered: a prop layer
			writer.EndArray();

			var visible = true;
			SerializeValue(writer, "visible", ref visible);
			EndVersionedPayload(writer);
			Test.Assert(writer.IsOk);
		}

		// Read it back THROUGH the manager, which is what applies the floor.
		let scene = scope Scene();
		VegetationScene.AddVegetationSceneManagers(scene);
		let manager = scene.GetSystem<TerrainVegetationComponentManager>();
		let entity = scene.CreateEntity("terrain");
		manager.Add(entity);

		Test.Assert(blob.Seek(0, .Begin) == 0);
		let reader = scope BinarySerializer(blob, .Read);
		manager.ReadComponent(reader, entity);
		Test.Assert(reader.IsOk, "the version one payload was accepted by the floor");

		let component = manager.Get(entity);
		Test.Assert(component.ProceduralLayers.Count == 1, "the Splat layer grew");
		Test.Assert(component.PropLayers.Count == 1, "and the Scattered one became a prop layer");
		Test.Assert(component.ProceduralLayers[0].Name == "Grass");
		Test.Assert(component.ProceduralLayers[0].Placement == .Splat);
		Test.Assert(component.ProceduralLayers[0].SplatLayer == 7);
		Test.Assert(component.PropLayers[0].Name == "Rocks");
		Test.Assert(component.PropLayers[0].Instances.Count == 1);

		// And what goes back out is version TWO, in the new shape.
		let resaved = scope MemoryStream();
		{
			let writer = scope BinarySerializer(resaved, .Write);
			manager.WriteComponent(writer, entity);
			Test.Assert(writer.IsOk);
		}

		let second = scope Scene();
		VegetationScene.AddVegetationSceneManagers(second);
		let secondManager = second.GetSystem<TerrainVegetationComponentManager>();
		let secondEntity = second.CreateEntity("terrain");
		secondManager.Add(secondEntity);
		Test.Assert(resaved.Seek(0, .Begin) == 0);
		let back = scope BinarySerializer(resaved, .Read);
		secondManager.ReadComponent(back, secondEntity);
		Test.Assert(back.IsOk, "the re-saved payload reads as the current version");

		let round = secondManager.Get(secondEntity);
		Test.Assert(round.ProceduralLayers.Count == 1);
		Test.Assert(round.PropLayers.Count == 1);
		Test.Assert(round.PropLayers[0].Instances.Count == 1);
	}

	/// One version 1 layer in version 1's field order.
	private static void WriteLayerV1(ISerializer ar, StringView name, uint8 placement,
		uint32 splatLayer)
	{
		var name;
		var placement;
		var splatLayer;
		let owned = scope String(name);
		Sedulous.Core.Serialization.Serialize(ar, "name", owned);
		Guid mesh = default;
		Guid material = default;
		SerializeValue(ar, "mesh", ref mesh);
		SerializeValue(ar, "material", ref material);
		SerializeValue(ar, "placement", ref placement);
		SerializeValue(ar, "splatLayer", ref splatLayer);
		var splatThreshold = 0.25f;
		SerializeValue(ar, "splatThreshold", ref splatThreshold);
		var maskPlane = (uint32)0;
		SerializeValue(ar, "maskPlane", ref maskPlane);
		var density = 2.0f;
		SerializeValue(ar, "density", ref density);
		var scaleRange = Float2(0.8f, 1.2f);
		ar.Key("scaleRange");
		Sedulous.Core.Serialization.Serialize(ar, ref scaleRange);
		var maxSlope = 35.0f;
		SerializeValue(ar, "maxSlopeDegrees", ref maxSlope);
		var heightRange = Float2(-1.0e6f, 1.0e6f);
		ar.Key("heightRange");
		Sedulous.Core.Serialization.Serialize(ar, ref heightRange);
		var alignToNormal = false;
		SerializeValue(ar, "alignToNormal", ref alignToNormal);
		var fadeStart = 40.0f;
		SerializeValue(ar, "fadeStart", ref fadeStart);
		var fadeEnd = 80.0f;
		SerializeValue(ar, "fadeEnd", ref fadeEnd);
		var castShadows = false;
		SerializeValue(ar, "castShadows", ref castShadows);
		var maxPerChunk = (uint32)4096;
		SerializeValue(ar, "maxInstancesPerChunk", ref maxPerChunk);
		var visible = true;
		SerializeValue(ar, "visible", ref visible);

		// A prop layer carried one placed instance; a procedural one carried an empty array.
		let instances = scope List<Float4x4>();
		if (placement == VegetationLayerV1.cPlacementScattered)
			instances.Add(Float4x4.Translation(.(3.0f, 2.0f, 4.0f)));
		ar.Key("instances");
		SerializeList(ar, instances);
	}
}
