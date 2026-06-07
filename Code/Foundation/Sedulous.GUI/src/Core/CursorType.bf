namespace Sedulous.GUI;

/// Cursor appearance when hovering a view. Views set Cursor to change
/// the cursor on hover. EffectiveCursor walks the parent chain to find
/// the first non-Default value.
public enum CursorType
{
	Default,
	Arrow,
	Hand,
	IBeam,
	Crosshair,
	SizeNS,
	SizeWE,
	SizeNWSE,
	SizeNESW,
	Move,
	NotAllowed,
	Wait
}
