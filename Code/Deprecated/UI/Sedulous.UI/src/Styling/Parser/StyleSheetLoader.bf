using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Image;

namespace Sedulous.UI;

/// The entry point for loading style sheet files.
class StyleSheetLoader
{
	/// For `@import`, `@icon` file loading and the image factory. BORROWED, and null means
	/// those fail gracefully rather than refusing the whole sheet.
	public IResourceProvider ResourceProvider = null;

	private Dictionary<String, String> mSvgRegistry = new .() ~ DeleteDictionaryAndKeysAndValues!(_);
	/// The images are BORROWED; whoever loaded them owns them.
	private Dictionary<String, ImageData> mImageRegistry = new .() ~ DeleteDictionaryAndKeys!(_);
	private Dictionary<String, Color> mBasePalette = new .() ~ DeleteDictionaryAndKeys!(_);

	public this() {}

	/// Registers an SVG by name from inline text, for `svg(name)` in a sheet.
	public void RegisterSvg(StringView name, StringView svgText)
	{
		if (mSvgRegistry.TryGetAlt(name, let existingKey, let existingText))
		{
			existingText.Set(svgText);
			return;
		}
		mSvgRegistry[new String(name)] = new String(svgText);
	}

	/// Registers an image by name, for `image(name)` in a sheet. BORROWED: the caller keeps
	/// the image alive.
	public void RegisterImage(StringView name, ImageData imageData)
	{
		if (mImageRegistry.TryGetAlt(name, let existingKey, ?))
		{
			mImageRegistry[existingKey] = imageData;
			return;
		}
		mImageRegistry[new String(name)] = imageData;
	}

	/// Sets one base palette variable. A sheet's own `@palette` block may override it.
	public void SetPaletteVariable(StringView name, Color color)
	{
		if (mBasePalette.TryGetAlt(name, let existingKey, ?))
		{
			mBasePalette[existingKey] = color;
			return;
		}
		mBasePalette[new String(name)] = color;
	}

	/// Sets the whole base palette from a theme palette.
	public void SetPalette(ThemePalette palette)
	{
		SetPaletteVariable("primary", palette.Primary);
		SetPaletteVariable("primary-accent", palette.PrimaryAccent);
		SetPaletteVariable("background", palette.Background);
		SetPaletteVariable("surface", palette.Surface);
		SetPaletteVariable("surface-bright", palette.SurfaceBright);
		SetPaletteVariable("border", palette.Border);
		SetPaletteVariable("text", palette.Text);
		SetPaletteVariable("text-dim", palette.TextDim);
		SetPaletteVariable("error", palette.Error);
		SetPaletteVariable("success", palette.Success);
		SetPaletteVariable("warning", palette.Warning);
	}

	/// Loads a sheet from style sheet text. OWNERSHIP of the result transfers.
	public StyleSheet Load(StringView source, StringView basePath = default)
	{
		// Ensured HERE rather than trusted to a startup call. A host that skipped it would
		// get type selectors resolving to nothing and matching nothing, and the parser would
		// then eat the first declaration while recovering. Registration is idempotent.
		InitializeGlobals();

		// The palette is COPIED, so a sheet's own `@palette` blocks cannot leak back into the
		// loader and change what the next sheet sees.
		let palette = scope Dictionary<String, Color>();
		defer { for (let key in palette.Keys) delete key; }
		for (let pair in mBasePalette)
			palette[new String(pair.key)] = pair.value;

		let tokenizer = scope Tokenizer(source);
		let tokens = new List<Token>();
		tokenizer.TokenizeAll(tokens);

		let parser = scope SSSParser(tokens, palette, mSvgRegistry, mImageRegistry,
			ResourceProvider, basePath);
		let sheet = parser.Parse();

		// The palette, base plus whatever the sheet declared, ALSO becomes a rule of custom
		// properties, so `$primary` at parse time and `var(--primary)` at compute time read
		// the same colours. Prepended, so a `--name` the sheet declares on View wins over it.
		if (!palette.IsEmpty)
		{
			let variables = new StyleRule();
			variables.Selector.ViewType = UITypeRegistry.Resolve("View");

			let name = scope String();
			for (let pair in palette)
			{
				name.Set("--");
				name.Append(pair.key);
				variables.SetCustom(name, .Color(pair.value));
			}
			sheet.PrependRule(variables);
		}

		return sheet;
	}

	/// Registers the built in drawable factories and view types. Idempotent, and safe to call
	/// at startup.
	///
	/// A host that loads a sheet needs both: the factories to build what a declaration names,
	/// and the type names for element selectors to resolve against.
	public static void InitializeGlobals()
	{
		DrawableFactoryRegistry.RegisterBuiltins();
		UITypeRegistry.RegisterBuiltins();
	}
}
