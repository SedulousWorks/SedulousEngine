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
using Sedulous.Core.Logging.Abstractions;
using Sedulous.Animation;
using Sedulous.Animation.Resources;

/// Options for model import, shown in the import dialog.
class ModelImportDialogOptions : ImportOptions
{
	public ModelImportOptions Options = new .();

	/// Optional skeleton reference for name-based animation remapping.
	/// When set, animation-only models will match channels by bone name
	/// against this skeleton instead of using raw node indices.
	public ResourceRef SkeletonRef ~ _.Dispose();

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
	private ILogger mLogger;
	private ResourceSystem mResourceSystem;
	private ResourceHandle<SkeletonResource> mSkeletonHandle;

	public this(ILogger logger, ResourceSystem resourceSystem)
	{
		mLogger = logger;
		mResourceSystem = resourceSystem;
	}

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
		{
			mLogger?.LogError("Model import preview: load failed for {}", sourcePath);
			return .Err;
		}

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
			item.OriginalName = new String(item.Name);
			item.Extension = new String(".mesh");
			item.TypeLabel = new String("Static Mesh");
			item.InternalIndex = idx++;
			preview.Items.Add(item);
		}

		for (let mesh in importResult.SkinnedMeshes)
		{
			let item = new ImportPreviewItem();
			item.Name = new String((mesh.Name != null && !mesh.Name.IsEmpty) ? StringView(mesh.Name) : StringView(modelBaseName));
			item.OriginalName = new String(item.Name);
			item.Extension = new String(".skinnedmesh");
			item.TypeLabel = new String("Skinned Mesh");
			item.InternalIndex = idx++;
			preview.Items.Add(item);
		}

		for (let tex in importResult.Textures)
		{
			let item = new ImportPreviewItem();
			item.Name = new String((tex.Name != null && !tex.Name.IsEmpty) ? StringView(tex.Name) : StringView(modelBaseName));
			item.OriginalName = new String(item.Name);
			item.Extension = new String(".texture");
			item.TypeLabel = new String("Texture");
			item.InternalIndex = idx++;
			preview.Items.Add(item);
		}

		for (let mat in importResult.Materials)
		{
			let item = new ImportPreviewItem();
			item.Name = new String((mat.Name != null && !mat.Name.IsEmpty) ? StringView(mat.Name) : StringView(modelBaseName));
			item.OriginalName = new String(item.Name);
			item.Extension = new String(".material");
			item.TypeLabel = new String("Material");
			item.InternalIndex = idx++;
			preview.Items.Add(item);
		}

		for (let skel in importResult.Skeletons)
		{
			let item = new ImportPreviewItem();
			item.Name = new String((skel.Name != null && !skel.Name.IsEmpty) ? StringView(skel.Name) : StringView(modelBaseName));
			item.OriginalName = new String(item.Name);
			item.Extension = new String(".skeleton");
			item.TypeLabel = new String("Skeleton");
			item.InternalIndex = idx++;
			preview.Items.Add(item);
		}

		for (let anim in importResult.Animations)
		{
			let item = new ImportPreviewItem();
			item.Name = new String((anim.Name != null && !anim.Name.IsEmpty) ? StringView(anim.Name) : StringView(modelBaseName));
			item.OriginalName = new String(item.Name);
			item.Extension = new String(".animation");
			item.TypeLabel = new String("Animation");
			item.InternalIndex = idx++;
			preview.Items.Add(item);
		}

		return .Ok(preview);
	}

	public Result<void> Import(ImportPreview preview, AssetImportContext ctx)
	{
		ctx.Logger?.LogInformation("Model import: {} -> {}", preview.SourcePath, ctx.UriPrefix);

		// Re-import the model (CreatePreview was a dry run to enumerate items)
		let model = scope Model();
		if (ModelLoaderFactory.LoadModel(preview.SourcePath, model) != .Ok)
		{
			ctx.Logger?.LogError("Model import: load failed for {}", preview.SourcePath);
			return .Err;
		}

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

			// Load target skeleton if specified (for animation-only imports)
			if (dialogOpts.SkeletonRef.IsValid)
			{
				if (LoadSkeletonFromRef(dialogOpts.SkeletonRef, ctx) case .Ok(let skel))
					options.TargetSkeleton = skel;
			}
		}

		let importer = scope ModelImporter(options);
		let importResult = importer.Import(model);
		defer delete importResult;

		// Release skeleton handle (loaded via resource system, not owned)
		mSkeletonHandle.Release();

		// Convert to resources
		let resResult = ResourceImportResult.ConvertFrom(importResult, null, preview.SourcePath);
		defer delete resResult;

		// User-rename pass: walk preview items, find each one's converted
		// resource by (OriginalName, Extension), update the resource's Name
		// to the user's choice, and ask every resource to rewrite its
		// cross-refs by Guid so material -> texture etc. point at the new
		// filenames. Owns the remap dict's string values; freed on scope
		// exit.
		let remap = scope Dictionary<Guid, String>();
		defer { for (let kv in remap) delete kv.value; }
		ApplyUserRenames(preview, resResult, remap, ctx);

		// Build list of selected item names for filtering. Resources have
		// already been renamed by ApplyUserRenames, so this uses the same
		// item.Name the user chose - which now matches res.Name.
		let selectedNames = scope List<StringView>();
		for (let item in preview.Items)
		{
			if (item.Selected)
				selectedNames.Add(item.Name);
		}

		// Save and register each selected resource. Textures get a binary
		// pixel sidecar; everything else is text-only.
		int written = 0;
		for (let res in resResult.Textures)
			if (SaveTexture(res, selectedNames, ctx)) written++;
		for (let res in resResult.Materials)
			if (SaveText(res, ".material", selectedNames, ctx)) written++;
		for (let res in resResult.StaticMeshes)
			if (SaveText(res, ".mesh", selectedNames, ctx)) written++;
		for (let res in resResult.SkinnedMeshes)
			if (SaveText(res, ".skinnedmesh", selectedNames, ctx)) written++;
		for (let res in resResult.Skeletons)
			if (SaveText(res, ".skeleton", selectedNames, ctx)) written++;
		for (let res in resResult.Animations)
			if (SaveText(res, ".animation", selectedNames, ctx)) written++;

		ctx.Logger?.LogInformation("Model import: wrote {} resource(s) from {}", written, preview.SourcePath);
		return .Ok;
	}

	/// Saves a text-only resource through the context's mount and registers
	/// its GUID in the context's index. Returns true on success so the caller
	/// can count what was actually written for the summary log line.
	private static bool SaveText(Resource res, StringView @extension,
		List<StringView> selectedNames, AssetImportContext ctx)
	{
		if (res.Name == null || !selectedNames.Contains(res.Name))
			return false;

		let fileName = scope String();
		fileName.AppendF("{}{}", res.Name, @extension);
		ResourceSerializer.SanitizePath(fileName);

		let locator = scope String();
		locator.Append(ctx.BaseLocator);
		locator.Append(fileName);

		let memStream = scope MemoryStream();
		if (res.WriteToStream(memStream, ctx.Serializer) case .Err)
		{
			ctx.Logger?.LogError("Model import: serialization failed for {}", locator);
			return false;
		}
		memStream.Position = 0;
		if (ctx.Mount.Save(locator, memStream) case .Err(let err))
		{
			ctx.Logger?.LogError("Model import: mount save failed for {}: {}", locator, err);
			return false;
		}

		let uri = scope String();
		uri.Append(ctx.UriPrefix);
		uri.Append(fileName);
		ctx.Index.Register(res.Id, uri);
		return true;
	}

	/// Saves a TextureResource (text metadata + pixel sidecar) through the
	/// context's mount and registers its GUID.
	private static bool SaveTexture(TextureResource res, List<StringView> selectedNames, AssetImportContext ctx)
	{
		if (res.Name == null || !selectedNames.Contains(res.Name))
			return false;

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
			{
				ctx.Logger?.LogError("Model import: texture metadata serialization failed for {}", locator);
				return false;
			}
			memStream.Position = 0;
			if (ctx.Mount.Save(locator, memStream) case .Err(let err))
			{
				ctx.Logger?.LogError("Model import: texture mount save failed for {}: {}", locator, err);
				return false;
			}
		}
		{
			let pixelStream = scope MemoryStream();
			if (res.WritePixelsToStream(pixelStream) case .Err)
			{
				ctx.Logger?.LogError("Model import: texture pixel sidecar serialization failed for {}", sidecarLocator);
				return false;
			}
			pixelStream.Position = 0;
			if (ctx.Mount.Save(sidecarLocator, pixelStream) case .Err(let err))
			{
				ctx.Logger?.LogError("Model import: texture pixel sidecar save failed for {}: {}", sidecarLocator, err);
				return false;
			}
		}

		let uri = scope String();
		uri.Append(ctx.UriPrefix);
		uri.Append(fileName);
		ctx.Index.Register(res.Id, uri);
		return true;
	}

	/// Walks preview items, matches each to its converted resource by
	/// (OriginalName, Extension), and:
	///   1. Updates the matched resource's Name to the user-edited Name
	///      (so SaveText / SaveTexture write the renamed filename).
	///   2. Records resource.Id -> "<newName><extension>" in `outRemap`.
	///   3. After all matches, calls RemapReferences(outRemap) on every
	///      converted resource so cross-refs (material -> texture,
	///      skinnedmesh -> skeleton, etc.) point at the new filenames.
	/// The remap dict's values are heap strings owned by the caller (see
	/// the `defer { delete kv.value; }` in Import).
	private static void ApplyUserRenames(ImportPreview preview, ResourceImportResult resResult,
		Dictionary<Guid, String> outRemap, AssetImportContext ctx)
	{
		for (let item in preview.Items)
		{
			let original = item.OriginalName ?? item.Name;
			let resource = FindResourceByName(resResult, original, item.Extension);
			if (resource == null)
				continue;

			// Update the resource's Name to the user's choice (no-op when
			// the user didn't rename).
			resource.Name.Set(item.Name);

			// Record GUID -> filename for cross-ref rewriting.
			let finalPath = new String();
			finalPath.AppendF("{}{}", item.Name, item.Extension);
			outRemap[resource.Id] = finalPath;

			if (item.Name != original)
				ctx.Logger?.LogDebug("Model import: rename {}{} -> {}", original, item.Extension, finalPath);
		}

		// Ask every converted resource to rewrite its cross-refs by Guid.
		// Most are no-ops (base default); MaterialResource and SkinnedMeshResource
		// actually do the rewriting for texture / skeleton refs.
		for (let res in resResult.Textures)     res.RemapReferences(outRemap);
		for (let res in resResult.Materials)    res.RemapReferences(outRemap);
		for (let res in resResult.StaticMeshes) res.RemapReferences(outRemap);
		for (let res in resResult.SkinnedMeshes) res.RemapReferences(outRemap);
		for (let res in resResult.Skeletons)    res.RemapReferences(outRemap);
		for (let res in resResult.Animations)   res.RemapReferences(outRemap);
	}

	/// Loads a Skeleton from a resource ref via the resource system.
	/// Returns the skeleton pointer (not owned — lives in the resource system cache).
	private Result<Skeleton> LoadSkeletonFromRef(ResourceRef skelRef, AssetImportContext ctx)
	{
		if (!skelRef.IsValid || mResourceSystem == null)
			return .Err;

		if (mResourceSystem.LoadByRef<SkeletonResource>(skelRef) case .Ok(let handle))
		{
			mSkeletonHandle = handle;
			if (handle.Resource?.Skeleton != null)
				return .Ok(handle.Resource.Skeleton);
		}

		return .Err;
	}

	private static Resource FindResourceByName(ResourceImportResult res,
		StringView name, StringView @extension)
	{
		switch (@extension)
		{
		case ".texture":
			for (let t in res.Textures) if (StringView(t.Name) == name) return t;
		case ".material":
			for (let m in res.Materials) if (StringView(m.Name) == name) return m;
		case ".mesh":
			for (let m in res.StaticMeshes) if (StringView(m.Name) == name) return m;
		case ".skinnedmesh":
			for (let m in res.SkinnedMeshes) if (StringView(m.Name) == name) return m;
		case ".skeleton":
			for (let s in res.Skeletons) if (StringView(s.Name) == name) return s;
		case ".animation":
			for (let a in res.Animations) if (StringView(a.Name) == name) return a;
		}
		return null;
	}
}
