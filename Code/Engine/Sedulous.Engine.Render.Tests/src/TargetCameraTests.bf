using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Render;
using Sedulous.RHI;
using Sedulous.RHI.Null;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Texture.Resource;

namespace Sedulous.Engine.Render.Tests;

/// A camera with a render texture target: never the screen camera, rendered at its texture's
/// aspect when active and on its interval, its target stored with the scene.
class TargetCameraTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-4f;

	/// A null device and the render texture products made on it, torn down together.
	private class Targets
	{
		public IBackend Backend ~ delete _;
		public IDevice Device;
		private List<Texture> mTextures = new .() ~ DeleteContainerAndItems!(_);

		public this()
		{
			Backend = NullRhi.CreateBackend();
			Device = Backend.EnumerateAdapters()[0].CreateDevice(.()).Value;
		}

		/// A live render texture product, the way the factory makes one.
		public Texture Make(uint32 width, uint32 height)
		{
			let gpu = Device.CreateTexture(TextureDesc.RenderTarget(.RGBA8UnormSrgb, width, height)).Value;
			let view = Device.CreateTextureView(gpu, .()).Value;
			let texture = new Texture();
			texture.Adopt(Device, gpu, view, null, width, height, .RGBA8UnormSrgb, false);
			mTextures.Add(texture);
			return texture;
		}
	}

	[Test]
	public static void ACameraWithATargetIsNeverTheScreenCameraPrimaryOrNot()
	{
		let targets = scope Targets();
		let scene = scope Scene("camera_target_pick");
		let cameras = scene.AddSystem<CameraComponentManager>();
		let minimap = scene.CreateEntity("minimap");
		scene.SetLocalPosition(minimap, .(0, 50, 0));
		cameras.Add(minimap).Target.SetDirect(targets.Make(64, 64)); // primary by default
		let player = scene.CreateEntity("player");
		scene.SetLocalPosition(player, .(0, 2, 0));
		cameras.Add(player);
		scene.UpdateTransforms();

		var view = ViewCamera();
		Test.Assert(RenderExtract.ExtractPrimaryCamera(scene, ref view));
		Test.Assert(Near(view.Position.Y, 2.0f), "the player's camera, though the minimap comes first");

		// An asset target that has not loaded still marks the camera as a target camera.
		var unloaded = CameraComponent();
		unloaded.Target.Id = Guid(0x1234, 0x5678, 0, 0, 0, 0, 0, 0, 0, 0, 0);
		Test.Assert(unloaded.HasTarget);
		Test.Assert(!CameraComponent().HasTarget);
	}

	[Test]
	public static void TargetCamerasRenderAtTheirTexturesAspectActiveAndOnTheirInterval()
	{
		let targets = scope Targets();
		let scene = scope Scene("camera_targets");
		let cameras = scene.AddSystem<CameraComponentManager>();

		let map = scene.CreateEntity("map");
		scene.SetLocalPosition(map, .(0, 40, 0));
		let mapCamera = cameras.Add(map);
		mapCamera.Projection = .Orthographic;
		mapCamera.OrthoHeight = 30.0f;
		mapCamera.ClearColor = .(0.0f, 0.5f, 0.0f, 1.0f);
		let mapTexture = targets.Make(200, 100);
		mapCamera.Target.SetDirect(mapTexture);

		let monitor = scene.CreateEntity("monitor");
		let monitorCamera = cameras.Add(monitor);
		let monitorTexture = targets.Make(64, 64);
		monitorCamera.Target.SetDirect(monitorTexture);
		monitorCamera.TargetInterval = 3;

		cameras.Add(scene.CreateEntity("screen")); // no target: the screen's camera, never collected
		scene.UpdateTransforms();

		let views = scope List<TargetCameraView>();
		RenderExtract.CollectTargetCameras(scene, 3, views); // frame three: both are due
		Test.Assert(views.Count == 2);
		Test.Assert((views[0].Target === mapTexture) && (views[1].Target === monitorTexture), "manager order, stable frame to frame");
		// The map renders orthographic at its texture's 2:1 aspect, from where its entity is.
		let expected = Float4x4.OrthographicRH(60.0f, 30.0f, mapCamera.NearZ, mapCamera.FarZ);
		for (int r < 4)
		{
			for (int c < 4)
				Test.Assert(Near(views[0].Camera.Camera.Projection.M[r][c], expected.M[r][c]));
		}
		Test.Assert(Near(views[0].Camera.Camera.Position.Y, 40.0f));
		Test.Assert(Near(views[0].Camera.ClearColor.G, 0.5f));

		RenderExtract.CollectTargetCameras(scene, 4, views); // the monitor draws every third frame only
		Test.Assert((views.Count == 1) && (views[0].Target === mapTexture));

		scene.SetActive(map, false);
		RenderExtract.CollectTargetCameras(scene, 6, views);
		Test.Assert((views.Count == 1) && (views[0].Target === monitorTexture));

		// A target whose texture is gone (a failed load) is skipped, not drawn into.
		monitorCamera.Target.SetDirect(null);
		RenderExtract.CollectTargetCameras(scene, 6, views);
		Test.Assert(views.IsEmpty);
	}

	[Test]
	public static void TheTargetAndItsIntervalRoundTripWithTheScene()
	{
		let texture = Guid(0xABCD, 0x1234, 0, 0, 0, 0, 0, 0, 0, 0, 0);
		let source = scope Scene("camera_target_written");
		let written = source.AddSystem<CameraComponentManager>().Add(source.CreateEntity("monitor"));
		written.Target.Id = texture;
		written.TargetInterval = 2;

		let stream = scope MemoryStream();
		{
			let writer = scope BinarySerializer(stream, .Write);
			SceneSerializer.SerializeScene(writer, source);
			Test.Assert(writer.IsOk);
		}
		stream.Seek(0, .Begin);
		let loaded = scope Scene("camera_target_read");
		let cameras = loaded.AddSystem<CameraComponentManager>();
		{
			let reader = scope BinarySerializer(stream, .Read);
			SceneSerializer.SerializeScene(reader, loaded);
			Test.Assert(reader.IsOk);
		}
		CameraComponent* read = null;
		cameras.ForEach(scope [&] (component, owner) => { read = component; });
		Test.Assert(read != null);
		Test.Assert(read.Target.Id == texture);
		Test.Assert(read.TargetInterval == 2);
	}

	/// A script points a camera at a render texture by id, as SetMesh points a mesh; a nil id
	/// gives the camera back to the screen, a texture assigned at run time included.
	[Test]
	public static void SetTargetPointsACameraAtATextureAndANilIdClearsIt()
	{
		let targets = scope Targets();
		let scene = scope Scene("camera_set_target");
		let cameras = scene.AddSystem<CameraComponentManager>();
		let entity = scene.CreateEntity("monitor");
		cameras.Add(entity);
		let texture = Guid(0x77, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
		Test.Assert(cameras.SetTarget(entity, texture));
		Test.Assert((cameras.Get(entity).Target.Id == texture) && cameras.Get(entity).HasTarget);

		cameras.Get(entity).Target.SetDirect(targets.Make(32, 32));
		Test.Assert(cameras.SetTarget(entity, .Empty));
		Test.Assert(!cameras.Get(entity).HasTarget, "the screen's camera again");
		Test.Assert(!cameras.SetTarget(scene.CreateEntity("no camera"), texture));
	}
}
