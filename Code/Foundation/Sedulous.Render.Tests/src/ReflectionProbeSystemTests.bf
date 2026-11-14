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
		listB[1].HalfExtents = .(2, 3, 4);
		listB[1].BlendDistance = 0.5f;
		listB[1].Intensity = 0.75f;
		listB[1].Priority = 7;
		listB[1].Parallax = false;

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

		// Each record holds its probe by name, as lighting.hlsli reads it (the box from the centre
		// and the half extents; the slice is the probe's slot in the array).
		Test.Assert(probes.CpuProbes.Length == 3);
		let record = probes.CpuProbes[2];
		Test.Assert(record.Center.X == 9.0f);
		Test.Assert(record.Intensity == 0.75f);
		Test.Assert(record.BoxMin.X == 7.0f);
		Test.Assert(record.BoxMin.Z == -4.0f);
		Test.Assert(record.BoxMax.Y == 4.0f);
		Test.Assert(record.BlendDistance == 0.5f);
		Test.Assert(record.Priority == 7.0f);
		Test.Assert(record.Parallax == 0.0f);
		Test.Assert(probes.CpuProbes[1].Parallax == 1.0f, "the default box projects");
		Test.Assert(record.MipCount > 0.0f);
		Test.Assert(record.Slice != probes.CpuProbes[1].Slice, "each probe its own cube");
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

	/// A static probe is captured once: from the next frame on it asks for no capture. A
	/// capture run again in each startup frame made every game's first seconds crawl on a
	/// phone.
	[Test]
	public static void AStaticProbeIsCapturedOnce()
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
			probes.MarkCaptured(task.Slot);

		probes.BeginFrame();
		probes.Assign(sceneA, .(&listA[0], 1));
		probes.Assign(sceneB, .(&listB[0], 2));
		Test.Assert(probes.Captures.IsEmpty);
		// And the ranges came back identical, the layout being rebuilt the same way.
		Test.Assert(probes.RangeFor(sceneB).Base == 1);

		// A capture request (a Manual probe's Capture()) recaptures that probe once, then it
		// is quiet again: Manual captured only at the start, with no way to ask again.
		listA[0].Update = .Manual;
		listA[0].CaptureRequest++;
		probes.BeginFrame();
		probes.Assign(sceneA, .(&listA[0], 1));
		probes.Assign(sceneB, .(&listB[0], 2));
		Test.Assert(probes.Captures.Length == 1);
		Test.Assert(probes.Captures[0].Scene == sceneA);
		probes.MarkCaptured(probes.Captures[0].Slot);
		probes.BeginFrame();
		probes.Assign(sceneA, .(&listA[0], 1));
		probes.Assign(sceneB, .(&listB[0], 2));
		Test.Assert(probes.Captures.IsEmpty);

		// Another resolution (a quality level's environment tier): the next frame remakes both
		// arrays at it, retiring the old ones, and every probe is captured again, once.
		let retire = scope GpuRetireQueue();
		retire.Initialize(fixture.Device, 2);
		probes.SetRetireQueue(retire);
		defer { retire.Flush(); probes.SetRetireQueue(null); }
		Test.Assert(probes.PrefilterArrayView.Texture.Desc.Width == 128);
		probes.SetResolution(64);
		probes.BeginFrame();
		probes.Assign(sceneA, .(&listA[0], 1));
		probes.Assign(sceneB, .(&listB[0], 2));
		Test.Assert(probes.PrefilterArrayView.Texture.Desc.Width == 64);
		Test.Assert(probes.CapturedSampleView.Texture.Desc.Width == 64);
		Test.Assert(probes.Resolution == 64);
		Test.Assert(retire.PendingCount == 4, "the two arrays and their two array views");
		Test.Assert(probes.Captures.Length == 3);
		for (let task in probes.Captures)
			probes.MarkCaptured(task.Slot);
		probes.BeginFrame();
		probes.Assign(sceneA, .(&listA[0], 1));
		probes.Assign(sceneB, .(&listB[0], 2));
		Test.Assert(probes.Captures.IsEmpty);
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
		let sliceA = probes.CpuProbes[0].Slice;
		let sliceB = probes.CpuProbes[1].Slice;

		// A second frame, with the probes given in the OTHER order.
		var swapped = ReflectionProbe[2](list[1], list[0]);
		probes.BeginFrame();
		probes.Assign(scene, .(&swapped[0], 2));

		// The slices follow the KEYS rather than the order they were handed over.
		Test.Assert(probes.CpuProbes[0].Slice == sliceB);
		Test.Assert(probes.CpuProbes[1].Slice == sliceA);
	}

	/// A slot goes back when its probe is gone. Slots were claimed for good, so once
	/// cMaxProbes keys had ever been seen (probes deleted and added in the editor, levels loaded
	/// one after another) every new probe was dropped.
	[Test]
	public static void TheSlotOfAProbeGoneGoesToTheNextProbe()
	{
		let fixture = scope RenderFrameFixture(64, 64);
		if (!fixture.Ready)
			return;

		let probes = scope ReflectionProbeSystem(fixture.Device, fixture.Shaders);
		Test.Assert(probes.Initialize() case .Ok);

		let max = ReflectionProbeSystem.cMaxProbes;
		let level = scope ExtractedScene();
		var first = ReflectionProbe[ReflectionProbeSystem.cMaxProbes]();
		for (uint32 i = 0; i < max; i++)
			first[i] = Probe(100 + i, .((float)i, 1, 0));

		probes.BeginFrame();
		probes.Assign(level, .(&first[0], (int)max));
		Test.Assert(probes.ActiveCount == max);
		for (let task in probes.Captures)
			probes.MarkCaptured(task.Slot);

		// While every slot holds a probe of this frame, one more has nowhere to go.
		let other = scope ExtractedScene();
		var extra = ReflectionProbe[1](Probe(999, .(0, 0, 0)));
		probes.BeginFrame();
		probes.Assign(level, .(&first[0], (int)max));
		probes.Assign(other, .(&extra[0], 1));
		Test.Assert(probes.RangeFor(other).Count == 0);

		// The probe in slot 3 is deleted: the next frame's new probe takes its slot and captures
		// into it; the others keep theirs and are not captured again.
		let freedSlice = probes.CpuProbes[3].Slice;
		first[3].Key = 500;
		probes.BeginFrame();
		probes.Assign(level, .(&first[0], (int)max));
		Test.Assert(probes.ActiveCount == max);
		Test.Assert(probes.CpuProbes[3].Slice == freedSlice);
		Test.Assert(probes.Captures.Length == 1);
		Test.Assert((float)probes.Captures[0].Slot == freedSlice);
		probes.MarkCaptured(probes.Captures[0].Slot);

		// A scene that stops drawing gives its slots up in the order its probes were last seen.
		probes.BeginFrame();
		probes.Assign(level, .(&first[0], (int)max - 1));
		probes.BeginFrame();
		probes.Assign(other, .(&extra[0], 1));
		Test.Assert(probes.ActiveCount == 1);
		Test.Assert(probes.CpuProbes[0].Slice == (float)(max - 1));
		Test.Assert(probes.Captures.Length == 1);
	}
}
