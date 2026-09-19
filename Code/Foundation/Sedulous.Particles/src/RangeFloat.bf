using Sedulous.Core.Serialization;

using Sedulous.Core;

namespace Sedulous.Particles;

/// A minimum and a maximum, sampled by ONE shared factor.
///
/// One factor rather than one per component, so the pair is a diagonal of the range rather
/// than a box: a spawn between two colours passes through the colours between them, not
/// through every mixture of their channels.
[Scriptable]
struct RangeFloat
{
	[Scriptable]
	public float Min = 0.0f;
	[Scriptable]
	public float Max = 0.0f;

	public this() {}
	public this(float value) { Min = value; Max = value; }
	public this(float min, float max) { Min = min; Max = max; }

	[Scriptable]
	public bool IsConstant => Min == Max;

	public float Evaluate(float t) => Min + (Max - Min) * t;

	public static RangeFloat Constant(float value) => .(value);
	public static RangeFloat Range(float min, float max) => .(min, max);

	/// Describes itself, so a module holding a range picks this up through the generated
	/// body's self serializing escape hatch.
	public void Serialize(ISerializer ar) mut
	{
		SerializeValue(ar, "min", ref Min);
		SerializeValue(ar, "max", ref Max);
	}
}
