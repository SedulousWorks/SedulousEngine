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

	/// Draws a scene's gizmos: every component's of the `selected` entities (by id), then, for
	/// the rest, each renderer that draws unselected and is on, over its own component's owners
	/// only. What it costs follows what is drawn, not every entity times every component type:
	/// a scene of forty thousand meshes with no overlay on costs nothing.
	public void DrawScene(Sedulous.Scene.Scene scene, Span<Guid> selected, GizmoContext ctx)
	{
		if ((scene == null) || (ctx.Debug == null))
			return;
		ctx.Scene = scene;
		// The selection: every component's gizmo, as DrawEntity draws one entity.
		for (let id in selected)
		{
			let entity = scene.FindEntity(id);
			if (entity.IsAssigned)
				DrawEntity(entity, true, ctx);
		}
		// The rest: only the renderers that draw unselected and are on, each over the owners of
		// its own component.
		HashSet<Guid> chosen = null;
		defer { delete chosen; }
		for (let renderer in mRenderers)
		{
			if (!renderer.DrawWhenUnselected || !renderer.IsOn(ctx))
				continue;
			let manager = scene.FindManagerByComponentType(renderer.ComponentType);
			if (manager == null)
				continue;
			if (chosen == null)
			{
				chosen = new .();
				for (let id in selected)
					chosen.Add(id);
			}
			for (let owner in manager.OwnerHandles)
			{
				// The raw pool holds components leaving this frame too: they are passed by.
				if (!manager.HasComponent(owner) || chosen.Contains(scene.GetEntityId(owner)))
					continue;
				let component = manager.GetComponentAddress(owner);
				if (component != null)
				{
					ctx.EntityEffectivelyActive = scene.IsEffectivelyActive(owner);
					renderer.Draw(component, owner, ctx);
				}
			}
		}
	}
}
