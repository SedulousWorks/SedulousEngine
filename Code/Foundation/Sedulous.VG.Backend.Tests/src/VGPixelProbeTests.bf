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
		// Every backend: the fill rules and the stencil clip is configured per backend, so one passing says nothing
		// about the other.
		for (let kind in scope ProbeBackend[](.Vulkan, .WebGpu, .Dx12))
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
		// Every backend: the colour pipelines and the spreads is configured per backend, so one passing says nothing
		// about the other.
		for (let kind in scope ProbeBackend[](.Vulkan, .WebGpu, .Dx12))
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
		// Every backend: the blend modes is configured per backend, so one passing says nothing
		// about the other.
		for (let kind in scope ProbeBackend[](.Vulkan, .WebGpu, .Dx12))
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

	/// The same scene in a Linear and an Encoded canvas. Linear blends linear light (half black
	/// over white is 73% grey, byte 188); Encoded blends the encoded values as browsers do (50%
	/// grey, byte 128). A gradient's ramp is baked from the authored stops, so it runs as
	/// authored in both (its middle is byte 128) once Encoded re-encodes what it samples, and a
	/// solid colour reads as authored in both.
	[Test]
	public static void AnEncodedCanvasBlendsEncodedValuesALinearOneLinearLight()
	{
		for (let kind in scope ProbeBackend[](.Vulkan, .WebGpu, .Dx12))
			BlendSpacesOn(kind);
	}

	private struct BlendSpaceReadings
	{
		public int HalfBlack;   // half transparent black over white
		public int GradientMid; // a black to white gradient's middle
		public int[3] Solid;
	}

	private static void BlendSpacesOn(ProbeBackend kind)
	{
		let fixture = scope VGProbeFixture(kind);
		if (!fixture.Ready)
			return;

		let linear = ReadBlendSpace(fixture, .Linear);
		let encoded = ReadBlendSpace(fixture, .Encoded);
		let name = kind.ToString(.. scope .());
		Test.Assert(Math.Abs(linear.HalfBlack - 188) <= 2, scope $"{name} linear: half black over white read {linear.HalfBlack}");
		Test.Assert(Math.Abs(encoded.HalfBlack - 128) <= 2, scope $"{name} encoded: half black over white read {encoded.HalfBlack}");
		Test.Assert(Math.Abs(linear.GradientMid - 128) <= 6, scope $"{name} linear: the gradient's middle read {linear.GradientMid}");
		Test.Assert(Math.Abs(encoded.GradientMid - 128) <= 6, scope $"{name} encoded: the gradient's middle read {encoded.GradientMid}");
		int[3] authored = .(180, 60, 40);
		for (int c < 3)
		{
			Test.Assert(Math.Abs(linear.Solid[c] - authored[c]) <= 2, scope $"{name} linear: a solid colour as authored");
			Test.Assert(Math.Abs(encoded.Solid[c] - authored[c]) <= 2, scope $"{name} encoded: a solid colour as authored");
		}
	}

	private static BlendSpaceReadings ReadBlendSpace(VGProbeFixture fixture, VGBlendSpace space)
	{
		let image = VGSceneRenderer.RenderScene(fixture, scope (context) =>
			{
				let white = Rect(0, 0, 128, 40);
				defer delete white;
				context.FillPath(white, ByteColor(255, 255, 255), .NonZero, false);
				context.FillPath(white, Color(0.0f, 0.0f, 0.0f, 0.5f), .NonZero, false);

				let ramp = scope VGLinearGradientFill(.(0.0f, 0.0f), .(128.0f, 0.0f));
				ramp.AddStop(0.0f, ByteColor(0, 0, 0));
				ramp.AddStop(1.0f, ByteColor(255, 255, 255));
				let band = Rect(0, 44, 128, 84);
				defer delete band;
				context.FillPath(band, ramp, .NonZero, false);

				let solid = Rect(0, 88, 128, 128);
				defer delete solid;
				context.FillPath(solid, ByteColor(180, 60, 40), .NonZero, false);
			}, 1, space);
		defer delete image;
		Test.Assert((image != null) && image.Valid, "the scene rendered");

		var readings = BlendSpaceReadings();
		readings.HalfBlack = image.At(64, 20)[0];
		readings.GradientMid = image.At(64, 64)[0];
		let solid = image.At(64, 108);
		for (int c < 3)
			readings.Solid[c] = solid[c];
		return readings;
	}

	/// Clip paths NEST as intersections: two rounded clips, the inner overlapping the outer's top
	/// left corner, then a clip rect inside the outer. Red fills the canvas under both clips and
	/// only their intersection shows, the outer's rounded corner included; with the inner popped,
	/// blue fills the outer alone; inside it, a clip rect confines green to its left part.
	[Test]
	public static void ClipPathsNestAsIntersectionsWithAClipRectInsideOne()
	{
		for (let kind in scope ProbeBackend[](.Vulkan, .WebGpu, .Dx12))
			NestedClipsOn(kind);
	}

	private static void NestedClipsOn(ProbeBackend kind)
	{
		let fixture = scope VGProbeFixture(kind);
		if (!fixture.Ready)
			return;

		let image = VGSceneRenderer.RenderScene(fixture, scope (context) =>
			{
				let full = Rect(0, 0, 128, 128);
				defer delete full;
				let outerBuilder = scope PathBuilder();
				ShapeBuilder.BuildRoundedRect(.(16, 16, 96, 96), .(24), outerBuilder);
				let outer = outerBuilder.ToPath();
				defer delete outer;
				let innerBuilder = scope PathBuilder();
				ShapeBuilder.BuildRoundedRect(.(4, 4, 64, 64), .(12), innerBuilder);
				let inner = innerBuilder.ToPath();
				defer delete inner;

				context.PushClipPath(outer);
				context.PushClipPath(inner);
				context.FillPath(full, ByteColor(255, 0, 0), .NonZero, false);
				context.PopClipPath();
				// The outer alone, below the inner's square: blue.
				let lower = Rect(0, 72, 128, 128);
				defer delete lower;
				context.FillPath(lower, ByteColor(0, 0, 255), .NonZero, false);
				// A clip rect inside the outer: green on its left part of the band x 72..128.
				context.PushClipRect(.(72, 0, 24, 72));
				context.FillPath(full, ByteColor(0, 255, 0), .NonZero, false);
				context.PopClip();
				context.PopClipPath();
			});
		defer delete image;
		Test.Assert((image != null) && image.Valid, "the scene rendered");

		let name = kind.ToString(.. scope .());
		bool Red(uint32 x, uint32 y) => (image.At(x, y)[0] > 200) && (image.At(x, y)[2] < 60);
		bool Blue(uint32 x, uint32 y) => (image.At(x, y)[2] > 200) && (image.At(x, y)[0] < 60);
		bool Green(uint32 x, uint32 y) => (image.At(x, y)[1] > 200) && (image.At(x, y)[0] < 60);
		bool Dark(uint32 x, uint32 y) => (image.At(x, y)[0] < 40) && (image.At(x, y)[1] < 40) && (image.At(x, y)[2] < 40);
		Test.Assert(Red(40, 40), scope $"{name}: inside both");
		Test.Assert(Dark(19, 19), scope $"{name}: inside the inner, outside the outer's rounded corner");
		Test.Assert(Dark(10, 40), scope $"{name}: inside the inner, left of the outer");
		Test.Assert(Dark(70, 40), scope $"{name}: inside the outer, right of the inner, before the clip rect");
		Test.Assert(Dark(64, 66), scope $"{name}: inside the inner's square, outside its rounded corner");
		Test.Assert(Blue(60, 100), scope $"{name}: the outer alone after the pop");
		Test.Assert(Dark(108, 108), scope $"{name}: outside the outer's rounded corner");
		Test.Assert(Green(84, 40), scope $"{name}: the clip rect inside the outer");
		Test.Assert(Dark(100, 40), scope $"{name}: inside the outer, right of the clip rect");
		Test.Assert(Dark(84, 8), scope $"{name}: inside the clip rect, above the outer");
	}

	/// Analytic boxes: a rounded fill with whole pixel straight edges, a one pixel border with no
	/// halo, and a border width per side, drawn by the box shader.
	[Test]
	public static void AnalyticBoxesFillBorderWithoutAHaloAndTakeAWidthPerSide()
	{
		for (let kind in scope ProbeBackend[](.Vulkan, .WebGpu, .Dx12))
			BoxesOn(kind);
	}

	private static void BoxesOn(ProbeBackend kind)
	{
		let fixture = scope VGProbeFixture(kind);
		if (!fixture.Ready)
			return;

		let image = VGSceneRenderer.RenderScene(fixture, scope (context) =>
			{
				// A rounded fill.
				context.DrawBox(.(16, 16, 48, 48), .(16.0f), ByteColor(220, 40, 40));
				// A one pixel border, no fill.
				context.DrawBox(.(80, 16, 32, 32), .(), .(0, 0, 0, 0), .(1.0f), ByteColor(60, 60, 240));
				// Six pixels of border on the left, none on the right, two above and below.
				context.DrawBox(.(16, 80, 48, 32), .(), .(0, 0, 0, 0), .(2.0f, 0.0f, 2.0f, 6.0f), ByteColor(40, 200, 40));
				// A canvas scaled to 0.48 (a game UI at a reference resolution): a 2 px border,
				// snapped to one whole device pixel.
				context.PushState();
				context.Scale(0.48f, 0.48f);
				context.DrawBox(.(180, 152, 40, 16), .(), .(0, 0, 0, 0), .(2.0f), ByteColor(40, 200, 40));
				context.PopState();
			});
		defer delete image;
		Test.Assert((image != null) && image.Valid, "the scene rendered");

		let name = kind.ToString(.. scope .());
		bool Red(uint32 x, uint32 y) => (image.At(x, y)[0] > 200) && (image.At(x, y)[1] < 80);
		bool Blue(uint32 x, uint32 y) => (image.At(x, y)[2] > 200) && (image.At(x, y)[0] < 100);
		bool Green(uint32 x, uint32 y) => (image.At(x, y)[1] > 180) && (image.At(x, y)[0] < 100);
		bool Dark(uint32 x, uint32 y) => (image.At(x, y)[0] < 12) && (image.At(x, y)[1] < 12) && (image.At(x, y)[2] < 12);

		// The fill: inside, its straight edges on whole pixels (no fringe), and clear outside
		// its rounded corner.
		Test.Assert(Red(40, 40), scope $"{name}: the fill");
		Test.Assert(Red(40, 16), scope $"{name}: the fill's top row");
		Test.Assert(Dark(40, 15), scope $"{name}: nothing above the fill");
		Test.Assert(Dark(18, 18), scope $"{name}: outside the corner's arc");
		// The one pixel border: its row lit, nothing outside it, the inside clear.
		Test.Assert(Blue(96, 16), scope $"{name}: the border's row");
		Test.Assert(Dark(96, 15), scope $"{name}: no halo outside the border");
		Test.Assert(Dark(96, 18), scope $"{name}: no fill inside the border");
		Test.Assert(Blue(80, 30), scope $"{name}: the border's column");
		Test.Assert(Dark(79, 30), scope $"{name}: no halo left of the border");
		// Per side: six on the left, none on the right.
		var left = 0;
		for (uint32 x = 14; x < 30; x++)
			left += Green(x, 96) ? 1 : 0;
		Test.Assert(left == 6, scope $"{name}: {left} pixels of left border");
		Test.Assert(Dark(62, 96), scope $"{name}: no right border");
		Test.Assert(Dark(64, 96), scope $"{name}: nothing right of the box");
		Test.Assert(Green(40, 80), scope $"{name}: the top border");
		Test.Assert(Dark(40, 83), scope $"{name}: inside, under the top border");
		// The scaled box: device 86.4..105.6 x 72.96..80.64, snapped to 86..106 x 73..81; its top
		// border one full pixel row, nothing above it, nothing under it.
		Test.Assert(Green(96, 73), scope $"{name}: the scaled box's top border");
		Test.Assert(Dark(96, 72), scope $"{name}: nothing above the scaled box");
		Test.Assert(Dark(96, 75), scope $"{name}: one pixel, nothing under it");
	}

	/// An axis aligned rectangle path, the caller's to delete.
	private static Path Rect(float x0, float y0, float x1, float y1)
	{
		let builder = scope PathBuilder();
		builder.MoveTo(x0, y0);
		builder.LineTo(x1, y0);
		builder.LineTo(x1, y1);
		builder.LineTo(x0, y1);
		builder.Close();
		return builder.ToPath();
	}

	[Test]
	public static void MultisamplingSoftensAHardDiagonal()
	{
		// Every backend: the multisample resolve is configured per backend, so one passing says nothing
		// about the other.
		for (let kind in scope ProbeBackend[](.Vulkan, .WebGpu, .Dx12))
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
