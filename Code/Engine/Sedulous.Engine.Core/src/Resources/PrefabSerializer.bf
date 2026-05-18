namespace Sedulous.Engine.Core.Resources;

using System;
using System.Collections;
using Sedulous.Engine.Core;
using Sedulous.Serialization;
using Sedulous.Resources;
using static Sedulous.Resources.ResourceSerializerExtensions;
using Sedulous.Core.Mathematics;

/// Serializes and deserializes prefabs. Reuses the same entity/component
/// format as SceneSerializer. No module-level data (prefabs are entity
/// subgraphs, not full scenes).
class PrefabSerializer
{
	private ComponentTypeRegistry mTypeRegistry;

	public this(ComponentTypeRegistry typeRegistry)
	{
		mTypeRegistry = typeRegistry;
	}

	/// Serializes a prefab (scene entities) to a serializer.
	public SerializationResult Save(Scene scene, Serializer serializer)
	{
		let entities = scope List<EntityHandle>();
		for (let entity in scene.Entities)
			entities.Add(entity);

		let serializableModules = scope List<SceneModule>();
		for (let module in scene.Modules)
		{
			if (module.IsSerializable)
				serializableModules.Add(module);
		}

		var entityCount = (int32)entities.Count;
		serializer.BeginArray("Entities", ref entityCount);

		for (let entity in entities)
		{
			serializer.BeginObject("");

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
			serializer.EndObject();
		}

		serializer.EndArray();
		return .Ok;
	}

	/// Deserializes a prefab into a scene.
	public SerializationResult Load(Scene scene, Serializer serializer)
	{
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

		// Resolve parent-child relationships
		for (let kv in parentMap)
		{
			let childHandle = scene.FindEntity(kv.key);
			let parentHandle = scene.FindEntity(kv.value);
			if (childHandle.IsAssigned && parentHandle.IsAssigned)
				scene.SetParent(childHandle, parentHandle);
		}

		return .Ok;
	}

	/// Instantiates a prefab's entities into an existing scene under a parent entity.
	/// Returns a map from prefab entity GUIDs to live entity handles.
	public Result<Dictionary<Guid, EntityHandle>> Instantiate(
		Scene scene, EntityHandle parentEntity, Serializer serializer)
	{
		let guidMap = new Dictionary<Guid, EntityHandle>();
		let parentMap = scope Dictionary<Guid, Guid>();

		var entityCount = (int32)0;
		serializer.BeginArray("Entities", ref entityCount);

		for (int32 i = 0; i < entityCount; i++)
		{
			serializer.BeginObject("");

			var sourceId = Guid.Empty;
			serializer.Guid("Id", ref sourceId);

			let name = scope String();
			serializer.String("Name", name);

			var active = true;
			serializer.Bool("Active", ref active);

			var sourceParentId = Guid.Empty;
			serializer.Guid("Parent", ref sourceParentId);

			var transform = Transform.Identity;
			SerializeTransform(serializer, ref transform);

			// Create with a NEW guid (not the prefab's guid)
			let entity = scene.CreateEntity(name);
			scene.SetActive(entity, active);
			scene.SetLocalTransform(entity, transform);
			guidMap[sourceId] = entity;

			if (sourceParentId != .Empty)
				parentMap[sourceId] = sourceParentId;

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

		// Resolve parent-child: root entities -> parentEntity, others -> mapped parent
		for (let kv in guidMap)
		{
			let sourceId = kv.key;
			let liveHandle = kv.value;

			if (parentMap.TryGetValue(sourceId, let sourceParentId))
			{
				if (guidMap.TryGetValue(sourceParentId, let liveParent))
					scene.SetParent(liveHandle, liveParent);
			}
			else
			{
				scene.SetParent(liveHandle, parentEntity);
			}
		}

		return .Ok(guidMap);
	}

	// === Helpers ===

	private SceneModule FindModuleByTypeId(Scene scene, StringView typeId)
	{
		for (let module in scene.Modules)
		{
			if (module.SerializationTypeId == typeId)
				return module;
		}
		return null;
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
