using System;
using System.Collections;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Importer;

namespace Sedulous.ModelImporter;

/// What one model import is allowed to create, which is what the import dialog renders as
/// checkboxes.
class ModelImportOptions : ImportOptions
{
	/// Embedded and sidecar images become texture assets.
	public bool ImportTextures = true;
	/// The model's materials, with their texture slots wired when the textures import too.
	public bool ImportMaterials = true;
	/// The skeleton and its clips.
	public bool ImportAnimations = true;
	/// A spawnable prefab of the node hierarchy, made after the import lands.
	public bool GeneratePrefab = true;
	/// A standalone scene of the same hierarchy, made after the import lands.
	public bool GenerateScene = false;
	/// A collision shape per mesh, with colliders on the generated prefab.
	public bool GenerateCollision = false;
	/// Hulls, which a dynamic body can use, rather than exact triangle meshes.
	public bool CollisionConvex = false;
	/// Level of detail chains for big static meshes. An AUTHORED chain always wins.
	public bool GenerateLods = true;

	public override void GetToggles(List<ImportToggle> outToggles)
	{
		outToggles.Add(.("Textures", "Import the model's images as texture assets",
			&ImportTextures));
		outToggles.Add(.("Materials",
			"Import PBR materials (textures wire in when they import too)", &ImportMaterials));
		outToggles.Add(.("Animations", "Import the skeleton and animation clips",
			&ImportAnimations));
		outToggles.Add(.("Generate prefab",
			"Create a spawnable prefab of the model's node hierarchy; re-import regenerates it",
			&GeneratePrefab));
		outToggles.Add(.("Generate scene",
			"Create a standalone scene of the model's node hierarchy; re-import regenerates it",
			&GenerateScene));
		outToggles.Add(.("Generate collision",
			"Cook a collision shape per mesh and add colliders (and a static rigid body) to the generated prefab",
			&GenerateCollision));
		outToggles.Add(.("Generate LODs",
			"Simplified LOD chains for large static meshes; meshes with authored _LOD1/_LOD2 levels keep those instead",
			&GenerateLods));
		outToggles.Add(.("Convex collision",
			"Simplified convex hulls (dynamic-capable) instead of exact triangle meshes",
			&CollisionConvex));
	}

	public override void Serialize(ISerializer ar)
	{
		SerializeValue(ar, "textures", ref ImportTextures);
		SerializeValue(ar, "materials", ref ImportMaterials);
		SerializeValue(ar, "animations", ref ImportAnimations);
		SerializeValue(ar, "prefab", ref GeneratePrefab);
		SerializeValue(ar, "collision", ref GenerateCollision);
		SerializeValue(ar, "collisionConvex", ref CollisionConvex);
		SerializeValue(ar, "scene", ref GenerateScene);
		SerializeValue(ar, "generateLods", ref GenerateLods);
	}
}
