namespace Sedulous.Shell;

/// The keyboard as a per frame snapshot.
///
/// Down is "held now"; Pressed and Released are edges within this frame. All three exist
/// because polling only Down cannot tell a fresh press from a key that has been held for
/// a second, which is the difference between a jump and a stuck jump.
interface IKeyboard
{
	bool IsKeyDown(KeyCode key);
	bool IsKeyPressed(KeyCode key);
	bool IsKeyReleased(KeyCode key);
	KeyModifiers Modifiers { get; }
}
