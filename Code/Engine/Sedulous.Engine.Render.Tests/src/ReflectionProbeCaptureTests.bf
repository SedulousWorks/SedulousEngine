using System;
using Sedulous.Core;
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
}
