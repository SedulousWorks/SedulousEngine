namespace Sedulous.UI;

/// One grid track's sizing: a mode, and the number that mode reads.
struct TrackSize
{
	public TrackSizeMode Mode = .Auto;
	/// The size for Fixed, the weight for Flex, and unused for Auto.
	public float Value = 0.0f;

	public this() {}

	public this(TrackSizeMode mode, float value)
	{
		Mode = mode;
		Value = value;
	}

	public static TrackSize Auto() => .(.Auto, 0.0f);
	public static TrackSize Fixed(float size) => .(.Fixed, size);
	public static TrackSize Flex(float weight = 1.0f) => .(.Flex, weight);
}
