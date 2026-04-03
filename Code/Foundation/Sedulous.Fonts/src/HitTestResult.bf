namespace Sedulous.Fonts;

/// Result of a hit test operation on text
public struct HitTestResult
{
	/// Index of the character hit (or nearest character)
	public int32 CharacterIndex;
	/// Whether the hit is on the trailing edge of the character
	/// Used for cursor positioning: trailing edge means cursor goes after this character
	public bool IsTrailingHit;
	/// Whether the hit was inside the text bounds
	public bool IsInside;
	/// The line index for multi-line text (0 for single line)
	public int32 LineIndex;

	public this()
	{
		CharacterIndex = 0;
		IsTrailingHit = false;
		IsInside = false;
		LineIndex = 0;
	}

	public this(int32 charIndex, bool trailing, bool inside, int32 line = 0)
	{
		CharacterIndex = charIndex;
		IsTrailingHit = trailing;
		IsInside = inside;
		LineIndex = line;
	}

	/// Get the caret/insertion position
	/// Returns the index where a new character would be inserted
	public int32 InsertionIndex => IsTrailingHit ? CharacterIndex + 1 : CharacterIndex;
}
