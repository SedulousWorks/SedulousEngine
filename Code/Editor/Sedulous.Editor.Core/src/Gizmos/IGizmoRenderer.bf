namespace Sedulous.Editor.Core;

using System;
using Sedulous.Engine.Core;

/// 3D viewport gizmo for a specific component type.
/// Plugins register these with EditorContext.RegisterGizmoRenderer().
interface IGizmoRenderer : IDisposable
{
	/// The component type this gizmo renders for.
	Type ComponentType { get; }

	/// Draw the gizmo for the given component.
	void Draw(Component component, GizmoContext ctx);

	/// Whether to draw this gizmo for unselected entities.
	bool DrawWhenUnselected { get; }
}
