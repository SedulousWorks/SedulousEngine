using System;
using Sedulous.Core;
using Sedulous.Render;

namespace Sedulous.Render.Tests;

/// The probe system's per scene record ranges and its capture queue.
class ReflectionProbeSystemTests
{
	private static ReflectionProbe Probe(uint64 key, Float3 center)
	{
		var probe = ReflectionProbe();
		probe.Key = key;
		probe.Center = center;
		return probe;
	}

	/// A frame can render several scenes, and each scene's probes land as a CONTIGUOUS RANGE
	/// in one record buffer. Assigning must not reset, or only the last scene's probes would
	/// be visible at all.
	[Test]
	public static void EachScenesProbesGetTheirOwnRange()
	{
		let fixture = scope RenderFrameFixture(64, 64);
		if (!fixture.Ready)
			return;

		let probes = scope ReflectionProbeSystem(fixture.Device, fixture.Shaders);
		Test.Assert(probes.Initialize() case .Ok);

		let sceneA = scope ExtractedScene();
		let sceneB = scope ExtractedScene();

		var listA = ReflectionProbe[1](Probe(1, .(0, 1, 0)));
		var listB = ReflectionProbe[2](Probe(2, .(5, 1, 0)), Probe(3, .(9, 1, 0)));

		probes.BeginFrame();
		probes.Assign(sceneA, .(&listA[0], 1));
		probes.Assign(sceneB, .(&listB[0], 2));
		// The SAME scene through a second view is a no op, not a second range.
		probes.Assign(sceneA, .(&listA[0], 1));

		Test.Assert(probes.ActiveCount == 3);
		Test.Assert(probes.RangeFor(sceneA).Base == 0);
		Test.Assert(probes.RangeFor(sceneA).Count == 1);
		Test.Assert(probes.RangeFor(sceneB).Base == 1);
		Test.Assert(probes.RangeFor(sceneB).Count == 2);

		let unknown = scope ExtractedScene();
		Test.Assert(probes.RangeFor(unknown).Count == 0);
	}

	/// A capture renders the probe's OWNING scene: a probe in one scene must never bake
	/// another's geometry.
	[Test]
	public static void ACaptureCarriesItsOwnScene()
	{
		let fixture = scope RenderFrameFixture(64, 64);
		if (!fixture.Ready)
			return;

		let probes = scope ReflectionProbeSystem(fixture.Device, fixture.Shaders);
		Test.Assert(probes.Initialize() case .Ok);

		let sceneA = scope ExtractedScene();
		let sceneB = scope ExtractedScene();

		var listA = ReflectionProbe[1](Probe(1, .(0, 1, 0)));
		var listB = ReflectionProbe[2](Probe(2, .(5, 1, 0)), Probe(3, .(9, 1, 0)));

		probes.BeginFrame();
		probes.Assign(sceneA, .(&listA[0], 1));
		probes.Assign(sceneB, .(&listB[0], 2));

		Test.Assert(probes.Captures.Length == 3);
		for (let task in probes.Captures)
			Test.Assert(task.Scene == ((task.Slot == 0) ? sceneA : sceneB));
	}

	/// A static probe stops asking to be captured once the startup window has drained.
	///
	/// The first frames deliberately recapture, so a dropped submission during startup cannot
	/// silently lose a one shot bake; it has to DRAIN, or a static probe would re-render its
	/// six faces forever.
	[Test]
	public static void TheStartupRecaptureWindowDrains()
	{
		let fixture = scope RenderFrameFixture(64, 64);
		if (!fixture.Ready)
			return;

		let probes = scope ReflectionProbeSystem(fixture.Device, fixture.Shaders);
		Test.Assert(probes.Initialize() case .Ok);

		let sceneA = scope ExtractedScene();
		let sceneB = scope ExtractedScene();
		var listA = ReflectionProbe[1](Probe(1, .(0, 1, 0)));
		var listB = ReflectionProbe[2](Probe(2, .(5, 1, 0)), Probe(3, .(9, 1, 0)));

		probes.BeginFrame();
		probes.Assign(sceneA, .(&listA[0], 1));
		probes.Assign(sceneB, .(&listB[0], 2));

		var frames = 0;
		for (; frames < 64; frames++)
		{
			for (let task in probes.Captures)
				probes.MarkCaptured(task.Slot);

			probes.BeginFrame();
			probes.Assign(sceneA, .(&listA[0], 1));
			probes.Assign(sceneB, .(&listB[0], 2));

			if (probes.Captures.IsEmpty)
				break;
		}

		// It recaptured for a while, and then went quiet.
		Test.Assert(frames > 0);
		Test.Assert(frames < 64);
		Test.Assert(probes.Captures.IsEmpty);
		// And the ranges came back identical, the layout being rebuilt the same way.
		Test.Assert(probes.RangeFor(sceneB).Base == 1);
	}

	/// A probe keeps its SLICE from frame to frame, keyed on its own tag, which is what lets a
	/// static one be captured once and cached.
	[Test]
	public static void AProbeKeepsItsSliceAcrossFrames()
	{
		let fixture = scope RenderFrameFixture(64, 64);
		if (!fixture.Ready)
			return;

		let probes = scope ReflectionProbeSystem(fixture.Device, fixture.Shaders);
		Test.Assert(probes.Initialize() case .Ok);

		let scene = scope ExtractedScene();
		var list = ReflectionProbe[2](Probe(7, .(0, 1, 0)), Probe(9, .(4, 1, 0)));

		probes.BeginFrame();
		probes.Assign(scene, .(&list[0], 2));
		let sliceA = probes.CpuProbes[0].BoxMax.W;
		let sliceB = probes.CpuProbes[1].BoxMax.W;

		// A second frame, with the probes given in the OTHER order.
		var swapped = ReflectionProbe[2](list[1], list[0]);
		probes.BeginFrame();
		probes.Assign(scene, .(&swapped[0], 2));

		// The slices follow the KEYS rather than the order they were handed over.
		Test.Assert(probes.CpuProbes[0].BoxMax.W == sliceB);
		Test.Assert(probes.CpuProbes[1].BoxMax.W == sliceA);
	}
}
