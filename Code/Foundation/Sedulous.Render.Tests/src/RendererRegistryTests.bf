using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.Render;

namespace Sedulous.Render.Tests;

/// The renderer registry, the jitter, and the draw emission.
class RendererRegistryTests
{
	/// A renderer that resolves nothing, for the routing tests.
	private class TestRenderer : Renderer
	{
		private uint16[1] mCategories;

		public this(uint16 category)
		{
			mCategories = .(category);
		}

		public override Span<uint16> SupportedCategories => .(&mCategories[0], 1);

		public override void Resolve(RenderRecordContext context, Span<DrawItem> items,
			List<ResolvedDraw> outDraws) {}
	}

	/// A renderer's INDEX is its dispatch id, which is what a producer stamps onto its data.
	[Test]
	public static void RegisteringAssignsTheDispatchIds()
	{
		let registry = scope RendererRegistry();
		let meshes = scope TestRenderer(RenderCategories.Opaque);
		let sprites = scope TestRenderer(RenderCategories.Transparent);

		registry.Register(meshes);
		registry.Register(sprites);

		Test.Assert(meshes.RendererId == 0, "the first registered is the default");
		Test.Assert(sprites.RendererId == 1);
		Test.Assert(registry.ById(0) == meshes);
		Test.Assert(registry.ById(1) == sprites);
	}

	/// Two renderers can share a CATEGORY and still be routed apart, which is exactly what
	/// the dispatch id is for.
	[Test]
	public static void TwoRenderersCanShareACategory()
	{
		let registry = scope RendererRegistry();
		let meshes = scope TestRenderer(RenderCategories.Transparent);
		let sprites = scope TestRenderer(RenderCategories.Transparent);

		registry.Register(meshes);
		registry.Register(sprites);

		Test.Assert(meshes.RendererId != sprites.RendererId);
		Test.Assert(registry.Count == 2);
	}

	[Test]
	public static void RegisteringTwiceRegistersOnce()
	{
		let registry = scope RendererRegistry();
		let renderer = scope TestRenderer(RenderCategories.Opaque);

		registry.Register(renderer);
		registry.Register(renderer);
		registry.Register(null);

		Test.Assert(registry.Count == 1);
	}

	/// An unknown id answers nothing rather than reading past the end.
	[Test]
	public static void AnUnknownIdAnswersNothing()
	{
		let registry = scope RendererRegistry();
		Test.Assert(registry.ById(0) == null);
		Test.Assert(registry.ById(999) == null);
	}

	/// The default render data routes to the FIRST registered renderer, so mesh data written
	/// before anything else existed needs no change.
	[Test]
	public static void TheDefaultDataRoutesToTheFirstRenderer()
	{
		let registry = scope RendererRegistry();
		let meshes = scope TestRenderer(RenderCategories.Opaque);
		registry.Register(meshes);

		let data = scope MeshRenderData();
		Test.Assert(registry.ById(data.RendererId) == meshes);
	}

	// ---- the jitter ----

	/// The sequence is deterministic, within its range, and does not repeat quickly: a jitter
	/// that repeated would defeat the accumulation it exists to feed.
	[Test]
	public static void TheJitterSequenceIsSpreadAndDeterministic()
	{
		for (uint32 i = 0; i < 32; i++)
		{
			let value = TaaJitter.HaltonSeq(i, 2);
			Test.Assert((value >= 0.0f) && (value < 1.0f));
			Test.Assert(TaaJitter.HaltonSeq(i, 2) == value);
		}

		// The first few terms of the base two sequence are the halves, then the quarters.
		Test.Assert(Abs(TaaJitter.HaltonSeq(0, 2) - 0.5f) < 0.0001f);
		Test.Assert(Abs(TaaJitter.HaltonSeq(1, 2) - 0.25f) < 0.0001f);
		Test.Assert(Abs(TaaJitter.HaltonSeq(2, 2) - 0.75f) < 0.0001f);
	}

	/// The jitter is CENTRED and scaled to a single texel, so it samples within a pixel
	/// rather than smearing across several.
	[Test]
	public static void TheJitterStaysWithinOneTexel()
	{
		for (uint32 i = 0; i < 16; i++)
		{
			let jitter = TaaJitter.HaltonJitter(i, 1920, 1080);
			Test.Assert(Abs(jitter.X) <= 1.0f / 1920.0f + 0.000001f);
			Test.Assert(Abs(jitter.Y) <= 1.0f / 1080.0f + 0.000001f);
		}
	}

	/// A degenerate extent does not divide by nothing.
	[Test]
	public static void AZeroSizedTargetStillJitters()
	{
		let jitter = TaaJitter.HaltonJitter(3, 0, 0);
		Test.Assert(Abs(jitter.X) <= 1.0f);
		Test.Assert(Abs(jitter.Y) <= 1.0f);
	}

	/// Two successive frames jitter DIFFERENTLY, which is the whole point.
	[Test]
	public static void SuccessiveFramesJitterDifferently()
	{
		let first = TaaJitter.HaltonJitter(0, 800, 600);
		let second = TaaJitter.HaltonJitter(1, 800, 600);
		Test.Assert((first.X != second.X) || (first.Y != second.Y));
	}

	/// A draw with no pipeline or no indices is SKIPPED rather than recorded: the path is
	/// indexed only, and recording it would be a draw of nothing.
	[Test]
	public static void AnIncompleteDrawIsNotEmitted()
	{
		let recorder = scope RecordingRenderEncoder();

		DrawEmitter.EmitDraw(recorder, .());
		Test.Assert(recorder.DrawCount == 0);
		Test.Assert(recorder.PipelineCount == 0);
	}
}
