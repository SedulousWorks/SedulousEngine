using System;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.Shaders;

namespace Sedulous.Materials;

/// A fluent builder for authoring a material in code.
///
/// It does the two things that are tedious and easy to get subtly wrong by hand: laying the
/// uniform buffer out with the alignment the shader side expects, and handing out binding
/// ordinals in declaration order.
///
/// The builder OWNS the material until Build takes it, so a builder abandoned part way
/// through frees what it had started.
class MaterialBuilder
{
	private Material mMaterial ~ delete _;
	private uint32 mUniformOffset = 0;
	private uint32 mBinding = 0;

	public this(StringView name)
	{
		mMaterial = new Material();
		mMaterial.Name.Set(name);
	}

	public MaterialBuilder Shader(StringView shaderName)
	{
		mMaterial.ShaderName.Set(shaderName);
		// The config's view points at the material's OWN storage, so the two cannot drift
		// and the view lives exactly as long as the material.
		mMaterial.Pipeline.ShaderName = mMaterial.ShaderName;
		return this;
	}

	public MaterialBuilder Flags(ShaderFlags flags)
	{
		mMaterial.ShaderFlags = flags;
		mMaterial.Pipeline.ShaderFlags = flags;
		return this;
	}

	public MaterialBuilder VertexLayout(VertexLayoutType layout)
	{
		mMaterial.Pipeline.VertexLayout = layout;
		return this;
	}

	public MaterialBuilder Blend(BlendMode mode)
	{
		mMaterial.Pipeline.BlendMode = mode;
		return this;
	}

	public MaterialBuilder Depth(DepthMode mode)
	{
		mMaterial.Pipeline.DepthMode = mode;
		return this;
	}

	public MaterialBuilder Cull(CullModeConfig mode)
	{
		mMaterial.Pipeline.CullMode = mode;
		return this;
	}

	public MaterialBuilder DoubleSided()
	{
		mMaterial.Pipeline.CullMode = .None;
		return this;
	}

	/// Alpha blended and depth READ ONLY, which is the pair that makes a transparent draw
	/// behave: writing depth would occlude whatever blends after it.
	public MaterialBuilder Transparent()
	{
		mMaterial.Pipeline.BlendMode = .AlphaBlend;
		mMaterial.Pipeline.DepthMode = .ReadOnly;
		return this;
	}

	public MaterialBuilder Additive()
	{
		mMaterial.Pipeline.BlendMode = .Additive;
		mMaterial.Pipeline.DepthMode = .ReadOnly;
		return this;
	}

	// ---- uniform properties ----

	public MaterialBuilder Float(StringView name, float value = 0.0f)
	{
		AddUniform(name, .Float, 4, false);
		mMaterial.AllocateDefaultUniformData();
		mMaterial.SetDefaultFloat(name, value);
		return this;
	}

	public MaterialBuilder Float2(StringView name, Float2 value = .Zero)
	{
		AddUniform(name, .Float2, 8, false);
		mMaterial.AllocateDefaultUniformData();
		mMaterial.SetDefaultFloat2(name, value);
		return this;
	}

	/// A three component vector occupies SIXTEEN bytes, not twelve: that is the std140 rule
	/// every backend agrees on, and packing it tightly puts every following member at an
	/// offset the shader does not read from.
	public MaterialBuilder Float3(StringView name, Float3 value = .Zero)
	{
		AddUniform(name, .Float3, 12, true);
		mMaterial.AllocateDefaultUniformData();
		mMaterial.SetDefaultFloat3(name, value);
		return this;
	}

	public MaterialBuilder Float4(StringView name, Float4 value = .Zero)
	{
		AddUniform(name, .Float4, 16, true);
		mMaterial.AllocateDefaultUniformData();
		mMaterial.SetDefaultFloat4(name, value);
		return this;
	}

	/// A colour IS a four component vector. The name exists so a call site says which it
	/// means, and so the default is white rather than transparent black.
	public MaterialBuilder Color(StringView name, Float4 value = .(1, 1, 1, 1))
		=> Float4(name, value);

	// ---- resource properties ----

	public MaterialBuilder Texture(StringView name, ITextureView defaultView = null)
	{
		AddResource(name, .Texture2D);
		if (defaultView != null)
			mMaterial.SetDefaultTexture(name, defaultView);
		return this;
	}

	public MaterialBuilder TextureCube(StringView name, ITextureView defaultView = null)
	{
		AddResource(name, .TextureCube);
		if (defaultView != null)
			mMaterial.SetDefaultTexture(name, defaultView);
		return this;
	}

	public MaterialBuilder Sampler(StringView name, ISampler defaultSampler = null)
	{
		AddResource(name, .Sampler);
		if (defaultSampler != null)
			mMaterial.SetDefaultSampler(name, defaultSampler);
		return this;
	}

	/// Finishes and yields the material. THE CALLER OWNS what comes back, and the builder
	/// is empty afterwards.
	public Material Build()
	{
		mMaterial.AllocateDefaultUniformData();
		let finished = mMaterial;
		mMaterial = null;
		return finished;
	}

	private void AddUniform(StringView name, MaterialPropertyType type, uint32 size, bool align16)
	{
		if (align16)
			mUniformOffset = (mUniformOffset + 15) & ~(uint32)15;

		var def = MaterialPropertyDef();
		def.Name = name;
		def.Type = type;
		def.Binding = mBinding;
		def.Offset = mUniformOffset;
		def.Size = size;
		mMaterial.AddProperty(def);

		// A three or four component vector consumes a whole sixteen byte slot whatever its
		// declared size.
		mUniformOffset += align16 ? 16 : size;
		mBinding++;
	}

	private void AddResource(StringView name, MaterialPropertyType type)
	{
		var def = MaterialPropertyDef();
		def.Name = name;
		def.Type = type;
		def.Binding = mBinding++;
		mMaterial.AddProperty(def);
	}
}
