using System;
using System.IO;
using System.Collections;
using Sedulous.Resources;
using Sedulous.Materials;
using Sedulous.Core.Mathematics;
using Sedulous.Serialization;
using static Sedulous.Resources.ResourceSerializerExtensions;

namespace Sedulous.Materials.Resources;

/// CPU-side material resource for serialization.
/// Wraps a Material and can save/load it.
class MaterialResource : Resource
{
	public const int32 FileVersion = 1;
	public override ResourceType ResourceType => .("material");

	private Material mMaterial;
	private bool mOwnsMaterial;

	/// Sampler wrap modes for this material.
	public SamplerAddressMode WrapU = .Repeat;
	public SamplerAddressMode WrapV = .Repeat;

	/// Sampler filter modes for this material.
	public SamplerMinFilter MinFilter = .LinearMipmapLinear;
	public SamplerMagFilter MagFilter = .Linear;

	/// Texture references (slot name -> ResourceRef with GUID + path).
	/// At runtime, these refs are resolved to actual texture resources via the registry.
	public Dictionary<String, ResourceRef> TextureRefs = new .() ~ {
		for (var kv in _)
		{
			delete kv.key;
			kv.value.Dispose();
		}
		delete _;
	};

	/// The wrapped material.
	public Material Material => mMaterial;

	public this()
	{
		mMaterial = null;
		mOwnsMaterial = false;
	}

	public this(Material material, bool ownsMaterial = false)
	{
		mMaterial = material;
		mOwnsMaterial = ownsMaterial;
	}

	public ~this()
	{
		if (mOwnsMaterial && mMaterial != null)
			delete mMaterial;
	}

	/// Sets the material. Takes ownership if ownsMaterial is true.
	public void SetMaterial(Material material, bool ownsMaterial = false)
	{
		if (mOwnsMaterial && mMaterial != null)
			delete mMaterial;
		mMaterial = material;
		mOwnsMaterial = ownsMaterial;
	}

	/// Sets a texture reference for a slot.
	public void SetTextureRef(StringView slot, ResourceRef @ref)
	{
		// Remove old entry if exists (need to clean up owned key + ref path)
		for (var kv in TextureRefs)
		{
			if (StringView(kv.key) == slot)
			{
				let oldKey = kv.key;
				let oldPath = kv.value.Path;
				@kv.Remove();
				delete oldKey;
				delete oldPath;
				break;
			}
		}
		TextureRefs[new String(slot)] = @ref;
	}

	/// Sets a texture path for a slot (convenience — creates a ResourceRef with empty GUID).
	public void SetTexturePath(StringView slot, StringView path)
	{
		SetTextureRef(slot, ResourceRef(.(), path));
	}

	/// Gets the texture reference for a slot.
	public ResourceRef GetTextureRef(StringView slot)
	{
		if (TextureRefs.TryGetValue(scope String(slot), let @ref))
			return @ref;
		return .();
	}

	// ---- Serialization ----

	public override int32 SerializationVersion => FileVersion;

	protected override SerializationResult OnSerialize(Serializer s)
	{
		if (s.IsWriting)
		{
			if (mMaterial == null)
				return .InvalidData;

			// Write material name and shader
			s.String("materialName", mMaterial.Name);
			s.String("shaderName", mMaterial.ShaderName);

			// Write shader flags
			int32 shaderFlags = (int32)mMaterial.ShaderFlags;
			s.Int32("shaderFlags", ref shaderFlags);

			// Write sampler settings
			int32 wrapU = (int32)WrapU;
			int32 wrapV = (int32)WrapV;
			int32 minFilter = (int32)MinFilter;
			int32 magFilter = (int32)MagFilter;
			s.Int32("wrapU", ref wrapU);
			s.Int32("wrapV", ref wrapV);
			s.Int32("minFilter", ref minFilter);
			s.Int32("magFilter", ref magFilter);

			// Write full pipeline config
			SerializePipelineConfig(s, mMaterial.PipelineConfig);

			// Write property definitions
			int32 propCount = (int32)mMaterial.PropertyCount;
			s.Int32("propertyCount", ref propCount);

			for (int32 i = 0; i < propCount; i++)
			{
				let prop = mMaterial.GetProperty(i);
				s.BeginObject(scope $"prop{i}");

				String propName = scope String(prop.Name);
				s.String("name", propName);

				int32 propType = (int32)prop.Type;
				s.Int32("type", ref propType);

				uint32 binding = prop.Binding;
				uint32 offset = prop.Offset;
				uint32 size = prop.Size;
				s.UInt32("binding", ref binding);
				s.UInt32("offset", ref offset);
				s.UInt32("size", ref size);

				s.EndObject();
			}

			// Write uniform data
			let uniformData = mMaterial.DefaultUniformData;
			int32 uniformSize = (int32)uniformData.Length;
			s.Int32("uniformSize", ref uniformSize);

			if (uniformSize > 0)
			{
				let floatCount = uniformSize / 4;
				s.FixedFloatArray("uniformData", (float*)uniformData.Ptr, (int32)floatCount);
			}

			// Write texture refs
			int32 texCount = (int32)TextureRefs.Count;
			s.Int32("textureCount", ref texCount);

			int32 idx = 0;
			for (var kv in TextureRefs)
			{
				s.BeginObject(scope $"tex{idx}");
				String slot = scope String(kv.key);
				s.String("slot", slot);
				var texRef = kv.value;
				s.ResourceRef("texture", ref texRef);
				s.EndObject();
				idx++;
			}
		}
		else
		{
			// Read material name and shader
			String materialName = scope String();
			String shaderName = scope String();
			s.String("materialName", materialName);
			s.String("shaderName", shaderName);

			// Read shader flags
			int32 shaderFlags = 0;
			s.Int32("shaderFlags", ref shaderFlags);

			// Read sampler settings
			int32 wrapU = 0, wrapV = 0;
			int32 minFilter = (int32)SamplerMinFilter.LinearMipmapLinear;
			int32 magFilter = (int32)SamplerMagFilter.Linear;
			s.Int32("wrapU", ref wrapU);
			s.Int32("wrapV", ref wrapV);
			s.Int32("minFilter", ref minFilter);
			s.Int32("magFilter", ref magFilter);
			WrapU = (SamplerAddressMode)wrapU;
			WrapV = (SamplerAddressMode)wrapV;
			MinFilter = (SamplerMinFilter)minFilter;
			MagFilter = (SamplerMagFilter)magFilter;

			// Create material
			let mat = new Material();
			mat.Name.Set(materialName);
			mat.ShaderName.Set(shaderName);
			mat.ShaderFlags = (.)shaderFlags;

			// Read full pipeline config
			var pipelineConfig = PipelineConfig();
			DeserializePipelineConfig(s, ref pipelineConfig);
			mat.PipelineConfig = pipelineConfig;

			// Read property definitions
			int32 propCount = 0;
			s.Int32("propertyCount", ref propCount);

			for (int32 i = 0; i < propCount; i++)
			{
				s.BeginObject(scope $"prop{i}");

				String propName = scope String();
				s.String("name", propName);

				int32 propType = 0;
				s.Int32("type", ref propType);

				uint32 binding = 0, offset = 0, size = 0;
				s.UInt32("binding", ref binding);
				s.UInt32("offset", ref offset);
				s.UInt32("size", ref size);

				mat.AddProperty(.(propName, (MaterialPropertyType)propType, binding, offset, size));

				s.EndObject();
			}

			// Read uniform data
			int32 uniformSize = 0;
			s.Int32("uniformSize", ref uniformSize);

			if (uniformSize > 0)
			{
				mat.AllocateDefaultUniformData();
				let floatCount = uniformSize / 4;
				s.FixedFloatArray("uniformData", (float*)mat.DefaultUniformData.Ptr, (int32)floatCount);
			}

			SetMaterial(mat, true);

			// Read texture refs
			int32 texCount = 0;
			s.Int32("textureCount", ref texCount);

			for (int32 i = 0; i < texCount; i++)
			{
				s.BeginObject(scope $"tex{i}");
				String slot = scope String();
				s.String("slot", slot);
				var texRef = ResourceRef();
				s.ResourceRef("texture", ref texRef);
				TextureRefs[new String(slot)] = texRef;
				s.EndObject();
			}
		}

		return .Ok;
	}

	// ---- Pipeline Config Serialization ----

	private void SerializePipelineConfig(Serializer s, PipelineConfig config)
	{
		s.BeginObject("pipelineConfig");

		int32 vertexLayout = (int32)config.VertexLayout;
		int32 topology = (int32)config.Topology;
		int32 cullMode = (int32)config.CullMode;
		int32 frontFace = (int32)config.FrontFace;
		int32 fillMode = (int32)config.FillMode;
		int32 blendMode = (int32)config.BlendMode;
		int32 colorWriteMask = (int32)config.ColorWriteMask;
		int32 depthMode = (int32)config.DepthMode;
		int32 depthCompare = (int32)config.DepthCompare;
		int32 depthFormat = (int32)config.DepthFormat;
		int32 depthBias = (int32)config.DepthBias;
		float depthBiasSlopeScale = config.DepthBiasSlopeScale;
		int32 colorFormat = (int32)config.ColorFormats[0];
		int32 colorTargetCount = (int32)config.ColorTargetCount;
		int32 sampleCount = (int32)config.SampleCount;
		int32 depthOnly = config.DepthOnly ? 1 : 0;

		s.Int32("vertexLayout", ref vertexLayout);
		s.Int32("topology", ref topology);
		s.Int32("cullMode", ref cullMode);
		s.Int32("frontFace", ref frontFace);
		s.Int32("fillMode", ref fillMode);
		s.Int32("blendMode", ref blendMode);
		s.Int32("colorWriteMask", ref colorWriteMask);
		s.Int32("depthMode", ref depthMode);
		s.Int32("depthCompare", ref depthCompare);
		s.Int32("depthFormat", ref depthFormat);
		s.Int32("depthBias", ref depthBias);
		s.Float("depthBiasSlopeScale", ref depthBiasSlopeScale);
		s.Int32("colorFormat", ref colorFormat);
		s.Int32("colorTargetCount", ref colorTargetCount);
		s.Int32("sampleCount", ref sampleCount);
		s.Int32("depthOnly", ref depthOnly);

		s.EndObject();
	}

	private void DeserializePipelineConfig(Serializer s, ref PipelineConfig config)
	{
		s.BeginObject("pipelineConfig");

		int32 vertexLayout = 0, topology = 0, cullMode = 0, frontFace = 0, fillMode = 0;
		int32 blendMode = 0, colorWriteMask = 0, depthMode = 0, depthCompare = 0;
		int32 depthFormat = 0, depthBias = 0, colorFormat = 0;
		int32 colorTargetCount = 0, sampleCount = 0, depthOnly = 0;
		float depthBiasSlopeScale = 0;

		s.Int32("vertexLayout", ref vertexLayout);
		s.Int32("topology", ref topology);
		s.Int32("cullMode", ref cullMode);
		s.Int32("frontFace", ref frontFace);
		s.Int32("fillMode", ref fillMode);
		s.Int32("blendMode", ref blendMode);
		s.Int32("colorWriteMask", ref colorWriteMask);
		s.Int32("depthMode", ref depthMode);
		s.Int32("depthCompare", ref depthCompare);
		s.Int32("depthFormat", ref depthFormat);
		s.Int32("depthBias", ref depthBias);
		s.Float("depthBiasSlopeScale", ref depthBiasSlopeScale);
		s.Int32("colorFormat", ref colorFormat);
		s.Int32("colorTargetCount", ref colorTargetCount);
		s.Int32("sampleCount", ref sampleCount);
		s.Int32("depthOnly", ref depthOnly);

		config.VertexLayout = (.)vertexLayout;
		config.Topology = (.)topology;
		config.CullMode = (.)cullMode;
		config.FrontFace = (.)frontFace;
		config.FillMode = (.)fillMode;
		config.BlendMode = (.)blendMode;
		config.ColorWriteMask = (.)colorWriteMask;
		config.DepthMode = (.)depthMode;
		config.DepthCompare = (.)depthCompare;
		config.DepthFormat = (.)depthFormat;
		config.DepthBias = (int16)depthBias;
		config.DepthBiasSlopeScale = depthBiasSlopeScale;
		config.ColorFormats[0] = (.)colorFormat;
		config.ColorTargetCount = (uint8)colorTargetCount;
		config.SampleCount = (uint8)sampleCount;
		config.DepthOnly = depthOnly != 0;

		s.EndObject();
	}

}
