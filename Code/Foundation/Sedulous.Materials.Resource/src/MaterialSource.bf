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
/// Version three.
[Serializable(3, true)] // afterRead: the stored colours typed on read
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
		return material;
	}

	/// Once read (the [Serializable] hook): stored colours typed as the template declares them.
	public void AfterRead()
	{
		AdoptTemplateColorTypes();
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
