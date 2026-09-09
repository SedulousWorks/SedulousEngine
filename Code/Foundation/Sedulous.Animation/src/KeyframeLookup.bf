namespace Sedulous.Animation;

/// The pair of keyframes a sample time falls between, and how far along it sits.
struct KeyframeLookup
{
	public int32 Prev = -1;
	public int32 Next = -1;
	public float T = 0.0f;

	public this() {}

	public this(int32 prev, int32 next, float t)
	{
		Prev = prev;
		Next = next;
		T = t;
	}

	public bool IsValid => Prev >= 0;
}
