using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;
using Sedulous.Editor.Navigation;
using Sedulous.Engine.Physics;
using Sedulous.Engine.Navigation;
using Sedulous.Engine.Script;

namespace Sedulous.Editor.Scene;

/// A component's section: its generated rows, the bespoke rows a few components add, the
/// prefab revert, and the copy and remove actions on its header.
extension SceneInspectorView
{
	private void BuildComponentSection(Guid id, ComponentManagerBase mgr)
	{
		let type = mgr.ComponentType;
		if (type == null)
			return;
		let entry = InspectorRegistry.Find(type);
		let category = scope String();
		if (entry != null)
			category.Set(entry.DisplayName);
		else
			category.Set(mgr.SerializationTypeId.IsEmpty ? "(unreflected component)" : mgr.SerializationTypeId);

		if (entry != null)
		{
			let section = scope InspectorSection(this, new ComponentTarget(mEdit, id, type), category);
			Keep(section.Target);
			entry.Build(section);
		}
		else
		{
			let notice = new NoticeEditor("Inspector", category);
			notice.Message.Set("No inspector is registered for this component type.");
			AddEditor(notice, new () => {});
		}

		let edit = mEdit;
		let editor = mEditor;

		if (type == typeof(RigidBodyComponent))
		{
			let e = edit.Resolve(id);
			let bodies = (RigidBodyComponentManager)mgr;
			let body = e.IsAssigned ? bodies.Get(e) : null;
			if ((body != null) && (body.Shape == .Cooked) && body.CollisionShape.Id.IsNil)
			{
				let notice = new NoticeEditor("Collision", "Physics");
				notice.Message.Set("Shape is Cooked but no collision shape is set - this body has no collider. Assign one (import a mesh with Generate collision, or create a Collision Shape asset).");
				AddEditor(notice, new () => {});
			}
		}

		if (type == typeof(NavMeshZoneComponent))
		{
			let bake = new ButtonEditor("Bake Navigation", new [=edit, =editor, =id]() =>
			{
				BakeZone(edit, editor, id);
			}, category);
			AddEditor(bake, new () => {});
		}

		if (mgr.SerializationTypeId == "script")
			BuildScriptBehaviors(id, category);

		PrefabMemberInfo member = ?;
		if (mgr.IsSerializable && PrefabOverrides.FindMember(edit.Scene, id, out member))
		{
			let revert = new ButtonEditor("Revert to Prefab", new [=edit, =id, =type]() =>
			{
				edit.RevertComponentToBaseline(id, type);
			}, category);
			revert.SetTooltip("Reverts this component to the prefab's values (undoable).");
			revert.SetButtonEnabled(false); // the refresher enables it on an override
			AddEditor(revert, new [=edit, =id, =mgr, =revert]() =>
			{
				PrefabMemberInfo m = ?;
				let overridden = PrefabOverrides.FindMember(edit.Scene, id, out m)
					&& PrefabOverrides.IsComponentOverridden(edit.Scene, m, mgr);
				revert.SetButtonEnabled(overridden);
				revert.SetDisplayName(overridden ? "Revert to Prefab *" : "Revert to Prefab");
			});
		}

		// The header's copy and remove icons.
		let actions = new FlexLayout();
		actions.Direction = .Horizontal;
		actions.Spacing = 2.0f;
		let copyButton = new IconButton(EditorIcons.Copy, 18.0f);
		copyButton.TooltipText.Set("Copy component");
		copyButton.OnClick.Add(new [=edit, =editor, =id, =type](b) =>
		{
			let blob = scope List<uint8>();
			edit.CopyComponent(id, type, blob);
			if (!blob.IsEmpty)
				editor.SetClipboard("component", blob);
		});
		actions.AddView(copyButton);
		let removeButton = new IconButton(EditorIcons.Remove, 18.0f);
		removeButton.TooltipText.Set("Remove component");
		removeButton.OnClick.Add(new [=edit, =id, =type](b) => { edit.RemoveComponent(id, type); });
		actions.AddView(removeButton);
		mGrid.SetCategoryHeaderActions(category, actions);
	}

	/// Bakes a zone's navigation into its assigned asset, with a notice for each way it
	/// cannot.
	private static void BakeZone(SceneEditContext edit, EditorContext editor, Guid id)
	{
		let entity = edit.Resolve(id);
		let zones = edit.Scene.GetSystem<NavMeshZoneComponentManager>();
		let zone = ((zones != null) && entity.IsAssigned) ? zones.Get(entity) : null;
		if (zone == null)
			return;
		if (editor.Project == null)
		{
			editor.Notify(.Error, "No project is open.");
			return;
		}
		let target = zone.Zone.Id.IsNil ? null : editor.Project.SourceDb.GetInstance(zone.Zone.Id);
		if (target == null)
		{
			editor.Notify(.Warning, "Assign a Navigation Zone asset to this zone before baking.");
			return;
		}
		let result = NavigationBake.BakeNavigationZone(edit.Scene, entity, target,
			NavigationEditorPreferences.ParallelBakeEnabled(editor));
		if (result.Baked)
		{
			editor.Notify(.Success, "Navigation baked. Save and cook to apply.");
		}
		else if (result.TriangleCount == 0)
		{
			editor.Notify(.Warning, "No mesh geometry inside the zone box. Check the zone's Extents cover your floor, that the floor entity has a Mesh component, and that the zone is placed over it (only static Mesh geometry is collected).");
		}
		else
		{
			editor.Notify(.Warning, scope $"Collected {result.TriangleCount} triangle(s) but Recast produced no walkable surface. Try a larger Cell Size or a smaller Agent Radius/Height, and check the surface is within Agent Max Slope.");
		}
	}
}
