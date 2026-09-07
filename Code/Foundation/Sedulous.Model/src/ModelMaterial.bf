using System;
using Sedulous.Core;

namespace Sedulous.Model;

/// PBR material properties as an importer found them.
///
/// Texture references are INDICES into the model's texture list, not pointers, because
/// that is how the source formats express them and it survives the model being moved or
/// serialized.
class ModelMaterial
{
	public String Name = new .() ~ delete _;

	public Float4 BaseColorFactor = .(1, 1, 1, 1);
	public int32 BaseColorTextureIndex = -1;

	public float MetallicFactor = 1.0f;
	public float RoughnessFactor = 1.0f;
	/// The glTF style PACKED texture, with roughness in green and metallic in blue.
	public int32 MetallicRoughnessTextureIndex = -1;
	/// The FBX style SEPARATE greyscale maps. An importer bakes these into a packed
	/// texture; feeding either one straight into the packed slot bleeds one channel's
	/// values into the other two.
	public int32 SeparateRoughnessTextureIndex = -1;
	public int32 SeparateMetalnessTextureIndex = -1;

	public float NormalScale = 1.0f;
	public int32 NormalTextureIndex = -1;

	public float OcclusionStrength = 1.0f;
	public int32 OcclusionTextureIndex = -1;

	public Float3 EmissiveFactor = .Zero;
	public int32 EmissiveTextureIndex = -1;

	public AlphaMode AlphaMode = .Opaque;
	public float AlphaCutoff = 0.5f;

	public bool DoubleSided;
}
