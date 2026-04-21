namespace Sedulous.Editor.Core;

using System;
using Sedulous.Images;

/// Generates thumbnail images for the asset browser.
interface IAssetThumbnailGenerator
{
	Result<OwnedImageData> GenerateThumbnail(StringView assetPath, int32 width, int32 height);
}
