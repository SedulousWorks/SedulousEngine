using System;
using Sedulous.Core;
using Sedulous.Geometry;
using Sedulous.Render;
using Sedulous.Scene;

namespace Sedulous.Engine.Render.Tests;

/// The effectively active gate, which every extraction loop consults.
class ActiveGateTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-3f;

	private static void ExtractAll(Scene scene, ExtractedScene outScene)
	{
		RenderExtract.ExtractSceneInto(scene, outScene);
		RenderExtract.ExtractInstancedMeshesInto(scene, outScene);
		RenderExtract.ExtractSpritesInto(scene, outScene, 1);
		RenderExtract.ExtractLightsInto(scene, outScene);
		RenderExtract.ExtractReflectionProbesInto(scene, outScene);
	}

	/// ONE gate per loop, driven by the effective active cache, so an inactive PARENT hides a
	/// child's renderables without touching the child's own flag.
	[Test]
	public static void AnInactiveParentHidesTheWholeSubtree()
	{
		let scene = scope Scene("active-gate");
		let meshes = scene.AddSystem<MeshComponentManager>();
		let sets = scene.AddSystem<InstancedMeshComponentManager>();
		scene.AddSystem<SpriteComponentManager>();
		let lights = scene.AddSystem<LightComponentManager>();
		let probes = scene.AddSystem<ReflectionProbeComponentManager>();

		let mesh = Primitives.Cube(1.0f);
		defer delete mesh;

		let parent = scene.CreateEntity("parent");
		meshes.Add(parent).Mesh.SetDirect(mesh);

		let child = scene.CreateEntity("child");
		scene.SetParent(child, parent);
		{
			let component = sets.Add(child);
			component.Mesh.SetDirect(mesh);
		}
		lights.Add(child);
		probes.Add(child);

		let bystander = scene.CreateEntity("bystander");
		meshes.Add(bystander).Mesh.SetDirect(mesh);

		scene.UpdateTransforms();

		{
			let all = scope ExtractedScene();
			ExtractAll(scene, all);
			// The parent's mesh, the child's set and the bystander.
			Test.Assert(all.Size == 3);
			Test.Assert(all.Lights.Length == 1);
			Test.Assert(all.ReflectionProbes.Length == 1);
		}

		// Deactivate the PARENT: the whole subtree goes dark, and the flags below are
		// untouched.
		scene.SetActive(parent, false);
		{
			let dark = scope ExtractedScene();
			ExtractAll(scene, dark);
			// Only the bystander survives.
			Test.Assert(dark.Size == 1);
			Test.Assert(dark.Lights.Length == 0);
			Test.Assert(dark.ReflectionProbes.Length == 0);
			Test.Assert(scene.IsActive(child));
		}

		// Reactivate, and everything returns exactly.
		scene.SetActive(parent, true);
		{
			let restored = scope ExtractedScene();
			ExtractAll(scene, restored);
			Test.Assert(restored.Size == 3);
			Test.Assert(restored.Lights.Length == 1);
			Test.Assert(restored.ReflectionProbes.Length == 1);
		}
	}

	/// The primary camera search skips INACTIVE entities rather than stopping at the first
	/// one that claims to be primary.
	[Test]
	public static void AnInactivePrimaryCameraFallsThroughToTheNext()
	{
		let scene = scope Scene("cam-fallthrough");
		let cameras = scene.AddSystem<CameraComponentManager>();

		let first = scene.CreateEntity("first");
		scene.SetLocalPosition(first, .(0, 0, 5));
		// Primary by default.
		cameras.Add(first).Aspect = 1.0f;

		let second = scene.CreateEntity("second");
		scene.SetLocalPosition(second, .(0, 0, 9));
		cameras.Add(second).Aspect = 1.0f;

		scene.UpdateTransforms();

		var view = ViewCamera();
		Test.Assert(RenderExtract.ExtractPrimaryCamera(scene, ref view));
		// Manager order: the first wins while it is active.
		Test.Assert(Near(view.Position.Z, 5.0f));

		scene.SetActive(first, false);
		Test.Assert(RenderExtract.ExtractPrimaryCamera(scene, ref view));
		Test.Assert(Near(view.Position.Z, 9.0f));

		scene.SetActive(second, false);
		// No active primary at all.
		Test.Assert(!RenderExtract.ExtractPrimaryCamera(scene, ref view));
	}
}
