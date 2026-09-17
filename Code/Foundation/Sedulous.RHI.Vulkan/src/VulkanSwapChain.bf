using System;
using System.Collections;
using Bulkan;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.Vulkan;

/// The surface's back buffers and the semaphores that order drawing against presenting.
///
/// The chain does not submit anything itself. Acquiring LEAVES its two semaphores on the
/// device, the next fence-signalling submit picks them up, and presenting waits on the one
/// that submit signalled. That indirection is what keeps the queue from having to know a
/// swap chain exists.
class VulkanSwapChain : ISwapChain
{
	private VkDevice mDevice;
	private VkPhysicalDevice mPhysicalDevice;
	private VkSurfaceKHR mSurface;
	private VkSwapchainKHR mSwapChain = .Null;
	private VulkanDevice mOwner;

	private TextureFormat mFormat = .Undefined;
	private PresentMode mPresentMode = .Fifo;
	private uint32 mWidth = 0;
	private uint32 mHeight = 0;
	private uint32 mBufferCount = 0;
	private uint32 mCurrentImageIndex = 0;
	/// Which acquire semaphore to use, which cycles independently of the image index
	/// because the image an acquire returns is the driver's choice, not a sequence.
	private uint32 mFrameIndex = 0;

	private List<VulkanTexture> mTextures = new List<VulkanTexture>() ~ delete _;
	private List<VulkanTextureView> mViews = new List<VulkanTextureView>() ~ delete _;
	private List<VkSemaphore> mAcquireSemaphores = new List<VkSemaphore>() ~ delete _;
	private List<VkSemaphore> mPresentSemaphores = new List<VkSemaphore>() ~ delete _;

	public TextureFormat Format => mFormat;
	public uint32 Width => mWidth;
	public uint32 Height => mHeight;
	public uint32 BufferCount => mBufferCount;
	public uint32 CurrentImageIndex => mCurrentImageIndex;

	public VkSwapchainKHR Handle => mSwapChain;

	public Result<void> Initialize(VkDevice device, VkPhysicalDevice physicalDevice,
		VkSurfaceKHR surface, SwapChainDesc desc, VulkanDevice owner)
	{
		mDevice = device;
		mPhysicalDevice = physicalDevice;
		mSurface = surface;
		mOwner = owner;
		mPresentMode = desc.PresentMode;
		return Create(desc.Width, desc.Height, desc.Format, desc.BufferCount, .Null);
	}

	public ITexture CurrentTexture
	{
		get
		{
			if (mCurrentImageIndex >= (uint32)mTextures.Count)
				return null;
			return mTextures[(int)mCurrentImageIndex];
		}
	}

	public ITextureView CurrentTextureView
	{
		get
		{
			if (mCurrentImageIndex >= (uint32)mViews.Count)
				return null;
			return mViews[(int)mCurrentImageIndex];
		}
	}

	/// Takes the next back buffer and leaves its semaphores with the device for the
	/// submission that will draw into it.
	public Result<void> AcquireNextImage()
	{
		if (mSwapChain == .Null)
			return .Err;

		let acquireSemaphore = mAcquireSemaphores[(int)mFrameIndex];
		uint32 imageIndex = 0;
		let result = VulkanNative.vkAcquireNextImageKHR(mDevice, mSwapChain, uint64.MaxValue,
			acquireSemaphore, .Null, &imageIndex);
		mCurrentImageIndex = imageIndex;

		// OUT_OF_DATE means the surface changed under us and the caller has to resize;
		// SUBOPTIMAL still presents, so it is not worth failing an otherwise usable frame.
		if (result == .VK_ERROR_OUT_OF_DATE_KHR)
			return .Err;
		if ((result != .VK_SUCCESS) && (result != .VK_SUBOPTIMAL_KHR))
			return .Err;

		mOwner.SetPendingSwapChainSync(acquireSemaphore, mPresentSemaphores[(int)mCurrentImageIndex]);
		return .Ok;
	}

	public Result<void> Present(IQueue queue)
	{
		let vulkanQueue = queue as VulkanQueue;
		if (vulkanQueue == null || mSwapChain == .Null)
			return .Err;

		var waitSemaphore = mPresentSemaphores[(int)mCurrentImageIndex];
		var swapChain = mSwapChain;
		var imageIndex = mCurrentImageIndex;

		VkPresentInfoKHR presentInfo = .();
		presentInfo.waitSemaphoreCount = 1;
		presentInfo.pWaitSemaphores = &waitSemaphore;
		presentInfo.swapchainCount = 1;
		presentInfo.pSwapchains = &swapChain;
		presentInfo.pImageIndices = &imageIndex;

		let result = VulkanNative.vkQueuePresentKHR(vulkanQueue.Handle, &presentInfo);
		// Advanced whatever the result: the acquire semaphore for this frame has been used
		// and reusing it before the next cycle would wait on a signal that never comes.
		mFrameIndex = (mFrameIndex + 1) % mBufferCount;

		if (result == .VK_ERROR_DEVICE_LOST)
			mOwner.MarkLost();
		// SUBOPTIMAL is a failure HERE, unlike on acquire: the frame is on screen, and the
		// caller is being told to rebuild the chain before the next one.
		if ((result == .VK_ERROR_OUT_OF_DATE_KHR) || (result == .VK_SUBOPTIMAL_KHR))
			return .Err;
		return (result == .VK_SUCCESS) ? .Ok : .Err;
	}

	public Result<void> Resize(uint32 width, uint32 height)
	{
		VulkanNative.vkDeviceWaitIdle(mDevice);
		CleanupImages();
		DestroySyncObjects();
		// The old chain is passed in rather than destroyed first, which lets the driver
		// reuse its images, and Create destroys it once the new one exists.
		return Create(width, height, mFormat, mBufferCount, mSwapChain);
	}

	public void Cleanup()
	{
		VulkanNative.vkDeviceWaitIdle(mDevice);
		CleanupImages();
		DestroySyncObjects();
		if (mSwapChain != .Null)
		{
			VulkanNative.vkDestroySwapchainKHR(mDevice, mSwapChain, null);
			mSwapChain = .Null;
		}
	}

	private Result<void> Create(uint32 width, uint32 height, TextureFormat requestedFormat,
		uint32 requestedCount, VkSwapchainKHR old)
	{
		VkSurfaceCapabilitiesKHR capabilities = .();
		VulkanNative.vkGetPhysicalDeviceSurfaceCapabilitiesKHR(mPhysicalDevice, mSurface,
			&capabilities);

		// A currentExtent of ~0 means the surface defers to the swap chain; anything else is
		// the size the surface INSISTS on, and asking for another is an error.
		if (capabilities.currentExtent.width != uint32.MaxValue)
		{
			mWidth = capabilities.currentExtent.width;
			mHeight = capabilities.currentExtent.height;
		}
		else
		{
			mWidth = Math.Clamp(width, capabilities.minImageExtent.width,
				capabilities.maxImageExtent.width);
			mHeight = Math.Clamp(height, capabilities.minImageExtent.height,
				capabilities.maxImageExtent.height);
		}
		// A minimised window, which cannot have a swap chain at all.
		if ((mWidth == 0) || (mHeight == 0))
			return .Err;

		let presentMode = ChoosePresentMode(mPresentMode);

		// Mailbox needs a third image to race ahead of the display without stalling; two is
		// enough for FIFO and immediate.
		uint32 wantedCount = requestedCount;
		if ((presentMode == .VK_PRESENT_MODE_MAILBOX_KHR) && (wantedCount < 3))
			wantedCount = 3;
		mBufferCount = Math.Max(wantedCount, capabilities.minImageCount);
		if (capabilities.maxImageCount > 0)
			mBufferCount = Math.Min(mBufferCount, capabilities.maxImageCount);

		let surfaceFormat = ChooseSurfaceFormat(requestedFormat);
		mFormat = FromVkFormat(surfaceFormat.format);
		if (mFormat == .Undefined)
			mFormat = requestedFormat;

		ReportNegotiatedFormat(requestedFormat, surfaceFormat);

		VkImageUsageFlags usage = .VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT;
		// Transfer usage is what a screenshot or a blit to the back buffer needs, and it is
		// not universally offered, so it is taken only where the surface has it.
		if (capabilities.supportedUsageFlags.HasFlag(.VK_IMAGE_USAGE_TRANSFER_DST_BIT))
			usage |= .VK_IMAGE_USAGE_TRANSFER_DST_BIT;
		if (capabilities.supportedUsageFlags.HasFlag(.VK_IMAGE_USAGE_TRANSFER_SRC_BIT))
			usage |= .VK_IMAGE_USAGE_TRANSFER_SRC_BIT;

		VkCompositeAlphaFlagsKHR compositeAlpha =
			capabilities.supportedCompositeAlpha.HasFlag(.VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR)
			? .VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR
			: .VK_COMPOSITE_ALPHA_INHERIT_BIT_KHR;

		VkSwapchainCreateInfoKHR createInfo = .();
		createInfo.surface = mSurface;
		createInfo.minImageCount = mBufferCount;
		createInfo.imageFormat = surfaceFormat.format;
		createInfo.imageColorSpace = surfaceFormat.colorSpace;
		createInfo.imageExtent = .() { width = mWidth, height = mHeight };
		createInfo.imageArrayLayers = 1;
		createInfo.imageUsage = usage;
		createInfo.imageSharingMode = .VK_SHARING_MODE_EXCLUSIVE;
		createInfo.preTransform = capabilities.currentTransform;
		createInfo.compositeAlpha = compositeAlpha;
		createInfo.presentMode = presentMode;
		createInfo.clipped = VulkanNative.VK_TRUE;
		createInfo.oldSwapchain = old;

		if (VulkanNative.vkCreateSwapchainKHR(mDevice, &createInfo, null, &mSwapChain)
			!= .VK_SUCCESS)
			return .Err;
		if (old != .Null)
			VulkanNative.vkDestroySwapchainKHR(mDevice, old, null);

		if (RetrieveImages(surfaceFormat.format) case .Err)
			return .Err;
		CreateSyncObjects();
		mFrameIndex = 0;
		return .Ok;
	}

	/// The exact format if the surface offers it, then sRGB BGRA, then plain BGRA, then
	/// whatever came first.
	private VkSurfaceFormatKHR ChooseSurfaceFormat(TextureFormat requested)
	{
		uint32 count = 0;
		VulkanNative.vkGetPhysicalDeviceSurfaceFormatsKHR(mPhysicalDevice, mSurface, &count,
			null);
		if (count == 0)
			return .();

		let formats = scope VkSurfaceFormatKHR[count];
		VulkanNative.vkGetPhysicalDeviceSurfaceFormatsKHR(mPhysicalDevice, mSurface, &count,
			&formats[0]);

		let desired = VulkanConversions.ToVkFormat(requested);
		for (let format in formats)
			if (format.format == desired)
				return format;
		for (let format in formats)
			if ((format.format == .VK_FORMAT_B8G8R8A8_SRGB)
				&& (format.colorSpace == .VK_COLOR_SPACE_SRGB_NONLINEAR_KHR))
				return format;
		for (let format in formats)
			if (format.format == .VK_FORMAT_B8G8R8A8_UNORM)
				return format;
		return formats[0];
	}

	/// The requested mode where the surface has it, otherwise the closest mode with the same
	/// INTENT.
	///
	/// Immediate and Mailbox both mean "do not block on the refresh", so an unavailable one
	/// falls to the other before settling for FIFO, which Wayland needs since it commonly
	/// offers Mailbox but not Immediate. FIFO is the only mode the spec guarantees.
	private VkPresentModeKHR ChoosePresentMode(PresentMode requested)
	{
		uint32 count = 0;
		VulkanNative.vkGetPhysicalDeviceSurfacePresentModesKHR(mPhysicalDevice, mSurface,
			&count, null);
		if (count == 0)
			return .VK_PRESENT_MODE_FIFO_KHR;

		let modes = scope VkPresentModeKHR[count];
		VulkanNative.vkGetPhysicalDeviceSurfacePresentModesKHR(mPhysicalDevice, mSurface,
			&count, &modes[0]);

		bool Has(Span<VkPresentModeKHR> available, VkPresentModeKHR mode)
		{
			for (let candidate in available)
				if (candidate == mode)
					return true;
			return false;
		}

		let desired = VulkanConversions.ToVkPresentMode(requested);
		if (Has(modes, desired))
			return desired;

		VkPresentModeKHR chosen = .VK_PRESENT_MODE_FIFO_KHR;
		if ((requested == .Immediate) || (requested == .Mailbox))
		{
			if (Has(modes, .VK_PRESENT_MODE_MAILBOX_KHR))
				chosen = .VK_PRESENT_MODE_MAILBOX_KHR;
			else if (Has(modes, .VK_PRESENT_MODE_IMMEDIATE_KHR))
				chosen = .VK_PRESENT_MODE_IMMEDIATE_KHR;
		}
		else if ((requested == .FifoRelaxed) && Has(modes, .VK_PRESENT_MODE_FIFO_RELAXED_KHR))
		{
			chosen = .VK_PRESENT_MODE_FIFO_RELAXED_KHR;
		}

		Console.WriteLine("[swapchain] requested present mode (vk {}) unavailable; using vk {}",
			(uint32)desired, (uint32)chosen);
		return chosen;
	}

	/// Wraps the images the chain owns in textures and views, which is what a render pass
	/// binds. The count comes back from the driver and can exceed what was asked for.
	private Result<void> RetrieveImages(VkFormat format)
	{
		uint32 imageCount = 0;
		VulkanNative.vkGetSwapchainImagesKHR(mDevice, mSwapChain, &imageCount, null);
		if (imageCount == 0)
			return .Err;

		let images = scope VkImage[imageCount];
		VulkanNative.vkGetSwapchainImagesKHR(mDevice, mSwapChain, &imageCount, &images[0]);
		mBufferCount = imageCount;

		var textureFormat = FromVkFormat(format);
		if (textureFormat == .Undefined)
			textureFormat = mFormat;

		for (uint32 i < imageCount)
		{
			var textureDesc = TextureDesc();
			textureDesc.Dimension = .Texture2D;
			textureDesc.Format = textureFormat;
			textureDesc.Width = mWidth;
			textureDesc.Height = mHeight;
			textureDesc.ArrayLayerCount = 1;
			textureDesc.MipLevelCount = 1;
			textureDesc.SampleCount = 1;
			textureDesc.Usage = .RenderTarget;

			let texture = new VulkanTexture();
			texture.InitializeFromExisting(images[(int)i], textureDesc);
			mTextures.Add(texture);

			var viewDesc = TextureViewDesc();
			viewDesc.Format = textureFormat;
			viewDesc.Dimension = .Texture2D;
			viewDesc.MipLevelCount = 1;
			viewDesc.ArrayLayerCount = 1;

			let view = new VulkanTextureView();
			if (view.Initialize(mDevice, texture, viewDesc) case .Err)
			{
				delete view;
				return .Err;
			}
			mViews.Add(view);
		}
		return .Ok;
	}

	/// One acquire and one present semaphore per image.
	///
	/// Binary, not timeline: presentation engines take only binary semaphores, which is
	/// also why these do not go through IFence.
	private void CreateSyncObjects()
	{
		VkSemaphoreCreateInfo createInfo = .();
		for (uint32 i < mBufferCount)
		{
			VkSemaphore acquire = .Null;
			VkSemaphore present = .Null;
			VulkanNative.vkCreateSemaphore(mDevice, &createInfo, null, &acquire);
			VulkanNative.vkCreateSemaphore(mDevice, &createInfo, null, &present);
			mAcquireSemaphores.Add(acquire);
			mPresentSemaphores.Add(present);
		}
	}

	private void CleanupImages()
	{
		for (let view in mViews)
		{
			view.Cleanup(mDevice);
			delete view;
		}
		mViews.Clear();
		// The images belong to the chain, so the textures only drop their description.
		for (let texture in mTextures)
		{
			texture.Cleanup(mDevice);
			delete texture;
		}
		mTextures.Clear();
	}

	private void DestroySyncObjects()
	{
		for (let semaphore in mAcquireSemaphores)
			VulkanNative.vkDestroySemaphore(mDevice, semaphore, null);
		mAcquireSemaphores.Clear();
		for (let semaphore in mPresentSemaphores)
			VulkanNative.vkDestroySemaphore(mDevice, semaphore, null);
		mPresentSemaphores.Clear();
	}

	/// Says what was asked for and what the surface gave, and warns when the result is not
	/// sRGB.
	///
	/// A silent fall to a UNORM target is the known cause of a washed out build: the final
	/// pass still assumes the encode happens on write. Naming the format makes that a
	/// one line diagnosis instead of a hunt.
	private void ReportNegotiatedFormat(TextureFormat requested, VkSurfaceFormatKHR negotiated)
	{
		Console.WriteLine("[RHI] swapchain surface format: requested {}, negotiated {} [{}]",
			VkFormatName(VulkanConversions.ToVkFormat(requested)),
			VkFormatName(negotiated.format), VkColorSpaceName(negotiated.colorSpace));

		if (!TextureFormats.IsSrgb(mFormat))
		{
			Console.WriteLine("[RHI] swapchain negotiated a NON-sRGB format ({}); the surface offered no sRGB target, and output may look washed out where the final pass assumes encode-on-write",
				VkFormatName(negotiated.format));
		}
	}

	/// The formats a surface can plausibly report, back to the RHI's own.
	///
	/// Deliberately PARTIAL: anything else means the surface offered nothing the RHI can
	/// describe, and the caller keeps the format it asked for.
	private static TextureFormat FromVkFormat(VkFormat format)
	{
		switch (format)
		{
		case .VK_FORMAT_R8G8B8A8_UNORM: return .RGBA8Unorm;
		case .VK_FORMAT_R8G8B8A8_SRGB: return .RGBA8UnormSrgb;
		case .VK_FORMAT_B8G8R8A8_UNORM: return .BGRA8Unorm;
		case .VK_FORMAT_B8G8R8A8_SRGB: return .BGRA8UnormSrgb;
		case .VK_FORMAT_R16G16B16A16_SFLOAT: return .RGBA16Float;
		case .VK_FORMAT_A2B10G10R10_UNORM_PACK32: return .RGB10A2Unorm;
		default: return .Undefined;
		}
	}

	private static StringView VkFormatName(VkFormat format)
	{
		switch (format)
		{
		case .VK_FORMAT_R8G8B8A8_UNORM: return "R8G8B8A8_UNORM";
		case .VK_FORMAT_R8G8B8A8_SRGB: return "R8G8B8A8_SRGB";
		case .VK_FORMAT_B8G8R8A8_UNORM: return "B8G8R8A8_UNORM";
		case .VK_FORMAT_B8G8R8A8_SRGB: return "B8G8R8A8_SRGB";
		case .VK_FORMAT_R16G16B16A16_SFLOAT: return "R16G16B16A16_SFLOAT";
		case .VK_FORMAT_A2B10G10R10_UNORM_PACK32: return "A2B10G10R10_UNORM_PACK32";
		default: return "(other)";
		}
	}

	private static StringView VkColorSpaceName(VkColorSpaceKHR colorSpace)
	{
		switch (colorSpace)
		{
		case .VK_COLOR_SPACE_SRGB_NONLINEAR_KHR: return "SRGB_NONLINEAR";
		default: return "(other)";
		}
	}
}
