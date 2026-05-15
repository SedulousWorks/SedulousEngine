namespace Sedulous.Editor.App;

using System;
using System.IO;
using System.Collections;
using Sedulous.Editor.Core;
using Sedulous.Resources;
using Sedulous.Models;
using Sedulous.Geometry.Tooling;
using Sedulous.Geometry.Tooling.Resources;
using Sedulous.Textures.Resources;
using Sedulous.VFS;

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
/// Uses the existing pipeline: ModelLoaderFactory -> ModelImporter -> ResourceImportResult.
/// Resources are written through the import context's mount and registered in its index.
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

		// Model base name for fallback when resource names are empty
		let modelBaseName = scope String();
		System.IO.Path.GetFileNameWithoutExtension(sourcePath, modelBaseName);
		if (modelBaseName.IsEmpty)
			modelBaseName.Set("model");

		int32 idx = 0;

		for (let mesh in importResult.StaticMeshes)
		{
			let item = new ImportPreviewItem();
			item.Name = new String((mesh.Name != null && !mesh.Name.IsEmpty) ? StringView(mesh.Name) : StringView(modelBaseName));
			item.Extension = new String(".mesh");
			item.TypeLabel = new String("Static Mesh");
			item.InternalIndex = idx++;
			preview.Items.Add(item);
		}

		for (let mesh in importResult.SkinnedMeshes)
		{
			let item = new ImportPreviewItem();
			item.Name = new String((mesh.Name != null && !mesh.Name.IsEmpty) ? StringView(mesh.Name) : StringView(modelBaseName));
			item.Extension = new String(".skinnedmesh");
			item.TypeLabel = new String("Skinned Mesh");
			item.InternalIndex = idx++;
			preview.Items.Add(item);
		}

		for (let tex in importResult.Textures)
		{
			let item = new ImportPreviewItem();
			item.Name = new String((tex.Name != null && !tex.Name.IsEmpty) ? StringView(tex.Name) : StringView(modelBaseName));
			item.Extension = new String(".texture");
			item.TypeLabel = new String("Texture");
			item.InternalIndex = idx++;
			preview.Items.Add(item);
		}

		for (let mat in importResult.Materials)
		{
			let item = new ImportPreviewItem();
			item.Name = new String((mat.Name != null && !mat.Name.IsEmpty) ? StringView(mat.Name) : StringView(modelBaseName));
			item.Extension = new String(".material");
			item.TypeLabel = new String("Material");
			item.InternalIndex = idx++;
			preview.Items.Add(item);
		}

		for (let skel in importResult.Skeletons)
		{
			let item = new ImportPreviewItem();
			item.Name = new String((skel.Name != null && !skel.Name.IsEmpty) ? StringView(skel.Name) : StringView(modelBaseName));
			item.Extension = new String(".skeleton");
			item.TypeLabel = new String("Skeleton");
			item.InternalIndex = idx++;
			preview.Items.Add(item);
		}

		for (let anim in importResult.Animations)
		{
			let item = new ImportPreviewItem();
			item.Name = new String((anim.Name != null && !anim.Name.IsEmpty) ? StringView(anim.Name) : StringView(modelBaseName));
			item.Extension = new String(".animation");
			item.TypeLabel = new String("Animation");
			item.InternalIndex = idx++;
			preview.Items.Add(item);
		}

		return .Ok(preview);
	}

	public Result<void> Import(ImportPreview preview, AssetImportContext ctx)
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

		// Build list of selected item names for filtering
		let selectedNames = scope List<StringView>();
		for (let item in preview.Items)
		{
			if (item.Selected)
				selectedNames.Add(item.Name);
		}

		// Save and register each selected resource. Textures get a binary
		// pixel sidecar; everything else is text-only.
		for (let res in resResult.Textures)
			SaveTexture(res, selectedNames, ctx);
		for (let res in resResult.Materials)
			SaveText(res, ".material", selectedNames, ctx);
		for (let res in resResult.StaticMeshes)
			SaveText(res, ".mesh", selectedNames, ctx);
		for (let res in resResult.SkinnedMeshes)
			SaveText(res, ".skinnedmesh", selectedNames, ctx);
		for (let res in resResult.Skeletons)
			SaveText(res, ".skeleton", selectedNames, ctx);
		for (let res in resResult.Animations)
			SaveText(res, ".animation", selectedNames, ctx);

		return .Ok;
	}

	/// Saves a text-only resource through the context's mount and registers
	/// its GUID in the context's index.
	private static void SaveText(Resource res, StringView @extension,
		List<StringView> selectedNames, AssetImportContext ctx)
	{
		if (res.Name == null || !selectedNames.Contains(res.Name))
			return;

		let fileName = scope String();
		fileName.AppendF("{}{}", res.Name, @extension);
		ResourceSerializer.SanitizePath(fileName);

		let locator = scope String();
		locator.Append(ctx.BaseLocator);
		locator.Append(fileName);

		let memStream = scope MemoryStream();
		if (res.WriteToStream(memStream, ctx.Serializer) case .Err)
			return;
		memStream.Position = 0;
		if (ctx.Mount.Save(locator, memStream) case .Err)
			return;

		let uri = scope String();
		uri.Append(ctx.UriPrefix);
		uri.Append(fileName);
		ctx.Index.Register(res.Id, uri);
	}

	/// Saves a TextureResource (text metadata + pixel sidecar) through the
	/// context's mount and registers its GUID.
	private static void SaveTexture(TextureResource res, List<StringView> selectedNames, AssetImportContext ctx)
	{
		if (res.Name == null || !selectedNames.Contains(res.Name))
			return;

		let fileName = scope String();
		fileName.AppendF("{}.texture", res.Name);
		ResourceSerializer.SanitizePath(fileName);

		let sidecarName = scope String();
		sidecarName.AppendF("{}.bin", fileName);

		let locator = scope String();
		locator.Append(ctx.BaseLocator);
		locator.Append(fileName);

		let sidecarLocator = scope String();
		sidecarLocator.Append(ctx.BaseLocator);
		sidecarLocator.Append(sidecarName);

		{
			let memStream = scope MemoryStream();
			if (res.WriteToStream(memStream, ctx.Serializer) case .Err)
				return;
			memStream.Position = 0;
			if (ctx.Mount.Save(locator, memStream) case .Err)
				return;
		}
		{
			let pcmStream = scope MemoryStream();
			if (res.WritePixelsToStream(pcmStream) case .Err)
				return;
			pcmStream.Position = 0;
			if (ctx.Mount.Save(sidecarLocator, pcmStream) case .Err)
				return;
		}

		let uri = scope String();
		uri.Append(ctx.UriPrefix);
		uri.Append(fileName);
		ctx.Index.Register(res.Id, uri);
	}
}
