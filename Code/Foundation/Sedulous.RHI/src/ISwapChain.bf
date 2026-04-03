namespace Sedulous.RHI;

using System;

/// A swap chain for presenting rendered images to a surface.
/// Destroyed via IDevice.DestroySwapChain().
///
/// Usage:
/// ```
/// swapChain.AcquireNextImage();
/// // ... record commands targeting swapChain.CurrentTextureView ...
/// queue.Submit(.(&cmdBuf, 1));
/// swapChain.Present(queue);
/// ```
interface ISwapChain
{
	/// Pixel format of the swap chain images.
	TextureFormat Format { get; }

	/// Width of the swap chain images in pixels.
	uint32 Width { get; }

	/// Height of the swap chain images in pixels.
	uint32 Height { get; }

	/// Number of back buffers.
	uint32 BufferCount { get; }

	/// Index of the currently acquired image (0 to BufferCount-1).
	uint32 CurrentImageIndex { get; }

	/// Acquires the next image. Must be called before rendering to the swap chain.
	Result<void> AcquireNextImage();

	/// Gets the texture for the current back buffer.
	ITexture CurrentTexture { get; }

	/// Gets a view of the current back buffer texture.
	ITextureView CurrentTextureView { get; }

	/// Presents the current image to the surface.
	Result<void> Present(IQueue queue);

	/// Resizes the swap chain. Call when the window is resized.
	Result<void> Resize(uint32 width, uint32 height);
}
