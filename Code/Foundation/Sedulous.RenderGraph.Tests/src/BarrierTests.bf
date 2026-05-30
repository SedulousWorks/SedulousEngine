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

	public this(ResourceState initialState = .Undefined, uint32 mipLevels = 1, uint32 arrayLayers = 1)
	{
		mDesc = .();
		mDesc.MipLevelCount = mipLevels;
		mDesc.ArrayLayerCount = arrayLayers;
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
	/// must be visible when the other is accessed - emitting the correct barrier.
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

		// Read texture - already in ShaderRead state
		let pass = scope RenderGraphPass("Reader", .Render);
		pass.Accesses.Add(.(RGHandle(0, 0), .ReadTexture));

		solver.EmitBarriers(pass, resources, encoder);

		Test.Assert(encoder.RecordedTextureBarriers.Count == 0);
	}

	// ==================== Per-subresource tests ====================

	/// Writing to individual array layers emits per-layer barriers with correct old states.
	[Test]
	public static void PerLayer_WriteDifferentLayers_IndividualBarriers()
	{
		let solver = scope BarrierSolver();
		let encoder = scope MockEncoder();

		// 4-layer shadow map array (e.g., 4 shadow cascades)
		let tex = scope MockTexture(.Undefined, mipLevels: 1, arrayLayers: 4);
		let view = scope MockTextureView(tex);

		let resources = scope List<RenderGraphResource>();
		let res = new RenderGraphResource("ShadowArray", .Texture, .Imported);
		res.Texture = tex;
		res.TextureView = view;
		res.LastKnownState = .ShaderRead;
		resources.Add(res);
		defer delete res;

		solver.Reset(resources);

		// Write to layer 0 only
		let pass0 = scope RenderGraphPass("Cascade0", .Render);
		pass0.Accesses.Add(.(RGHandle(0, 0), .WriteDepthTarget, .(0, 1, 0, 1)));
		solver.EmitBarriers(pass0, resources, encoder);

		// Should emit one barrier: ShaderRead -> DepthStencilWrite for layer 0
		Test.Assert(encoder.RecordedTextureBarriers.Count == 1);
		Test.Assert(encoder.RecordedTextureBarriers[0].OldState == .ShaderRead);
		Test.Assert(encoder.RecordedTextureBarriers[0].NewState == .DepthStencilWrite);
		Test.Assert(encoder.RecordedTextureBarriers[0].BaseArrayLayer == 0);
		Test.Assert(encoder.RecordedTextureBarriers[0].ArrayLayerCount == 1);

		encoder.RecordedTextureBarriers.Clear();

		// Write to layer 2 - tracker is now non-uniform (layer 0 = DepthStencilWrite, rest = ShaderRead)
		let pass2 = scope RenderGraphPass("Cascade2", .Render);
		pass2.Accesses.Add(.(RGHandle(0, 0), .WriteDepthTarget, .(0, 1, 2, 1)));
		solver.EmitBarriers(pass2, resources, encoder);

		// Should emit one per-subresource barrier for layer 2
		Test.Assert(encoder.RecordedTextureBarriers.Count == 1);
		Test.Assert(encoder.RecordedTextureBarriers[0].OldState == .ShaderRead);
		Test.Assert(encoder.RecordedTextureBarriers[0].NewState == .DepthStencilWrite);
		Test.Assert(encoder.RecordedTextureBarriers[0].BaseArrayLayer == 2);
		Test.Assert(encoder.RecordedTextureBarriers[0].ArrayLayerCount == 1);
	}

	/// Reading the whole resource after per-subresource writes emits correct per-subresource barriers.
	[Test]
	public static void NonUniform_WholeResourceRead_EmitsPerSubresourceBarriers()
	{
		let solver = scope BarrierSolver();
		let encoder = scope MockEncoder();

		// 2-layer texture: layer 0 = RenderTarget, layer 1 = ShaderRead
		let tex = scope MockTexture(.Undefined, mipLevels: 1, arrayLayers: 2);
		let view = scope MockTextureView(tex);

		let resources = scope List<RenderGraphResource>();
		let res = new RenderGraphResource("Tex", .Texture, .Imported);
		res.Texture = tex;
		res.TextureView = view;
		res.LastKnownState = .ShaderRead;
		resources.Add(res);
		defer delete res;

		solver.Reset(resources);

		// Write layer 0 as render target -> state becomes non-uniform
		let writePass = scope RenderGraphPass("Writer", .Render);
		writePass.Accesses.Add(.(RGHandle(0, 0), .WriteColorTarget, .(0, 1, 0, 1)));
		solver.EmitBarriers(writePass, resources, encoder);
		encoder.RecordedTextureBarriers.Clear();

		// Read entire texture -> should emit barrier only for layer 0 (layer 1 already ShaderRead)
		let readPass = scope RenderGraphPass("Reader", .Render);
		readPass.Accesses.Add(.(RGHandle(0, 0), .ReadTexture));
		solver.EmitBarriers(readPass, resources, encoder);

		// Only layer 0 needs transition (RenderTarget -> ShaderRead)
		Test.Assert(encoder.RecordedTextureBarriers.Count == 1);
		Test.Assert(encoder.RecordedTextureBarriers[0].OldState == .RenderTarget);
		Test.Assert(encoder.RecordedTextureBarriers[0].NewState == .ShaderRead);
		Test.Assert(encoder.RecordedTextureBarriers[0].BaseArrayLayer == 0);
		Test.Assert(encoder.RecordedTextureBarriers[0].ArrayLayerCount == 1);
	}

	/// Writing all layers to the same state collapses tracker back to uniform.
	[Test]
	public static void AllLayersWritten_CollapsesToUniform()
	{
		let solver = scope BarrierSolver();
		let encoder = scope MockEncoder();

		let tex = scope MockTexture(.Undefined, mipLevels: 1, arrayLayers: 2);
		let view = scope MockTextureView(tex);

		let resources = scope List<RenderGraphResource>();
		let res = new RenderGraphResource("Tex", .Texture, .Imported);
		res.Texture = tex;
		res.TextureView = view;
		res.LastKnownState = .ShaderRead;
		resources.Add(res);
		defer delete res;

		solver.Reset(resources);

		// Write layer 0 -> non-uniform
		let pass0 = scope RenderGraphPass("W0", .Render);
		pass0.Accesses.Add(.(RGHandle(0, 0), .WriteColorTarget, .(0, 1, 0, 1)));
		solver.EmitBarriers(pass0, resources, encoder);
		encoder.RecordedTextureBarriers.Clear();

		// Write layer 1 -> same state as layer 0, should collapse to uniform
		let pass1 = scope RenderGraphPass("W1", .Render);
		pass1.Accesses.Add(.(RGHandle(0, 0), .WriteColorTarget, .(0, 1, 1, 1)));
		solver.EmitBarriers(pass1, resources, encoder);
		encoder.RecordedTextureBarriers.Clear();

		// Now read whole texture - should be a single whole-resource barrier (uniform fast path)
		let readPass = scope RenderGraphPass("Read", .Render);
		readPass.Accesses.Add(.(RGHandle(0, 0), .ReadTexture));
		solver.EmitBarriers(readPass, resources, encoder);

		// One whole-resource barrier: RenderTarget -> ShaderRead
		Test.Assert(encoder.RecordedTextureBarriers.Count == 1);
		Test.Assert(encoder.RecordedTextureBarriers[0].OldState == .RenderTarget);
		Test.Assert(encoder.RecordedTextureBarriers[0].NewState == .ShaderRead);
		// Whole-resource: default subresource range
		Test.Assert(encoder.RecordedTextureBarriers[0].MipLevelCount == uint32.MaxValue);
		Test.Assert(encoder.RecordedTextureBarriers[0].ArrayLayerCount == uint32.MaxValue);
	}

	/// Per-mip barriers work correctly (e.g., mip generation pattern).
	[Test]
	public static void PerMip_DifferentStates_CorrectBarriers()
	{
		let solver = scope BarrierSolver();
		let encoder = scope MockEncoder();

		// 4-mip texture
		let tex = scope MockTexture(.Undefined, mipLevels: 4, arrayLayers: 1);
		let view = scope MockTextureView(tex);

		let resources = scope List<RenderGraphResource>();
		let res = new RenderGraphResource("Tex", .Texture, .Imported);
		res.Texture = tex;
		res.TextureView = view;
		res.LastKnownState = .Undefined;
		resources.Add(res);
		defer delete res;

		solver.Reset(resources);

		// Write mip 0 as render target
		let pass0 = scope RenderGraphPass("WriteMip0", .Render);
		pass0.Accesses.Add(.(RGHandle(0, 0), .WriteColorTarget, .(0, 1, 0, 1)));
		solver.EmitBarriers(pass0, resources, encoder);
		encoder.RecordedTextureBarriers.Clear();

		// Write mip 1 as render target - tracker is non-uniform
		let pass1 = scope RenderGraphPass("WriteMip1", .Render);
		pass1.Accesses.Add(.(RGHandle(0, 0), .WriteColorTarget, .(1, 1, 0, 1)));
		solver.EmitBarriers(pass1, resources, encoder);

		// Should emit one barrier for mip 1: Undefined -> RenderTarget
		Test.Assert(encoder.RecordedTextureBarriers.Count == 1);
		Test.Assert(encoder.RecordedTextureBarriers[0].OldState == .Undefined);
		Test.Assert(encoder.RecordedTextureBarriers[0].NewState == .RenderTarget);
		Test.Assert(encoder.RecordedTextureBarriers[0].BaseMipLevel == 1);
		Test.Assert(encoder.RecordedTextureBarriers[0].MipLevelCount == 1);
	}

	/// ReadableAfterWrite respects subresource ranges - only transitions written subresources.
	[Test]
	public static void ReadableAfterWrite_SubresourceAware()
	{
		let solver = scope BarrierSolver();
		let encoder = scope MockEncoder();

		let tex = scope MockTexture(.Undefined, mipLevels: 1, arrayLayers: 4);
		let view = scope MockTextureView(tex);

		let resources = scope List<RenderGraphResource>();
		let res = new RenderGraphResource("Tex", .Texture, .Imported);
		res.Texture = tex;
		res.TextureView = view;
		res.LastKnownState = .ShaderRead;
		res.ReadableAfterWrite = true;
		resources.Add(res);
		defer delete res;

		solver.Reset(resources);

		// Write layer 1 as depth target
		let writePass = scope RenderGraphPass("Writer", .Render);
		writePass.Accesses.Add(.(RGHandle(0, 0), .WriteDepthTarget, .(0, 1, 1, 1)));
		solver.EmitBarriers(writePass, resources, encoder);
		encoder.RecordedTextureBarriers.Clear();

		// Emit readable-after-write barriers
		solver.EmitReadableAfterWriteBarriers(writePass, resources, encoder);

		// Should transition layer 1 from DepthStencilWrite -> ShaderRead
		Test.Assert(encoder.RecordedTextureBarriers.Count == 1);
		Test.Assert(encoder.RecordedTextureBarriers[0].OldState == .DepthStencilWrite);
		Test.Assert(encoder.RecordedTextureBarriers[0].NewState == .ShaderRead);
		Test.Assert(encoder.RecordedTextureBarriers[0].BaseArrayLayer == 1);
		Test.Assert(encoder.RecordedTextureBarriers[0].ArrayLayerCount == 1);
	}

	/// Final transitions emit per-subresource barriers when the texture is non-uniform.
	[Test]
	public static void FinalTransition_NonUniform_EmitsPerSubresource()
	{
		let solver = scope BarrierSolver();
		let encoder = scope MockEncoder();

		let tex = scope MockTexture(.Undefined, mipLevels: 1, arrayLayers: 2);
		let view = scope MockTextureView(tex);

		let resources = scope List<RenderGraphResource>();
		let res = new RenderGraphResource("Swapchain", .Texture, .Imported);
		res.Texture = tex;
		res.TextureView = view;
		res.LastKnownState = .Undefined;
		res.FinalState = .Present;
		resources.Add(res);
		defer delete res;

		solver.Reset(resources);

		// Write layer 0 as render target, leave layer 1 as Undefined
		let writePass = scope RenderGraphPass("Blit", .Render);
		writePass.Accesses.Add(.(RGHandle(0, 0), .WriteColorTarget, .(0, 1, 0, 1)));
		solver.EmitBarriers(writePass, resources, encoder);
		encoder.RecordedTextureBarriers.Clear();

		// Emit final transitions -> both layers go to Present but from different old states
		solver.EmitFinalTransitions(resources, encoder);

		// Should emit 2 per-subresource barriers (different old states)
		Test.Assert(encoder.RecordedTextureBarriers.Count == 2);

		// Layer 0: RenderTarget -> Present
		bool foundLayer0 = false;
		bool foundLayer1 = false;
		for (let b in encoder.RecordedTextureBarriers)
		{
			if (b.BaseArrayLayer == 0 && b.OldState == .RenderTarget && b.NewState == .Present)
				foundLayer0 = true;
			if (b.BaseArrayLayer == 1 && b.OldState == .Undefined && b.NewState == .Present)
				foundLayer1 = true;
		}
		Test.Assert(foundLayer0);
		Test.Assert(foundLayer1);
	}

	/// No false barriers: writing to layer 0 then reading layer 1 should NOT emit a barrier
	/// for layer 1 since it was never written (stays in its original state).
	[Test]
	public static void NonOverlapping_SubresourceAccess_NoFalseBarrier()
	{
		let solver = scope BarrierSolver();
		let encoder = scope MockEncoder();

		let tex = scope MockTexture(.Undefined, mipLevels: 1, arrayLayers: 4);
		let view = scope MockTextureView(tex);

		let resources = scope List<RenderGraphResource>();
		let res = new RenderGraphResource("Array", .Texture, .Imported);
		res.Texture = tex;
		res.TextureView = view;
		res.LastKnownState = .ShaderRead;
		resources.Add(res);
		defer delete res;

		solver.Reset(resources);

		// Write layer 0
		let writePass = scope RenderGraphPass("WriteLayer0", .Render);
		writePass.Accesses.Add(.(RGHandle(0, 0), .WriteColorTarget, .(0, 1, 0, 1)));
		solver.EmitBarriers(writePass, resources, encoder);
		encoder.RecordedTextureBarriers.Clear();

		// Read layer 2 (which is still ShaderRead - no barrier needed)
		let readPass = scope RenderGraphPass("ReadLayer2", .Render);
		readPass.Accesses.Add(.(RGHandle(0, 0), .ReadTexture, .(0, 1, 2, 1)));
		solver.EmitBarriers(readPass, resources, encoder);

		// No barrier needed - layer 2 is already in ShaderRead
		Test.Assert(encoder.RecordedTextureBarriers.Count == 0);
	}

	/// Persistent resources preserve per-subresource state across UpdatePersistentStates.
	[Test]
	public static void PersistentResource_PreservesPerSubresourceState()
	{
		let solver = scope BarrierSolver();
		let encoder = scope MockEncoder();

		let tex = scope MockTexture(.Undefined, mipLevels: 1, arrayLayers: 2);
		let view = scope MockTextureView(tex);

		let resources = scope List<RenderGraphResource>();
		let res = new RenderGraphResource("Persistent", .Texture, .Persistent);
		res.Texture = tex;
		res.TextureView = view;
		let persistent = new PersistentResource(tex, view);
		persistent.FirstFrame = false;
		persistent.LastKnownState = .ShaderRead;
		res.PersistentData = persistent;
		resources.Add(res);
		defer delete res;

		solver.Reset(resources);

		// Write layer 0 -> non-uniform
		let writePass = scope RenderGraphPass("Writer", .Render);
		writePass.Accesses.Add(.(RGHandle(0, 0), .WriteColorTarget, .(0, 1, 0, 1)));
		solver.EmitBarriers(writePass, resources, encoder);

		// Save persistent state
		solver.UpdatePersistentStates(resources);

		// Persistent data should have per-subresource states stored
		Test.Assert(persistent.SubresourceStates != null);
		Test.Assert(persistent.SubresourceStates.Count == 2);
	}
}
