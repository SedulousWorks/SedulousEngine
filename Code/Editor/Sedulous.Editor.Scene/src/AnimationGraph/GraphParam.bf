using System;

namespace Sedulous.Editor.Scene;

/// One graph parameter in the edit model: its name, type and authored default.
class GraphParam
{
	public String Name = new .() ~ delete _;
	/// AnimationParameterType: 0 float, 1 int, 2 bool, 3 trigger.
	public uint8 Type = 0;
	public float FloatValue = 0.0f;
	public int32 IntValue = 0;
	public bool BoolValue = false;
}
