using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Image;
using Sedulous.UI;

namespace Samples.UISandbox;

/// The two themes the sandbox builds rather than takes from the engine: a fully image skinned
/// one, and one loaded from a style sheet on disk.
static class SandboxThemes
{
	typealias Px = RoundedRectImage.Px;

	/// A theme whose every visual region is an IMAGE, generated here and packed into one atlas.
	///
	/// The source images only have to outlive the Create call, which copies their pixels into
	/// its atlas, so they are dropped on the way out. OWNERSHIP of the sheet transfers.
	public static StyleSheet CreateTextured()
	{
		let images = scope ThemeImageSet();
		let keep = scope List<OwnedImageData>();
		defer { ClearAndDeleteItems!(keep); }

		ImageData Hold(OwnedImageData image)
		{
			keep.Add(image);
			return image;
		}

		// Buttons, in soft blue, with every state drawn rather than derived.
		images.AddStateImages("button:Background",
			Hold(RoundedRectImage.Make(48, 32, .(180, 200, 225), .(140, 165, 195), 6)),
			Hold(RoundedRectImage.Make(48, 32, .(190, 210, 235), .(150, 175, 205), 6)),
			Hold(RoundedRectImage.Make(48, 32, .(150, 175, 205), .(120, 145, 175), 6)),
			Hold(RoundedRectImage.Make(48, 32, .(195, 205, 215, 128), .(175, 185, 195, 128), 6)),
			null, NineSlice(8, 8, 8, 8));

		images.AddImage("panel:Background",
			Hold(RoundedRectImage.Make(48, 48, .(220, 230, 240), .(185, 200, 220), 4)),
			NineSlice(8, 8, 8, 8));

		// Text fields: white, and the FOCUSED state is the only one that changes, which is the
		// border going blue.
		let fieldNormal = Hold(RoundedRectImage.Make(48, 28, .(245, 248, 252), .(170, 185, 210), 4));
		let fieldFocused = Hold(RoundedRectImage.Make(48, 28, .(245, 248, 252), .(80, 130, 200), 4));
		images.AddStateImages("edittext:Background", fieldNormal, null, null, null, fieldFocused,
			NineSlice(6, 6, 6, 6));
		images.AddStateImages("numericfield:Background", fieldNormal, null, null, null,
			fieldFocused, NineSlice(6, 6, 6, 6));

		// The spin buttons round on ONE outer corner each, so the pair tucks into the field.
		images.AddStateImages("numericfield::spin-up",
			Hold(RoundedRectImage.Make(20, 16, .(225, 230, 240), .(170, 185, 210), 0, 3, 0, 0)),
			Hold(RoundedRectImage.Make(20, 16, .(210, 218, 230), .(150, 170, 200), 0, 3, 0, 0)),
			Hold(RoundedRectImage.Make(20, 16, .(195, 205, 220), .(140, 160, 190), 0, 3, 0, 0)),
			null, null, NineSlice(4, 4, 4, 4));
		images.AddStateImages("numericfield::spin-down",
			Hold(RoundedRectImage.Make(20, 16, .(225, 230, 240), .(170, 185, 210), 0, 0, 3, 0)),
			Hold(RoundedRectImage.Make(20, 16, .(210, 218, 230), .(150, 170, 200), 0, 0, 3, 0)),
			Hold(RoundedRectImage.Make(20, 16, .(195, 205, 220), .(140, 160, 190), 0, 0, 3, 0)),
			null, null, NineSlice(4, 4, 4, 4));

		images.AddImage("checkbox::box",
			Hold(RoundedRectImage.Make(16, 16, .(240, 244, 250), .(160, 175, 200), 3)));
		images.AddImage("checkbox::box:checked",
			Hold(RoundedRectImage.Make(16, 16, .(80, 140, 220), .(60, 120, 200), 3)));

		// A radius of half the side makes the radio a circle.
		images.AddImage("radiobutton::box",
			Hold(RoundedRectImage.Make(16, 16, .(240, 244, 250), .(160, 175, 200), 8)));
		images.AddImage("radiobutton::box:checked",
			Hold(RoundedRectImage.Make(16, 16, .(80, 140, 220), .(60, 120, 200), 8)));

		images.AddImage("slider::track",
			Hold(RoundedRectImage.Make(32, 6, .(195, 205, 220), .(195, 205, 220, 0), 3)),
			NineSlice(3, 2, 3, 2));
		images.AddImage("slider::fill",
			Hold(RoundedRectImage.Make(32, 6, .(80, 140, 220), .(80, 140, 220, 0), 3)),
			NineSlice(3, 2, 3, 2));
		images.AddImage("slider::thumb",
			Hold(RoundedRectImage.Make(14, 14, .(255, 255, 255), .(140, 165, 200), 7)));

		images.AddImage("progressbar::track",
			Hold(RoundedRectImage.Make(32, 12, .(195, 205, 220), .(195, 205, 220, 0), 4)),
			NineSlice(4, 4, 4, 4));
		images.AddImage("progressbar::fill",
			Hold(RoundedRectImage.Make(32, 12, .(80, 140, 220), .(80, 140, 220, 0), 4)),
			NineSlice(4, 4, 4, 4));

		images.AddImage("toggleswitch::track",
			Hold(RoundedRectImage.Make(44, 24, .(190, 200, 215), .(170, 185, 205), 12)),
			NineSlice(12, 12, 12, 12));
		images.AddImage("toggleswitch::track:checked",
			Hold(RoundedRectImage.Make(44, 24, .(80, 140, 220), .(60, 120, 200), 12)),
			NineSlice(12, 12, 12, 12));
		images.AddImage("toggleswitch::knob",
			Hold(RoundedRectImage.Make(20, 20, .(255, 255, 255), .(210, 215, 225), 10)));

		images.AddStateImages("combobox:Background",
			Hold(RoundedRectImage.Make(48, 28, .(240, 244, 250), .(170, 185, 210), 4)),
			Hold(RoundedRectImage.Make(48, 28, .(230, 238, 248), .(150, 170, 200), 4)),
			null, null, null, NineSlice(6, 6, 6, 6));

		images.AddImage("scrollbar::track",
			Hold(RoundedRectImage.Make(12, 32, .(210, 218, 230, 150), .(210, 218, 230, 0), 3)),
			NineSlice(4, 6, 4, 6));
		images.AddImage("scrollbar::thumb",
			Hold(RoundedRectImage.Make(12, 24, .(150, 170, 200, 200), .(150, 170, 200, 0), 3)),
			NineSlice(4, 6, 4, 6));

		images.AddImage("dialog:Background",
			Hold(RoundedRectImage.Make(64, 64, .(235, 240, 248), .(170, 185, 210), 8)),
			NineSlice(10, 10, 10, 10));
		images.AddImage("tooltip:Background",
			Hold(RoundedRectImage.Make(32, 24, .(255, 255, 225, 245), .(180, 175, 140), 4)),
			NineSlice(6, 6, 6, 6));
		images.AddImage("contextmenu:Background",
			Hold(RoundedRectImage.Make(48, 48, .(240, 244, 250), .(175, 190, 215), 6)),
			NineSlice(8, 8, 8, 8));
		images.AddImage("contextmenu:MenuItemHoverDrawable",
			Hold(RoundedRectImage.Make(32, 24, .(80, 140, 220, 60), .(80, 140, 220, 0), 3)),
			NineSlice(4, 4, 4, 4));

		images.AddImage("tabview::strip",
			Hold(RoundedRectImage.Make(48, 32, .(210, 218, 230), .(210, 218, 230, 0), 0)),
			NineSlice(4, 4, 4, 4));
		images.AddImage("tabview::content",
			Hold(RoundedRectImage.Make(48, 48, .(228, 234, 244), .(228, 234, 244, 0), 0)),
			NineSlice(4, 4, 4, 4));
		images.AddImage("tabview::tab:checked",
			Hold(RoundedRectImage.Make(64, 28, .(240, 244, 250), .(240, 244, 250, 0), 4)),
			NineSlice(6, 6, 6, 4));
		images.AddImage("tabview::tab:hover",
			Hold(RoundedRectImage.Make(64, 28, .(220, 228, 240), .(220, 228, 240, 0), 4)),
			NineSlice(6, 6, 6, 4));

		images.AddImage("expander::header",
			Hold(RoundedRectImage.Make(48, 24, .(215, 222, 235), .(215, 222, 235, 0), 0)),
			NineSlice(4, 4, 4, 4));
		images.AddImage("expander::header:hover",
			Hold(RoundedRectImage.Make(48, 24, .(205, 215, 230), .(205, 215, 230, 0), 0)),
			NineSlice(4, 4, 4, 4));

		// A LIGHT palette, because the skin is light and the text has to read on it.
		return TexturedTheme.Create(images, ThemePalette.Light());
	}

	/// A theme read from a style sheet on disk, which is how a project ships one.
	///
	/// Falls back to the built in dark theme when this checkout carries no assets, so the
	/// sandbox still runs. OWNERSHIP of the sheet transfers.
	public static StyleSheet LoadSheet(IResourceProvider provider, StringView path,
		ThemePalette palette)
	{
		if (provider == null)
			return DarkTheme.Create();

		// Registers the drawable factories and the built in type names, so the sheet's element
		// selectors resolve.
		StyleSheetLoader.InitializeGlobals();

		let loader = scope StyleSheetLoader();
		loader.ResourceProvider = provider;
		loader.SetPalette(palette);

		// The chrome glyphs by name, so the sheet can ask for `svg(checkmark)`.
		loader.RegisterSvg("checkmark", ThemeIcons.Checkmark);
		loader.RegisterSvg("radio-mark-square", ThemeIcons.RadioMarkSquare);
		loader.RegisterSvg("radio-mark-round", ThemeIcons.RadioMarkRound);
		loader.RegisterSvg("close", ThemeIcons.Close);
		loader.RegisterSvg("chevron-down", ThemeIcons.ChevronDown);
		loader.RegisterSvg("chevron-right", ThemeIcons.ChevronRight);
		loader.RegisterSvg("arrow-down", ThemeIcons.ArrowDown);
		loader.RegisterSvg("arrow-up", ThemeIcons.ArrowUp);

		let source = scope String();
		if (!provider.LoadText(path, source) || source.IsEmpty)
			return DarkTheme.Create();

		let sheet = loader.Load(source);
		return (sheet != null) ? sheet : DarkTheme.Create();
	}
}
