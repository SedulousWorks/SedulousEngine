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
	/// In the order the shader's effects were adopted.
	private List<MaterialEffectGroup> mEffectGroups = new .() ~ DeleteContainerAndItems!(_);

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
	/// The shader's own programs for the depth like passes (the camera depth prepass, the shadow
	/// maps, the editor's pick), when it has them (a surface shader that moves its vertices or
	/// cuts out with its own alpha); empty is the built-in `shadow_depth` and `pick_ids`.
	public String DepthShaderName = new .() ~ delete _;
	public String PickShaderName = new .() ~ delete _;
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

	// ---- effect groups ----

	public int EffectGroupCount => mEffectGroups.Count;
	public MaterialEffectGroup GetEffectGroup(int index) => mEffectGroups[index];
	public Span<MaterialEffectGroup> EffectGroups => mEffectGroups;

	/// The index of the named effect's group, or -1.
	public int FindEffectGroup(StringView effectName)
	{
		for (int i < mEffectGroups.Count)
		{
			if (mEffectGroups[i].Name == effectName)
				return i;
		}
		return -1;
	}

	/// Splits `Effect.Property` at its dot. False for a name without one (a shader property's:
	/// HLSL identifiers have no dot, so the dot alone says which set a name addresses).
	public static bool SplitEffectPropertyName(StringView qualified, out StringView effect, out StringView property)
	{
		let dot = qualified.IndexOf('.');
		if (dot < 0)
		{
			effect = default;
			property = default;
			return false;
		}
		effect = qualified.Substring(0, dot);
		property = qualified.Substring(dot + 1);
		return true;
	}

	/// The parameter `Effect.Property` names, and its group's index; false when the material
	/// carries no such group or the group no such parameter.
	public bool FindEffectProperty(StringView qualified, out MaterialPropertyDef property, out int group)
	{
		property = .();
		group = -1;
		if (!SplitEffectPropertyName(qualified, let effect, let name))
			return false;
		let index = FindEffectGroup(effect);
		if ((index < 0) || !mEffectGroups[index].FindProperty(name, out property))
			return false;
		group = index;
		return true;
	}

	/// Adds an effect's group (replacing one of the same name): its parameters' names, types and
	/// offsets in the effect's buffer, the gate's index and the buffer's size, and the values
	/// (`uniformSize` bytes; shorter is zero filled). What a material from an asset restores from
	/// its source.
	public void SetEffectGroup(StringView effectName, ShaderFlags flag, uint32 gateIndex, uint32 uniformSize,
		Span<MaterialPropertyDef> properties, Span<uint8> values)
	{
		let group = new MaterialEffectGroup();
		group.Name.Set(effectName);
		group.Flag = flag;
		group.GateIndex = gateIndex;
		group.UniformSize = CbufferRowSize(uniformSize);
		for (let def in properties)
		{
			group.AddProperty(def);
			group.UniformSize = Math.Max(group.UniformSize, CbufferRowSize(def.Offset + def.Size));
		}
		group.Defaults.Count = (int)group.UniformSize;
		for (int i < group.Defaults.Count)
			group.Defaults[i] = 0;
		let count = Math.Min(values.Length, group.Defaults.Count);
		if (count > 0)
			Internal.MemCpy(group.Defaults.Ptr, values.Ptr, count);
		let existing = FindEffectGroup(effectName);
		if (existing >= 0)
		{
			delete mEffectGroups[existing];
			mEffectGroups[existing] = group;
		}
		else
			mEffectGroups.Add(group);
	}

	/// Adds an effect's group from the effect's table (the shader system's, from the effect
	/// block), at the effect's defaults: what a material built in code takes from whoever holds
	/// the shader system. An effect takes uniforms only, so every parameter is one.
	public void AddEffectGroup(ShaderEffect effect)
	{
		let defs = scope List<MaterialPropertyDef>();
		let values = scope List<uint8>();
		values.Count = (int)effect.UniformSize;
		for (int i < values.Count)
			values[i] = 0;
		for (int i < effect.Properties.Count)
		{
			let property = effect.Properties[i];
			var def = MaterialPropertyDef();
			def.Name = property.Name;
			def.Type = MaterialPropertyTypes.Of(property.Type);
			def.Binding = (uint32)i;
			def.Offset = property.Offset;
			def.Size = property.Size;
			defs.Add(def);
			if ((property.Size == 0) || ((int)property.Offset + (int)property.Size > values.Count))
				continue;
			if (property.Type == .Int)
				*(int32*)(values.Ptr + property.Offset) = (int32)property.Value.X; // an int as the shader reads it
			else
			{
				float[4] components = .(property.Value.X, property.Value.Y, property.Value.Z, property.Value.W);
				Internal.MemCpy(values.Ptr + property.Offset, &components[0], Math.Min((int)property.Size, sizeof(float[4])));
			}
		}
		SetEffectGroup(effect.Name, effect.Flag, effect.GateIndex, effect.UniformSize, defs, values);
	}

	/// Adds the group of every effect in `effects` whose flag `vertexVariants` declares (the
	/// variants line of the material's shader's vertex stage), and drops any group whose effect
	/// the shader no longer declares. A group already carried keeps the values whose name, type
	/// and size still fit (an effect's table may have grown since it was saved).
	public void AdoptDeclaredEffects(Span<ShaderEffect> effects, ShaderFlags vertexVariants)
	{
		let kept = scope List<MaterialEffectGroup>();
		for (let effect in effects)
		{
			if (!vertexVariants.HasFlag(effect.Flag))
				continue;
			MaterialEffectGroup previous = null;
			let old = FindEffectGroup(effect.Name);
			if (old >= 0)
			{
				previous = mEffectGroups[old];
				mEffectGroups.RemoveAt(old);
			}
			AddEffectGroup(effect);
			let fresh = mEffectGroups.PopBack();
			if (previous != null)
			{
				for (let def in fresh.Properties)
				{
					if (previous.FindProperty(def.Name, let was) && (was.Type == def.Type) && (was.Size == def.Size)
						&& ((int)was.Offset + (int)was.Size <= previous.Defaults.Count)
						&& ((int)def.Offset + (int)def.Size <= fresh.Defaults.Count))
						Internal.MemCpy(fresh.Defaults.Ptr + (int)def.Offset, previous.Defaults.Ptr + (int)was.Offset, (int)def.Size);
				}
				delete previous;
			}
			kept.Add(fresh);
		}
		ClearAndDeleteItems!(mEffectGroups);
		mEffectGroups.AddRange(kept);
	}

	/// A copy of this material, with its own uid: its shader, pipeline state, properties, values,
	/// effect groups, textures and samplers (the views and samplers shared, borrowed as the
	/// original's are). For a caller that draws a variant without touching the shared material (the
	/// import preview drawing it without a texture the import leaves out). THE CALLER OWNS it.
	public Material Clone()
	{
		let copy = new Material();
		copy.SamplerU = SamplerU;
		copy.SamplerV = SamplerV;
		copy.Name.Set(Name);
		copy.ShaderName.Set(ShaderName);
		copy.DepthShaderName.Set(DepthShaderName);
		copy.PickShaderName.Set(PickShaderName);
		copy.ShaderFlags = ShaderFlags;
		copy.Pipeline = Pipeline;
		// The config's name is a view: of this material's own name (the builder's, the source's), it
		// becomes the copy's, which outlives this.
		if (Pipeline.ShaderName.Ptr == ShaderName.Ptr)
			copy.Pipeline.ShaderName = copy.ShaderName;
		for (let property in mProperties)
			copy.AddProperty(property); // its own copy of the name
		copy.AllocateDefaultUniformData();
		copy.SetRawDefaultUniformData(mDefaultUniformData);
		for (let group in mEffectGroups)
			copy.SetEffectGroup(group.Name, group.Flag, group.GateIndex, group.UniformSize, group.Properties, group.Defaults);
		for (let (index, texture) in mDefaultTextures)
			copy.mDefaultTextures[index] = texture;
		for (let (index, sampler) in mDefaultSamplers)
			copy.mDefaultSamplers[index] = sampler;
		return copy;
	}

	public void ClearEffectGroups()
	{
		ClearAndDeleteItems!(mEffectGroups);
	}

	private static uint32 CbufferRowSize(uint32 bytes) => (bytes + 15) & ~(uint32)15;

	/// Writes into the default buffer, and does NOTHING when the property is unknown, is
	/// not a uniform, or would not fit. Silence is right here: defaults are set by
	/// importers walking whatever a source file happened to declare, and a property the
	/// shader does not have is a source file being generous, not an error. An `Effect.Property`
	/// name writes its group's values.
	private void WriteUniform<T>(StringView name, T value) where T : struct
	{
		if (FindEffectProperty(name, let effect, let group))
		{
			let values = mEffectGroups[group].Defaults;
			if ((sizeof(T) <= (int)effect.Size) && ((int)effect.Offset + sizeof(T) <= values.Count))
			{
				var local = value;
				Internal.MemCpy(values.Ptr + effect.Offset, &local, sizeof(T));
			}
			return;
		}

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
