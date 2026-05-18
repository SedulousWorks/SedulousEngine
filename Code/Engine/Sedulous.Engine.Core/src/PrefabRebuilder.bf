namespace Sedulous.Engine.Core;

using System;
using System.Collections;
using Sedulous.Resources;
using Sedulous.Serialization;
using Sedulous.Engine.Core.Resources;
using Sedulous.Core.Mathematics;

/// Rebuilds prefab instances in a scene when the template changes.
/// Caches per-instance overrides, destroys old entities, respawns from
/// the updated template, and re-applies the cached overrides.
static class PrefabRebuilder
{
	/// Cached override data for a single entity within a prefab instance.
	private struct EntityOverride : IDisposable
	{
		public Guid SourceEntityId;
		public List<PropertyOverride> Properties;

		public void Dispose() mut
		{
			if (Properties != null)
			{
				for (var p in Properties) p.Dispose();
				delete Properties;
				Properties = null;
			}
		}
	}

	/// A single property override: component type + serialized data.
	private struct PropertyOverride : IDisposable
	{
		public String ComponentTypeId;
		public String SerializedData;

		public void Dispose() mut
		{
			delete ComponentTypeId;
			delete SerializedData;
		}
	}

	/// Rebuilds all instances of a prefab in the given scene.
	/// Called when a .prefab resource is hot-reloaded.
	public static void Rebuild(Scene scene, Guid prefabId,
		ResourceRef prefabRef,
		ComponentTypeRegistry typeRegistry,
		ISerializerProvider serializerProvider,
		ResourceSystem resourceSystem)
	{
		let tagMgr = scene.GetModule<PrefabInstanceTagManager>();
		if (tagMgr == null) return;

		// Find all instance roots for this prefab
		let instanceRoots = scope List<EntityHandle>();
		for (let entity in scene.Entities)
		{
			let tag = tagMgr.GetForEntity(entity);
			if (tag != null && tag.PrefabId == prefabId && tag.InstanceRoot == tag.Owner)
				instanceRoots.Add(entity);
		}

		if (instanceRoots.Count == 0) return;

		// Rebuild each instance
		for (let rootEntity in instanceRoots)
			RebuildInstance(scene, rootEntity, prefabId, prefabRef,
				tagMgr, typeRegistry, serializerProvider, resourceSystem);
	}

	private static void RebuildInstance(Scene scene, EntityHandle rootEntity, Guid prefabId,
		ResourceRef prefabRef, PrefabInstanceTagManager tagMgr,
		ComponentTypeRegistry typeRegistry, ISerializerProvider serializerProvider,
		ResourceSystem resourceSystem)
	{
		let localMods = scene.LocalModifications;

		// 1. Collect all entities in this instance
		let instanceEntities = scope List<EntityHandle>();
		instanceEntities.Add(rootEntity);
		for (let entity in scene.Entities)
		{
			if (entity == rootEntity) continue;
			let tag = tagMgr.GetForEntity(entity);
			if (tag != null && tag.InstanceRoot == rootEntity && tag.PrefabId == prefabId)
				instanceEntities.Add(entity);
		}

		// 2. Cache the root transform and which fields are overridden
		let rootTransform = scene.GetLocalTransform(rootEntity);
		let rootState = localMods.GetObjectState(rootEntity);
		let posOverridden = rootState != null && rootState.IsPropertyModified("Transform", "Position");
		let rotOverridden = rootState != null && rootState.IsPropertyModified("Transform", "Rotation");
		let scaleOverridden = rootState != null && rootState.IsPropertyModified("Transform", "Scale");

		// 3. Cache overrides from LocalModifications
		let cachedOverrides = scope List<EntityOverride>();
		defer { for (var ov in cachedOverrides) ov.Dispose(); }

		for (let entity in instanceEntities)
		{
			let state = localMods.GetObjectState(entity);
			if (state == null) continue;

			let tag = tagMgr.GetForEntity(entity);
			if (tag == null) continue;

			var entityOverride = EntityOverride();
			entityOverride.SourceEntityId = tag.SourceEntityId;
			entityOverride.Properties = new List<PropertyOverride>();

			// For each modified component, serialize the current values
			for (let module in scene.Modules)
			{
				if (!module.IsSerializable) continue;
				if (!state.IsPropertyModifiedForComponent(module.SerializationTypeId)) continue;

				if (let cms = module as IComponentManagerSerializer)
				{
					if (!cms.HasComponentForEntity(entity)) continue;

					// Serialize the modified properties to a string buffer
					let writer = serializerProvider.CreateWriter();
					if (writer == null) continue;

					let diffAdapter = scope DiffComponentSerializer(
						writer, cms.GetSerializationVersion(), module.SerializationTypeId, state);
					cms.SerializeEntityComponent(entity, diffAdapter);

					let output = scope String();
					serializerProvider.GetOutput(writer, output);

					var propOverride = PropertyOverride();
					propOverride.ComponentTypeId = new String(module.SerializationTypeId);
					propOverride.SerializedData = new String(output);
					entityOverride.Properties.Add(propOverride);

					delete writer;
				}
			}

			cachedOverrides.Add(entityOverride);
		}

		// 4. Cache which properties were modified (for restoring LocalModifications)
		let cachedModifications = scope List<(Guid sourceId, List<PropertyPath> paths)>();
		defer {
			for (var entry in cachedModifications)
			{
				for (var p in entry.paths) p.Dispose();
				delete entry.paths;
			}
		}

		for (let entity in instanceEntities)
		{
			let state = localMods.GetObjectState(entity);
			if (state == null) continue;
			let tag = tagMgr.GetForEntity(entity);
			if (tag == null) continue;

			let paths = new List<PropertyPath>();
			for (let path in state.ModifiedProperties)
				paths.Add(PropertyPath.Create(path.ComponentTypeId, path.PropertyName));

			cachedModifications.Add((tag.SourceEntityId, paths));
		}

		// 5. Get parent of root (to restore hierarchy position)
		let rootParent = scene.GetParent(rootEntity);

		// 6. Destroy all instance entities
		for (let entity in instanceEntities)
		{
			if (scene.IsValid(entity))
				scene.DestroyEntity(entity);
		}

		// 7. Respawn from updated template
		let spawnResult = PrefabSpawner.Spawn(scene, prefabRef, prefabId,
			rootParent, typeRegistry, serializerProvider, resourceSystem);

		if (spawnResult case .Err)
		{
			Console.WriteLine("[PrefabRebuilder] Respawn FAILED");
			return;
		}

		let sr = spawnResult.Value;
		defer delete sr.GuidMap;

		// Restore only overridden transform fields. Non-overridden fields
		// keep the new template values from the respawn.
		if (sr.RootEntity.IsAssigned && (posOverridden || rotOverridden || scaleOverridden))
		{
			var newTransform = scene.GetLocalTransform(sr.RootEntity);
			if (posOverridden) newTransform.Position = rootTransform.Position;
			if (rotOverridden) newTransform.Rotation = rootTransform.Rotation;
			if (scaleOverridden) newTransform.Scale = rootTransform.Scale;
			scene.SetLocalTransform(sr.RootEntity, newTransform);
		}

		// 8. Re-apply cached overrides
		for (let entityOverride in cachedOverrides)
		{
			EntityHandle targetEntity = .Invalid;
			if (!sr.GuidMap.TryGetValue(entityOverride.SourceEntityId, out targetEntity))
				continue;

			for (let propOverride in entityOverride.Properties)
			{
				// Find the component manager
				SceneModule module = null;
				for (let m in scene.Modules)
				{
					if (m.IsSerializable && m.SerializationTypeId == propOverride.ComponentTypeId)
					{
						module = m;
						break;
					}
				}
				if (module == null) continue;

				if (let cms = module as IComponentManagerSerializer)
				{
					// Apply the cached override data
					let reader = serializerProvider.CreateReader(propOverride.SerializedData);
					if (reader == null) continue;
					defer delete reader;

					cms.SerializeEntityComponent(targetEntity, scope ComponentSerializerAdapter(reader, cms.GetSerializationVersion()));
				}
			}
		}

		// 9. Restore LocalModifications
		for (let entry in cachedModifications)
		{
			EntityHandle targetEntity = .Invalid;
			if (!sr.GuidMap.TryGetValue(entry.sourceId, out targetEntity))
				continue;

			for (let path in entry.paths)
				localMods.SetPropertyModified(targetEntity, path.ComponentTypeId, path.PropertyName);
		}
	}
}
