namespace Sedulous.Core;

/// One keyframe.
///
/// TangentIn and TangentOut are slopes in Value units per Time unit, and matter only for
/// Cubic segments: in is arriving at this key from the previous segment, out is leaving
/// toward the next. Constant and Linear ignore them.
struct CurveKey
{
	public float Time = 0.0f;
	public float Value = 0.0f;
	public float TangentIn = 0.0f;
	public float TangentOut = 0.0f;
	public CurveKeyInterpolation Interpolation = .Linear;

	public this() { }

	public this(float time, float value,
		CurveKeyInterpolation interpolation = .Linear,
		float tangentIn = 0.0f, float tangentOut = 0.0f)
	{
		this.Time = time;
		this.Value = value;
		this.Interpolation = interpolation;
		this.TangentIn = tangentIn;
		this.TangentOut = tangentOut;
	}
}
