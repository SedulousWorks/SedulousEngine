namespace Sedulous.Core;

/// One keyframe.
///
/// tangentIn and tangentOut are slopes in value units per time unit, and matter only for
/// Cubic segments: in is arriving at this key from the previous segment, out is leaving
/// toward the next. Constant and Linear ignore them.
struct CurveKey
{
	public float time = 0.0f;
	public float value = 0.0f;
	public float tangentIn = 0.0f;
	public float tangentOut = 0.0f;
	public CurveKeyInterpolation interpolation = .Linear;

	public this() { }

	public this(float time, float value,
		CurveKeyInterpolation interpolation = .Linear,
		float tangentIn = 0.0f, float tangentOut = 0.0f)
	{
		this.time = time;
		this.value = value;
		this.interpolation = interpolation;
		this.tangentIn = tangentIn;
		this.tangentOut = tangentOut;
	}
}
