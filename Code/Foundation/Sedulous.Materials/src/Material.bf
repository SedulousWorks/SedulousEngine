namespace Sedulous.Materials;

using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.Core.Mathematics;
using Sedulous.Shaders;

/// Property type for material parameters.
enum MaterialPropertyType : uint8
{
	Float,
	Float2,
	Float3,
	Float4,
	Int,
	Int2,
	Int3,
	Int4,
	Matrix4x4,
	Texture2D,
	TextureCube,
	Sampler
}

/// A single material property definition.
struct MaterialPropertyDef
{
	public StringView Name;
	public MaterialPropertyType Type;
	public uint32 Binding;      // Binding index in shader
	public uint32 Offset;       // Offset in uniform buffer (for scalar/vector types)
	public uint32 Size;         // Size in bytes

	public this(StringView name, MaterialPropertyType type, uint32 binding, uint32 offset = 0, uint32 size = 0)
	{
		Name = name;
		Type = type;
		Binding = binding;
		Offset = offset;
		Size = size;
	}

	/// Gets the size for a property type.
	public static uint32 GetSize(MaterialPropertyType type)
	{
		switch (type)
		{
		case .Float: return 4;
		case .Float2: return 8;
		case .Float3: return 12;
		case .Float4: return 16;
		case .Int: return 4;
		case .Int2: return 8;
		case .Int3: return 12;
		case .Int4: return 16;
		case .Matrix4x4: return 64;
		case .Texture2D, .TextureCube, .Sampler: return 0; // No uniform data
		}
	}

	public bool IsTexture => Type == .Texture2D || Type == .TextureCube;
	public bool IsSampler => Type == .Sampler;
	public bool IsUniform => !IsTexture && !IsSampler;
}

/// Material definition (shared, immutable template).
/// Defines shader, properties, and default values.
class Material
{
	/// Material name for debugging.
	public String Name = new .() ~ delete _;

	/// Shader name (looked up via ShaderSystem).
	public String ShaderName = new .() ~ delete _;

	/// Shader variant flags.
	public ShaderFlags ShaderFlags;

	/// Property definitions.
	private List<MaterialPropertyDef> mProperties = new .() ~ delete _;

	/// Owned property name strings (indexed by property index).
	private List<String> mPropertyNames = new .() ~ DeleteContainerAndItems!(_);

	/// Property name to index lookup.
	private Dictionary<StringView, int> mPropertyIndices = new .() ~ delete _;

	/// Default uniform buffer data.
	private uint8[] mDefaultUniformData ~ delete _;
	private uint32 mUniformDataSize = 0;

	/// Default texture bindings (by property index).
	private Dictionary<int, ITextureView> mDefaultTextures = new .() ~ delete _;

	/// Default sampler bindings (by property index).
	private Dictionary<int, ISampler> mDefaultSamplers = new .() ~ delete _;

	/// Pipeline configuration for this material.
	public PipelineConfig PipelineConfig;

	/// Clears all properties, uniform data, and bindings for in-place reload.
	/// Name, ShaderName, and PipelineConfig are preserved (overwritten by caller).
	public void ClearForReload()
	{
		for (let name in mPropertyNames) delete name;
		mPropertyNames.Clear();
		mProperties.Clear();
		mPropertyIndices.Clear();
		mDefaultTextures.Clear();
		mDefaultSamplers.Clear();
		delete mDefaultUniformData;
		mDefaultUniformData = null;
		mUniformDataSize = 0;
	}

	/// Whether this material is ready to use.
	public bool IsValid => ShaderName.Length > 0;

	/// Number of properties.
	public int PropertyCount => mProperties.Count;

	/// Gets a property definition by index.
	public MaterialPropertyDef GetProperty(int index)
	{
		if (index >= 0 && index < mProperties.Count)
			return mProperties[index];
		return default;
	}

	/// Gets a property definition by name.
	public MaterialPropertyDef? GetProperty(StringView name)
	{
		if (mPropertyIndices.TryGetValue(name, let index))
			return mProperties[index];
		return null;
	}

	/// Gets property index by name (-1 if not found).
	public int GetPropertyIndex(StringView name)
	{
		if (mPropertyIndices.TryGetValue(name, let index))
			return index;
		return -1;
	}

	/// Adds a property definition.
	/// The name is cloned so the caller's string doesn't need to outlive the material.
	public void AddProperty(MaterialPropertyDef prop)
	{
		let index = mProperties.Count;

		// Clone the name so Material owns it
		let ownedName = new String(prop.Name);
		mPropertyNames.Add(ownedName);

		// Update the property def to point to the owned name
		var ownedProp = prop;
		ownedProp.Name = ownedName;
		mProperties.Add(ownedProp);
		mPropertyIndices[StringView(ownedName)] = index;

		// Update uniform size if needed
		if (prop.IsUniform)
		{
			let endOffset = prop.Offset + prop.Size;
			if (endOffset > mUniformDataSize)
				mUniformDataSize = endOffset;
		}
	}

	/// Allocates default uniform data buffer.
	/// Preserves existing data when growing the buffer.
	public void AllocateDefaultUniformData()
	{
		if (mUniformDataSize > 0)
		{
			uint8[] newData = new uint8[mUniformDataSize];

			// Copy existing data if present (preserve previously set defaults)
			if (mDefaultUniformData != null)
			{
				let copyLen = Math.Min(mDefaultUniformData.Count, (int)mUniformDataSize);
				Internal.MemCpy(newData.Ptr, mDefaultUniformData.Ptr, copyLen);
				delete mDefaultUniformData;
			}

			mDefaultUniformData = newData;
		}
	}

	/// Sets a default float value.
	public void SetDefaultFloat(StringView name, float value)
	{
		if (let prop = GetProperty(name))
		{
			if (prop.IsUniform && mDefaultUniformData != null)
				*(float*)(&mDefaultUniformData[prop.Offset]) = value;
		}
	}

	/// Sets a default float2 value.
	public void SetDefaultFloat2(StringView name, Vector2 value)
	{
		if (let prop = GetProperty(name))
		{
			if (prop.IsUniform && mDefaultUniformData != null)
				*(Vector2*)(&mDefaultUniformData[prop.Offset]) = value;
		}
	}

	/// Sets a default float3 value.
	public void SetDefaultFloat3(StringView name, Vector3 value)
	{
		if (let prop = GetProperty(name))
		{
			if (prop.IsUniform && mDefaultUniformData != null)
				*(Vector3*)(&mDefaultUniformData[prop.Offset]) = value;
		}
	}

	/// Sets a default float4 value.
	public void SetDefaultFloat4(StringView name, Vector4 value)
	{
		if (let prop = GetProperty(name))
		{
			if (prop.IsUniform && mDefaultUniformData != null)
				*(Vector4*)(&mDefaultUniformData[prop.Offset]) = value;
		}
	}

	/// Sets a default color value.
	public void SetDefaultColor(StringView name, Vector4 color)
	{
		SetDefaultFloat4(name, color);
	}

	/// Sets a default texture.
	public void SetDefaultTexture(StringView name, ITextureView texture)
	{
		if (mPropertyIndices.TryGetValue(name, let index))
		{
			let prop = mProperties[index];
			if (prop.IsTexture)
				mDefaultTextures[index] = texture;
		}
	}

	/// Sets a default sampler.
	public void SetDefaultSampler(StringView name, ISampler sampler)
	{
		if (mPropertyIndices.TryGetValue(name, let index))
		{
			let prop = mProperties[index];
			if (prop.IsSampler)
				mDefaultSamplers[index] = sampler;
		}
	}

	/// Gets default uniform data.
	public Span<uint8> DefaultUniformData => mDefaultUniformData != null ? Span<uint8>(mDefaultUniformData) : default;

	/// Gets default uniform data size.
	public uint32 UniformDataSize => mUniformDataSize;

	/// Gets default texture for a property.
	public ITextureView GetDefaultTexture(int propertyIndex)
	{
		if (mDefaultTextures.TryGetValue(propertyIndex, let texture))
			return texture;
		return null;
	}

	/// Gets default sampler for a property.
	public ISampler GetDefaultSampler(int propertyIndex)
	{
		if (mDefaultSamplers.TryGetValue(propertyIndex, let sampler))
			return sampler;
		return null;
	}

	/// Iterates over all properties.
	public List<MaterialPropertyDef>.Enumerator Properties => mProperties.GetEnumerator();
}
