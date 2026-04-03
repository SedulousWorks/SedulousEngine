namespace Sedulous.RHI.Vulkan;

using System;
using System.Collections;
using Bulkan;
using Sedulous.RHI;

/// Vulkan implementation of ISwapChain.
class VulkanSwapChain : ISwapChain
{
	private VulkanDevice mDevice;
	private VulkanSurface mSurface;
	private VkSwapchainKHR mSwapchain;

	private TextureFormat mFormat;
	private uint32 mWidth;
	private uint32 mHeight;
	private uint32 mBufferCount;
	private PresentMode mPresentMode;
	private uint32 mCurrentImageIndex;

	// Per-image resources
	private List<VulkanTexture> mTextures = new .() ~ DeleteContainerAndItems!(_);
	private List<VulkanTextureView> mTextureViews = new .() ~ DeleteContainerAndItems!(_);

	// Synchronization: binary semaphores for acquire/present
	private List<VkSemaphore> mImageAvailableSemaphores = new .() ~ delete _;
	private List<VkSemaphore> mRenderFinishedSemaphores = new .() ~ delete _;
	private uint32 mFrameIndex;

	public TextureFormat Format => mFormat;
	public uint32 Width => mWidth;
	public uint32 Height => mHeight;
	public uint32 BufferCount => mBufferCount;
	public uint32 CurrentImageIndex => mCurrentImageIndex;

	public ITexture CurrentTexture => (mCurrentImageIndex < (uint32)mTextures.Count)
		? mTextures[(.)mCurrentImageIndex] : null;

	public ITextureView CurrentTextureView => (mCurrentImageIndex < (uint32)mTextureViews.Count)
		? mTextureViews[(.)mCurrentImageIndex] : null;

	public this() { }

	public Result<void> Init(VulkanDevice device, VulkanSurface surface, SwapChainDesc desc)
	{
		mDevice = device;
		mSurface = surface;
		mPresentMode = desc.PresentMode;

		return CreateSwapChain(desc.Width, desc.Height, desc.Format, desc.BufferCount, .Null);
	}

	private Result<void> CreateSwapChain(uint32 width, uint32 height, TextureFormat requestedFormat, uint32 requestedBufferCount, VkSwapchainKHR oldSwapchain)
	{
		let adapter = mDevice.Adapter;
		let physDevice = adapter.PhysicalDevice;
		let surfaceHandle = mSurface.Handle;

		// Query surface capabilities
		VkSurfaceCapabilitiesKHR caps = default;
		VulkanNative.vkGetPhysicalDeviceSurfaceCapabilitiesKHR(physDevice, surfaceHandle, &caps);

		// Choose extent
		if (caps.currentExtent.width != uint32.MaxValue)
		{
			mWidth = caps.currentExtent.width;
			mHeight = caps.currentExtent.height;
		}
		else
		{
			mWidth = Math.Clamp(width, caps.minImageExtent.width, caps.maxImageExtent.width);
			mHeight = Math.Clamp(height, caps.minImageExtent.height, caps.maxImageExtent.height);
		}

		if (mWidth == 0 || mHeight == 0)
		{
			System.Diagnostics.Debug.WriteLine("VulkanSwapChain: surface extent is zero");
			return .Err;
		}

		// Choose image count
		mBufferCount = Math.Max(requestedBufferCount, caps.minImageCount);
		if (caps.maxImageCount > 0)
			mBufferCount = Math.Min(mBufferCount, caps.maxImageCount);

		// Choose surface format
		let vkFormat = ChooseSurfaceFormat(physDevice, surfaceHandle, requestedFormat);
		mFormat = VulkanConversions.FromVkFormat(vkFormat.format);
		if (mFormat == .Undefined)
			mFormat = requestedFormat; // Keep requested if conversion didn't map

		// Choose present mode
		let presentMode = ChoosePresentMode(physDevice, surfaceHandle, mPresentMode);

		// Determine image usage
		VkImageUsageFlags usage = .VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT;
		if (caps.supportedUsageFlags.HasFlag(.VK_IMAGE_USAGE_TRANSFER_DST_BIT))
			usage |= .VK_IMAGE_USAGE_TRANSFER_DST_BIT;
		if (caps.supportedUsageFlags.HasFlag(.VK_IMAGE_USAGE_TRANSFER_SRC_BIT))
			usage |= .VK_IMAGE_USAGE_TRANSFER_SRC_BIT;

		// Choose composite alpha
		VkCompositeAlphaFlagsKHR compositeAlpha = .VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR;
		if (!caps.supportedCompositeAlpha.HasFlag(.VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR))
			compositeAlpha = .VK_COMPOSITE_ALPHA_INHERIT_BIT_KHR;

		// Create swapchain
		VkSwapchainCreateInfoKHR createInfo = .();
		createInfo.surface = surfaceHandle;
		createInfo.minImageCount = mBufferCount;
		createInfo.imageFormat = vkFormat.format;
		createInfo.imageColorSpace = vkFormat.colorSpace;
		createInfo.imageExtent.width = mWidth;
		createInfo.imageExtent.height = mHeight;
		createInfo.imageArrayLayers = 1;
		createInfo.imageUsage = usage;
		createInfo.imageSharingMode = .VK_SHARING_MODE_EXCLUSIVE;
		createInfo.preTransform = caps.currentTransform;
		createInfo.compositeAlpha = compositeAlpha;
		createInfo.presentMode = presentMode;
		createInfo.clipped = VkBool32.True;
		createInfo.oldSwapchain = oldSwapchain;

		let result = VulkanNative.vkCreateSwapchainKHR(mDevice.Handle, &createInfo, null, &mSwapchain);
		if (result != .VK_SUCCESS)
		{
			System.Diagnostics.Debug.WriteLine(scope $"VulkanSwapChain: vkCreateSwapchainKHR failed ({result})");
			return .Err;
		}

		// Destroy old swapchain after creating new one
		if (oldSwapchain.Handle != 0)
			VulkanNative.vkDestroySwapchainKHR(mDevice.Handle, oldSwapchain, null);

		// Get images
		if (RetrieveImages(vkFormat.format) case .Err)
		{
			System.Diagnostics.Debug.WriteLine("VulkanSwapChain: failed to retrieve swap chain images");
			return .Err;
		}

		// Create synchronization semaphores
		CreateSyncObjects();

		mFrameIndex = 0;
		return .Ok;
	}

	private VkSurfaceFormatKHR ChooseSurfaceFormat(VkPhysicalDevice physDevice, VkSurfaceKHR surface, TextureFormat requested)
	{
		uint32 formatCount = 0;
		VulkanNative.vkGetPhysicalDeviceSurfaceFormatsKHR(physDevice, surface, &formatCount, null);
		VkSurfaceFormatKHR[] formats = scope VkSurfaceFormatKHR[(.)formatCount];
		VulkanNative.vkGetPhysicalDeviceSurfaceFormatsKHR(physDevice, surface, &formatCount, formats.CArray());

		let desired = VulkanConversions.ToVkFormat(requested);

		// Try exact match
		for (let fmt in formats)
		{
			if (fmt.format == desired)
				return fmt;
		}

		// Try BGRA8 SRGB as fallback
		for (let fmt in formats)
		{
			if (fmt.format == .VK_FORMAT_B8G8R8A8_SRGB &&
				fmt.colorSpace == .VK_COLOR_SPACE_SRGB_NONLINEAR_KHR)
				return fmt;
		}

		// Try BGRA8 UNORM as fallback
		for (let fmt in formats)
		{
			if (fmt.format == .VK_FORMAT_B8G8R8A8_UNORM)
				return fmt;
		}

		// Just return first available
		return formats[0];
	}

	private VkPresentModeKHR ChoosePresentMode(VkPhysicalDevice physDevice, VkSurfaceKHR surface, PresentMode requested)
	{
		uint32 modeCount = 0;
		VulkanNative.vkGetPhysicalDeviceSurfacePresentModesKHR(physDevice, surface, &modeCount, null);
		VkPresentModeKHR[] modes = scope VkPresentModeKHR[(.)modeCount];
		VulkanNative.vkGetPhysicalDeviceSurfacePresentModesKHR(physDevice, surface, &modeCount, modes.CArray());

		let desired = VulkanConversions.ToVkPresentMode(requested);
		for (let mode in modes)
		{
			if (mode == desired)
				return mode;
		}

		// FIFO is guaranteed by spec
		return .VK_PRESENT_MODE_FIFO_KHR;
	}

	private Result<void> RetrieveImages(VkFormat format)
	{
		// Get swap chain images
		uint32 imageCount = 0;
		VulkanNative.vkGetSwapchainImagesKHR(mDevice.Handle, mSwapchain, &imageCount, null);
		VkImage[] images = scope VkImage[(.)imageCount];
		VulkanNative.vkGetSwapchainImagesKHR(mDevice.Handle, mSwapchain, &imageCount, images.CArray());

		mBufferCount = imageCount;

		// Wrap each image as VulkanTexture + VulkanTextureView
		for (uint32 i = 0; i < imageCount; i++)
		{
			TextureDesc texDesc = .();
			texDesc.Dimension = .Texture2D;
			texDesc.Format = mFormat;
			texDesc.Width = mWidth;
			texDesc.Height = mHeight;
			texDesc.ArrayLayerCount = 1;
			texDesc.MipLevelCount = 1;
			texDesc.SampleCount = 1;
			texDesc.Usage = .RenderTarget;

			let texture = new VulkanTexture();
			texture.InitFromExisting(images[(.)i], texDesc);
			mTextures.Add(texture);

			TextureViewDesc viewDesc = .();
			viewDesc.Format = mFormat;
			viewDesc.Dimension = .Texture2D;
			viewDesc.BaseMipLevel = 0;
			viewDesc.MipLevelCount = 1;
			viewDesc.BaseArrayLayer = 0;
			viewDesc.ArrayLayerCount = 1;

			let view = new VulkanTextureView();
			if (view.Init(mDevice, texture, viewDesc) case .Err)
			{
				System.Diagnostics.Debug.WriteLine("VulkanSwapChain: failed to create image view for swap chain image");
				delete view;
				return .Err;
			}
			mTextureViews.Add(view);
		}

		return .Ok;
	}

	private void CreateSyncObjects()
	{
		VkSemaphoreCreateInfo semInfo = .();

		for (uint32 i = 0; i < mBufferCount; i++)
		{
			VkSemaphore imgAvail = default;
			VkSemaphore renderDone = default;
			VulkanNative.vkCreateSemaphore(mDevice.Handle, &semInfo, null, &imgAvail);
			VulkanNative.vkCreateSemaphore(mDevice.Handle, &semInfo, null, &renderDone);
			mImageAvailableSemaphores.Add(imgAvail);
			mRenderFinishedSemaphores.Add(renderDone);
		}
	}

	public Result<void> AcquireNextImage()
	{
		// imageAvailable is indexed by frame-in-flight (we don't know the image index yet)
		let acquireSem = mImageAvailableSemaphores[(.)mFrameIndex];
		var imageIndex = mCurrentImageIndex;

		let result = VulkanNative.vkAcquireNextImageKHR(
			mDevice.Handle, mSwapchain, uint64.MaxValue,
			acquireSem, .Null, &imageIndex);

		mCurrentImageIndex = imageIndex;

		if (result == .VK_ERROR_OUT_OF_DATE_KHR)
		{
			System.Diagnostics.Debug.WriteLine("VulkanSwapChain: vkAcquireNextImageKHR returned out of date");
			return .Err; // Caller should resize
		}

		if (result != .VK_SUCCESS && result != .VK_SUBOPTIMAL_KHR)
		{
			System.Diagnostics.Debug.WriteLine(scope $"VulkanSwapChain: vkAcquireNextImageKHR failed ({result})");
			return .Err;
		}

		// renderFinished is indexed by acquired image to avoid signaling a semaphore
		// that's still in use by a previous present of a different image.
		let presentSem = mRenderFinishedSemaphores[(.)mCurrentImageIndex];

		// Tell the device about the binary semaphores so the next queue submit
		// waits on imageAvailable and signals renderFinished.
		mDevice.SetPendingSwapChainSync(acquireSem, presentSem);

		return .Ok;
	}

	public Result<void> Present(IQueue queue)
	{
		if (let vkQueue = queue as VulkanQueue)
		{
			var swapchain = mSwapchain;
			var imageIndex = mCurrentImageIndex;
			var waitSem = mRenderFinishedSemaphores[(.)mCurrentImageIndex];

			VkPresentInfoKHR presentInfo = .();
			presentInfo.waitSemaphoreCount = 1;
			presentInfo.pWaitSemaphores = &waitSem;
			presentInfo.swapchainCount = 1;
			presentInfo.pSwapchains = &swapchain;
			presentInfo.pImageIndices = &imageIndex;

			let result = VulkanNative.vkQueuePresentKHR(vkQueue.Handle, &presentInfo);

			mFrameIndex = (mFrameIndex + 1) % mBufferCount;

			if (result == .VK_ERROR_OUT_OF_DATE_KHR || result == .VK_SUBOPTIMAL_KHR)
			{
				System.Diagnostics.Debug.WriteLine(scope $"VulkanSwapChain: vkQueuePresentKHR returned ({result}), resize needed");
				return .Err; // Caller should resize
			}

			if (result != .VK_SUCCESS)
			{
				System.Diagnostics.Debug.WriteLine(scope $"VulkanSwapChain: vkQueuePresentKHR failed ({result})");
				return .Err;
			}

			return .Ok;
		}
		System.Diagnostics.Debug.WriteLine("VulkanSwapChain: queue is not a VulkanQueue");
		return .Err;
	}

	public Result<void> Resize(uint32 width, uint32 height)
	{
		mDevice.WaitIdle();

		// Clean up old image views and textures
		CleanupImages();

		// Destroy old sync objects
		DestroySyncObjects();

		// Recreate with old swapchain for recycling
		return CreateSwapChain(width, height, mFormat, mBufferCount, mSwapchain);
	}

	private void CleanupImages()
	{
		for (let view in mTextureViews)
		{
			view.Cleanup(mDevice);
			delete view;
		}
		mTextureViews.Clear();

		for (let tex in mTextures)
		{
			// These don't own the VkImage (swap chain images), just delete wrapper
			tex.Cleanup(mDevice);
			delete tex;
		}
		mTextures.Clear();
	}

	private void DestroySyncObjects()
	{
		for (let sem in mImageAvailableSemaphores)
			VulkanNative.vkDestroySemaphore(mDevice.Handle, sem, null);
		mImageAvailableSemaphores.Clear();

		for (let sem in mRenderFinishedSemaphores)
			VulkanNative.vkDestroySemaphore(mDevice.Handle, sem, null);
		mRenderFinishedSemaphores.Clear();
	}

	/// Gets the binary semaphore signaled when the current image is available.
	public VkSemaphore CurrentImageAvailableSemaphore =>
		mImageAvailableSemaphores[(.)mFrameIndex];

	/// Gets the binary semaphore to signal when rendering is complete (for present).
	/// Indexed by acquired image index to avoid conflicts across frames.
	public VkSemaphore CurrentRenderFinishedSemaphore =>
		mRenderFinishedSemaphores[(.)mCurrentImageIndex];

	public void Cleanup(VulkanDevice device)
	{
		device.WaitIdle();

		CleanupImages();
		DestroySyncObjects();

		if (mSwapchain.Handle != 0)
		{
			VulkanNative.vkDestroySwapchainKHR(device.Handle, mSwapchain, null);
			mSwapchain = .Null;
		}
	}
}
