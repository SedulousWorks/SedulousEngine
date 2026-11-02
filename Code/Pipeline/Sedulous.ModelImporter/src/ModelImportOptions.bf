using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Importer;

namespace Sedulous.ModelImporter;

/// Which way is up in a model file whose loader reads it as Y up but whose content is not (an
/// export whose Z-up axis was not written into the file). Its cases are reflected: the import
/// window offers them, and an agent names one.
[Reflect(.StaticFields)]
enum ModelUpAxis : uint8
{
	/// As the file is read.
	case Y;
	/// Turned so its Z points up.
	case Z;
}

/// What one model import is allowed to create: its settings, which the import window draws and an
/// agent sets by label.
[Reflect(.NonStaticFields | .DefaultConstructor)]
class ModelImportOptions : ImportOptions
{
	/// Every length times this (a file in centimetres: 0.01), applied before the fan out
	/// (ModelImportFrame).
	[DisplayName("Scale"), Description("Every length times this: 0.01 for a file in centimetres, 100 for one in metres read as centimetres")]
	public float Scale = 1.0f;
	/// The file's up, turned to the engine's Y.
	[DisplayName("Up axis"), Description("The axis that is up in the model: Z turns a Z-up model upright")]
	public ModelUpAxis UpAxis = .Y;
	/// Embedded and sidecar images become texture assets.
	[DisplayName("Textures"), Description("Import the model's images as texture assets")]
	public bool ImportTextures = true;
	/// The model's materials, with their texture slots wired when the textures import too.
	[DisplayName("Materials"), Description("Import PBR materials (textures wire in when they import too)")]
	public bool ImportMaterials = true;
	/// The skeleton and its clips.
	[DisplayName("Animations"), Description("Import the skeleton and animation clips")]
	public bool ImportAnimations = true;
	/// A spawnable prefab of the node hierarchy, made after the import lands.
	[DisplayName("Generate prefab"), Description("Create a spawnable prefab of the model's node hierarchy; re-import regenerates it")]
	public bool GeneratePrefab = true;
	/// A standalone scene of the same hierarchy, made after the import lands.
	[DisplayName("Generate scene"), Description("Create a standalone scene of the model's node hierarchy; re-import regenerates it")]
	public bool GenerateScene = false;
	/// A collision shape per mesh, with colliders on the generated prefab.
	[DisplayName("Generate collision"), Description("Cook a collision shape per mesh and add colliders (and a static rigid body) to the generated prefab")]
	public bool GenerateCollision = false;
	/// Hulls, which a dynamic body can use, rather than exact triangle meshes.
	[DisplayName("Convex collision"), Description("Simplified convex hulls (dynamic-capable) instead of exact triangle meshes"), VisibleWhen("GenerateCollision")]
	public bool CollisionConvex = false;
	/// Level of detail chains for big static meshes. An AUTHORED chain always wins.
	[DisplayName("Generate LODs"), Description("Simplified LOD chains for large static meshes; meshes with authored _LOD1/_LOD2 levels keep those instead")]
	public bool GenerateLods = true;
	/// New clips move the character by their root's travel and turn, and play in place
	/// (root-motion.md); a re-import keeps what each clip says.
	[DisplayName("Root motion"), Description("New clips move the character by their root's travel and turn, and play in place (each clip's page can change it; a re-import keeps what the clip says)")]
	public bool RootMotion = false;

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
		// Appended: options saved before it read as off.
		if ((ar.Mode != .Read) || ar.HasKey("rootMotion"))
			SerializeValue(ar, "rootMotion", ref RootMotion);
		// Appended: before them, 1 and Y.
		if ((ar.Mode != .Read) || ar.HasKey("scale"))
			SerializeValue(ar, "scale", ref Scale);
		if ((ar.Mode != .Read) || ar.HasKey("upAxis"))
			SerializeValue(ar, "upAxis", ref UpAxis);
		if (UpAxis != .Z)
			UpAxis = .Y;
	}
}
