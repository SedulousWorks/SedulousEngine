using System;

namespace Sedulous.Materials;

/// One declared property: its name, its kind, and where its bytes sit.
///
/// `Name` is a VIEW into the owning material's own name storage, so it lives exactly as
/// long as the material does. Copying a def out of a material and outliving it leaves a
/// dangling view.
struct MaterialPropertyDef
{
	public StringView Name = default;
	public MaterialPropertyType Type = .Float;
	/// The ordinal in the material's binding space.
	public uint32 Binding = 0;
	/// Byte offset into the uniform buffer. Meaningless for a texture or a sampler.
	public uint32 Offset = 0;
	public uint32 Size = 0;

	public this() {}

	public bool IsTexture => (Type == .Texture2D) || (Type == .TextureCube);
	public bool IsSampler => Type == .Sampler;
	/// Everything that carries uniform data, which is everything that is not a bound
	/// object.
	public bool IsUniform => !IsTexture && !IsSampler;

	/// The PACKED size of a uniform kind, and zero for a texture or a sampler, which carry
	/// no uniform data at all.
	public static uint32 SizeOf(MaterialPropertyType type)
	{
		switch (type)
		{
		case .Float, .Int: return 4;
		case .Float2, .Int2: return 8;
		case .Float3, .Int3: return 12;
		case .Float4, .Int4: return 16;
		case .Matrix4x4: return 64;
		case .Texture2D, .TextureCube, .Sampler: return 0;
		}
	}
}
