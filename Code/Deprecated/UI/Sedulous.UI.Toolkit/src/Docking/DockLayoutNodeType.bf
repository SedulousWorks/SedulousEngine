namespace Sedulous.UI.Toolkit;

/// What a node in a saved dock layout describes.
enum DockLayoutNodeType
{
	/// Two children and a divider between them.
	Split,
	/// One or more panels sharing a tab strip.
	TabGroup
}
