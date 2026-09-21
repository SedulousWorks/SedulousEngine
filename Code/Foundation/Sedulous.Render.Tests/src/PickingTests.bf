using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.RHI.Null;
using Sedulous.RenderGraph;
using Sedulous.Render;

namespace Sedulous.Render.Tests;

/// GPU picking, the device free half: the entity tag layout, the rect clamp, the projection
/// crop (a pixel of the full view maps to the centre of the cropped clip space, which is why a
/// click can render a 1x1 target), the readback decode, and the pick system's request state
/// machine on the Null device: request, declared, retired on the ring's round trip, taken once;
/// expiry when no view renders; cancel.
class PickingTests
{
	private static bool Near(float a, float b, float epsilon) => Math.Abs(a - b) <= epsilon;

	/// The pixel a world point lands on through the view projection in a w by h viewport, y
	/// down.
	private static void PixelOf(Float4x4 viewProj, Float3 world, uint32 w, uint32 h,
		out float px, out float py)
	{
		let clip = Float4(world.X, world.Y, world.Z, 1.0f) * viewProj;
		let ndcX = clip.X / clip.W;
		let ndcY = clip.Y / clip.W;
		px = (ndcX * 0.5f + 0.5f) * (float)w;
		py = (0.5f - ndcY * 0.5f) * (float)h;
	}

	[Test]
	public static void EntityTagPacksIndexLowGenerationHigh()
	{
		let tag = EntityTag.Pack(1234, 77);
		Test.Assert(EntityTag.Index(tag) == 1234);
		Test.Assert(EntityTag.Generation(tag) == 77);
		Test.Assert(EntityTag.Pack(0xFFFFFFFF, 0xFFFFFFFF) == 0xFFFFFFFFFFFFFFFF);
		Test.Assert(EntityTag.Index(EntityTag.Pack(0, 5)) == 0);
		Test.Assert(EntityTag.Generation(EntityTag.Pack(9, 0)) == 0);
	}

	[Test]
	public static void ClampRectKeepsTheInsidePart()
	{
		var inside = PickRect(10, 20, 5, 6);
		Test.Assert(PickSystem.ClampRect(ref inside, 100, 80));
		Test.Assert((inside.X == 10) && (inside.Y == 20) && (inside.Width == 5) && (inside.Height == 6));

		var straddling = PickRect(-3, 75, 10, 10); // over the left edge and the bottom edge
		Test.Assert(PickSystem.ClampRect(ref straddling, 100, 80));
		Test.Assert((straddling.X == 0) && (straddling.Y == 75));
		Test.Assert((straddling.Width == 7) && (straddling.Height == 5));

		var outside = PickRect(100, 0, 1, 1); // one past the right edge
		Test.Assert(!PickSystem.ClampRect(ref outside, 100, 80));
		var negative = PickRect(-5, -5, 5, 5);
		Test.Assert(!PickSystem.ClampRect(ref negative, 100, 80));
		var empty = PickRect(10, 10, 0, 4);
		Test.Assert(!PickSystem.ClampRect(ref empty, 100, 80));
		var noView = PickRect(0, 0, 1, 1);
		Test.Assert(!PickSystem.ClampRect(ref noView, 0, 0));
	}

	[Test]
	public static void CropProjectionMapsTheRectToClipSpaceDepthUntouched()
	{
		const uint32 cW = 640;
		const uint32 cH = 360;
		let view = Float4x4.LookAtRH(.(0, 0, 0), .(0, 0, -1), .(0, 1, 0));
		let proj = Float4x4.PerspectiveFovRH(1.0472f, 640.0f / 360.0f, 0.1f, 100.0f);
		let full = view * proj;

		// A world point off centre; find its pixel in the full view.
		let world = Float3(1.3f, -0.7f, -6.0f);
		PixelOf(full, world, cW, cH, let px, let py);
		Test.Assert((px > 0.0f) && (py > 0.0f) && (px < (float)cW) && (py < (float)cH));

		// Crop to the 1x1 rect of that pixel: the point lands inside the 1x1 target.
		let one = PickRect((int32)px, (int32)py, 1, 1);
		let cropped = view * PickSystem.CropProjectionToRect(proj, one, cW, cH);
		PixelOf(cropped, world, 1, 1, let cx, let cy);
		Test.Assert((cx >= 0.0f) && (cx < 1.0f) && (cy >= 0.0f) && (cy < 1.0f));

		// A wider rect: the point keeps its offset INSIDE the rect.
		let rect = PickRect((int32)px - 7, (int32)py - 3, 20, 12);
		let croppedRect = view * PickSystem.CropProjectionToRect(proj, rect, cW, cH);
		PixelOf(croppedRect, world, rect.Width, rect.Height, let rx, let ry);
		Test.Assert(Near(rx, px - (float)rect.X, 0.01f));
		Test.Assert(Near(ry, py - (float)rect.Y, 0.01f));

		// Depth is the same: z over w through both projections agree, so the pick's own depth
		// test ranks surfaces exactly as the view would.
		let clipFull = Float4(world.X, world.Y, world.Z, 1.0f) * full;
		let clipCrop = Float4(world.X, world.Y, world.Z, 1.0f) * croppedRect;
		Test.Assert(Near(clipCrop.Z / clipCrop.W, clipFull.Z / clipFull.W, 1e-5f));

		// The whole viewport as the rect is the identity crop.
		let all = PickRect(0, 0, cW, cH);
		let same = PickSystem.CropProjectionToRect(proj, all, cW, cH);
		for (int r < 4)
			for (int c < 4)
				Test.Assert(Near(same.M[r][c], proj.M[r][c], 1e-6f));
	}

	[Test]
	public static void DecodeTexelsDedupesSkipsBackgroundHonoursStride()
	{
		// 3x2 texels in 256 byte rows: (index + 1, generation) pairs.
		const uint32 cW = 3;
		const uint32 cH = 2;
		let stride = PickSystem.RowStride(cW);
		Test.Assert(stride == 256);
		Test.Assert(PickSystem.RowStride(32) == 256); // 32 * 8 is 256 exactly
		Test.Assert(PickSystem.RowStride(33) == 512);
		let bytes = scope uint8[stride * cH];
		void Put(uint32 x, uint32 y, uint32 indexPlusOne, uint32 gen)
		{
			let texel = (uint32*)(&bytes[(int)y * (int)stride + (int)x * 8]);
			texel[0] = indexPlusOne;
			texel[1] = gen;
		}
		Put(0, 0, 5, 1); // entity 4 gen 1
		Put(1, 0, 0, 9); // background, whatever y says
		Put(2, 0, 5, 1); // entity 4 again: deduped
		Put(0, 1, 1, 0); // entity 0 gen 0
		Put(1, 1, 5, 2); // entity 4 but a DIFFERENT generation: a distinct hit
		Put(2, 1, 0, 0);

		let hits = scope List<PickHit>();
		PickSystem.DecodeTexels(bytes.Ptr, cW, cH, stride, hits);
		Test.Assert(hits.Count == 3);
		Test.Assert((hits[0].EntityIndex == 4) && (hits[0].Generation == 1));
		Test.Assert((hits[1].EntityIndex == 0) && (hits[1].Generation == 0));
		Test.Assert((hits[2].EntityIndex == 4) && (hits[2].Generation == 2));

		PickSystem.DecodeTexels(null, cW, cH, stride, hits);
		Test.Assert(hits.IsEmpty);
	}

	[Test]
	public static void RequestDeclaredRetiredOnRoundTripTakenOnce()
	{
		let device = scope NullDevice();
		let pick = scope PickSystem(device);
		int viewportKey = 0;
		int otherKey = 0;

		let id = pick.Request(&viewportKey, .(10, 10, 1, 1));
		Test.Assert(id != PickSystem.cInvalidRequest);
		Test.Assert(pick.IsPending(id));
		Test.Assert(pick.PendingCount(&viewportKey) == 1);
		Test.Assert(pick.PendingCount(&otherKey) == 0);
		Test.Assert(pick.PendingTotal() == 1);
		let result = scope PickResult();
		Test.Assert(!pick.TryTakeResult(id, result));

		// Frame nought: the view declares a pick pass and a copy pass in the graph.
		let graph = scope RenderGraph(device);
		graph.BeginFrame(0);
		uint32 recorded = 0;
		PickRecordDelegate record = scope [&](pass, viewProj, rect, context) => { recorded++; };
		let view = Float4x4.Identity();
		let proj = Float4x4.PerspectiveFovRH(1.0f, 1.0f, 0.1f, 100.0f);
		pick.BeginFrame(0);
		// A view with ANOTHER key answers nothing.
		Test.Assert(pick.DeclarePasses(graph, &otherKey, view, proj, 100, 100, .Depth32Float, 0,
			record, null) == 0);
		Test.Assert(pick.PendingCount(&viewportKey) == 1);
		Test.Assert(pick.DeclarePasses(graph, &viewportKey, view, proj, 100, 100, .Depth32Float, 0,
			record, null) == 1);
		Test.Assert(recorded == 0); // declared, not executed: the graph never ran
		Test.Assert(pick.PendingCount(&viewportKey) == 0); // no longer waiting for a render
		Test.Assert(pick.IsPending(id)); // but not answered yet either
		Test.Assert(graph.PassCount >= 2); // the id pass and the readback copy
		graph.EndFrame();

		// Frame one, the other ring slot: still in flight. Frame nought again: retired and
		// decoded, the Null device's buffer mapping to zeros, so no hits, and rendered.
		pick.BeginFrame(1);
		Test.Assert(pick.IsPending(id));
		Test.Assert(!pick.TryTakeResult(id, result));
		pick.BeginFrame(0);
		Test.Assert(!pick.IsPending(id));
		Test.Assert(pick.TryTakeResult(id, result));
		Test.Assert(result.Id == id);
		Test.Assert(result.Rendered);
		Test.Assert(result.Hits.IsEmpty);
		Test.Assert(!pick.TryTakeResult(id, result)); // taken once
		Test.Assert(!pick.IsPending(id));
		device.WaitIdle();
	}

	[Test]
	public static void OutsideRectAnswersAtOnceExpiryCancel()
	{
		let device = scope NullDevice();
		let pick = scope PickSystem(device);
		int viewportKey = 0;
		let graph = scope RenderGraph(device);
		PickRecordDelegate record = scope (pass, viewProj, rect, context) => {};
		let view = Float4x4.Identity();
		let proj = Float4x4.PerspectiveFovRH(1.0f, 1.0f, 0.1f, 100.0f);
		let result = scope PickResult();

		// Outside: no pass, ready immediately, rendered, the view having considered it.
		let outside = pick.Request(&viewportKey, .(500, 500, 1, 1));
		graph.BeginFrame(0);
		pick.BeginFrame(0);
		Test.Assert(pick.DeclarePasses(graph, &viewportKey, view, proj, 100, 100, .Depth32Float, 0,
			record, null) == 0);
		graph.EndFrame();
		Test.Assert(pick.TryTakeResult(outside, result));
		Test.Assert(result.Rendered);
		Test.Assert(result.Hits.IsEmpty);

		// Expiry: a request whose view never renders completes as NOT rendered after the
		// window.
		let orphan = pick.Request(&viewportKey, .(1, 1, 1, 1));
		for (uint32 f = 0; f <= PickSystem.cExpireFrames; f++)
		{
			Test.Assert(!pick.TryTakeResult(orphan, result));
			pick.BeginFrame(f % 2);
		}
		Test.Assert(pick.TryTakeResult(orphan, result));
		Test.Assert(!result.Rendered);
		Test.Assert(result.Hits.IsEmpty);

		// Cancel: a waiting request vanishes; the ids never answer.
		let a = pick.Request(&viewportKey, .(1, 1, 1, 1));
		let b = pick.Request(&viewportKey, .(2, 2, 3, 3));
		Test.Assert(pick.PendingCount(&viewportKey) == 2);
		pick.Cancel(&viewportKey);
		Test.Assert(pick.PendingCount(&viewportKey) == 0);
		Test.Assert(!pick.IsPending(a));
		Test.Assert(!pick.IsPending(b));
		Test.Assert(!pick.TryTakeResult(a, result));
		Test.Assert(!pick.TryTakeResult(b, result));

		// Cancel of an in flight readback: it still retires, its result discarded.
		let c = pick.Request(&viewportKey, .(1, 1, 1, 1));
		graph.BeginFrame(0);
		pick.BeginFrame(0);
		Test.Assert(pick.DeclarePasses(graph, &viewportKey, view, proj, 100, 100, .Depth32Float, 0,
			record, null) == 1);
		graph.EndFrame();
		pick.Cancel(&viewportKey);
		Test.Assert(!pick.IsPending(c));
		pick.BeginFrame(1);
		pick.BeginFrame(0);
		Test.Assert(!pick.TryTakeResult(c, result));
		Test.Assert(pick.PendingTotal() == 0);
		device.WaitIdle();
	}
}
