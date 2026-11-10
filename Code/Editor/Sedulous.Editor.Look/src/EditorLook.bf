using System;
using Sedulous.Editor.Look;

namespace Sedulous.Editor.App;

/// An accent Preferences offers: its name and its fill.
struct EditorAccent
{
	public StringView Name;
	public StringView Fill;

	public this(StringView name, StringView fill)
	{
		Name = name;
		Fill = fill;
	}
}

/// The user's appearance inputs (Preferences): the scheme, the accent, the density, less motion
/// and the UI scale. The defaults are the editor's. A class: it owns its text;
/// Set copies another.
class EditorLook
{
	/// The densities the editor's sheets give (Editor/density-<name>.css), in their order.
	public static readonly StringView[3] Densities = .("compact", "default", "comfortable");
	/// The accents Preferences offers, each a fill white text reads on (azure is the editor's).
	/// Any other #rrggbb is taken too.
	public static readonly EditorAccent[4] Accents = .(
		.("Azure", "#2f6fdf"),
		.("Violet", "#6d5bd8"),
		.("Teal", "#0f8a7e"),
		.("Magenta", "#b03d93"));

	public bool Dark = true;
	public String Accent = new .("#2f6fdf") ~ delete _; // azure
	/// compact, default or comfortable: Editor/density-<name>.css.
	public String Density = new .("compact") ~ delete _;
	public bool ReduceMotion = false;
	public float UiScale = 1.0f;

	public void Set(EditorLook other)
	{
		if (other === this)
			return;
		Dark = other.Dark;
		Accent.Set(other.Accent);
		Density.Set(other.Density);
		ReduceMotion = other.ReduceMotion;
		UiScale = other.UiScale;
	}

	/// The look the user's settings ask for (null: none, the defaults); what they leave unset or
	/// name wrongly (a density with no sheet, an accent that is no colour) is the editor's default.
	public void ReadFrom(EditorUiSettings ui)
	{
		Set(scope EditorLook()); // the defaults, then what the settings say over them
		if (ui == null)
			return;
		Dark = ui.Scheme != "light";
		if (IsHexColor(ui.Accent))
			Accent.Set(ui.Accent);
		for (let density in Densities)
		{
			if (density == (StringView)ui.Density)
				Density.Set(density);
		}
		ReduceMotion = ui.ReduceMotion;
		UiScale = Math.Clamp(ui.UiScale, EditorUiSettings.MinUiScale, EditorUiSettings.MaxUiScale);
	}

	/// The look into the user's settings, the section's other fields kept.
	public void StoreInto(EditorUiSettings ui)
	{
		ui.Scheme.Set(Dark ? "dark" : "light");
		ui.Accent.Set(Accent);
		ui.Density.Set(Density);
		ui.ReduceMotion = ReduceMotion;
		ui.UiScale = UiScale;
	}

	/// Whether `text` is a colour as #rrggbb.
	public static bool IsHexColor(StringView text)
	{
		if ((text.Length != 7) || (text[0] != '#'))
			return false;
		for (int i = 1; i < 7; i++)
		{
			let c = text[i];
			if (!(((c >= '0') && (c <= '9')) || ((c >= 'a') && (c <= 'f')) || ((c >= 'A') && (c <= 'F'))))
				return false;
		}
		return true;
	}
}
