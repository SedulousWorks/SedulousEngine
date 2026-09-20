using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.VFS;
using Sedulous.Geometry;
using Sedulous.Geometry.Pipeline;
using Sedulous.Fonts.Pipeline;
using Sedulous.Texture.Pipeline;
using Sedulous.Pipeline.Importer;
using Sedulous.Editor.Core;

namespace Sedulous.Tools.Editor;

/// The starter content a new project gets, and the primitive mesh creators: the Roboto
/// font as the project's default UI font, the BlueSky environment, and the primitives.
/// Composed here because only the executable links every asset type.
static class EditorSeed
{
	/// --seed-primitives: every primitive rather than the three a new project starts with.
	public static bool SeedAllPrimitives = false;

	/// The engine data root the baseline assets come from.
	public static String DataRoot = new .() ~ delete _;

	private static void BaselineAssetPath(StringView relative, String outPath)
	{
		DataPath(DataRoot, PathJoin("Assets", relative, .. scope .()), outPath);
	}

	/// Authors a StaticMeshAsset from an in memory mesh, under `target` or the Meshes group.
	/// Takes the mesh.
	public static Instance CreatePrimitiveMeshInstance(EditorContext ctx, StringView baseName, StaticMesh mesh, Group target)
	{
		defer delete mesh;
		let project = ctx.Project;
		if ((project == null) || (mesh == null))
			return null;
		var meshes = target;
		if (meshes == null)
		{
			let root = project.SourceDb.RootGroup;
			meshes = root.GetGroup("Meshes");
			if (meshes == null)
				meshes = root.CreateGroup("Meshes");
		}
		if (meshes == null)
			return null;
		let name = meshes.UniqueInstanceName(baseName, .. scope .());
		let instance = meshes.CreateInstance(name, typeof(StaticMeshAsset).GetFullName(.. scope .()));
		if (instance == null)
			return null;
		let asset = scope StaticMeshAsset();
		MeshImporter.Import(mesh, asset);
		if (MeshAssetStorage.WriteStatic(instance, asset) case .Err)
			return null;
		return instance;
	}

	/// One "Primitives" creator per shape.
	public static void RegisterPrimitiveMeshCreators(EditorContext context)
	{
		context.RegisterCreator(new AssetCreator("Cube", "Primitives", new (ctx, group) => CreatePrimitiveMeshInstance(ctx, "Cube", Primitives.Cube(), group)));
		context.RegisterCreator(new AssetCreator("Sphere", "Primitives", new (ctx, group) => CreatePrimitiveMeshInstance(ctx, "Sphere", Primitives.Sphere(), group)));
		context.RegisterCreator(new AssetCreator("Plane", "Primitives", new (ctx, group) => CreatePrimitiveMeshInstance(ctx, "Plane", Primitives.Plane(), group)));
		context.RegisterCreator(new AssetCreator("Cylinder", "Primitives", new (ctx, group) => CreatePrimitiveMeshInstance(ctx, "Cylinder", Primitives.Cylinder(), group)));
		context.RegisterCreator(new AssetCreator("Cone", "Primitives", new (ctx, group) => CreatePrimitiveMeshInstance(ctx, "Cone", Primitives.Cone(), group)));
		context.RegisterCreator(new AssetCreator("Torus", "Primitives", new (ctx, group) => CreatePrimitiveMeshInstance(ctx, "Torus", Primitives.Torus(), group)));
	}

	/// Seeds a project the manager just created: the font, the sky and the primitives.
	public static void SeedNewProject(EditorContext ctx, EditorProject project)
	{
		let root = project.SourceDb.RootGroup;
		let importContext = scope ImportContext(project.SourcesRoot(.. scope .()));
		{
			let source = BaselineAssetPath("fonts/roboto/Roboto-Regular.ttf", .. scope .());
			let copied = scope String();
			if (ImportPaths.CopyIntoSources(importContext, source, copied) case .Ok)
			{
				var fonts = root.GetGroup("Fonts");
				if (fonts == null)
					fonts = root.CreateGroup("Fonts");
				if (let instance = fonts.CreateInstance("Roboto", typeof(FontAsset).GetFullName(.. scope .())))
				{
					let asset = scope FontAsset();
					asset.FileName.Set(copied);
					asset.Family.Set("Roboto");
					if (instance.WriteObject(asset) case .Ok)
						project.Settings.DefaultUiFontId = instance.Id;
				}
			}
			else
				GlobalLog(.Warning, "Editor: starter font missing ({}), the new project has no default UI font", source);
		}
		{
			let source = BaselineAssetPath("environment/BlueSky.hdr", .. scope .());
			let copied = scope String();
			if (ImportPaths.CopyIntoSources(importContext, source, copied) case .Ok)
			{
				var env = root.GetGroup("Environment");
				if (env == null)
					env = root.CreateGroup("Environment");
				if (let instance = env.CreateInstance("BlueSky", typeof(TextureAsset).GetFullName(.. scope .())))
				{
					let asset = scope TextureAsset();
					asset.FileName.Set(copied);
					asset.SetupForEquirectangularSkybox();
					instance.WriteObject(asset).IgnoreError();
				}
			}
		}
		CreatePrimitiveMeshInstance(ctx, "Cube", Primitives.Cube(), null);
		CreatePrimitiveMeshInstance(ctx, "Sphere", Primitives.Sphere(), null);
		CreatePrimitiveMeshInstance(ctx, "Plane", Primitives.Plane(), null);
		if (SeedAllPrimitives)
		{
			CreatePrimitiveMeshInstance(ctx, "Cylinder", Primitives.Cylinder(), null);
			CreatePrimitiveMeshInstance(ctx, "Cone", Primitives.Cone(), null);
			CreatePrimitiveMeshInstance(ctx, "Torus", Primitives.Torus(), null);
		}
		GlobalLog(.Information, "Editor: starter content seeded (font/sky/primitives{})", SeedAllPrimitives ? ", all primitives" : "");
	}
}
