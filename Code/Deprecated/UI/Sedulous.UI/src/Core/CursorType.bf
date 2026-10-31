namespace Sedulous.UI;

/// The cursor shown while hovering a view.
///
/// A view sets Cursor to change the cursor over itself; EffectiveCursor walks the parent
/// chain to the first value that is not Default, so a container can dress its whole subtree
/// without every child restating it.
enum CursorType
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
