namespace Sedulous.UI;

/// Cursor appearance types. Views set Cursor to change the cursor
/// when hovered. EffectiveCursor walks the parent chain.
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
