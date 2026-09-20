using System;

namespace Sedulous.Editor.Scene;

/// One registered inspectable type: its generated row builder and its labels.
class InspectorEntry
{
	public delegate void(InspectorSection section) Build ~ delete _;
	public String DisplayName = new .() ~ delete _;
	public String Category = new .() ~ delete _;
}
