using System;
using Sedulous.Core;
using Sedulous.Editor.Core;
using Sedulous.Editor.Navigation;
using Sedulous.Engine.Physics;
using Sedulous.Engine.Navigation;
using Sedulous.Engine.Animation; // PropertyAnimatorComponent (its Edit Clip)

namespace Sedulous.Editor.Scene;

// The inspector's extras for the engine's own components and settings blocks, registered by type
// into the inspector's registry by
// SceneEditor.Register:
//   - a rigid body whose shape is Cooked with no collision shape set has no collider: said under
//     its header while it is so (it follows an edit, not only a rebuild);
//   - a navigation zone's Bake: the in-zone static geometry baked and written into the zone's
//     asset, the outcome said. It runs at once on the main thread, as the bake's interface is one
//     call; a bake as a job waits for that call to be split (collect here, bake on a worker);
//   - the physics block's collision groups, a source of their own (SettingsExtraSources);
//   - a property animator's Edit Clip: its clip in the page's animation panel, animating its entity
//     (layer 9, part 3).
static class BuiltinInspectorExtras
{
	public const String cNoColliderText = "Shape is Cooked but no collision shape is set - this body has no collider. Assign one (import a mesh with Generate collision, or create a Collision Shape asset).";

	private static bool sRegistered = false;

	/// Registers them once (the registry is the editor's one, a test's host asks again).
	public static void Register()
	{
		if (sRegistered)
			return;
		sRegistered = true;
		InspectorExtrasRegistry.Register(typeof(RigidBodyComponent), new (extras) => { AddNoCollider(extras); });
		InspectorExtrasRegistry.Register(typeof(NavMeshZoneComponent), new (extras) => { AddBake(extras); });
		InspectorExtrasRegistry.Register(typeof(PhysicsSceneSettings), new (extras) => { AddCollisionGroups(extras); });
		InspectorExtrasRegistry.Register(typeof(PropertyAnimatorComponent), new (extras) => { AddEditClip(extras); });
	}

	// The physics block's collision groups (reflection does not show them).
	private static void AddCollisionGroups(InspectorExtras extras)
	{
		let source = new CollisionGroupsSource(extras.Edit);
		extras.AddSection(source, new [=source] () => { source.Refresh(); });
	}

	// An animator's clip in the page's animation panel, animating its entity (no clip: the panel bound
	// to it, to make one).
	private static void AddEditClip(InspectorExtras extras)
	{
		extras.AddAction("Animation", "Edit Clip", "Open the clip in the animation panel under the viewport, animating this entity",
			new [=extras] () =>
			{
				let context = extras.Context;
				let page = (context != null) ? (context.ActivePage as ISceneEditorPage) : null;
				if ((page == null) || extras.Entities.IsEmpty)
					return;
				let edit = extras.Edit;
				let entity = extras.Entities[0];
				let animators = edit.Scene.GetSystem<PropertyAnimatorComponentManager>();
				let handle = edit.Resolve(entity);
				let animator = ((animators != null) && handle.IsAssigned) ? animators.Get(handle) : null;
				page.EditAnimationClip((animator != null) ? animator.Clip.Id : .Empty, entity);
			});
	}

	private static void AddNoCollider(InspectorExtras extras)
	{
		extras.AddNotice("Collision", new [=extras] (outMessage) =>
			{
				let edit = extras.Edit;
				let bodies = edit.Scene.GetSystem<RigidBodyComponentManager>();
				for (let id in extras.Entities)
				{
					let e = edit.Resolve(id);
					let body = ((bodies != null) && e.IsAssigned) ? bodies.Get(e) : null;
					if ((body != null) && (body.Shape == .Cooked) && body.CollisionShape.Id.IsNil)
					{
						outMessage.Set(cNoColliderText);
						return;
					}
				}
			});
	}

	private static void AddBake(InspectorExtras extras)
	{
		extras.AddAction("Navigation", "Bake Navigation",
			"Bake the zone's static geometry (static bodies, terrain) into its Navigation Zone asset; cook to apply it.",
			new [=extras] () =>
			{
				let context = extras.Context;
				let edit = extras.Edit;
				if (context == null)
					return;
				if (context.Project == null)
				{
					context.Notify(.Error, "No project is open.");
					return;
				}
				let zones = edit.Scene.GetSystem<NavMeshZoneComponentManager>();
				for (let id in extras.Entities)
				{
					let entity = edit.Resolve(id);
					let zone = ((zones != null) && entity.IsAssigned) ? zones.Get(entity) : null;
					if (zone == null)
						continue;
					let target = zone.Zone.Id.IsNil ? null : context.Project.SourceDb.GetInstance(zone.Zone.Id);
					if (target == null)
					{
						context.Notify(.Warning, "Assign a Navigation Zone asset to this zone before baking.");
						continue;
					}
					let result = NavigationBake.BakeNavigationZone(edit.Scene, entity, target,
						NavigationEditorPreferences.ParallelBakeEnabled(context));
					context.Notify(result.Baked ? .Success : .Warning, NavigationBake.DescribeBake(result, .. scope .()));
				}
			});
	}
}
