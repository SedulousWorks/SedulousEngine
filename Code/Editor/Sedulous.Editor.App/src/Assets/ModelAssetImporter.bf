namespace Sedulous.Editor.App;

using System;
using System.Collections;
using Sedulous.Editor.Core;
using Sedulous.Resources;
using Sedulous.Models;
using Sedulous.Geometry.Tooling;
using Sedulous.Geometry.Tooling.Resources;

/// Options for model import, shown in the import dialog.
class ModelImportDialogOptions : ImportOptions
{
	public ModelImportOptions Options = new .();

	public ~this()
	{
		delete Options;
	}
}

/// Imports 3D model files (.gltf, .glb, .fbx, .obj) into engine resources.
/// Produces: static meshes, skinned meshes, materials, textures, skeletons, animations.
///
/// Uses the existing pipeline: ModelLoaderFactory -> ModelImporter -> ResourceImportResult
/// -> ResourceSerializer for disk save, then registers GUIDs in the target registry.
class ModelAssetImporter : IAssetImporter
{
	public void GetSupportedExtensions(List<String> outExtensions)
	{
		outExtensions.Add(new .(".gltf"));
		outExtensions.Add(new .(".glb"));
		outExtensions.Add(new .(".fbx"));
		outExtensions.Add(new .(".obj"));
	}

	public Result<ImportPreview> CreatePreview(StringView sourcePath)
	{
		// Load the model to discover its contents
		let model = scope Model();
		if (ModelLoaderFactory.LoadModel(sourcePath, model) != .Ok)
			return .Err;

		// Get the directory of the source file for texture resolution
		let baseDir = scope String();
		System.IO.Path.GetDirectoryPath(sourcePath, baseDir);

		// Run the importer to discover what will be produced
		let options = new ModelImportOptions();
		options.BasePath.Set(baseDir);
		options.ModelPath.Set(sourcePath);
		let importer = scope ModelImporter(options);
		let importResult = importer.Import(model);
		defer { delete importResult; /*delete options;*/ }

		// Build preview items from the import result
		let preview = new ImportPreview();
		preview.SourcePath = new String(sourcePath);

		let dialogOptions = new ModelImportDialogOptions();
		dialogOptions.Options.BasePath.Set(baseDir);
		dialogOptions.Options.ModelPath.Set(sourcePath);
		preview.Options = dialogOptions;

		int32 idx = 0;

		for (let mesh in importResult.StaticMeshes)
		{
			let item = new ImportPreviewItem();
			item.Name = new String(mesh.Name ?? "mesh");
			item.Extension = new String(".mesh");
			item.TypeLabel = new String("Static Mesh");
			item.InternalIndex = idx++;
			preview.Items.Add(item);
		}

		for (let mesh in importResult.SkinnedMeshes)
		{
			let item = new ImportPreviewItem();
			item.Name = new String(mesh.Name ?? "skinnedmesh");
			item.Extension = new String(".skinnedmesh");
			item.TypeLabel = new String("Skinned Mesh");
			item.InternalIndex = idx++;
			preview.Items.Add(item);
		}

		for (let tex in importResult.Textures)
		{
			let item = new ImportPreviewItem();
			item.Name = new String(tex.Name ?? "texture");
			item.Extension = new String(".texture");
			item.TypeLabel = new String("Texture");
			item.InternalIndex = idx++;
			preview.Items.Add(item);
		}

		for (let mat in importResult.Materials)
		{
			let item = new ImportPreviewItem();
			item.Name = new String(mat.Name ?? "material");
			item.Extension = new String(".material");
			item.TypeLabel = new String("Material");
			item.InternalIndex = idx++;
			preview.Items.Add(item);
		}

		for (let skel in importResult.Skeletons)
		{
			let item = new ImportPreviewItem();
			item.Name = new String(skel.Name ?? "skeleton");
			item.Extension = new String(".skeleton");
			item.TypeLabel = new String("Skeleton");
			item.InternalIndex = idx++;
			preview.Items.Add(item);
		}

		for (let anim in importResult.Animations)
		{
			let item = new ImportPreviewItem();
			item.Name = new String(anim.Name ?? "animation");
			item.Extension = new String(".animation");
			item.TypeLabel = new String("Animation");
			item.InternalIndex = idx++;
			preview.Items.Add(item);
		}

		return .Ok(preview);
	}

	public Result<void> Import(ImportPreview preview, StringView outputDir,
		ResourceRegistry registry, Sedulous.Serialization.ISerializerProvider serializer)
	{
		// Re-import the model (CreatePreview was a dry run to enumerate items)
		let model = scope Model();
		if (ModelLoaderFactory.LoadModel(preview.SourcePath, model) != .Ok)
			return .Err;

		// Use dialog options if available, otherwise defaults
		let baseDir = scope String();
		System.IO.Path.GetDirectoryPath(preview.SourcePath, baseDir);

		// ModelImporter takes ownership of its options and deletes them,
		// so we always create a fresh copy for it.
		let options = new ModelImportOptions();
		options.BasePath.Set(baseDir);
		options.ModelPath.Set(preview.SourcePath);

		// Copy dialog settings if available
		if (let dialogOpts = preview.Options as ModelImportDialogOptions)
		{
			options.Flags = dialogOpts.Options.Flags;
			options.Scale = dialogOpts.Options.Scale;
			options.GenerateNormals = dialogOpts.Options.GenerateNormals;
			options.GenerateTangents = dialogOpts.Options.GenerateTangents;
			options.RecenterMeshes = dialogOpts.Options.RecenterMeshes;
			options.MaxBonesPerVertex = dialogOpts.Options.MaxBonesPerVertex;
		}

		let importer = scope ModelImporter(options);
		let importResult = importer.Import(model);
		defer delete importResult;

		// Convert to resources
		let resResult = ResourceImportResult.ConvertFrom(importResult, null, preview.SourcePath);
		defer delete resResult;

		let provider = serializer;

		// Ensure output directory exists
		if (!System.IO.Directory.Exists(outputDir))
			System.IO.Directory.CreateDirectory(outputDir);

		// Build list of selected item names for filtering
		let selectedNames = scope List<StringView>();
		for (let item in preview.Items)
		{
			if (item.Selected)
				selectedNames.Add(item.Name);
		}

		// Compute relative path prefix for registry (relative to registry root)
		let relPrefix = scope String();
		if (registry.RootPath.Length > 0 && StringView(outputDir).StartsWith(registry.RootPath))
		{
			let after = StringView(outputDir)[registry.RootPath.Length...];
			if (after.StartsWith('/') || after.StartsWith('\\'))
				relPrefix.Set(after[1...]);
			else
				relPrefix.Set(after);
			relPrefix.Replace('\\', '/');
		}

		// Save and register each selected resource
		for (let res in resResult.Textures)
			SaveAndRegister(res, ".texture", selectedNames, outputDir, relPrefix, registry, provider);
		for (let res in resResult.Materials)
			SaveAndRegister(res, ".material", selectedNames, outputDir, relPrefix, registry, provider);
		for (let res in resResult.StaticMeshes)
			SaveAndRegister(res, ".mesh", selectedNames, outputDir, relPrefix, registry, provider);
		for (let res in resResult.SkinnedMeshes)
			SaveAndRegister(res, ".skinnedmesh", selectedNames, outputDir, relPrefix, registry, provider);
		for (let res in resResult.Skeletons)
			SaveAndRegister(res, ".skeleton", selectedNames, outputDir, relPrefix, registry, provider);
		for (let res in resResult.Animations)
			SaveAndRegister(res, ".animation", selectedNames, outputDir, relPrefix, registry, provider);

		// Save registry to disk
		let regFile = scope String();
		System.IO.Path.InternalCombine(regFile, registry.RootPath, scope $"{registry.Name}.registry");
		registry.SaveToFile(regFile);

		return .Ok;
	}

	/// Saves a single resource to disk and registers it in the registry if selected.
	private void SaveAndRegister(Resource res, StringView @extension,
		List<StringView> selectedNames, StringView outputDir, StringView relPrefix,
		ResourceRegistry registry, Sedulous.Serialization.ISerializerProvider provider)
	{
		if (res.Name == null || !selectedNames.Contains(res.Name))
			return;

		let fileName = scope String();
		fileName.AppendF("{}{}", res.Name, @extension);
		ResourceSerializer.SanitizePath(fileName);

		let fullPath = scope String();
		System.IO.Path.InternalCombine(fullPath, outputDir, fileName);

		if (res.SaveToFile(fullPath, provider) case .Ok)
		{
			let relPath = scope String();
			if (relPrefix.Length > 0)
				relPath.AppendF("{}/{}", relPrefix, fileName);
			else
				relPath.Set(fileName);

			registry.Register(res.Id, relPath);
		}
	}
}
