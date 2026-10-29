using System;
using Sedulous.GUI;
using Sedulous.Editor.ViewportTools;

namespace Sedulous.Editor.App;

/// A UI-tier settings panel for a viewport tool "mode". A viewport tool is UI-free, so a tool
/// that wants an on-screen settings surface while it is active (a terrain brush's panel)
/// registers one of these, keyed by its tool's Id, one layer up; the scene page mounts the
/// matching panel whenever the active tool changes, in its one place, the HUD's tool panel
/// (Raptor's editor-gui spec, ruling 23; the dock and overlay placements it had were never
/// used). The panel's lifetime is activation-scoped, the node created on activate and dropped
/// on deactivate, so durable edit state lives in the tool or its domain lib, never in the node.
/// Static lifetime: explicit registration, never discovery.
interface IViewportToolPanelProvider
{
	/// The tool this panel belongs to; matches IViewportTool.Id.
	StringView ToolId { get; }
	/// Builds the panel's body for one host activation (the host gives it its chrome: the tool's
	/// name, a fold and a close), given the active tool (a provider downcasts it to its concrete
	/// tool, the id matched) and the same context the tool got. Null means this context has
	/// nothing to show and the host shows no panel. The caller owns the returned reference.
	Node CreatePanel(IViewportTool tool, in ViewportToolHostContext context);
}
