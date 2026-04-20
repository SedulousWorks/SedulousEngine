namespace Sedulous.Scenes.Resources;

using System;
using System.Collections;
using Sedulous.Scenes;
using Sedulous.Serialization;
using Sedulous.Resources;
using static Sedulous.Resources.ResourceSerializerExtensions;
using Sedulous.Core.Mathematics;

/// Serializes and deserializes scenes using the Sedulous.Serialization framework.
/// Handles entities, transforms, parent-child hierarchy, and components.
class SceneSerializer
{
	private ComponentTypeRegistry mTypeRegistry;

	public this(ComponentTypeRegistry typeRegistry)
	{
		mTypeRegistry = typeRegistry;
	}

	/// Serializes a scene to a serializer (write mode).
	public SerializationResult Save(Scene scene, Serializer serializer)
	{
		// Collect alive entities
		let entities = scope List<EntityHandle>();
		for (let entity in scene.Entities)
			entities.Add(entity);

		// Collect serializable modules
		let serializableModules = scope List<SceneModule>();
		for (let module in scene.Modules)
		{
			if (module.IsSerializable)
				serializableModules.Add(module);
		}

		// Write entity array
		var entityCount = (int32)entities.Count;
		serializer.BeginArray("Entities", ref entityCount);

		for (let entity in entities)
		{
			serializer.BeginObject("");

			// Entity header
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

			// Transform
			var transform = scene.GetLocalTransform(entity);
			SerializeTransform(serializer, ref transform);

			// Components - count how many serializable modules have a component for this entity
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

					// Write type ID and version
					let typeId = scope String(module.SerializationTypeId);
					serializer.String("TypeId", typeId);

					var version = cms.GetSerializationVersion();
					serializer.Int32("Version", ref version);

					// Serialize component data inside a nested object
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

		// Module-level data (non-entity state)
		SaveModuleData(scene, serializer);

		return .Ok;
	}

	/// Deserializes a scene from a serializer (read mode).
	public SerializationResult Load(Scene scene, Serializer serializer)
	{
		var entityCount = (int32)0;
		serializer.BeginArray("Entities", ref entityCount);

		let parentMap = scope Dictionary<Guid, Guid>(); // child -> parent

		for (int32 i = 0; i < entityCount; i++)
		{
			serializer.BeginObject("");

			// Entity header
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

			// Create entity
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

				// Find or create manager for this type
				SceneModule module = FindModuleByTypeId(scene, typeId);
				if (module == null && mTypeRegistry != null)
				{
					module = mTypeRegistry.CreateManager(typeId);
					if (module != null)
						scene.AddModule(module);
				}

				// Deserialize component data
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

		// Module-level data
		LoadModuleData(scene, serializer);

		return .Ok;
	}

	/// Saves module-level data for modules that implement IModuleSerializer.
	private void SaveModuleData(Scene scene, Serializer serializer)
	{
		// Count modules with module-level data
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

	/// Loads module-level data for modules that implement IModuleSerializer.
	private void LoadModuleData(Scene scene, Serializer serializer)
	{
		var moduleDataCount = (int32)0;
		if (serializer.BeginArray("Modules", ref moduleDataCount) not case .Ok)
			return; // No module data section - older scene file

		for (int32 i = 0; i < moduleDataCount; i++)
		{
			serializer.BeginObject("");

			let typeId = scope String();
			serializer.String("TypeId", typeId);

			var version = (int32)1;
			serializer.Int32("Version", ref version);

			// Find existing module
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

	/// Finds a module in the scene by its serialization type ID.
	private SceneModule FindModuleByTypeId(Scene scene, StringView typeId)
	{
		for (let module in scene.Modules)
		{
			if (module.IsSerializable && module.SerializationTypeId == typeId)
				return module;
		}
		return null;
	}

	private void SerializeTransform(Serializer serializer, ref Transform transform)
	{
		serializer.Float("PosX", ref transform.Position.X);
		serializer.Float("PosY", ref transform.Position.Y);
		serializer.Float("PosZ", ref transform.Position.Z);
		serializer.Float("RotX", ref transform.Rotation.X);
		serializer.Float("RotY", ref transform.Rotation.Y);
		serializer.Float("RotZ", ref transform.Rotation.Z);
		serializer.Float("RotW", ref transform.Rotation.W);
		serializer.Float("ScaleX", ref transform.Scale.X);
		serializer.Float("ScaleY", ref transform.Scale.Y);
		serializer.Float("ScaleZ", ref transform.Scale.Z);
	}
}
