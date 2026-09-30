using System;
using Sedulous.Core;
using Sedulous.Content;
using Sedulous.Geometry;
using Sedulous.Pipeline.Core;

namespace Sedulous.Geometry.Pipeline;

/// The geometry domain's New Asset creators: one per primitive shape, a static mesh under
/// Meshes/ unless a group was picked.
static class GeometryCreators
{
	public static void Register(AssetCreatorRegistry registry)
	{
		registry.Register(new AssetCreator("Cube", "Primitives", typeof(StaticMeshAsset), new (context) => CreatePrimitive(context.Target, context.NameOr("Cube"), Primitives.Cube())).Under("Meshes"));
		registry.Register(new AssetCreator("Sphere", "Primitives", typeof(StaticMeshAsset), new (context) => CreatePrimitive(context.Target, context.NameOr("Sphere"), Primitives.Sphere())).Under("Meshes"));
		registry.Register(new AssetCreator("Plane", "Primitives", typeof(StaticMeshAsset), new (context) => CreatePrimitive(context.Target, context.NameOr("Plane"), Primitives.Plane())).Under("Meshes"));
		registry.Register(new AssetCreator("Cylinder", "Primitives", typeof(StaticMeshAsset), new (context) => CreatePrimitive(context.Target, context.NameOr("Cylinder"), Primitives.Cylinder())).Under("Meshes"));
		registry.Register(new AssetCreator("Cone", "Primitives", typeof(StaticMeshAsset), new (context) => CreatePrimitive(context.Target, context.NameOr("Cone"), Primitives.Cone())).Under("Meshes"));
		registry.Register(new AssetCreator("Torus", "Primitives", typeof(StaticMeshAsset), new (context) => CreatePrimitive(context.Target, context.NameOr("Torus"), Primitives.Torus())).Under("Meshes"));
	}

	/// A static mesh asset authored from an in memory mesh, uniquely named in `target`: the
	/// creators' body, and the new-project seed's. TAKES the mesh.
	public static Instance CreatePrimitive(Group target, StringView baseName, StaticMesh mesh)
	{
		defer delete mesh;
		if ((target == null) || (mesh == null))
			return null;
		let name = target.UniqueInstanceName(baseName, .. scope .());
		let instance = target.CreateInstance(name, typeof(StaticMeshAsset).GetFullName(.. scope .()));
		if (instance == null)
			return null;
		let asset = scope StaticMeshAsset();
		MeshImporter.Import(mesh, asset);
		if (MeshAssetStorage.WriteStatic(instance, asset) case .Err)
			return null;
		return instance;
	}
}
