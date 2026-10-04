using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// Every edit the scene editor makes to a scene, as undoable commands over a command stack.
///
/// The scene and the stack are BORROWED: the page owns both and this outlives neither. The
/// entity selection lives here because commands touch it: a destroy deselects the doomed
/// subtree, and a create selects what it made.
///
/// Entities are named by Guid rather than by handle throughout. A handle dies with its
/// entity and a redo recreates the entity under the SAME Guid, so the Guid is the identity
/// that survives an undo cycle; every command re-resolves it on each Execute and Undo.
///
/// The clipboard and prefab verbs live in the extension files alongside.
class SceneEditContext
{
	private Sedulous.Scene.Scene mScene;
	private EditorCommandStack mCommands;
	private ResourceManager mResources = null;
	/// Reaches the payloads of the prefabs a spawned one nests. Owned here; optional.
	private ScenePrefabs.PayloadResolver mPrefabResolver = null ~ delete _;
	private Selection<Guid> mSelection = new .() ~ delete _;

	public this(Sedulous.Scene.Scene scene, EditorCommandStack commands)
	{
		mScene = scene;
		mCommands = commands;
	}

	public Sedulous.Scene.Scene Scene => mScene;
	public EditorCommandStack Commands => mCommands;
	public Selection<Guid> EntitySelection => mSelection;

	/// The manager a restored reference rebinds through. Borrowed; null leaves restored
	/// references unbound until the next load.
	public void SetResources(ResourceManager resources) => mResources = resources;

	/// Re-binds every reference in the scene, so a pasted or undo-restored component renders
	/// this frame rather than after the next load.
	public void ResolveRestoredResources()
	{
		if (mResources != null)
			SceneResolve.ResolveSceneResources(mScene, mResources);
	}

	/// CONSUMES the resolver; the previous one, if any, is deleted.
	public void SetPrefabResolver(ScenePrefabs.PayloadResolver resolver)
	{
		if (mPrefabResolver != resolver)
			delete mPrefabResolver;
		mPrefabResolver = resolver;
	}

	public ScenePrefabs.PayloadResolver PrefabResolver => mPrefabResolver;

	public EntityHandle Resolve(Guid id) => mScene.FindEntity(id);

	// ---- entity verbs ----

	/// Creates an entity under `parent` (nil for a root), selects it and answers its Guid; nil
	/// when the parent is gone.
	public Guid CreateEntity(StringView name, Guid parent = .())
	{
		let command = new CreateEntityCommand(this, name, parent);
		// A create never merges, so the command is on the stack and readable after Execute.
		if (!mCommands.Execute(command))
			return .();
		let created = command.CreatedId;
		mSelection.Set(created);
		return created;
	}

	/// Destroys the whole subtree, deselecting it first. A missing entity is a no-op.
	public void DestroyEntity(Guid entity)
	{
		let root = Resolve(entity);
		if (!root.IsAssigned)
			return;
		mSelection.Remove(entity);
		CollectSubtree(root, scope [&](e) => { mSelection.Remove(mScene.GetEntityId(e)); });
		mCommands.Execute(new DestroyEntityCommand(this, entity));
	}

	/// Renames; consecutive renames of one entity merge into a single undo step.
	public void RenameEntity(Guid entity, StringView newName)
		=> mCommands.Execute(new RenameEntityCommand(this, entity, newName));

	/// Reparents, keeping the world transform. A cycle, a missing parent or a no-op is
	/// refused and leaves the stack untouched.
	public void ReparentEntity(Guid entity, Guid newParent)
		=> mCommands.Execute(new ReparentEntityCommand(this, entity, newParent));

	/// Moves `entity` immediately before `sibling`, or to the end of the root list when the
	/// sibling is nil. An unchanged position is dropped.
	public void MoveEntityBefore(Guid entity, Guid sibling)
		=> mCommands.Execute(new MoveEntityCommand(this, entity, sibling));

	public void SetEntityActive(Guid entity, bool active)
		=> mCommands.Execute(new SetActiveCommand(this, entity, active));

	/// Sets the local transform; consecutive sets on one entity merge, so a gizmo drag is one
	/// undo step.
	public void SetLocalTransform(Guid entity, Transform transform)
		=> mCommands.Execute(new SetTransformCommand(this, entity, transform));

	// ---- component verbs ----

	/// Sets a reflected field of a component. CONSUMES `value`, which must be of the field's
	/// exact type. Consecutive sets of one field merge.
	public void SetComponentProperty(Guid entity, Type componentType, StringView property,
		Variant value)
		=> mCommands.Execute(new SetComponentPropertyCommand(this, entity, componentType,
			property, value));

	/// The typed convenience over the Variant form.
	public void SetComponentProperty<T>(Guid entity, Type componentType, StringView property,
		T value) where T : struct
		=> SetComponentProperty(entity, componentType, property, Variant.Create<T>(value));

	/// Writes a field's raw integer bytes, sized by the field: what an enum picker sets.
	public void SetComponentPropertyRaw(Guid entity, Type componentType, StringView property,
		int64 value)
		=> mCommands.Execute(new SetComponentPropertyCommand(this, entity, componentType,
			property, value));

	/// Points a component's Ref<T> field at another resource and rebinds it.
	public void SetComponentResourceRef<T>(Guid entity, Type componentType, StringView property,
		Guid value, ResourceManager resources) where T : class
		=> mCommands.Execute(new SetResourceRefCommand<T>(this, entity, componentType, property,
			value, resources));

	/// The same for a reference-shaped field known only by its type (an agent's
	/// component_set): no T is named. `resources` is nullable; the reference then binds on the
	/// next resolve.
	public void SetComponentReference(Guid entity, Type componentType, StringView property,
		Guid value, ResourceManager resources)
		=> mCommands.Execute(new SetReferenceCommand(this, entity, componentType, property,
			value, resources));

	/// Sets a component's String field in place; refused when the field holds no string.
	public void SetComponentString(Guid entity, Type componentType, StringView property, StringView text)
		=> mCommands.Execute(new SetComponentStringCommand(this, entity, componentType, property, text));

	/// Points a component's EntityRef field at another entity.
	public void SetComponentEntityRef(Guid entity, Type componentType, StringView property,
		Guid target)
		=> mCommands.Execute(new SetEntityRefCommand(this, entity, componentType, property,
			target));

	/// Adds a default component; dropped when the entity already has one.
	public void AddComponent(Guid entity, Type componentType)
		=> mCommands.Execute(new AddComponentCommand(this, entity, componentType));

	/// Removes a component, remembering it in full so undo brings it back as it was.
	public void RemoveComponent(Guid entity, Type componentType)
		=> mCommands.Execute(new RemoveComponentCommand(this, entity, componentType));

	public ComponentManagerBase FindManager(Type componentType)
		=> mScene.FindManagerByComponentType(componentType);

	// ---- scene settings verbs ----

	/// Sets a reflected field of a system's settings block. CONSUMES `value`. Merges like a
	/// scrub.
	public void SetSceneSettingProperty(Type settingsType, StringView property, Variant value)
		=> mCommands.Execute(new SetSceneSettingCommand(this, settingsType, property, value));

	public void SetSceneSettingProperty<T>(Type settingsType, StringView property, T value)
		where T : struct
		=> SetSceneSettingProperty(settingsType, property, Variant.Create<T>(value));

	public void SetSceneSettingPropertyRaw(Type settingsType, StringView property, int64 value)
		=> mCommands.Execute(new SetSceneSettingCommand(this, settingsType, property, value));

	public void SetSceneSettingResourceRef<T>(Type settingsType, StringView property, Guid value,
		ResourceManager resources) where T : class
		=> mCommands.Execute(new SetSceneSettingRefCommand<T>(this, settingsType, property,
			value, resources));

	/// Replaces a whole settings block from its serialized form, as one undo step. CONSUMES
	/// `newBlob`. What a settings editor that rebuilt the block wholesale applies.
	public bool ApplySceneSettingsBlock(Type settingsType, List<uint8> newBlob)
		=> mCommands.Execute(new SetSceneSettingsBlockCommand(this, settingsType, newBlob));

	public SceneSystem FindSystemBySettingsType(Type settingsType)
	{
		for (let system in mScene.Systems)
		{
			if ((system.SettingsType != null) && (system.SettingsType == settingsType))
				return system;
		}
		return null;
	}

	// ---- a settings block whose source is a profile ----
	// Its values in effect are the profile's, so an edit of a value field lands there, where
	// every scene sharing the profile sees it, and the page persists it to the profile's asset.
	// The block's own fields ([SceneOnly]: the source, the profile reference) stay the scene's.

	/// The page's persistence of a profile edit: an asset edit for the save flow. OWNED.
	public delegate void(Type settingsType, Guid profile) OnSettingsProfileEdited ~ delete _;

	/// The profile an edit of `property` lands in: nil when it lands in the scene's block.
	public Guid SettingsEditProfile(Type settingsType, StringView property)
	{
		let system = FindSystemBySettingsType(settingsType);
		if ((system == null) || (system.SettingsProfileType == null))
			return .();
		if (!(RawFieldAccess.FindField(settingsType, property) case .Ok(let field)))
			return .();
		if (field.GetCustomAttribute<SceneOnlyAttribute>() case .Ok)
			return .();
		return system.SettingsProfile;
	}

	/// The values an edit for `profile` (from SettingsEditProfile) writes: the scene's block for
	/// nil, the profile's values while the block still uses it, else null. An undo after the
	/// source moved on reaches the profile again once that move is undone first.
	public void* SettingsEditTarget(Type settingsType, Guid profile)
	{
		let system = FindSystemBySettingsType(settingsType);
		if (system == null)
			return null;
		if (profile == Guid.Empty)
			return system.SettingsInstance;
		return (system.SettingsProfile == profile) ? system.EffectiveSettingsInstance : null;
	}

	/// The values a row shows and edits now: the scene's block for a [SceneOnly] field, the
	/// values in effect for the rest.
	public void* SettingsValues(Type settingsType, bool sceneOnly)
	{
		let system = FindSystemBySettingsType(settingsType);
		if (system == null)
			return null;
		return sceneOnly ? system.SettingsInstance : system.EffectiveSettingsInstance;
	}

	/// What the settings commands call after they write a profile's values; nil does nothing.
	public void NoteSettingsProfileEdited(Type settingsType, Guid profile)
	{
		if ((profile != Guid.Empty) && (OnSettingsProfileEdited != null))
			OnSettingsProfileEdited(settingsType, profile);
	}

	/// One undoable mutation of a settings block, whatever it touches (its source, a copy of a
	/// profile's values into it): the live block mutated, captured, restored, then applied
	/// through the block command, which keeps the block before. False when there is none.
	public bool MutateSceneSettings(Type settingsType, delegate void(SceneSystem system) mutate)
	{
		let system = FindSystemBySettingsType(settingsType);
		if (system == null)
			return false;
		let before = scope List<uint8>();
		SceneSettingsBlock.Capture(system, before);
		mutate(system);
		let after = new List<uint8>();
		SceneSettingsBlock.Capture(system, after);
		SceneSettingsBlock.Apply(system, before);
		return ApplySceneSettingsBlock(settingsType, after);
	}

	// ---- hierarchy queries ----

	/// Whether `possibleAncestor` is `entity` itself or somewhere above it.
	public bool IsSelfOrAncestor(Guid entity, Guid possibleAncestor)
	{
		let ancestor = Resolve(possibleAncestor);
		if (!ancestor.IsAssigned)
			return false;
		for (var e = Resolve(entity); e.IsAssigned; e = mScene.GetParent(e))
		{
			if (e == ancestor)
				return true;
		}
		return false;
	}

	/// Visits `root` and every descendant, parents before children.
	public void CollectSubtree(EntityHandle root, delegate void(EntityHandle) fn)
	{
		if (!root.IsAssigned)
			return;
		fn(root);
		for (var c = mScene.GetFirstChild(root); c.IsAssigned; c = mScene.GetNextSibling(c))
			CollectSubtree(c, fn);
	}
}
