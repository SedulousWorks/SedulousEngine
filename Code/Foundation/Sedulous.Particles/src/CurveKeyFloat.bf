namespace Sedulous.Particles;

struct CurveKeyFloat
{
	public float Time = 0.0f;
	public float Value = 0.0f;
	public float TangentIn = 0.0f;
	public float TangentOut = 0.0f;

	public this() {}

	public this(float time, float value, float tangentIn = 0.0f, float tangentOut = 0.0f)
	{
		Time = time;
		Value = value;
		TangentIn = tangentIn;
		TangentOut = tangentOut;
	}
}
