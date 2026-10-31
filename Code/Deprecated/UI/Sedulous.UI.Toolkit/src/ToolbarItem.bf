using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// The base for anything in a [[Toolbar]].
///
/// It adds nothing to View. It exists so a toolbar's own controls are one family a theme can
/// target, while AddItem still accepts any view at all.
class ToolbarItem : View
{
}
