namespace Sedulous.Editor.App;

/// Where the host should present a tool's panel. A hint the provider declares; the host's
/// mount callback decides how to honour each, and may fall back to Dock for one it does not
/// implement. The framework only forwards it, so a page can host the same panel in the
/// bottom dock, a floating palette, or a viewport overlay by routing on this.
enum ToolPanelPlacement : uint8
{
	/// A tab or slot in the editor's docked panel area; the default.
	case Dock;
	/// A floating palette near the viewport.
	case Float;
	/// A HUD-style overlay drawn inside the viewport.
	case ViewportOverlay;
}
