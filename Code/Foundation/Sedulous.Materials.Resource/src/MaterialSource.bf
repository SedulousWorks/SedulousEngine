using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Materials;

namespace Sedulous.Materials.Resource;

/// An authored material: a shader reference, the declared properties, the render state
/// presets, and the packed default uniform blob.
///
/// The properties are PARALLEL ARRAYS rather than a list of structs, so the whole record
/// serializes through the primitive paths and a text form of it stays readable as columns.
///
/// Texture and sampler DEFAULTS for unbound slots are not stored: the material system
/// substitutes a neutral texture at bind time, and storing white in every asset would be a
/// thousand copies of a decision that belongs in one place. The texture slots that ARE
/// bound are stored, by resource id.
/// Version four: the effect groups (Effects). A version three record still reads, and a builtin
/// material's wind lanes migrate into a Wind group as it does (AfterRead).
[Serializable(4, true, 3)] // afterRead: the stored colours typed and the wind lanes migrated on read
class MaterialSource
{
	[DisplayName("Name")]
	public String Name = new .() ~ delete _;

	/// A cooked shader resource. NIL means fall back to ShaderName, which is how a builtin
	/// shader is referenced: it has no asset to point at.
	[DisplayName("Shader")]
	public Guid ShaderId = .();
	[DisplayName("Shader Name")]
	[Description("Builtin shader name fallback when Shader is unset")]
	public String ShaderName = new .() ~ delete _;
	[DisplayName("Shader Flags")]
	public uint32 ShaderFlags = 0;

	[DisplayName("Blend Mode")]
	public BlendMode BlendMode = .Opaque;
	[DisplayName("Depth Mode")]
	public DepthMode DepthMode = .ReadWrite;
	[DisplayName("Cull Mode")]
	public CullModeConfig CullMode = .Back;
	[DisplayName("Vertex Layout")]
	public VertexLayoutType VertexLayout = .Mesh;

	public List<String> PropertyNames = new .() ~ DeleteContainerAndItems!(_);
	/// MaterialPropertyType values.
	public List<uint8> PropertyTypes = new .() ~ delete _;
	public List<uint32> PropertyBindings = new .() ~ delete _;
	public List<uint32> PropertyOffsets = new .() ~ delete _;
	public List<uint32> PropertySizes = new .() ~ delete _;
	public List<uint8> UniformDefaults = new .() ~ delete _;

	/// Which slot takes which texture, by resource id. Parallel.
	///
	/// This is what makes a cooked material SELF CONTAINED. Without it only a model spawn
	/// wired textures up, so a material referenced directly rendered untextured.
	public List<String> TextureSlots = new .() ~ DeleteContainerAndItems!(_);
	public List<Guid> TextureIds = new .() ~ delete _;

	/// AddressMode values, wired from the source asset's sampler at import.
	[DisplayName("Sampler U")]
	public uint8 SamplerU = 0;
	[DisplayName("Sampler V")]
	public uint8 SamplerV = 0;

	/// The effect groups: one per effect the material's shader declares the variant of, apart
	/// from the shader's properties.
	[Appended(4)]
	public List<MaterialEffectGroupSource> Effects = new .() ~ DeleteContainerAndItems!(_);

	/// Captures a built material's declared layout and defaults into an authorable source
	/// referencing `shaderId`. What the editor's cook and the round trip tests use.
	public static void FromMaterial(Material material, Guid shaderId, MaterialSource outSource)
	{
		outSource.Name.Set(material.Name);
		outSource.ShaderId = shaderId;
		outSource.ShaderName.Set(material.ShaderName);
		outSource.ShaderFlags = (uint32)material.ShaderFlags;

		outSource.BlendMode = material.Pipeline.BlendMode;
		outSource.DepthMode = material.Pipeline.DepthMode;
		outSource.CullMode = material.Pipeline.CullMode;
		outSource.VertexLayout = material.Pipeline.VertexLayout;
		outSource.SamplerU = (uint8)material.SamplerU;
		outSource.SamplerV = (uint8)material.SamplerV;

		ClearAndDeleteItems!(outSource.PropertyNames);
		outSource.PropertyTypes.Clear();
		outSource.PropertyBindings.Clear();
		outSource.PropertyOffsets.Clear();
		outSource.PropertySizes.Clear();

		for (let property in material.Properties)
		{
			outSource.PropertyNames.Add(new String(property.Name));
			outSource.PropertyTypes.Add((uint8)property.Type);
			outSource.PropertyBindings.Add(property.Binding);
			outSource.PropertyOffsets.Add(property.Offset);
			outSource.PropertySizes.Add(property.Size);
		}

		outSource.UniformDefaults.Clear();
		outSource.UniformDefaults.AddRange(material.DefaultUniformData);

		ClearAndDeleteItems!(outSource.Effects);
		for (let group in material.EffectGroups)
		{
			let stored = new MaterialEffectGroupSource();
			MaterialEffectGroupSource.FromGroup(group, stored);
			outSource.Effects.Add(stored);
		}
	}

	/// A runtime material from this source, drawn with `shaderName`: its property layout, default
	/// values, render state and sampler addressing; its textures are left unbound (the factory
	/// resolves them through the resource manager, an editor preview through its own). The one
	/// conversion, so a preview draws what a loaded material draws. The caller owns the result.
	///
	/// The layout is taken verbatim. The offsets are the COOK's, not recomputed here: the shader
	/// was compiled against them, and rederiving them would be a second opinion that can disagree.
	public Material ToMaterial(StringView shaderName)
	{
		let material = new Material();
		material.Name.Set(Name);
		material.ShaderName.Set(shaderName);
		material.ShaderFlags = (Sedulous.Shaders.ShaderFlags)ShaderFlags;
		for (int i < PropertyNames.Count)
		{
			var def = MaterialPropertyDef();
			def.Name = PropertyNames[i];
			def.Type = (i < PropertyTypes.Count) ? (MaterialPropertyType)PropertyTypes[i] : .Float;
			def.Binding = (i < PropertyBindings.Count) ? PropertyBindings[i] : 0;
			def.Offset = (i < PropertyOffsets.Count) ? PropertyOffsets[i] : 0;
			def.Size = (i < PropertySizes.Count) ? PropertySizes[i] : 0;
			material.AddProperty(def);
		}
		material.AllocateDefaultUniformData();
		material.SetRawDefaultUniformData(UniformDefaults);

		material.Pipeline = .();
		material.Pipeline.ShaderName = material.ShaderName;
		material.Pipeline.ShaderFlags = material.ShaderFlags;
		material.Pipeline.BlendMode = BlendMode;
		material.Pipeline.DepthMode = DepthMode;
		material.Pipeline.CullMode = CullMode;
		material.Pipeline.VertexLayout = VertexLayout;
		material.SamplerU = (Sedulous.RHI.AddressMode)SamplerU;
		material.SamplerV = (Sedulous.RHI.AddressMode)SamplerV;
		// The effect groups, each as stored (the material needs nothing else to draw them).
		for (let group in Effects)
			group.ApplyTo(material);
		return material;
	}

	/// Once read (the [Serializable] hook): stored colours typed as the template declares them,
	/// and a builtin material's wind lanes moved into its Wind group.
	public void AfterRead()
	{
		AdoptTemplateColorTypes();
		MigrateWindLanes();
	}

	/// Before effect groups (data version 3), a PBR material carried the wind in its buffer's
	/// spare lanes as the properties WindStrength, WindSpeed and WindHeight (offsets 24, 28, 60).
	/// The wind is an effect now: the three properties go (their bytes stay, as the padding the
	/// buffer declares there) and the material gets a Wind group holding their values. The
	/// group's layout below is the effect's on the day of that change, frozen with the data it
	/// reads; the live table is wind.hlsli's effect block, onto which the factory re-lays the
	/// group, keeping these values, whenever it has the shader system. Only for a builtin
	/// shader's material whose template no longer declares the lanes: a custom shader may name
	/// properties of its own so. Idempotent: a migrated source has no lanes left.
	public void MigrateWindLanes()
	{
		if (ShaderId != Guid())
			return;
		StringView[3] lanes = .("WindStrength", "WindSpeed", "WindHeight");
		StringView[3] parameters = .("Strength", "Speed", "Height");
		float[3] values = .(0.0f, 1.0f, 1.0f); // a lane the source lacks
		var any = false;
		for (let name in PropertyNames)
		{
			for (let lane in lanes)
				any = any || (name == lane);
		}
		if (!any)
			return;
		let template = MaterialPresets.BuiltinTemplate(ShaderName);
		if (template == null)
			return;
		defer delete template;
		if (template.FindProperty(lanes[0], let ignored))
			return;

		var write = 0;
		let count = PropertyNames.Count;
		for (int i < count)
		{
			var lane = -1;
			for (int k < 3)
			{
				if (PropertyNames[i] == lanes[k])
					lane = k;
			}
			if (lane >= 0)
			{
				let offset = (i < PropertyOffsets.Count) ? PropertyOffsets[i] : uint32.MaxValue;
				if ((offset != uint32.MaxValue) && ((int)offset + sizeof(float) <= UniformDefaults.Count))
					values[lane] = *(float*)(UniformDefaults.Ptr + offset);
				delete PropertyNames[i];
				PropertyNames[i] = null;
				continue;
			}
			if (write != i)
			{
				PropertyNames[write] = PropertyNames[i];
				PropertyNames[i] = null;
				if (i < PropertyTypes.Count)
					PropertyTypes[write] = PropertyTypes[i];
				if (i < PropertyOffsets.Count)
					PropertyOffsets[write] = PropertyOffsets[i];
				if (i < PropertySizes.Count)
					PropertySizes[write] = PropertySizes[i];
			}
			if (write < PropertyBindings.Count)
				PropertyBindings[write] = (uint32)write; // a builtin's ordinals are its order
			write++;
		}
		PropertyNames.Count = write;
		PropertyTypes.Count = Math.Min(write, PropertyTypes.Count);
		PropertyOffsets.Count = Math.Min(write, PropertyOffsets.Count);
		PropertySizes.Count = Math.Min(write, PropertySizes.Count);
		PropertyBindings.Count = Math.Min(write, PropertyBindings.Count);

		for (let group in Effects)
		{
			if (group.Name == "Wind")
				return; // already carried
		}
		let wind = new MaterialEffectGroupSource();
		wind.Name.Set("Wind");
		wind.Flag = (uint32)Sedulous.Shaders.ShaderFlags.Wind;
		wind.GateIndex = 0;
		wind.UniformSize = 16;
		wind.Values.Count = 16;
		for (int b < 16)
			wind.Values[b] = 0;
		for (int k < 3)
		{
			wind.PropertyNames.Add(new String(parameters[k]));
			wind.PropertyTypes.Add((uint8)MaterialPropertyType.Float);
			wind.PropertyOffsets.Add((uint32)(k * sizeof(float)));
			wind.PropertySizes.Add((uint32)sizeof(float));
			*(float*)(wind.Values.Ptr + k * sizeof(float)) = values[k];
		}
		Effects.Add(wind);
	}

	/// A material stored before materials had colour properties declared its colours as
	/// Float4. A Float4 that the builtin template of this material's shader declares as a
	/// colour takes the template's colour type, so its value is treated as the sRGB colour it
	/// was entered as (and the editor shows a colour picker for it). Only the type changes,
	/// never an offset or a size. Idempotent; a custom shader's properties are left as they are.
	public void AdoptTemplateColorTypes()
	{
		let template = MaterialPresets.BuiltinTemplate(ShaderName);
		if (template == null)
			return;
		defer delete template;
		let count = Math.Min(PropertyNames.Count, PropertyTypes.Count);
		for (int i < count)
		{
			if (PropertyTypes[i] != (uint8)MaterialPropertyType.Float4)
				continue;
			if (template.FindProperty(PropertyNames[i], let def) && def.IsColor)
				PropertyTypes[i] = (uint8)def.Type;
		}
	}
}
