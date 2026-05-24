namespace CuteSeriesImporter;

using System;
using System.Collections;
using Sedulous.Resources;
using Sedulous.Serialization;
using Sedulous.Core.Mathematics;
using static Sedulous.Resources.ResourceSerializerExtensions;

/// Resource that writes a multi-entity prefab (scene) in PrefabSerializer format.
/// Each entity has a MeshComponent with mesh and material refs.
class GeneratedScenePrefab : Resource
{
	public struct EntityEntry : IDisposable
	{
		public String Name;
		public ResourceRef MeshRef;
		public ResourceRef MaterialRef;
		public Vector3 Position;
		public Quaternion Rotation;
		public Vector3 Scale;

		public void Dispose() mut
		{
			delete Name;
			// Don't dispose refs — they borrow from caller's dictionaries
		}
	}

	public List<EntityEntry> Entities = new .() ~ {
		for (var e in ref _) e.Dispose();
		delete _;
	};

	public override ResourceType ResourceType => .("Sedulous.Engine.Core.Resources.PrefabResource");
	public override int32 SerializationVersion => 2;

	protected override SerializationResult OnSerialize(Serializer s)
	{
		if (!s.IsWriting)
			return .Ok;

		var entityCount = (int32)Entities.Count;
		s.BeginArray("Entities", ref entityCount);

		for (let entry in ref Entities)
		{
			s.BeginObject("");

			var entityId = Guid.Create();
			s.Guid("Id", ref entityId);

			let name = scope String(entry.Name);
			s.String("Name", name);

			var active = true;
			s.Bool("Active", ref active);

			var parentId = Guid.Empty;
			s.Guid("Parent", ref parentId);

			// Transform
			var pos = entry.Position;
			var rot = entry.Rotation;
			var scale = entry.Scale;

			s.BeginObject("Position");
			s.Float("X", ref pos.X);
			s.Float("Y", ref pos.Y);
			s.Float("Z", ref pos.Z);
			s.EndObject();

			s.BeginObject("Rotation");
			s.Float("X", ref rot.X);
			s.Float("Y", ref rot.Y);
			s.Float("Z", ref rot.Z);
			s.Float("W", ref rot.W);
			s.EndObject();

			s.BeginObject("Scale");
			s.Float("X", ref scale.X);
			s.Float("Y", ref scale.Y);
			s.Float("Z", ref scale.Z);
			s.EndObject();

			// 1 component: MeshComponent
			var componentCount = (int32)1;
			s.BeginArray("Components", ref componentCount);

			s.BeginObject("");
			let typeId = scope String("Sedulous.MeshComponent");
			s.String("TypeId", typeId);
			var version = (int32)1;
			s.Int32("Version", ref version);

			s.BeginObject("Data");

			var meshRef = entry.MeshRef;
			s.ResourceRef("MeshRef", ref meshRef);

			var castsShadows = true;
			s.Bool("CastsShadows", ref castsShadows);

			var isVisible = true;
			s.Bool("IsVisible", ref isVisible);

			var layerMask = (int32)1;
			s.Int32("LayerMask", ref layerMask);

			s.BeginObject("Color");
			var cx = 1.0f; var cy = 1.0f; var cz = 1.0f; var cw = 1.0f;
			s.Float("X", ref cx);
			s.Float("Y", ref cy);
			s.Float("Z", ref cz);
			s.Float("W", ref cw);
			s.EndObject();

			var matCount = entry.MaterialRef.IsValid ? (int32)1 : (int32)0;
			s.BeginArray("MaterialRefs", ref matCount);
			if (entry.MaterialRef.IsValid)
			{
				var matRef = entry.MaterialRef;
				s.ResourceRef("", ref matRef);
			}
			s.EndArray();

			s.EndObject(); // Data
			s.EndObject(); // Component

			s.EndArray(); // Components
			s.EndObject(); // Entity
		}

		s.EndArray(); // Entities
		return .Ok;
	}
}
