namespace Sedulous.RenderGraph.Tests;

using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.RenderGraph;

/// Minimal ITexture mock for barrier tests.
/// Each instance has a unique pointer identity for TextureKey hashing.
class MockTexture : ITexture
{
	private TextureDesc mDesc;
	private ResourceState mInitialState;

	public this(ResourceState initialState = .Undefined)
	{
		mDesc = .();
		mInitialState = initialState;
	}

	public TextureDesc Desc => mDesc;
	public ResourceState InitialState => mInitialState;
}

/// Minimal ITextureView mock.
class MockTextureView : ITextureView
{
	private ITexture mTexture;
	public this(ITexture texture) { mTexture = texture; }
	public TextureViewDesc Desc => .();
	public ITexture Texture => mTexture;
}

/// ICommandEncoder mock that records emitted barriers for verification.
class MockEncoder : ICommandEncoder
{
	public List<TextureBarrier> RecordedTextureBarriers = new .() ~ delete _;
	public List<BufferBarrier> RecordedBufferBarriers = new .() ~ delete _;

	public void Barrier(BarrierGroup barriers)
	{
		for (let b in barriers.TextureBarriers)
			RecordedTextureBarriers.Add(b);
		for (let b in barriers.BufferBarriers)
			RecordedBufferBarriers.Add(b);
	}

	// Stubs for unused ICommandEncoder methods
	public IRenderPassEncoder BeginRenderPass(RenderPassDesc desc) => null;
	public IComputePassEncoder BeginComputePass(StringView label) => null;
	public void CopyBufferToBuffer(IBuffer src, uint64 srcOffset, IBuffer dst, uint64 dstOffset, uint64 size) {}
	public void CopyBufferToTexture(IBuffer src, ITexture dst, BufferTextureCopyRegion region) {}
	public void CopyTextureToBuffer(ITexture src, IBuffer dst, BufferTextureCopyRegion region) {}
	public void CopyTextureToTexture(ITexture src, ITexture dst, TextureCopyRegion region) {}
	public void Blit(ITexture src, ITexture dst) {}
	public void GenerateMipmaps(ITexture texture) {}
	public void ResolveTexture(ITexture src, ITexture dst) {}
	public void ResetQuerySet(IQuerySet querySet, uint32 first, uint32 count) {}
	public void WriteTimestamp(IQuerySet querySet, uint32 index) {}
	public void ResolveQuerySet(IQuerySet querySet, uint32 first, uint32 count, IBuffer dst, uint64 dstOffset) {}
	public void BeginDebugLabel(StringView label, float r = 0, float g = 0, float b = 0, float a = 1) {}
	public void EndDebugLabel() {}
	public void InsertDebugLabel(StringView label, float r = 0, float g = 0, float b = 0, float a = 1) {}
	public ICommandBuffer Finish() => null;
}

class BarrierTests
{
	/// When two handles reference the same ITexture, a state change through one
	/// must be visible when the other is accessed — emitting the correct barrier.
	[Test]
	public static void SameTexture_TwoHandles_BarrierEmitted()
	{
		let solver = scope BarrierSolver();
		let encoder = scope MockEncoder();

		// One GPU texture, two resource entries (shadow map pattern)
		let shadowTex = scope MockTexture(.Undefined);
		let shadowView = scope MockTextureView(shadowTex);

		let resources = scope List<RenderGraphResource>();

		// Handle 0: shadow pass writes depth
		let res0 = new RenderGraphResource("ShadowWrite", .Texture, .Imported);
		res0.Texture = shadowTex;
		res0.TextureView = shadowView;
		res0.LastKnownState = .Undefined;
		resources.Add(res0);
		defer delete res0;

		// Handle 1: forward pass reads same texture
		let res1 = new RenderGraphResource("ShadowRead", .Texture, .Imported);
		res1.Texture = shadowTex; // Same ITexture!
		res1.TextureView = shadowView;
		res1.LastKnownState = .Undefined;
		resources.Add(res1);
		defer delete res1;

		solver.Reset(resources);

		// Pass 1: writes to handle 0 as depth target
		let writePass = scope RenderGraphPass("ShadowPass", .Render);
		writePass.Accesses.Add(.(RGHandle(0, 0), .WriteDepthTarget ));

		solver.EmitBarriers(writePass, resources, encoder);
		encoder.RecordedTextureBarriers.Clear(); // Don't care about this barrier

		// Pass 2: reads handle 1 as sampled texture
		let readPass = scope RenderGraphPass("ForwardPass", .Render);
		readPass.Accesses.Add(.( RGHandle(1, 0), .ReadTexture ));

		solver.EmitBarriers(readPass, resources, encoder);

		// Should emit DepthStencilWrite -> ShaderRead barrier
		Test.Assert(encoder.RecordedTextureBarriers.Count == 1);
		Test.Assert(encoder.RecordedTextureBarriers[0].OldState == .DepthStencilWrite);
		Test.Assert(encoder.RecordedTextureBarriers[0].NewState == .ShaderRead);
		Test.Assert(encoder.RecordedTextureBarriers[0].Texture === shadowTex);
	}

	/// When a single handle is written then read in subsequent passes,
	/// the barrier should be emitted (standard read-after-write).
	[Test]
	public static void SingleHandle_ReadAfterWrite_BarrierEmitted()
	{
		let solver = scope BarrierSolver();
		let encoder = scope MockEncoder();

		let tex = scope MockTexture(.Undefined);
		let view = scope MockTextureView(tex);

		let resources = scope List<RenderGraphResource>();
		let res = new RenderGraphResource("Color", .Texture, .Transient);
		res.Texture = tex;
		res.TextureView = view;
		resources.Add(res);
		defer delete res;

		solver.Reset(resources);

		// Pass 1: write as color target
		let writePass = scope RenderGraphPass("Writer", .Render);
		writePass.Accesses.Add(.(RGHandle(0, 0), .WriteColorTarget ));

		solver.EmitBarriers(writePass, resources, encoder);
		encoder.RecordedTextureBarriers.Clear();

		// Pass 2: read as texture
		let readPass = scope RenderGraphPass("Reader", .Render);
		readPass.Accesses.Add(.(RGHandle(0, 0), .ReadTexture ));

		solver.EmitBarriers(readPass, resources, encoder);

		Test.Assert(encoder.RecordedTextureBarriers.Count == 1);
		Test.Assert(encoder.RecordedTextureBarriers[0].OldState == .RenderTarget);
		Test.Assert(encoder.RecordedTextureBarriers[0].NewState == .ShaderRead);
	}

	/// Compute write (storage) followed by render read (sampled texture).
	[Test]
	public static void ComputeWrite_ThenRenderRead_BarrierEmitted()
	{
		let solver = scope BarrierSolver();
		let encoder = scope MockEncoder();

		let tex = scope MockTexture(.Undefined);
		let view = scope MockTextureView(tex);

		let resources = scope List<RenderGraphResource>();
		let res = new RenderGraphResource("Volume", .Texture, .Imported);
		res.Texture = tex;
		res.TextureView = view;
		res.LastKnownState = .Undefined;
		resources.Add(res);
		defer delete res;

		solver.Reset(resources);

		// Compute pass: write storage
		let computePass = scope RenderGraphPass("Compute", .Compute);
		computePass.Accesses.Add(.(RGHandle(0, 0), .WriteStorage ));

		solver.EmitBarriers(computePass, resources, encoder);
		encoder.RecordedTextureBarriers.Clear();

		// Render pass: read texture
		let renderPass = scope RenderGraphPass("Render", .Render);
		renderPass.Accesses.Add(.(RGHandle(0, 0), .ReadTexture ));

		solver.EmitBarriers(renderPass, resources, encoder);

		Test.Assert(encoder.RecordedTextureBarriers.Count == 1);
		Test.Assert(encoder.RecordedTextureBarriers[0].OldState == .ShaderWrite);
		Test.Assert(encoder.RecordedTextureBarriers[0].NewState == .ShaderRead);
	}

	/// Final state transition should use ITexture-keyed state.
	[Test]
	public static void FinalTransition_UsesTextureKeyedState()
	{
		let solver = scope BarrierSolver();
		let encoder = scope MockEncoder();

		let tex = scope MockTexture(.Undefined);
		let view = scope MockTextureView(tex);

		let resources = scope List<RenderGraphResource>();
		let res = new RenderGraphResource("Backbuffer", .Texture, .Imported);
		res.Texture = tex;
		res.TextureView = view;
		res.LastKnownState = .Undefined;
		res.FinalState = .Present;
		resources.Add(res);
		defer delete res;

		solver.Reset(resources);

		// Write as render target
		let pass = scope RenderGraphPass("FinalBlit", .Render);
		pass.Accesses.Add(.(RGHandle(0, 0), .WriteColorTarget));
		solver.EmitBarriers(pass, resources, encoder);
		encoder.RecordedTextureBarriers.Clear();

		// Emit final transitions
		solver.EmitFinalTransitions(resources, encoder);

		Test.Assert(encoder.RecordedTextureBarriers.Count == 1);
		Test.Assert(encoder.RecordedTextureBarriers[0].OldState == .RenderTarget);
		Test.Assert(encoder.RecordedTextureBarriers[0].NewState == .Present);
	}

	/// No barrier should be emitted when texture is already in the required state.
	[Test]
	public static void NoBarrier_WhenAlreadyInCorrectState()
	{
		let solver = scope BarrierSolver();
		let encoder = scope MockEncoder();

		let tex = scope MockTexture(.Undefined);
		let view = scope MockTextureView(tex);

		let resources = scope List<RenderGraphResource>();
		let res = new RenderGraphResource("Tex", .Texture, .Imported);
		res.Texture = tex;
		res.TextureView = view;
		res.LastKnownState = .ShaderRead;
		resources.Add(res);
		defer delete res;

		solver.Reset(resources);

		// Read texture — already in ShaderRead state
		let pass = scope RenderGraphPass("Reader", .Render);
		pass.Accesses.Add(.(RGHandle(0, 0), .ReadTexture));

		solver.EmitBarriers(pass, resources, encoder);

		Test.Assert(encoder.RecordedTextureBarriers.Count == 0);
	}
}
