using System;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Pipeline.Core;
using Sedulous.UI.Resource;
using Sedulous.VG.SVG;

namespace Sedulous.UI.Pipeline;

/// Cooks a vector image, loading it on the way through: the document must read as the
/// renderer reads it, or the cook fails.
class UIVectorImageAssetBuilder : IAssetBuilder
{
	public Type AssetType => typeof(UIVectorImageAsset);
	public Type ProductType => typeof(UIVectorImageResource);

	public Result<void, ErrorCode> Build(Asset asset, AssetBuildContext context)
	{
		if (context.Output == null)
			return .Err(.InvalidArgument);

		let image = (UIVectorImageAsset)asset;
		if (image.FileName.IsEmpty)
		{
			GlobalLog(.Error, "UI: the vector image has no linked source file, so there is nothing to cook");
			return .Err(.InvalidArgument);
		}

		let svg = scope String();
		if (AssetSource.ReadText(context, image.FileName.Value, svg) case .Err(let readError))
		{
			GlobalLog(.Error, "UI: the vector image's source file '{}' is missing", image.FileName.Value);
			return .Err(readError);
		}
		switch (SVGLoader.Load(svg))
		{
		case .Ok(let document): delete document;
		case .Err:
			GlobalLog(.Error, "UI: the vector image '{}' is not an SVG this engine reads", image.FileName.Value);
			return .Err(.InvalidArgument);
		}

		let cooked = scope UIVectorImageResource();
		cooked.Svg.Set(svg);
		return context.Output.WriteObject(cooked);
	}
}
