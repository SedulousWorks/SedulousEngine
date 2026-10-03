using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Render;
using Sedulous.Scene;
using Sedulous.Scene.Resource;

namespace Sedulous.Engine.Render.Tests;

/// A camera's projection: perspective or orthographic, built in one place, extracted at the
/// view's aspect, stored with the scene, and read from a record written before it existed.
class CameraProjectionTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-4f;

	private static bool Near(Float4x4 a, Float4x4 b)
	{
		for (int r < 4)
		{
			for (int c < 4)
			{
				if (!Near(a.M[r][c], b.M[r][c]))
					return false;
			}
		}
		return true;
	}

	[Test]
	public static void MakeProjectionBuildsAPerspectiveOrAnOrthographicMatrix()
	{
		var camera = CameraComponent();
		camera.FovYRadians = 1.2f;
		camera.NearZ = 0.5f;
		camera.FarZ = 300.0f;
		camera.OrthoHeight = 40.0f;

		let perspective = camera.MakeProjection(2.0f);
		Test.Assert(Near(perspective, Float4x4.PerspectiveFovRH(1.2f, 2.0f, 0.5f, 300.0f)));
		Test.Assert(!perspective.IsOrthographic);

		camera.Projection = .Orthographic;
		let orthographic = camera.MakeProjection(2.0f);
		// The height is authored; the width follows the aspect.
		Test.Assert(Near(orthographic, Float4x4.OrthographicRH(80.0f, 40.0f, 0.5f, 300.0f)));
		Test.Assert(orthographic.IsOrthographic);
	}

	[Test]
	public static void AnOrthographicPrimaryCameraRendersOrthographicAtTheViewsAspect()
	{
		let scene = scope Scene("camera_ortho");
		let cameras = scene.AddSystem<CameraComponentManager>();
		let entity = scene.CreateEntity("top");
		let camera = cameras.Add(entity);
		camera.Projection = .Orthographic;
		camera.OrthoHeight = 20.0f;
		scene.UpdateTransforms();

		var view = ViewCamera();
		Test.Assert(RenderExtract.ExtractPrimaryCamera(scene, ref view, null, 1.5f));
		Test.Assert(view.Projection.IsOrthographic);
		Test.Assert(Near(view.Projection.M[0][0], 2.0f / 30.0f)); // the width is 20 x 1.5
		Test.Assert(Near(view.Projection.M[1][1], 2.0f / 20.0f));
	}

	[Test]
	public static void TheProjectionModeAndTheHeightRoundTripWithTheScene()
	{
		let source = scope Scene("camera_written");
		let written = source.AddSystem<CameraComponentManager>().Add(source.CreateEntity("map"));
		written.Projection = .Orthographic;
		written.OrthoHeight = 64.0f;

		let stream = scope MemoryStream();
		{
			let writer = scope BinarySerializer(stream, .Write);
			SceneSerializer.SerializeScene(writer, source);
			Test.Assert(writer.IsOk);
		}
		stream.Seek(0, .Begin);
		let loaded = scope Scene("camera_read");
		let cameras = loaded.AddSystem<CameraComponentManager>();
		{
			let reader = scope BinarySerializer(stream, .Read);
			SceneSerializer.SerializeScene(reader, loaded);
			Test.Assert(reader.IsOk);
		}
		CameraComponent* read = null;
		cameras.ForEach(scope [&] (component, owner) => { read = component; });
		Test.Assert(read != null);
		Test.Assert(read.Projection == .Orthographic);
		Test.Assert(Near(read.OrthoHeight, 64.0f));
	}

	/// A record written before the projection existed (version 1, the six lens fields) reads as
	/// the perspective camera it was, the new fields at their defaults.
	[Test]
	public static void AVersionOneRecordReadsAsAPerspectiveCamera()
	{
		let stream = scope MemoryStream();
		{
			let writer = scope BinarySerializer(stream, .Write);
			var fov = 0.9f;
			var aspect = 1.5f;
			var nearZ = 0.2f;
			var farZ = 500.0f;
			var clear = Color(0.1f, 0.2f, 0.3f, 1.0f);
			var primary = true;
			SerializeValue(writer, "fovYRadians", ref fov);
			SerializeValue(writer, "aspect", ref aspect);
			SerializeValue(writer, "nearZ", ref nearZ);
			SerializeValue(writer, "farZ", ref farZ);
			writer.Key("clearColor");
			Sedulous.Core.Serialization.Serialize(writer, ref clear);
			SerializeValue(writer, "primary", ref primary);
			var trailing = 77u;
			SerializeValue(writer, "trailing", ref trailing);
			Test.Assert(writer.IsOk);
		}
		stream.Seek(0, .Begin);
		let reader = scope BinarySerializer(stream, .Read);
		reader.PushVersionScope(scope SerializedDataVersion[](.(TypeIdOf("camera"), 1)));
		var camera = CameraComponent();
		camera.Projection = .Orthographic; // the reader must leave the defaults it was given
		camera.OrthoHeight = 3.0f;
		camera.Serialize(reader);
		reader.PopVersionScope();
		Test.Assert(reader.IsOk);
		Test.Assert(Near(camera.FovYRadians, 0.9f) && Near(camera.FarZ, 500.0f));
		Test.Assert(camera.Projection == .Orthographic && Near(camera.OrthoHeight, 3.0f), "a version one record carries no projection");
		// Nothing past the six fields was consumed.
		uint32 trailing = 0;
		SerializeValue(reader, "trailing", ref trailing);
		Test.Assert(trailing == 77);
	}
}
