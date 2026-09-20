using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Content;
using Sedulous.Image;
using Sedulous.VFS;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Core.Tests;

/// Covers "StubAsset"; counts its calls and fails to generate on request.
class StubThumbnailGenerator : IThumbnailGenerator
{
	public int* PrepareCount = null;
	public int* GenerateCount = null;
	public bool FailGenerate = false;

	public void AssetTypeNames(List<StringView> outNames) => outNames.Add("StubAsset");

	public Result<void, ErrorCode> Prepare(Instance instance, IFileSystem sources, List<uint8> outPayload)
	{
		if (PrepareCount != null)
			(*PrepareCount)++;
		outPayload.Add(42);
		return .Ok;
	}

	public Result<void, ErrorCode> Generate(Span<uint8> payload, Image outImage)
	{
		if (GenerateCount != null)
			(*GenerateCount)++;
		if (FailGenerate)
			return .Err(.Internal);
		SolidTile(200, outImage);
		return .Ok;
	}

	/// An 8x8 RGBA tile of one red level, opaque.
	public static void SolidTile(uint8 red, Image outImage)
	{
		let pixels = scope uint8[8 * 8 * 4];
		for (int i = 0; i < pixels.Count; i += 4)
		{
			pixels[i] = red;
			pixels[i + 3] = 255;
		}
		outImage.ReplaceData(8, 8, .RGBA8, pixels);
	}
}
