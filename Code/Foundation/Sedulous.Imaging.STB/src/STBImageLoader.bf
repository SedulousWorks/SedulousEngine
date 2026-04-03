using System.Collections;
using System;
using stb_image;
namespace Sedulous.Imaging.STB;

class STBImageLoader: ImageLoader
{
	private static Self sInstance = null;

	public static bool Initialized => sInstance != null;

	public static void Initialize()
	{
		if(sInstance == null)
		{
			sInstance = new .();
			ImageLoaderFactory.RegisterLoader(sInstance);
		}
	}

	private static List<StringView> sSupportedExtensions = new .() { ".hdr", ".jpg", ".jpeg", ".png", ".tga", ".bmp", ".psd", "" } ~ delete _;

	private static Image.PixelFormat ToPixelFormat(int32 componentCount)
	{
		switch (componentCount)
		{
		case 1:
			return .R32F;
		case 2:
			return .RG32F;
		case 3:
			return .RGB32F;
		case 4:
			return .RGBA32F;
		default:
			// For unsupported formats, default to RGBA32F
			return .RGBA32F;
		}
	}

	public override Result<LoadInfo, LoadResult> LoadFromFile(StringView filePath)
	{
		int32 x = 0;
		int32 y = 0;
		int32 channels_in_file = 0;
		int32 desired_channels = 4;
		var data = stbi_loadf(scope String(filePath).CStr(), &x, &y, &channels_in_file, desired_channels);
		if(data == null)
		{
			return .Err(.FileNotFound);
		}

		defer stbi_image_free(data);

		int dataSize = x * y * desired_channels * sizeof(float);
		uint8[] pixelData = new .[dataSize];
		Internal.MemCpy(pixelData.Ptr, data, dataSize);

		let result = LoadInfo()
			{
				Width = (uint32)x,
				Height = (uint32)y,
				Format = ToPixelFormat(desired_channels),
				Data = pixelData
			};

		return .Ok(result);
	}

	public override Result<LoadInfo, LoadResult> LoadFromMemory(Span<uint8> buffer)
	{
		int32 x = 0;
		int32 y = 0;
		int32 channels_in_file = 0;
		int32 desired_channels = 4;
		var data = stbi_loadf_from_memory(buffer.Ptr, (int32)buffer.Length, &x, &y, &channels_in_file, desired_channels);
		if(data == null)
		{
			return .Err(.FileNotFound);
		}

		defer stbi_image_free(data);

		int dataSize = x * y * desired_channels * sizeof(float);
		uint8[] pixelData = new .[dataSize];
		Internal.MemCpy(pixelData.Ptr, data, dataSize);

		let result = LoadInfo()
			{
				Width = (uint32)x,
				Height = (uint32)y,
				Format = ToPixelFormat(desired_channels),
				Data = pixelData
			};

		return .Ok(result);
	}

	public override bool SupportsExtension(System.StringView @extension)
	{
		return sSupportedExtensions.Contains(@extension);
	}

	public override void GetSupportedExtensions(List<StringView> outExtensions)
	{
		outExtensions.AddRange(sSupportedExtensions);
	}
}