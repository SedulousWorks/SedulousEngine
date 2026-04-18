namespace Sedulous.UI;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Fonts;

/// Flat, string-keyed theme. Keys follow "ViewType.Property" convention
/// (e.g., "Button.Background", "Label.Foreground"). No cascading.
public class Theme
{
	// === Static extension registry ===
	private static List<IThemeExtension> sExtensions = new .() ~ {
		for (let ext in _) delete ext;
		delete _;
	};

	public static void RegisterExtension(IThemeExtension ext)
	{
		sExtensions.Add(ext);
	}

	/// Remove a previously registered extension. Does NOT delete it —
	/// caller manages lifetime. Use this to clean up scope-allocated
	/// extensions in tests.
	public static void UnregisterExtension(IThemeExtension ext)
	{
		sExtensions.Remove(ext);
	}

	// === Typed dictionaries ===
	private Dictionary<String, Color> mColors = new .() ~ DeleteDictKeys(_);
	private Dictionary<String, float> mDimensions = new .() ~ DeleteDictKeys(_);
	private Dictionary<String, Thickness> mPaddings = new .() ~ DeleteDictKeys(_);
	private Dictionary<String, Drawable> mDrawables = new .() ~ {
		for (let kv in _) { delete kv.key; delete kv.value; }
		delete _;
	};
	private Dictionary<String, String> mStrings = new .() ~ {
		for (let kv in _) { delete kv.key; delete kv.value; }
		delete _;
	};
	private Dictionary<String, float> mFontSizes = new .() ~ DeleteDictKeys(_);

	public String Name = new .() ~ delete _;
	public Palette Palette;

	private static void DeleteDictKeys<T>(Dictionary<String, T> dict)
	{
		for (let kv in dict) delete kv.key;
		delete dict;
	}

	// === Setters ===

	/// Set or overwrite without leaking the key string.
	private static void SetDict<T>(Dictionary<String, T> dict, StringView key, T value)
	{
		let k = scope String(key);
		if (dict.ContainsKey(k))
			dict[k] = value;
		else
			dict[new String(key)] = value;
	}

	public void SetColor(StringView key, Color value) => SetDict(mColors, key, value);
	public void SetDimension(StringView key, float value) => SetDict(mDimensions, key, value);
	public void SetPadding(StringView key, Thickness value) => SetDict(mPaddings, key, value);
	public void SetFontSize(StringView key, float value) => SetDict(mFontSizes, key, value);

	public void SetDrawable(StringView key, Drawable value)
	{
		let k = scope String(key);
		if (mDrawables.TryGetValue(k, let old))
		{
			delete old;
			mDrawables[k] = value;
		}
		else
			mDrawables[new String(key)] = value;
	}

	public void SetString(StringView key, StringView value)
	{
		let k = scope String(key);
		if (mStrings.TryGetValue(k, let old))
		{
			old.Set(value);
		}
		else
			mStrings[new String(key)] = new String(value);
	}

	// === Getters (return default if key missing) ===

	public Color GetColor(StringView key, Color defaultValue = .White)
	{
		let k = scope String(key);
		if (mColors.TryGetValue(k, let value))
			return value;
		return defaultValue;
	}

	/// Nullable color lookup — returns null if the key is not set.
	/// Use when you need a fallback chain: theme key -> palette -> hardcoded.
	public Color? TryGetColor(StringView key)
	{
		let k = scope String(key);
		if (mColors.TryGetValue(k, let value))
			return value;
		return null;
	}

	public float GetDimension(StringView key, float defaultValue = 0)
	{
		let k = scope String(key);
		if (mDimensions.TryGetValue(k, let value))
			return value;
		return defaultValue;
	}

	public Thickness GetPadding(StringView key, Thickness defaultValue = .())
	{
		let k = scope String(key);
		if (mPaddings.TryGetValue(k, let value))
			return value;
		return defaultValue;
	}

	public Drawable GetDrawable(StringView key)
	{
		let k = scope String(key);
		if (mDrawables.TryGetValue(k, let value))
			return value;
		return null;
	}

	public String GetString(StringView key, String defaultValue = null)
	{
		let k = scope String(key);
		if (mStrings.TryGetValue(k, let value))
			return value;
		return defaultValue;
	}

	public float GetFontSize(StringView key, float defaultValue = 16)
	{
		let k = scope String(key);
		if (mFontSizes.TryGetValue(k, let value))
			return value;
		return defaultValue;
	}

	public bool HasKey(StringView key)
	{
		let k = scope String(key);
		return mColors.ContainsKey(k) || mDimensions.ContainsKey(k) ||
			   mPaddings.ContainsKey(k) || mDrawables.ContainsKey(k) ||
			   mStrings.ContainsKey(k) || mFontSizes.ContainsKey(k);
	}

	/// Apply all registered extensions. Call after base theme initialization.
	public void ApplyExtensions()
	{
		for (let ext in sExtensions)
			ext.Apply(this);
	}
}
