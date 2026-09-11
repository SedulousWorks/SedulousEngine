using System;

namespace Sedulous.UI.Resource;

/// A loaded UI theme: the style sheet text a context parses and applies.
///
/// The TEXT rather than a parsed sheet, because parsing needs a palette bound and the palette
/// is the application's choice: one cooked theme serves every variant of itself.
class UITheme
{
	public String StyleSheet = new .() ~ delete _;
}
