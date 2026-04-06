namespace Sedulous.Materials;

using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.Core.Mathematics;

/// Manages materials, material instances, and their GPU resources.
/// Generates bind group layouts from material property definitions.
class MaterialSystem : IDisposable
{
	private IDevice mDevice;
	private IQueue mQueue;

	/// Bind group layout cache (keyed by layout hash).
	private Dictionary<int, IBindGroupLayout> mLayoutCache = new .() ~ delete _;

	/// Material uniform buffers (per material instance).
	private Dictionary<MaterialInstance, IBuffer> mUniformBuffers = new .() ~ delete _;

	/// Material bind groups (per material instance).
	private Dictionary<MaterialInstance, IBindGroup> mBindGroups = new .() ~ delete _;

	/// Default resources.
	private ISampler mDefaultSampler;
	private ITexture mWhiteTexture;
	private ITexture mNormalTexture;
	private ITexture mBlackTexture;
	private ITexture mDepthTexture;
	private ITextureView mWhiteTextureView;
	private ITextureView mNormalTextureView;
	private ITextureView mBlackTextureView;
	private ITextureView mDepthTextureView;

	/// Cached samplers keyed by (AddressModeU, AddressModeV).
	private Dictionary<int, ISampler> mSamplerCache = new .() ~ {
		for (var kv in _)
		{
			var s = kv.value;
			mDevice?.DestroySampler(ref s);
		}
		delete _;
	};

	/// Default PBR material (for meshes without assigned materials).
	private Material mDefaultMaterial ~ delete _;
	private MaterialInstance mDefaultMaterialInstance ~ _?.ReleaseRef();

	/// Cached default material bind group layout (owned by mLayoutCache, not deleted here).
	private IBindGroupLayout mDefaultMaterialLayout;

	/// Gets the default sampler (linear, clamp).
	public ISampler DefaultSampler => mDefaultSampler;

	/// Gets the white 1x1 texture view.
	public ITextureView WhiteTexture => mWhiteTextureView;

	/// Gets the flat normal 1x1 texture view.
	public ITextureView NormalTexture => mNormalTextureView;

	/// Gets the black 1x1 texture view.
	public ITextureView BlackTexture => mBlackTextureView;

	/// Gets the depth 1x1 texture view (for shadow fallback).
	public ITextureView DepthTexture => mDepthTextureView;

	/// Gets the device.
	public IDevice Device => mDevice;

	/// Gets the default PBR material.
	public Material DefaultMaterial => mDefaultMaterial;

	/// Gets the default material instance.
	public MaterialInstance DefaultMaterialInstance => mDefaultMaterialInstance;

	/// Gets the default material bind group layout.
	public IBindGroupLayout DefaultMaterialLayout => mDefaultMaterialLayout;

	/// Initializes the material system.
	public Result<void> Initialize(IDevice device, IQueue graphicsQueue)
	{
		if (device == null || graphicsQueue == null)
			return .Err;

		mDevice = device;
		mQueue = graphicsQueue;

		if (!CreateDefaultResources())
			return .Err;

		return .Ok;
	}

	/// Gets or creates a bind group layout for a material.
	/// Layout is inferred from the material's property definitions.
	public Result<IBindGroupLayout> GetOrCreateLayout(Material material)
	{
		if (material == null)
			return .Err;

		// Compute hash from material properties
		int layoutHash = ComputeLayoutHash(material);

		// Check cache
		if (mLayoutCache.TryGetValue(layoutHash, let cached))
			return cached;

		// Build layout entries from material properties
		List<BindGroupLayoutEntry> entries = scope .();

		// Check if we need a uniform buffer (any scalar properties)
		bool hasUniforms = false;
		for (let prop in material.Properties)
		{
			if (prop.IsUniform)
			{
				hasUniforms = true;
				break;
			}
		}

		// Add uniform buffer entry at binding 0 for material uniforms
		if (hasUniforms && material.UniformDataSize > 0)
			entries.Add(.UniformBuffer(0, .Fragment));

		// Track texture and sampler bindings
		int textureBinding = 0;
		int samplerBinding = 0;

		// Add texture/sampler entries
		for (let prop in material.Properties)
		{
			switch (prop.Type)
			{
			case .Texture2D, .TextureCube:
				// Textures start at binding 0 in the texture binding space
				entries.Add(.SampledTexture((uint32)textureBinding, .Fragment));
				textureBinding++;
			case .Sampler:
				entries.Add(.Sampler((uint32)samplerBinding, .Fragment));
				samplerBinding++;
			default:
				// Scalar params go in uniform buffer
			}
		}

		if (entries.Count == 0)
			return .Err;

		// Create layout
		Span<BindGroupLayoutEntry> entriesSpan = .(entries.Ptr, entries.Count);
		BindGroupLayoutDesc layoutDesc = .() { Entries = entriesSpan };

		if (mDevice.CreateBindGroupLayout(layoutDesc) case .Ok(let layout))
		{
			mLayoutCache[layoutHash] = layout;
			return layout;
		}

		return .Err;
	}

	/// Creates or updates a bind group for a material instance.
	/// Must call this before rendering with the material instance.
	public Result<IBindGroup> PrepareInstance(MaterialInstance instance, IBindGroupLayout layout = null)
	{
		if (instance == null || instance.Material == null)
			return .Err;

		let material = instance.Material;
		IBindGroupLayout bgLayout = layout;

		// Get or create layout if not provided
		if (bgLayout == null)
		{
			if (GetOrCreateLayout(material) case .Ok(let l))
				bgLayout = l;
			else
				return .Err;
		}

		// Create/update uniform buffer if dirty
		if (instance.IsUniformDirty && material.UniformDataSize > 0)
		{
			if (!UpdateUniformBuffer(instance))
				return .Err;
			instance.ClearUniformDirty();
		}

		// Create bind group if dirty
		if (instance.IsBindGroupDirty)
		{
			if (!UpdateBindGroup(instance, bgLayout))
				return .Err;
			instance.ClearBindGroupDirty();
		}

		// Return bind group
		if (mBindGroups.TryGetValue(instance, let bg))
			return bg;

		return .Err;
	}

	/// Gets the bind group for a material instance (returns null if not prepared).
	public IBindGroup GetBindGroup(MaterialInstance instance)
	{
		if (mBindGroups.TryGetValue(instance, let bg))
			return bg;
		return null;
	}

	/// Releases resources associated with a material instance.
	public void ReleaseInstance(MaterialInstance instance)
	{
		if (instance == null)
			return;

		if (mBindGroups.TryGetValue(instance, var bg))
		{
			// Clear the reference on the instance first
			instance.BindGroup = null;
			mDevice.DestroyBindGroup(ref bg);
			mBindGroups.Remove(instance);
		}

		if (mUniformBuffers.TryGetValue(instance, var buf))
		{
			mDevice.DestroyBuffer(ref buf);
			mUniformBuffers.Remove(instance);
		}
	}

	/// Clears all cached resources.
	public void ClearCache()
	{
		if (mDevice != null)
		{
			for (var kv in mBindGroups)
			{
				var bg = kv.value;
				mDevice.DestroyBindGroup(ref bg);
			}
			for (var kv in mUniformBuffers)
			{
				var buf = kv.value;
				mDevice.DestroyBuffer(ref buf);
			}
			for (var kv in mLayoutCache)
			{
				var layout = kv.value;
				mDevice.DestroyBindGroupLayout(ref layout);
			}
		}
		mBindGroups.Clear();
		mUniformBuffers.Clear();
		mLayoutCache.Clear();
	}

	public void Dispose()
	{
		ClearCache();

		if (mDevice != null)
		{
			mDevice.DestroyTextureView(ref mWhiteTextureView);
			mDevice.DestroyTextureView(ref mNormalTextureView);
			mDevice.DestroyTextureView(ref mBlackTextureView);
			mDevice.DestroyTextureView(ref mDepthTextureView);
			mDevice.DestroyTexture(ref mWhiteTexture);
			mDevice.DestroyTexture(ref mNormalTexture);
			mDevice.DestroyTexture(ref mBlackTexture);
			mDevice.DestroyTexture(ref mDepthTexture);
			mDevice.DestroySampler(ref mDefaultSampler);
		}
	}

	/// Gets or creates a sampler with the specified settings.
	/// Caches samplers by their combined settings to avoid duplicates.
	public ISampler GetOrCreateSampler(AddressMode addressU, AddressMode addressV,
		FilterMode minFilter = .Linear, FilterMode magFilter = .Linear, FilterMode mipmapFilter = .Linear)
	{
		let key = (int)addressU
			| ((int)addressV << 4)
			| ((int)minFilter << 8)
			| ((int)magFilter << 12)
			| ((int)mipmapFilter << 16);

		if (mSamplerCache.TryGetValue(key, let cached))
			return cached;

		SamplerDesc desc = .();
		desc.AddressU = addressU;
		desc.AddressV = addressV;
		desc.AddressW = .Repeat;
		desc.MinFilter = minFilter;
		desc.MagFilter = magFilter;
		desc.MipmapFilter = (mipmapFilter == .Linear) ? .Linear : .Nearest;

		if (mDevice.CreateSampler(desc) case .Ok(let sampler))
		{
			mSamplerCache[key] = sampler;
			return sampler;
		}

		return mDefaultSampler;
	}

	// ===== Private Methods =====

	private bool CreateDefaultResources()
	{
		// Create default sampler (linear, clamp)
		SamplerDesc samplerDesc = .();
		samplerDesc.AddressU = .ClampToEdge;
		samplerDesc.AddressV = .ClampToEdge;
		samplerDesc.AddressW = .ClampToEdge;
		samplerDesc.MinFilter = .Linear;
		samplerDesc.MagFilter = .Linear;
		samplerDesc.MipmapFilter = .Linear;

		if (mDevice.CreateSampler(samplerDesc) case .Ok(let sampler))
			mDefaultSampler = sampler;
		else
			return false;

		// Create white 1x1 texture
		if (!CreateTexture1x1(.(255, 255, 255, 255), out mWhiteTexture, out mWhiteTextureView))
			return false;

		// Create flat normal 1x1 texture (0.5, 0.5, 1.0 = pointing up in tangent space)
		if (!CreateTexture1x1(.(128, 128, 255, 255), out mNormalTexture, out mNormalTextureView))
			return false;

		// Create black 1x1 texture
		if (!CreateTexture1x1(.(0, 0, 0, 255), out mBlackTexture, out mBlackTextureView))
			return false;

		// Create 1x1 depth texture (for shadow fallback with comparison sampler)
		if (!CreateDepthTexture1x1())
			return false;

		// Create default PBR material
		if (!CreateDefaultMaterial())
			return false;

		return true;
	}

	private bool CreateDefaultMaterial()
	{
		// Create the default PBR material with standard texture slots
		mDefaultMaterial = Materials.CreatePBR("DefaultPBR", "forward", mWhiteTextureView, mDefaultSampler);

		// Create an instance of the default material
		mDefaultMaterialInstance = new MaterialInstance(mDefaultMaterial);

		// Get/create the layout for the default material
		if (GetOrCreateLayout(mDefaultMaterial) case .Ok(let layout))
			mDefaultMaterialLayout = layout;
		else
			return false;

		// Prepare the default instance (creates bind group)
		if (PrepareInstance(mDefaultMaterialInstance, mDefaultMaterialLayout) case .Err)
			return false;

		return true;
	}

	private bool CreateTexture1x1(Color32 color, out ITexture texture, out ITextureView view)
	{
		texture = null;
		view = null;

		// Create texture descriptor
		let texDesc = TextureDesc.Tex2D(.RGBA8Unorm, 1, 1, .Sampled | .CopyDst, label: "1x1");

		if (mDevice.CreateTexture(texDesc) case .Ok(let tex))
			texture = tex;
		else
			return false;

		// Upload pixel data
		uint8[4] data = .(color.R, color.G, color.B, color.A);
		var layout = TextureDataLayout()
		{
			BytesPerRow = 4,
			RowsPerImage = 1
		};
		var writeSize = Extent3D(1, 1, 1);

		// Upload via transfer batch
		let batchResult = mQueue.CreateTransferBatch();
		if (batchResult case .Err) return false;
		let tb = batchResult.Value;
		tb.WriteTexture(texture, Span<uint8>(&data[0], 4), layout, writeSize);
		tb.Submit();
		mDevice.WaitIdle();
		var tbRef = tb;
		mQueue.DestroyTransferBatch(ref tbRef);

		// Create view
		var viewDesc = TextureViewDesc()
		{
			Dimension = .Texture2D,
			Format = .RGBA8Unorm,
			BaseMipLevel = 0,
			MipLevelCount = 1,
			BaseArrayLayer = 0,
			ArrayLayerCount = 1,
			Label = "1x1View"
		};

		if (mDevice.CreateTextureView(texture, viewDesc) case .Ok(let v))
			view = v;
		else
			return false;

		return true;
	}

	private bool CreateDepthTexture1x1()
	{
		// Create 1x1 depth texture for shadow comparison fallback
		// Use DepthStencil to allow clearing, Sampled to allow sampling
		let texDesc = TextureDesc.Tex2D(.Depth32Float, 1, 1, .Sampled | .DepthStencil, label: "Depth1x1");

		if (mDevice.CreateTexture(texDesc) case .Ok(let tex))
			mDepthTexture = tex;
		else
			return false;

		// Create view with depth aspect
		var viewDesc = TextureViewDesc()
		{
			Dimension = .Texture2D,
			Format = .Depth32Float,
			BaseMipLevel = 0,
			MipLevelCount = 1,
			BaseArrayLayer = 0,
			ArrayLayerCount = 1,
			Aspect = .DepthOnly,
			Label = "Depth1x1View"
		};

		if (mDevice.CreateTextureView(mDepthTexture, viewDesc) case .Ok(let v))
			mDepthTextureView = v;
		else
			return false;

		// Clear the texture to transition from UNDEFINED to SHADER_READ_ONLY
		// by doing a dummy render pass with depth clear
		ClearDepthTexture();

		return true;
	}

	private void ClearDepthTexture()
	{
		// Create command pool + encoder to clear the depth texture
		let poolResult = mDevice.CreateCommandPool(.Graphics);
		if (poolResult case .Err) return;
		var cmdPool = poolResult.Value;

		let encResult = cmdPool.CreateEncoder();
		if (encResult case .Err) { mDevice.DestroyCommandPool(ref cmdPool); return; }
		var encoder = encResult.Value;

		// Render pass that clears depth
		var rpDesc = RenderPassDesc();
		rpDesc.DepthStencilAttachment = DepthStencilAttachment()
		{
			View = mDepthTextureView,
			DepthLoadOp = .Clear,
			DepthStoreOp = .Store,
			DepthClearValue = 1.0f,
			StencilLoadOp = .DontCare,
			StencilStoreOp = .DontCare
		};

		let rp = encoder.BeginRenderPass(rpDesc);
		rp.End();

		// Transition to ShaderRead for sampling
		var barrier = TextureBarrier()
		{
			Texture = mDepthTexture,
			OldState = .DepthStencilWrite,
			NewState = .ShaderRead
		};
		encoder.Barrier(BarrierGroup() { TextureBarriers = Span<TextureBarrier>(&barrier, 1) });

		let cmdBuf = encoder.Finish();
		ICommandBuffer[1] cmdBufs = .(cmdBuf);
		mQueue.Submit(Span<ICommandBuffer>(&cmdBufs[0], 1));
		mDevice.WaitIdle();

		cmdPool.Reset();
		cmdPool.DestroyEncoder(ref encoder);
		mDevice.DestroyCommandPool(ref cmdPool);
	}

	private int ComputeLayoutHash(Material material)
	{
		int hash = 17;

		// Include uniform buffer size
		hash = hash * 31 + (int)material.UniformDataSize;

		// Include each property type
		for (let prop in material.Properties)
		{
			hash = hash * 31 + (int)prop.Type;
			hash = hash * 31 + (int)prop.Binding;
		}

		return hash;
	}

	private bool UpdateUniformBuffer(MaterialInstance instance)
	{
		let material = instance.Material;
		if (material.UniformDataSize == 0)
			return true;

		IBuffer buffer = null;

		// Create buffer if doesn't exist
		if (!mUniformBuffers.TryGetValue(instance, out buffer))
		{
			let bufDesc = BufferDesc() { Size = (uint64)material.UniformDataSize, Usage = .Uniform, Memory = .CpuToGpu };
			if (mDevice.CreateBuffer(bufDesc) case .Ok(let buf))
			{
				buffer = buf;
				mUniformBuffers[instance] = buffer;
			}
			else
				return false;
		}

		// Upload uniform data via mapped pointer
		let data = instance.UniformData;
		if (data.Length > 0)
		{
			let ptr = buffer.Map();
			if (ptr != null)
			{
				Internal.MemCpy(ptr, data.Ptr, data.Length);
				buffer.Unmap();
			}
		}

		return true;
	}

	private bool UpdateBindGroup(MaterialInstance instance, IBindGroupLayout layout)
	{
		let material = instance.Material;
		List<BindGroupEntry> entries = scope .();

		// Add uniform buffer if present
		if (mUniformBuffers.TryGetValue(instance, let buffer))
		{
			entries.Add(.Buffer(buffer, 0, (uint64)material.UniformDataSize));
		}

		// Add textures and samplers
		int textureBinding = 0;
		int samplerBinding = 0;
		int propIndex = 0;

		for (let prop in material.Properties)
		{
			switch (prop.Type)
			{
			case .Texture2D, .TextureCube:
				var view = instance.GetTexture(propIndex);

				// Use appropriate default if not set
				if (view == null)
				{
					if (prop.Name.Contains("normal", true) || prop.Name.Contains("Normal", true))
						view = mNormalTextureView;
					else if (prop.Name.Contains("emissive", true) || prop.Name.Contains("Emissive", true))
						view = mBlackTextureView;
					else
						view = mWhiteTextureView;
				}

				if (view != null)
					entries.Add(.Texture(view));

				textureBinding++;

			case .Sampler:
				var sampler = instance.GetSampler(propIndex);
				if (sampler == null)
					sampler = mDefaultSampler;

				if (sampler != null)
					entries.Add(.Sampler(sampler));

				samplerBinding++;

			default:
				// Scalar params in uniform buffer
			}

			propIndex++;
		}

		if (entries.Count == 0)
			return false;

		// Delete old bind group
		if (mBindGroups.TryGetValue(instance, var oldBg))
		{
			instance.BindGroup = null; // clear reference first
			mDevice.DestroyBindGroup(ref oldBg);
			mBindGroups.Remove(instance);
		}

		// Create new bind group
		Span<BindGroupEntry> entriesSpan = .(entries.Ptr, entries.Count);
		let bgDesc = BindGroupDesc() { Layout = layout, Entries = entriesSpan };

		if (mDevice.CreateBindGroup(bgDesc) case .Ok(let bg))
		{
			mBindGroups[instance] = bg;
			instance.BindGroup = bg; // update reference
			return true;
		}

		return false;
	}
}

/// RGBA8 color for texture data.
[Packed, CRepr]
struct Color32
{
	public uint8 R, G, B, A;

	public this(uint8 r, uint8 g, uint8 b, uint8 a)
	{
		R = r;
		G = g;
		B = b;
		A = a;
	}
}
