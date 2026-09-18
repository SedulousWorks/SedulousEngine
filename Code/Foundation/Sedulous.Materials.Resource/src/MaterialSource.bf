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
/// Version three, matching the cooked layout Raptor stamps.
[Serializable(3)]
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
}
