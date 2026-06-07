namespace Sedulous.GUI.IO;

using System;
using System.IO;
using Sedulous.GUI;
using Sedulous.VFS;
using Sedulous.Images;

/// IResourceProvider implementation that loads resources from a VFS mount.
/// Used by StyleSheetLoader for @import, @icon, @image, and drawable
/// factories that reference external files.
///
/// Usage:
///   let mount = new FileSystemMount("Assets/gui");
///   let provider = new VfsResourceProvider(mount);
///   loader.ResourceProvider = provider;
public class VfsResourceProvider : IResourceProvider
{
	private IMount mMount;

	/// Creates a resource provider backed by a VFS mount.
	/// The caller owns the mount — this provider does not delete it.
	public this(IMount mount)
	{
		mMount = mount;
	}

	/// Load text content from a path relative to the mount.
	public Result<void> LoadText(StringView path, String outText)
	{
		if (mMount == null)
			return .Err;

		if (mMount.Open(path) case .Ok(let stream))
		{
			defer delete stream;

			let length = stream.Length;
			if (length <= 0)
				return .Ok;

			let buf = new uint8[length];
			defer delete buf;

			switch (stream.TryRead(.(buf, 0, (int)length)))
			{
			case .Ok(let bytesRead):
				outText.Append((char8*)buf.Ptr, bytesRead);
				return .Ok;
			case .Err:
				return .Err;
			}
		}

		return .Err;
	}

	/// Load image data from a path relative to the mount.
	/// Uses ImageLoaderFactory to decode the image from memory bytes.
	/// Returns an OwnedImageData that the caller owns.
	public Result<IImageData> LoadImage(StringView path)
	{
		if (mMount == null)
			return .Err;

		if (mMount.Open(path) case .Ok(let stream))
		{
			defer delete stream;

			let length = stream.Length;
			if (length <= 0)
				return .Err;

			let buf = new uint8[length];
			defer delete buf;

			switch (stream.TryRead(.(buf, 0, (int)length)))
			{
			case .Ok(let bytesRead):
				// Determine format hint from file extension
				let hint = scope String();
				let dotIdx = StringView(path).LastIndexOf('.');
				if (dotIdx >= 0)
					hint.Append(path.Substring(dotIdx));

				if (ImageLoaderFactory.LoadImageFromMemory(.(buf, 0, bytesRead), hint) case .Ok(let image))
				{
					// Convert Image to OwnedImageData (which implements IImageData)
					let imageData = new OwnedImageData(
						image.Width, image.Height,
						image.Format, image.Data);
					delete image;
					return .Ok(imageData);
				}
				return .Err;
			case .Err:
				return .Err;
			}
		}

		return .Err;
	}
}
