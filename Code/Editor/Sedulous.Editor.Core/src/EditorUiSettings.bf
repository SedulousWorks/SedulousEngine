using System;
using Sedulous.Core.Serialization;
using Sedulous.Settings;

namespace Sedulous.Editor.Core;

/// The editor level UI preferences, a settings section. UiScale multiplies the window's OS
/// content scale for the whole editor UI, layout, fonts and baked icons: an accessibility
/// knob, and the way to exercise the DPI path without a scaled monitor.
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

	/// The user's auto orthographic preference, on when there is no store or no section yet.
	public static bool AutoOrthographicViews(Settings user)
	{
		let ui = (user != null) ? user.Find<EditorUiSettings>() : null;
		return (ui == null) || ui.AutoOrthographic;
	}
}
