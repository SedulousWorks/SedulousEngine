using System;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.RHI.Validation;

namespace Sedulous.RHI.Validation.Tests;

/// The device's creation rules, and its resource tracking.
class DeviceValidationTests
{
	[Test]
	public static void TheLayerIsTransparentWhenNothingIsWrong()
	{
		let fixture = scope ValidationFixture();

		// A correct sequence reports NOTHING. A layer that cried wolf on valid usage would
		// be turned off, which is the only way it can fail completely.
		var desc = BufferDesc();
		desc.Size = 64;
		Test.Assert(fixture.Device.CreateBuffer(desc) case .Ok(var buffer));
		fixture.Own(buffer);
		fixture.Device.DestroyBuffer(ref buffer);

		let described = scope String();
		fixture.Messages.Describe(described);
		Test.Assert(fixture.Messages.Count == 0, scope $"reported: {described}");

		// And it forwards: the device under it still answers for itself.
		Test.Assert(fixture.Device.Type == .Null);
		Test.Assert(fixture.Device.PreferredShaderFormat == .SpirV);
		Test.Assert(fixture.Device.GetQueueCount(.Graphics) == 1);
	}

	[Test]
	public static void AZeroSizedBufferIsRefused()
	{
		let fixture = scope ValidationFixture();
		Test.Assert(fixture.Device.CreateBuffer(.()) case .Err);
		Test.Assert(fixture.Messages.HasError("size is zero"));
	}

	/// A DX12 upload heap cannot allow unordered access, so this combination works on
	/// Vulkan and fails on DX12. Catching it here is the point: the bug would otherwise be
	/// found only on the other backend.
	[Test]
	public static void StorageOnCpuVisibleMemoryIsRefused()
	{
		let fixture = scope ValidationFixture();

		var upload = BufferDesc();
		upload.Size = 64;
		upload.Usage = .Storage;
		upload.Memory = .CpuToGpu;
		Test.Assert(fixture.Device.CreateBuffer(upload) case .Err);
		Test.Assert(fixture.Messages.HasError("not compatible with CpuToGpu"));

		fixture.Messages.Clear();
		var readback = BufferDesc();
		readback.Size = 64;
		readback.Usage = .Storage;
		readback.Memory = .GpuToCpu;
		Test.Assert(fixture.Device.CreateBuffer(readback) case .Err);
		Test.Assert(fixture.Messages.HasError("not compatible with GpuToCpu"));

		// StorageRead is the way to have a mappable buffer a shader reads, so it passes.
		fixture.Messages.Clear();
		var readOnly = BufferDesc();
		readOnly.Size = 64;
		readOnly.Usage = .StorageRead;
		readOnly.Memory = .CpuToGpu;
		Test.Assert(fixture.Device.CreateBuffer(readOnly) case .Ok(var buffer));
		fixture.Own(buffer);
		Test.Assert(fixture.Messages.Count == 0, "the documented alternative is not flagged");
		fixture.Device.DestroyBuffer(ref buffer);
	}

	[Test]
	public static void ZeroSizedTexturesAndEmptyShadersAreRefused()
	{
		let fixture = scope ValidationFixture();

		var texture = TextureDesc();
		texture.Width = 0;
		texture.Height = 16;
		Test.Assert(fixture.Device.CreateTexture(texture) case .Err);
		Test.Assert(fixture.Messages.HasError("width or height is zero"));

		fixture.Messages.Clear();
		Test.Assert(fixture.Device.CreateShaderModule(.()) case .Err);
		Test.Assert(fixture.Messages.HasError("code is empty"));

		fixture.Messages.Clear();
		Test.Assert(fixture.Device.CreateQuerySet(.()) case .Err);
		Test.Assert(fixture.Messages.HasError("count is zero"));
	}

	[Test]
	public static void PipelinesNeedALayoutAndAShader()
	{
		let fixture = scope ValidationFixture();
		Test.Assert(fixture.Device.CreatePipelineLayout(.()) case .Ok(var layout));
		fixture.Own(layout);
		Test.Assert(fixture.Device.CreateShaderModule(
			.() { Code = scope uint8[4](1, 2, 3, 4) }) case .Ok(var module));
			fixture.Own(module);
		fixture.Messages.Clear();

		// Render: layout, then vertex shader.
		Test.Assert(fixture.Device.CreateRenderPipeline(.()) case .Err);
		Test.Assert(fixture.Messages.HasError("CreateRenderPipeline: layout is null"));

		fixture.Messages.Clear();
		var render = RenderPipelineDesc();
		render.Layout = layout;
		Test.Assert(fixture.Device.CreateRenderPipeline(render) case .Err);
		Test.Assert(fixture.Messages.HasError("vertex shader module is null"));

		fixture.Messages.Clear();
		render.Vertex.Shader.Module = module;
		Test.Assert(fixture.Device.CreateRenderPipeline(render) case .Ok(var renderPipeline));
		fixture.Own(renderPipeline);
		Test.Assert(fixture.Messages.Count == 0, "a complete descriptor passes");
		fixture.Device.DestroyRenderPipeline(ref renderPipeline);

		// Compute: the same two.
		fixture.Messages.Clear();
		Test.Assert(fixture.Device.CreateComputePipeline(.()) case .Err);
		Test.Assert(fixture.Messages.HasError("CreateComputePipeline: layout is null"));

		fixture.Messages.Clear();
		var compute = ComputePipelineDesc();
		compute.Layout = layout;
		Test.Assert(fixture.Device.CreateComputePipeline(compute) case .Err);
		Test.Assert(fixture.Messages.HasError("compute shader module is null"));

		fixture.Device.DestroyShaderModule(ref module);
		fixture.Device.DestroyPipelineLayout(ref layout);
	}

	/// Viewing a texture the device does not know about reads freed memory. Tracking is
	/// what makes that detectable at all.
	[Test]
	public static void ViewingADestroyedTextureIsReported()
	{
		let fixture = scope ValidationFixture();

		var texture = fixture.MakeTexture();
		fixture.Messages.Clear();

		// While it is alive, no complaint.
		Test.Assert(fixture.Device.CreateTextureView(texture, .()) case .Ok(var view));
		fixture.Own(view);
		Test.Assert(fixture.Messages.Count == 0);

		fixture.Device.DestroyTextureView(ref view);
		let stale = texture;
		fixture.Device.DestroyTexture(ref texture);
		fixture.Messages.Clear();

		// Through the stale handle, it is caught.
		fixture.Device.CreateTextureView(stale, .()).IgnoreError();
		Test.Assert(fixture.Messages.HasError("was destroyed, or was not created by this device"));

		fixture.Messages.Clear();
		Test.Assert(fixture.Device.CreateTextureView(null, .()) case .Err);
		Test.Assert(fixture.Messages.HasError("texture is null"));
	}

	[Test]
	public static void DestroyingTwiceIsReported()
	{
		let fixture = scope ValidationFixture();

		var buffer = fixture.MakeBuffer();
		let stale = buffer;
		fixture.Device.DestroyBuffer(ref buffer);
		Test.Assert(buffer == null);
		fixture.Messages.Clear();

		// The same object again: the device no longer knows it.
		var again = stale;
		fixture.Device.DestroyBuffer(ref again);
		Test.Assert(fixture.Messages.HasWarning("not tracked"));
	}

	/// A resource outliving its device is a leak everywhere and a crash on some backends.
	[Test]
	public static void DestroyingADeviceWithLiveResourcesIsReported()
	{
		let fixture = scope ValidationFixture();

		fixture.MakeBuffer();
		fixture.MakeBuffer();
		fixture.MakeTexture();
		fixture.Messages.Clear();

		fixture.Device.Destroy();

		Test.Assert(fixture.Messages.HasWarning("2 live Buffer(s)"), "the count and the kind");
		Test.Assert(fixture.Messages.HasWarning("1 live Texture(s)"));

		// And destroying it again is itself an error.
		fixture.Messages.Clear();
		fixture.Device.Destroy();
		Test.Assert(fixture.Messages.HasError("already destroyed"));
	}

	[Test]
	public static void UsingADestroyedDeviceIsRefused()
	{
		let fixture = scope ValidationFixture();
		fixture.Device.Destroy();
		fixture.Messages.Clear();

		var desc = BufferDesc();
		desc.Size = 64;
		Test.Assert(fixture.Device.CreateBuffer(desc) case .Err);
		Test.Assert(fixture.Messages.HasError("the device is destroyed"));

		fixture.Messages.Clear();
		Test.Assert(fixture.Device.CreateCommandPool(.Graphics) case .Err);
		Test.Assert(fixture.Messages.HasError("the device is destroyed"));

		fixture.Messages.Clear();
		Test.Assert(fixture.Device.CreateFence(0) case .Err);
		Test.Assert(fixture.Messages.HasError("the device is destroyed"));
	}

	[Test]
	public static void ASwapChainNeedsASurfaceAndASize()
	{
		let fixture = scope ValidationFixture();

		var desc = SwapChainDesc();
		desc.Width = 64; desc.Height = 64;
		Test.Assert(fixture.Device.CreateSwapChain(null, desc) case .Err);
		Test.Assert(fixture.Messages.HasError("surface is null"));

		fixture.Messages.Clear();
		Test.Assert(fixture.Backend.CreateSurface((void*)(int)1) case .Ok(let surface));
		fixture.Messages.Clear();

		var zeroSize = SwapChainDesc();
		Test.Assert(fixture.Device.CreateSwapChain(surface, zeroSize) case .Err);
		Test.Assert(fixture.Messages.HasError("width or height is zero"));
	}

	/// The bind group entries are POSITIONAL against the layout's non bindless slots, so a
	/// count mismatch binds every resource one slot out and nothing looks wrong.
	[Test]
	public static void ABindGroupMustMatchItsLayout()
	{
		let fixture = scope ValidationFixture();

		Test.Assert(fixture.Device.CreateBindGroup(.()) case .Err);
		Test.Assert(fixture.Messages.HasError("layout is null"));

		fixture.Messages.Clear();
		Test.Assert(fixture.Device.CreateBindGroupLayout(.()) case .Ok(var layout));
		fixture.Own(layout);
		fixture.Messages.Clear();

		// The null backend's layout reports no entries, so ONE entry is one too many.
		var desc = BindGroupDesc();
		desc.Layout = layout;
		let entries = scope BindGroupEntry[1];
		desc.Entries = entries;
		Test.Assert(fixture.Device.CreateBindGroup(desc) case .Err);
		Test.Assert(fixture.Messages.HasError("does not match"));

		fixture.Messages.Clear();
		var matching = BindGroupDesc();
		matching.Layout = layout;
		Test.Assert(fixture.Device.CreateBindGroup(matching) case .Ok(var group));
		fixture.Own(group);
		Test.Assert(fixture.Messages.Count == 0);
		fixture.Device.DestroyBindGroup(ref group);
		fixture.Device.DestroyBindGroupLayout(ref layout);
	}
}
