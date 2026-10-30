using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Image;
using Sedulous.Image.Pipeline;

namespace Sedulous.Editor.Image;

/// The image page's headless half: the source format label its facts say.
static class ImageAssetEdit
{
	public static StringView PixelFormatLabel(PixelFormat format)
	{
		switch (format)
		{
		case .R8: return "R8";
		case .RG8: return "RG8";
		case .RGB8: return "RGB8";
		case .RGBA8: return "RGBA8";
		case .RGBA32F: return "RGBA32F (HDR)";
		default: return "?";
		}
	}
}
