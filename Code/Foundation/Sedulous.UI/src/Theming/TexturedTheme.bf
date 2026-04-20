namespace Sedulous.UI;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Images;

/// Entry for a single image in a ThemeImageSet.
public struct ThemeImageEntry
{
	public IImageData Image;
	public NineSlice Slices;
	public bool IsNineSlice;
}

/// Generic container for theme images, keyed by drawable key name.
/// Core registers its entries, toolkit extensions add their own.
/// Pass to TexturedTheme.Create() to build the theme.
public class ThemeImageSet
{
	private Dictionary<String, ThemeImageEntry> mImages = new .() ~ {
		for (let kv in _) delete kv.key;
		delete _;
	};

	// State image groups: drawable key -> (state -> internal image key).
	private Dictionary<String, List<(ControlState, String)>> mStateGroups = new .() ~ {
		for (let kv in _)
		{
			delete kv.key;
			for (let entry in kv.value) delete entry.1;
			delete kv.value;
		}
		delete _;
	};

	/// Add a single image for a drawable key. Uses 9-slice if slices are non-zero.
	public void AddImage(StringView drawableKey, IImageData image, NineSlice slices = default)
	{
		if (image == null) return;
		ThemeImageEntry entry;
		entry.Image = image;
		entry.Slices = slices;
		entry.IsNineSlice = slices.IsValid;
		mImages[new String(drawableKey)] = entry;
	}

	/// Add state-variant images for a drawable key (creates a StateListDrawable).
	/// Each state image is registered internally and grouped under the drawable key.
	public void AddStateImages(StringView drawableKey,
		IImageData normal, IImageData hover = null,
		IImageData pressed = null, IImageData disabled = null,
		IImageData focused = null, NineSlice slices = default)
	{
		let group = new List<(ControlState, String)>();

		void AddState(ControlState state, IImageData img, StringView suffix)
		{
			if (img == null) return;
			let internalKey = scope String();
			internalKey.AppendF("{}_{}", drawableKey, suffix);
			AddImage(internalKey, img, slices);
			group.Add((state, new String(internalKey)));
		}

		AddState(.Normal, normal, "Normal");
		AddState(.Hover, hover, "Hover");
		AddState(.Pressed, pressed, "Pressed");
		AddState(.Disabled, disabled, "Disabled");
		AddState(.Focused, focused, "Focused");

		mStateGroups[new String(drawableKey)] = group;
	}

	/// Iterate all image entries.
	public Dictionary<String, ThemeImageEntry>.Enumerator GetImages() => mImages.GetEnumerator();

	/// Iterate all state groups.
	public Dictionary<String, List<(ControlState, String)>>.Enumerator GetStateGroups() => mStateGroups.GetEnumerator();

	/// Get a single image entry by key.
	public ThemeImageEntry? GetEntry(StringView key)
	{
		for (let kv in mImages)
			if (StringView(kv.key) == key)
				return kv.value;
		return null;
	}
}

/// Creates a fully image-skinned theme from a ThemeImageSet.
/// All provided images are packed into a single atlas for optimal
/// GPU batching (zero texture switches during UI rendering).
public static class TexturedTheme
{
	/// Create a textured theme. Starts from DarkTheme colors as base,
	/// then overlays drawables for all provided images.
	public static Theme Create(ThemeImageSet images)
	{
		let theme = DarkTheme.Create();
		theme.Name.Set("Textured");

		let atlas = new ThemeAtlas();

		// Add all images to atlas.
		for (let kv in images.GetImages())
			atlas.AddImage(kv.key, kv.value.Image);

		if (!atlas.Build())
		{
			delete atlas;
			return theme;
		}

		// Create drawables for state groups (StateListDrawable).
		for (let kv in images.GetStateGroups())
		{
			let drawableKey = kv.key;
			let states = kv.value;
			let stateList = new StateListDrawable(true);

			for (let (state, internalKey) in states)
			{
				let entry = images.GetEntry(internalKey);
				if (!entry.HasValue) continue;

				Drawable drawable;
				if (entry.Value.IsNineSlice)
					drawable = atlas.CreateNineSliceDrawable(internalKey, entry.Value.Slices);
				else
					drawable = atlas.CreateImageDrawable(internalKey);

				if (drawable != null)
					stateList.Set(state, drawable);
			}

			theme.SetDrawable(drawableKey, stateList);
		}

		// Create drawables for non-grouped images (single drawable per key).
		for (let kv in images.GetImages())
		{
			let key = StringView(kv.key);

			// Skip internal state images (they're handled by state groups above).
			bool isStateImage = false;
			for (let sg in images.GetStateGroups())
			{
				for (let (_, internalKey) in sg.value)
				{
					if (key == StringView(internalKey))
					{
						isStateImage = true;
						break;
					}
				}
				if (isStateImage) break;
			}
			if (isStateImage) continue;

			// Skip if theme already has a drawable for this key (from state groups).
			if (theme.GetDrawable(key) != null) continue;

			let entry = kv.value;
			Drawable drawable;
			if (entry.IsNineSlice)
				drawable = atlas.CreateNineSliceDrawable(key, entry.Slices);
			else
				drawable = atlas.CreateImageDrawable(key);

			if (drawable != null)
				theme.SetDrawable(key, drawable);
		}

		// Register SVG icons for consistent styling.
		RegisterSVGIcons(theme);

		// Theme owns the atlas so it lives as long as the drawables that reference it.
		theme.OwnResource(atlas);

		return theme;
	}

	private static void RegisterSVGIcons(Theme theme)
	{
		void SetSVG(StringView key, StringView svg)
		{
			// Don't overwrite if already set (e.g., by an image in the set).
			if (theme.GetDrawable(key) != null) return;
			let d = SVGDrawable.FromString(svg);
			if (d != null) theme.SetDrawable(key, d);
		}

		SetSVG("ComboBox.Arrow", ThemeIcons.ArrowDown);
		SetSVG("NumericField.UpArrow", ThemeIcons.ArrowUp);
		SetSVG("NumericField.DownArrow", ThemeIcons.ArrowDown);
		SetSVG("Expander.ArrowCollapsed", ThemeIcons.ChevronRight);
		SetSVG("Expander.ArrowExpanded", ThemeIcons.ChevronDown);
		SetSVG("TabView.CloseIcon", ThemeIcons.Close);
		SetSVG("DockablePanel.CloseIcon", ThemeIcons.Close);
		SetSVG("ContextMenu.SubmenuArrow", ThemeIcons.ChevronRight);
	}
}
