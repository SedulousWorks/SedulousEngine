namespace Sedulous.UI;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Images;

/// Entry point for loading .sss stylesheet files.
///
/// Usage:
///   let loader = scope StyleSheetLoader();
///   loader.RegisterSvg("checkmark", ThemeIcons.Checkmark);
///   let sheet = loader.Load(sssText);
///   context.StyleSheet = sheet;
public class StyleSheetLoader
{
	/// Pre-registered SVG text by name. These are available to svg() factory calls.
	private Dictionary<String, String> mSvgRegistry = new .() ~ DeleteDictionaryAndKeysAndValues!(_);

	/// Pre-registered image data by name. Available to image()/nine-slice() calls.
	private Dictionary<String, IImageData> mImageRegistry = new .() ~ DeleteDictionaryAndKeys!(_);

	/// Base palette variables. Set before Load() to provide default palette values
	/// that .sss @palette blocks can extend.
	private Dictionary<String, Color32> mBasePalette = new .() ~ DeleteDictionaryAndKeys!(_);

	/// Resource provider for @import, @icon file loading, image() factory.
	public IResourceProvider ResourceProvider;

	/// Register an SVG by name from inline text. Available to svg(name) in .sss.
	public void RegisterSvg(StringView name, StringView svgText)
	{
		for (let kv in mSvgRegistry)
		{
			if (StringView(kv.key) == name)
			{
				delete mSvgRegistry[kv.key];
				mSvgRegistry[kv.key] = new String(svgText);
				return;
			}
		}
		mSvgRegistry[new String(name)] = new String(svgText);
	}

	/// Register an image by name from pre-built data. Available to image(name) in .sss.
	/// The loader does NOT own the image data — caller is responsible for lifetime.
	public void RegisterImage(StringView name, IImageData imageData)
	{
		for (let kv in mImageRegistry)
		{
			if (StringView(kv.key) == name)
			{
				mImageRegistry[kv.key] = imageData;
				return;
			}
		}
		mImageRegistry[new String(name)] = imageData;
	}

	/// Set a base palette variable. .sss @palette blocks can override these.
	public void SetPaletteVariable(StringView name, Color32 color)
	{
		for (let kv in mBasePalette)
		{
			if (StringView(kv.key) == name)
			{
				mBasePalette[kv.key] = color;
				return;
			}
		}
		mBasePalette[new String(name)] = color;
	}

	/// Set base palette from a ThemePalette struct.
	public void SetPalette(ThemePalette p)
	{
		SetPaletteVariable("primary", p.Primary);
		SetPaletteVariable("primary-accent", p.PrimaryAccent);
		SetPaletteVariable("background", p.Background);
		SetPaletteVariable("surface", p.Surface);
		SetPaletteVariable("surface-bright", p.SurfaceBright);
		SetPaletteVariable("border", p.Border);
		SetPaletteVariable("text", p.Text);
		SetPaletteVariable("text-dim", p.TextDim);
		SetPaletteVariable("error", p.Error);
		SetPaletteVariable("success", p.Success);
		SetPaletteVariable("warning", p.Warning);
	}

	/// Load a StyleSheet from .sss text content.
	public StyleSheet Load(StringView source, StringView basePath = "")
	{
		// Copy palette so the parser can mutate it without affecting the loader.
		let palette = new Dictionary<String, Color32>();
		for (let kv in mBasePalette)
			palette[new String(kv.key)] = kv.value;
		defer { DeleteDictionaryAndKeys!(palette); }

		let tokenizer = scope Tokenizer(source);
		let tokens = new List<Token>();
		tokenizer.TokenizeAll(tokens);

		let basePathStr = new String(basePath);
		defer delete basePathStr;

		let parser = scope SSSParser(tokens, palette, mSvgRegistry, mImageRegistry,
			ResourceProvider, basePathStr);
		return parser.Parse();
	}

	/// Convenience: initialize registries. Call once at startup.
	public static void InitializeGlobals()
	{
		UITypeRegistry.RegisterBuiltins();
		DrawableFactoryRegistry.RegisterBuiltins();
	}
}
