using System;

namespace Sedulous.Editor.Core;

/// The UI's snapshot of the running job; Active false when idle. Main thread only.
class JobProgress
{
	public bool Active = false;
	public String Title = new .() ~ delete _;
	public float Fraction = 0.0f;
	public String Step = new .() ~ delete _;
	public int StepIndex = 0;
	public int StepCount = 0;
}
