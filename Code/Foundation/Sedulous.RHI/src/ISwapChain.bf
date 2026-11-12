using System;
using Sedulous.Core;

namespace Sedulous.RHI;

/// The chain of back buffers for one surface.
interface ISwapChain
{
	TextureFormat Format { get; }
	uint32 Width { get; }
	uint32 Height { get; }
	uint32 BufferCount { get; }
	uint32 CurrentImageIndex { get; }

	/// Takes the next back buffer. MUST be called before reading CurrentTexture or
	/// CurrentTextureView, which name whatever this acquired.
	Result<void> AcquireNextImage();

	ITexture CurrentTexture { get; }
	ITextureView CurrentTextureView { get; }

	/// The alternate view format the back buffers were made viewable in
	/// (SwapChainDesc.AlternateViewFormat, the format's sRGB or UNORM twin), or Undefined when
	/// none was asked for or this device and surface cannot (Vulkan without
	/// VK_KHR_swapchain_mutable_format): a host then draws through CurrentTextureView alone.
	TextureFormat AlternateViewFormat { get; }
	/// A view of the currently acquired back buffer in AlternateViewFormat; null when that is
	/// Undefined.
	ITextureView CurrentAlternateTextureView { get; }

	/// How the back buffers' content is turned from the window's picture, clockwise: None unless
	/// SwapChainDesc.PreRotate was asked and the surface presents turned. On a quarter turn the back
	/// buffers are the window's size with its sides swapped (Width and Height are theirs), and the
	/// window's picture is drawn into them turned (ContentFit.TurnPoint), its top-left corner
	/// landing at their top-right.
	ContentRotation PreRotation { get; }

	/// Hands the acquired buffer to the display.
	Result<void> Present(IQueue queue);

	/// Rebuilds at a new size, after a window resize. The back buffer textures and views
	/// are replaced, so anything holding them must reacquire.
	Result<void> Resize(uint32 width, uint32 height);
}
