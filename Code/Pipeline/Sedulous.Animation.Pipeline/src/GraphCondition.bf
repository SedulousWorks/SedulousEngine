using System;

namespace Sedulous.Animation.Pipeline;

/// One transition condition in the edit model.
class GraphCondition
{
	public int32 ParamIndex = -1;
	/// ComparisonOp value.
	public uint8 Op = 0;
	public float Threshold = 0.0f;
}
