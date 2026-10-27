using System;
using Sedulous.Core.Serialization;
using Sedulous.Settings;

namespace Sedulous.Editor.Core;

/// The editor level UI preferences, a settings section. UiScale multiplies the window's OS
/// content scale for the whole editor UI, layout, fonts and baked icons: an accessibility
/// knob, and the way to exercise the DPI path without a scaled monitor. The look's inputs
/// (Raptor's editor-gui spec, 3.1; rulings 6, 7, 13) sit beside it: the scheme, the accent, the
/// density and less motion.
///
/// The store is XML, so a field added later is [Appended] by its key: a file saved before it
/// reads with the field at its default, and the version stays (a bump would refuse those files).
[Serializable(1)]
class EditorUiSettings
{
	/// The range the slider offers and every clamp reads: 50%, a dense layout on a large
	/// monitor, up to 200%.
	public const float MinUiScale = 0.5f;
	public const float MaxUiScale = 2.0f;

	/// Clamped to [MinUiScale, MaxUiScale] on use.
	public float UiScale = 1.0f;

	/// Snapping a scene view to an axis (its orientation gizmo) turns it orthographic, and
	/// turning away turns it back.
	[Appended]
	public bool AutoOrthographic = true;

	/// "dark" or "light". Added 2026-10-27.
	[Appended]
	public String Scheme = new .("dark") ~ delete _;
	/// A fill white text reads on, as #rrggbb (azure). Added 2026-10-27.
	[Appended]
	public String Accent = new .("#2f6fdf") ~ delete _;
	/// "compact", "default" or "comfortable". Added 2026-10-27.
	[Appended]
	public String Density = new .("compact") ~ delete _;
	/// What moves, still. Added 2026-10-27.
	[Appended]
	public bool ReduceMotion = false;

	/// The user's auto orthographic preference, on when there is no store or no section yet.
	public static bool AutoOrthographicViews(Settings user)
	{
		let ui = (user != null) ? user.Find<EditorUiSettings>() : null;
		return (ui == null) || ui.AutoOrthographic;
	}
}
