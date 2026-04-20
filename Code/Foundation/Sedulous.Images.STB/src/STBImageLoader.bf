using System.Collections;
using System;
using stb_image;
namespace Sedulous.Images.STB;

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

	private static PixelFormat ToPixelFormat(int32 componentCount, bool isHDR)
	{
	    if (isHDR)
	    {
	        switch (componentCount)
	        {
	        case 1: return .R32F;
	        case 2: return .RG32F;
	        case 3: return .RGB32F;
	        case 4: return .RGBA32F;
	        default: return .RGBA32F;
	        }
	    }
	    else
	    {
	        switch (componentCount)
	        {
	        case 1: return .R8;
	        case 2: return .RG8;
	        case 3: return .RGB8;
	        case 4: return .RGBA8;
	        default: return .RGBA8;
	        }
	    }
	}

	public override Result<LoadInfo, LoadResult> LoadFromFile(StringView filePath)
	{
	    int32 x = 0;
	    int32 y = 0;
	    int32 channels_in_file = 0;
	    int32 desired_channels = 4;

	    String pathStr = scope String(filePath);

	    bool isHDR = stbi_is_hdr(pathStr.CStr()) != 0;

	    void* data = null;

	    if (isHDR)
	    {
	        data = stbi_loadf(pathStr.CStr(), &x, &y, &channels_in_file, desired_channels);
	    }
	    else
	    {
	        data = stbi_load(pathStr.CStr(), &x, &y, &channels_in_file, desired_channels);
	    }

	    if (data == null)
	    {
	        return .Err(.FileNotFound);
	    }

	    defer stbi_image_free(data);

	    int dataSize;
	    if (isHDR)
	    {
	        dataSize = x * y * desired_channels * sizeof(float);
	    }
	    else
	    {
	        dataSize = x * y * desired_channels;
	    }

	    uint8[] pixelData = new .[dataSize];
	    Internal.MemCpy(pixelData.Ptr, data, dataSize);

	    let result = LoadInfo()
	    {
	        Width = (uint32)x,
	        Height = (uint32)y,
	        Format = ToPixelFormat(desired_channels, isHDR),
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

	    bool isHDR = stbi_is_hdr_from_memory(buffer.Ptr, (int32)buffer.Length) != 0;

	    void* data = null;

	    if (isHDR)
	    {
	        data = stbi_loadf_from_memory(buffer.Ptr, (int32)buffer.Length, &x, &y, &channels_in_file, desired_channels);
	    }
	    else
	    {
	        data = stbi_load_from_memory(buffer.Ptr, (int32)buffer.Length, &x, &y, &channels_in_file, desired_channels);
	    }

	    if (data == null)
	    {
	        return .Err(.FileNotFound);
	    }

	    defer stbi_image_free(data);

	    int dataSize;
	    if (isHDR)
	    {
	        dataSize = x * y * desired_channels * sizeof(float);
	    }
	    else
	    {
	        dataSize = x * y * desired_channels;
	    }

	    uint8[] pixelData = new .[dataSize];
	    Internal.MemCpy(pixelData.Ptr, data, dataSize);

	    let result = LoadInfo()
	    {
	        Width = (uint32)x,
	        Height = (uint32)y,
	        Format = ToPixelFormat(desired_channels, isHDR),
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