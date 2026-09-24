using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Model;
using Sedulous.Model.IO;
using Sedulous.Image;
using Sedulous.Image.DDS;
using Sedulous.Image.IO;
using ufbx_Beef;

namespace Sedulous.Model.FBX;

/// Loads FBX and OBJ files through ufbx.
///
/// Unlike glTF, an FBX carries whatever axes and units the tool that wrote it used, and its
/// geometry is not triangulated and not indexed the way a GPU wants. So the load asks ufbx
/// to convert on the way in and then rebuilds the geometry: triangulate, deduplicate, and
/// index.
class FbxLoader : IModelLoader
{
	private ufbx_scene* mScene = null;
	private String mBasePath = new .() ~ delete _;

	/// ufbx addresses everything by a per type id. These carry those ids across to the
	/// indices the model uses, because the two are not the same numbering: a mesh ufbx
	/// could not load is skipped, and every index after it would otherwise be wrong.
	private Dictionary<uint32, int32> mNodeToBone = new .() ~ delete _;
	private Dictionary<uint32, int32> mMaterialToIndex = new .() ~ delete _;
	private Dictionary<uint32, int32> mTextureToIndex = new .() ~ delete _;
	private Dictionary<uint32, int32> mMeshToIndex = new .() ~ delete _;
	private Dictionary<uint32, int32> mSkinToIndex = new .() ~ delete _;

	public ~this()
	{
		FreeScene();
	}

	/// @extension because `extension` is a Beef keyword.
	///
	/// OBJ as well as FBX: ufbx reads both, and a caller that has one has usually got the
	/// other beside it.
	public bool SupportsExtension(StringView @extension)
		=> EqualsIgnoreCase(@extension, ".fbx") || EqualsIgnoreCase(@extension, ".obj");

	public ModelLoadResult Load(StringView path, ModelData model)
	{
		FreeScene();
		ClearMaps();

		mBasePath.Clear();
		PathParent(path, mBasePath);

		var options = ufbx_load_opts();
		// Converted on the way IN rather than afterwards: ufbx rewrites the geometry into
		// the target space itself, which is exact, where transforming a loaded mesh
		// afterwards would have to fix up normals and tangents separately.
		options.target_axes = ufbx_Beef.ufbx_axes_right_handed_y_up;
		options.target_unit_meters = 1.0;
		options.space_conversion = .UFBX_SPACE_CONVERSION_MODIFY_GEOMETRY;
		// No fallback node: a geometry transform becomes part of the mesh rather than an
		// extra bone in the hierarchy, which would not survive the round trip through a
		// skeleton that has to match an animation.
		options.geometry_transform_handling = .UFBX_GEOMETRY_TRANSFORM_HANDLING_MODIFY_GEOMETRY_NO_FALLBACK;
		options.generate_missing_normals = true;
		// Drops the near zero weights an exporter leaves behind, which would otherwise take
		// up slots in the four the vertex has room for.
		options.clean_skin_weights = true;
		options.use_blender_pbr_material = true;
		// Reads the files the model POINTS AT: an OBJ's .mtl above all. Without it a
		// material arrives with its name and nothing else, so every OBJ loads untextured
		// and untinted while still looking like it worked.
		options.load_external_files = true;
		// A MISSING sidecar is not an error: the file still describes geometry, and failing
		// the whole load over an absent .mtl would refuse models that render fine.
		options.ignore_missing_external_files = true;
		// Find the .mtl beside the OBJ by filename when the file does not say where it is,
		// which is the common case for exported models.
		options.obj_search_mtl_by_filename = true;

		let pathZ = scope String(path);
		ufbx_error error = default;
		mScene = ufbx_Beef.ufbx_load_file(pathZ, &options, &error);

		if (mScene == null)
		{
			switch (error.type)
			{
			case .UFBX_ERROR_FILE_NOT_FOUND: return .FileNotFound;
			case .UFBX_ERROR_UNSUPPORTED_VERSION: return .UnsupportedFormat;
			default: return .ParseError;
			}
		}

		// The conversion above has already made it Y up, so there is nothing to detect.
		model.OriginalUpAxis = .PositiveY;

		LoadMaterials(model);
		LoadTextures(model);
		DetectAlphaFromTextures(model);
		LoadMeshes(model);
		LoadNodes(model);
		LoadSkins(model);
		LoadAnimations(model);

		model.BuildBoneHierarchy();
		model.CalculateBounds();

		return .Ok;
	}

	private void FreeScene()
	{
		if (mScene != null)
		{
			ufbx_Beef.ufbx_free_scene(mScene);
			mScene = null;
		}
	}

	private void ClearMaps()
	{
		mNodeToBone.Clear();
		mMaterialToIndex.Clear();
		mTextureToIndex.Clear();
		mMeshToIndex.Clear();
		mSkinToIndex.Clear();
	}

	// ---------------------------------------------------------------- helpers

	private static bool EqualsIgnoreCase(StringView a, StringView b)
	{
		if (a.Length != b.Length)
			return false;
		for (int i < a.Length)
		{
			if (a[i].ToLower != b[i].ToLower)
				return false;
		}
		return true;
	}

	/// ufbx strings carry a length and are not null terminated, so the length is what to
	/// trust.
	private static void AppendUfbx(String target, ufbx_string text)
	{
		if ((text.data != null) && (text.length > 0))
			target.Append(StringView(text.data, (int)text.length));
	}

	private static void AppendCString(String target, char8* text)
	{
		if (text != null)
			target.Append(StringView(text));
	}
	// -------------------------------------------------------------- materials

	private void LoadMaterials(ModelData model)
	{
		for (int i < (int)mScene.materials.count)
		{
			let source = mScene.materials.data[i];
			let material = new ModelMaterial();
			AppendUfbx(material.Name, source.element.name);

			if (source.features.pbr.enabled)
				ReadPbrMaterial(source, material, model);
			else
				ReadLegacyMaterial(source, material, model);

			// FBX does not reliably carry a double sided flag out of the tools, so an
			// unstated one is taken as TRUE. Culling a surface that should not have been
			// culled leaves a visible hole; drawing a back face that could have been
			// skipped only costs a little fill.
			if (source.features.double_sided.is_explicit)
				material.DoubleSided = source.features.double_sided.enabled;
			else
				material.DoubleSided = true;

			// Only the SCALAR opacity here. Alpha carried in a texture is decided after the
			// textures have been read, which is what DetectAlphaFromTextures is for.
			if (source.features.opacity.enabled)
			{
				if (source.pbr.opacity.has_value && ((float)source.pbr.opacity.value_real < 1.0f))
					material.AlphaMode = .Blend;
				else if (source.fbx.transparency_factor.has_value
					&& ((float)source.fbx.transparency_factor.value_real > 0.0f))
					material.AlphaMode = .Blend;
			}

			let index = model.AddMaterial(material);
			mMaterialToIndex[source.element.typed_id] = index;
		}
	}

	private void ReadPbrMaterial(ufbx_material* source, ModelMaterial material, ModelData model)
	{
		if (source.pbr.base_color.has_value)
		{
			let c = source.pbr.base_color.value_vec4;
			material.BaseColorFactor = .((float)c.x, (float)c.y, (float)c.z, (float)c.w);
		}
		if (source.pbr.base_color.texture != null)
		{
			material.BaseColorTextureIndex = TextureIndex(source.pbr.base_color.texture, model);
			// Reset to white. With the Blender PBR mapping the base colour is often the
			// legacy diffuse grey, and leaving it would darken the texture by a fifth.
			material.BaseColorFactor = .(1, 1, 1, 1);
		}

		if (source.pbr.metalness.has_value)
			material.MetallicFactor = (float)source.pbr.metalness.value_real;
		if (source.pbr.roughness.has_value)
			material.RoughnessFactor = (float)source.pbr.roughness.value_real;

		// FBX authors metalness and roughness as SEPARATE greyscale maps where glTF packs
		// them into one texture's green and blue. Kept apart here and packed downstream by
		// the importer, because packing needs both to be present and one may be missing.
		if (source.pbr.metalness.texture != null)
			material.SeparateMetalnessTextureIndex = TextureIndex(source.pbr.metalness.texture, model);
		if (source.pbr.roughness.texture != null)
			material.SeparateRoughnessTextureIndex = TextureIndex(source.pbr.roughness.texture, model);

		if (source.pbr.normal_map.texture != null)
		{
			material.NormalTextureIndex = TextureIndex(source.pbr.normal_map.texture, model);
			material.NormalScale = 1.0f;
		}
		if (source.pbr.ambient_occlusion.texture != null)
		{
			material.OcclusionTextureIndex = TextureIndex(source.pbr.ambient_occlusion.texture, model);
			material.OcclusionStrength = 1.0f;
		}

		if (source.pbr.emission_color.has_value)
		{
			let e = source.pbr.emission_color.value_vec3;
			// FBX keeps the emissive colour and its strength apart; the model has one
			// factor, so they are multiplied together here.
			let factor = source.pbr.emission_factor.has_value
				? (float)source.pbr.emission_factor.value_real : 1.0f;
			material.EmissiveFactor = .((float)e.x * factor, (float)e.y * factor, (float)e.z * factor);
		}
		if (source.pbr.emission_color.texture != null)
			material.EmissiveTextureIndex = TextureIndex(source.pbr.emission_color.texture, model);
	}

	/// A Lambert or Phong material from before PBR, mapped onto the PBR fields.
	private void ReadLegacyMaterial(ufbx_material* source, ModelMaterial material, ModelData model)
	{
		if (source.fbx.diffuse_color.has_value)
		{
			let c = source.fbx.diffuse_color.value_vec4;
			let factor = source.fbx.diffuse_factor.has_value
				? (float)source.fbx.diffuse_factor.value_real : 1.0f;
			material.BaseColorFactor = .((float)c.x * factor, (float)c.y * factor, (float)c.z * factor, 1.0f);
		}
		if (source.fbx.diffuse_color.texture != null)
		{
			material.BaseColorTextureIndex = TextureIndex(source.fbx.diffuse_color.texture, model);
			material.BaseColorFactor = .(1, 1, 1, 1);
		}

		if (source.fbx.normal_map.texture != null)
		{
			material.NormalTextureIndex = TextureIndex(source.fbx.normal_map.texture, model);
			material.NormalScale = 1.0f;
		}

		if (source.fbx.emission_color.has_value)
		{
			let e = source.fbx.emission_color.value_vec3;
			let factor = source.fbx.emission_factor.has_value
				? (float)source.fbx.emission_factor.value_real : 1.0f;
			material.EmissiveFactor = .((float)e.x * factor, (float)e.y * factor, (float)e.z * factor);
		}
		if (source.fbx.emission_color.texture != null)
			material.EmissiveTextureIndex = TextureIndex(source.fbx.emission_color.texture, model);

		// A material that predates PBR says nothing about metalness, and a default of one
		// would make every old asset a mirror.
		material.MetallicFactor = 0.0f;
		material.RoughnessFactor = 0.8f;
	}

	/// The model index for a ufbx texture, creating the entry if this is the first mention.
	///
	/// Materials are read BEFORE textures, so a material naming a texture has to be able to
	/// point at one that has no pixels yet. LoadTextures fills these in afterwards.
	private int32 TextureIndex(ufbx_texture* texture, ModelData model)
	{
		if (texture == null)
			return -1;

		let typedId = texture.element.typed_id;
		if (mTextureToIndex.TryGetValue(typedId, let existing))
			return existing;

		let modelTexture = new ModelTexture();
		AppendUfbx(modelTexture.Name, texture.element.name);
		let index = model.AddTexture(modelTexture);
		mTextureToIndex[typedId] = index;
		return index;
	}

	// --------------------------------------------------------------- textures

	private void LoadTextures(ModelData model)
	{
		for (int i < (int)mScene.textures.count)
		{
			let source = mScene.textures.data[i];
			let typedId = source.element.typed_id;

			// A material may already have created the entry; otherwise this is its first
			// mention and it gets one now.
			ModelTexture texture;
			if (mTextureToIndex.TryGetValue(typedId, let existing))
			{
				texture = model.Textures[existing];
			}
			else
			{
				texture = new ModelTexture();
				AppendUfbx(texture.Name, source.element.name);
				mTextureToIndex[typedId] = model.AddTexture(texture);
			}

			if ((source.content.size > 0) && (source.content.data != null))
			{
				// Carried inside the file, which is how a single file FBX ships.
				let embedded = scope Image();
				if (ImageIO.LoadImageFromMemory(.((uint8*)source.content.data, (int)source.content.size),
					embedded) case .Ok)
					StoreImageData(embedded, texture);
			}
			else if (source.has_file)
			{
				ResolveExternalImage(source, texture);
			}

			// Every texture gets its own sampler, because FBX carries the wrap mode on the
			// texture rather than on a shared sampler the way glTF does.
			var sampler = TextureSampler();
			sampler.WrapS = WrapFrom(source.wrap_u);
			sampler.WrapT = WrapFrom(source.wrap_v);
			texture.SamplerIndex = model.AddSampler(sampler);
		}
	}

	/// Finds an image the file points at, which is rarely where it says it is.
	///
	/// An FBX records the path the artist's machine used, so the recorded path, the bare
	/// filename beside the model, and then a walk up the parent directories are all tried.
	/// Content moves between machines and the reference does not follow it; refusing to
	/// look would mean most FBX files load untextured.
	private void ResolveExternalImage(ufbx_texture* source, ModelTexture texture)
	{
		let relative = scope String();
		AppendUfbx(relative, source.relative_filename);
		let candidate = scope String();

		// A file that records no relative name at all still has the absolute one below.
		if (!relative.IsEmpty)
		{
			// As recorded, relative to the model.
			PathJoin(mBasePath, relative, candidate);
			if (TryLoadInto(candidate, texture))
				return;

			// Just the filename, beside the model: the usual case when a project has been
			// copied and the directories above it differ.
			let filename = scope String();
			PathFilename(relative, filename);
			if (!filename.IsEmpty)
			{
				candidate.Clear();
				PathJoin(mBasePath, filename, candidate);
				if (TryLoadInto(candidate, texture))
					return;
			}

			// Then upwards, a few levels: a textures directory beside the models directory is
			// the common layout, and the recorded path is relative to the project root.
			let searchDir = scope String(mBasePath);
			for (int depth < cParentSearchDepth)
			{
				let parent = scope:: String();
				PathParent(searchDir, parent);
				if (parent.IsEmpty || (parent == searchDir))
					break;

				candidate.Clear();
				PathJoin(parent, relative, candidate);
				if (TryLoadInto(candidate, texture))
					return;

				searchDir.Set(parent);
			}
		}

		// Last, the absolute name. ufbx resolves the recorded path against the file it came
		// from and normalises it, so this is usually the one that lands when the content sits
		// where the model says it does and only the separators were foreign.
		let absolute = scope String();
		AppendUfbx(absolute, source.filename);
		if (!absolute.IsEmpty)
			TryLoadInto(absolute, texture);
	}

	/// How far up to look for a texture the recorded path does not find. Bounded, because
	/// an unbounded walk of a deep tree costs a stat per level per texture.
	private const int cParentSearchDepth = 5;

	/// Takes the file at `path`: a DDS stays UNDECODED, being GPU ready, so the pipeline
	/// passes its levels through from the file; anything else decodes here.
	private bool TryLoadInto(StringView path, ModelTexture texture)
	{
		if (!FileExists(path))
			return false;

		if (Dds.IsDdsFile(path))
		{
			texture.SourceFile.Set(path);
		}
		else
		{
			let image = scope Image();
			if (!(ImageIO.LoadImage(path, image) case .Ok))
				return false;
			StoreImageData(image, texture);
		}

		// Recorded so a later step can tell two textures apart by where they came from,
		// which is how the importer avoids importing one image twice.
		texture.Uri.Set(path);
		return true;
	}

	private static void StoreImageData(Image image, ModelTexture texture)
	{
		texture.Width = (int32)image.Width;
		texture.Height = (int32)image.Height;
		texture.PixelFormat = PixelFormatFrom(image.Format);

		let pixels = image.PixelData;
		if ((pixels.Ptr != null) && (pixels.Length > 0))
			texture.SetData(pixels);
	}

	private static TexturePixelFormat PixelFormatFrom(PixelFormat format)
	{
		switch (format)
		{
		case .R8: return .R8;
		case .RG8: return .RG8;
		case .RGB8: return .RGB8;
		case .RGBA8: return .RGBA8;
		case .BGR8: return .BGR8;
		case .BGRA8: return .BGRA8;
		default: return .Unknown;
		}
	}

	private static TextureWrap WrapFrom(ufbx_wrap_mode mode)
	{
		switch (mode)
		{
		case .UFBX_WRAP_CLAMP: return .ClampToEdge;
		default: return .Repeat;
		}
	}

	// ---------------------------------------------------------- alpha detection

	/// Works out which materials need blending by LOOKING at their base colour texture.
	///
	/// FBX has no alpha mode the way glTF does, so a cutout leaf and an opaque wall are
	/// indistinguishable from the material alone. Scanning the alpha channel is what other
	/// engines do too, and getting it wrong means either sorting everything (slow) or
	/// drawing foliage as opaque rectangles (visibly wrong).
	private static void DetectAlphaFromTextures(ModelData model)
	{
		for (let material in model.Materials)
		{
			// A material that already said what it wants is left alone.
			if (material.AlphaMode != .Opaque)
				continue;
			if ((material.BaseColorTextureIndex < 0)
				|| (material.BaseColorTextureIndex >= (int32)model.Textures.Length))
				continue;

			let texture = model.Textures[material.BaseColorTextureIndex];
			if (!texture.HasEmbeddedData)
				continue;

			// Only a format that HAS an alpha channel can say anything about alpha.
			let bytesPerPixel = BytesPerPixelOf(texture.PixelFormat);
			if (bytesPerPixel != 4)
				continue;
			let alphaOffset = AlphaOffsetOf(texture.PixelFormat);
			if (alphaOffset < 0)
				continue;

			let pixelCount = (int)texture.Width * (int)texture.Height;
			if ((pixelCount * bytesPerPixel) > texture.DataSize)
				continue; // A truncated texture says nothing.

			let data = texture.Data;
			int transparent = 0;
			int gradient = 0;
			for (int p < pixelCount)
			{
				let alpha = data[p * bytesPerPixel + alphaOffset];
				if (alpha == 255) {}
				else if (alpha == 0) transparent++;
				else gradient++;
			}

			if ((transparent == 0) && (gradient == 0))
				continue; // Every pixel is opaque, so it is an opaque material.

			// Mostly partial alpha means real translucency, which needs blending and the
			// sorting that comes with it. A hard edge between opaque and clear is a cutout,
			// which masks instead and stays cheap.
			let gradientRatio = (float)gradient / (float)pixelCount;
			if (gradientRatio > 0.25f)
			{
				material.AlphaMode = .Blend;
			}
			else
			{
				material.AlphaMode = .Mask;
				material.AlphaCutoff = 0.2f;
			}
		}
	}

	private static int BytesPerPixelOf(TexturePixelFormat format)
	{
		switch (format)
		{
		case .RGBA8, .BGRA8: return 4;
		case .RGB8, .BGR8: return 3;
		case .RG8: return 2;
		case .R8: return 1;
		default: return 0;
		}
	}

	/// Where the alpha byte sits, or -1 when the format has none. Both RGBA and BGRA put it
	/// last: only the colour order differs.
	private static int AlphaOffsetOf(TexturePixelFormat format)
	{
		switch (format)
		{
		case .RGBA8, .BGRA8: return 3;
		default: return -1;
		}
	}

	// ----------------------------------------------------------------- meshes

	private void LoadMeshes(ModelData model)
	{
		for (int i < (int)mScene.meshes.count)
		{
			let source = mScene.meshes.data[i];
			let mesh = new ModelMesh();
			AppendUfbx(mesh.Name, source.element.name);

			BuildMesh(source, mesh);

			mesh.Topology = .Triangles;
			mesh.CalculateBounds();
			mMeshToIndex[source.element.typed_id] = model.AddMesh(mesh);
		}
	}

	/// Triangulates, deduplicates and indexes one FBX mesh.
	///
	/// FBX stores geometry per FACE CORNER: a cube has twenty four corners for its eight
	/// positions, because each corner carries its own normal. A GPU wants unique vertices
	/// and an index buffer, so every corner is built, compared against what has been built
	/// already, and either reused or appended. That is what collapses the cube back to
	/// twenty four (a cube genuinely needs them, its normals all differ) while a smooth
	/// sphere collapses to nearly its position count.
	private void BuildMesh(ufbx_mesh* source, ModelMesh mesh)
	{
		let isSkinned = source.skin_deformers.count > 0;
		let skin = isSkinned ? source.skin_deformers.data[0] : null;

		// Normals are always present because the load asked ufbx to generate any that were
		// missing, which is cheaper and more correct than doing it here.
		let hasNormals = source.vertex_normal.exists;
		let hasUv = (source.uv_sets.count > 0) && source.uv_sets.data[0].vertex_uv.exists;
		let hasTangent = (source.uv_sets.count > 0) && source.uv_sets.data[0].vertex_tangent.exists;
		// Either the modern per set colours or the legacy single set: an older file has
		// only the latter.
		let hasColor = ((source.color_sets.count > 0) && source.color_sets.data[0].vertex_color.exists)
			|| source.vertex_color.exists;

		mesh.HasNormals = hasNormals;
		mesh.HasTangents = hasTangent;

		// The same layout the glTF loader builds, so one shader serves both.
		var layout = VertexLayout();
		layout.PositionOffset = layout.Stride;
		layout.Stride += (int32)sizeof(Float3);
		mesh.AddVertexElement(.(.Position, .Float3, layout.PositionOffset));

		layout.NormalOffset = layout.Stride;
		layout.Stride += (int32)sizeof(Float3);
		mesh.AddVertexElement(.(.Normal, .Float3, layout.NormalOffset));

		layout.TexCoordOffset = layout.Stride;
		layout.Stride += (int32)sizeof(Float2);
		mesh.AddVertexElement(.(.TexCoord, .Float2, layout.TexCoordOffset));

		layout.ColorOffset = layout.Stride;
		layout.Stride += (int32)sizeof(uint32);
		mesh.AddVertexElement(.(.Color, .Byte4, layout.ColorOffset));

		layout.TangentOffset = layout.Stride;
		layout.Stride += (int32)sizeof(Float4);
		mesh.AddVertexElement(.(.Tangent, .Float4, layout.TangentOffset));

		if (isSkinned)
		{
			layout.JointsOffset = layout.Stride;
			layout.Stride += (int32)(sizeof(uint16) * 4);
			mesh.AddVertexElement(.(.Joints, .UShort4, layout.JointsOffset));

			layout.WeightsOffset = layout.Stride;
			layout.Stride += (int32)sizeof(Float4);
			mesh.AddVertexElement(.(.Weights, .Float4, layout.WeightsOffset));
		}
		layout.IsSkinned = isSkinned;
		layout.HasUv = hasUv;
		layout.HasTangent = hasTangent;
		layout.HasColor = hasColor;

		let vertexBytes = scope List<uint8>();
		let indices = scope List<uint32>();

		// Hash to the vertices that hashed there. The bytes are then compared for real, so
		// a collision costs a comparison rather than silently welding two different
		// vertices into one, which shows up as a pulled seam nobody can trace.
		let buckets = scope Dictionary<int, List<int32>>();
		defer
		{
			for (let bucket in buckets)
				delete bucket.value;
		}

		// ufbx triangulates into a caller supplied buffer, sized for the worst face in the
		// mesh.
		let maxTriangleIndices = (int)source.max_face_triangles * 3;
		let triangleIndices = scope List<uint32>();
		triangleIndices.Resize(maxTriangleIndices > 0 ? maxTriangleIndices : 3);

		if (source.material_parts.count > 0)
		{
			// One part per material, which is what lets a mesh be drawn in several calls
			// with different materials.
			for (int p < (int)source.material_parts.count)
			{
				let part = &source.material_parts.data[p];
				let indexStart = (int32)indices.Count;
				int32 indexCount = 0;

				int32 materialIndex = -1;
				if (part.index < (uint32)source.materials.count)
				{
					let material = source.materials.data[part.index];
					if ((material != null) && mMaterialToIndex.TryGetValue(material.element.typed_id, let found))
						materialIndex = found;
				}

				for (int f < (int)part.face_indices.count)
				{
					let face = source.faces.data[part.face_indices.data[f]];
					indexCount += EmitFace(source, face, skin, layout, triangleIndices,
						vertexBytes, indices, buckets);
				}

				if (indexCount > 0)
					mesh.AddPart(.(indexStart, indexCount, materialIndex));
			}
		}
		else
		{
			// No material at all: one part covering everything, with no material index.
			int32 indexCount = 0;
			for (int f < (int)source.faces.count)
			{
				indexCount += EmitFace(source, source.faces.data[f], skin, layout,
					triangleIndices, vertexBytes, indices, buckets);
			}
			if (indexCount > 0)
				mesh.AddPart(.(0, indexCount, -1));
		}

		let vertexCount = (int32)(vertexBytes.Count / layout.Stride);
		if (vertexCount > 0)
		{
			mesh.AllocateVertices(vertexCount, layout.Stride);
			Internal.MemCpy(mesh.VertexData, vertexBytes.Ptr, vertexBytes.Count);
		}

		let indexCount = (int32)indices.Count;
		if (indexCount > 0)
		{
			// Widened on either count: a mesh can have few vertices and many indices, or
			// the other way round.
			let use32Bit = (indexCount > 65535) || (vertexCount > 65535);
			mesh.AllocateIndices(indexCount, use32Bit);
			if (use32Bit)
			{
				Internal.MemCpy(mesh.IndexData, indices.Ptr, indexCount * 4);
			}
			else
			{
				let destination = (uint16*)mesh.IndexData;
				for (int32 i = 0; i < indexCount; i++)
					destination[i] = (uint16)indices[i];
			}
		}
	}

	/// Triangulates one face and appends its vertices. Returns how many indices it added.
	private int32 EmitFace(ufbx_mesh* source, ufbx_face face, ufbx_skin_deformer* skin,
		VertexLayout layout, List<uint32> triangleIndices, List<uint8> vertexBytes,
		List<uint32> indices, Dictionary<int, List<int32>> buckets)
	{
		let triangleCount = ufbx_Beef.ufbx_triangulate_face(triangleIndices.Ptr,
			(uint)triangleIndices.Count, source, face);

		int32 emitted = 0;
		for (uint32 i = 0; i < triangleCount * 3; i++)
		{
			let corner = (int)triangleIndices[(int)i];
			indices.Add((uint32)AddVertex(source, corner, skin, layout, vertexBytes, buckets));
			emitted++;
		}
		return emitted;
	}

	// ---------------------------------------------------------------- vertices

	/// Builds the vertex for one face corner and returns its index, reusing an identical
	/// one already built.
	private int32 AddVertex(ufbx_mesh* source, int corner, ufbx_skin_deformer* skin,
		VertexLayout layout, List<uint8> vertexBytes, Dictionary<int, List<int32>> buckets)
	{
		let position = ReadVec3(source.vertex_position, corner);
		let normal = source.vertex_normal.exists
			? ReadVec3(source.vertex_normal, corner) : ufbx_vec3() { x = 0, y = 1, z = 0 };

		var u = 0.0f;
		var v = 0.0f;
		if (layout.HasUv)
		{
			let uv = ReadVec2(source.uv_sets.data[0].vertex_uv, corner);
			u = (float)uv.x;
			// FBX puts V zero at the BOTTOM; glTF and the renderer put it at the top. Not
			// flipping shows as every texture upside down.
			v = 1.0f - (float)uv.y;
		}

		var tangent = Float4(1, 0, 0, 1);
		if (layout.HasTangent)
		{
			let t = ReadVec3(source.uv_sets.data[0].vertex_tangent, corner);
			tangent = .((float)t.x, (float)t.y, (float)t.z, 1.0f);

			// The fourth component is TBN handedness, worked out from ufbx's bitangent:
			// mirrored UVs give a bitangent that opposes the cross product, and without the
			// sign the normal map lights inverted on the mirrored half of a model.
			if (source.uv_sets.data[0].vertex_bitangent.exists)
			{
				let b = ReadVec3(source.uv_sets.data[0].vertex_bitangent, corner);
				let n = Float3((float)normal.x, (float)normal.y, (float)normal.z);
				let tv = Float3(tangent.X, tangent.Y, tangent.Z);
				let bv = Float3((float)b.x, (float)b.y, (float)b.z);
				if (Dot(Cross(n, tv), bv) < 0.0f)
					tangent.W = -1.0f;
			}
		}

		var color = Float4(1, 1, 1, 1);
		if (layout.HasColor)
		{
			if ((source.color_sets.count > 0) && source.color_sets.data[0].vertex_color.exists)
			{
				let c = ReadVec4(source.color_sets.data[0].vertex_color, corner);
				color = .((float)c.x, (float)c.y, (float)c.z, (float)c.w);
			}
			else if (source.vertex_color.exists)
			{
				let c = ReadVec4(source.vertex_color, corner);
				color = .((float)c.x, (float)c.y, (float)c.z, (float)c.w);
			}
		}

		uint16[4] joints = .(0, 0, 0, 0);
		float[4] weights = .(0, 0, 0, 0);
		if (layout.IsSkinned && (skin != null))
		{
			// Skinning is per VERTEX, not per corner: several corners of one position share
			// its weights.
			let vertexIndex = (int)source.vertex_indices.data[corner];
			ReadSkinWeights(skin, vertexIndex, ref joints, ref weights);
		}

		// Built into a scratch buffer first, so the bytes can be compared against what is
		// already there before deciding whether to keep them.
		let candidate = scope uint8[layout.Stride];
		let vertex = &candidate[0];

		*(Float3*)(vertex + layout.PositionOffset) = .((float)position.x, (float)position.y, (float)position.z);
		*(Float3*)(vertex + layout.NormalOffset) = .((float)normal.x, (float)normal.y, (float)normal.z);
		*(Float2*)(vertex + layout.TexCoordOffset) = .(u, v);

		let r = (uint32)Clamp(color.X * 255.0f, 0.0f, 255.0f);
		let g = (uint32)Clamp(color.Y * 255.0f, 0.0f, 255.0f);
		let b = (uint32)Clamp(color.Z * 255.0f, 0.0f, 255.0f);
		let a = (uint32)Clamp(color.W * 255.0f, 0.0f, 255.0f);
		*(uint32*)(vertex + layout.ColorOffset) = r | (g << 8) | (b << 16) | (a << 24);

		*(Float4*)(vertex + layout.TangentOffset) = tangent;

		if (layout.IsSkinned)
		{
			let jointsDestination = (uint16*)(vertex + layout.JointsOffset);
			for (int i < 4)
				jointsDestination[i] = joints[i];
			*(Float4*)(vertex + layout.WeightsOffset) = .(weights[0], weights[1], weights[2], weights[3]);
		}

		// Compared by BYTES, not by hash.
		//
		// Keying on the hash alone welds two genuinely different vertices whenever their
		// hashes collide. That is rare and, when it happens, shows up as a pulled seam that
		// no amount of staring at the source file explains. Hashing to a bucket and then
		// comparing costs one comparison and cannot do that. The loader was keyed on the hash
		// alone once, and the seam is how it was found.
		let hash = (int)HashBytes(vertex, layout.Stride);
		if (buckets.TryGetValue(hash, let existing))
		{
			for (let index in existing)
			{
				let other = &vertexBytes[(int)index * layout.Stride];
				if (Internal.MemCmp(vertex, other, layout.Stride) == 0)
					return index;
			}
		}

		let newIndex = (int32)(vertexBytes.Count / layout.Stride);
		vertexBytes.AddRange(.(vertex, layout.Stride));

		if (!buckets.ContainsKey(hash))
			buckets[hash] = new List<int32>();
		buckets[hash].Add(newIndex);
		return newIndex;
	}

	/// The four heaviest influences on a vertex, normalised.
	///
	/// A vertex can be bound to more bones than the four a GPU skin has room for, so the
	/// strongest four are kept and renormalised. Dropping the rest without renormalising
	/// would shrink the vertex toward the origin, because the weights would no longer sum
	/// to one.
	private static void ReadSkinWeights(ufbx_skin_deformer* skin, int vertexIndex,
		ref uint16[4] joints, ref float[4] weights)
	{
		if (vertexIndex >= (int)skin.vertices.count)
			return;

		let skinVertex = &skin.vertices.data[vertexIndex];
		let available = (int)skinVertex.num_weights;
		if (available == 0)
			return;

		// Bounded: an exporter can bind a vertex to a great many bones, and only the
		// heaviest few can matter once four are kept.
		let considered = Math.Min(available, cMaxConsideredWeights);
		let candidateJoints = scope uint16[cMaxConsideredWeights];
		let candidateWeights = scope float[cMaxConsideredWeights];

		for (int w < considered)
		{
			let entry = &skin.weights.data[skinVertex.weight_begin + (uint32)w];
			// The CLUSTER index is the joint index: a skin's clusters are its joints, in
			// the order the skin lists them, which is the order LoadSkins records.
			candidateJoints[w] = (uint16)entry.cluster_index;
			candidateWeights[w] = (float)entry.weight;
		}

		// A partial selection sort: only the top four are needed, so the rest is not worth
		// ordering.
		let keep = Math.Min(considered, 4);
		for (int a < keep)
		{
			int heaviest = a;
			for (int b = a + 1; b < considered; b++)
			{
				if (candidateWeights[b] > candidateWeights[heaviest])
					heaviest = b;
			}
			if (heaviest != a)
			{
				Swap!(candidateJoints[a], candidateJoints[heaviest]);
				Swap!(candidateWeights[a], candidateWeights[heaviest]);
			}
			joints[a] = candidateJoints[a];
			weights[a] = candidateWeights[a];
		}

		let sum = weights[0] + weights[1] + weights[2] + weights[3];
		if (sum > 0)
		{
			let inverse = 1.0f / sum;
			for (int i < 4)
				weights[i] *= inverse;
		}
	}

	private const int cMaxConsideredWeights = 16;

	/// ufbx attributes are indirect: an index buffer into a value buffer, so a value shared
	/// by several corners is stored once.
	private static ufbx_vec3 ReadVec3(ufbx_vertex_vec3 attribute, int index)
		=> attribute.values.data[attribute.indices.data[index]];

	private static ufbx_vec2 ReadVec2(ufbx_vertex_vec2 attribute, int index)
		=> attribute.values.data[attribute.indices.data[index]];

	private static ufbx_vec4 ReadVec4(ufbx_vertex_vec4 attribute, int index)
		=> attribute.values.data[attribute.indices.data[index]];

	// ------------------------------------------------------------------ nodes

	private void LoadNodes(ModelData model)
	{
		// Bones first, parents after: a node's parent can appear later in the file.
		for (int i < (int)mScene.nodes.count)
		{
			let node = mScene.nodes.data[i];
			let bone = new ModelBone();
			AppendUfbx(bone.Name, node.element.name);

			// ufbx has already decomposed the local transform, including the Euler order
			// and the pre and post rotations FBX carries separately.
			let t = node.local_transform;
			bone.Translation = .((float)t.translation.x, (float)t.translation.y, (float)t.translation.z);
			bone.Rotation = .((float)t.rotation.x, (float)t.rotation.y, (float)t.rotation.z, (float)t.rotation.w);
			bone.Scale = .((float)t.scale.x, (float)t.scale.y, (float)t.scale.z);
			bone.UpdateLocalTransform();

			if (node.mesh != null)
			{
				if (mMeshToIndex.TryGetValue(node.mesh.element.typed_id, let meshIndex))
					bone.MeshIndex = meshIndex;
			}

			mNodeToBone[node.element.typed_id] = model.AddBone(bone);
		}

		for (int i < (int)mScene.nodes.count)
		{
			let node = mScene.nodes.data[i];
			if (node.parent == null)
				continue;
			if (mNodeToBone.TryGetValue(node.parent.element.typed_id, let parentIndex)
				&& mNodeToBone.TryGetValue(node.element.typed_id, let selfIndex))
				model.Bones[selfIndex].ParentIndex = parentIndex;
		}
	}

	// ------------------------------------------------------------------ skins

	private void LoadSkins(ModelData model)
	{
		for (int i < (int)mScene.skin_deformers.count)
		{
			let source = mScene.skin_deformers.data[i];
			let skin = new ModelSkin();
			AppendUfbx(skin.Name, source.element.name);

			for (int j < (int)source.clusters.count)
			{
				let cluster = source.clusters.data[j];
				if ((cluster == null) || (cluster.bone_node == null))
					continue;
				if (!mNodeToBone.TryGetValue(cluster.bone_node.element.typed_id, let jointIndex))
					continue;

				// geometry_to_bone IS the inverse bind matrix: it takes a vertex from the
				// mesh's space into the bone's, which is what skinning multiplies by.
				let inverseBind = ConvertMatrix(cluster.geometry_to_bone);
				skin.AddJoint(jointIndex, inverseBind);

				// Also onto the bone, so skinning code that walks bones rather than the
				// skin has it to hand.
				if (jointIndex < (int32)model.Bones.Length)
					model.Bones[jointIndex].InverseBindMatrix = inverseBind;
			}

			mSkinToIndex[source.element.typed_id] = model.AddSkin(skin);
		}

		// The bones were built before the skins existed, so their skin indices are filled
		// in now.
		for (int i < (int)mScene.nodes.count)
		{
			let node = mScene.nodes.data[i];
			if ((node.mesh == null) || (node.mesh.skin_deformers.count == 0))
				continue;
			let deformer = node.mesh.skin_deformers.data[0];
			if (mSkinToIndex.TryGetValue(deformer.element.typed_id, let skinIndex)
				&& mNodeToBone.TryGetValue(node.element.typed_id, let boneIndex))
				model.Bones[boneIndex].SkinIndex = skinIndex;
		}
	}

	// ------------------------------------------------------------- animations

	private void LoadAnimations(ModelData model)
	{
		for (int i < (int)mScene.anim_stacks.count)
		{
			let stack = mScene.anim_stacks.data[i];
			let animation = new ModelAnimation();
			AppendUfbx(animation.Name, stack.element.name);

			// BAKED rather than read as curves. FBX animation is layers of Euler curves
			// with their own pre and post rotations and their own interpolation; baking
			// hands back plain TRS keys in the target space, with the layer blending and
			// the Euler to quaternion conversion already done. Doing that here would be
			// reimplementing ufbx badly.
			var bakeOptions = ufbx_bake_opts();
			bakeOptions.resample_rate = cAnimationSampleRate;
			bakeOptions.minimum_sample_rate = cAnimationSampleRate;
			bakeOptions.max_keyframe_segments = 1024;

			ufbx_error bakeError = default;
			let baked = ufbx_Beef.ufbx_bake_anim(mScene, stack.anim, &bakeOptions, &bakeError);
			if (baked == null)
			{
				// A stack that will not bake is skipped rather than failing the load: the
				// rest of the model is still worth having.
				delete animation;
				continue;
			}
			defer ufbx_Beef.ufbx_free_baked_anim(baked);

			for (int n < (int)baked.nodes.count)
			{
				let node = &baked.nodes.data[n];
				if (!mNodeToBone.TryGetValue(node.typed_id, let boneIndex))
					continue;

				// A CONSTANT channel is dropped: a bone that never moves does not need
				// keyframes, and every one kept costs sampling work every frame.
				if ((node.translation_keys.count > 0) && !node.constant_translation)
				{
					let channel = new AnimationChannel();
					channel.TargetBone = boneIndex;
					channel.Path = .Translation;
					channel.Interpolation = InterpolationOfVec3(node.translation_keys);
					for (int k < (int)node.translation_keys.count)
					{
						let key = &node.translation_keys.data[k];
						channel.AddKeyframe((float)key.time,
							.((float)key.value.x, (float)key.value.y, (float)key.value.z, 0));
					}
					animation.AddChannel(channel);
				}

				if ((node.rotation_keys.count > 0) && !node.constant_rotation)
				{
					let channel = new AnimationChannel();
					channel.TargetBone = boneIndex;
					channel.Path = .Rotation;
					channel.Interpolation = InterpolationOfQuat(node.rotation_keys);
					for (int k < (int)node.rotation_keys.count)
					{
						let key = &node.rotation_keys.data[k];
						channel.AddKeyframe((float)key.time,
							.((float)key.value.x, (float)key.value.y, (float)key.value.z, (float)key.value.w));
					}
					animation.AddChannel(channel);
				}

				if ((node.scale_keys.count > 0) && !node.constant_scale)
				{
					let channel = new AnimationChannel();
					channel.TargetBone = boneIndex;
					channel.Path = .Scale;
					channel.Interpolation = InterpolationOfVec3(node.scale_keys);
					for (int k < (int)node.scale_keys.count)
					{
						let key = &node.scale_keys.data[k];
						channel.AddKeyframe((float)key.time,
							.((float)key.value.x, (float)key.value.y, (float)key.value.z, 0));
					}
					animation.AddChannel(channel);
				}
			}

			animation.CalculateDuration();
			model.AddAnimation(animation);
		}
	}

	/// Thirty hertz. Fine enough for the character motion FBX usually carries, and coarse
	/// enough that a long take does not become tens of thousands of keys per bone.
	private const double cAnimationSampleRate = 30.0;

	/// Stepped if ANY key says so.
	///
	/// The channel carries one interpolation for all of its keys, so a take that steps
	/// anywhere has to step throughout: interpolating a step produces motion the animator
	/// did not author, which is worse than stepping one that was smooth.
	private static AnimationInterpolation InterpolationOfVec3(ufbx_baked_vec3_list keys)
	{
		for (int i < (int)keys.count)
		{
			if ((keys.data[i].flags & (.UFBX_BAKED_KEY_STEP_LEFT | .UFBX_BAKED_KEY_STEP_RIGHT)) != 0)
				return .Step;
		}
		return .Linear;
	}

	private static AnimationInterpolation InterpolationOfQuat(ufbx_baked_quat_list keys)
	{
		for (int i < (int)keys.count)
		{
			if ((keys.data[i].flags & (.UFBX_BAKED_KEY_STEP_LEFT | .UFBX_BAKED_KEY_STEP_RIGHT)) != 0)
				return .Step;
		}
		return .Linear;
	}

	/// ufbx's three by four, transposed into the row vector convention.
	///
	/// ufbx names its elements column first, so its column becomes a row here, and the
	/// translation lands in the last row. That is the same transpose the glTF loader does
	/// by copying a column major array straight into row major storage.
	private static Float4x4 ConvertMatrix(ufbx_matrix m)
	{
		return .(
			(float)m.m00, (float)m.m10, (float)m.m20, 0,
			(float)m.m01, (float)m.m11, (float)m.m21, 0,
			(float)m.m02, (float)m.m12, (float)m.m22, 0,
			(float)m.m03, (float)m.m13, (float)m.m23, 1);
	}
}
