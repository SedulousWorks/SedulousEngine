using System;
using System.Collections;

namespace Sedulous.Editor.Core;

/// A domain's category of preference fields; the Preferences dialog renders every
/// contribution generically, the app hard coding nothing. Bool fields for now; kinds grow as
/// domains need them.
class EditorSettingsContribution
{
	/// Its Preferences tab, "Navigation"; one tab per category, shared by contributions naming it.
	public String Category = new .() ~ delete _;
	public List<EditorSettingsBoolField> Bools = new .() ~ DeleteContainerAndItems!(_);

	public this(StringView category)
	{
		Category.Set(category);
	}
}
