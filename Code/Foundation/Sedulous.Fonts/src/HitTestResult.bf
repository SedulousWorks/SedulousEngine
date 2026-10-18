namespace Sedulous.Fonts;

/// Where a point landed in laid out text: the cluster it hit (its first character) and which
/// half, so the caret goes before the cluster or after it (ClusterEnd).
struct HitTestResult
{
	/// The first character of the cluster the point is on.
	public int32 CharacterIndex = 0;
	/// Whether it landed on the TRAILING half of that character.
	public bool IsTrailingHit = false;
	/// Whether the point was within the text at all, as opposed to clamped to it.
	public bool IsInside = false;
	public int32 LineIndex = 0;
	/// The character after the hit cluster.
	public int32 ClusterEnd = 1;

	public this() { CharacterIndex = 0; IsTrailingHit = false; IsInside = false; LineIndex = 0; ClusterEnd = 1; }

	public this(int32 characterIndex, bool trailing, bool inside, int32 lineIndex = 0)
	{
		CharacterIndex = characterIndex; IsTrailingHit = trailing;
		IsInside = inside; LineIndex = lineIndex; ClusterEnd = characterIndex + 1;
	}

	/// A hit on `glyph`'s cluster.
	public static HitTestResult OnCluster(GlyphPosition glyph, bool trailing, bool inside, int32 lineIndex = 0)
	{
		var result = HitTestResult(glyph.Cluster, trailing, inside, lineIndex);
		result.ClusterEnd = glyph.ClusterEnd;
		return result;
	}

	/// Where a caret goes for this hit: after the whole cluster when the click was on its
	/// trailing half, before it otherwise. Clicking the right half of a letter puts the caret
	/// past it, which is what makes click-to-place feel right; on a ligature it goes past every
	/// character the glyph covers.
	public int32 InsertionIndex => IsTrailingHit ? ClusterEnd : CharacterIndex;
}
