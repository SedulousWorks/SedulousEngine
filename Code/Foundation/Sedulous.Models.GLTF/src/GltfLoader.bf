using System;
using System.IO;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Models;
using cgltf_Beef;
using Sedulous.Images;

namespace Sedulous.Models.GLTF;

/// Loads GLTF and GLB model files using cgltf
public class GltfLoader : IModelLoader
{
	private static StringView[?] sSupportedExtensions = .(".gltf", ".glb");

	private cgltf_data* mData;
	private String mBasePath ~ delete _;

	public this()
	{
		mBasePath = new String();
	}

	public ~this()
	{
		if (mData != null)
		{
			cgltf_free(mData);
			mData = null;
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

	/// Load a GLTF or GLB file
	public ModelLoadResult Load(StringView path, Model model)
	{
		// Free previous data
		if (mData != null)
		{
			cgltf_free(mData);
			mData = null;
		}

		// Extract base path for loading external resources
		mBasePath.Clear();
		Path.GetDirectoryPath(path, mBasePath);

		// Parse the file
		cgltf_options options = .();
		let pathStr = path.ToScopeCStr!();

		let parseResult = cgltf_parse_file(&options, pathStr, &mData);
		if (parseResult != .cgltf_result_success)
		{
			return parseResult == .cgltf_result_file_not_found ? .FileNotFound : .ParseError;
		}

		// Load buffer data
		let loadResult = cgltf_load_buffers(&options, mData, pathStr);
		if (loadResult != .cgltf_result_success)
		{
			return .BufferLoadError;
		}

		// Validate
		if (cgltf_validate(mData) != .cgltf_result_success)
		{
			return .InvalidFormat;
		}

		// GLTF is always Y-up per specification
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

	private void LoadMaterials(Model model)
	{
		for (int i = 0; i < (int)mData.materials_count; i++)
		{
			let mat = &mData.materials[i];
			let material = new ModelMaterial();

			if (mat.name != null)
				material.SetName(StringView(mat.name));
			else
				material.SetName(scope $"texture_{i}");

			// PBR Metallic Roughness
			if (mat.has_pbr_metallic_roughness != 0)
			{
				let pbr = &mat.pbr_metallic_roughness;

				material.BaseColorFactor = .(
					pbr.base_color_factor[0],
					pbr.base_color_factor[1],
					pbr.base_color_factor[2],
					pbr.base_color_factor[3]
				);

				if (pbr.base_color_texture.texture != null)
				{
					material.BaseColorTextureIndex = (int32)cgltf_texture_index(mData, pbr.base_color_texture.texture);
				}

				material.MetallicFactor = pbr.metallic_factor;
				material.RoughnessFactor = pbr.roughness_factor;

				if (pbr.metallic_roughness_texture.texture != null)
				{
					material.MetallicRoughnessTextureIndex = (int32)cgltf_texture_index(mData, pbr.metallic_roughness_texture.texture);
				}
			}

			// Normal texture
			if (mat.normal_texture.texture != null)
			{
				material.NormalTextureIndex = (int32)cgltf_texture_index(mData, mat.normal_texture.texture);
				material.NormalScale = mat.normal_texture.scale;
			}

			// Occlusion texture
			if (mat.occlusion_texture.texture != null)
			{
				material.OcclusionTextureIndex = (int32)cgltf_texture_index(mData, mat.occlusion_texture.texture);
				material.OcclusionStrength = mat.occlusion_texture.scale;
			}

			// Emissive
			material.EmissiveFactor = .(
				mat.emissive_factor[0],
				mat.emissive_factor[1],
				mat.emissive_factor[2]
			);

			if (mat.emissive_texture.texture != null)
			{
				material.EmissiveTextureIndex = (int32)cgltf_texture_index(mData, mat.emissive_texture.texture);
			}

			// Alpha
			switch (mat.alpha_mode)
			{
			case .cgltf_alpha_mode_mask: material.AlphaMode = .Mask;
			case .cgltf_alpha_mode_blend: material.AlphaMode = .Blend;
			default: material.AlphaMode = .Opaque;
			}

			material.AlphaCutoff = mat.alpha_cutoff;
			material.DoubleSided = mat.double_sided != 0;

			model.AddMaterial(material);
		}
	}

	private void LoadTextures(Model model)
	{
		for (int i = 0; i < (int)mData.textures_count; i++)
		{
			let tex = &mData.textures[i];
			let texture = new ModelTexture();

			if (tex.name != null)
				texture.SetName(StringView(tex.name));
			else if(tex.image?.name != null)
				texture.SetName(StringView(tex.image.name));

			if (tex.sampler != null)
				texture.SamplerIndex = (int32)cgltf_sampler_index(mData, tex.sampler);

			if (tex.image != null)
			{
				let gltfImage = tex.image;

				if (gltfImage.mime_type != null)
					texture.MimeType.Set(StringView(gltfImage.mime_type));

				if (gltfImage.uri != null)
				{
					let uri = StringView(gltfImage.uri);
					texture.SetUri(uri);

					if (uri.StartsWith("data:"))
					{
						// Base64 encoded data URI (e.g., "data:image/png;base64,iVBORw0...")
						if (LoadImageFromDataUri(uri) case .Ok(let image))
						{
							StoreImageData(image, texture);
							delete image;
						}
					}
					else
					{
						// External image file
						let imagePath = scope String();
						Path.InternalCombine(imagePath, mBasePath, uri);

						if (ImageLoaderFactory.LoadImage(imagePath) case .Ok(let image))
						{
							StoreImageData(image, texture);
							delete image;
						}
					}
				}
				else if (gltfImage.buffer_view != null)
				{
					// Embedded image data in buffer
					let bufferData = cgltf_buffer_view_data(gltfImage.buffer_view);
					let size = (int)gltfImage.buffer_view.size;
					if (bufferData != null && size > 0)
					{
						let span = Span<uint8>(bufferData, size);
						let formatHint = GetFormatHintFromMimeType(gltfImage.mime_type);

						if (ImageLoaderFactory.LoadImageFromMemory(span, formatHint) case .Ok(let image))
						{
							StoreImageData(image, texture);
							delete image;
						}
					}
				}
			}

			model.AddTexture(texture);
		}

		// Load samplers
		for (int i = 0; i < (int)mData.samplers_count; i++)
		{
			let samp = &mData.samplers[i];
			TextureSampler sampler = .();

			sampler.WrapS = WrapModeFromCgltf(samp.wrap_s);
			sampler.WrapT = WrapModeFromCgltf(samp.wrap_t);
			sampler.MinFilter = MinFilterFromCgltf(samp.min_filter);
			sampler.MagFilter = MagFilterFromCgltf(samp.mag_filter);

			model.AddSampler(sampler);
		}

		// Ensure all textures have a valid sampler.
		// Per glTF spec, textures without an explicit sampler default to Repeat wrapping.
		for (let texture in model.Textures)
		{
			if (texture.SamplerIndex < 0)
			{
				// Add a default glTF sampler (Repeat/Repeat) and assign it
				TextureSampler defaultSampler = .(); // Defaults: WrapS=Repeat, WrapT=Repeat
				texture.SamplerIndex = model.AddSampler(defaultSampler);
			}
		}
	}

	private void StoreImageData(Image image, ModelTexture texture)
	{
		texture.Width = (int32)image.Width;
		texture.Height = (int32)image.Height;
		texture.PixelFormat = ConvertPixelFormat(image.Format);

		// Copy pixel data
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

	private StringView GetFormatHintFromMimeType(char8* mimeType)
	{
		if (mimeType == null)
			return "";

		let mime = StringView(mimeType);
		if (mime == "image/png")
			return ".png";
		if (mime == "image/jpeg")
			return ".jpg";
		return "";
	}

	private Result<Image> LoadImageFromDataUri(StringView dataUri)
	{
		// Format: data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA...
		let commaPos = dataUri.IndexOf(',');
		if (commaPos == -1)
			return .Err;

		let header = dataUri.Substring(5, commaPos - 5); // Skip "data:"
		let base64Data = dataUri.Substring(commaPos + 1);

		// Parse MIME type from header (e.g., "image/png;base64")
		StringView formatHint = "";
		if (header.Contains("image/png"))
			formatHint = ".png";
		else if (header.Contains("image/jpeg") || header.Contains("image/jpg"))
			formatHint = ".jpg";

		// Use cgltf's base64 decoder
		// Estimate decoded size: base64 uses 4 chars per 3 bytes
		let estimatedSize = (base64Data.Length * 3) / 4;
		void* decodedData = null;
		cgltf_options options = .();

		let base64Str = scope String(base64Data);
		if (cgltf_load_buffer_base64(&options, (.)estimatedSize, base64Str.CStr(), &decodedData) != .cgltf_result_success)
			return .Err;

		defer Internal.StdFree(decodedData);

		let span = Span<uint8>((uint8*)decodedData, estimatedSize);

		if (ImageLoaderFactory.LoadImageFromMemory(span, formatHint) case .Ok(let image))
			return .Ok(image);

		return .Err;
	}

	private TextureWrap WrapModeFromCgltf(cgltf_wrap_mode mode)
	{
		switch (mode)
		{
		case .cgltf_wrap_mode_clamp_to_edge: return .ClampToEdge;
		case .cgltf_wrap_mode_mirrored_repeat: return .MirroredRepeat;
		default: return .Repeat;
		}
	}

	private static TextureMinFilter MinFilterFromCgltf(cgltf_filter_type filter)
	{
		switch(filter)
		{
			case .cgltf_filter_type_nearest: return .Nearest;
			case .cgltf_filter_type_linear: return .Linear;
			case .cgltf_filter_type_nearest_mipmap_nearest: return .NearestMipmapNearest;
			case .cgltf_filter_type_linear_mipmap_nearest: return .LinearMipmapNearest;
			case .cgltf_filter_type_nearest_mipmap_linear: return .NearestMipmapLinear;
			case .cgltf_filter_type_linear_mipmap_linear: return .LinearMipmapLinear;
			case .cgltf_filter_type_undefined: return .Nearest;
		}
	}

	public static TextureMagFilter MagFilterFromCgltf(cgltf_filter_type filter)
	{
		switch(filter)
		{
			case .cgltf_filter_type_nearest, .cgltf_filter_type_nearest_mipmap_nearest, .cgltf_filter_type_nearest_mipmap_linear: return .Nearest;
			case .cgltf_filter_type_linear, .cgltf_filter_type_linear_mipmap_nearest, .cgltf_filter_type_linear_mipmap_linear: return .Linear;
			case .cgltf_filter_type_undefined: return .Nearest;
		}
	}

	private void LoadMeshes(Model model)
	{
		for (int i = 0; i < (int)mData.meshes_count; i++)
		{
			let meshData = &mData.meshes[i];
			let mesh = new ModelMesh();

			if (meshData.name != null)
				mesh.SetName(StringView(meshData.name));

			if (meshData.primitives_count > 0)
				LoadMeshPrimitives(meshData, mesh);

			mesh.CalculateBounds();
			model.AddMesh(mesh);
		}
	}

	/// Loads all primitives of a GLTF mesh, merging their vertex/index data into one ModelMesh.
	/// Each primitive becomes a ModelMeshPart with correct index offsets and material index.
	private void LoadMeshPrimitives(cgltf_mesh* meshData, ModelMesh mesh)
	{
		let firstPrim = &meshData.primitives[0];

		// Phase 1: Detect skinning and available attributes from first primitive
		bool isSkinned = false;
		bool hasNormals = false;
		bool hasTangents = false;
		bool hasTexCoords = false;
		for (int a = 0; a < (int)firstPrim.attributes_count; a++)
		{
			let attr = &firstPrim.attributes[a];
			if (attr.type == .cgltf_attribute_type_joints && attr.index == 0)
				isSkinned = true;
			if (attr.type == .cgltf_attribute_type_normal)
				hasNormals = true;
			if (attr.type == .cgltf_attribute_type_tangent)
				hasTangents = true;
			if (attr.type == .cgltf_attribute_type_texcoord && attr.index == 0)
				hasTexCoords = true;
		}

		mesh.SetHasNormals(hasNormals);
		mesh.SetHasTangents(hasTangents);

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

		// Phase 2: Count total vertices and indices across all primitives
		int32 totalVertexCount = 0;
		int32 totalIndexCount = 0;
		for (int p = 0; p < (int)meshData.primitives_count; p++)
		{
			let prim = &meshData.primitives[p];
			for (int a = 0; a < (int)prim.attributes_count; a++)
			{
				if (prim.attributes[a].type == .cgltf_attribute_type_position)
				{
					totalVertexCount += (int32)prim.attributes[a].data.count;
					break;
				}
			}
			if (prim.indices != null)
				totalIndexCount += (int32)prim.indices.count;
		}

		if (totalVertexCount == 0)
			return;

		// Phase 3: Allocate buffers for all primitives combined
		bool use32Bit = totalIndexCount > 65535 || totalVertexCount > 65535;
		mesh.AllocateVertices(totalVertexCount, stride);
		mesh.AllocateIndices(totalIndexCount, use32Bit);

		uint8* vertexData = mesh.GetVertexData();
		uint8* indexData = mesh.GetIndexData();

		// Phase 4: Load each primitive's data at correct offset
		int32 vertexOffset = 0;
		int32 indexOffset = 0;

		for (int p = 0; p < (int)meshData.primitives_count; p++)
		{
			let prim = &meshData.primitives[p];

			// Find accessors for this primitive
			cgltf_accessor* positionAccessor = null;
			cgltf_accessor* normalAccessor = null;
			cgltf_accessor* texCoordAccessor = null;
			cgltf_accessor* colorAccessor = null;
			cgltf_accessor* tangentAccessor = null;
			cgltf_accessor* jointsAccessor = null;
			cgltf_accessor* weightsAccessor = null;

			for (int a = 0; a < (int)prim.attributes_count; a++)
			{
				let attr = &prim.attributes[a];
				switch (attr.type)
				{
				case .cgltf_attribute_type_position: positionAccessor = attr.data;
				case .cgltf_attribute_type_normal: normalAccessor = attr.data;
				case .cgltf_attribute_type_texcoord:
					if (attr.index == 0) texCoordAccessor = attr.data;
				case .cgltf_attribute_type_color:
					if (attr.index == 0) colorAccessor = attr.data;
				case .cgltf_attribute_type_tangent: tangentAccessor = attr.data;
				case .cgltf_attribute_type_joints:
					if (attr.index == 0) jointsAccessor = attr.data;
				case .cgltf_attribute_type_weights:
					if (attr.index == 0) weightsAccessor = attr.data;
				default:
				}
			}

			if (positionAccessor == null)
				continue;

			int32 primVertexCount = (int32)positionAccessor.count;

			// Fill vertex data at offset
			for (int32 v = 0; v < primVertexCount; v++)
			{
				uint8* vertex = vertexData + (vertexOffset + v) * stride;

				// Position
				float[3] pos = .();
				cgltf_accessor_read_float(positionAccessor, (.)v, &pos, 3);
				*(Vector3*)(vertex + positionOffset) = .(pos[0], pos[1], pos[2]);

				// Normal
				if (normalAccessor != null)
				{
					float[3] normal = .();
					cgltf_accessor_read_float(normalAccessor, (.)v, &normal, 3);
					*(Vector3*)(vertex + normalOffset) = .(normal[0], normal[1], normal[2]);
				}
				else
				{
					*(Vector3*)(vertex + normalOffset) = .(0, 1, 0);
				}

				// TexCoord
				if (texCoordAccessor != null)
				{
					float[2] uv = .();
					cgltf_accessor_read_float(texCoordAccessor, (.)v, &uv, 2);
					*(Vector2*)(vertex + texCoordOffset) = .(uv[0], uv[1]);
				}

				// Color
				if (colorAccessor != null)
				{
					float[4] color = .(1, 1, 1, 1);
					cgltf_accessor_read_float(colorAccessor, (.)v, &color, 4);
					uint8 cr = (uint8)Math.Clamp(color[0] * 255.0f, 0, 255);
					uint8 cg = (uint8)Math.Clamp(color[1] * 255.0f, 0, 255);
					uint8 cb = (uint8)Math.Clamp(color[2] * 255.0f, 0, 255);
					uint8 ca = (uint8)Math.Clamp(color[3] * 255.0f, 0, 255);
					*(uint32*)(vertex + colorOffset) = (uint32)cr | ((uint32)cg << 8) | ((uint32)cb << 16) | ((uint32)ca << 24);
				}
				else
				{
					*(uint32*)(vertex + colorOffset) = 0xFFFFFFFF;
				}

				// Tangent
				if (tangentAccessor != null)
				{
					float[4] tangent = .();
					cgltf_accessor_read_float(tangentAccessor, (.)v, &tangent, 4);
					*(Vector3*)(vertex + tangentOffset) = .(tangent[0], tangent[1], tangent[2]);
				}
				else
				{
					*(Vector3*)(vertex + tangentOffset) = .(1, 0, 0);
				}

				// Skinning data
				if (isSkinned && jointsAccessor != null && weightsAccessor != null)
				{
					uint32[4] joints = .();
					cgltf_accessor_read_uint(jointsAccessor, (.)v, &joints, 4);
					*(uint16[4]*)(vertex + jointsOffset) = .((uint16)joints[0], (uint16)joints[1], (uint16)joints[2], (uint16)joints[3]);

					float[4] weights = .();
					cgltf_accessor_read_float(weightsAccessor, (.)v, &weights, 4);
					*(Vector4*)(vertex + weightsOffset) = .(weights[0], weights[1], weights[2], weights[3]);
				}
			}

			// Fill index data at offset (indices must be remapped by vertexOffset)
			int32 primIndexCount = 0;
			if (prim.indices != null)
			{
				primIndexCount = (int32)prim.indices.count;

				if (use32Bit)
				{
					uint32* indices = (uint32*)(indexData + indexOffset * 4);
					for (int32 idx = 0; idx < primIndexCount; idx++)
						indices[idx] = (uint32)cgltf_accessor_read_index(prim.indices, (.)idx) + (uint32)vertexOffset;
				}
				else
				{
					uint16* indices = (uint16*)(indexData + indexOffset * 2);
					for (int32 idx = 0; idx < primIndexCount; idx++)
						indices[idx] = (uint16)((uint32)cgltf_accessor_read_index(prim.indices, (.)idx) + (uint32)vertexOffset);
				}
			}

			// Add mesh part with correct offset
			int32 materialIndex = -1;
			if (prim.material != null)
				materialIndex = (int32)cgltf_material_index(mData, prim.material);

			if (primIndexCount > 0)
				mesh.AddPart(ModelMeshPart(indexOffset, primIndexCount, materialIndex));

			vertexOffset += primVertexCount;
			indexOffset += primIndexCount;
		}

		// Set topology from first primitive
		switch (firstPrim.type)
		{
		case .cgltf_primitive_type_triangles: mesh.SetTopology(.Triangles);
		case .cgltf_primitive_type_triangle_strip: mesh.SetTopology(.TriangleStrip);
		case .cgltf_primitive_type_lines: mesh.SetTopology(.Lines);
		case .cgltf_primitive_type_line_strip: mesh.SetTopology(.LineStrip);
		case .cgltf_primitive_type_points: mesh.SetTopology(.Points);
		default: mesh.SetTopology(.Triangles);
		}
	}

	private void LoadNodes(Model model)
	{
		// First pass: create all bones
		for (int i = 0; i < (int)mData.nodes_count; i++)
		{
			let node = &mData.nodes[i];
			let bone = new ModelBone();

			if (node.name != null)
				bone.SetName(StringView(node.name));

			// Translation
			if (node.has_translation != 0)
			{
				bone.Translation = .(node.translation[0], node.translation[1], node.translation[2]);
			}

			// Rotation
			if (node.has_rotation != 0)
			{
				bone.Rotation = .(node.rotation[0], node.rotation[1], node.rotation[2], node.rotation[3]);
			}

			// Scale
			if (node.has_scale != 0)
			{
				bone.Scale = .(node.scale[0], node.scale[1], node.scale[2]);
			}

			// Matrix
			if (node.has_matrix != 0)
			{
				// GLTF stores column-major for column-vector convention.
				// Transpose to row-vector convention by reading flat array directly into row-major storage.
				bone.LocalTransform = .(
					node.matrix[0], node.matrix[1], node.matrix[2], node.matrix[3],
					node.matrix[4], node.matrix[5], node.matrix[6], node.matrix[7],
					node.matrix[8], node.matrix[9], node.matrix[10], node.matrix[11],
					node.matrix[12], node.matrix[13], node.matrix[14], node.matrix[15]
				);
			}
			else
			{
				bone.UpdateLocalTransform();
			}

			if (node.mesh != null)
				bone.MeshIndex = (int32)cgltf_mesh_index(mData, node.mesh);

			if (node.skin != null)
				bone.SkinIndex = (int32)cgltf_skin_index(mData, node.skin);

			model.AddBone(bone);
		}

		// Second pass: set up parent relationships
		for (int i = 0; i < (int)mData.nodes_count; i++)
		{
			let node = &mData.nodes[i];
			if (node.parent != null)
			{
				model.Bones[i].ParentIndex = (int32)cgltf_node_index(mData, node.parent);
			}
		}
	}

	private void LoadSkins(Model model)
	{
		for (int i = 0; i < (int)mData.skins_count; i++)
		{
			let skinData = &mData.skins[i];
			let skin = new ModelSkin();

			if (skinData.name != null)
				skin.SetName(StringView(skinData.name));

			if (skinData.skeleton != null)
				skin.SkeletonRootIndex = (int32)cgltf_node_index(mData, skinData.skeleton);

			for (int j = 0; j < (int)skinData.joints_count; j++)
			{
				let jointNode = skinData.joints[j];
				int32 jointIndex = (int32)cgltf_node_index(mData, jointNode);

				Matrix ibm = .Identity;
				if (skinData.inverse_bind_matrices != null)
				{
					float[16] mat = .();
					cgltf_accessor_read_float(skinData.inverse_bind_matrices, (.)j, &mat, 16);
					// GLTF stores column-major for column-vector convention.
					// Transpose to row-vector convention by reading flat array directly into row-major storage.
					ibm = .(
						mat[0], mat[1], mat[2], mat[3],
						mat[4], mat[5], mat[6], mat[7],
						mat[8], mat[9], mat[10], mat[11],
						mat[12], mat[13], mat[14], mat[15]
					);
				}

				skin.AddJoint(jointIndex, ibm);

				// Also set on the bone
				if (jointIndex >= 0 && jointIndex < model.Bones.Count)
					model.Bones[jointIndex].InverseBindMatrix = ibm;
			}

			model.AddSkin(skin);
		}
	}

	private void LoadAnimations(Model model)
	{
		for (int i = 0; i < (int)mData.animations_count; i++)
		{
			let animData = &mData.animations[i];
			let animation = new ModelAnimation();

			if (animData.name != null)
				animation.SetName(StringView(animData.name));

			for (int c = 0; c < (int)animData.channels_count; c++)
			{
				let channelData = &animData.channels[c];
				let channel = new AnimationChannel();

				if (channelData.target_node != null)
					channel.TargetBone = (int32)cgltf_node_index(mData, channelData.target_node);

				switch (channelData.target_path)
				{
				case .cgltf_animation_path_type_translation: channel.Path = .Translation;
				case .cgltf_animation_path_type_rotation: channel.Path = .Rotation;
				case .cgltf_animation_path_type_scale: channel.Path = .Scale;
				case .cgltf_animation_path_type_weights: channel.Path = .Weights;
				default:
				}

				if (channelData.sampler != null)
				{
					let sampler = channelData.sampler;

					switch (sampler.interpolation)
					{
					case .cgltf_interpolation_type_step: channel.Interpolation = .Step;
					case .cgltf_interpolation_type_cubic_spline: channel.Interpolation = .CubicSpline;
					default: channel.Interpolation = .Linear;
					}

					if (sampler.input != null && sampler.output != null)
					{
						int32 keyframeCount = (int32)sampler.input.count;

						for (int32 k = 0; k < keyframeCount; k++)
						{
							float time = 0;
							cgltf_accessor_read_float(sampler.input, (.)k, &time, 1);

							Vector4 value = .Zero;
							switch (channel.Path)
							{
							case .Translation, .Scale:
								float[3] v3 = .();
								cgltf_accessor_read_float(sampler.output, (.)k, &v3, 3);
								value = .(v3[0], v3[1], v3[2], 0);
							case .Rotation:
								float[4] v4 = .();
								cgltf_accessor_read_float(sampler.output, (.)k, &v4, 4);
								value = .(v4[0], v4[1], v4[2], v4[3]);
							case .Weights:
								float w = 0;
								cgltf_accessor_read_float(sampler.output, (.)k, &w, 1);
								value.X = w;
							}

							channel.AddKeyframe(time, value);
						}
					}
				}

				animation.AddChannel(channel);
			}

			animation.CalculateDuration();
			model.AddAnimation(animation);
		}
	}
}
