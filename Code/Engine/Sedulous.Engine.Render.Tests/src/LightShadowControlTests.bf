using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Render;
using Sedulous.Scene;
using Sedulous.Scene.Resource;

namespace Sedulous.Engine.Render.Tests;

/// A light's shadow controls: extracted onto the shadow it casts, stored with the scene, and
/// read at their defaults from a record written before they existed.
class LightShadowControlTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) < 1e-6f;

	[Test]
	public static void ALightsShadowControlsReachTheShadowItCasts()
	{
		let scene = scope Scene("shadows");
		let lights = scene.AddSystem<LightComponentManager>();
		let sun = lights.Add(scene.CreateEntity("sun"));
		sun.CastsShadows = true;
		sun.ShadowNormalBias = 1.5f;
		sun.ShadowDepthBiasScale = 2.0f;
		sun.ShadowStrength = 0.4f;
		let spot = lights.Add(scene.CreateEntity("spot"));
		spot.Type = .Spot;
		spot.CastsShadows = true;
		spot.ShadowNormalBias = 0.5f;
		spot.ShadowDepthBiasScale = 3.0f;
		scene.UpdateTransforms();

		let snapshot = scope ExtractedScene();
		RenderExtract.ExtractLightsInto(scene, snapshot);
		let directional = snapshot.DirectionalShadowData;
		Test.Assert(directional.Valid);
		Test.Assert(Near(directional.NormalBias, 1.5f));
		Test.Assert(Near(directional.DepthBias, ShadowBiasDefaults.DepthBias * 2.0f), "a scale of the default");
		Test.Assert(Near(directional.Strength, 0.4f));
		Test.Assert(snapshot.Lights.Length == 2);
		Test.Assert(Near(snapshot.Lights[0].ShadowStrength, 0.4f), "the forward shader's per light lerp");
		Test.Assert(Near(snapshot.Lights[1].ShadowStrength, 1.0f), "the default: a full shadow");
		Test.Assert(snapshot.LocalShadowCasters.Length == 1);
		let caster = snapshot.LocalShadowCasters[0];
		Test.Assert(Near(caster.NormalBias, 0.5f));
		Test.Assert(Near(caster.DepthBias, ShadowBiasDefaults.LocalDepthBias * 3.0f));

		// A built atlas entry carries them: the depth bias as it is, the normal offset as world
		// units per unit of distance (its texels times the tile's texel size at distance one).
		let entry = ShadowMath.BuildSpotShadow(caster, 0, 2048, 512);
		Test.Assert(Near(entry.DepthBias, ShadowBiasDefaults.LocalDepthBias * 3.0f));
		let fov = Math.Min(spot.OuterAngle * 2.0f + 0.05f, 3.0f);
		Test.Assert(Math.Abs(entry.NormalBiasPerDistance - 0.5f * 2.0f * Math.Tan(fov * 0.5f) / 512.0f) < 1e-6f);
	}

	[Test]
	public static void TheShadowControlsRoundTripWithTheScene()
	{
		let source = scope Scene("light_written");
		let written = source.AddSystem<LightComponentManager>().Add(source.CreateEntity("sun"));
		written.ShadowNormalBias = 0.75f;
		written.ShadowDepthBiasScale = 1.5f;
		written.ShadowStrength = 0.25f;

		let stream = scope MemoryStream();
		{
			let writer = scope BinarySerializer(stream, .Write);
			SceneSerializer.SerializeScene(writer, source);
			Test.Assert(writer.IsOk);
		}
		stream.Seek(0, .Begin);
		let loaded = scope Scene("light_read");
		let lights = loaded.AddSystem<LightComponentManager>();
		{
			let reader = scope BinarySerializer(stream, .Read);
			SceneSerializer.SerializeScene(reader, loaded);
			Test.Assert(reader.IsOk);
		}
		LightComponent* read = null;
		lights.ForEach(scope [&] (component, owner) => { read = component; });
		Test.Assert(read != null);
		Test.Assert(Near(read.ShadowNormalBias, 0.75f));
		Test.Assert(Near(read.ShadowDepthBiasScale, 1.5f));
		Test.Assert(Near(read.ShadowStrength, 0.25f));
	}

	/// A record written before the shadow controls (version 1) reads with them at their
	/// defaults, which are what it rendered with, and consumes nothing past its own fields.
	[Test]
	public static void AVersionOneRecordReadsTheShadowControlsDefaults()
	{
		let stream = scope MemoryStream();
		{
			let writer = scope BinarySerializer(stream, .Write);
			var v1 = LightComponent();
			v1.CastsShadows = true;
			v1.Intensity = 3.0f;
			// The version one fields, in their order: the current body up to castsShadows.
			var type = (uint32)v1.Type;
			SerializeValue(writer, "type", ref type);
			writer.Key("color");
			Sedulous.Core.Serialization.Serialize(writer, ref v1.Color);
			SerializeValue(writer, "intensity", ref v1.Intensity);
			SerializeValue(writer, "range", ref v1.Range);
			SerializeValue(writer, "innerAngle", ref v1.InnerAngle);
			SerializeValue(writer, "outerAngle", ref v1.OuterAngle);
			var shadowUpdate = (uint32)v1.ShadowUpdate;
			SerializeValue(writer, "shadowUpdate", ref shadowUpdate);
			SerializeValue(writer, "enabled", ref v1.Enabled);
			SerializeValue(writer, "castsShadows", ref v1.CastsShadows);
			var trailing = 77u;
			SerializeValue(writer, "trailing", ref trailing);
			Test.Assert(writer.IsOk);
		}
		stream.Seek(0, .Begin);
		let reader = scope BinarySerializer(stream, .Read);
		reader.PushVersionScope(scope SerializedDataVersion[](.(TypeIdOf("light"), 1)));
		var light = LightComponent();
		light.Serialize(reader);
		reader.PopVersionScope();
		Test.Assert(reader.IsOk);
		Test.Assert(light.CastsShadows && Near(light.Intensity, 3.0f));
		Test.Assert(Near(light.ShadowStrength, 1.0f));
		Test.Assert(Near(light.ShadowNormalBias, ShadowBiasDefaults.NormalBias));
		Test.Assert(Near(light.ShadowDepthBiasScale, 1.0f));
		uint32 trailing = 0;
		SerializeValue(reader, "trailing", ref trailing);
		Test.Assert(trailing == 77, "nothing past the version one fields was consumed");
	}
}
