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

	/// Hands the acquired buffer to the display.
	Result<void> Present(IQueue queue);

	/// Rebuilds at a new size, after a window resize. The back buffer textures and views
	/// are replaced, so anything holding them must reacquire.
	Result<void> Resize(uint32 width, uint32 height);
}
