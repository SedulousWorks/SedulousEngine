namespace Sedulous.GUI;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;

/// Entry point for loading .sss stylesheet files.
///
/// Usage:
///   let sheet = StyleSheetLoader.LoadFromString(sssContent);
///   context.StyleSheet = sheet;
public static class StyleSheetLoader
{
	/// Load a StyleSheet from .sss text content.
	public static StyleSheet LoadFromString(StringView source)
	{
		let tokenizer = scope Tokenizer(source);
		let tokens = new List<Token>();
		tokenizer.TokenizeAll(tokens);

		let parser = scope SSSParser(tokens);
		return parser.Parse();
	}

	/// Load a StyleSheet from .sss text with a base palette.
	public static StyleSheet LoadFromString(StringView source, Dictionary<String, Color> basePalette)
	{
		let tokenizer = scope Tokenizer(source);
		let tokens = new List<Token>();
		tokenizer.TokenizeAll(tokens);

		let parser = scope SSSParser(tokens);
		return parser.Parse(basePalette);
	}

	/// Initialize the parser infrastructure. Call once at startup.
	public static void Initialize()
	{
		UITypeRegistry.RegisterBuiltins();
		DrawableFactoryRegistry.RegisterBuiltins();
	}
}
