using System;

namespace Sedulous.Scripting;

/// One parameter of a surface method.
class ScriptParamInfo
{
	public String Name = new .() ~ delete _;
	public String TypeName = new .() ~ delete _;
	/// Passed by reference: `ref`, `out`, or `in`.
	public bool IsByRef = false;
}
