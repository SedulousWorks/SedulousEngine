namespace Sedulous.Engine.Core.Resources;

using System;
using System.Collections;
using Sedulous.Engine.Core;
using Sedulous.Serialization;
using Sedulous.Resources;
using static Sedulous.Resources.ResourceSerializerExtensions;
using Sedulous.Core.Mathematics;

/// V2 scene serializer with diff-based prefab instance support.
/// Normal entities are serialized fully (same as SceneSerializer).
/// Prefab instance entities are serialized as diffs against their template.
class SceneSerializer
{
	private ComponentTypeRegistry mTypeRegistry;
	private ISerializerProvider mSerializerProvider;
	private ResourceSystem mResourceSystem;

	public this(ComponentTypeRegistry typeRegistry,
		ISerializerProvider serializerProvider = null,
		ResourceSystem resourceSystem = null)
	{
		mTypeRegistry = typeRegistry;
		mSerializerProvider = serializerProvider;
		mResourceSystem = resourceSystem;
	}

	// ==================== Save ====================

	public SerializationResult Save(Scene scene, Serializer serializer)
	{
		let tagMgr = scene.GetModule<PrefabInstanceTagManager>();
		let localMods = scene.LocalModifications;

		// Partition entities: normal vs prefab instance
		let normalEntities = scope List<EntityHandle>();
		let prefabRoots = scope List<EntityHandle>(); // Instance root entities

		for (let entity in scene.Entities)
		{
			if (tagMgr != null)
			{
				let tag = tagMgr.GetForEntity(entity);
				if (tag != null)
				{
					// Collect unique roots (root's InstanceRoot == its own Owner)
					if (tag.InstanceRoot == tag.Owner)
						prefabRoots.Add(entity);
					continue;
				}
			}

			normalEntities.Add(entity);
		}

		// Collect serializable modules
		let serializableModules = scope List<SceneModule>();
		for (let module in scene.Modules)
		{
			if (module.IsSerializable)
				serializableModules.Add(module);
		}

		// --- Normal entities (full serialization) ---
		SaveNormalEntities(scene, normalEntities, serializableModules, serializer);

		// --- Prefab instances (diff serialization) ---
		SavePrefabInstances(scene, tagMgr, localMods, prefabRoots, serializableModules, serializer);

		// --- Module-level data ---
		SaveModuleData(scene, serializer);

		return .Ok;
	}

	private void SaveNormalEntities(Scene scene, List<EntityHandle> entities,
		List<SceneModule> serializableModules, Serializer serializer)
	{
		var entityCount = (int32)entities.Count;
		serializer.BeginArray("Entities", ref entityCount);

		for (let entity in entities)
		{
			serializer.BeginObject("");
			SaveEntityFull(scene, entity, serializableModules, serializer);
			serializer.EndObject();
		}

		serializer.EndArray();
	}

	private void SaveEntityFull(Scene scene, EntityHandle entity,
		List<SceneModule> serializableModules, Serializer serializer)
	{
		var id = scene.GetEntityId(entity);
		serializer.Guid("Id", ref id);

		let nameView = scene.GetEntityName(entity);
		let name = scope String(nameView);
		serializer.String("Name", name);

		var active = scene.IsActive(entity);
		serializer.Bool("Active", ref active);

		let parentHandle = scene.GetParent(entity);
		var parentId = parentHandle.IsAssigned ? scene.GetEntityId(parentHandle) : Guid.Empty;
		serializer.Guid("Parent", ref parentId);

		var transform = scene.GetLocalTransform(entity);
		SerializeTransform(serializer, ref transform);

		// Components
		var componentCount = (int32)0;
		for (let module in serializableModules)
		{
			if (let cms = module as IComponentManagerSerializer)
			{
				if (cms.HasComponentForEntity(entity))
					componentCount++;
			}
		}

		serializer.BeginArray("Components", ref componentCount);

		for (let module in serializableModules)
		{
			if (let cms = module as IComponentManagerSerializer)
			{
				if (!cms.HasComponentForEntity(entity))
					continue;

				serializer.BeginObject("");

				let typeId = scope String(module.SerializationTypeId);
				serializer.String("TypeId", typeId);

				var version = cms.GetSerializationVersion();
				serializer.Int32("Version", ref version);

				serializer.BeginObject("Data");
				let adapter = scope ComponentSerializerAdapter(serializer, version);
				cms.SerializeEntityComponent(entity, adapter);
				serializer.EndObject();

				serializer.EndObject();
			}
		}

		serializer.EndArray();
	}

	private void SavePrefabInstances(Scene scene, PrefabInstanceTagManager tagMgr,
		LocalModifications localMods, List<EntityHandle> prefabRoots,
		List<SceneModule> serializableModules, Serializer serializer)
	{
		var instanceCount = (int32)prefabRoots.Count;
		serializer.BeginArray("PrefabInstances", ref instanceCount);

		for (let rootEntity in prefabRoots)
		{
			let rootTag = (tagMgr != null) ? tagMgr.GetForEntity(rootEntity) : null;
			if (rootTag == null) continue;

			serializer.BeginObject("");

			// Instance header
			var prefabId = rootTag.PrefabId;
			serializer.Guid("PrefabId", ref prefabId);

			let prefabPath = scope String(rootTag.PrefabPath ?? "");
			serializer.String("PrefabPath", prefabPath);

			// Store only overridden transform fields. If nothing is overridden,
			// the template transform is used on load.
			var rootTransform = scene.GetLocalTransform(rootEntity);
			let rootState = (localMods != null) ? localMods.GetObjectState(rootEntity) : null;
			SerializeTransformDiff(serializer, ref rootTransform, rootState);

			// Collect all entities in this instance (root + children with same PrefabId)
			let instanceEntities = scope List<EntityHandle>();
			CollectInstanceEntities(scene, tagMgr, rootEntity, rootTag.PrefabId, instanceEntities);

			// Write override data for each entity that has modifications
			var overrideEntityCount = (int32)0;
			for (let entity in instanceEntities)
			{
				if (localMods != null && localMods.HasModifications(entity))
					overrideEntityCount++;
			}

			serializer.BeginArray("Overrides", ref overrideEntityCount);

			for (let entity in instanceEntities)
			{
				let state = (localMods != null) ? localMods.GetObjectState(entity) : null;
				if (state == null) continue;

				let tag = tagMgr.GetForEntity(entity);
				if (tag == null) continue;

				serializer.BeginObject("");

				var sourceEntityId = tag.SourceEntityId;
				serializer.Guid("SourceEntityId", ref sourceEntityId);

				// Write only modified component properties
				var overrideComponentCount = (int32)0;
				for (let module in serializableModules)
				{
					if (let cms = module as IComponentManagerSerializer)
					{
						if (cms.HasComponentForEntity(entity) &&
							state.IsPropertyModifiedForComponent(module.SerializationTypeId))
							overrideComponentCount++;
					}
				}

				serializer.BeginArray("Components", ref overrideComponentCount);

				for (let module in serializableModules)
				{
					if (let cms = module as IComponentManagerSerializer)
					{
						if (!cms.HasComponentForEntity(entity))
							continue;
						if (!state.IsPropertyModifiedForComponent(module.SerializationTypeId))
							continue;

						serializer.BeginObject("");

						let typeId = scope String(module.SerializationTypeId);
						serializer.String("TypeId", typeId);

						var version = cms.GetSerializationVersion();
						serializer.Int32("Version", ref version);

						serializer.BeginObject("Data");
						let diffAdapter = scope DiffComponentSerializer(
							serializer, version, module.SerializationTypeId, state);
						cms.SerializeEntityComponent(entity, diffAdapter);
						serializer.EndObject();

						serializer.EndObject();
					}
				}

				serializer.EndArray();
				serializer.EndObject();
			}

			serializer.EndArray();
			serializer.EndObject();
		}

		serializer.EndArray();
	}

	private void CollectInstanceEntities(Scene scene, PrefabInstanceTagManager tagMgr,
		EntityHandle root, Guid prefabId, List<EntityHandle> outEntities)
	{
		outEntities.Add(root);

		// Walk all entities (not just children - tags identify membership)
		for (let entity in scene.Entities)
		{
			if (entity == root) continue;
			let tag = tagMgr.GetForEntity(entity);
			if (tag != null && tag.InstanceRoot == root && tag.PrefabId == prefabId)
				outEntities.Add(entity);
		}
	}

	// ==================== Load ====================

	public SerializationResult Load(Scene scene, Serializer serializer)
	{
		// --- Normal entities ---
		var entityCount = (int32)0;
		serializer.BeginArray("Entities", ref entityCount);

		let parentMap = scope Dictionary<Guid, Guid>();

		for (int32 i = 0; i < entityCount; i++)
		{
			serializer.BeginObject("");

			var id = Guid.Empty;
			serializer.Guid("Id", ref id);

			let name = scope String();
			serializer.String("Name", name);

			var active = true;
			serializer.Bool("Active", ref active);

			var parentId = Guid.Empty;
			serializer.Guid("Parent", ref parentId);

			var transform = Transform.Identity;
			SerializeTransform(serializer, ref transform);

			let entity = scene.CreateEntity(id, name);
			scene.SetActive(entity, active);
			scene.SetLocalTransform(entity, transform);

			if (parentId != .Empty)
				parentMap[id] = parentId;

			// Components
			var componentCount = (int32)0;
			serializer.BeginArray("Components", ref componentCount);

			for (int32 c = 0; c < componentCount; c++)
			{
				serializer.BeginObject("");

				let typeId = scope String();
				serializer.String("TypeId", typeId);

				var version = (int32)1;
				serializer.Int32("Version", ref version);

				SceneModule module = FindModuleByTypeId(scene, typeId);
				if (module == null && mTypeRegistry != null)
				{
					module = mTypeRegistry.CreateManager(typeId);
					if (module != null)
						scene.AddModule(module);
				}

				if (serializer.BeginObject("Data") == .Ok)
				{
					if (module != null)
					{
						if (let cms = module as IComponentManagerSerializer)
						{
							let adapter = scope ComponentSerializerAdapter(serializer, version);
							cms.DeserializeEntityComponent(entity, adapter);
						}
					}
					serializer.EndObject();
				}

				serializer.EndObject();
			}

			serializer.EndArray();
			serializer.EndObject();
		}

		serializer.EndArray();

		// Resolve parent-child for normal entities
		for (let kv in parentMap)
		{
			let childHandle = scene.FindEntity(kv.key);
			let parentHandle = scene.FindEntity(kv.value);
			if (childHandle.IsAssigned && parentHandle.IsAssigned)
				scene.SetParent(childHandle, parentHandle);
		}

		// --- Prefab instances ---
		LoadPrefabInstances(scene, serializer);

		// --- Module-level data ---
		LoadModuleData(scene, serializer);

		return .Ok;
	}

	private void LoadPrefabInstances(Scene scene, Serializer serializer)
	{
		var instanceCount = (int32)0;
		if (serializer.BeginArray("PrefabInstances", ref instanceCount) not case .Ok)
			return; // No prefab instances section - older scene file

		if (mSerializerProvider == null || mResourceSystem == null)
		{
			// Can't load prefab instances without resource system
			serializer.EndArray();
			return;
		}

		for (int32 i = 0; i < instanceCount; i++)
		{
			serializer.BeginObject("");

			var prefabId = Guid.Empty;
			serializer.Guid("PrefabId", ref prefabId);

			let prefabPath = scope String();
			serializer.String("PrefabPath", prefabPath);

			// Load the prefab resource and spawn with template transform
			var prefabRef = ResourceRef(prefabId, prefabPath);
			defer prefabRef.Dispose();

			let spawnResult = PrefabSpawner.Spawn(
				scene, prefabRef, prefabId,
				.Invalid,
				mTypeRegistry, mSerializerProvider, mResourceSystem);

			Dictionary<Guid, EntityHandle> guidMap = null;
			EntityHandle rootEntity = .Invalid;

			if (spawnResult case .Ok(let result))
			{
				guidMap = result.GuidMap;
				rootEntity = result.RootEntity;
			}

			// Apply transform overrides from the scene file on top of the
			// template transform. Only fields present in the file are applied.
			if (rootEntity.IsAssigned)
			{
				var transform = scene.GetLocalTransform(rootEntity);
				LoadTransformDiff(serializer, ref transform, scene, rootEntity);
				scene.SetLocalTransform(rootEntity, transform);
			}

			// Read component overrides and apply them
			var overrideEntityCount = (int32)0;
			serializer.BeginArray("Overrides", ref overrideEntityCount);

			for (int32 oi = 0; oi < overrideEntityCount; oi++)
			{
				serializer.BeginObject("");

				var sourceEntityId = Guid.Empty;
				serializer.Guid("SourceEntityId", ref sourceEntityId);

				// Find the live entity for this source ID
				EntityHandle targetEntity = .Invalid;
				if (guidMap != null)
					guidMap.TryGetValue(sourceEntityId, out targetEntity);

				// Read component overrides
				var componentOverrideCount = (int32)0;
				serializer.BeginArray("Components", ref componentOverrideCount);

				for (int32 ci = 0; ci < componentOverrideCount; ci++)
				{
					serializer.BeginObject("");

					let typeId = scope String();
					serializer.String("TypeId", typeId);

					var version = (int32)1;
					serializer.Int32("Version", ref version);

					if (serializer.BeginObject("Data") == .Ok)
					{
						if (targetEntity.IsAssigned)
						{
							SceneModule module = FindModuleByTypeId(scene, typeId);
							if (module != null)
							{
								if (let cms = module as IComponentManagerSerializer)
								{
									// Apply override values to the existing component.
									// The component was already created by PrefabSpawner with
									// template defaults. The adapter reads from the Data block -
									// fields not present are left unchanged (FieldNotFound = no-op).
									let adapter = scope TrackingComponentSerializer(serializer, version);
									ApplyComponentOverrides(targetEntity, cms, adapter);

									// Register read fields in LocalModifications
									for (let fieldName in adapter.ReadFields)
										scene.LocalModifications.SetPropertyModified(
											targetEntity, typeId, fieldName);
								}
							}
						}
						serializer.EndObject();
					}

					serializer.EndObject();
				}

				serializer.EndArray();
				serializer.EndObject();
			}

			serializer.EndArray();
			serializer.EndObject();

			if (guidMap != null)
				delete guidMap;
		}

		serializer.EndArray();
	}

	/// Applies override values from a serializer to an existing component.
	/// The component was already created by PrefabSpawner with template defaults.
	/// This reads the override data and writes it into the component.
	private void ApplyComponentOverrides(EntityHandle entity,
		IComponentManagerSerializer cms, IComponentSerializer adapter)
	{
		// The adapter is in read mode - calling SerializeEntityComponent with a
		// read-mode adapter would create a new component. Instead, we need to
		// get the existing component and call its Serialize with the reader.
		// SerializeEntityComponent on an existing entity's component writes (in write mode)
		// or reads (in read mode). Since adapter.IsReading = true, this reads
		// override values into the existing component's fields.
		// Note: fields not present in the serializer data are left unchanged
		// (OpenDDL returns FieldNotFound, ref value untouched).
		cms.SerializeEntityComponent(entity, adapter);
	}

	// ==================== Module Data ====================

	private void SaveModuleData(Scene scene, Serializer serializer)
	{
		var moduleDataCount = (int32)0;
		for (let module in scene.Modules)
		{
			if (module.IsSerializable && module is IModuleSerializer)
				moduleDataCount++;
		}

		serializer.BeginArray("Modules", ref moduleDataCount);

		for (let module in scene.Modules)
		{
			if (!module.IsSerializable)
				continue;
			if (let ms = module as IModuleSerializer)
			{
				serializer.BeginObject("");

				let typeId = scope String(module.SerializationTypeId);
				serializer.String("TypeId", typeId);

				var version = ms.GetModuleSerializationVersion();
				serializer.Int32("Version", ref version);

				serializer.BeginObject("Data");
				let adapter = scope ComponentSerializerAdapter(serializer, version);
				ms.SerializeModule(adapter);
				serializer.EndObject();

				serializer.EndObject();
			}
		}

		serializer.EndArray();
	}

	private void LoadModuleData(Scene scene, Serializer serializer)
	{
		var moduleDataCount = (int32)0;
		if (serializer.BeginArray("Modules", ref moduleDataCount) not case .Ok)
			return;

		for (int32 i = 0; i < moduleDataCount; i++)
		{
			serializer.BeginObject("");

			let typeId = scope String();
			serializer.String("TypeId", typeId);

			var version = (int32)1;
			serializer.Int32("Version", ref version);

			SceneModule module = FindModuleByTypeId(scene, typeId);
			if (module == null && mTypeRegistry != null)
			{
				module = mTypeRegistry.CreateManager(typeId);
				if (module != null)
					scene.AddModule(module);
			}

			if (serializer.BeginObject("Data") == .Ok)
			{
				if (module != null)
				{
					if (let ms = module as IModuleSerializer)
					{
						let adapter = scope ComponentSerializerAdapter(serializer, version);
						ms.DeserializeModule(adapter);
					}
				}
				serializer.EndObject();
			}

			serializer.EndObject();
		}

		serializer.EndArray();
	}

	// ==================== Helpers ====================

	private SceneModule FindModuleByTypeId(Scene scene, StringView typeId)
	{
		for (let module in scene.Modules)
		{
			if (module.IsSerializable && module.SerializationTypeId == typeId)
				return module;
		}
		return null;
	}

	/// Writes only the transform fields that are marked as modified in LocalModifications.
	/// Uses the well-known component type "Transform" with property names "Position",
	/// "Rotation", "Scale".
	private void SerializeTransformDiff(Serializer serializer, ref Transform transform, ObjectState state)
	{
		if (state != null && state.IsPropertyModified("Transform", "Position"))
		{
			serializer.BeginObject("Position");
			serializer.Float("X", ref transform.Position.X);
			serializer.Float("Y", ref transform.Position.Y);
			serializer.Float("Z", ref transform.Position.Z);
			serializer.EndObject();
		}

		if (state != null && state.IsPropertyModified("Transform", "Rotation"))
		{
			serializer.BeginObject("Rotation");
			serializer.Float("X", ref transform.Rotation.X);
			serializer.Float("Y", ref transform.Rotation.Y);
			serializer.Float("Z", ref transform.Rotation.Z);
			serializer.Float("W", ref transform.Rotation.W);
			serializer.EndObject();
		}

		if (state != null && state.IsPropertyModified("Transform", "Scale"))
		{
			serializer.BeginObject("Scale");
			serializer.Float("X", ref transform.Scale.X);
			serializer.Float("Y", ref transform.Scale.Y);
			serializer.Float("Z", ref transform.Scale.Z);
			serializer.EndObject();
		}
	}

	/// Reads transform override fields from the serializer and applies them.
	/// Fields not present in the data are left unchanged (template values preserved).
	/// Registers overridden fields in LocalModifications.
	private void LoadTransformDiff(Serializer serializer, ref Transform transform,
		Scene scene, EntityHandle entity)
	{
		if (serializer.BeginObject("Position") == .Ok)
		{
			serializer.Float("X", ref transform.Position.X);
			serializer.Float("Y", ref transform.Position.Y);
			serializer.Float("Z", ref transform.Position.Z);
			serializer.EndObject();
			scene.LocalModifications.SetPropertyModified(entity, "Transform", "Position");
		}

		if (serializer.BeginObject("Rotation") == .Ok)
		{
			serializer.Float("X", ref transform.Rotation.X);
			serializer.Float("Y", ref transform.Rotation.Y);
			serializer.Float("Z", ref transform.Rotation.Z);
			serializer.Float("W", ref transform.Rotation.W);
			serializer.EndObject();
			scene.LocalModifications.SetPropertyModified(entity, "Transform", "Rotation");
		}

		if (serializer.BeginObject("Scale") == .Ok)
		{
			serializer.Float("X", ref transform.Scale.X);
			serializer.Float("Y", ref transform.Scale.Y);
			serializer.Float("Z", ref transform.Scale.Z);
			serializer.EndObject();
			scene.LocalModifications.SetPropertyModified(entity, "Transform", "Scale");
		}
	}

	private void SerializeTransform(Serializer serializer, ref Transform transform)
	{
		serializer.BeginObject("Position");
		serializer.Float("X", ref transform.Position.X);
		serializer.Float("Y", ref transform.Position.Y);
		serializer.Float("Z", ref transform.Position.Z);
		serializer.EndObject();

		serializer.BeginObject("Rotation");
		serializer.Float("X", ref transform.Rotation.X);
		serializer.Float("Y", ref transform.Rotation.Y);
		serializer.Float("Z", ref transform.Rotation.Z);
		serializer.Float("W", ref transform.Rotation.W);
		serializer.EndObject();

		serializer.BeginObject("Scale");
		serializer.Float("X", ref transform.Scale.X);
		serializer.Float("Y", ref transform.Scale.Y);
		serializer.Float("Z", ref transform.Scale.Z);
		serializer.EndObject();
	}
}
