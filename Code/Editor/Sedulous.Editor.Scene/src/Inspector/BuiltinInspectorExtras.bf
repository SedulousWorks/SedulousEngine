using System;
using Sedulous.Core;
using Sedulous.Editor.Core;
using Sedulous.Editor.Navigation;
using Sedulous.Engine.Physics;
using Sedulous.Engine.Navigation;
using Sedulous.Engine.Script;

namespace Sedulous.Editor.Scene;

// The inspector's extras for the engine's own components and settings blocks (Raptor's editor-gui
// spec, 5.3, layer 4, parts 3 and 4), registered by type into the inspector's registry by
// SceneEditor.Register:
//   - a rigid body whose shape is Cooked with no collision shape set has no collider: said under
//     its header while it is so (it follows an edit, not only a rebuild);
//   - a script component's behaviours, a source of their own (ScriptBehaviorsSource);
//   - a navigation zone's Bake: the in-zone static geometry baked and written into the zone's
//     asset, the outcome said. It runs at once on the main thread, as the bake's interface is one
//     call; a bake as a job waits for that call to be split (collect here, bake on a worker);
//   - the physics block's collision groups and the scene script block's level properties, sources
//     of their own (SettingsExtraSources).
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
		InspectorExtrasRegistry.Register(typeof(ScriptComponent), new (extras) => { AddBehaviors(extras); });
		InspectorExtrasRegistry.Register(typeof(PhysicsSceneSettings), new (extras) => { AddCollisionGroups(extras); });
		InspectorExtrasRegistry.Register(typeof(SceneScriptSettings), new (extras) => { AddLevelProperties(extras); });
	}

	// A script component's behaviours: a source of their own (reflection does not show them).
	private static void AddBehaviors(InspectorExtras extras)
	{
		let source = new ScriptBehaviorsSource(extras.Edit, extras.Context, extras.Entities);
		extras.AddSection(source, new [=source] () => { source.Refresh(); });
	}

	// The physics block's collision groups (reflection does not show them).
	private static void AddCollisionGroups(InspectorExtras extras)
	{
		let source = new CollisionGroupsSource(extras.Edit);
		extras.AddSection(source, new [=source] () => { source.Refresh(); });
	}

	// The scene script block's Level class's properties (its overrides are not reflected).
	private static void AddLevelProperties(InspectorExtras extras)
	{
		let source = new LevelScriptSource(extras.Edit, extras.Context);
		extras.AddSection(source, new [=source] () => { source.Refresh(); });
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
