using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Image;
using Sedulous.Image.IO;
using Sedulous.Image.Resource;
using Sedulous.Pipeline.Core;

namespace Sedulous.Image.Pipeline;

/// Decodes the source file into a header and a pixel stream.
class ImageAssetBuilder : IAssetBuilder
{
	/// The stream the decoded pixels travel in, beside the envelope.
	public const String cPixelStreamName = "pixels";

	public Type AssetType => typeof(ImageAsset);
	public Type ProductType => typeof(ImageResource);

	public Result<void, ErrorCode> Build(Asset asset, AssetBuildContext context)
	{
		if (context.Output == null)
			return .Err(.InvalidArgument);

		let authored = (ImageAsset)asset;

		let bytes = scope List<uint8>();
		if (AssetSource.ReadBytes(context, authored.FileName.Value, bytes) case .Err(let readError))
			return .Err(readError);

		let image = scope Image();
		if (ImageIO.LoadImageFromMemory(bytes, image) case .Err(let decodeError))
			return .Err(decodeError);

		let resource = scope ImageResource();
		resource.Width = image.Width;
		resource.Height = image.Height;
		resource.Format = image.Format;
		resource.ColorSpace = authored.ColorSpace;

		if (context.Output.WriteObject(resource) case .Err(let writeError))
			return .Err(writeError);

		// The PIXELS go in a stream of their own rather than into the envelope, which may be
		// text: a decoded image is bulk by definition.
		return context.Output.WriteData(cPixelStreamName, image.PixelData);
	}
}
