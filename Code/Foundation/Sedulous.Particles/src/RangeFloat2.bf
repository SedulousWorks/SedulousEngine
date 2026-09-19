using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Particles;

/// A pair of vectors, sampled by ONE shared factor. See RangeFloat.
[Scriptable]
struct RangeFloat2
{
	[Scriptable]
	public Float2 Min = .(0, 0);
	[Scriptable]
	public Float2 Max = .(0, 0);

	public this() {}
	public this(Float2 value) { Min = value; Max = value; }
	public this(Float2 min, Float2 max) { Min = min; Max = max; }

	public Float2 Evaluate(float t) => Min + (Max - Min) * t;

	public static RangeFloat2 Constant(Float2 value) => .(value);

	public void Serialize(ISerializer ar) mut
	{
		SerializeValue(ar, "min", ref Min);
		SerializeValue(ar, "max", ref Max);
	}
}
