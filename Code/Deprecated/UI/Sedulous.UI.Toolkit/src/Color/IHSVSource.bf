namespace Sedulous.UI.Toolkit;

/// The state the three interactive colour surfaces read and write.
///
/// It exists because [[ColorPicker]] and [[HDRColorPicker]] are the SAME widget over two value
/// models: one ends at a colour, the other at a colour times an intensity. Their squares and
/// strips are otherwise identical, so they drive this instead of each carrying a copy.
///
/// Implemented EXPLICITLY by both pickers, so hue and saturation stay off their public surface
/// and reachable only through here.
interface IHSVSource
{
	/// Degrees, 0 to 360.
	float Hue { get; set; }
	/// 0 to 1.
	float Saturation { get; set; }
	/// 0 to 1.
	float Value { get; set; }
	/// 0 to 1.
	float Alpha { get; set; }

	/// Called after a surface writes one of the above: the picker rewrites its own controls
	/// and reports the change.
	void OnHSVChangedBySurface();
}
