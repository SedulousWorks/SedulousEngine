using System;

namespace Sedulous.Editor.Core;

/// One preference a domain contributes to the Preferences dialog. The get and set closures
/// keep where the value lives, usually the domain's own section of the user settings, the
/// domain's business.
class EditorSettingsBoolField
{
	public String Label = new .() ~ delete _;
	/// The tooltip; empty is none.
	public String Description = new .() ~ delete _;
	public delegate bool() Get ~ delete _;
	public delegate void(bool value) Set ~ delete _;

	public this(StringView label, StringView description, delegate bool() get, delegate void(bool) set)
	{
		Label.Set(label);
		Description.Set(description);
		Get = get;
		Set = set;
	}
}
