using System;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.Tests;

/// Descriptor DEFAULTS and factories.
///
/// The defaults are the contract: a caller fills in what it cares about and relies on the
/// rest, so a changed default silently changes every pipeline that did not name the field.
class DescriptorTests
{
	[Test]
	public static void ExtentDefaultsToFlatNotEmpty()
	{
		let extent = Extent3D();
		Test.Assert(extent.Width == 0);
		// One, not zero: a 2D extent must be valid with only width and height set, and a
		// zero depth would make the region empty rather than flat.
		Test.Assert(extent.Height == 1);
		Test.Assert(extent.Depth == 1);

		let sized = Extent3D(640, 480);
		Test.Assert((sized.Width == 640) && (sized.Height == 480) && (sized.Depth == 1));
	}

	[Test]
	public static void ClearColorDefaultsToOpaqueBlack()
	{
		let c = ClearColor();
		Test.Assert((c.R == 0) && (c.G == 0) && (c.B == 0));
		Test.Assert(c.A == 1, "opaque, not transparent");

		Test.Assert(ClearColor.White.R == 1);
		Test.Assert(ClearColor.Black.A == 1);
		Test.Assert(ClearColor.CornflowerBlue.B > ClearColor.CornflowerBlue.R);
	}

	[Test]
	public static void TextureDescFactoriesSetTheUsageTheirNameImplies()
	{
		let target = TextureDesc.RenderTarget(.RGBA8Unorm, 800, 600);
		Test.Assert(target.Format == .RGBA8Unorm);
		Test.Assert(target.Width == 800);
		Test.Assert(target.Height == 600);
		Test.Assert(target.SampleCount == 1);
		Test.Assert(target.Usage.HasFlag(.RenderTarget));
		Test.Assert(target.Usage.HasFlag(.Sampled), "an intermediate target is read again");
		Test.Assert(target.Dimension == .Texture2D);

		let depth = TextureDesc.DepthBuffer(.Depth32Float, 800, 600, 4);
		Test.Assert(depth.Usage.HasFlag(.DepthStencil));
		Test.Assert(!depth.Usage.HasFlag(.Sampled), "not sampled unless asked for");
		Test.Assert(depth.SampleCount == 4);
	}

	[Test]
	public static void SamplerDefaultsAreTrilinearRepeatWithNoComparison()
	{
		let s = SamplerDesc();
		Test.Assert(s.MinFilter == .Linear);
		Test.Assert(s.MagFilter == .Linear);
		Test.Assert(s.MipmapFilter == .Linear);
		Test.Assert(s.AddressU == .Repeat);
		Test.Assert(s.MaxAnisotropy == 1);
		Test.Assert(s.MaxLod == 1000.0f, "past any mip chain, so effectively unclamped");
		Test.Assert(s.Compare == null, "an ordinary sampler, not a comparison one");
		Test.Assert(s.BorderColor == .TransparentBlack);
	}

	[Test]
	public static void BindGroupLayoutFactoriesPickTheRightType()
	{
		let uniform = BindGroupLayoutEntry.UniformBuffer(0, .Vertex);
		Test.Assert(uniform.Binding == 0);
		Test.Assert(uniform.Visibility == .Vertex);
		Test.Assert(uniform.Type == .UniformBuffer);
		Test.Assert(uniform.Count == 1);

		let texture = BindGroupLayoutEntry.SampledTexture(1, .Fragment, .TextureCube);
		Test.Assert(texture.Type == .SampledTexture);
		Test.Assert(texture.TextureDimension == .TextureCube);

		let sampler = BindGroupLayoutEntry.Sampler(2, .Fragment);
		Test.Assert(sampler.Type == .Sampler);

		// Read only and read write are DIFFERENT binding types, not a flag.
		let readWrite = BindGroupLayoutEntry.StorageBuffer(3, .Compute, false, 32);
		Test.Assert(readWrite.Type == .StorageBufferReadWrite);
		Test.Assert(readWrite.StorageBufferStride == 32, "the DX12 structured stride");

		let readOnly = BindGroupLayoutEntry.StorageBuffer(4, .Compute, true);
		Test.Assert(readOnly.Type == .StorageBufferReadOnly);
		Test.Assert(readOnly.StorageBufferStride == 0, "raw, a byte address buffer");
	}

	[Test]
	public static void BindGroupEntryFactoriesSetOnlyTheirOwnField()
	{
		let buffer = BindGroupEntry.BufferEntry(null, 64, 256);
		Test.Assert(buffer.BufferOffset == 64);
		Test.Assert(buffer.BufferSize == 256);
		Test.Assert(buffer.TextureView == null);
		Test.Assert(buffer.Sampler == null);
		Test.Assert(buffer.AccelStruct == null);

		let texture = BindGroupEntry.TextureEntry(null);
		Test.Assert(texture.BufferSize == 0, "a texture entry leaves the buffer fields alone");
	}

	[Test]
	public static void BlendPresetsMatchTheirEquations()
	{
		let alpha = BlendState.AlphaBlend;
		Test.Assert(alpha.Color.SrcFactor == .SrcAlpha);
		Test.Assert(alpha.Color.DstFactor == .OneMinusSrcAlpha);
		Test.Assert(alpha.Color.Operation == .Add);
		// The alpha channel uses One, not SrcAlpha, so the result's alpha composites
		// correctly rather than being squared.
		Test.Assert(alpha.Alpha.SrcFactor == .One);

		let premultiplied = BlendState.PremultipliedAlpha;
		Test.Assert(premultiplied.Color.SrcFactor == .One, "the colour is already scaled");
		Test.Assert(premultiplied.Color.DstFactor == .OneMinusSrcAlpha);

		let additive = BlendState.Additive;
		Test.Assert((additive.Color.SrcFactor == .One) && (additive.Color.DstFactor == .One));

		let multiply = BlendState.Multiply;
		Test.Assert(multiply.Color.SrcFactor == .Dst);
		Test.Assert(multiply.Color.DstFactor == .Zero);
	}

	[Test]
	public static void PipelineStateDefaults()
	{
		let primitive = PrimitiveState();
		Test.Assert(primitive.Topology == .TriangleList);
		Test.Assert(primitive.FrontFace == .CCW);
		Test.Assert(primitive.CullMode == .None, "nothing culled until asked");
		Test.Assert(primitive.FillMode == .Solid);
		Test.Assert(primitive.DepthClipEnabled);

		let depth = DepthStencilState();
		Test.Assert(depth.DepthTestEnabled && depth.DepthWriteEnabled);
		Test.Assert(depth.DepthCompare == Depth.Nearer, "the default test names the depth convention");
		Test.Assert(!depth.StencilEnabled);
		Test.Assert((depth.StencilReadMask == 0xFF) && (depth.StencilWriteMask == 0xFF));
		Test.Assert(depth.StencilFront.Compare == .Always);
		Test.Assert(depth.StencilFront.PassOp == .Keep);

		let multisample = MultisampleState();
		Test.Assert(multisample.Count == 1);
		Test.Assert(multisample.Mask == 0xFFFFFFFF);
		Test.Assert(!multisample.AlphaToCoverageEnabled);

		let target = ColorTargetState();
		Test.Assert(target.Blend == null, "no blending disables the read entirely");
		Test.Assert(target.WriteMask == .All);

		let stage = ProgrammableStage();
		Test.Assert(stage.EntryPoint == "main");
		Test.Assert(stage.Stage == .None);
	}

	[Test]
	public static void AttachmentAndSwapChainDefaults()
	{
		let color = ColorAttachment();
		Test.Assert(color.LoadOp == .Clear);
		Test.Assert(color.StoreOp == .Store);
		Test.Assert(color.ClearValue.A == 1);
		Test.Assert(color.ResolveTarget == null);

		let depth = DepthStencilAttachment();
		Test.Assert(depth.DepthClearValue == Depth.ClearValue, "the far plane under the depth convention");
		Test.Assert(!depth.DepthReadOnly);
		Test.Assert(depth.StencilClearValue == 0);

		let swapChain = SwapChainDesc();
		Test.Assert(swapChain.Format == .BGRA8UnormSrgb);
		Test.Assert(swapChain.PresentMode == .Fifo, "the one mode every backend must have");
		Test.Assert(swapChain.BufferCount == 2);
	}

	/// Barrier ranges default to "the whole thing", so a caller transitioning an entire
	/// resource names nothing.
	[Test]
	public static void BarrierRangesDefaultToEverything()
	{
		let buffer = BufferBarrier();
		Test.Assert(buffer.Offset == 0);
		Test.Assert(buffer.Size == uint64.MaxValue);
		Test.Assert(buffer.OldState == .Undefined);

		let texture = TextureBarrier();
		Test.Assert(texture.BaseMipLevel == 0);
		Test.Assert(texture.MipLevelCount == uint32.MaxValue);
		Test.Assert(texture.ArrayLayerCount == uint32.MaxValue);
	}

	[Test]
	public static void DeviceFeatureDefaultsAreTheFloorNotZero()
	{
		let features = DeviceFeatures();

		// Capabilities start off, so a caller must ask for what it needs.
		Test.Assert(!features.BindlessDescriptors);
		Test.Assert(!features.MeshShaders);
		Test.Assert(!features.RayTracing);

		// Limits start at the floor every backend clears, so a device that reports nothing
		// still describes something buildable.
		Test.Assert(features.MaxBindGroups == 4);
		Test.Assert(features.MaxPushConstantSize == 128);
		Test.Assert(features.MaxTextureDimension2D == 8192);
		Test.Assert(features.MinUniformBufferOffsetAlignment == 256);
		Test.Assert(features.MaxBufferSize == 256 * 1024 * 1024);

		// Mesh limits stay at zero until a device reports support, so reading one without
		// checking MeshShaders gives a bound nothing satisfies rather than a plausible lie.
		Test.Assert(features.MaxMeshOutputVertices == 0);

		let desc = DeviceDesc();
		Test.Assert(desc.GraphicsQueueCount == 1);
		Test.Assert(desc.ComputeQueueCount == 0, "no dedicated compute queue by default");
	}

	[Test]
	public static void PushConstantRangeDefaultsToGroupOne()
	{
		let range = PushConstantRange();
		Test.Assert(range.Stages == .None);
		Test.Assert(range.BindGroupIndex == 1, "the engine's dominant push constant space");
	}

	/// The colour attachment list is inline and bounded by the RHI's own limit.
	[Test]
	public static void ColorAttachmentListIsInlineAndBounded()
	{
		var pass = RenderPassDesc();
		Test.Assert(pass.ColorAttachments.IsEmpty);
		Test.Assert(pass.Contents == .Inline);
		Test.Assert(pass.DepthStencilAttachment == null);

		var attachment = ColorAttachment();
		attachment.LoadOp = .Load;
		pass.ColorAttachments.Add(attachment);
		Test.Assert(pass.ColorAttachments.Count == 1);
		Test.Assert(pass.ColorAttachments[0].LoadOp == .Load);

		Test.Assert(ColorAttachmentList.Capacity == RhiLimits.MaxColorAttachments);
		Test.Assert(RhiLimits.MaxColorAttachments == 8);
	}

	[Test]
	public static void RayTracingGroupIndicesStartUnused()
	{
		let group = RayTracingShaderGroup();
		Test.Assert(group.Type == .General);
		// Not zero: zero is a legitimate index into the stage list.
		Test.Assert(group.GeneralShaderIndex == RayTracingShaderGroup.UnusedShader);
		Test.Assert(group.ClosestHitShaderIndex == RayTracingShaderGroup.UnusedShader);
		Test.Assert(RayTracingShaderGroup.UnusedShader == uint32.MaxValue);

		let aabbs = AccelStructGeometryAABBs();
		Test.Assert(aabbs.Stride == 24, "six floats: the two corners");

		let accel = AccelStructDesc();
		Test.Assert(accel.Type == .BottomLevel);
		Test.Assert(accel.Flags == .PreferFastTrace);
	}

	[Test]
	public static void AdapterPreferenceRanksDiscreteFirst()
	{
		Test.Assert(AdapterSelection.PreferenceRank(.DiscreteGpu) == 0);
		Test.Assert(AdapterSelection.PreferenceRank(.IntegratedGpu) == 1);
		Test.Assert(AdapterSelection.PreferenceRank(.Unknown) == 2);
		Test.Assert(AdapterSelection.PreferenceRank(.Cpu) == 3);

		// Strictly ordered, which is what makes element zero mean "the best available".
		Test.Assert(AdapterSelection.PreferenceRank(.DiscreteGpu)
			< AdapterSelection.PreferenceRank(.IntegratedGpu));
		Test.Assert(AdapterSelection.PreferenceRank(.Unknown)
			< AdapterSelection.PreferenceRank(.Cpu), "an unknown GPU beats a software one");
	}
}
