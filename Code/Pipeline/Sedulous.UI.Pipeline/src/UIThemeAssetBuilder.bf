using System;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Pipeline.Core;
using Sedulous.UI;
using Sedulous.UI.Resource;

namespace Sedulous.UI.Pipeline;

/// Cooks a stylesheet, parsing it on the way through so a malformed one fails at the cook.
class UIThemeAssetBuilder : IAssetBuilder
{
	public Type AssetType => typeof(UIThemeAsset);
	public Type ProductType => typeof(UIThemeResource);

	public Result<void, ErrorCode> Build(Asset asset, AssetBuildContext context)
	{
		if (context.Output == null)
			return .Err(.InvalidArgument);

		let theme = (UIThemeAsset)asset;
		if (theme.FileName.IsEmpty)
		{
			GlobalLog(.Error, "UI: the theme has no linked source file, so there is nothing to cook");
			return .Err(.InvalidArgument);
		}

		let stylesheet = scope String();
		if (AssetSource.ReadText(context, theme.FileName.Value, stylesheet) case .Err(let readError))
		{
			GlobalLog(.Error, "UI: the theme's source file '{}' is missing", theme.FileName.Value);
			return .Err(readError);
		}
		if (stylesheet.IsEmpty)
		{
			GlobalLog(.Error, "UI: the theme is empty, so there is nothing to cook");
			return .Err(.InvalidArgument);
		}

		let loader = scope StyleSheetLoader();
		loader.SetPalette(ThemePalette.Dark()); // so palette variables resolve at cook time
		let sheet = loader.Load(stylesheet);
		if (sheet == null)
		{
			GlobalLog(.Error, "UI: the theme did not parse");
			return .Err(.InvalidArgument);
		}
		sheet.ReleaseRef();

		// The TEXT is what is cooked, not the parsed sheet: parsing needs a palette bound, and
		// which palette is the application's choice, so one cooked theme serves every variant
		// of itself.
		let cooked = scope UIThemeResource();
		cooked.StyleSheet.Set(stylesheet);
		return context.Output.WriteObject(cooked);
	}
}
