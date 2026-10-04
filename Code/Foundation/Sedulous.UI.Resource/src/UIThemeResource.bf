using System;
using System.Collections;
using Sedulous.Core.Serialization;

namespace Sedulous.UI.Resource;

/// The cooked form of a UI theme: a validated style sheet payload, and the icons it names.
///
/// An icon is an SVG the sheet names with `@icon name "{guid}"` (a vector image asset),
/// embedded so the sheet parses on its own with nothing else to wait for, and `svg(name)` draws
/// it. Parallel lists, the serializer's flat form: `IconIds[i]` is the reference exactly as
/// the sheet writes it, `IconSvgs[i]` the document.
[Serializable(2)]
class UIThemeResource
{
	public String StyleSheet = new .() ~ delete _;
	public List<String> IconIds = new .() ~ DeleteContainerAndItems!(_);
	public List<String> IconSvgs = new .() ~ DeleteContainerAndItems!(_);
}
