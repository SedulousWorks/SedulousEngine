using System;
using System.IO;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Models;
using ufbx_Beef;
using Sedulous.Images;

namespace Sedulous.Models.FBX;

/// Loads FBX model files using ufbx
public class FbxLoader : IModelLoader
{
	private static StringView[?] sSupportedExtensions = .(".fbx", ".obj");

	private ufbx_scene* mScene;
	private String mBasePath ~ delete _;

	/// Node typed_id -> model bone index
	private Dictionary<uint32, int32> mNodeToBoneIndex ~ delete _;

	/// Material typed_id -> model material index
	private Dictionary<uint32, int32> mMaterialIndexMap ~ delete _;

	/// Texture typed_id -> model texture index
	private Dictionary<uint32, int32> mTextureIndexMap ~ delete _;

	/// Mesh typed_id -> model mesh index
	private Dictionary<uint32, int32> mMeshIndexMap ~ delete _;

	/// Skin deformer typed_id -> model skin index
	private Dictionary<uint32, int32> mSkinIndexMap ~ delete _;

	/// Tracks load options for use in mesh loading
	private ufbx_load_opts mLoadOpts;

	public this()
	{
		mBasePath = new String();
		mNodeToBoneIndex = new Dictionary<uint32, int32>();
		mMaterialIndexMap = new Dictionary<uint32, int32>();
		mTextureIndexMap = new Dictionary<uint32, int32>();
		mMeshIndexMap = new Dictionary<uint32, int32>();
		mSkinIndexMap = new Dictionary<uint32, int32>();
	}

	public ~this()
	{
		if (mScene != null)
		{
			ufbx_free_scene(mScene);
			mScene = null;
		}
	}

	/// File extensions this loader supports.
	public Span<StringView> SupportedExtensions => .(&sSupportedExtensions, sSupportedExtensions.Count);

	/// Check if this loader supports the given file extension.
	public bool SupportsExtension(StringView fileExtension)
	{
		for (let ext in sSupportedExtensions)
		{
			if (fileExtension.Equals(ext, true))
				return true;
		}
		return false;
	}

	/// Load an FBX file
	public ModelLoadResult Load(StringView path, Model model)
	{
		// Free previous scene
		if (mScene != null)
		{
			ufbx_free_scene(mScene);
			mScene = null;
		}

		// Clear mappings
		mNodeToBoneIndex.Clear();
		mMaterialIndexMap.Clear();
		mTextureIndexMap.Clear();
		mMeshIndexMap.Clear();
		mSkinIndexMap.Clear();

		// Extract base path for loading external resources
		mBasePath.Clear();
		Path.GetDirectoryPath(path, mBasePath);

		// Setup load options
		mLoadOpts = .();
		mLoadOpts.target_axes = ufbx_axes_right_handed_y_up;
		mLoadOpts.target_unit_meters = 1.0;
		mLoadOpts.space_conversion = .UFBX_SPACE_CONVERSION_MODIFY_GEOMETRY;
		mLoadOpts.geometry_transform_handling = .UFBX_GEOMETRY_TRANSFORM_HANDLING_MODIFY_GEOMETRY_NO_FALLBACK;
		mLoadOpts.generate_missing_normals = true;
		mLoadOpts.clean_skin_weights = true;
		mLoadOpts.use_blender_pbr_material = true;

		// Parse the file
		ufbx_error error = .();
		let pathStr = path.ToScopeCStr!();
		mScene = ufbx_load_file(pathStr, &mLoadOpts, &error);

		if (mScene == null)
		{
			if (error.type == .UFBX_ERROR_FILE_NOT_FOUND)
				return .FileNotFound;
			if (error.type == .UFBX_ERROR_UNSUPPORTED_VERSION)
				return .UnsupportedVersion;
			return .ParseError;
		}

		// With MODIFY_GEOMETRY, ufbx converts everything to Y-up already.
		model.OriginalUpAxis = .PositiveY;

		// Convert to Model
		LoadMaterials(model);
		LoadTextures(model);
		LoadMeshes(model);
		LoadNodes(model);
		LoadSkins(model);
		LoadAnimations(model);

		model.BuildBoneHierarchy();
		model.CalculateBounds();

		return .Ok;
	}

	// ===== Materials =====

	private void LoadMaterials(Model model)
	{
		for (int i = 0; i < (int)mScene.materials.count; i++)
		{
			let mat = mScene.materials.data[i];
			let material = new ModelMaterial();

			if (mat.element.name.data != null && mat.element.name.length > 0)
				material.SetName(StringView(mat.element.name.data, (int)mat.element.name.length));

			// Check if material has PBR maps
			bool hasPBR = mat.features.pbr.enabled;

			if (hasPBR)
			{
				// PBR: base color
				if (mat.pbr.base_color.has_value)
				{
					let c = mat.pbr.base_color.value_vec4;
					material.BaseColorFactor = .((float)c.x, (float)c.y, (float)c.z, (float)c.w);
				}
				if (mat.pbr.base_color.texture != null)
				{
					material.BaseColorTextureIndex = GetOrCreateTextureIndex(mat.pbr.base_color.texture, model);
					// When using use_blender_pbr_material, the base_color value is often the
					// legacy diffuse color (0.8,0.8,0.8) which shouldn't tint the texture.
					material.BaseColorFactor = .(1.0f, 1.0f, 1.0f, 1.0f);
				}

				// PBR: metallic + roughness
				if (mat.pbr.metalness.has_value)
					material.MetallicFactor = (float)mat.pbr.metalness.value_real;
				if (mat.pbr.roughness.has_value)
					material.RoughnessFactor = (float)mat.pbr.roughness.value_real;

				// For metallic-roughness texture, check if metalness or roughness have the same texture
				if (mat.pbr.metalness.texture != null)
					material.MetallicRoughnessTextureIndex = GetOrCreateTextureIndex(mat.pbr.metalness.texture, model);
				else if (mat.pbr.roughness.texture != null)
					material.MetallicRoughnessTextureIndex = GetOrCreateTextureIndex(mat.pbr.roughness.texture, model);

				// PBR: normal map
				if (mat.pbr.normal_map.texture != null)
				{
					material.NormalTextureIndex = GetOrCreateTextureIndex(mat.pbr.normal_map.texture, model);
					material.NormalScale = 1.0f;
				}

				// PBR: ambient occlusion
				if (mat.pbr.ambient_occlusion.texture != null)
				{
					material.OcclusionTextureIndex = GetOrCreateTextureIndex(mat.pbr.ambient_occlusion.texture, model);
					material.OcclusionStrength = 1.0f;
				}

				// PBR: emissive
				if (mat.pbr.emission_color.has_value)
				{
					let e = mat.pbr.emission_color.value_vec3;
					float factor = mat.pbr.emission_factor.has_value ? (float)mat.pbr.emission_factor.value_real : 1.0f;
					material.EmissiveFactor = .((float)e.x * factor, (float)e.y * factor, (float)e.z * factor);
				}
				if (mat.pbr.emission_color.texture != null)
					material.EmissiveTextureIndex = GetOrCreateTextureIndex(mat.pbr.emission_color.texture, model);
			}
			else
			{
				// Legacy FBX (Lambert/Phong): map to PBR
				if (mat.fbx.diffuse_color.has_value)
				{
					let c = mat.fbx.diffuse_color.value_vec4;
					float factor = mat.fbx.diffuse_factor.has_value ? (float)mat.fbx.diffuse_factor.value_real : 1.0f;
					material.BaseColorFactor = .((float)c.x * factor, (float)c.y * factor, (float)c.z * factor, 1.0f);
				}
				if (mat.fbx.diffuse_color.texture != null)
				{
					material.BaseColorTextureIndex = GetOrCreateTextureIndex(mat.fbx.diffuse_color.texture, model);
					// When a diffuse texture is present, use white base color factor.
					// Legacy FBX materials often have a default diffuse color (e.g. 0.8,0.8,0.8)
					// that's not meant to tint the texture.
					material.BaseColorFactor = .(1.0f, 1.0f, 1.0f, 1.0f);
				}

				// Normal map
				if (mat.fbx.normal_map.texture != null)
				{
					material.NormalTextureIndex = GetOrCreateTextureIndex(mat.fbx.normal_map.texture, model);
					material.NormalScale = 1.0f;
				}

				// Emissive
				if (mat.fbx.emission_color.has_value)
				{
					let e = mat.fbx.emission_color.value_vec3;
					float factor = mat.fbx.emission_factor.has_value ? (float)mat.fbx.emission_factor.value_real : 1.0f;
					material.EmissiveFactor = .((float)e.x * factor, (float)e.y * factor, (float)e.z * factor);
				}
				if (mat.fbx.emission_color.texture != null)
					material.EmissiveTextureIndex = GetOrCreateTextureIndex(mat.fbx.emission_color.texture, model);

				// Non-PBR defaults
				material.MetallicFactor = 0.0f;
				material.RoughnessFactor = 0.8f;
			}

			// Double-sided: FBX format doesn't reliably carry the DoubleSided flag
			// from Blender. When not explicitly set in the file, default to true
			// to match the behavior of most GLTF exports and avoid incorrect culling.
			if (mat.features.double_sided.is_explicit)
				material.DoubleSided = mat.features.double_sided.enabled;
			else
				material.DoubleSided = true;

			// Alpha / opacity
			if (mat.features.opacity.enabled)
			{
				if (mat.pbr.opacity.has_value && (float)mat.pbr.opacity.value_real < 1.0f)
					material.AlphaMode = .Blend;
				else if (mat.fbx.transparency_factor.has_value && (float)mat.fbx.transparency_factor.value_real > 0.0f)
					material.AlphaMode = .Blend;
			}

			let matIndex = model.AddMaterial(material);
			mMaterialIndexMap[mat.element.typed_id] = matIndex;
		}
	}

	/// Gets or creates a model texture index for a ufbx texture.
	/// This allows materials to reference textures before LoadTextures runs.
	private int32 GetOrCreateTextureIndex(ufbx_texture* texture, Model model)
	{
		if (texture == null)
			return -1;

		let typedId = texture.element.typed_id;
		if (mTextureIndexMap.TryGetValue(typedId, let existing))
			return existing;

		// Create a placeholder texture entry that LoadTextures will populate
		let modelTex = new ModelTexture();
		if (texture.element.name.data != null && texture.element.name.length > 0)
			modelTex.SetName(StringView(texture.element.name.data, (int)texture.element.name.length));

		let index = model.AddTexture(modelTex);
		mTextureIndexMap[typedId] = index;
		return index;
	}

	// ===== Textures =====

	private void LoadTextures(Model model)
	{
		for (int i = 0; i < (int)mScene.textures.count; i++)
		{
			let tex = mScene.textures.data[i];
			let typedId = tex.element.typed_id;

			// Get or create the model texture
			ModelTexture modelTex = null;
			if (mTextureIndexMap.TryGetValue(typedId, let existingIdx))
			{
				modelTex = model.Textures[existingIdx];
			}
			else
			{
				modelTex = new ModelTexture();
				if (tex.element.name.data != null && tex.element.name.length > 0)
					modelTex.SetName(StringView(tex.element.name.data, (int)tex.element.name.length));
				let idx = model.AddTexture(modelTex);
				mTextureIndexMap[typedId] = idx;
			}

			// Try to load image data
			if (tex.content.size > 0 && tex.content.data != null)
			{
				// Embedded texture data
				let span = Span<uint8>((uint8*)tex.content.data, (int)tex.content.size);
				StringView formatHint = GetFormatHintFromFilename(tex);
				if (ImageLoaderFactory.LoadImageFromMemory(span, formatHint) case .Ok(let image))
				{
					StoreImageData(image, modelTex);
					delete image;
				}
			}
			else if (tex.has_file)
			{
				// External file — try relative path, then walk parent directories, then absolute
				StringView relPath = default;
				if (tex.relative_filename.data != null && tex.relative_filename.length > 0)
					relPath = StringView(tex.relative_filename.data, (int)tex.relative_filename.length);

/*
				StringView absFilename = default;
				if (tex.filename.data != null && tex.filename.length > 0)
					absFilename = StringView(tex.filename.data, (int)tex.filename.length);
*/

				Image loadedImage = null;

				if (relPath.Length > 0)
				{
					// Try basePath + relative path first
					let imagePath = scope String();
					Path.InternalCombine(imagePath, mBasePath, relPath);

					if (File.Exists(imagePath))
					{
						if (ImageLoaderFactory.LoadImage(imagePath) case .Ok(let image))
							loadedImage = image;
					}
					else
					{
						// Walk up parent directories (up to 5 levels) looking for the relative file
						let searchDir = scope String(mBasePath);
						for (int depth = 0; depth < 5 && loadedImage == null; depth++)
						{
							let parentDir = scope String();
							Path.GetDirectoryPath(searchDir, parentDir);
							if (parentDir.Length == 0 || parentDir == searchDir)
								break;

							let candidatePath = scope String();
							Path.InternalCombine(candidatePath, parentDir, relPath);
							if (File.Exists(candidatePath))
							{
								if (ImageLoaderFactory.LoadImage(candidatePath) case .Ok(let image))
									loadedImage = image;
							}

							searchDir.Set(parentDir);
						}
					}
				}

				// Fallback: try absolute filename path
				if (loadedImage == null && tex.filename.data != null && tex.filename.length > 0)
				{
					let absPath = StringView(tex.filename.data, (int)tex.filename.length);
					if (ImageLoaderFactory.LoadImage(absPath) case .Ok(let image))
						loadedImage = image;
				}

				if (loadedImage != null)
				{
					StoreImageData(loadedImage, modelTex);
					delete loadedImage;
				}
			}

			// Sampler / wrap mode
			TextureSampler sampler = .();
			sampler.WrapS = ConvertWrapMode(tex.wrap_u);
			sampler.WrapT = ConvertWrapMode(tex.wrap_v);
			model.AddSampler(sampler);

			// Link sampler index to texture
			modelTex.SamplerIndex = (int32)(model.Samplers.Count - 1);
		}
	}

	private void StoreImageData(Image image, ModelTexture texture)
	{
		texture.Width = (int32)image.Width;
		texture.Height = (int32)image.Height;
		texture.PixelFormat = ConvertPixelFormat(image.Format);

		let data = image.Data;
		let dataArray = new uint8[data.Length];
		data.CopyTo(dataArray);
		texture.SetData(dataArray);
	}

	private TexturePixelFormat ConvertPixelFormat(PixelFormat format)
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

	private StringView GetFormatHintFromFilename(ufbx_texture* tex)
	{
		StringView filename = "";
		if (tex.filename.data != null && tex.filename.length > 0)
			filename = StringView(tex.filename.data, (int)tex.filename.length);
		else if (tex.relative_filename.data != null && tex.relative_filename.length > 0)
			filename = StringView(tex.relative_filename.data, (int)tex.relative_filename.length);

		if (filename.EndsWith(".png", .OrdinalIgnoreCase))
			return ".png";
		if (filename.EndsWith(".jpg", .OrdinalIgnoreCase) || filename.EndsWith(".jpeg", .OrdinalIgnoreCase))
			return ".jpg";
		if (filename.EndsWith(".tga", .OrdinalIgnoreCase))
			return ".tga";
		if (filename.EndsWith(".bmp", .OrdinalIgnoreCase))
			return ".bmp";
		return "";
	}

	private TextureWrap ConvertWrapMode(ufbx_wrap_mode mode)
	{
		switch (mode)
		{
		case .UFBX_WRAP_CLAMP: return .ClampToEdge;
		default: return .Repeat;
		}
	}

	// ===== Meshes =====

	private void LoadMeshes(Model model)
	{
		for (int i = 0; i < (int)mScene.meshes.count; i++)
		{
			let fbxMesh = mScene.meshes.data[i];
			let mesh = new ModelMesh();

			if (fbxMesh.element.name.data != null && fbxMesh.element.name.length > 0)
				mesh.SetName(StringView(fbxMesh.element.name.data, (int)fbxMesh.element.name.length));

			// Determine if this mesh is skinned
			bool isSkinned = fbxMesh.skin_deformers.count > 0;
			ufbx_skin_deformer* skinDeformer = isSkinned ? fbxMesh.skin_deformers.data[0] : null;

			// Check for available attributes
			bool hasNormals = fbxMesh.vertex_normal.exists || mLoadOpts.generate_missing_normals;
			bool hasUV = fbxMesh.uv_sets.count > 0 && fbxMesh.uv_sets.data[0].vertex_uv.exists;
			bool hasTangent = fbxMesh.uv_sets.count > 0 && fbxMesh.uv_sets.data[0].vertex_tangent.exists;
			bool hasColor = fbxMesh.color_sets.count > 0 && fbxMesh.color_sets.data[0].vertex_color.exists;
			// Also check legacy vertex_color field on mesh (may be set even when color_sets is empty)
			bool hasLegacyColor = fbxMesh.vertex_color.exists;
			if (!hasColor && hasLegacyColor)
				hasColor = true; // Use legacy field as fallback

			mesh.SetHasNormals(hasNormals);
			mesh.SetHasTangents(hasTangent);

			// Setup vertex format (matching GltfLoader layout)
			int32 stride = 0;
			int32 positionOffset = stride;
			stride += sizeof(Vector3);
			mesh.AddVertexElement(VertexElement(.Position, .Float3, positionOffset));

			int32 normalOffset = stride;
			stride += sizeof(Vector3);
			mesh.AddVertexElement(VertexElement(.Normal, .Float3, normalOffset));

			int32 texCoordOffset = stride;
			stride += sizeof(Vector2);
			mesh.AddVertexElement(VertexElement(.TexCoord, .Float2, texCoordOffset));

			int32 colorOffset = stride;
			stride += sizeof(uint32);
			mesh.AddVertexElement(VertexElement(.Color, .Byte4, colorOffset));

			int32 tangentOffset = stride;
			stride += sizeof(Vector3);
			mesh.AddVertexElement(VertexElement(.Tangent, .Float3, tangentOffset));

			int32 jointsOffset = 0;
			int32 weightsOffset = 0;
			if (isSkinned)
			{
				jointsOffset = stride;
				stride += sizeof(uint16) * 4;
				mesh.AddVertexElement(VertexElement(.Joints, .UShort4, jointsOffset));

				weightsOffset = stride;
				stride += sizeof(Vector4);
				mesh.AddVertexElement(VertexElement(.Weights, .Float4, weightsOffset));
			}

			// Collect all triangulated vertices across all material parts
			let allVertexBytes = scope List<uint8>();
			let allIndices = scope List<uint32>();
			let vertexMap = scope Dictionary<int, int32>(); // vertex hash -> index

			// Allocate triangle index buffer for triangulation
			int maxTriIndices = (int)fbxMesh.max_face_triangles * 3;
			let triIndices = scope uint32[maxTriIndices];

			// Process material parts
			if (fbxMesh.material_parts.count > 0)
			{
				for (int p = 0; p < (int)fbxMesh.material_parts.count; p++)
				{
					let part = &fbxMesh.material_parts.data[p];
					int32 indexStart = (int32)allIndices.Count;
					int32 indexCount = 0;

					// Get material index
					int32 materialIndex = -1;
					if (part.index < (uint32)fbxMesh.materials.count)
					{
						let matPtr = fbxMesh.materials.data[part.index];
						if (matPtr != null && mMaterialIndexMap.TryGetValue(matPtr.element.typed_id, let matIdx))
							materialIndex = matIdx;
					}

					// Process each face in this material part
					for (int fi = 0; fi < (int)part.face_indices.count; fi++)
					{
						let faceIdx = part.face_indices.data[fi];
						let face = fbxMesh.faces.data[faceIdx];

						// Triangulate the face
						let numTris = ufbx_triangulate_face(&triIndices[0], (uint)maxTriIndices, fbxMesh, face);

						for (uint32 ti = 0; ti < numTris * 3; ti++)
						{
							let idx = triIndices[ti];

							// Build vertex data
							int hash = BuildVertex(fbxMesh, (int)idx, skinDeformer, isSkinned,
								hasUV, hasTangent, hasColor,
								stride, positionOffset, normalOffset, texCoordOffset, colorOffset, tangentOffset,
								jointsOffset, weightsOffset,
								allVertexBytes, vertexMap);

							let vertexIndex = vertexMap[hash];
							allIndices.Add((uint32)vertexIndex);
							indexCount++;
						}
					}

					if (indexCount > 0)
						mesh.AddPart(ModelMeshPart(indexStart, indexCount, materialIndex));
				}
			}
			else
			{
				// No material parts — process all faces as a single part
				int32 indexCount = 0;

				for (int fi = 0; fi < (int)fbxMesh.faces.count; fi++)
				{
					let face = fbxMesh.faces.data[fi];
					let numTris = ufbx_triangulate_face(&triIndices[0], (uint)maxTriIndices, fbxMesh, face);

					for (uint32 ti = 0; ti < numTris * 3; ti++)
					{
						let idx = triIndices[ti];
						int hash = BuildVertex(fbxMesh, (int)idx, skinDeformer, isSkinned,
							hasUV, hasTangent, hasColor,
							stride, positionOffset, normalOffset, texCoordOffset, colorOffset, tangentOffset,
							jointsOffset, weightsOffset,
							allVertexBytes, vertexMap);

						let vertexIndex = vertexMap[hash];
						allIndices.Add((uint32)vertexIndex);
						indexCount++;
					}
				}

				if (indexCount > 0)
					mesh.AddPart(ModelMeshPart(0, indexCount, -1));
			}

			// Copy vertex data to mesh
			int32 vertexCount = (int32)(allVertexBytes.Count / stride);
			if (vertexCount > 0)
			{
				mesh.AllocateVertices(vertexCount, stride);
				Internal.MemCpy(mesh.GetVertexData(), allVertexBytes.Ptr, allVertexBytes.Count);
			}

			// Copy index data to mesh
			int32 idxCount = (int32)allIndices.Count;
			if (idxCount > 0)
			{
				bool use32Bit = idxCount > 65535 || vertexCount > 65535;
				mesh.AllocateIndices(idxCount, use32Bit);

				if (use32Bit)
				{
					let indices = new uint32[idxCount];
					for (int32 j = 0; j < idxCount; j++)
						indices[j] = allIndices[j];
					mesh.SetIndexData(indices);
					delete indices;
				}
				else
				{
					let indices = new uint16[idxCount];
					for (int32 j = 0; j < idxCount; j++)
						indices[j] = (uint16)allIndices[j];
					mesh.SetIndexData(indices);
					delete indices;
				}
			}

			mesh.SetTopology(.Triangles);
			mesh.CalculateBounds();

			let meshIdx = model.AddMesh(mesh);
			mMeshIndexMap[fbxMesh.element.typed_id] = meshIdx;
		}
	}

	/// Builds a vertex at the given face index and adds it to the vertex buffer.
	/// Returns the hash for deduplication.
	private int BuildVertex(
		ufbx_mesh* fbxMesh, int idx, ufbx_skin_deformer* skinDeformer, bool isSkinned,
		bool hasUV, bool hasTangent, bool hasColor,
		int32 stride, int32 positionOffset, int32 normalOffset, int32 texCoordOffset,
		int32 colorOffset, int32 tangentOffset, int32 jointsOffset, int32 weightsOffset,
		List<uint8> vertexBytes, Dictionary<int, int32> vertexMap)
	{
		// Read vertex attributes
		let pos = ReadVec3(fbxMesh.vertex_position, idx);
		let normal = fbxMesh.vertex_normal.exists ? ReadVec3(fbxMesh.vertex_normal, idx) : ufbx_vec3() { x = 0, y = 1, z = 0 };

		ufbx_vec2 uv = .();
		if (hasUV)
		{
			uv = ReadVec2(fbxMesh.uv_sets.data[0].vertex_uv, idx);
			// FBX uses bottom-left UV origin (V=0 at bottom), flip to match
			// GLTF/renderer convention (V=0 at top)
			uv.y = 1.0 - uv.y;
		}

		ufbx_vec3 tangent = .() { x = 1, y = 0, z = 0 };
		if (hasTangent)
			tangent = ReadVec3(fbxMesh.uv_sets.data[0].vertex_tangent, idx);

		ufbx_vec4 color = .() { x = 1, y = 1, z = 1, w = 1 };
		if (hasColor)
		{
			if (fbxMesh.color_sets.count > 0 && fbxMesh.color_sets.data[0].vertex_color.exists)
				color = ReadVec4(fbxMesh.color_sets.data[0].vertex_color, idx);
			else if (fbxMesh.vertex_color.exists)
				color = ReadVec4(fbxMesh.vertex_color, idx);
		}

		// Skinning data
		uint16[4] joints = .();
		float[4] weights = .();
		if (isSkinned && skinDeformer != null)
		{
			// Get the vertex index (not face index) for skinning
			let vertexIndex = fbxMesh.vertex_indices.data[idx];
			GetSkinWeights(skinDeformer, (int)vertexIndex, ref joints, ref weights);
		}

		// Compute hash for deduplication
		int hash = HashVertex(pos, normal, uv, tangent, color, isSkinned, joints, weights);

		if (vertexMap.ContainsKey(hash))
			return hash;

		// Add new vertex
		int32 newIndex = (int32)(vertexBytes.Count / stride);

		// Extend buffer
		int oldCount = vertexBytes.Count;
		for (int b = 0; b < stride; b++)
			vertexBytes.Add(0);
		uint8* vertex = &vertexBytes[oldCount];

		// Position
		*(Vector3*)(vertex + positionOffset) = .((float)pos.x, (float)pos.y, (float)pos.z);

		// Normal
		*(Vector3*)(vertex + normalOffset) = .((float)normal.x, (float)normal.y, (float)normal.z);

		// TexCoord
		*(Vector2*)(vertex + texCoordOffset) = .((float)uv.x, (float)uv.y);

		// Color (pack to RGBA8)
		uint8 cr = (uint8)Math.Clamp((float)color.x * 255.0f, 0, 255);
		uint8 cg = (uint8)Math.Clamp((float)color.y * 255.0f, 0, 255);
		uint8 cb = (uint8)Math.Clamp((float)color.z * 255.0f, 0, 255);
		uint8 ca = (uint8)Math.Clamp((float)color.w * 255.0f, 0, 255);
		*(uint32*)(vertex + colorOffset) = (uint32)cr | ((uint32)cg << 8) | ((uint32)cb << 16) | ((uint32)ca << 24);

		// Tangent
		*(Vector3*)(vertex + tangentOffset) = .((float)tangent.x, (float)tangent.y, (float)tangent.z);

		// Skinning
		if (isSkinned)
		{
			*(uint16[4]*)(vertex + jointsOffset) = joints;
			*(Vector4*)(vertex + weightsOffset) = .(weights[0], weights[1], weights[2], weights[3]);
		}

		vertexMap[hash] = newIndex;
		return hash;
	}

	private ufbx_vec3 ReadVec3(ufbx_vertex_vec3 attrib, int idx)
	{
		let valueIdx = attrib.indices.data[idx];
		return attrib.values.data[valueIdx];
	}

	private ufbx_vec2 ReadVec2(ufbx_vertex_vec2 attrib, int idx)
	{
		let valueIdx = attrib.indices.data[idx];
		return attrib.values.data[valueIdx];
	}

	private ufbx_vec4 ReadVec4(ufbx_vertex_vec4 attrib, int idx)
	{
		let valueIdx = attrib.indices.data[idx];
		return attrib.values.data[valueIdx];
	}

	private void GetSkinWeights(ufbx_skin_deformer* skin, int vertexIndex, ref uint16[4] joints, ref float[4] weights)
	{
		if (vertexIndex >= (int)skin.vertices.count)
			return;

		let skinVertex = &skin.vertices.data[vertexIndex];
		int numWeights = (int)skinVertex.num_weights;
		if (numWeights == 0)
			return;

		// Collect weights using parallel arrays (top 16 max)
		int entryCount = Math.Min(numWeights, 16);
		uint16[16] entryJoints = .();
		float[16] entryWeights = .();

		for (int w = 0; w < entryCount; w++)
		{
			let skinWeight = &skin.weights.data[skinVertex.weight_begin + (uint32)w];
			let clusterIdx = skinWeight.cluster_index;

			// Use cluster index directly as skeleton joint index.
			// Clusters map 1:1 to Skin.Joints (skeleton bones), NOT to Model.Bones.
			entryJoints[w] = (uint16)clusterIdx;
			entryWeights[w] = (float)skinWeight.weight;
		}

		// Simple selection of top 4 weights
		for (int a = 0; a < Math.Min(entryCount, 4); a++)
		{
			// Find max remaining
			int maxIdx = a;
			for (int b = a + 1; b < entryCount; b++)
			{
				if (entryWeights[b] > entryWeights[maxIdx])
					maxIdx = b;
			}
			if (maxIdx != a)
			{
				let tmpJ = entryJoints[a];
				entryJoints[a] = entryJoints[maxIdx];
				entryJoints[maxIdx] = tmpJ;
				let tmpW = entryWeights[a];
				entryWeights[a] = entryWeights[maxIdx];
				entryWeights[maxIdx] = tmpW;
			}

			joints[a] = entryJoints[a];
			weights[a] = entryWeights[a];
		}

		// Normalize weights
		float sum = weights[0] + weights[1] + weights[2] + weights[3];
		if (sum > 0)
		{
			float invSum = 1.0f / sum;
			weights[0] *= invSum;
			weights[1] *= invSum;
			weights[2] *= invSum;
			weights[3] *= invSum;
		}
	}

	private int HashVertex(ufbx_vec3 pos, ufbx_vec3 normal, ufbx_vec2 uv, ufbx_vec3 tangent,
		ufbx_vec4 color, bool isSkinned, uint16[4] joints, float[4] weights)
	{
		int hash = 17;
		hash = hash * 31 + ((float)pos.x).GetHashCode();
		hash = hash * 31 + ((float)pos.y).GetHashCode();
		hash = hash * 31 + ((float)pos.z).GetHashCode();
		hash = hash * 31 + ((float)normal.x).GetHashCode();
		hash = hash * 31 + ((float)normal.y).GetHashCode();
		hash = hash * 31 + ((float)normal.z).GetHashCode();
		hash = hash * 31 + ((float)uv.x).GetHashCode();
		hash = hash * 31 + ((float)uv.y).GetHashCode();
		hash = hash * 31 + ((float)tangent.x).GetHashCode();
		hash = hash * 31 + ((float)tangent.y).GetHashCode();
		hash = hash * 31 + ((float)tangent.z).GetHashCode();
		hash = hash * 31 + ((float)color.x).GetHashCode();
		hash = hash * 31 + ((float)color.y).GetHashCode();
		hash = hash * 31 + ((float)color.z).GetHashCode();
		hash = hash * 31 + ((float)color.w).GetHashCode();

		if (isSkinned)
		{
			hash = hash * 31 + (int)joints[0];
			hash = hash * 31 + (int)joints[1];
			hash = hash * 31 + (int)joints[2];
			hash = hash * 31 + (int)joints[3];
			hash = hash * 31 + weights[0].GetHashCode();
			hash = hash * 31 + weights[1].GetHashCode();
			hash = hash * 31 + weights[2].GetHashCode();
			hash = hash * 31 + weights[3].GetHashCode();
		}

		return hash;
	}

	// ===== Nodes =====

	private void LoadNodes(Model model)
	{
		// Pass 1: create all bones
		for (int i = 0; i < (int)mScene.nodes.count; i++)
		{
			let node = mScene.nodes.data[i];
			let bone = new ModelBone();

			if (node.element.name.data != null && node.element.name.length > 0)
				bone.SetName(StringView(node.element.name.data, (int)node.element.name.length));

			// Extract TRS from local transform
			let t = node.local_transform;
			bone.Translation = .((float)t.translation.x, (float)t.translation.y, (float)t.translation.z);
			bone.Rotation = .((float)t.rotation.x, (float)t.rotation.y, (float)t.rotation.z, (float)t.rotation.w);
			bone.Scale = .((float)t.scale.x, (float)t.scale.y, (float)t.scale.z);
			bone.UpdateLocalTransform();

			// Mesh reference
			if (node.mesh != null)
			{
				if (mMeshIndexMap.TryGetValue(node.mesh.element.typed_id, let meshIdx))
					bone.MeshIndex = meshIdx;
			}

			// Skin reference
			if (node.mesh != null && node.mesh.skin_deformers.count > 0)
			{
				let skinDef = node.mesh.skin_deformers.data[0];
				if (mSkinIndexMap.TryGetValue(skinDef.element.typed_id, let skinIdx))
					bone.SkinIndex = skinIdx;
				// Note: skin index may be set later when LoadSkins runs
			}

			let boneIdx = model.AddBone(bone);
			mNodeToBoneIndex[node.element.typed_id] = boneIdx;
		}

		// Pass 2: set parent relationships
		for (int i = 0; i < (int)mScene.nodes.count; i++)
		{
			let node = mScene.nodes.data[i];
			if (node.parent != null)
			{
				if (mNodeToBoneIndex.TryGetValue(node.parent.element.typed_id, let parentIdx))
					model.Bones[i].ParentIndex = parentIdx;
			}
		}
	}

	// ===== Skins =====

	private void LoadSkins(Model model)
	{
		for (int i = 0; i < (int)mScene.skin_deformers.count; i++)
		{
			let skinDef = mScene.skin_deformers.data[i];
			let skin = new ModelSkin();

			if (skinDef.element.name.data != null && skinDef.element.name.length > 0)
				skin.SetName(StringView(skinDef.element.name.data, (int)skinDef.element.name.length));

			// Process clusters (joints)
			for (int j = 0; j < (int)skinDef.clusters.count; j++)
			{
				let cluster = skinDef.clusters.data[j];
				if (cluster == null || cluster.bone_node == null)
					continue;

				int32 jointIndex = -1;
				if (mNodeToBoneIndex.TryGetValue(cluster.bone_node.element.typed_id, let boneIdx))
					jointIndex = boneIdx;

				if (jointIndex < 0)
					continue;

				// Convert geometry_to_bone matrix to our inverse bind matrix
				let ibm = ConvertMatrix(cluster.geometry_to_bone);

				skin.AddJoint(jointIndex, ibm);

				// Also set on the bone
				if (jointIndex >= 0 && jointIndex < model.Bones.Count)
					model.Bones[jointIndex].InverseBindMatrix = ibm;
			}

			let skinIdx = model.AddSkin(skin);
			mSkinIndexMap[skinDef.element.typed_id] = skinIdx;
		}

		// Update bone skin indices now that skins are loaded
		for (int i = 0; i < (int)mScene.nodes.count; i++)
		{
			let node = mScene.nodes.data[i];
			if (node.mesh != null && node.mesh.skin_deformers.count > 0)
			{
				let skinDef = node.mesh.skin_deformers.data[0];
				if (mSkinIndexMap.TryGetValue(skinDef.element.typed_id, let skinIdx))
				{
					if (i < model.Bones.Count)
						model.Bones[i].SkinIndex = skinIdx;
				}
			}
		}
	}

	// ===== Animations =====

	private void LoadAnimations(Model model)
	{
		for (int i = 0; i < (int)mScene.anim_stacks.count; i++)
		{
			let stack = mScene.anim_stacks.data[i];
			let animation = new ModelAnimation();

			if (stack.element.name.data != null && stack.element.name.length > 0)
				animation.SetName(StringView(stack.element.name.data, (int)stack.element.name.length));

			// Bake the animation — this pre-computes T/R/S keyframes per node
			// in the target coordinate system (Y-up), handling Euler-to-quaternion
			// conversion and layer blending automatically.
			ufbx_bake_opts bakeOpts = .();
			bakeOpts.resample_rate = 30.0;
			bakeOpts.minimum_sample_rate = 30.0;
			bakeOpts.max_keyframe_segments = 1024;

			ufbx_error bakeError = .();
			let bakedAnim = ufbx_bake_anim(mScene, stack.anim, &bakeOpts, &bakeError);
			if (bakedAnim == null)
			{
				delete animation;
				continue;
			}

			for (int ni = 0; ni < (int)bakedAnim.nodes.count; ni++)
			{
				let bakedNode = &bakedAnim.nodes.data[ni];

				// Map baked node to our bone index
				if (!mNodeToBoneIndex.TryGetValue(bakedNode.typed_id, let boneIdx))
					continue;

				// Translation channel
				if (bakedNode.translation_keys.count > 0 && !bakedNode.constant_translation)
				{
					let channel = new AnimationChannel();
					channel.TargetBone = boneIdx;
					channel.Path = .Translation;
					channel.Interpolation = DetectInterpolation(bakedNode.translation_keys);

					for (int ki = 0; ki < (int)bakedNode.translation_keys.count; ki++)
					{
						let key = &bakedNode.translation_keys.data[ki];
						channel.AddKeyframe((float)key.time, .((float)key.value.x, (float)key.value.y, (float)key.value.z, 0));
					}
					animation.AddChannel(channel);
				}

				// Rotation channel
				if (bakedNode.rotation_keys.count > 0 && !bakedNode.constant_rotation)
				{
					let channel = new AnimationChannel();
					channel.TargetBone = boneIdx;
					channel.Path = .Rotation;
					channel.Interpolation = DetectInterpolation(bakedNode.rotation_keys);

					for (int ki = 0; ki < (int)bakedNode.rotation_keys.count; ki++)
					{
						let key = &bakedNode.rotation_keys.data[ki];
						channel.AddKeyframe((float)key.time, .((float)key.value.x, (float)key.value.y, (float)key.value.z, (float)key.value.w));
					}
					animation.AddChannel(channel);
				}

				// Scale channel
				if (bakedNode.scale_keys.count > 0 && !bakedNode.constant_scale)
				{
					let channel = new AnimationChannel();
					channel.TargetBone = boneIdx;
					channel.Path = .Scale;
					channel.Interpolation = DetectInterpolation(bakedNode.scale_keys);

					for (int ki = 0; ki < (int)bakedNode.scale_keys.count; ki++)
					{
						let key = &bakedNode.scale_keys.data[ki];
						channel.AddKeyframe((float)key.time, .((float)key.value.x, (float)key.value.y, (float)key.value.z, 0));
					}
					animation.AddChannel(channel);
				}
			}

			ufbx_free_baked_anim(bakedAnim);

			animation.CalculateDuration();
			model.AddAnimation(animation);
		}
	}

	/// Detect interpolation mode from baked vec3 keyframe flags.
	private AnimationInterpolation DetectInterpolation(ufbx_baked_vec3_list keys)
	{
		for (int i = 0; i < (int)keys.count; i++)
		{
			let flags = keys.data[i].flags;
			if (flags.HasFlag(.UFBX_BAKED_KEY_STEP_LEFT) || flags.HasFlag(.UFBX_BAKED_KEY_STEP_RIGHT))
				return .Step;
		}
		return .Linear;
	}

	/// Detect interpolation mode from baked quaternion keyframe flags.
	private AnimationInterpolation DetectInterpolation(ufbx_baked_quat_list keys)
	{
		for (int i = 0; i < (int)keys.count; i++)
		{
			let flags = keys.data[i].flags;
			if (flags.HasFlag(.UFBX_BAKED_KEY_STEP_LEFT) || flags.HasFlag(.UFBX_BAKED_KEY_STEP_RIGHT))
				return .Step;
		}
		return .Linear;
	}

	// ===== Matrix Conversion =====

	/// Converts a ufbx 3x4 matrix to our 4x4 Matrix.
	/// ufbx column -> Matrix row (same pattern as GltfLoader's column-major transpose).
	private static Matrix ConvertMatrix(ufbx_matrix m)
	{
		return .(
			(float)m.m00, (float)m.m10, (float)m.m20, 0,
			(float)m.m01, (float)m.m11, (float)m.m21, 0,
			(float)m.m02, (float)m.m12, (float)m.m22, 0,
			(float)m.m03, (float)m.m13, (float)m.m23, 1
		);
	}
}
