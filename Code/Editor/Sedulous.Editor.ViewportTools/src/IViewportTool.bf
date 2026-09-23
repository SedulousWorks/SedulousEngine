using System;
using Sedulous.Render;

namespace Sedulous.Editor.ViewportTools;

/// A modal interaction mode of a 3D viewport: select plus gizmos is the default tool, terrain
/// sculpting and splat painting are modal tools, so the viewport has one input-routing path.
/// Implementations live in domain editor libs, or the hosting page for its default tool, and
/// are owned by a ViewportToolManager. Mutation goes through EditorCommandStack commands only.
interface IViewportTool
{
	/// Stable identifier ("select", "terrain.sculpt"): palette state, tests, settings keys.
	StringView Id { get; }
	/// Palette label.
	StringView DisplayName { get; }
	/// Registration is unconditional, relevance is contextual (a terrain brush needs a
	/// terrain). Checked every frame for the active tool; the manager falls back to the
	/// default tool when it turns false.
	bool IsAvailable { get; }
	/// Why IsAvailable is false, for the person who has just clicked the tool: the host says
	/// it as a notice when it refuses the activation, a toggle that silently snaps back
	/// reading as a dead button. One sentence naming what the scene lacks.
	StringView UnavailableReason => "This tool has nothing to work on in this scene.";
	void OnActivate();
	/// Must end any in-flight gesture so no half-applied command group survives a switch;
	/// the manager calls it before another tool activates.
	void OnDeactivate();
	/// One frame. True when the tool consumed the pointer (hot handle or active gesture), so
	/// the host suppresses its default click behaviour.
	bool Update(in ViewportToolInput input);
	/// Overlay drawing into the host viewport's debug-draw list, every frame for the active
	/// tool only.
	void Draw(DebugDraw drawList);
	/// One-line status readout for the viewport corner; empty for nothing.
	StringView StatusText { get; }
}
