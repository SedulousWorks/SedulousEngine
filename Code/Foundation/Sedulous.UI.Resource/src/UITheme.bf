using System;
using System.Collections;

namespace Sedulous.UI.Resource;

/// A loaded UI theme: the style sheet text a context parses and applies, and the icons the
/// sheet names.
///
/// The TEXT rather than a parsed sheet, because parsing needs a palette bound and the palette
/// is the application's choice: one cooked theme serves every variant of itself.
class UITheme
{
	public String StyleSheet = new .() ~ delete _;
	/// Parallel: an icon reference as the sheet writes it (`"{guid}"`), and its SVG.
	public List<String> IconIds = new .() ~ DeleteContainerAndItems!(_);
	public List<String> IconSvgs = new .() ~ DeleteContainerAndItems!(_);

	/// The SVG an icon reference stands for; false if the theme carries none by it.
	public bool FindIcon(StringView id, out StringView svg)
	{
		for (int i < IconIds.Count)
		{
			if (IconIds[i] == id)
			{
				svg = IconSvgs[i];
				return true;
			}
		}
		svg = default;
		return false;
	}
}
