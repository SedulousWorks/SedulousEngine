using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Model;
using Sedulous.Model.IO;
using Sedulous.Image;
using Sedulous.Image.DDS;
using Sedulous.Image.IO;
using cgltf_Beef;

namespace Sedulous.Model.GLTF;

/// Loads glTF and GLB files through cgltf.
///
/// Holds the parsed document until the next load or until it is deleted, because cgltf's
/// accessors point into it and the conversion below reads through them.
class GltfLoader : IModelLoader
{
	private cgltf_data* mData = null;
	private String mBasePath = new .() ~ delete _;

	public ~this()
	{
		FreeData();
	}

	/// @extension because `extension` is a Beef keyword.
	public bool SupportsExtension(StringView @extension)
		=> EqualsIgnoreCase(@extension, ".gltf") || EqualsIgnoreCase(@extension, ".glb");

	public ModelLoadResult Load(StringView path, ModelData model)
	{
		FreeData();

		// External images and .bin buffers are named relative to the file, so the
		// directory has to be kept for the rest of the load.
		mBasePath.Clear();
		PathParent(path, mBasePath);

		cgltf_options options = default;

		// A .glb whose bytes we hand over ourselves does not always auto detect, so the
		// type is stated when the extension says so.
		if (EndsWithIgnoreCase(path, ".glb"))
			options.type = .cgltf_file_type_glb;

		// Zero lets cgltf size the JSON token pool with a counting pass. A fixed cap fails
		// on larger documents with an unhelpful invalid_json, which is exactly the sort of
		// failure that gets blamed on the exporter.
		options.json_token_count = 0;

		// The file is read here rather than by cgltf, because its own fopen fails on some
		// path shapes on Windows.
		let bytes = scope List<uint8>();
		if (ReadFile(path, bytes) case .Err)
			return .FileNotFound;

		if (cgltf_parse(&options, bytes.Ptr, (cgltf_size)bytes.Count, &mData) != .cgltf_result_success)
		{
			mData = null;
			return .ParseError;
		}

		// Pulls in external .bin files. A GLB carries its buffers inside itself, and this
		// is a no-op for one.
		let pathZ = scope String(path);
		if (cgltf_load_buffers(&options, mData, pathZ) != .cgltf_result_success)
			return .InvalidData;

		// Validation failing is NOT fatal: exporters routinely produce files that violate
		// the spec in ways that load and render perfectly well, and refusing them would
		// reject most of the content people actually have.
		cgltf_validate(mData);

		// glTF is Y up by specification, so there is nothing to detect.
		model.OriginalUpAxis = .PositiveY;

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

	private void FreeData()
	{
		if (mData != null)
		{
			cgltf_free(mData);
			mData = null;
		}
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

	private static bool EndsWithIgnoreCase(StringView text, StringView suffix)
	{
		if (text.Length < suffix.Length)
			return false;
		return EqualsIgnoreCase(text.Substring(text.Length - suffix.Length), suffix);
	}

	/// cgltf hands back UTF-8 char*, and Beef strings are UTF-8, so this copies bytes and
	/// transcodes nothing.
	private static void AppendCString(String target, char8* text)
	{
		if (text != null)
			target.Append(StringView(text));
	}

	// -------------------------------------------------------------- materials

	private void LoadMaterials(ModelData model)
	{
		for (cgltf_size i = 0; i < mData.materials_count; i++)
		{
			let source = &mData.materials[i];
			let material = new ModelMaterial();

			if (source.name != null)
				AppendCString(material.Name, source.name);
			else
				material.Name.AppendF("m_texture{}", i);

			if (source.has_pbr_metallic_roughness != 0)
			{
				let pbr = &source.pbr_metallic_roughness;

				material.BaseColorFactor = .(pbr.base_color_factor[0], pbr.base_color_factor[1],
					pbr.base_color_factor[2], pbr.base_color_factor[3]);

				if (pbr.base_color_texture.texture != null)
					material.BaseColorTextureIndex = (int32)cgltf_texture_index(mData, pbr.base_color_texture.texture);

				material.MetallicFactor = pbr.metallic_factor;
				material.RoughnessFactor = pbr.roughness_factor;

				if (pbr.metallic_roughness_texture.texture != null)
					material.MetallicRoughnessTextureIndex =
						(int32)cgltf_texture_index(mData, pbr.metallic_roughness_texture.texture);
			}
			else if (source.has_pbr_specular_glossiness != 0)
			{
				// KHR_materials_pbrSpecularGlossiness, which is what a Lumberyard export ships:
				// the diffuse map and factor stand in for the base colour, the glossiness
				// inverts to roughness, and the surface is taken as dielectric. The specular
				// map is NOT converted, a true specular gloss to metal rough conversion being
				// a step of its own. Only reached when the material carries no metallic
				// roughness block, which is the one the standard prefers.
				let sg = &source.pbr_specular_glossiness;
				material.BaseColorFactor = .(sg.diffuse_factor[0], sg.diffuse_factor[1],
					sg.diffuse_factor[2], sg.diffuse_factor[3]);
				if (sg.diffuse_texture.texture != null)
					material.BaseColorTextureIndex =
						(int32)cgltf_texture_index(mData, sg.diffuse_texture.texture);
				material.MetallicFactor = 0.0f;
				material.RoughnessFactor = 1.0f - sg.glossiness_factor;
			}

			if (source.normal_texture.texture != null)
			{
				material.NormalTextureIndex = (int32)cgltf_texture_index(mData, source.normal_texture.texture);
				material.NormalScale = source.normal_texture.scale;
			}

			// glTF spells occlusion strength as the texture view's scale.
			if (source.occlusion_texture.texture != null)
			{
				material.OcclusionTextureIndex = (int32)cgltf_texture_index(mData, source.occlusion_texture.texture);
				material.OcclusionStrength = source.occlusion_texture.scale;
			}

			material.EmissiveFactor = .(source.emissive_factor[0], source.emissive_factor[1],
				source.emissive_factor[2]);

			if (source.emissive_texture.texture != null)
				material.EmissiveTextureIndex = (int32)cgltf_texture_index(mData, source.emissive_texture.texture);

			switch (source.alpha_mode)
			{
			case .cgltf_alpha_mode_mask: material.AlphaMode = .Mask;
			case .cgltf_alpha_mode_blend: material.AlphaMode = .Blend;
			default: material.AlphaMode = .Opaque;
			}

			material.AlphaCutoff = source.alpha_cutoff;
			material.DoubleSided = source.double_sided != 0;

			model.AddMaterial(material);
		}
	}

	// --------------------------------------------------------------- textures

	private static TextureWrap WrapFrom(cgltf_wrap_mode mode)
	{
		switch (mode)
		{
		case .cgltf_wrap_mode_clamp_to_edge: return .ClampToEdge;
		case .cgltf_wrap_mode_mirrored_repeat: return .MirroredRepeat;
		default: return .Repeat;
		}
	}

	private static TextureMinFilter MinFilterFrom(cgltf_filter_type filter)
	{
		switch (filter)
		{
		case .cgltf_filter_type_nearest: return .Nearest;
		case .cgltf_filter_type_linear: return .Linear;
		case .cgltf_filter_type_nearest_mipmap_nearest: return .NearestMipmapNearest;
		case .cgltf_filter_type_linear_mipmap_nearest: return .LinearMipmapNearest;
		case .cgltf_filter_type_nearest_mipmap_linear: return .NearestMipmapLinear;
		case .cgltf_filter_type_linear_mipmap_linear: return .LinearMipmapLinear;
		default: return .Nearest;
		}
	}

	private static TextureMagFilter MagFilterFrom(cgltf_filter_type filter)
	{
		switch (filter)
		{
		case .cgltf_filter_type_nearest,
			 .cgltf_filter_type_nearest_mipmap_nearest,
			 .cgltf_filter_type_nearest_mipmap_linear:
			return .Nearest;
		case .cgltf_filter_type_linear,
			 .cgltf_filter_type_linear_mipmap_nearest,
			 .cgltf_filter_type_linear_mipmap_linear:
			return .Linear;
		default: return .Nearest;
		}
	}

	private void LoadTextures(ModelData model)
	{
		for (cgltf_size i = 0; i < mData.textures_count; i++)
		{
			let source = &mData.textures[i];
			let texture = new ModelTexture();

			if (source.name != null)
				AppendCString(texture.Name, source.name);
			else if ((source.image != null) && (source.image.name != null))
				AppendCString(texture.Name, source.image.name);

			if (source.sampler != null)
				texture.SamplerIndex = (int32)cgltf_sampler_index(mData, source.sampler);

			// MSFT_texture_dds: the texture names a PNG or a JPEG source for readers without
			// DDS, and the GPU ready DDS in the extension. The DDS is preferred where both are
			// shipped, which is what a Lumberyard export does.
			var preferred = source.image;
			for (cgltf_size e = 0; e < source.extensions_count; e++)
			{
				let ext = source.extensions[e];
				if ((ext.name == null) || (ext.data == null)
					|| (StringView(ext.name) != "MSFT_texture_dds"))
					continue;
				let ddsIndex = ParseExtensionSource(ext.data);
				if ((ddsIndex >= 0) && ((cgltf_size)ddsIndex < mData.images_count))
					preferred = &mData.images[ddsIndex];
			}

			if (preferred != null)
			{
				let image = preferred;

				if (image.mime_type != null)
					AppendCString(texture.MimeType, image.mime_type);

				if (image.uri != null)
				{
					let uri = StringView(image.uri);
					texture.Uri.Append(uri);

					if (uri.StartsWith("data:"))
					{
						// A base64 payload carried inline, which is how a single file glTF
						// ships its images.
						let decoded = scope Image();
						if (LoadImageFromDataUri(image.uri, decoded))
							StoreImageData(decoded, texture);
					}
					else
					{
						let imagePath = scope String();
						PathJoin(mBasePath, uri, imagePath);
						// A DDS stays UNDECODED: it is GPU ready, and the pipeline passes its
						// levels through from the file rather than re-encoding them.
						if (Dds.IsDdsFile(imagePath))
						{
							texture.SourceFile.Set(imagePath);
						}
						else
						{
							let external = scope Image();
							if (ImageIO.LoadImage(imagePath, external) case .Ok)
								StoreImageData(external, texture);
						}
					}
				}
				else if (image.buffer_view != null)
				{
					// Embedded in a buffer, which is how a GLB carries its images.
					let bufferData = cgltf_buffer_view_data(image.buffer_view);
					let size = (int)image.buffer_view.size;
					if ((bufferData != null) && (size > 0))
					{
						let embedded = scope Image();
						if (ImageIO.LoadImageFromMemory(.(bufferData, size), embedded) case .Ok)
							StoreImageData(embedded, texture);
					}
				}
			}

			model.AddTexture(texture);
		}

		for (cgltf_size i = 0; i < mData.samplers_count; i++)
		{
			let source = &mData.samplers[i];
			var sampler = TextureSampler();
			sampler.WrapS = WrapFrom(source.wrap_s);
			sampler.WrapT = WrapFrom(source.wrap_t);
			sampler.MinFilter = MinFilterFrom(source.min_filter);
			sampler.MagFilter = MagFilterFrom(source.mag_filter);
			model.AddSampler(sampler);
		}

		// A texture with no sampler of its own gets the glTF default, which is repeat on
		// both axes. Leaving the index at -1 would push the decision onto every renderer.
		for (let texture in model.Textures)
		{
			if (texture.SamplerIndex < 0)
				texture.SamplerIndex = model.AddSampler(TextureSampler());
		}
	}

	// ----------------------------------------------------------------- images

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

	private static void StoreImageData(Image image, ModelTexture texture)
	{
		texture.Width = (int32)image.Width;
		texture.Height = (int32)image.Height;
		texture.PixelFormat = PixelFormatFrom(image.Format);

		let pixels = image.PixelData;
		if ((pixels.Ptr != null) && (pixels.Length > 0))
			texture.SetData(pixels);
	}

	/// Decodes a `data:` URI into an image.
	///
	/// cgltf's own base64 decoder is used rather than a second one, so a payload it can
	/// read here is one it could read anywhere else in the file.
	/// The `source` integer of a `{"source": N}` extension body, cgltf handing an extension
	/// over as raw JSON, or minus one when there is none.
	private static int ParseExtensionSource(char8* json)
	{
		let text = StringView(json);
		let key = text.IndexOf("\"source\"");
		if (key < 0)
			return -1;

		var at = key + 8;
		while ((at < text.Length)
			&& ((text[at] == ' ') || (text[at] == ':') || (text[at] == '\t')
				|| (text[at] == '\n') || (text[at] == '\r')))
		{
			at++;
		}
		if ((at >= text.Length) || (text[at] < '0') || (text[at] > '9'))
			return -1;

		var value = 0;
		while ((at < text.Length) && (text[at] >= '0') && (text[at] <= '9'))
		{
			value = value * 10 + (int)(text[at] - '0');
			at++;
		}
		return value;
	}

	private bool LoadImageFromDataUri(char8* dataUri, Image outImage)
	{
		// The shape is data:image/png;base64,<payload>, and only the payload matters.
		let text = StringView(dataUri);
		let comma = text.IndexOf(',');
		if (comma < 0)
			return false;

		let payload = dataUri + comma + 1;
		let payloadLength = text.Length - comma - 1;

		// Four base64 characters carry three bytes. Padding makes this an over estimate by
		// at most two, which decodes fine and only leaves a couple of unread bytes.
		let estimatedSize = (cgltf_size)((payloadLength * 3) / 4);

		void* decoded = null;
		cgltf_options options = default;
		if (cgltf_load_buffer_base64(&options, estimatedSize, payload, &decoded) != .cgltf_result_success)
			return false;
		defer Internal.StdFree(decoded);

		return ImageIO.LoadImageFromMemory(.((uint8*)decoded, (int)estimatedSize), outImage) case .Ok;
	}
	// ----------------------------------------------------------------- meshes

	private void LoadMeshes(ModelData model)
	{
		for (cgltf_size i = 0; i < mData.meshes_count; i++)
		{
			let source = &mData.meshes[i];
			let mesh = new ModelMesh();

			if (source.name != null)
				AppendCString(mesh.Name, source.name);

			if (source.primitives_count > 0)
				LoadMeshPrimitives(source, mesh);

			mesh.CalculateBounds();
			model.AddMesh(mesh);
		}
	}

	/// Merges every primitive of one glTF mesh into a single ModelMesh.
	///
	/// One vertex and index buffer with a part per primitive, rather than a mesh each: a
	/// primitive is a material change, not a separate object, and merging them means one
	/// buffer binding for the whole mesh.
	///
	/// The vertex layout is fixed and taken from the FIRST primitive. glTF allows the
	/// primitives of a mesh to differ, but in practice they do not, and one layout is what
	/// lets them share a buffer at all.
	private void LoadMeshPrimitives(cgltf_mesh* source, ModelMesh mesh)
	{
		let firstPrimitive = &source.primitives[0];

		bool isSkinned = false;
		bool hasNormals = false;
		bool hasTangents = false;
		for (cgltf_size a = 0; a < firstPrimitive.attributes_count; a++)
		{
			let attribute = &firstPrimitive.attributes[a];
			if ((attribute.type == .cgltf_attribute_type_joints) && (attribute.index == 0))
				isSkinned = true;
			if (attribute.type == .cgltf_attribute_type_normal)
				hasNormals = true;
			if (attribute.type == .cgltf_attribute_type_tangent)
				hasTangents = true;
		}

		mesh.HasNormals = hasNormals;
		mesh.HasTangents = hasTangents;

		// Every vertex carries a full set of slots whether the file supplies them or not,
		// so one shader works across every model rather than one per attribute
		// combination. The missing ones are filled with neutral defaults below.
		int32 stride = 0;

		let positionOffset = stride;
		stride += (int32)sizeof(Float3);
		mesh.AddVertexElement(.(.Position, .Float3, positionOffset));

		let normalOffset = stride;
		stride += (int32)sizeof(Float3);
		mesh.AddVertexElement(.(.Normal, .Float3, normalOffset));

		let texCoordOffset = stride;
		stride += (int32)sizeof(Float2);
		mesh.AddVertexElement(.(.TexCoord, .Float2, texCoordOffset));

		let colorOffset = stride;
		stride += (int32)sizeof(uint32);
		mesh.AddVertexElement(.(.Color, .Byte4, colorOffset));

		let tangentOffset = stride;
		stride += (int32)sizeof(Float4);
		mesh.AddVertexElement(.(.Tangent, .Float4, tangentOffset));

		int32 jointsOffset = 0;
		int32 weightsOffset = 0;
		if (isSkinned)
		{
			jointsOffset = stride;
			stride += (int32)(sizeof(uint16) * 4);
			mesh.AddVertexElement(.(.Joints, .UShort4, jointsOffset));

			weightsOffset = stride;
			stride += (int32)sizeof(Float4);
			mesh.AddVertexElement(.(.Weights, .Float4, weightsOffset));
		}

		int32 totalVertexCount = 0;
		int32 totalIndexCount = 0;
		for (cgltf_size p = 0; p < source.primitives_count; p++)
		{
			let primitive = &source.primitives[p];
			let positionCount = PositionCount(primitive);
			totalVertexCount += positionCount;
			// A primitive with no index accessor gets sequential indices generated for it,
			// so it costs one index per vertex. glTF permits non indexed geometry;
			// rendering it here does not.
			totalIndexCount += (primitive.indices != null) ? (int32)primitive.indices.count : positionCount;
		}

		if (totalVertexCount == 0)
			return;

		// Indices are widened for the whole mesh, not per primitive, because they all share
		// one buffer and a later primitive's remapped indices can exceed the short range
		// even when its own do not.
		let use32Bit = (totalIndexCount > 65535) || (totalVertexCount > 65535);
		mesh.AllocateVertices(totalVertexCount, stride);
		mesh.AllocateIndices(totalIndexCount, use32Bit);

		let vertexData = mesh.VertexData;
		let indexData = mesh.IndexData;

		int32 vertexOffset = 0;
		int32 indexOffset = 0;

		for (cgltf_size p = 0; p < source.primitives_count; p++)
		{
			let primitive = &source.primitives[p];

			cgltf_accessor* positions = null;
			cgltf_accessor* normals = null;
			cgltf_accessor* texCoords = null;
			cgltf_accessor* colors = null;
			cgltf_accessor* tangents = null;
			cgltf_accessor* joints = null;
			cgltf_accessor* weights = null;

			for (cgltf_size a = 0; a < primitive.attributes_count; a++)
			{
				let attribute = &primitive.attributes[a];
				switch (attribute.type)
				{
				case .cgltf_attribute_type_position: positions = attribute.data;
				case .cgltf_attribute_type_normal: normals = attribute.data;
				// Only the first set of each, because the layout above has one slot.
				case .cgltf_attribute_type_texcoord: if (attribute.index == 0) texCoords = attribute.data;
				case .cgltf_attribute_type_color: if (attribute.index == 0) colors = attribute.data;
				case .cgltf_attribute_type_tangent: tangents = attribute.data;
				case .cgltf_attribute_type_joints: if (attribute.index == 0) joints = attribute.data;
				case .cgltf_attribute_type_weights: if (attribute.index == 0) weights = attribute.data;
				default:
				}
			}

			// No positions is not geometry at all, so the primitive is skipped rather than
			// filled with zeroes.
			if (positions == null)
				continue;

			let primitiveVertexCount = (int32)positions.count;

			for (int32 v = 0; v < primitiveVertexCount; v++)
			{
				let vertex = vertexData + (vertexOffset + v) * stride;

				float[3] position = .(0, 0, 0);
				cgltf_accessor_read_float(positions, (cgltf_size)v, &position[0], 3);
				*(Float3*)(vertex + positionOffset) = .(position[0], position[1], position[2]);

				if (normals != null)
				{
					float[3] normal = .(0, 0, 0);
					cgltf_accessor_read_float(normals, (cgltf_size)v, &normal[0], 3);
					*(Float3*)(vertex + normalOffset) = .(normal[0], normal[1], normal[2]);
				}
				else
				{
					// Up, which at least lights consistently rather than turning the mesh
					// black.
					*(Float3*)(vertex + normalOffset) = .(0, 1, 0);
				}

				if (texCoords != null)
				{
					float[2] uv = .(0, 0);
					cgltf_accessor_read_float(texCoords, (cgltf_size)v, &uv[0], 2);
					*(Float2*)(vertex + texCoordOffset) = .(uv[0], uv[1]);
				}

				if (colors != null)
				{
					float[4] color = .(1, 1, 1, 1);
					cgltf_accessor_read_float(colors, (cgltf_size)v, &color[0], 4);
					let r = (uint32)Clamp(color[0] * 255.0f, 0.0f, 255.0f);
					let g = (uint32)Clamp(color[1] * 255.0f, 0.0f, 255.0f);
					let b = (uint32)Clamp(color[2] * 255.0f, 0.0f, 255.0f);
					let a = (uint32)Clamp(color[3] * 255.0f, 0.0f, 255.0f);
					*(uint32*)(vertex + colorOffset) = r | (g << 8) | (b << 16) | (a << 24);
				}
				else
				{
					// Opaque white, so a shader can multiply by the vertex colour
					// unconditionally.
					*(uint32*)(vertex + colorOffset) = 0xFFFFFFFF;
				}

				if (tangents != null)
				{
					float[4] tangent = .(1, 0, 0, 1);
					cgltf_accessor_read_float(tangents, (cgltf_size)v, &tangent[0], 4);
					// The fourth component is TBN handedness, not a coordinate: mirrored
					// UVs make it negative, and normalising it to exactly plus or minus one
					// keeps the bitangent cross product from being scaled by it.
					*(Float4*)(vertex + tangentOffset) =
						.(tangent[0], tangent[1], tangent[2], (tangent[3] < 0.0f) ? -1.0f : 1.0f);
				}
				else
				{
					*(Float4*)(vertex + tangentOffset) = .(1, 0, 0, 1);
				}

				if (isSkinned && (joints != null) && (weights != null))
				{
					cgltf_uint[4] jointIndices = .(0, 0, 0, 0);
					cgltf_accessor_read_uint(joints, (cgltf_size)v, &jointIndices[0], 4);
					let jointsDestination = (uint16*)(vertex + jointsOffset);
					jointsDestination[0] = (uint16)jointIndices[0];
					jointsDestination[1] = (uint16)jointIndices[1];
					jointsDestination[2] = (uint16)jointIndices[2];
					jointsDestination[3] = (uint16)jointIndices[3];

					float[4] jointWeights = .(0, 0, 0, 0);
					cgltf_accessor_read_float(weights, (cgltf_size)v, &jointWeights[0], 4);
					*(Float4*)(vertex + weightsOffset) =
						.(jointWeights[0], jointWeights[1], jointWeights[2], jointWeights[3]);
				}
			}

			// Indices are shifted by where this primitive's vertices landed in the shared
			// buffer, which is what merging costs.
			int32 primitiveIndexCount = 0;
			if (primitive.indices != null)
			{
				primitiveIndexCount = (int32)primitive.indices.count;
				if (use32Bit)
				{
					let indices = (uint32*)(indexData + indexOffset * 4);
					for (int32 i = 0; i < primitiveIndexCount; i++)
						indices[i] = (uint32)cgltf_accessor_read_index(primitive.indices, (cgltf_size)i)
							+ (uint32)vertexOffset;
				}
				else
				{
					let indices = (uint16*)(indexData + indexOffset * 2);
					for (int32 i = 0; i < primitiveIndexCount; i++)
						indices[i] = (uint16)((uint32)cgltf_accessor_read_index(primitive.indices, (cgltf_size)i)
							+ (uint32)vertexOffset);
				}
			}
			else
			{
				primitiveIndexCount = primitiveVertexCount;
				if (use32Bit)
				{
					let indices = (uint32*)(indexData + indexOffset * 4);
					for (int32 i = 0; i < primitiveIndexCount; i++)
						indices[i] = (uint32)(vertexOffset + i);
				}
				else
				{
					let indices = (uint16*)(indexData + indexOffset * 2);
					for (int32 i = 0; i < primitiveIndexCount; i++)
						indices[i] = (uint16)(vertexOffset + i);
				}
			}

			int32 materialIndex = -1;
			if (primitive.material != null)
				materialIndex = (int32)cgltf_material_index(mData, primitive.material);

			if (primitiveIndexCount > 0)
				mesh.AddPart(.(indexOffset, primitiveIndexCount, materialIndex));

			vertexOffset += primitiveVertexCount;
			indexOffset += primitiveIndexCount;
		}

		// One topology for the merged mesh, taken from the first primitive, for the same
		// reason as the layout.
		switch (firstPrimitive.type)
		{
		case .cgltf_primitive_type_triangles: mesh.Topology = .Triangles;
		case .cgltf_primitive_type_triangle_strip: mesh.Topology = .TriangleStrip;
		case .cgltf_primitive_type_lines: mesh.Topology = .Lines;
		case .cgltf_primitive_type_line_strip: mesh.Topology = .LineStrip;
		case .cgltf_primitive_type_points: mesh.Topology = .Points;
		default: mesh.Topology = .Triangles;
		}
	}

	/// How many vertices a primitive has, which is the count of its position accessor.
	private static int32 PositionCount(cgltf_primitive* primitive)
	{
		for (cgltf_size a = 0; a < primitive.attributes_count; a++)
		{
			if (primitive.attributes[a].type == .cgltf_attribute_type_position)
				return (int32)primitive.attributes[a].data.count;
		}
		return 0;
	}

	// ------------------------------------------------------------------ nodes

	private void LoadNodes(ModelData model)
	{
		// Bones first, parents after, because a node's parent can appear later in the
		// document than the node itself.
		for (cgltf_size i = 0; i < mData.nodes_count; i++)
		{
			let node = &mData.nodes[i];
			let bone = new ModelBone();

			if (node.name != null)
				AppendCString(bone.Name, node.name);

			if (node.has_translation != 0)
				bone.Translation = .(node.translation[0], node.translation[1], node.translation[2]);

			if (node.has_rotation != 0)
				bone.Rotation = .(node.rotation[0], node.rotation[1], node.rotation[2], node.rotation[3]);

			if (node.has_scale != 0)
				bone.Scale = .(node.scale[0], node.scale[1], node.scale[2]);

			// glTF stores the matrix column major for column vectors. Copying the flat
			// array straight into row major storage IS the transpose, which lands it in the
			// row vector convention used throughout.
			//
			// The translation, rotation and scale FIELDS are what every consumer reads, so
			// a node given only a matrix has to have them filled in too. Leaving them at
			// identity puts such a node at the origin with no rotation or scale, which is a
			// bug that only shows up on models exported with baked matrices.
			if (node.has_matrix != 0)
			{
				var nodeMatrix = Float4x4.Identity();
				Internal.MemCpy(nodeMatrix.Data, &node.matrix[0], sizeof(float) * 16);
				let trs = Transform.FromMatrix(nodeMatrix);
				bone.Translation = trs.Position;
				bone.Rotation = trs.Rotation;
				bone.Scale = trs.Scale;
			}
			bone.UpdateLocalTransform();

			if (node.mesh != null)
				bone.MeshIndex = (int32)cgltf_mesh_index(mData, node.mesh);

			if (node.skin != null)
				bone.SkinIndex = (int32)cgltf_skin_index(mData, node.skin);

			model.AddBone(bone);
		}

		for (cgltf_size i = 0; i < mData.nodes_count; i++)
		{
			let node = &mData.nodes[i];
			if (node.parent != null)
				model.Bones[(int)i].ParentIndex = (int32)cgltf_node_index(mData, node.parent);
		}
	}

	// ------------------------------------------------------------------ skins

	private void LoadSkins(ModelData model)
	{
		for (cgltf_size i = 0; i < mData.skins_count; i++)
		{
			let source = &mData.skins[i];
			let skin = new ModelSkin();

			if (source.name != null)
				AppendCString(skin.Name, source.name);

			if (source.skeleton != null)
				skin.SkeletonRootIndex = (int32)cgltf_node_index(mData, source.skeleton);

			for (cgltf_size j = 0; j < source.joints_count; j++)
			{
				let jointIndex = (int32)cgltf_node_index(mData, source.joints[j]);

				var inverseBind = Float4x4.Identity();
				if (source.inverse_bind_matrices != null)
				{
					float[16] values = default;
					cgltf_accessor_read_float(source.inverse_bind_matrices, j, &values[0], 16);
					// The same transpose by copy as a node's matrix.
					Internal.MemCpy(inverseBind.Data, &values[0], sizeof(float) * 16);
				}

				skin.AddJoint(jointIndex, inverseBind);

				// Also onto the bone, so skinning code that walks bones rather than the
				// skin has it to hand.
				if ((jointIndex >= 0) && (jointIndex < model.Bones.Length))
					model.Bones[jointIndex].InverseBindMatrix = inverseBind;
			}

			model.AddSkin(skin);
		}
	}

	// ------------------------------------------------------------- animations

	private void LoadAnimations(ModelData model)
	{
		for (cgltf_size i = 0; i < mData.animations_count; i++)
		{
			let source = &mData.animations[i];
			let animation = new ModelAnimation();

			if (source.name != null)
				AppendCString(animation.Name, source.name);

			for (cgltf_size c = 0; c < source.channels_count; c++)
			{
				let channelData = &source.channels[c];
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

					if ((sampler.input != null) && (sampler.output != null))
					{
						let keyframeCount = (int32)sampler.input.count;
						for (int32 k = 0; k < keyframeCount; k++)
						{
							float time = 0;
							cgltf_accessor_read_float(sampler.input, (cgltf_size)k, &time, 1);

							// One keyframe type carries every path, with the unused
							// components left at zero, so a channel is a flat array
							// whatever it animates.
							Float4 value = .Zero;
							switch (channel.Path)
							{
							case .Translation, .Scale:
								float[3] v3 = .(0, 0, 0);
								cgltf_accessor_read_float(sampler.output, (cgltf_size)k, &v3[0], 3);
								value = .(v3[0], v3[1], v3[2], 0);
							case .Rotation:
								float[4] v4 = .(0, 0, 0, 0);
								cgltf_accessor_read_float(sampler.output, (cgltf_size)k, &v4[0], 4);
								value = .(v4[0], v4[1], v4[2], v4[3]);
							case .Weights:
								float weight = 0;
								cgltf_accessor_read_float(sampler.output, (cgltf_size)k, &weight, 1);
								value.X = weight;
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
