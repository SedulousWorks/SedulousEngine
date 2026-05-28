namespace CuteSeriesImporter;

using System;
using Sedulous.Resources;
using Sedulous.Serialization;
using Sedulous.Core.Mathematics;
using static Sedulous.Resources.ResourceSerializerExtensions;

/// Minimal Resource subclass that writes a single-entity prefab in the same
/// format as PrefabSerializer, without needing the engine layer (Scene,
/// component managers, etc.). Avoids pulling in Sedulous.Engine.Render's
/// heavy graphics dependency chain.
class GeneratedPrefabResource : Resource
{
	public String EntityName = new .() ~ delete _;

	// Component refs (not owned - caller keeps them alive)
	public ResourceRef SkinnedMeshRef;
	public ResourceRef StaticMeshRef;
	public ResourceRef SkeletonRef;
	public ResourceRef MaterialRef;
	public ResourceRef GraphRef;

	public override ResourceType ResourceType => .("Sedulous.Engine.Core.Resources.PrefabResource");
	public override int32 SerializationVersion => 2;

	protected override SerializationResult OnSerialize(Serializer s)
	{
		if (!s.IsWriting)
			return .Ok;

		let isAnimated = SkinnedMeshRef.IsValid;

		var entityCount = (int32)1;
		s.BeginArray("Entities", ref entityCount);

		// Single root entity
		s.BeginObject("");

		var entityId = Guid.Create();
		s.Guid("Id", ref entityId);

		let name = scope String(EntityName);
		s.String("Name", name);

		var active = true;
		s.Bool("Active", ref active);

		var parentId = Guid.Empty;
		s.Guid("Parent", ref parentId);

		// Identity transform
		WriteTransform(s, .Zero, Quaternion.Identity, .One);

		// Count components
		var componentCount = (int32)1; // mesh component
		if (isAnimated) componentCount++; // AnimationGraphComponent
		s.BeginArray("Components", ref componentCount);

		if (isAnimated)
		{
			WriteSkinnedMeshComponent(s);
			WriteAnimGraphComponent(s);
		}
		else
		{
			WriteMeshComponent(s);
		}

		s.EndArray(); // Components
		s.EndObject(); // Entity
		s.EndArray(); // Entities

		return .Ok;
	}

	private void WriteTransform(Serializer s, Vector3 pos, Quaternion rot, Vector3 scale)
	{
		var pos;
		var rot;
		var scale;

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
	}

	private void WriteSkinnedMeshComponent(Serializer s)
	{
		s.BeginObject("");

		let typeId = scope String("Sedulous.SkinnedMeshComponent");
		s.String("TypeId", typeId);
		var version = (int32)1;
		s.Int32("Version", ref version);

		s.BeginObject("Data");

		var meshRef = SkinnedMeshRef;
		s.ResourceRef("MeshRef", ref meshRef);

		var castsShadows = true;
		s.Bool("CastsShadows", ref castsShadows);

		var isVisible = true;
		s.Bool("IsVisible", ref isVisible);

		s.BeginObject("Color");
		var cx = 1.0f; var cy = 1.0f; var cz = 1.0f; var cw = 1.0f;
		s.Float("X", ref cx);
		s.Float("Y", ref cy);
		s.Float("Z", ref cz);
		s.Float("W", ref cw);
		s.EndObject();

		var matCount = MaterialRef.IsValid ? (int32)1 : (int32)0;
		s.BeginArray("MaterialRefs", ref matCount);
		if (MaterialRef.IsValid)
		{
			var matRef = MaterialRef;
			s.ResourceRef("", ref matRef);
		}
		s.EndArray();

		s.EndObject(); // Data
		s.EndObject(); // Component
	}

	private void WriteMeshComponent(Serializer s)
	{
		s.BeginObject("");

		let typeId = scope String("Sedulous.MeshComponent");
		s.String("TypeId", typeId);
		var version = (int32)1;
		s.Int32("Version", ref version);

		s.BeginObject("Data");

		var meshRef = StaticMeshRef;
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

		var matCount = MaterialRef.IsValid ? (int32)1 : (int32)0;
		s.BeginArray("MaterialRefs", ref matCount);
		if (MaterialRef.IsValid)
		{
			var matRef = MaterialRef;
			s.ResourceRef("", ref matRef);
		}
		s.EndArray();

		s.EndObject(); // Data
		s.EndObject(); // Component
	}

	private void WriteAnimGraphComponent(Serializer s)
	{
		s.BeginObject("");

		let typeId = scope String("Sedulous.AnimationGraphComponent");
		s.String("TypeId", typeId);
		var version = (int32)1;
		s.Int32("Version", ref version);

		s.BeginObject("Data");

		var skelRef = SkeletonRef;
		s.ResourceRef("SkeletonRef", ref skelRef);

		var graphRef = GraphRef;
		s.ResourceRef("GraphRef", ref graphRef);

		var active = true;
		s.Bool("Active", ref active);

		s.EndObject(); // Data
		s.EndObject(); // Component
	}
}
