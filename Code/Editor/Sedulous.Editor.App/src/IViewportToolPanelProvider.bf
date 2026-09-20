using System;
using Sedulous.UI;
using Sedulous.Editor.ViewportTools;

namespace Sedulous.Editor.App;

/// A UI-tier settings panel for a viewport tool "mode". A viewport tool is UI-free, so a tool
/// that wants an on-screen settings surface docked beside the viewport (property-animation
/// authoring, a terrain brush, a nav-mesh bake) registers one of these, keyed by its tool's
/// Id, one layer up; the scene page mounts the matching panel whenever the active tool
/// changes. The panel's lifetime is activation-scoped, the view created on activate and
/// dropped on deactivate, so durable edit state lives in the tool or its domain lib, never
/// in the view. Static lifetime: explicit registration, never discovery.
interface IViewportToolPanelProvider
{
	/// The tool this panel belongs to; matches IViewportTool.Id.
	StringView ToolId { get; }
	/// The preferred presentation; the host forwards it to its mount callback.
	ToolPanelPlacement Placement { get; }
	/// Builds the panel view for one host activation, given the active tool (a provider
	/// downcasts it to its concrete tool, the id matched) and the same context the tool got.
	/// Null means this context has nothing to show and the host docks no panel. The caller
	/// owns the returned reference.
	View CreatePanel(IViewportTool tool, in ViewportToolHostContext context);
}
