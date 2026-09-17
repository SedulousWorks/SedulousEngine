using System;
using Sedulous.Core;
using Sedulous.RHI.TestSupport;
using Sedulous.VG;

namespace Sedulous.VG.Backend.Tests;

/// Deterministic vector scenes on a REAL device, read back and asserted STRUCTURALLY: the
/// fill rules, stencil path clipping, the colour pipelines agreeing, gradient spreads, the
/// blend modes, and what multisampling does to a hard edge.
///
/// Semantic probes rather than stored image comparisons, so there is no drift between drivers
/// or cards, and each assertion names the property it guards rather than "it changed".
class VGPixelProbeTests
{
	private const uint32 cSize = VGSceneRenderer.Size;

	private static Color ByteColor(uint8 r, uint8 g, uint8 b) => VGSceneRenderer.ByteColor(r, g, b);

	[Test]
	public static void FillRulesAndStencilClipsHold()
	{
		// Both backends: the fill rules and the stencil clip is configured per backend, so one passing says nothing
		// about the other.
		for (let kind in scope ProbeBackend[](.Vulkan, .WebGpu))
			FillRulesAndStencilClipsHoldOn(kind);
	}

	private static void FillRulesAndStencilClipsHoldOn(ProbeBackend kind)
	{
		let fixture = scope VGProbeFixture(kind);
		if (!fixture.Ready)
			return;

		let image = VGSceneRenderer.RenderScene(fixture, scope (context) =>
			{
				// An even odd donut: the ring fills, the core stays open.
				let donut = scope PathBuilder();
				ShapeBuilder.BuildCircle(.(32.0f, 64.0f), 28.0f, donut);
				ShapeBuilder.BuildCircle(.(32.0f, 64.0f), 12.0f, donut);
				let donutPath = donut.ToPath();
				defer delete donutPath;
				context.FillPath(donutPath, ByteColor(255, 160, 60), .EvenOdd, false);

				// Stripes under a star shaped clip: only what is inside the star survives.
				context.PushState();
				context.Translate(96.0f, 64.0f);

				let star = scope PathBuilder();
				ShapeBuilder.BuildStar(.(0.0f, 0.0f), 30.0f, 12.0f, 5, star);
				let starPath = star.ToPath();
				defer delete starPath;
				context.PushClipPath(starPath);

				for (int32 i = -4; i <= 4; i++)
				{
					let stripe = scope:: PathBuilder();
					let y = (float)i * 8.0f - 2.0f;
					stripe.MoveTo(-32.0f, y);
					stripe.LineTo(32.0f, y);
					stripe.LineTo(32.0f, y + 4.0f);
					stripe.LineTo(-32.0f, y + 4.0f);
					stripe.Close();

					let stripePath = stripe.ToPath();
					defer:: delete stripePath;
					context.FillPath(stripePath, ByteColor(240, 200, 60), .NonZero, false);
				}

				context.PopClipPath();
				context.PopState();
			});

		defer delete image;
		Test.Assert((image != null) && image.Valid, "the scene rendered");

		// Inside the ring band.
		Test.Assert(image.At(32 + 20, 64)[0] > 200, "the ring filled");
		// The even odd core is OPEN, so the background shows through.
		Test.Assert(image.At(32, 64)[0] < 40, "the core stayed open");
		// Inside the star, where a stripe crosses.
		Test.Assert(image.At(96, 64)[0] > 180, "the clip let the stripes through");
		// On a stripe's row but OUTSIDE the star.
		Test.Assert(image.At(96 + 31, 64 - 31)[0] < 40, "and clipped them everywhere else");
	}

	[Test]
	public static void TheColourPipelinesAgreeAndSpreadsRepeat()
	{
		// Both backends: the colour pipelines and the spreads is configured per backend, so one passing says nothing
		// about the other.
		for (let kind in scope ProbeBackend[](.Vulkan, .WebGpu))
			TheColourPipelinesAgreeAndSpreadsRepeatOn(kind);
	}

	private static void TheColourPipelinesAgreeAndSpreadsRepeatOn(ProbeBackend kind)
	{
		let fixture = scope VGProbeFixture(kind);
		if (!fixture.Ready)
			return;

		let image = VGSceneRenderer.RenderScene(fixture, scope (context) =>
			{
				// A solid and a same colour two stop gradient, butted together: the seam is
				// the test. One decodes through the vertex colour, the other through the
				// ramp, and the two have to land on the same value.
				let solid = scope PathBuilder();
				solid.MoveTo(0, 0);
				solid.LineTo(32, 0);
				solid.LineTo(32, 40);
				solid.LineTo(0, 40);
				solid.Close();
				let solidPath = solid.ToPath();
				defer delete solidPath;
				context.FillPath(solidPath, ByteColor(180, 60, 40), .NonZero, false);

				let flat = scope VGLinearGradientFill(.(32.0f, 0.0f), .(64.0f, 0.0f));
				flat.AddStop(0.0f, ByteColor(180, 60, 40));
				flat.AddStop(1.0f, ByteColor(180, 60, 40));

				let gradient = scope PathBuilder();
				gradient.MoveTo(32, 0);
				gradient.LineTo(64, 0);
				gradient.LineTo(64, 40);
				gradient.LineTo(32, 40);
				gradient.Close();
				let gradientPath = gradient.ToPath();
				defer delete gradientPath;
				context.FillPath(gradientPath, flat, .NonZero, false);

				// A red to blue ramp over a third of the band, REPEATED: it should read red
				// again where the second period starts.
				let @repeat = scope VGLinearGradientFill(.(0.0f, 0.0f), .(32.0f, 0.0f));
				@repeat.AddStop(0.0f, ByteColor(220, 40, 40));
				@repeat.AddStop(1.0f, ByteColor(40, 40, 220));
				@repeat.Spread = .Repeat;

				let band = scope PathBuilder();
				band.MoveTo(0, 80);
				band.LineTo(96, 80);
				band.LineTo(96, 120);
				band.LineTo(0, 120);
				band.Close();
				let bandPath = band.ToPath();
				defer delete bandPath;
				context.FillPath(bandPath, @repeat, .NonZero, false);
			});

		defer delete image;
		Test.Assert((image != null) && image.Valid, "the scene rendered");

		let solid = image.At(16, 20);
		let gradient = image.At(48, 20);
		Test.Assert(Math.Abs((int32)solid[0] - (int32)gradient[0]) <= 2, "red agrees");
		Test.Assert(Math.Abs((int32)solid[1] - (int32)gradient[1]) <= 2, "green agrees");
		Test.Assert(Math.Abs((int32)solid[2] - (int32)gradient[2]) <= 2, "blue agrees");
		// And both are the colour that was actually authored.
		Test.Assert(Math.Abs((int32)solid[0] - 180) <= 2, "and it is the authored colour");

		let periodStart = image.At(4, 100);
		let periodEnd = image.At(30, 100);
		let secondPeriod = image.At(36, 100);
		Test.Assert(periodStart[0] > periodStart[2], "the first period starts red");
		Test.Assert(periodEnd[2] > periodEnd[0], "and ends blue");
		Test.Assert(secondPeriod[0] > secondPeriod[2], "then repeats back to red");
	}

	[Test]
	public static void TheBlendModesActOverALightStrip()
	{
		// Both backends: the blend modes is configured per backend, so one passing says nothing
		// about the other.
		for (let kind in scope ProbeBackend[](.Vulkan, .WebGpu))
			TheBlendModesActOverALightStripOn(kind);
	}

	private static void TheBlendModesActOverALightStripOn(ProbeBackend kind)
	{
		let fixture = scope VGProbeFixture(kind);
		if (!fixture.Ready)
			return;

		let image = VGSceneRenderer.RenderScene(fixture, scope (context) =>
			{
				let strip = scope PathBuilder();
				strip.MoveTo(0, 48);
				strip.LineTo(128, 48);
				strip.LineTo(128, 80);
				strip.LineTo(0, 80);
				strip.Close();
				let stripPath = strip.ToPath();
				defer delete stripPath;
				context.FillPath(stripPath, ByteColor(220, 220, 225), .NonZero, false);

				for (let entry in scope (float x, VGBlendMode mode)[3](
					(20.0f, .Additive), (60.0f, .Multiply), (100.0f, .Normal)))
				{
					context.SetBlendMode(entry.mode);

					let circle = scope:: PathBuilder();
					ShapeBuilder.BuildCircle(.(entry.x, 64.0f), 14.0f, circle);
					let circlePath = circle.ToPath();
					defer:: delete circlePath;
					context.FillPath(circlePath, ByteColor(180, 60, 40), .NonZero, false);

					context.SetBlendMode(.Normal);
				}
			});

		defer delete image;
		Test.Assert((image != null) && image.Valid, "the scene rendered");

		let strip = image.At(40, 64);
		let additive = image.At(20, 64);
		let multiply = image.At(60, 64);
		let normal = image.At(100, 64);

		Test.Assert(additive[0] >= 250, "adding clips the red channel");
		Test.Assert((int32)multiply[1] < (int32)strip[1] - 40, "multiplying darkens the strip");
		Test.Assert(Math.Abs((int32)normal[0] - 180) <= 2, "and normal is the authored red");
		Test.Assert(Math.Abs((int32)normal[1] - 60) <= 2, "and its green");
	}

	[Test]
	public static void MultisamplingSoftensAHardDiagonal()
	{
		// Both backends: the multisample resolve is configured per backend, so one passing says nothing
		// about the other.
		for (let kind in scope ProbeBackend[](.Vulkan, .WebGpu))
			MultisamplingSoftensAHardDiagonalOn(kind);
	}

	private static void MultisamplingSoftensAHardDiagonalOn(ProbeBackend kind)
	{
		// A stencil then cover fill has HARD edges: there are no analytic fringes, so what
		// smooths an edge is the multisample resolve and nothing else. A diagonal must alias
		// at one sample, every pixel wholly background or wholly fill, and antialias at four.
		let fixture = scope VGProbeFixture(kind);
		if (!fixture.Ready)
			return;

		delegate void(VGContext) diagonal = scope (context) =>
			{
				let triangle = scope PathBuilder();
				triangle.MoveTo(10, 10);
				triangle.LineTo(110, 10);
				triangle.LineTo(10, 110);
				triangle.Close();
				let path = triangle.ToPath();
				defer delete path;
				context.FillPath(path, ByteColor(180, 60, 40), .NonZero, false);
			};

		let aliased = VGSceneRenderer.RenderScene(fixture, diagonal, 1);
		defer delete aliased;
		let smooth = VGSceneRenderer.RenderScene(fixture, diagonal, 4);
		defer delete smooth;

		Test.Assert((aliased != null) && aliased.Valid, "the aliased scene rendered");
		Test.Assert((smooth != null) && smooth.Valid, "the multisampled one too");

		// The interior keeps the authored colour exactly through the resolve.
		Test.Assert(Math.Abs((int32)smooth.At(20, 20)[0] - 180) <= 2, "the interior is untouched");
		Test.Assert(Math.Abs((int32)smooth.At(20, 20)[1] - 60) <= 2, "in green too");

		Test.Assert(CountIntermediate(aliased) == 0, "one sample leaves a hard edge");
		Test.Assert(CountIntermediate(smooth) >= 30, "four samples soften it");
	}

	/// The in between reds across the hypotenuse: every column from 30 to 90 crosses it once.
	/// The fill is 180 and the background nought.
	private static int CountIntermediate(CapturedImage image)
	{
		var count = 0;
		for (uint32 x = 30; x <= 90; x++)
		{
			for (uint32 y = 10; y <= 110; y++)
			{
				let r = image.At(x, y)[0];
				if ((r > 15) && (r < 165))
					count++;
			}
		}
		return count;
	}
}
