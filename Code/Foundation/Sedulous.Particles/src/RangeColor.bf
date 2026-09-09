using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Particles;

/// A pair of colours, sampled by ONE shared factor. See RangeFloat.
struct RangeColor
{
	public Float4 Min = .(1, 1, 1, 1);
	public Float4 Max = .(1, 1, 1, 1);

	public this() {}
	public this(Float4 value) { Min = value; Max = value; }
	public this(Float4 min, Float4 max) { Min = min; Max = max; }

	public Float4 Evaluate(float t) => Min + (Max - Min) * t;

	public static RangeColor Constant(Float4 value) => .(value);

	public void Serialize(ISerializer ar) mut
	{
		SerializeValue(ar, "min", ref Min);
		SerializeValue(ar, "max", ref Max);
	}
}
