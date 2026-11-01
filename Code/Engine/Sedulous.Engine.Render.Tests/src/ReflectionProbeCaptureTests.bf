using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Render;
using Sedulous.Scene;

namespace Sedulous.Engine.Render.Tests;

/// A script asks a probe to capture with Capture(); the request count rides the extracted probe
/// to the probe system, which recaptures on a count it has not seen.
class ReflectionProbeCaptureTests
{
	[Test]
	public static void ACaptureRequestReachesTheExtractedProbe()
	{
		let scene = scope Scene("probe-capture");
		let probes = scene.AddSystem<ReflectionProbeComponentManager>();
		let entity = scene.CreateEntity("probe");
		let probe = probes.Add(entity);
		probe.Update = .Manual;
		scene.UpdateTransforms();

		let before = scope ExtractedScene();
		RenderExtract.ExtractReflectionProbesInto(scene, before);
		Test.Assert(before.ReflectionProbes.Length == 1);
		probe.Capture();
		let after = scope ExtractedScene();
		RenderExtract.ExtractReflectionProbesInto(scene, after);
		Test.Assert(after.ReflectionProbes.Length == 1);
		Test.Assert(after.ReflectionProbes[0].CaptureRequest != before.ReflectionProbes[0].CaptureRequest);
	}

	/// A version 1 probe stored a per-probe resolution between intensity and priority; version 2
	/// has none. It loads through the manager, which accepts version 1 as well as the current one,
	/// and the fields after the resolution land where they belong, with nothing past them read.
	[Test]
	public static void AVersionOneProbeReadsItsResolutionDropped()
	{
		let stream = scope MemoryStream();
		{
			let writer = scope BinarySerializer(stream, .Write);
			BeginVersionedPayload(writer, TypeIdOf("reflection_probe"), 1);
			writer.Key("halfExtents");
			var halfExtents = Float3(3.0f, 2.0f, 4.0f);
			Serialize(writer, ref halfExtents);
			var blendDistance = 0.5f;
			SerializeValue(writer, "blendDistance", ref blendDistance);
			var intensity = 1.5f;
			SerializeValue(writer, "intensity", ref intensity);
			uint32 resolution = 256;
			SerializeValue(writer, "resolution", ref resolution);
			uint32 priority = 7;
			SerializeValue(writer, "priority", ref priority);
			var update = (uint32)ProbeUpdateMode.Manual;
			SerializeValue(writer, "update", ref update);
			var parallax = false;
			SerializeValue(writer, "parallax", ref parallax);
			var enabled = true;
			SerializeValue(writer, "enabled", ref enabled);
			EndVersionedPayload(writer);
			uint32 trailing = 77;
			SerializeValue(writer, "trailing", ref trailing);
			Test.Assert(writer.IsOk);
		}

		let scene = scope Scene("probe-v1");
		let probes = scene.AddSystem<ReflectionProbeComponentManager>();
		let entity = scene.CreateEntity("probe");
		stream.Seek(0, .Begin);
		let reader = scope BinarySerializer(stream, .Read);
		probes.ReadComponent(reader, entity);
		uint32 trailing = 0;
		SerializeValue(reader, "trailing", ref trailing);
		Test.Assert(reader.IsOk, "a version 1 record loads");
		let probe = probes.Get(entity);
		Test.Assert(probe.HalfExtents.Z == 4.0f);
		Test.Assert(probe.Intensity == 1.5f);
		Test.Assert(probe.Priority == 7);
		Test.Assert(probe.Update == .Manual);
		Test.Assert(!probe.Parallax);
		Test.Assert(trailing == 77, "nothing past the version 1 fields was consumed");
	}
}
