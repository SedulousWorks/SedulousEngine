using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Image;
using Sedulous.RHI;
using Sedulous.VG;
using Sedulous.VG.Renderer;

namespace Sedulous.VG.Renderer.Tests;

/// Taking a batch to the GPU: the vertex conversion, the frame ring, the pipelines a
/// command picks, and the texture cache.
class VGRendererTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f) => Abs(a - b) <= epsilon;

	private static void FillBatch(VGBatch batch, ImageData white, int quads = 1)
	{
		batch.Textures.Add(white);
		for (int q = 0; q < quads; q++)
		{
			let baseIndex = (uint32)batch.Vertices.Count;
			let offset = (float)q * 20.0f;
			batch.Vertices.Add(VGVertex.Solid(.(offset, 0), .Red));
			batch.Vertices.Add(VGVertex.Solid(.(offset + 10, 0), .Red));
			batch.Vertices.Add(VGVertex.Solid(.(offset + 10, 10), .Red));
			batch.Vertices.Add(VGVertex.Solid(.(offset, 10), .Red));

			for (let index in scope uint32[](0, 1, 2, 0, 2, 3))
				batch.Indices.Add(baseIndex + index);
		}

		var command = VGCommand();
		command.StartIndex = 0;
		command.IndexCount = (int32)batch.Indices.Count;
		command.TextureIndex = 0;
		batch.Commands.Add(command);
	}

	/// The colour passes through RAW. The shader owns the single decode to linear, and
	/// converting here as well would decode twice.
	[Test]
	public static void TheRenderVertexPassesColourThroughRaw()
	{
		let source = VGVertex(.(1, 2), .(0.25f, 0.75f), .(0.5f, 0.25f, 0.125f, 0.5f), 0.5f);
		let converted = VGRenderVertex(source);

		Test.Assert(converted.Position[0] == 1.0f && converted.Position[1] == 2.0f);
		Test.Assert(converted.TexCoord[0] == 0.25f && converted.TexCoord[1] == 0.75f);
		Test.Assert(converted.Color[0] == 0.5f, "not decoded on the way through");
		Test.Assert(converted.Color[1] == 0.25f);
		Test.Assert(converted.Color[2] == 0.125f);
		Test.Assert(converted.Color[3] == 0.5f);
		Test.Assert(converted.Coverage == 0.5f);
	}

	/// The stride the vertex layout declares. A struct that grew without the layout
	/// following would make every attribute after the change read the wrong bytes.
	[Test]
	public static void TheRenderVertexStrideMatchesItsLayout()
	{
		Test.Assert(sizeof(VGRenderVertex) == VGRenderVertex.SizeInBytes);
		Test.Assert(VGRenderVertex.SizeInBytes == 36);
	}

	[Test]
	public static void InitialisingBringsUpTheRenderer()
	{
		let fixture = scope RendererFixture();
		Test.Assert(fixture.Renderer.IsInitialized);
	}

	/// Without a stencil attachment the stencil families are never built, and the host
	/// reads that off the renderer rather than guessing.
	[Test]
	public static void StencilSupportFollowsTheTargetConfig()
	{
		let plain = scope RendererFixture();
		Test.Assert(!plain.Renderer.StencilFillsSupported);

		let stencil = scope RendererFixture(true);
		Test.Assert(stencil.Renderer.StencilFillsSupported,
			"the null backend accepts a stencil format");
	}

	/// The format is PROBED rather than assumed, because drivers commonly accept only one
	/// of the combined formats.
	[Test]
	public static void TheStencilFormatIsProbed()
	{
		let fixture = scope RendererFixture();
		let format = VGRenderer.PickStencilCapableFormat(fixture.Device, 1);
		Test.Assert(format != .Undefined);
		Test.Assert(TextureFormats.HasStencil(format), "and it actually carries stencil");
	}

	// ---- preparing ----

	[Test]
	public static void PreparingABatchYieldsAValidSlice()
	{
		let fixture = scope RendererFixture();
		let white = scope OwnedImageData(1, 1, .RGBA8, scope uint8[4](255, 255, 255, 255), .Linear);

		let batch = scope VGBatch();
		FillBatch(batch, white);

		fixture.Renderer.BeginFrame(0);
		let slice = fixture.Renderer.Prepare(batch, 0, 800, 600);

		Test.Assert(slice.IsValid);
		Test.Assert(slice.VertexByteOffset == 0);
		Test.Assert(slice.IndexByteOffset == 0);
		Test.Assert(slice.UniformByteOffset == 0);
		Test.Assert(slice.DrawCommandCount == 1);
	}

	/// A second slice in the same frame starts where the first ended: the buffers are a
	/// shared ring, and each surface takes its own span.
	[Test]
	public static void ASecondSliceFollowsTheFirst()
	{
		let fixture = scope RendererFixture();
		let white = scope OwnedImageData(1, 1, .RGBA8, scope uint8[4](255, 255, 255, 255), .Linear);

		let batch = scope VGBatch();
		FillBatch(batch, white);

		fixture.Renderer.BeginFrame(0);
		let first = fixture.Renderer.Prepare(batch, 0, 800, 600);
		let second = fixture.Renderer.Prepare(batch, 0, 800, 600);

		Test.Assert(second.VertexByteOffset == 4 * (uint32)VGRenderVertex.SizeInBytes);
		Test.Assert(second.IndexByteOffset == 6 * (uint32)sizeof(uint32));
		Test.Assert(second.UniformByteOffset > first.UniformByteOffset, "its own uniform slot");
		Test.Assert(second.DrawCommandStart == first.DrawCommandCount);
	}

	/// Beginning the frame again resets the ring, so the offsets start over.
	[Test]
	public static void BeginningAFrameResetsItsRing()
	{
		let fixture = scope RendererFixture();
		let white = scope OwnedImageData(1, 1, .RGBA8, scope uint8[4](255, 255, 255, 255), .Linear);

		let batch = scope VGBatch();
		FillBatch(batch, white);

		fixture.Renderer.BeginFrame(0);
		fixture.Renderer.Prepare(batch, 0, 800, 600);

		fixture.Renderer.BeginFrame(0);
		let slice = fixture.Renderer.Prepare(batch, 0, 800, 600);
		Test.Assert(slice.VertexByteOffset == 0);
	}

	/// An empty batch has nothing to upload, and an invalid slice draws nothing.
	[Test]
	public static void AnEmptyBatchYieldsAnInvalidSlice()
	{
		let fixture = scope RendererFixture();
		let batch = scope VGBatch();

		fixture.Renderer.BeginFrame(0);
		Test.Assert(!fixture.Renderer.Prepare(batch, 0, 800, 600).IsValid);
	}

	/// The command texture indices are REBASED into the shared list, because several
	/// batches share one frame's texture table.
	[Test]
	public static void CommandTextureIndicesAreRebased()
	{
		let fixture = scope RendererFixture();
		let white = scope OwnedImageData(1, 1, .RGBA8, scope uint8[4](255, 255, 255, 255), .Linear);
		let other = scope OwnedImageData(2, 2, .RGBA8, scope uint8[16](), .Linear);

		let first = scope VGBatch();
		FillBatch(first, white);

		let second = scope VGBatch();
		FillBatch(second, other);

		fixture.Renderer.BeginFrame(0);
		fixture.Renderer.Prepare(first, 0, 800, 600);
		fixture.Renderer.Prepare(second, 0, 800, 600);

		// Both cached: the second batch's index zero became index one in the shared list.
		Test.Assert(fixture.Renderer.CachedTextureCount == 2);
	}

	// ---- the scissor ----

	/// Clamped to the content box FIRST and offset second, so a viewport's content can
	/// never bleed into a neighbouring view.
	[Test]
	public static void TheScissorClampsThenOffsets()
	{
		let inside = VGRenderer.ComputeScissor(.(10, 20, 30, 40), 0, 0, 800, 600);
		Test.Assert(inside.X == 10 && inside.Y == 20);
		Test.Assert(inside.Width == 30 && inside.Height == 40);

		// Past the content box on both sides: clamped to it, then offset.
		let clamped = VGRenderer.ComputeScissor(.(-50, -50, 1000, 1000), 100, 200, 800, 600);
		Test.Assert(clamped.X == 100, "the negative edge clamps to zero, then offsets");
		Test.Assert(clamped.Y == 200);
		Test.Assert(clamped.Width == 800, "and the far edge clamps to the content extent");
		Test.Assert(clamped.Height == 600);
	}

	/// A clip entirely outside the content is EMPTY rather than negative, which would be a
	/// wrapped unsigned extent covering everything.
	[Test]
	public static void AClipOutsideTheContentIsEmpty()
	{
		let outside = VGRenderer.ComputeScissor(.(2000, 2000, 100, 100), 0, 0, 800, 600);
		Test.Assert(outside.Width == 0 && outside.Height == 0);
	}

	/// The near edge rounds UP and the far edge DOWN, so a partially covered pixel is
	/// excluded: a scissor that grew by rounding would let content spill past its clip.
	[Test]
	public static void ThePartialPixelsAreExcluded()
	{
		let rect = VGRenderer.ComputeScissor(.(10.3f, 20.7f, 30.4f, 40.2f), 0, 0, 800, 600);
		Test.Assert(rect.X == 11, "rounded in");
		Test.Assert(rect.Y == 21);
		Test.Assert(rect.Width == 29, "and the far edge rounded in too");
		Test.Assert(rect.Height == 39);
	}

	// ---- the texture cache ----

	[Test]
	public static void ATextureIsUploadedOnceAndCached()
	{
		let fixture = scope RendererFixture();
		let white = scope OwnedImageData(1, 1, .RGBA8, scope uint8[4](255, 255, 255, 255), .Linear);

		let batch = scope VGBatch();
		FillBatch(batch, white);

		fixture.Renderer.BeginFrame(0);
		fixture.Renderer.Prepare(batch, 0, 800, 600);
		Test.Assert(fixture.Renderer.CachedTextureCount == 1);

		fixture.Renderer.Prepare(batch, 0, 800, 600);
		Test.Assert(fixture.Renderer.CachedTextureCount == 1, "the same source, cached");
	}

	/// A caller owned view registers under an image identity, so drawing that image samples
	/// the given texture rather than uploading pixels.
	[Test]
	public static void AnExternalViewRegistersAndUnregisters()
	{
		let fixture = scope RendererFixture();
		let key = scope OwnedImageData(4, 4, .RGBA8, .(), .Linear);

		var textureDesc = TextureDesc();
		textureDesc.Format = .RGBA8Unorm;
		textureDesc.Width = 4;
		textureDesc.Height = 4;
		textureDesc.Usage = .Sampled;
		var texture = fixture.Device.CreateTexture(textureDesc).Value;
		var view = fixture.Device.CreateTextureView(texture, .()).Value;

		Test.Assert(!fixture.Renderer.IsExternalTextureRegistered(key));

		fixture.Renderer.RegisterExternalTexture(key, view);
		Test.Assert(fixture.Renderer.IsExternalTextureRegistered(key));
		Test.Assert(fixture.Renderer.CachedTextureCount == 1);

		fixture.Renderer.UnregisterExternalTexture(key);
		Test.Assert(!fixture.Renderer.IsExternalTextureRegistered(key));
		Test.Assert(fixture.Renderer.CachedTextureCount == 0);

		// The caller's own view and texture survive: the renderer never owned them.
		fixture.Device.DestroyTextureView(ref view);
		fixture.Device.DestroyTexture(ref texture);
	}

	/// Re-registering rebinds rather than duplicating.
	[Test]
	public static void ReRegisteringRebinds()
	{
		let fixture = scope RendererFixture();
		let key = scope OwnedImageData(4, 4, .RGBA8, .(), .Linear);

		var textureDesc = TextureDesc();
		textureDesc.Format = .RGBA8Unorm;
		textureDesc.Width = 4;
		textureDesc.Height = 4;
		textureDesc.Usage = .Sampled;
		var texture = fixture.Device.CreateTexture(textureDesc).Value;
		var first = fixture.Device.CreateTextureView(texture, .()).Value;
		var second = fixture.Device.CreateTextureView(texture, .()).Value;

		fixture.Renderer.RegisterExternalTexture(key, first);
		fixture.Renderer.RegisterExternalTexture(key, second);
		Test.Assert(fixture.Renderer.CachedTextureCount == 1);

		fixture.Renderer.UnregisterExternalTexture(key);
		fixture.Device.DestroyTextureView(ref second);
		fixture.Device.DestroyTextureView(ref first);
		fixture.Device.DestroyTexture(ref texture);
	}

	/// An eviction RETIRES an entry rather than freeing it, and it is freed once every in
	/// flight frame has aged past it. Freeing at once would destroy bind groups a submitted
	/// frame still references.
	[Test]
	public static void AnEvictionRetiresUntilTheFramesAgeOut()
	{
		let fixture = scope RendererFixture();
		let white = scope OwnedImageData(1, 1, .RGBA8, scope uint8[4](255, 255, 255, 255), .Linear);

		let batch = scope VGBatch();
		FillBatch(batch, white);

		fixture.Renderer.BeginFrame(0);
		fixture.Renderer.Prepare(batch, 0, 800, 600);
		Test.Assert(fixture.Renderer.CachedTextureCount == 1);

		// The batch's eviction list is the invalidation signal.
		let eviction = scope VGBatch();
		eviction.EvictedTextures.Add(white);
		fixture.Renderer.BeginFrame(1);
		fixture.Renderer.Prepare(eviction, 1, 800, 600);

		Test.Assert(fixture.Renderer.CachedTextureCount == 0, "out of the live cache at once");
		Test.Assert(fixture.Renderer.RetiredTextureCount == 1, "but not yet freed");

		// One frame per in flight frame, and then it goes.
		for (int32 i = 0; i < RendererFixture.FrameCount; i++)
			fixture.Renderer.BeginFrame(i % RendererFixture.FrameCount);

		Test.Assert(fixture.Renderer.RetiredTextureCount == 0);
	}

	/// An external entry is NOT evicted by a batch: its owner invalidates it, because only
	/// the owner knows when its view dies.
	[Test]
	public static void ABatchEvictionSkipsAnExternalEntry()
	{
		let fixture = scope RendererFixture();
		let key = scope OwnedImageData(4, 4, .RGBA8, .(), .Linear);

		var textureDesc = TextureDesc();
		textureDesc.Format = .RGBA8Unorm;
		textureDesc.Width = 4;
		textureDesc.Height = 4;
		textureDesc.Usage = .Sampled;
		var texture = fixture.Device.CreateTexture(textureDesc).Value;
		var view = fixture.Device.CreateTextureView(texture, .()).Value;

		fixture.Renderer.RegisterExternalTexture(key, view);
		fixture.Renderer.EvictCachedTexture(key);

		Test.Assert(fixture.Renderer.CachedTextureCount == 1, "left for its owner");
		Test.Assert(fixture.Renderer.RetiredTextureCount == 0);

		fixture.Renderer.UnregisterExternalTexture(key);
		fixture.Device.DestroyTextureView(ref view);
		fixture.Device.DestroyTexture(ref texture);
	}

	/// Clearing the cache takes the retired entries with it.
	[Test]
	public static void ClearingTakesTheRetiredEntriesToo()
	{
		let fixture = scope RendererFixture();
		let white = scope OwnedImageData(1, 1, .RGBA8, scope uint8[4](255, 255, 255, 255), .Linear);

		let batch = scope VGBatch();
		FillBatch(batch, white);
		fixture.Renderer.BeginFrame(0);
		fixture.Renderer.Prepare(batch, 0, 800, 600);

		fixture.Renderer.EvictCachedTexture(white);
		Test.Assert(fixture.Renderer.RetiredTextureCount == 1);

		fixture.Renderer.ClearTextureCache();
		Test.Assert(fixture.Renderer.CachedTextureCount == 0);
		Test.Assert(fixture.Renderer.RetiredTextureCount == 0);
	}

	/// An unknown key evicts nothing, and a null one is harmless.
	[Test]
	public static void EvictingSomethingUncachedIsHarmless()
	{
		let fixture = scope RendererFixture();
		let stranger = scope OwnedImageData(1, 1, .RGBA8, .(), .Linear);

		fixture.Renderer.EvictCachedTexture(stranger);
		fixture.Renderer.EvictCachedTexture(null);
		fixture.Renderer.UnregisterExternalTexture(stranger);
		Test.Assert(fixture.Renderer.CachedTextureCount == 0);
	}
}
