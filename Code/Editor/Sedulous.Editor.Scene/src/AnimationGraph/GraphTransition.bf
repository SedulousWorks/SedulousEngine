using System;
using System.Collections;

namespace Sedulous.Editor.Scene;

/// One transition in the edit model; a source of -1 is Any State.
class GraphTransition
{
	public int32 Src = -1;
	public int32 Dst = 0;
	public float Duration = 0.25f;
	public bool HasExitTime = false;
	public float ExitTime = 1.0f;
	public int32 Priority = 0;
	public List<GraphCondition> Conditions = new .() ~ DeleteContainerAndItems!(_);
}
