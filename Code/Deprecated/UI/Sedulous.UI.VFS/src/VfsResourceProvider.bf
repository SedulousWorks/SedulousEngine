using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Image;
using Sedulous.Core.IO;
using Sedulous.Image.IO;
using Sedulous.UI;
using Sedulous.VFS;

namespace Sedulous.UI.VFS;

/// A style sheet's resource provider, reading through a virtual file system.
///
/// This is the IO half of theming: `@import`, an `@icon`'s SVG text, and the image and nine
/// slice drawable factories all resolve their paths through here.
///
/// It lives in its own module so the core UI carries no file system dependency at all. A UI
/// that never loads anything from disk never links this.
///
/// The file system is BORROWED, and the decoded images are OWNED: a provider hands its images
/// out borrowed, so it has to outlive what it gave them to.
class VfsResourceProvider : IResourceProvider
{
	/// BORROWED; the caller owns it.
	private IFileSystem mFileSystem;
	private List<OwnedImageData> mImages = new .() ~ DeleteContainerAndItems!(_);

	public this(IFileSystem fileSystem)
	{
		mFileSystem = fileSystem;
	}

	/// Text for an imported sheet or an icon. An EMPTY file succeeds: a sheet importing an
	/// empty one is odd but not broken, and failing would take the whole parse down.
	public bool LoadText(StringView path, String outText)
	{
		let buffer = scope List<uint8>();
		if (!ReadAll(path, buffer))
			return false;

		if (buffer.IsEmpty)
			return true;

		outText.Append(StringView((char8*)buffer.Ptr, buffer.Count));
		return true;
	}

	/// An image for the image and nine slice factories. BORROWED, cached here for the
	/// provider's lifetime, and null when it is missing or will not decode.
	public ImageData LoadImage(StringView path)
	{
		let buffer = scope List<uint8>();
		if (!ReadAll(path, buffer) || buffer.IsEmpty)
			return null;

		let decoded = scope Image();
		if (ImageIO.LoadImageFromMemory(Span<uint8>(buffer.Ptr, buffer.Count), decoded) case .Err)
			return null;

		// COPIED out of the scratch image, which does not outlive this call.
		let owned = new OwnedImageData(decoded.Width, decoded.Height, decoded.Format,
			decoded.PixelData);
		mImages.Add(owned);
		return owned;
	}

	/// Reads a whole file. False when there is no file system, or the path will not open.
	private bool ReadAll(StringView path, List<uint8> outBuffer)
	{
		if (mFileSystem == null)
			return false;

		let stream = mFileSystem.Open(path, .Read);
		if (stream == null)
			return false;

		defer delete stream;

		let length = stream.Size();
		if (length <= 0)
			return true;

		outBuffer.Resize((int)length);
		// A short read is not an error: the stream reports what it transferred, so the buffer
		// is trimmed to it rather than the whole load being refused.
		let read = stream.Read(Span<uint8>(outBuffer.Ptr, outBuffer.Count));
		outBuffer.Resize((read > 0) ? read : 0);
		return true;
	}
}
