namespace Sedulous.Shell;

/// What the field being typed in holds. A platform's IME composes ordinary text; it stays out of
/// a secret one (a password: no composition, no suggestions, nothing learned from it).
enum TextInputKind : uint8
{
	Text,
	Secret
}
