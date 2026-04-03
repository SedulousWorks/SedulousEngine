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
		if(sInstance == null)
		{
			sInstance = new .();
			ImageLoaderFactory.RegisterLoader(sInstance);
		}
	}

	private static List<StringView> sSupportedExtensions = new .() { ".png", ".jpg", ".jpeg", ".bmp", ".gif", ".tga" } ~ delete _;

	private static Image.PixelFormat SDLSurfaceFormatToPixelFormat(SDL_PixelFormat sdlFormat)
	{
		switch (sdlFormat)
		{
		case .SDL_PIXELFORMAT_RGB24:
			return .RGB8;
		case .SDL_PIXELFORMAT_BGR24:
			return .BGR8;
		case .SDL_PIXELFORMAT_RGBA8888,
			.SDL_PIXELFORMAT_RGBA32:
			return .RGBA8;
		case .SDL_PIXELFORMAT_BGRA8888,
			.SDL_PIXELFORMAT_BGRA32:
			return .BGRA8;
		/*case .SDL_PIXELFORMAT_ABGR8888,
			 .SDL_PIXELFORMAT_ABGR32:
			return .RGBA8;  // Note: ABGR will need swizzling to RGBA
		case .SDL_PIXELFORMAT_ARGB8888,
			 .SDL_PIXELFORMAT_ARGB32:
			return .BGRA8;  // Note: ARGB will need swizzling to BGRA*/
		case .SDL_PIXELFORMAT_RGB48_FLOAT:
			return .RGB16F;
		case .SDL_PIXELFORMAT_BGR48_FLOAT:
			return .RGB16F; // Note: BGR will need swizzling
		case .SDL_PIXELFORMAT_RGBA64_FLOAT:
			return .RGBA16F;
		case .SDL_PIXELFORMAT_BGRA64_FLOAT:
			return .RGBA16F; // Note: BGRA will need swizzling
		case .SDL_PIXELFORMAT_ABGR64_FLOAT:
			return .RGBA16F; // Note: ABGR will need swizzling
		case .SDL_PIXELFORMAT_ARGB64_FLOAT:
			return .RGBA16F; // Note: ARGB will need swizzling
		case .SDL_PIXELFORMAT_RGB96_FLOAT:
			return .RGB32F;
		case .SDL_PIXELFORMAT_BGR96_FLOAT:
			return .RGB32F; // Note: BGR will need swizzling
		case .SDL_PIXELFORMAT_RGBA128_FLOAT:
			return .RGBA32F;
		case .SDL_PIXELFORMAT_BGRA128_FLOAT:
			return .RGBA32F; // Note: BGRA will need swizzling
		case .SDL_PIXELFORMAT_ABGR128_FLOAT:
			return .RGBA32F; // Note: ABGR will need swizzling
		case .SDL_PIXELFORMAT_ARGB128_FLOAT:
			return .RGBA32F; // Note: ARGB will need swizzling
		default:
			// For unsupported formats, default to RGBA8
			return .RGBA8;
		}
	}

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

		if (surface.format != .SDL_PIXELFORMAT_RGBA32 &&
			surface.format != .SDL_PIXELFORMAT_RGBA8888)
		{
			convertedSurface = SDL_ConvertSurface(surface, .SDL_PIXELFORMAT_RGBA32);
			if (convertedSurface == null)
			{
				return .Err(.UnsupportedFormat);
			}
			needsDestroy = true;
		}

		uint8[] pixelData = new .[convertedSurface.pitch * convertedSurface.h];
		Internal.MemCpy(pixelData.Ptr, convertedSurface.pixels, pixelData.Count);

		let result = LoadInfo()
			{
				Width = (uint32)convertedSurface.w,
				Height = (uint32)convertedSurface.h,
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

		if (surface.format != .SDL_PIXELFORMAT_RGBA32 &&
			surface.format != .SDL_PIXELFORMAT_RGBA8888)
		{
			convertedSurface = SDL_ConvertSurface(surface, .SDL_PIXELFORMAT_RGBA32);
			if (convertedSurface == null)
			{
				return .Err(.UnsupportedFormat);
			}
			needsDestroy = true;
		}

		uint8[] pixelData = new .[convertedSurface.pitch * convertedSurface.h];
		Internal.MemCpy(pixelData.Ptr, convertedSurface.pixels, pixelData.Count);

		let result = LoadInfo()
			{
				Width = (uint32)convertedSurface.w,
				Height = (uint32)convertedSurface.h,
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