using System;
using System.Collections;
using System.Threading;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.Shaders;

namespace Sedulous.Materials;

/// The shared, immutable material TEMPLATE: a shader, a property list, a pipeline config
/// and the default values.
///
/// It is DATA. The material system reads the property list to infer the GPU bind group
/// layout, which is what lets a new material with a new shader need no renderer change at
/// all. Per use overrides live in a MaterialInstance rather than here, so one template
/// serves every object that shares it.
class Material
{
	private static int64 sNextUid;

	private List<MaterialPropertyDef> mProperties = new .() ~ delete _;
	/// STABLE backing for the property name views. A def's Name points in here, so these
	/// outlive every def and are never moved.
	private List<String> mPropertyNames = new .() ~ DeleteContainerAndItems!(_);
	private List<uint8> mDefaultUniformData = new .() ~ delete _;
	private uint32 mUniformDataSize = 0;

	private Dictionary<int, ITextureView> mDefaultTextures = new .() ~ delete _;
	private Dictionary<int, ISampler> mDefaultSamplers = new .() ~ delete _;

	/// Unique per OBJECT.
	///
	/// A renderer's caches key on THIS, never on the reference: a reloaded material is
	/// freed and the allocator can hand the replacement the same address, at which point a
	/// pointer keyed bind group serves the dead material's textures.
	public readonly uint64 Uid = (uint64)Interlocked.Increment(ref sNextUid);

	public String Name = new .() ~ delete _;
	public String ShaderName = new .() ~ delete _;
	public ShaderFlags ShaderFlags = .None;
	public PipelineConfig Pipeline = .();

	/// The address modes for this material's texture slots, which the importer wires from
	/// the source asset's sampler. The material system resolves the actual sampler from
	/// these when it builds an instance's bind group.
	public AddressMode SamplerU = .Repeat;
	public AddressMode SamplerV = .Repeat;

	/// A material with no shader cannot draw anything, which is the one thing that makes it
	/// unusable rather than merely empty.
	public bool IsValid => !ShaderName.IsEmpty;

	public int PropertyCount => mProperties.Count;
	public uint32 UniformDataSize => mUniformDataSize;

	public MaterialPropertyDef GetProperty(int index) => mProperties[index];

	public Span<MaterialPropertyDef> Properties => mProperties;

	/// The index of the named property, or -1.
	public int GetPropertyIndex(StringView name)
	{
		for (int i = 0; i < mProperties.Count; i++)
		{
			if (mProperties[i].Name == name)
				return i;
		}
		return -1;
	}

	public bool FindProperty(StringView name, out MaterialPropertyDef property)
	{
		let index = GetPropertyIndex(name);
		if (index < 0)
		{
			property = .();
			return false;
		}
		property = mProperties[index];
		return true;
	}

	/// Declares a property. The name is CLONED into stable backing, so the caller's string
	/// need not outlive the material.
	public void AddProperty(MaterialPropertyDef property)
	{
		let owned = new String(property.Name);
		mPropertyNames.Add(owned);

		var def = property;
		def.Name = owned;
		mProperties.Add(def);

		if (!def.IsUniform)
			return;

		let end = def.Offset + def.Size;
		if (end <= mUniformDataSize)
			return;

		// Rounded to constant buffer alignment. The shader side struct is padded to
		// sixteen bytes on every API, and WebGPU VALIDATES the bound range against the
		// struct's size: a sixty byte range under a sixty four byte buffer is rejected
		// outright. The buffer and the binding both use this size, so they agree.
		mUniformDataSize = (end + 15) & ~(uint32)15;
	}

	/// Grows the default uniform buffer to fit the declared properties, KEEPING whatever
	/// has already been written: defaults are commonly set between declarations.
	public void AllocateDefaultUniformData()
	{
		if (mUniformDataSize == 0)
			return;
		if (mDefaultUniformData.Count >= (int)mUniformDataSize)
			return;

		let previous = mDefaultUniformData.Count;
		mDefaultUniformData.Resize((int)mUniformDataSize);
		for (int i = previous; i < mDefaultUniformData.Count; i++)
			mDefaultUniformData[i] = 0;
	}

	public Span<uint8> DefaultUniformData => mDefaultUniformData;

	public void SetDefaultFloat(StringView name, float value) => WriteUniform(name, value);
	public void SetDefaultFloat2(StringView name, Float2 value) => WriteUniform(name, value);
	public void SetDefaultFloat3(StringView name, Float3 value) => WriteUniform(name, value);
	public void SetDefaultFloat4(StringView name, Float4 value) => WriteUniform(name, value);
	/// A colour IS a Float4; the name exists so a call site reads as what it means.
	public void SetDefaultColor(StringView name, Float4 color) => SetDefaultFloat4(name, color);

	public void SetDefaultTexture(StringView name, ITextureView texture)
	{
		let index = GetPropertyIndex(name);
		if ((index >= 0) && mProperties[index].IsTexture)
			mDefaultTextures[index] = texture;
	}

	public void SetDefaultSampler(StringView name, ISampler sampler)
	{
		let index = GetPropertyIndex(name);
		if ((index >= 0) && mProperties[index].IsSampler)
			mDefaultSamplers[index] = sampler;
	}

	public ITextureView GetDefaultTexture(int propertyIndex)
	{
		if (mDefaultTextures.TryGetValue(propertyIndex, let texture))
			return texture;
		return null;
	}

	public ISampler GetDefaultSampler(int propertyIndex)
	{
		if (mDefaultSamplers.TryGetValue(propertyIndex, let sampler))
			return sampler;
		return null;
	}

	/// Overlays a raw blob of authored defaults, which is how the resource factory restores
	/// what was cooked. A SHORT blob fills what it can and leaves the rest alone rather
	/// than truncating the buffer.
	public void SetRawDefaultUniformData(Span<uint8> data)
	{
		AllocateDefaultUniformData();
		let count = Min(data.Length, mDefaultUniformData.Count);
		if (count > 0)
			Internal.MemCpy(mDefaultUniformData.Ptr, data.Ptr, count);
	}

	/// Writes into the default buffer, and does NOTHING when the property is unknown, is
	/// not a uniform, or would not fit. Silence is right here: defaults are set by
	/// importers walking whatever a source file happened to declare, and a property the
	/// shader does not have is a source file being generous, not an error.
	private void WriteUniform<T>(StringView name, T value) where T : struct
	{
		let index = GetPropertyIndex(name);
		if (index < 0)
			return;

		let def = mProperties[index];
		if (!def.IsUniform || (((int)def.Offset + sizeof(T)) > mDefaultUniformData.Count))
			return;

		var local = value;
		Internal.MemCpy(mDefaultUniformData.Ptr + def.Offset, &local, sizeof(T));
	}
}
