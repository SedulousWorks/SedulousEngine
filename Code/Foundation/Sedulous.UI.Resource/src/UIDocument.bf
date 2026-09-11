using System;

namespace Sedulous.UI.Resource;

/// A loaded UI document: the markup a canvas instantiates from.
///
/// Documents are TEMPLATES and never shared as live trees. A canvas binding one builds its
/// own view tree from the markup, so two canvases showing the same document do not share
/// state and cannot disturb one another.
class UIDocument
{
	public String Markup = new .() ~ delete _;
}
