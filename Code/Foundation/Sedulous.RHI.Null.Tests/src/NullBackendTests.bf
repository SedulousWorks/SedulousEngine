using System;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.RHI.Null;

namespace Sedulous.RHI.Null.Tests;

/// Bringing the null backend up and walking the whole create and destroy surface.
class NullBackendTests
{
	[Test]
	public static void TheBackendEnumeratesOneAdapterAndMakesADevice()
	{
		let backend = NullRhi.CreateBackend();
		defer delete backend;
		Test.Assert(backend.IsInitialized);

		let adapters = backend.EnumerateAdapters();
		Test.Assert(adapters.Length == 1);

		let info = scope AdapterInfo();
		adapters[0].GetInfo(info);
		Test.Assert(info.Name == "Null Device");
		// Cpu so it sorts LAST: a process with a real GPU must never pick this by taking
		// element zero.
		Test.Assert(info.Type == .Cpu);

		Test.Assert(adapters[0].CreateDevice(.()) case .Ok(let device));
		Test.Assert(device.Type == .Null);
		Test.Assert(device.PreferredShaderFormat == .SpirV);
		Test.Assert(!device.NeedsClipSpaceYFlip);
		Test.Assert(!device.IsLost(), "a null device cannot be lost");
	}

	/// The requested features come back on the device, so a caller reads what it asked for
	/// rather than a fixed set.
	[Test]
	public static void TheDeviceReportsTheRequestedFeatures()
	{
		let backend = NullRhi.CreateBackend();
		defer delete backend;

		var desc = DeviceDesc();
		desc.RequiredFeatures.MeshShaders = true;
		desc.RequiredFeatures.MaxBindGroups = 8;

		Test.Assert(backend.EnumerateAdapters()[0].CreateDevice(desc) case .Ok(let device));
		Test.Assert(device.Features.MeshShaders);
		Test.Assert(device.Features.MaxBindGroups == 8);
	}

	[Test]
	public static void EveryQueueTypeResolvesAndCarriesItsType()
	{
		let backend = NullRhi.CreateBackend();
		defer delete backend;
		Test.Assert(backend.EnumerateAdapters()[0].CreateDevice(.()) case .Ok(let device));

		for (let type in QueueType[](.Graphics, .Compute, .Transfer))
		{
			let queue = device.GetQueue(type);
			Test.Assert(queue != null, scope $"{type} queue exists");
			Test.Assert(queue.QueueType == type, "and knows which it is");
			Test.Assert(device.GetQueueCount(type) == 1);
		}

		// Distinct objects, not one queue answering for all three.
		Test.Assert(device.GetQueue(.Graphics) !== device.GetQueue(.Compute));
		Test.Assert(device.GetQueue(.Compute) !== device.GetQueue(.Transfer));

		Test.Assert(device.GetQueue(.Graphics).TimestampPeriod() == 1.0f,
			"one nanosecond per tick, so a difference reads as nanoseconds");
	}

	/// A buffer is backed by REAL memory, which is what makes the null backend worth having:
	/// an upload or readback path can be exercised end to end.
	[Test]
	public static void ABufferMapsToRealMemoryThatRoundTrips()
	{
		let backend = NullRhi.CreateBackend();
		defer delete backend;
		Test.Assert(backend.EnumerateAdapters()[0].CreateDevice(.()) case .Ok(let device));

		var desc = BufferDesc();
		desc.Label = "NullBackendTests.ABufferMapsToRealMemoryThatRoundTrips";
		desc.Size = 256;
		desc.Usage = .Vertex | .CopyDst;
		desc.Memory = .CpuToGpu;

		Test.Assert(device.CreateBuffer(desc) case .Ok(var buffer));
		Test.Assert(buffer.Size == 256, "the descriptor came back through the interface");
		Test.Assert(buffer.Usage.HasFlag(.Vertex));

		let mapped = (uint8*)buffer.Map();
		Test.Assert(mapped != null);
		for (int i < 256)
			mapped[i] = (uint8)i;
		buffer.Unmap();

		// Mapping again sees the same storage.
		let again = (uint8*)buffer.Map();
		Test.Assert(again[0] == 0);
		Test.Assert(again[255] == 255, "the writes stuck");
		buffer.Unmap();

		device.DestroyBuffer(ref buffer);
		Test.Assert(buffer == null, "destroy nulls the caller's handle");
	}

	/// A zero sized buffer maps to nothing rather than to a dangling pointer.
	[Test]
	public static void AnEmptyBufferMapsToNull()
	{
		let backend = NullRhi.CreateBackend();
		defer delete backend;
		Test.Assert(backend.EnumerateAdapters()[0].CreateDevice(.()) case .Ok(let device));

		Test.Assert(device.CreateBuffer(.() { Label = "NullBackendTests.AnEmptyBufferMapsToNull" }) case .Ok(var buffer));
		Test.Assert(buffer.Map() == null);
		device.DestroyBuffer(ref buffer);
	}

	[Test]
	public static void TexturesAndViewsCarryTheirDescriptors()
	{
		let backend = NullRhi.CreateBackend();
		defer delete backend;
		Test.Assert(backend.EnumerateAdapters()[0].CreateDevice(.()) case .Ok(let device));

		var textureDesc = TextureDesc.RenderTarget(.RGBA8Unorm, 320, 240);
		textureDesc.Label = "NullBackendTests.TexturesAndViewsCarryTheirDescriptors";
		Test.Assert(device.CreateTexture(textureDesc) case .Ok(var texture));
		Test.Assert(texture.Desc.Width == 320);
		Test.Assert(texture.Desc.Format == .RGBA8Unorm);
		Test.Assert(texture.InitialState == .Undefined);

		texture.InitialState = .RenderTarget;
		Test.Assert(texture.InitialState == .RenderTarget, "the state is settable");

		var viewDesc = TextureViewDesc();
		viewDesc.Label = "NullBackendTests.TexturesAndViewsCarryTheirDescriptors";
		viewDesc.Format = .RGBA8Unorm;
		Test.Assert(device.CreateTextureView(texture, viewDesc) case .Ok(var view));
		Test.Assert(view.Texture === texture, "the view remembers what it views");
		Test.Assert(view.Desc.Format == .RGBA8Unorm);

		device.DestroyTextureView(ref view);
		device.DestroyTexture(ref texture);
		Test.Assert((view == null) && (texture == null));
	}

	/// Texture view ids are UNIQUE AND MONOTONIC.
	///
	/// The guard this exists for: a destroyed view's address can be handed straight to the
	/// next allocation, so a cache keyed on the object alone can hand out descriptors of a
	/// dead view. The id is what makes such a hit checkable.
	[Test]
	public static void TextureViewIdsAreUniqueAndMonotonic()
	{
		let backend = NullRhi.CreateBackend();
		defer delete backend;
		Test.Assert(backend.EnumerateAdapters()[0].CreateDevice(.()) case .Ok(let device));
		Test.Assert(device.CreateTexture(.() { Label = "NullBackendTests.TextureViewIdsAreUniqueAndMonotonic" }) case .Ok(var texture));

		Test.Assert(device.CreateTextureView(texture, .() { Label = "NullBackendTests.TextureViewIdsAreUniqueAndMonotonic" }) case .Ok(var first));
		let firstId = first.UniqueId;

		Test.Assert(device.CreateTextureView(texture, .() { Label = "NullBackendTests.TextureViewIdsAreUniqueAndMonotonic" }) case .Ok(var second));
		Test.Assert(second.UniqueId > firstId, "ids only go up");

		// Free the first and make another. Even if the allocator reuses the address, the id
		// must not repeat.
		device.DestroyTextureView(ref first);
		Test.Assert(device.CreateTextureView(texture, .() { Label = "NullBackendTests.TextureViewIdsAreUniqueAndMonotonic" }) case .Ok(var third));
		Test.Assert(third.UniqueId != firstId, "an id is never reused");
		Test.Assert(third.UniqueId > second.UniqueId);

		device.DestroyTextureView(ref second);
		device.DestroyTextureView(ref third);
		device.DestroyTexture(ref texture);
	}

	[Test]
	public static void TheRestOfTheCreationSurfaceRoundTrips()
	{
		let backend = NullRhi.CreateBackend();
		defer delete backend;
		Test.Assert(backend.EnumerateAdapters()[0].CreateDevice(.()) case .Ok(let device));

		Test.Assert(device.CreateSampler(.() { Label = "NullBackendTests.TheRestOfTheCreationSurfaceRoundTrips" }) case .Ok(var sampler));
		Test.Assert(sampler.Desc.MinFilter == .Linear);
		device.DestroySampler(ref sampler);

		Test.Assert(device.CreateShaderModule(.() { Label = "NullBackendTests.TheRestOfTheCreationSurfaceRoundTrips" }) case .Ok(var module));
		device.DestroyShaderModule(ref module);

		Test.Assert(device.CreateBindGroupLayout(.() { Label = "NullBackendTests.TheRestOfTheCreationSurfaceRoundTrips" }) case .Ok(var layout));
		Test.Assert(layout.Entries.IsEmpty);
		device.DestroyBindGroupLayout(ref layout);

		Test.Assert(device.CreateBindGroup(.() { Label = "NullBackendTests.TheRestOfTheCreationSurfaceRoundTrips" }) case .Ok(var group));
		device.DestroyBindGroup(ref group);

		Test.Assert(device.CreatePipelineLayout(.() { Label = "NullBackendTests.TheRestOfTheCreationSurfaceRoundTrips" }) case .Ok(var pipelineLayout));

		Test.Assert(device.CreatePipelineCache(.() { Label = "NullBackendTests.TheRestOfTheCreationSurfaceRoundTrips" }) case .Ok(var cache));
		Test.Assert(cache.GetDataSize() == 0);
		Test.Assert(cache.GetData(.()) case .Ok, "writing nothing matches the zero size");
		device.DestroyPipelineCache(ref cache);

		var renderDesc = RenderPipelineDesc();
		renderDesc.Label = "NullBackendTests.TheRestOfTheCreationSurfaceRoundTrips";
		renderDesc.Layout = pipelineLayout;
		Test.Assert(device.CreateRenderPipeline(renderDesc) case .Ok(var renderPipeline));
		Test.Assert(renderPipeline.Layout === pipelineLayout, "the pipeline keeps its layout");
		device.DestroyRenderPipeline(ref renderPipeline);

		var computeDesc = ComputePipelineDesc();
		computeDesc.Label = "NullBackendTests.TheRestOfTheCreationSurfaceRoundTrips";
		computeDesc.Layout = pipelineLayout;
		Test.Assert(device.CreateComputePipeline(computeDesc) case .Ok(var computePipeline));
		Test.Assert(computePipeline.Layout === pipelineLayout);
		device.DestroyComputePipeline(ref computePipeline);

		device.DestroyPipelineLayout(ref pipelineLayout);

		var querySetDesc = QuerySetDesc();
		querySetDesc.Label = "NullBackendTests.TheRestOfTheCreationSurfaceRoundTrips";
		querySetDesc.Type = .Occlusion;
		querySetDesc.Count = 16;
		Test.Assert(device.CreateQuerySet(querySetDesc) case .Ok(var querySet));
		Test.Assert(querySet.Type == .Occlusion);
		Test.Assert(querySet.Count == 16);
		device.DestroyQuerySet(ref querySet);

		device.WaitIdle();
	}

	[Test]
	public static void FormatSupportIsHonestAboutWhatItClaims()
	{
		let backend = NullRhi.CreateBackend();
		defer delete backend;
		Test.Assert(backend.EnumerateAdapters()[0].CreateDevice(.()) case .Ok(let device));

		let support = device.GetFormatSupport(.RGBA8Unorm);
		Test.Assert(support.HasFlag(.Texture));
		Test.Assert(support.HasFlag(.ColorAttachment));
		// NOT everything: a caller asking about storage images gets an honest no rather
		// than a yes it cannot rely on.
		Test.Assert(!support.HasFlag(.StorageTexture));

		// MSAA is refused by default, which is the safe answer for a backend that does not
		// implement the query.
		Test.Assert(device.MaxColorDepthSampleCount == 1);
		Test.Assert(device.SupportsSampleCount(1));
		Test.Assert(!device.SupportsSampleCount(4));
	}
}
