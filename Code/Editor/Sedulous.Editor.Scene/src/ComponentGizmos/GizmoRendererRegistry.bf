using System;
using System.Collections;
using Sedulous.Scene;

namespace Sedulous.Editor.Scene;

/// The gizmo renderers by component type. OWNS them.
class GizmoRendererRegistry
{
	private List<IGizmoRenderer> mRenderers = new .() ~ DeleteContainerAndItems!(_);

	public int Count => mRenderers.Count;

	/// CONSUMES the renderer.
	public void Register(IGizmoRenderer renderer)
	{
		if (renderer != null)
			mRenderers.Add(renderer);
	}

	public IGizmoRenderer Find(Type componentType)
	{
		for (let r in mRenderers)
		{
			if (r.ComponentType == componentType)
				return r;
		}
		return null;
	}

	/// Draws every gizmo the entity's components have, honouring each renderer's unselected
	/// gate.
	public void DrawEntity(EntityHandle entity, bool selected, GizmoContext ctx)
	{
		if ((ctx.Scene == null) || (ctx.Debug == null) || !entity.IsAssigned)
			return;
		ctx.EntityEffectivelyActive = ctx.Scene.IsEffectivelyActive(entity);
		ctx.Scene.ForEachManager(scope [&](mgr) =>
		{
			if (!mgr.HasComponent(entity))
				return;
			let renderer = Find(mgr.ComponentType);
			if (renderer == null)
				return;
			if (!selected && !renderer.DrawWhenUnselected)
				return;
			let component = mgr.GetComponentAddress(entity);
			if (component != null)
				renderer.Draw(component, entity, ctx);
		});
	}
}
