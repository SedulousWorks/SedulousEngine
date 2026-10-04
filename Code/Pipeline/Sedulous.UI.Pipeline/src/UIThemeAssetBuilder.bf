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
	/// 2: the icons the sheet names, embedded.
	public int32 Version => 2;

	/// The vector images the sheet's `@icon`s name: their content is embedded, so a changed
	/// icon recooks the theme.
	public void ScanDependencies(Asset asset, AssetBuildContext context, AssetDependencies outDeps)
	{
		let theme = (UIThemeAsset)asset;
		if (theme.FileName.IsEmpty)
			return;
		let stylesheet = scope String();
		if (AssetSource.ReadText(context, theme.FileName.Value, stylesheet) case .Err)
			return;
		// Parsed with no context: every reference is recorded, none read.
		let collector = scope ThemeIconCollector(null);
		let loader = scope StyleSheetLoader();
		loader.SetPalette(ThemePalette.Dark());
		loader.ResourceProvider = collector;
		if (let sheet = loader.Load(stylesheet))
			sheet.ReleaseRef();
		for (let id in collector.References)
			outDeps.Reads.Add(id);
	}

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

		let icons = scope ThemeIconCollector(context);
		let loader = scope StyleSheetLoader();
		loader.SetPalette(ThemePalette.Dark()); // so palette variables resolve at cook time
		loader.ResourceProvider = icons; // @icon: the vector images, embedded below
		let sheet = loader.Load(stylesheet);
		if (sheet == null)
		{
			GlobalLog(.Error, "UI: the theme did not parse");
			return .Err(.InvalidArgument);
		}
		sheet.ReleaseRef();
		if (!icons.Missing.IsEmpty)
		{
			for (let missing in icons.Missing)
				GlobalLog(.Error, "UI: the theme's @icon \"{}\" names no vector image asset", missing);
			return .Err(.NotFound);
		}

		// The TEXT is what is cooked, not the parsed sheet: parsing needs a palette bound, and
		// which palette is the application's choice, so one cooked theme serves every variant
		// of itself.
		let cooked = scope UIThemeResource();
		cooked.StyleSheet.Set(stylesheet);
		for (int i < icons.IconIds.Count)
		{
			cooked.IconIds.Add(new .(icons.IconIds[i]));
			cooked.IconSvgs.Add(new .(icons.IconSvgs[i]));
		}
		return context.Output.WriteObject(cooked);
	}
}
