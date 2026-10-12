using System;

namespace Sedulous.Editor.Scene;

/// One registered inspectable type: its generated row builder and its labels.
class InspectorEntry
{
	public delegate void(InspectorSection section) Build ~ delete _;
	public String DisplayName = new .() ~ delete _;
	public String Category = new .() ~ delete _;

	/// The section a settings type shows as, on the Scene tab and its profile's page alike: its
	/// label, with a trailing "Settings" dropped from a type that has no label of its own.
	public void SettingsSectionName(String outName)
	{
		outName.Set(DisplayName);
		let suffix = "Settings";
		if ((outName.Length > suffix.Length) && outName.EndsWith(suffix))
		{
			outName.RemoveFromEnd(suffix.Length);
			outName.TrimEnd();
		}
	}
}
