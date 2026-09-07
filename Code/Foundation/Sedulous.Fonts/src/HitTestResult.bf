namespace Sedulous.Fonts;

/// Where a point landed in laid out text.
struct HitTestResult
{
	/// The character the point is on.
	public int32 CharacterIndex = 0;
	/// Whether it landed on the TRAILING half of that character.
	public bool IsTrailingHit = false;
	/// Whether the point was within the text at all, as opposed to clamped to it.
	public bool IsInside = false;
	public int32 LineIndex = 0;

	public this() { CharacterIndex = 0; IsTrailingHit = false; IsInside = false; LineIndex = 0; }

	public this(int32 characterIndex, bool trailing, bool inside, int32 lineIndex = 0)
	{
		CharacterIndex = characterIndex; IsTrailingHit = trailing;
		IsInside = inside; LineIndex = lineIndex;
	}

	/// Where a caret goes for this hit: after the character when the click was on its
	/// trailing half, before it otherwise. Clicking the right half of a letter puts the
	/// caret past it, which is what makes click-to-place feel right.
	public int32 InsertionIndex => IsTrailingHit ? (CharacterIndex + 1) : CharacterIndex;
}
