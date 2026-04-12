using System.Collections;
using System;
using SDL3;

namespace Sedulous.Imaging.SDL;

class SDLImageLoader : ImageLoader
{
	private static Self sInstance = null;

	public static bool Initialized => sInstance != null;

	public static void Initialize()
	{
		if (sInstance == null)
		{
			sInstance = new .();
			ImageLoaderFactory.RegisterLoader(sInstance);
		}
	}

	private static List<StringView> sSupportedExtensions = new .() { ".png", ".jpg", ".jpeg", ".bmp", ".gif", ".tga" } ~ delete _;

	public override Result<LoadInfo, LoadResult> LoadFromFile(StringView filePath)
	{
		SDL_Surface* surface = SDL3_image.IMG_Load(scope String(filePath).CStr());
		if (surface == null)
		{
			return .Err(.FileNotFound);
		}
		defer SDL_DestroySurface(surface);

		// Always convert to RGBA32 for consistent format
		// This handles indexed/palette formats, RGB24, BGR24, and other odd formats
		SDL_Surface* convertedSurface = surface;
		bool needsDestroy = false;

		// Ensure consistent RGBA8 format
		if (surface.format != .SDL_PIXELFORMAT_RGBA32)
		{
			convertedSurface = SDL_ConvertSurface(surface, .SDL_PIXELFORMAT_RGBA32);
			if (convertedSurface == null)
			{
				return .Err(.UnsupportedFormat);
			}
			needsDestroy = true;
		}

		int width = convertedSurface.w;
		int height = convertedSurface.h;
		int srcPitch = convertedSurface.pitch;
		uint8* srcPixels = (uint8*)convertedSurface.pixels;

		int rowSize = width * 4; // tightly packed RGBA8
		uint8[] pixelData = new .[rowSize * height];

		// Copy row-by-row to remove pitch padding
		for (int y = 0; y < height; y++)
		{
			uint8* srcRow = srcPixels + y * srcPitch;
			uint8* dstRow = pixelData.Ptr + y * rowSize;
			Internal.MemCpy(dstRow, srcRow, rowSize);
		}

		let result = LoadInfo()
			{
				Width = (uint32)width,
				Height = (uint32)height,
				Format = .RGBA8, // Always RGBA8 after conversion
				Data = pixelData
			};

		if (needsDestroy)
			SDL_DestroySurface(convertedSurface);

		return .Ok(result);
	}

	public override Result<LoadInfo, LoadResult> LoadFromMemory(Span<uint8> data)
	{
		SDL_IOStream* stream = SDL_IOFromMem(data.Ptr, (uint)data.Length);
		SDL_Surface* surface = SDL3_image.IMG_Load_IO(stream, true);
		if (surface == null)
		{
			return .Err(.UnsupportedFormat);
		}
		defer SDL_DestroySurface(surface);

		// Always convert to RGBA32 for consistent format
		// This handles indexed/palette formats, RGB24, BGR24, and other odd formats
		SDL_Surface* convertedSurface = surface;
		bool needsDestroy = false;

		// Ensure consistent RGBA8 format
		if (surface.format != .SDL_PIXELFORMAT_RGBA32)
		{
			convertedSurface = SDL_ConvertSurface(surface, .SDL_PIXELFORMAT_RGBA32);
			if (convertedSurface == null)
			{
				return .Err(.UnsupportedFormat);
			}
			needsDestroy = true;
		}

		int width = convertedSurface.w;
		int height = convertedSurface.h;
		int srcPitch = convertedSurface.pitch;
		uint8* srcPixels = (uint8*)convertedSurface.pixels;

		int rowSize = width * 4; // tightly packed RGBA8
		uint8[] pixelData = new .[rowSize * height];

		// Copy row-by-row to remove pitch padding
		for (int y = 0; y < height; y++)
		{
			uint8* srcRow = srcPixels + y * srcPitch;
			uint8* dstRow = pixelData.Ptr + y * rowSize;
			Internal.MemCpy(dstRow, srcRow, rowSize);
		}

		let result = LoadInfo()
			{
				Width = (uint32)width,
				Height = (uint32)height,
				Format = .RGBA8, // Always RGBA8 after conversion
				Data = pixelData
			};

		if (needsDestroy)
			SDL_DestroySurface(convertedSurface);

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