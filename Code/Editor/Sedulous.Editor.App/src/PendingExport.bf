using System;

namespace Sedulous.Editor.App;

/// An export waiting on its pre-cook: RunExport records it, OnUpdate submits the job once the
/// cook finishes.
class PendingExport
{
	public String PresetName = new .() ~ delete _;
	public bool All = false;
	public bool WaitingCook = false;
	public bool Active = false;
}
