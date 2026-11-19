using System;
using Sedulous.Scene;

namespace Sedulous.Editor.Scene;

/// Draws the viewport gizmo for one component type.
interface IGizmoRenderer
{
	Type ComponentType { get; }
	/// `component` is the LIVE component's address in its manager's pool.
	void Draw(void* component, EntityHandle owner, GizmoContext ctx);
	/// Whether the gizmo shows on entities that are not selected: a collider outline does,
	/// a light's range sphere does not.
	bool DrawWhenUnselected { get => false; }
	/// Whether it draws anything at all this frame: off, it is not asked for a single component
	/// (a toggle driven overlay with its toggle off). The default is always on.
	bool IsOn(GizmoContext ctx) => true;
}
