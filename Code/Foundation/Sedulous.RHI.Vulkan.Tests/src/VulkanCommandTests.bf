using System;
using Sedulous.Core;
using Sedulous.RHI;
using Bulkan;
using Sedulous.RHI.Vulkan;

namespace Sedulous.RHI.Vulkan.Tests;

/// The command tier end to end on the real GPU: staged upload, recorded work, submission,
/// timeline wait, readback.
///
/// These are the only tests that prove the pieces AGREE. Each tier passes on its own with a
/// pool that hands out handles nothing submits and a pipeline nothing dispatches; a number
/// that comes back doubled could only have come from every one of them working.
class VulkanCommandTests
{
	private static IBackend sBackend;
	private static IDevice sDevice;

	/// The compute shader's local size, so one dispatch covers the whole buffer.
	private const int cElementCount = 64;

	private static bool Ready()
	{
		if (sDevice != null)
			return true;
		if (!(VulkanRhi.CreateBackend(false) case .Ok(let backend)))
			return false;
		sBackend = backend;
		let adapters = backend.EnumerateAdapters();
		if (adapters.IsEmpty)
			return false;

		let info = scope AdapterInfo();
		adapters[0].GetInfo(info);
		var desc = DeviceDesc();
		desc.RequiredFeatures = info.SupportedFeatures;
		if (!(adapters[0].CreateDevice(desc) case .Ok(let device)))
			return false;
		sDevice = device;
		return true;
	}

	/// A transfer batch stages a buffer's contents and a copy brings them back unchanged.
	///
	/// Separate from the compute round trip so a failure says WHICH half broke: the upload
	/// path, or the dispatch on top of it.
	[Test]
	public static void AStagedUploadArrivesInTheBuffer()
	{
		if (!Ready()) { Console.WriteLine("SKIP: no Vulkan"); return; }

		let queue = sDevice.GetQueue(.Graphics);
		Test.Assert(queue != null, "the device has a graphics queue");

		var source = uint32[cElementCount]();
		for (int i < cElementCount)
			source[i] = (uint32)(i + 1);

		var storageDesc = BufferDesc();
		storageDesc.Size = cElementCount * sizeof(uint32);
		storageDesc.Usage = .CopyDst | .CopySrc;
		storageDesc.Memory = .GpuOnly;
		Test.Assert(sDevice.CreateBuffer(storageDesc) case .Ok(var storage));

		var readbackDesc = BufferDesc();
		readbackDesc.Size = storageDesc.Size;
		readbackDesc.Usage = .CopyDst;
		readbackDesc.Memory = .GpuToCpu;
		Test.Assert(sDevice.CreateBuffer(readbackDesc) case .Ok(var readback));

		Test.Assert(queue.CreateTransferBatch() case .Ok(var batch));
		batch.WriteBuffer(storage, 0, .((uint8*)&source[0], (int)storageDesc.Size));
		Test.Assert(batch.Submit() case .Ok, "the staged write submitted and completed");

		CopyBack(queue, storage, readback, storageDesc.Size);

		let mapped = (uint32*)readback.Map();
		Test.Assert(mapped != null, "a GpuToCpu buffer is mapped");
		for (int i < cElementCount)
			Test.Assert(mapped[i] == (uint32)(i + 1), "the staged value survived the round trip");
		readback.Unmap();

		queue.DestroyTransferBatch(ref batch);
		sDevice.DestroyBuffer(ref readback);
		sDevice.DestroyBuffer(ref storage);
	}

	/// Upload, dispatch, read back: the value comes back DOUBLED, which the shader can only
	/// produce by having read what the transfer batch wrote.
	[Test]
	public static void ADispatchDoublesTheUploadedData()
	{
		if (!Ready()) { Console.WriteLine("SKIP: no Vulkan"); return; }

		// A dedicated compute queue where the device has one, the graphics queue otherwise:
		// either can run the dispatch and the copy that follows it.
		var queue = sDevice.GetQueue(.Compute);
		if (queue == null)
			queue = sDevice.GetQueue(.Graphics);
		Test.Assert(queue != null);

		var source = uint32[cElementCount]();
		for (int i < cElementCount)
			source[i] = (uint32)(i + 1);

		let byteSize = (uint64)(cElementCount * sizeof(uint32));

		var storageDesc = BufferDesc();
		storageDesc.Size = byteSize;
		storageDesc.Usage = .Storage | .CopyDst | .CopySrc;
		storageDesc.Memory = .GpuOnly;
		Test.Assert(sDevice.CreateBuffer(storageDesc) case .Ok(var storage));

		var readbackDesc = BufferDesc();
		readbackDesc.Size = byteSize;
		readbackDesc.Usage = .CopyDst;
		readbackDesc.Memory = .GpuToCpu;
		Test.Assert(sDevice.CreateBuffer(readbackDesc) case .Ok(var readback));

		// Upload first, so the dispatch has something to double.
		Test.Assert(queue.CreateTransferBatch() case .Ok(var batch));
		batch.WriteBuffer(storage, 0, .((uint8*)&source[0], (int)byteSize));
		Test.Assert(batch.Submit() case .Ok);

		var moduleDesc = ShaderModuleDesc();
		moduleDesc.Code = TestShaders.AsBytes(&TestShaders.ComputeDouble[0],
			TestShaders.ComputeDouble.Count);
		Test.Assert(sDevice.CreateShaderModule(moduleDesc) case .Ok(var module));

		// Register u0: the backend applies the UAV shift, landing it on binding 200, which
		// is what the shader was compiled against.
		var entry = BindGroupLayoutEntry.StorageBuffer(0, .Compute);
		var layoutDesc = BindGroupLayoutDesc();
		layoutDesc.Entries = .(&entry, 1);
		Test.Assert(sDevice.CreateBindGroupLayout(layoutDesc) case .Ok(var bindLayout));

		var bindEntry = BindGroupEntry.BufferEntry(storage, 0, byteSize);
		var groupDesc = BindGroupDesc();
		groupDesc.Layout = bindLayout;
		groupDesc.Entries = .(&bindEntry, 1);
		Test.Assert(sDevice.CreateBindGroup(groupDesc) case .Ok(var bindGroup));

		var pipelineLayoutDesc = PipelineLayoutDesc();
		pipelineLayoutDesc.BindGroupLayouts = .(&bindLayout, 1);
		Test.Assert(sDevice.CreatePipelineLayout(pipelineLayoutDesc) case .Ok(var pipelineLayout));

		var pipelineDesc = ComputePipelineDesc();
		pipelineDesc.Layout = pipelineLayout;
		pipelineDesc.Compute = .(module, "main", .Compute);
		Test.Assert(sDevice.CreateComputePipeline(pipelineDesc) case .Ok(var pipeline));

		Test.Assert(sDevice.CreateCommandPool(queue.QueueType) case .Ok(var pool));
		Test.Assert(pool.CreateEncoder() case .Ok(var encoder));

		encoder.TransitionBuffer(storage, .CopyDst, .ShaderWrite);
		let pass = encoder.BeginComputePass("double");
		Test.Assert(pass != null, "the compute pass opened");
		pass.SetPipeline(pipeline);
		pass.SetBindGroup(0, bindGroup);
		pass.Dispatch(1);
		pass.End();
		// The copy reads what the dispatch wrote, so it has to wait for it.
		encoder.TransitionBuffer(storage, .ShaderWrite, .CopySrc);
		encoder.CopyBufferToBuffer(storage, 0, readback, 0, byteSize);

		let commandBuffer = encoder.Finish();
		Test.Assert(commandBuffer != null, "the encoder produced a command buffer");

		Test.Assert(sDevice.CreateFence(0) case .Ok(var fence));
		var buffers = ICommandBuffer[1](commandBuffer);
		queue.Submit(buffers, fence, 1);
		Test.Assert(fence.Wait(1), "the timeline reached the submitted value");
		Test.Assert(fence.CompletedValue() == 1, "and the fence reports it");

		let mapped = (uint32*)readback.Map();
		Test.Assert(mapped != null);
		for (int i < cElementCount)
			Test.Assert(mapped[i] == (uint32)((i + 1) * 2), "the shader doubled every element");
		readback.Unmap();

		sDevice.DestroyFence(ref fence);
		pool.DestroyEncoder(ref encoder);
		sDevice.DestroyCommandPool(ref pool);
		sDevice.DestroyComputePipeline(ref pipeline);
		sDevice.DestroyPipelineLayout(ref pipelineLayout);
		sDevice.DestroyBindGroup(ref bindGroup);
		sDevice.DestroyBindGroupLayout(ref bindLayout);
		sDevice.DestroyShaderModule(ref module);
		queue.DestroyTransferBatch(ref batch);
		sDevice.DestroyBuffer(ref readback);
		sDevice.DestroyBuffer(ref storage);
	}

	/// A batch that is reset and refilled writes the NEW contents, not the old ones, which
	/// is what makes a batch reusable across frames.
	[Test]
	public static void AResetBatchStagesTheNewContents()
	{
		if (!Ready()) { Console.WriteLine("SKIP: no Vulkan"); return; }

		let queue = sDevice.GetQueue(.Graphics);
		let byteSize = (uint64)(cElementCount * sizeof(uint32));

		var storageDesc = BufferDesc();
		storageDesc.Size = byteSize;
		storageDesc.Usage = .CopyDst | .CopySrc;
		storageDesc.Memory = .GpuOnly;
		Test.Assert(sDevice.CreateBuffer(storageDesc) case .Ok(var storage));

		var readbackDesc = BufferDesc();
		readbackDesc.Size = byteSize;
		readbackDesc.Usage = .CopyDst;
		readbackDesc.Memory = .GpuToCpu;
		Test.Assert(sDevice.CreateBuffer(readbackDesc) case .Ok(var readback));

		Test.Assert(queue.CreateTransferBatch() case .Ok(var batch));

		var first = uint32[cElementCount]();
		for (int i < cElementCount)
			first[i] = 111;
		batch.WriteBuffer(storage, 0, .((uint8*)&first[0], (int)byteSize));
		Test.Assert(batch.Submit() case .Ok);

		batch.Reset();

		var second = uint32[cElementCount]();
		for (int i < cElementCount)
			second[i] = 222;
		batch.WriteBuffer(storage, 0, .((uint8*)&second[0], (int)byteSize));
		Test.Assert(batch.Submit() case .Ok);

		CopyBack(queue, storage, readback, byteSize);

		let mapped = (uint32*)readback.Map();
		Test.Assert(mapped != null);
		// A batch that failed to reset would replay the first write after the second and
		// leave 111 here.
		Test.Assert(mapped[0] == 222, "the second write is what landed");
		Test.Assert(mapped[cElementCount - 1] == 222);
		readback.Unmap();

		queue.DestroyTransferBatch(ref batch);
		sDevice.DestroyBuffer(ref readback);
		sDevice.DestroyBuffer(ref storage);
	}

	/// A batch bigger than the initial staging buffer grows it and keeps everything already
	/// staged, which is the case that silently corrupts if the grow forgets to carry it.
	[Test]
	public static void AGrownStagingBufferKeepsWhatWasAlreadyStaged()
	{
		if (!Ready()) { Console.WriteLine("SKIP: no Vulkan"); return; }

		let queue = sDevice.GetQueue(.Graphics);
		// Two writes of three megabytes each: the first fits the four megabyte initial
		// staging buffer, the second forces it to grow.
		const int cChunkBytes = 3 * 1024 * 1024;
		const int cChunkElements = cChunkBytes / sizeof(uint32);

		var chunk = new uint32[cChunkElements];
		defer delete chunk;

		var descriptor = BufferDesc();
		descriptor.Size = cChunkBytes;
		descriptor.Usage = .CopyDst | .CopySrc;
		descriptor.Memory = .GpuOnly;
		Test.Assert(sDevice.CreateBuffer(descriptor) case .Ok(var firstBuffer));
		Test.Assert(sDevice.CreateBuffer(descriptor) case .Ok(var secondBuffer));

		var readbackDesc = BufferDesc();
		readbackDesc.Size = cChunkBytes;
		readbackDesc.Usage = .CopyDst;
		readbackDesc.Memory = .GpuToCpu;
		Test.Assert(sDevice.CreateBuffer(readbackDesc) case .Ok(var readback));

		Test.Assert(queue.CreateTransferBatch() case .Ok(var batch));

		for (int i < cChunkElements)
			chunk[i] = 0xAAAAAAAA;
		batch.WriteBuffer(firstBuffer, 0, .((uint8*)&chunk[0], cChunkBytes));

		for (int i < cChunkElements)
			chunk[i] = 0xBBBBBBBB;
		batch.WriteBuffer(secondBuffer, 0, .((uint8*)&chunk[0], cChunkBytes));

		Test.Assert(batch.Submit() case .Ok);

		// The FIRST write is the one at risk: it was staged before the grow, so it only
		// survives if the grow copied it across.
		CopyBack(queue, firstBuffer, readback, cChunkBytes);
		var mapped = (uint32*)readback.Map();
		Test.Assert(mapped != null);
		Test.Assert(mapped[0] == 0xAAAAAAAA, "the pre-grow write survived the grow");
		Test.Assert(mapped[cChunkElements - 1] == 0xAAAAAAAA);
		readback.Unmap();

		CopyBack(queue, secondBuffer, readback, cChunkBytes);
		mapped = (uint32*)readback.Map();
		Test.Assert(mapped[0] == 0xBBBBBBBB, "and the write that caused it landed too");
		readback.Unmap();

		queue.DestroyTransferBatch(ref batch);
		sDevice.DestroyBuffer(ref readback);
		sDevice.DestroyBuffer(ref secondBuffer);
		sDevice.DestroyBuffer(ref firstBuffer);
	}

	/// An encoder can be destroyed AFTER the pool it came from was reset.
	///
	/// That order is ordinary: a caller resets the pool for the next frame and then
	/// releases the encoder it still holds. A reset that freed encoders itself would turn
	/// the following destroy into a read of freed memory, which is a crash rather than a
	/// wrong picture.
	[Test]
	public static void AnEncoderSurvivesUntilItIsDestroyed()
	{
		if (!Ready()) { Console.WriteLine("SKIP: no Vulkan"); return; }

		let queue = sDevice.GetQueue(.Graphics);
		Test.Assert(sDevice.CreateCommandPool(.Graphics) case .Ok(var pool));
		Test.Assert(sDevice.CreateFence(0) case .Ok(var fence));

		var descriptor = BufferDesc();
		descriptor.Size = 256;
		descriptor.Usage = .CopyDst | .CopySrc;
		descriptor.Memory = .GpuOnly;
		Test.Assert(sDevice.CreateBuffer(descriptor) case .Ok(var source));
		Test.Assert(sDevice.CreateBuffer(descriptor) case .Ok(var destination));

		Test.Assert(pool.CreateEncoder() case .Ok(var encoder));
		encoder.CopyBufferToBuffer(source, 0, destination, 0, 256);
		var buffers = ICommandBuffer[1](encoder.Finish());
		queue.Submit(buffers, fence, 1);
		Test.Assert(fence.Wait(1));

		// Reset FIRST, destroy after: the sequence the samples use.
		pool.Reset();
		pool.DestroyEncoder(ref encoder);
		Test.Assert(encoder == null, "the caller's handle was cleared");

		// The pool is still usable, so the reset did what it was for.
		Test.Assert(pool.CreateEncoder() case .Ok(var next));
		next.CopyBufferToBuffer(source, 0, destination, 0, 256);
		var moreBuffers = ICommandBuffer[1](next.Finish());
		queue.Submit(moreBuffers, fence, 2);
		Test.Assert(fence.Wait(2), "the pool still works afterwards");
		pool.DestroyEncoder(ref next);

		sDevice.DestroyFence(ref fence);
		sDevice.DestroyCommandPool(ref pool);
		sDevice.DestroyBuffer(ref destination);
		sDevice.DestroyBuffer(ref source);
	}

	/// A pool hands out a fresh encoder after a reset, and the second one records and
	/// submits just as the first did.
	[Test]
	public static void APoolIsReusableAfterReset()
	{
		if (!Ready()) { Console.WriteLine("SKIP: no Vulkan"); return; }

		let queue = sDevice.GetQueue(.Graphics);
		Test.Assert(sDevice.CreateCommandPool(.Graphics) case .Ok(var pool));

		var descriptor = BufferDesc();
		descriptor.Size = 256;
		descriptor.Usage = .CopyDst | .CopySrc;
		descriptor.Memory = .GpuOnly;
		Test.Assert(sDevice.CreateBuffer(descriptor) case .Ok(var source));
		Test.Assert(sDevice.CreateBuffer(descriptor) case .Ok(var destination));

		Test.Assert(sDevice.CreateFence(0) case .Ok(var fence));

		for (uint64 pass = 1; pass <= 2; ++pass)
		{
			Test.Assert(pool.CreateEncoder() case .Ok(var encoder));
			encoder.CopyBufferToBuffer(source, 0, destination, 0, 256);
			let commandBuffer = encoder.Finish();
			Test.Assert(commandBuffer != null);

			var buffers = ICommandBuffer[1](commandBuffer);
			queue.Submit(buffers, fence, pass);
			Test.Assert(fence.Wait(pass), "the submission from the reused pool completed");

			pool.DestroyEncoder(ref encoder);
			pool.Reset();
		}

		Test.Assert(fence.CompletedValue() == 2, "both submissions signalled in order");

		sDevice.DestroyFence(ref fence);
		sDevice.DestroyCommandPool(ref pool);
		sDevice.DestroyBuffer(ref destination);
		sDevice.DestroyBuffer(ref source);
	}

	/// A texture upload whose rows are PADDED lands with the padding stripped.
	///
	/// The stride is the case that separates a correct upload from one that ignores the
	/// layout: with a tight stride both behave the same, so only a padded one shows whether
	/// the row length reached Vulkan.
	[Test]
	public static void APaddedTextureUploadStripsTheRowPadding()
	{
		if (!Ready()) { Console.WriteLine("SKIP: no Vulkan"); return; }

		let queue = sDevice.GetQueue(.Graphics);

		const uint32 cWidth = 4;
		const uint32 cHeight = 4;
		const uint32 cBytesPerPixel = 4;
		// A stride wider than the four pixels the rows actually hold, which is what an
		// aligned upload looks like.
		const uint32 cPaddedStride = 32;

		var textureDesc = TextureDesc();
		textureDesc.Format = .RGBA8Unorm;
		textureDesc.Width = cWidth;
		textureDesc.Height = cHeight;
		textureDesc.Usage = .Sampled | .CopyDst | .CopySrc;
		Test.Assert(sDevice.CreateTexture(textureDesc) case .Ok(var texture));

		// Every pixel gets its row and column, so a row picked up at the wrong stride shows
		// up as the wrong value rather than as plausible noise.
		var staging = new uint8[cPaddedStride * cHeight];
		defer delete staging;
		for (uint32 y < cHeight)
			for (uint32 x < cWidth)
			{
				let at = y * cPaddedStride + x * cBytesPerPixel;
				staging[at + 0] = (uint8)(x + 1);
				staging[at + 1] = (uint8)(y + 1);
				staging[at + 2] = 0xCC;
				staging[at + 3] = 0xFF;
			}

		var layout = TextureDataLayout();
		layout.BytesPerRow = cPaddedStride;
		layout.RowsPerImage = cHeight;

		Test.Assert(queue.CreateTransferBatch() case .Ok(var batch));
		batch.WriteTexture(texture, .(&staging[0], staging.Count), layout,
			.(cWidth, cHeight, 1));
		Test.Assert(batch.Submit() case .Ok, "the texture upload submitted");

		// Read back TIGHTLY packed, so what comes out is the image itself rather than the
		// stride it was uploaded at.
		let tightSize = (uint64)(cWidth * cHeight * cBytesPerPixel);
		var readbackDesc = BufferDesc();
		readbackDesc.Size = tightSize;
		readbackDesc.Usage = .CopyDst;
		readbackDesc.Memory = .GpuToCpu;
		Test.Assert(sDevice.CreateBuffer(readbackDesc) case .Ok(var readback));

		Test.Assert(sDevice.CreateCommandPool(.Graphics) case .Ok(var pool));
		Test.Assert(pool.CreateEncoder() case .Ok(var encoder));

		// The batch left it shader readable, which is where the copy has to transition from.
		encoder.TransitionTexture(texture, .ShaderRead, .CopySrc);

		var region = BufferTextureCopyRegion();
		region.BytesPerRow = cWidth * cBytesPerPixel;
		region.RowsPerImage = cHeight;
		region.TextureExtent = .(cWidth, cHeight, 1);
		encoder.CopyTextureToBuffer(texture, readback, region);

		var buffers = ICommandBuffer[1](encoder.Finish());
		queue.Submit(buffers);
		queue.WaitIdle();

		let mapped = (uint8*)readback.Map();
		Test.Assert(mapped != null);
		for (uint32 y < cHeight)
			for (uint32 x < cWidth)
			{
				let at = (y * cWidth + x) * cBytesPerPixel;
				Test.Assert(mapped[at + 0] == (uint8)(x + 1), "the column survived the stride");
				Test.Assert(mapped[at + 1] == (uint8)(y + 1), "and so did the row");
			}
		readback.Unmap();

		pool.DestroyEncoder(ref encoder);
		sDevice.DestroyCommandPool(ref pool);
		queue.DestroyTransferBatch(ref batch);
		sDevice.DestroyBuffer(ref readback);
		sDevice.DestroyTexture(ref texture);
	}

	/// A readback into a PADDED buffer lands one image row per buffer row.
	///
	/// A copy destination's rows are usually aligned, to 256 bytes for DX12 compatibility,
	/// so the buffer stride is larger than the image row. A copy that ignored the stride
	/// would pack the rows tightly and every row after the first would be read from the
	/// wrong place, which looks like a partly written image rather than like an error.
	[Test]
	public static void APaddedReadbackLandsOneRowPerBufferRow()
	{
		if (!Ready()) { Console.WriteLine("SKIP: no Vulkan"); return; }

		const uint32 cWidth = 4;
		const uint32 cHeight = 4;
		const uint32 cBytesPerPixel = 4;
		// Far wider than the four pixels a row holds, so a tightly packed copy is
		// unmistakable.
		const uint32 cPaddedStride = 256;

		var textureDesc = TextureDesc();
		textureDesc.Format = .RGBA8Unorm;
		textureDesc.Width = cWidth;
		textureDesc.Height = cHeight;
		textureDesc.Usage = .Sampled | .CopyDst | .CopySrc;
		Test.Assert(sDevice.CreateTexture(textureDesc) case .Ok(var texture));

		// Each pixel carries its own row, so a row read from the wrong offset shows up as
		// the wrong number rather than as plausible noise.
		let source = scope uint8[cWidth * cHeight * cBytesPerPixel];
		for (uint32 y < cHeight)
		{
			for (uint32 x < cWidth)
			{
				let at = (y * cWidth + x) * cBytesPerPixel;
				source[at + 0] = (uint8)(x + 1);
				source[at + 1] = (uint8)(y + 1);
				source[at + 2] = 0x77;
				source[at + 3] = 0xFF;
			}
		}

		let queue = sDevice.GetQueue(.Graphics);
		Test.Assert(queue.CreateTransferBatch() case .Ok(var batch));
		var uploadLayout = TextureDataLayout();
		uploadLayout.BytesPerRow = cWidth * cBytesPerPixel;
		uploadLayout.RowsPerImage = cHeight;
		batch.WriteTexture(texture, source, uploadLayout, .(cWidth, cHeight, 1));
		Test.Assert(batch.Submit() case .Ok);
		queue.DestroyTransferBatch(ref batch);

		var readbackDesc = BufferDesc();
		readbackDesc.Size = (uint64)cPaddedStride * cHeight;
		readbackDesc.Usage = .CopyDst;
		readbackDesc.Memory = .GpuToCpu;
		Test.Assert(sDevice.CreateBuffer(readbackDesc) case .Ok(var readback));

		Test.Assert(sDevice.CreateCommandPool(.Graphics) case .Ok(var pool));
		Test.Assert(pool.CreateEncoder() case .Ok(var encoder));

		encoder.TransitionTexture(texture, .ShaderRead, .CopySrc);
		var region = BufferTextureCopyRegion();
		region.BytesPerRow = cPaddedStride;
		region.RowsPerImage = cHeight;
		region.TextureExtent = .(cWidth, cHeight, 1);
		encoder.CopyTextureToBuffer(texture, readback, region);

		var buffers = ICommandBuffer[1](encoder.Finish());
		queue.Submit(buffers);
		queue.WaitIdle();

		let mapped = (uint8*)readback.Map();
		Test.Assert(mapped != null);
		for (uint32 y < cHeight)
		{
			for (uint32 x < cWidth)
			{
				// Indexed by the PADDED stride, which is where each row must have landed.
				let at = y * cPaddedStride + x * cBytesPerPixel;
				Test.Assert(mapped[at + 0] == (uint8)(x + 1), "the column came back");
				Test.Assert(mapped[at + 1] == (uint8)(y + 1), "at the right row");
			}
		}
		readback.Unmap();

		pool.DestroyEncoder(ref encoder);
		sDevice.DestroyCommandPool(ref pool);
		sDevice.DestroyBuffer(ref readback);
		sDevice.DestroyTexture(ref texture);
	}

	/// Generating a mip chain leaves EVERY level in the same layout.
	///
	/// The chain is built by blitting each level from the one above, so mid-generation the
	/// levels are deliberately split between source and destination. What must be true
	/// afterwards is that they agree again: a caller's next barrier covers the whole chain
	/// at once, and one level in a different layout makes that barrier name the wrong old
	/// layout for exactly that level.
	///
	/// The base level's incoming layout is also unknown to the generator, since an upload
	/// leaves it shader readable, so this uploads through a batch first to put it in that
	/// state rather than a convenient one.
	[Test]
	public static void GeneratingMipmapsLeavesEveryLevelInOneLayout()
	{
		if (!Ready()) { Console.WriteLine("SKIP: no Vulkan"); return; }

		const uint32 cWidth = 64;
		const uint32 cHeight = 64;
		// 64 halves down to 1 in seven levels.
		const uint32 cMipCount = 7;

		var textureDesc = TextureDesc();
		textureDesc.Format = .RGBA8Unorm;
		textureDesc.Width = cWidth;
		textureDesc.Height = cHeight;
		textureDesc.MipLevelCount = cMipCount;
		textureDesc.Usage = .Sampled | .CopySrc | .CopyDst;
		Test.Assert(sDevice.CreateTexture(textureDesc) case .Ok(var texture));

		// Uploaded first, so the base level arrives shader readable rather than in
		// whatever layout would make the generator's job easy.
		let pixels = scope uint8[cWidth * cHeight * 4];
		for (int i < pixels.Count)
			pixels[i] = (uint8)i;

		let queue = sDevice.GetQueue(.Graphics);
		Test.Assert(queue.CreateTransferBatch() case .Ok(var batch));
		var layout = TextureDataLayout();
		layout.BytesPerRow = cWidth * 4;
		layout.RowsPerImage = cHeight;
		batch.WriteTexture(texture, pixels, layout, .(cWidth, cHeight, 1));
		Test.Assert(batch.Submit() case .Ok);
		queue.DestroyTransferBatch(ref batch);

		let vulkanTexture = texture as VulkanTexture;
		Test.Assert(vulkanTexture != null);
		Test.Assert(vulkanTexture.GetSubresourceLayout(0, 0)
			== .VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
			"the upload left the base level shader readable");

		Test.Assert(sDevice.CreateCommandPool(.Graphics) case .Ok(var pool));
		Test.Assert(pool.CreateEncoder() case .Ok(var encoder));
		encoder.GenerateMipmaps(texture);

		Test.Assert(sDevice.CreateFence(0) case .Ok(var fence));
		var buffers = ICommandBuffer[1](encoder.Finish());
		queue.Submit(buffers, fence, 1);
		Test.Assert(fence.Wait(1), "the generation completed");
		Test.Assert(!sDevice.IsLost());

		// Every level, including the LAST, which is the one that is only ever written and
		// so the one a generator forgets to bring back.
		for (uint32 level < cMipCount)
		{
			Test.Assert(vulkanTexture.GetSubresourceLayout(level, 0)
				== .VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
				"every level ends as a transfer source");
		}

		sDevice.DestroyFence(ref fence);
		pool.DestroyEncoder(ref encoder);
		sDevice.DestroyCommandPool(ref pool);
		sDevice.DestroyTexture(ref texture);
	}

	/// Copies a GPU buffer into a mappable one and waits, so a test can look at what the GPU
	/// actually holds.
	private static void CopyBack(IQueue queue, IBuffer source, IBuffer destination,
		uint64 size)
	{
		if (!(sDevice.CreateCommandPool(queue.QueueType) case .Ok(var pool)))
			return;
		if (!(pool.CreateEncoder() case .Ok(var encoder)))
		{
			sDevice.DestroyCommandPool(ref pool);
			return;
		}

		encoder.CopyBufferToBuffer(source, 0, destination, 0, size);
		var buffers = ICommandBuffer[1](encoder.Finish());
		queue.Submit(buffers);
		queue.WaitIdle();

		pool.DestroyEncoder(ref encoder);
		sDevice.DestroyCommandPool(ref pool);
	}
}
