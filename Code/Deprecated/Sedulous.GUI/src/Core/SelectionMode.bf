namespace Sedulous.GUI;

/// Selection behavior for list controls.
public enum SelectionMode
{
	/// Only one item can be selected at a time.
	Single,
	/// Multiple items can be selected by clicking (no modifier key needed).
	Multiple,
	/// Multiple items can be selected via Ctrl+click (toggle) and Shift+click (range).
	Extended
}
