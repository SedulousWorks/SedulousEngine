using System;
using System.IO;
using System.Collections;

namespace Sedulous.Imaging;

// Abstract base class for image loaders
public abstract class ImageLoader
{
	public enum LoadResult
	{
		Success,
		FileNotFound,
		UnsupportedFormat,
		CorruptedData,
		OutOfMemory,
		InvalidDimensions,
		UnknownError
	}

	public struct LoadInfo
	{
		public uint32 Width;
		public uint32 Height;
		public Image.PixelFormat Format;
		public uint8[] Data;

		public this()
		{
			Width = 0;
			Height = 0;
			Format = .RGBA8;
			Data = null;
		}

		public void Dispose() mut
		{
			delete Data;
			Data = null;
		}
	}

    // Load image from file path
	public abstract Result<LoadInfo, LoadResult> LoadFromFile(StringView filePath);

    // Load image from memory buffer
	public abstract Result<LoadInfo, LoadResult> LoadFromMemory(Span<uint8> data);

    // Check if this loader supports the file extension
    public abstract bool SupportsExtension(StringView @extension);

    // Get supported file extensions
	public abstract void GetSupportedExtensions(List<StringView> outExtensions);

    // Helper method to create Image from LoadInfo
	public static Result<Image> CreateImageFromLoadInfo(LoadInfo loadInfo)
	{
		if (loadInfo.Data == null)
			return .Err;

		var image = new Image(loadInfo.Width, loadInfo.Height, loadInfo.Format, loadInfo.Data);
		return image;
	}
}