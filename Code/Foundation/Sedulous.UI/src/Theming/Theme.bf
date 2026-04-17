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

	public void SetColor(StringView key, Color value)
	{
		mColors[new String(key)] = value;
	}

	public void SetDimension(StringView key, float value)
	{
		mDimensions[new String(key)] = value;
	}

	public void SetPadding(StringView key, Thickness value)
	{
		mPaddings[new String(key)] = value;
	}

	public void SetDrawable(StringView key, Drawable value)
	{
		// Delete old drawable if replacing.
		let k = scope String(key);
		if (mDrawables.TryGetValue(k, let old))
		{
			delete old;
			mDrawables.Remove(k);
		}
		mDrawables[new String(key)] = value;
	}

	public void SetString(StringView key, StringView value)
	{
		let k = scope String(key);
		if (mStrings.TryGetValue(k, let old))
		{
			delete old;
			mStrings.Remove(k);
		}
		mStrings[new String(key)] = new String(value);
	}

	public void SetFontSize(StringView key, float value)
	{
		mFontSizes[new String(key)] = value;
	}

	// === Getters (return default if key missing) ===

	public Color GetColor(StringView key, Color defaultValue = .White)
	{
		let k = scope String(key);
		if (mColors.TryGetValue(k, let value))
			return value;
		return defaultValue;
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
