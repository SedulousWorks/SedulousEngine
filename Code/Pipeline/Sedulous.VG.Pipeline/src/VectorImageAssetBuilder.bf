using System;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Pipeline.Core;
using Sedulous.VG.Resource;
using Sedulous.VG.SVG;

namespace Sedulous.VG.Pipeline;

/// Cooks a vector image, loading it on the way through: the document must read as the
/// renderer reads it, or the cook fails.
class VectorImageAssetBuilder : IAssetBuilder
{
	public Type AssetType => typeof(VectorImageAsset);
	public Type ProductType => typeof(VectorImageResource);

	public Result<void, ErrorCode> Build(Asset asset, AssetBuildContext context)
	{
		if (context.Output == null)
			return .Err(.InvalidArgument);

		let image = (VectorImageAsset)asset;
		if (image.FileName.IsEmpty)
		{
			GlobalLog(.Error, "VG: the vector image has no linked source file, so there is nothing to cook");
			return .Err(.InvalidArgument);
		}

		let svg = scope String();
		if (AssetSource.ReadText(context, image.FileName.Value, svg) case .Err(let readError))
		{
			GlobalLog(.Error, "VG: the vector image's source file '{}' is missing", image.FileName.Value);
			return .Err(readError);
		}
		switch (SVGLoader.Load(svg))
		{
		case .Ok(let document): delete document;
		case .Err:
			GlobalLog(.Error, "VG: the vector image '{}' is not an SVG this engine reads", image.FileName.Value);
			return .Err(.InvalidArgument);
		}

		let cooked = scope VectorImageResource();
		cooked.Svg.Set(svg);
		return context.Output.WriteObject(cooked);
	}
}
