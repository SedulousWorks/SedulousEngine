using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Image;
using Sedulous.RHI;
using Sedulous.VG;
using Sedulous.VG.Renderer;

namespace Sedulous.VG.Renderer.Tests;

/// Dispatching a slice into a pass, and the cases where a command must be skipped rather
/// than drawn with the wrong pipeline.
class VGRenderDispatchTests
{
	private static ImageData White(uint8[4]* pixel) => new OwnedImageData(1, 1, .RGBA8,
		.(&(*pixel)[0], 4), .Linear);

	/// One quad, with a caller supplied command.
	private static void FillBatch(VGBatch batch, ImageData white, VGCommand command)
	{
		batch.Textures.Add(white);
		batch.Vertices.Add(VGVertex.Solid(.(0, 0), .Red));
		batch.Vertices.Add(VGVertex.Solid(.(10, 0), .Red));
		batch.Vertices.Add(VGVertex.Solid(.(10, 10), .Red));
		batch.Vertices.Add(VGVertex.Solid(.(0, 10), .Red));
		for (let index in scope uint32[](0, 1, 2, 0, 2, 3))
			batch.Indices.Add(index);

		var withGeometry = command;
		withGeometry.StartIndex = 0;
		withGeometry.IndexCount = 6;
		batch.Commands.Add(withGeometry);
	}

	/// Runs a prepared batch through a real pass encoder. What is being checked is that
	/// every command resolves to something drawable and nothing faults on the way.
	private static void Dispatch(RendererFixture fixture, VGBatch batch)
	{
		fixture.Renderer.BeginFrame(0);
		let slice = fixture.Renderer.Prepare(batch, 0, 800, 600);

		Test.Assert(fixture.Device.CreateCommandPool(.Graphics) case .Ok(var pool));
		defer fixture.Device.DestroyCommandPool(ref pool);
		Test.Assert(pool.CreateEncoder() case .Ok(let encoder));

		let pass = encoder.BeginRenderPass(.());
		fixture.Renderer.Render(pass, 800, 600, 0, slice);
		pass.End();
	}

	[Test]
	public static void AnOrdinaryBatchDispatches()
	{
		let fixture = scope RendererFixture();
		uint8[4] pixel = .(255, 255, 255, 255);
		let white = White(&pixel);
		defer delete white;

		let batch = scope VGBatch();
		FillBatch(batch, white, .());
		Dispatch(fixture, batch);
	}

	/// An invalid slice draws nothing rather than dispatching a zero length range.
	[Test]
	public static void AnInvalidSliceDrawsNothing()
	{
		let fixture = scope RendererFixture();

		Test.Assert(fixture.Device.CreateCommandPool(.Graphics) case .Ok(var pool));
		defer fixture.Device.DestroyCommandPool(ref pool);
		Test.Assert(pool.CreateEncoder() case .Ok(let encoder));

		let pass = encoder.BeginRenderPass(.());
		fixture.Renderer.Render(pass, 800, 600, 0, .());
		pass.End();
	}

	/// Every blend mode and draw mode resolves to a pipeline. A blend variant is built on
	/// first use, so this is also what exercises that path.
	[Test]
	public static void EveryModeResolvesToAPipeline()
	{
		let fixture = scope RendererFixture(false, true);
		uint8[4] pixel = .(255, 255, 255, 255);
		let white = White(&pixel);
		defer delete white;

		for (let blend in scope VGBlendMode[](.Normal, .Additive, .Multiply, .Screen))
		{
			for (let draw in scope VGDrawMode[](
				.Default, .DistanceField, .GradientRadial, .GradientConic))
			{
				var command = VGCommand();
				command.BlendMode = blend;
				command.DrawMode = draw;

				let batch = scope VGBatch();
				FillBatch(batch, white, command);
				Dispatch(fixture, batch);
			}
		}
	}

	/// WITHOUT the optional shaders, a distance field or gradient command falls back to the
	/// default pipeline rather than being dropped: the text would look wrong, but it draws.
	[Test]
	public static void AMissingOptionalPipelineFallsBackToTheDefault()
	{
		let fixture = scope RendererFixture();
		uint8[4] pixel = .(255, 255, 255, 255);
		let white = White(&pixel);
		defer delete white;

		var command = VGCommand();
		command.DrawMode = .DistanceField;

		let batch = scope VGBatch();
		FillBatch(batch, white, command);
		Dispatch(fixture, batch);
	}

	/// A stencil phase command with NO stencil pipelines is skipped entirely. A context
	/// should not emit one, but a stale batch must not draw its winding fans as colour.
	[Test]
	public static void AStencilCommandWithoutStencilSupportIsSkipped()
	{
		let fixture = scope RendererFixture();
		uint8[4] pixel = .(255, 255, 255, 255);
		let white = White(&pixel);
		defer delete white;

		for (let phase in scope VGFillPhase[](
			.StencilWrite, .StencilCover, .ClipApply, .ClipClear))
		{
			var command = VGCommand();
			command.FillPhase = phase;

			let batch = scope VGBatch();
			FillBatch(batch, white, command);
			Dispatch(fixture, batch);
		}
	}

	/// With a stencil attachment every phase and rule resolves.
	[Test]
	public static void EveryStencilPhaseResolvesWithAnAttachment()
	{
		let fixture = scope RendererFixture(true, true);
		uint8[4] pixel = .(255, 255, 255, 255);
		let white = White(&pixel);
		defer delete white;

		for (let phase in scope VGFillPhase[](
			.Direct, .StencilWrite, .StencilCover, .ClipApply, .ClipClear))
		{
			for (let rule in scope FillRule[](.NonZero, .EvenOdd))
			{
				for (let clipped in scope bool[](false, true))
				{
					var command = VGCommand();
					command.FillPhase = phase;
					command.FillRule = rule;
					command.ClipMode = clipped ? .Stencil : .None;

					let batch = scope VGBatch();
					FillBatch(batch, white, command);
					Dispatch(fixture, batch);
				}
			}
		}
	}

	/// A gradient cover keeps its own per pixel shader, so a complex shape and a simple one
	/// are shaded identically.
	[Test]
	public static void AGradientCoverResolvesToItsOwnPipeline()
	{
		let fixture = scope RendererFixture(true, true);
		uint8[4] pixel = .(255, 255, 255, 255);
		let white = White(&pixel);
		defer delete white;

		for (let draw in scope VGDrawMode[](.GradientRadial, .GradientConic))
		{
			var command = VGCommand();
			command.FillPhase = .StencilCover;
			command.DrawMode = draw;

			let batch = scope VGBatch();
			FillBatch(batch, white, command);
			Dispatch(fixture, batch);
		}
	}

	/// Every gradient spread resolves to its own sampler and therefore its own bind group.
	[Test]
	public static void EverySpreadResolvesToABindGroup()
	{
		let fixture = scope RendererFixture();
		uint8[4] pixel = .(255, 255, 255, 255);
		let white = White(&pixel);
		defer delete white;

		for (let spread in scope VGGradientSpread[](.Pad, .Repeat, .Reflect))
		{
			var command = VGCommand();
			command.GradientSpread = spread;

			let batch = scope VGBatch();
			FillBatch(batch, white, command);
			Dispatch(fixture, batch);
		}
	}

	/// A scissor clipped command, an empty clip, and an unclipped one all dispatch.
	[Test]
	public static void EveryClipModeDispatches()
	{
		let fixture = scope RendererFixture();
		uint8[4] pixel = .(255, 255, 255, 255);
		let white = White(&pixel);
		defer delete white;

		for (let clip in scope Rectangle[](.(10, 10, 100, 100), .(0, 0, 0, 0)))
		{
			var command = VGCommand();
			command.ClipMode = .Scissor;
			command.ClipRect = clip;

			let batch = scope VGBatch();
			FillBatch(batch, white, command);
			Dispatch(fixture, batch);
		}
	}

	/// A command with no indices contributes nothing and is skipped before any state is
	/// touched.
	[Test]
	public static void AnEmptyCommandIsSkipped()
	{
		let fixture = scope RendererFixture();
		uint8[4] pixel = .(255, 255, 255, 255);
		let white = White(&pixel);
		defer delete white;

		let batch = scope VGBatch();
		FillBatch(batch, white, .());
		// A second command covering nothing.
		batch.Commands.Add(.());

		Dispatch(fixture, batch);
	}

	/// The cache guards against ADDRESS REUSE with the source's instance id: a deleted
	/// image and a new one at the same address are the same reference and different ids.
	[Test]
	public static void TheCacheDetectsAddressReuse()
	{
		let fixture = scope RendererFixture();
		uint8[4] pixel = .(255, 255, 255, 255);

		var first = White(&pixel);
		let firstAddress = Internal.UnsafeCastToPtr(first);

		let batch = scope VGBatch();
		FillBatch(batch, first, .());
		fixture.Renderer.BeginFrame(0);
		fixture.Renderer.Prepare(batch, 0, 800, 600);
		Test.Assert(fixture.Renderer.CachedTextureCount == 1);

		delete first;

		// The allocator commonly hands the next allocation the same address. When it does,
		// the id is what tells the two apart.
		var second = White(&pixel);
		defer delete second;

		if (Internal.UnsafeCastToPtr(second) != firstAddress)
			return; // No reuse this run: nothing to check.

		Test.Assert(second.InstanceId != 0);

		let reused = scope VGBatch();
		FillBatch(reused, second, .());
		fixture.Renderer.BeginFrame(1);
		fixture.Renderer.Prepare(reused, 1, 800, 600);

		// The stale entry was retired and a fresh one built, rather than the new image
		// silently sampling the dead one's texture.
		Test.Assert(fixture.Renderer.CachedTextureCount == 1);
		Test.Assert(fixture.Renderer.RetiredTextureCount == 1, "the stale entry was retired");
	}
}
