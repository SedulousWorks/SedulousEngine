using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.Materials;

/// Owns the GPU side of material instances, and INFERS the bind group layout from a
/// material's declared properties.
///
/// That inference is the whole idea. Uniforms become one buffer at binding zero; each
/// texture and each sampler becomes an entry of its own. A new material with a custom
/// shader therefore needs no renderer change: it declares what it has and the layout
/// follows.
///
/// Layouts are cached by content, so materials sharing a property shape share one layout.
/// Buffers and bind groups are built lazily, and an instance notifies on becoming dirty, so
/// the per frame pass costs what CHANGED rather than what exists.
class MaterialSystem : IMaterialInstanceSink
{
	/// How many frames a replaced bind group waits before it is freed.
	private const uint32 cRetireFrames = 3;

	private struct RetiredBindGroup
	{
		public IBindGroup Group;
		public uint32 FramesLeft;
	}

	private IDevice mDevice;
	private IQueue mQueue;
	private ISampler mDefaultSampler;

	private ITexture mWhiteTexture;
	private ITextureView mWhiteView;
	private ITexture mNormalTexture;
	private ITextureView mNormalView;
	private ITexture mBlackTexture;
	private ITextureView mBlackView;

	private Dictionary<uint64, IBindGroupLayout> mLayoutCache = new .() ~ delete _;
	private Dictionary<uint64, ISampler> mSamplerCache = new .() ~ delete _;
	private Dictionary<MaterialInstance, IBuffer> mUniformBuffers = new .() ~ delete _;
	/// Each instance's effect group buffers, by group index (null for a group without uniforms).
	private Dictionary<MaterialInstance, List<IBuffer>> mEffectBuffers = new .() ~ DeleteDictionaryAndValues!(_);
	/// The binding the first effect group's buffer takes in the material's set (b1:
	/// ShaderProperties.cEffectRegister).
	private const uint32 cFirstEffectBinding = 1;
	private Dictionary<MaterialInstance, IBindGroup> mBindGroups = new .() ~ delete _;
	private List<MaterialInstance> mDirty = new .() ~ delete _;
	private List<RetiredBindGroup> mRetiredBindGroups = new .() ~ delete _;

	public ~this()
	{
		Shutdown();
	}

	/// Binds to a device and creates the fallback resources an unbound texture slot needs.
	public Result<void, ErrorCode> Initialize(IDevice device)
	{
		mDevice = device;
		mQueue = device.GetQueue(.Graphics);
		if (mQueue == null)
			return .Err(.Unknown);

		return CreateDefaultResources();
	}

	public IDevice Device => mDevice;
	public ISampler DefaultSampler => mDefaultSampler;
	/// White, because albedo, metallic-roughness and occlusion all MULTIPLY: white is the
	/// identity for an unbound slot.
	public ITextureView WhiteTexture => mWhiteView;
	/// Flat normal: (0.5, 0.5, 1) decodes to the geometric normal.
	public ITextureView NormalTexture => mNormalView;
	/// Black: no unbound slot binds it (an emissive map's neutral is white); a stand in for a
	/// texture that should read nought.
	public ITextureView BlackTexture => mBlackView;

	/// Brings the instance's uniform buffer up to date and hands it back, or null when the
	/// material declares no uniforms.
	///
	/// Exists so a renderer with its own fixed bind group layout can still source packed
	/// uniform data from here rather than duplicating the packing.
	public IBuffer EnsureUniformBuffer(MaterialInstance instance)
	{
		let material = instance.Material;
		if ((material == null) || (material.UniformDataSize == 0))
			return null;

		instance.SetSink(this);

		if (instance.IsUniformDirty)
		{
			if (!UpdateUniformBuffer(instance))
				return null;
			instance.ClearUniformDirty();
		}

		if (mUniformBuffers.TryGetValue(instance, let buffer))
			return buffer;
		return null;
	}

	/// The layout inferred from the material's properties, cached by content so two
	/// materials with the same property shape share one.
	public IBindGroupLayout GetOrCreateLayout(Material material)
	{
		let hash = ComputeLayoutHash(material);
		if (mLayoutCache.TryGetValue(hash, let cached))
			return cached;

		let entries = scope List<BindGroupLayoutEntry>();

		var hasUniforms = false;
		for (let property in material.Properties)
		{
			if (property.IsUniform)
			{
				hasUniforms = true;
				break;
			}
		}
		// The vertex stage too: a surface shader's Vertex() reads its material's properties.
		if (hasUniforms && (material.UniformDataSize > 0))
			entries.Add(BindGroupLayoutEntry.UniformBuffer(0, .Vertex | .Fragment));
		// Each effect group's buffer, right after the material's (the bind group pushes them at
		// the same positions: WebGPU matches entries by position). An effect block binds at b1 of
		// the material's set; the engine declares one effect per flag and its shaders one (Wind),
		// so a second group would take b2, which no shader declares until effects get registers
		// of their own. Vertex: the effects are vertex effects (the sway).
		var effectBinding = cFirstEffectBinding;
		for (let group in material.EffectGroups)
		{
			if (group.UniformSize > 0)
				entries.Add(BindGroupLayoutEntry.UniformBuffer(effectBinding++, .Vertex));
		}

		// Textures and samplers number SEPARATELY: the two occupy different binding spaces
		// on the backends that separate them, and one shared counter would leave holes.
		uint32 textureBinding = 0;
		uint32 samplerBinding = 0;
		for (let property in material.Properties)
		{
			switch (property.Type)
			{
			case .Texture2D:
				entries.Add(BindGroupLayoutEntry.SampledTexture(textureBinding++, .Fragment));
			case .TextureCube:
				entries.Add(BindGroupLayoutEntry.SampledTexture(textureBinding++, .Fragment,
					.TextureCube));
			case .Sampler:
				entries.Add(BindGroupLayoutEntry.Sampler(samplerBinding++, .Fragment));
			default:
				// A scalar lives in the uniform buffer, which already has its entry.
			}
		}

		// A material declaring nothing at all has no layout to make, which is not a
		// failure: it simply binds nothing.
		if (entries.IsEmpty)
			return null;

		var desc = BindGroupLayoutDesc();
		desc.Entries = entries;
		if (!(mDevice.CreateBindGroupLayout(desc) case .Ok(let layout)))
			return null;

		mLayoutCache[hash] = layout;
		return layout;
	}

	/// Rebuilds whatever is dirty and hands back the instance's bind group, ready to bind.
	///
	/// `layout` lets a renderer impose its own; without one the inferred layout is used.
	public IBindGroup PrepareInstance(MaterialInstance instance, IBindGroupLayout layout = null)
	{
		let material = instance.Material;
		if (material == null)
			return null;

		instance.SetSink(this);

		let bindGroupLayout = (layout != null) ? layout : GetOrCreateLayout(material);
		if (bindGroupLayout == null)
			return null;

		if (instance.IsUniformDirty && HasUniformBuffers(material))
		{
			if (!UpdateUniformBuffer(instance))
				return null;
			instance.ClearUniformDirty();
		}

		instance.SetBindGroupLayout(bindGroupLayout);

		if (instance.IsBindGroupDirty)
		{
			if (!UpdateBindGroup(instance, bindGroupLayout))
				return null;
			instance.ClearBindGroupDirty();
		}

		if (mBindGroups.TryGetValue(instance, let group))
			return group;
		return null;
	}

	public IBindGroup GetBindGroup(MaterialInstance instance)
	{
		if (mBindGroups.TryGetValue(instance, let group))
			return group;
		return null;
	}

	/// Re-preps everything dirtied since the last drain, which is proportional to what
	/// changed.
	public void PrepareDirtyInstances()
	{
		for (let instance in mDirty)
		{
			if (instance == null)
				continue;

			instance.SetInDirtyList(false);
			if (instance.IsUniformDirty || instance.IsBindGroupDirty)
				PrepareInstance(instance);
		}
		mDirty.Clear();
	}

	/// Frees retired bind groups once the frame ring has cycled past them. Called once a
	/// frame, alongside whatever else the renderer retires.
	public void TickRetired()
	{
		var write = 0;
		for (int i = 0; i < mRetiredBindGroups.Count; i++)
		{
			var retired = mRetiredBindGroups[i];
			if (retired.FramesLeft <= 1)
			{
				var group = retired.Group;
				mDevice.DestroyBindGroup(ref group);
				continue;
			}
			retired.FramesLeft--;
			mRetiredBindGroups[write++] = retired;
		}
		mRetiredBindGroups.Count = write;
	}

	// ---- IMaterialInstanceSink ----

	public void MarkInstanceDirty(MaterialInstance instance)
	{
		if ((instance == null) || instance.IsInDirtyList)
			return;

		instance.SetInDirtyList(true);
		mDirty.Add(instance);
	}

	/// Frees the instance's GPU resources IMMEDIATELY.
	///
	/// Anything that in flight frames may still be binding must have had both its bind
	/// group and its uniform buffer detached for deferred retirement before it dies.
	/// Destroying only the bind group is not enough: the buffer's memory is still in use,
	/// which a validating backend reports on every material hot reload.
	public void ReleaseInstance(MaterialInstance instance)
	{
		if (instance == null)
			return;

		if (instance.IsInDirtyList)
		{
			RemoveFromDirty(instance);
			instance.SetInDirtyList(false);
		}

		if (mBindGroups.TryGetValue(instance, var group))
		{
			mDevice.DestroyBindGroup(ref group);
			mBindGroups.Remove(instance);
		}
		if (mUniformBuffers.TryGetValue(instance, var buffer))
		{
			mDevice.DestroyBuffer(ref buffer);
			mUniformBuffers.Remove(instance);
		}
		if (mEffectBuffers.GetAndRemove(instance) case .Ok(let pair))
		{
			for (var effectBuffer in pair.value)
			{
				if (effectBuffer != null)
					mDevice.DestroyBuffer(ref effectBuffer);
			}
			delete pair.value;
		}
	}

	/// Hands the instance's effect buffers to the caller (removed from the system) WITHOUT
	/// destroying them, appended to `outBuffers`: DetachUniformBuffer's twin for the effect
	/// groups' buffers, retired the same way.
	public void DetachEffectBuffers(MaterialInstance instance, List<IBuffer> outBuffers)
	{
		if (instance == null)
			return;
		if (mEffectBuffers.GetAndRemove(instance) case .Ok(let pair))
		{
			for (let effectBuffer in pair.value)
			{
				if (effectBuffer != null)
					outBuffers.Add(effectBuffer);
			}
			delete pair.value;
		}
	}

	/// Hands the instance's uniform buffer to the caller WITHOUT destroying it, so the
	/// caller can retire it on its own schedule. The twin of DetachBindGroup, and both are
	/// needed together.
	public IBuffer DetachUniformBuffer(MaterialInstance instance)
	{
		if (instance == null)
			return null;
		if (!mUniformBuffers.TryGetValue(instance, let buffer))
			return null;

		mUniformBuffers.Remove(instance);
		return buffer;
	}

	public IBindGroup DetachBindGroup(MaterialInstance instance)
	{
		if (instance == null)
			return null;
		if (!mBindGroups.TryGetValue(instance, let group))
			return null;

		mBindGroups.Remove(instance);
		return group;
	}

	/// A sampler cache keyed on the combination, so a thousand materials wanting repeat
	/// and linear share one sampler.
	public ISampler GetOrCreateSampler(AddressMode addressU, AddressMode addressV,
		FilterMode minFilter = .Linear, FilterMode magFilter = .Linear,
		MipmapFilterMode mipmapFilter = .Linear)
	{
		let key = (uint64)addressU | ((uint64)addressV << 4) | ((uint64)minFilter << 8)
			| ((uint64)magFilter << 12) | ((uint64)mipmapFilter << 16);

		if (mSamplerCache.TryGetValue(key, let cached))
			return cached;

		var desc = SamplerDesc();
		desc.AddressU = addressU;
		desc.AddressV = addressV;
		desc.AddressW = .Repeat;
		desc.MinFilter = minFilter;
		desc.MagFilter = magFilter;
		desc.MipmapFilter = mipmapFilter;

		// A device that cannot make one is not worth failing a draw over: the default
		// sampler is wrong rather than absent, and absent is a black screen.
		if (!(mDevice.CreateSampler(desc) case .Ok(let sampler)))
			return mDefaultSampler;

		mSamplerCache[key] = sampler;
		return sampler;
	}

	// ---- internals ----

	private Result<void, ErrorCode> CreateDefaultResources()
	{
		// REPEAT, which is the glTF default and what assets actually rely on: a model whose
		// V coordinates run past one has the whole texture smeared into its edge rows under
		// clamp. A material wanting clamp asks for it per sampler.
		var samplerDesc = SamplerDesc();
		samplerDesc.AddressU = .Repeat;
		samplerDesc.AddressV = .Repeat;
		samplerDesc.AddressW = .Repeat;
		if (!(mDevice.CreateSampler(samplerDesc) case .Ok(let sampler)))
			return .Err(.Unknown);
		mDefaultSampler = sampler;

		if (!CreateTexture1x1(.(255, 255, 255, 255), out mWhiteTexture, out mWhiteView))
			return .Err(.Unknown);
		if (!CreateTexture1x1(.(128, 128, 255, 255), out mNormalTexture, out mNormalView))
			return .Err(.Unknown);
		if (!CreateTexture1x1(.(0, 0, 0, 255), out mBlackTexture, out mBlackView))
			return .Err(.Unknown);

		return .Ok;
	}

	private bool CreateTexture1x1(Color32 color, out ITexture outTexture, out ITextureView outView)
	{
		outTexture = null;
		outView = null;

		var desc = TextureDesc();
		desc.Dimension = .Texture2D;
		desc.Format = .RGBA8Unorm;
		desc.Width = 1;
		desc.Height = 1;
		desc.Usage = .Sampled | .CopyDst;
		desc.Label = "1x1";

		if (!(mDevice.CreateTexture(desc) case .Ok(let texture)))
			return false;
		outTexture = texture;

		uint8[4] pixel = .(color.R, color.G, color.B, color.A);
		if (mQueue.CreateTransferBatch() case .Ok(var batch))
		{
			var layout = TextureDataLayout();
			layout.BytesPerRow = 4;
			layout.RowsPerImage = 1;
			batch.WriteTexture(texture, .(&pixel[0], 4), layout, .(1, 1, 1));
			batch.Submit().IgnoreError();
			mQueue.DestroyTransferBatch(ref batch);
		}

		var viewDesc = TextureViewDesc();
		viewDesc.Format = .RGBA8Unorm;
		viewDesc.Dimension = .Texture2D;
		if (!(mDevice.CreateTextureView(texture, viewDesc) case .Ok(let view)))
			return false;

		outView = view;
		return true;
	}

	/// Whether the material has a uniform buffer of any kind: its own or an effect group's.
	private static bool HasUniformBuffers(Material material)
	{
		if (material.UniformDataSize > 0)
			return true;
		for (let group in material.EffectGroups)
		{
			if (group.UniformSize > 0)
				return true;
		}
		return false;
	}

	/// The instance's effect group buffers, created on first use and written from its values.
	private bool UpdateEffectBuffers(MaterialInstance instance)
	{
		let material = instance.Material;
		if (material.EffectGroupCount == 0)
			return true;
		if (!mEffectBuffers.TryGetValue(instance, var buffers))
		{
			buffers = new List<IBuffer>();
			mEffectBuffers[instance] = buffers;
		}
		while (buffers.Count < material.EffectGroupCount)
			buffers.Add(null);
		for (int g < material.EffectGroupCount)
		{
			let group = material.GetEffectGroup(g);
			if (group.UniformSize == 0)
				continue;
			if (buffers[g] == null)
			{
				var desc = BufferDesc();
				desc.Size = group.UniformSize; // a whole row already (Material.SetEffectGroup)
				desc.Usage = .Uniform;
				desc.Memory = .CpuToGpu;
				desc.Label = "material-effect-uniforms";
				if (!(mDevice.CreateBuffer(desc) case .Ok(let created)))
					return false;
				buffers[g] = created;
			}
			let data = instance.EffectData(g);
			if ((data.Length > 0) && (data.Length <= (int)group.UniformSize))
			{
				let mapped = buffers[g].Map();
				if (mapped != null)
				{
					MaterialUniforms.EncodeForGpu(group.Properties, data, (uint8*)mapped);
					buffers[g].Unmap();
				}
			}
		}
		return true;
	}

	private bool UpdateUniformBuffer(MaterialInstance instance)
	{
		let material = instance.Material;
		if (!UpdateEffectBuffers(instance))
			return false;
		if (material.UniformDataSize == 0)
			return true;

		IBuffer buffer;
		if (mUniformBuffers.TryGetValue(instance, let existing))
		{
			buffer = existing;
		}
		else
		{
			var desc = BufferDesc();
			// Rounded to sixteen: a constant buffer is padded to a sixteen byte multiple on
			// every API, and the BOUND RANGE has to cover that even when the declared
			// properties sum to less. A float4 plus two floats is twenty four bytes of data
			// in a thirty two byte buffer.
			desc.Size = (material.UniformDataSize + 15) & ~(uint64)15;
			desc.Usage = .Uniform;
			desc.Memory = .CpuToGpu;
			// LABELLED, because these are handed out by DetachUniformBuffer for a caller to
			// retire later: one that goes astray is an anonymous small allocation in a leak
			// report, with nothing on it to say where it came from.
			desc.Label = "material-uniforms";

			if (!(mDevice.CreateBuffer(desc) case .Ok(let created)))
				return false;

			buffer = created;
			mUniformBuffers[instance] = buffer;
		}

		let data = instance.UniformData;
		if (data.IsEmpty)
			return true;

		let mapped = buffer.Map();
		if (mapped == null)
			return true;

		// The authored colours decoded on the way (sRGB to linear).
		MaterialUniforms.EncodeForGpu(instance.Material, data, (uint8*)mapped);
		buffer.Unmap();
		return true;
	}

	private bool UpdateBindGroup(MaterialInstance instance, IBindGroupLayout layout)
	{
		let material = instance.Material;
		let entries = scope List<BindGroupEntry>();

		if (mUniformBuffers.TryGetValue(instance, let buffer))
			entries.Add(BindGroupEntry.BufferEntry(buffer, 0, material.UniformDataSize));
		// The effect groups' buffers, in the layout's order (GetOrCreateLayout).
		if (material.EffectGroupCount > 0)
		{
			mEffectBuffers.TryGetValue(instance, let buffers);
			for (int g < material.EffectGroupCount)
			{
				let group = material.GetEffectGroup(g);
				if (group.UniformSize == 0)
					continue;
				if ((buffers == null) || (g >= buffers.Count) || (buffers[g] == null))
					return false; // never written: the layout's entry would go unfilled
				entries.Add(BindGroupEntry.BufferEntry(buffers[g], 0, group.UniformSize));
			}
		}

		for (int index = 0; index < material.PropertyCount; index++)
		{
			let property = material.GetProperty(index);

			if (property.IsTexture)
			{
				var view = instance.GetTexture(index);
				if (view == null)
					view = NeutralTextureFor(property.Name);
				if (view != null)
					entries.Add(BindGroupEntry.TextureEntry(view));
			}
			else if (property.IsSampler)
			{
				var sampler = instance.GetSampler(index);
				if (sampler == null)
					sampler = GetOrCreateSampler(material.SamplerU, material.SamplerV);
				if (sampler == null)
					sampler = mDefaultSampler;
				if (sampler != null)
					entries.Add(BindGroupEntry.SamplerEntry(sampler));
			}
		}

		if (entries.IsEmpty)
			return false;

		if (mBindGroups.TryGetValue(instance, let old))
		{
			// DEFERRED, because an in flight frame may still be binding the group being
			// replaced. Destroying it here produces draws against invalid descriptors on
			// every hot reload.
			mRetiredBindGroups.Add(.() { Group = old, FramesLeft = cRetireFrames });
			mBindGroups.Remove(instance);
		}

		var desc = BindGroupDesc();
		desc.Layout = layout;
		desc.Entries = entries;

		if (!(mDevice.CreateBindGroup(desc) case .Ok(let group)))
			return false;

		mBindGroups[instance] = group;
		return true;
	}

	/// What an unbound texture slot binds instead, chosen by INTENT rather than by
	/// convenience: a normal map must decode to the geometric normal, and everything else
	/// multiplies its factor so white is identity. An emissive map too (glTF: emission is
	/// factor times texture, the texture white when absent): a glow authored as a colour
	/// alone shows, and a material that does not glow has a black EmissiveColor.
	///
	/// Matched on a substring that skips the first letter, so "NormalMap" and "normalMap"
	/// both hit without a case fold.
	private ITextureView NeutralTextureFor(StringView name)
	{
		if (name.Contains("ormal"))
			return mNormalView;
		return mWhiteView;
	}

	private static uint64 ComputeLayoutHash(Material material)
	{
		var hash = 17UL;
		// &* and &+, because this folds content and MUST be allowed to wrap.
		hash = (hash &* 31) &+ material.UniformDataSize;
		for (let property in material.Properties)
		{
			hash = (hash &* 31) &+ (uint64)property.Type;
			hash = (hash &* 31) &+ property.Binding;
		}
		// Each effect group adds a binding: a material with one is another layout.
		uint64 effectBindings = 0;
		for (let group in material.EffectGroups)
			effectBindings += (group.UniformSize > 0) ? 1 : 0;
		hash = (hash &* 31) &+ 0x9E37 &+ effectBindings;
		return hash;
	}

	/// Nulled in place rather than removed, so the drain's walk is not disturbed by an
	/// instance dying while it runs.
	private void RemoveFromDirty(MaterialInstance instance)
	{
		for (int i = 0; i < mDirty.Count; i++)
		{
			if (mDirty[i] == instance)
			{
				mDirty[i] = null;
				return;
			}
		}
	}

	private void Shutdown()
	{
		if (mDevice == null)
			return;

		for (let entry in mBindGroups)
		{
			var group = entry.value;
			mDevice.DestroyBindGroup(ref group);
		}
		for (let retired in mRetiredBindGroups)
		{
			var group = retired.Group;
			mDevice.DestroyBindGroup(ref group);
		}
		for (let entry in mUniformBuffers)
		{
			var buffer = entry.value;
			mDevice.DestroyBuffer(ref buffer);
		}
		for (let entry in mEffectBuffers)
		{
			for (var effectBuffer in entry.value)
			{
				if (effectBuffer != null)
					mDevice.DestroyBuffer(ref effectBuffer);
			}
			delete entry.value;
		}
		mEffectBuffers.Clear();
		for (let entry in mLayoutCache)
		{
			var layout = entry.value;
			mDevice.DestroyBindGroupLayout(ref layout);
		}
		for (let entry in mSamplerCache)
		{
			var sampler = entry.value;
			mDevice.DestroySampler(ref sampler);
		}

		mBindGroups.Clear();
		mUniformBuffers.Clear();
		mLayoutCache.Clear();
		mSamplerCache.Clear();
		mRetiredBindGroups.Clear();
		mDirty.Clear();

		// Views before their textures: a view refers to one, and a validating backend
		// objects to outliving it.
		if (mWhiteView != null) mDevice.DestroyTextureView(ref mWhiteView);
		if (mNormalView != null) mDevice.DestroyTextureView(ref mNormalView);
		if (mBlackView != null) mDevice.DestroyTextureView(ref mBlackView);
		if (mWhiteTexture != null) mDevice.DestroyTexture(ref mWhiteTexture);
		if (mNormalTexture != null) mDevice.DestroyTexture(ref mNormalTexture);
		if (mBlackTexture != null) mDevice.DestroyTexture(ref mBlackTexture);
		if (mDefaultSampler != null) mDevice.DestroySampler(ref mDefaultSampler);

		mDevice = null;
	}
}
