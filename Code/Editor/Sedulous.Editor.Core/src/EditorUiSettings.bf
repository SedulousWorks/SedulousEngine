using System;
using Sedulous.Core.Serialization;

namespace Sedulous.Editor.Core;

/// The editor level UI preferences, a settings section. UiScale multiplies the window's OS
/// content scale for the whole editor UI, layout, fonts and baked icons: an accessibility
/// knob, and the way to exercise the DPI path without a scaled monitor.
[Serializable(1)]
class EditorUiSettings
{
	/// Clamped to [1, 2] on use.
	public float UiScale = 1.0f;
}
