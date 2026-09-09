using System;
using Sedulous.RHI;
using Sedulous.RenderGraph;
using Sedulous.Core;

namespace Sedulous.Render;

/// The shadow maps: the directional cascades, and the atlas the local lights share.
///
/// The textures are created LAZILY, on the first shadowed frame, so a scene with no shadow
/// casters pays nothing for them.
class ShadowSystem
{
	private const TextureFormat cShadowFormat = .Depth32Float;
	/// Per cascade.
	private const uint32 cShadowResolution = 1024;
	private const uint32 cCascadeCount = ShadowCascades.Count;
	private const int cMaxFramesInFlight = 8;

	/// The local light atlas: spot and point shadows pack into TWO LAYERS, while the cascades
	/// keep an array of their own. The first layer is redrawn every frame; the second holds
	/// the static casters, rendered only when that set changes and then cached.
	public const uint32 AtlasResolutionValue = 2048;
	public const uint32 AtlasTileValue = 512;
	public const uint32 AtlasLayers = 2;
	public const uint32 AtlasLayerRealtime = 0;
	public const uint32 AtlasLayerStatic = 1;

	/// Cascades for this many views fit in the array before it has to grow.
	public const uint32 MaxShadowViews = 4;

	private IDevice mDevice;
	private uint32 mFramesInFlight = 2;
	/// BORROWED. Null means growing drains the device instead.
	private GpuRetireQueue mRetire = null;

	/// Bumped on every texture recreation, which is what a bind group cache over the sample
	/// view keys on: a reused address would otherwise alias a destroyed texture.
	private uint64 mGeneration = 0;

	private ITexture[cMaxFramesInFlight] mTextures = .();
	private ITextureView[cMaxFramesInFlight] mAttachViews = .();
	private ITextureView[cMaxFramesInFlight] mSampleViews = .();
	private ResourceState[cMaxFramesInFlight] mStates = .();
	private uint32[cMaxFramesInFlight] mLayerCounts = .();

	private ITexture[cMaxFramesInFlight] mAtlasTextures = .();
	private ITextureView[cMaxFramesInFlight] mAtlasAttachViews = .();
	private ITextureView[cMaxFramesInFlight] mAtlasSampleViews = .();
	private ResourceState[cMaxFramesInFlight] mAtlasStates = .();

	public this(IDevice device, uint32 framesInFlight)
	{
		mDevice = device;
		mFramesInFlight = Max(framesInFlight, (uint32)1);
	}

	public ~this()
	{
		Shutdown();
	}

	/// Wires the retire queue, which makes an atlas growth web safe. Null drains instead.
	public void SetRetireQueue(GpuRetireQueue retire) => mRetire = retire;

	/// Nothing to do up front: the textures appear on first use, and the comparison sampler
	/// that reads them belongs to whoever owns the set they are bound in.
	public Result<void> Initialize() => .Ok;

	public TextureFormat Format => cShadowFormat;
	public uint32 Resolution => cShadowResolution;
	public uint32 FramesInFlight => mFramesInFlight;
	public uint32 CascadeCount => cCascadeCount;
	public uint64 Generation => mGeneration;

	public uint32 AtlasResolution => AtlasResolutionValue;
	public uint32 AtlasTileResolution => AtlasTileValue;

	/// Tiles per LAYER.
	public uint32 AtlasTileCapacity
	{
		get
		{
			let perRow = AtlasResolutionValue / AtlasTileValue;
			return perRow * perRow;
		}
	}

	/// Makes sure this frame's cascade array has layers for every view, and answers the view
	/// the forward pass samples. Null when it could not be made.
	public ITextureView PrepareFrame(uint32 frameIndex, uint32 viewCount)
	{
		let slot = (int)(frameIndex % mFramesInFlight);
		let layers = Max(viewCount, (uint32)1) * cCascadeCount;

		if (!EnsureTexture(slot, layers))
			return null;

		return mSampleViews[slot];
	}

	public ITextureView SampleView(uint32 frameIndex) => mSampleViews[(int)(frameIndex % mFramesInFlight)];

	/// Imports this frame's cascade array into the graph: the depth pass writes it, and it
	/// then barriers to a readable state for the forward sample.
	public RGHandle ImportTarget(RenderGraph graph, uint32 frameIndex)
	{
		let slot = (int)(frameIndex % mFramesInFlight);
		if (mTextures[slot] == null)
			return .Invalid;

		let handle = graph.ImportTarget("shadow.cascades", mTextures[slot], mAttachViews[slot],
			ResourceState.DepthStencilRead, mStates[slot]);
		mStates[slot] = .DepthStencilRead;
		return handle;
	}

	/// Makes sure this frame's local atlas exists. Fixed size, so it is built once per slot.
	public ITextureView PrepareAtlas(uint32 frameIndex)
	{
		let slot = (int)(frameIndex % mFramesInFlight);
		if (!EnsureAtlas(slot))
			return null;

		return mAtlasSampleViews[slot];
	}

	public RGHandle ImportAtlas(RenderGraph graph, uint32 frameIndex)
	{
		let slot = (int)(frameIndex % mFramesInFlight);
		if (mAtlasTextures[slot] == null)
			return .Invalid;

		let handle = graph.ImportTarget("shadow.atlas", mAtlasTextures[slot],
			mAtlasAttachViews[slot], ResourceState.DepthStencilRead, mAtlasStates[slot]);
		mAtlasStates[slot] = .DepthStencilRead;
		return handle;
	}

	/// The cascade array for one frame slot, one layer per view cascade.
	///
	/// Recreated when the layer count GROWS, which is a frame rendering more views than the
	/// last one did. The per layer attachment views are derived by the graph at pass time.
	private bool EnsureTexture(int slot, uint32 layerCount)
	{
		if ((mTextures[slot] != null) && (mLayerCounts[slot] >= layerCount))
			return true;

		RetireTexture(ref mTextures[slot], ref mAttachViews[slot], ref mSampleViews[slot]);

		var desc = TextureDesc();
		desc.Dimension = .Texture2D;
		desc.Format = cShadowFormat;
		desc.Width = cShadowResolution;
		desc.Height = cShadowResolution;
		desc.Depth = 1;
		desc.ArrayLayerCount = layerCount;
		desc.Usage = .DepthStencil | .Sampled;
		desc.Label = "shadow.cascades";

		if (!(mDevice.CreateTexture(desc) case .Ok(let texture)))
			return false;

		var attachDesc = TextureViewDesc();
		attachDesc.Dimension = .Texture2DArray;
		attachDesc.Format = cShadowFormat;
		attachDesc.ArrayLayerCount = layerCount;
		attachDesc.Label = "shadow.cascades.attach";

		var sampleDesc = attachDesc;
		sampleDesc.Aspect = .DepthOnly;
		sampleDesc.Label = "shadow.cascades.sample";

		if (!(mDevice.CreateTextureView(texture, attachDesc) case .Ok(let attachView)))
		{
			var doomed = texture;
			mDevice.DestroyTexture(ref doomed);
			return false;
		}

		if (!(mDevice.CreateTextureView(texture, sampleDesc) case .Ok(let sampleView)))
		{
			var doomedView = attachView;
			var doomed = texture;
			mDevice.DestroyTextureView(ref doomedView);
			mDevice.DestroyTexture(ref doomed);
			return false;
		}

		mTextures[slot] = texture;
		mAttachViews[slot] = attachView;
		mSampleViews[slot] = sampleView;
		mLayerCounts[slot] = layerCount;
		mStates[slot] = .Undefined;
		mGeneration++;
		return true;
	}

	private bool EnsureAtlas(int slot)
	{
		if (mAtlasTextures[slot] != null)
			return true;

		var desc = TextureDesc();
		desc.Dimension = .Texture2D;
		desc.Format = cShadowFormat;
		desc.Width = AtlasResolutionValue;
		desc.Height = AtlasResolutionValue;
		desc.Depth = 1;
		desc.ArrayLayerCount = AtlasLayers;
		desc.Usage = .DepthStencil | .Sampled;
		desc.Label = "shadow.atlas";

		if (!(mDevice.CreateTexture(desc) case .Ok(let texture)))
			return false;

		var attachDesc = TextureViewDesc();
		attachDesc.Dimension = .Texture2DArray;
		attachDesc.Format = cShadowFormat;
		attachDesc.ArrayLayerCount = AtlasLayers;
		attachDesc.Label = "shadow.atlas.attach";

		var sampleDesc = attachDesc;
		sampleDesc.Aspect = .DepthOnly;
		sampleDesc.Label = "shadow.atlas.sample";

		if (!(mDevice.CreateTextureView(texture, attachDesc) case .Ok(let attachView)))
		{
			var doomed = texture;
			mDevice.DestroyTexture(ref doomed);
			return false;
		}

		if (!(mDevice.CreateTextureView(texture, sampleDesc) case .Ok(let sampleView)))
		{
			var doomedView = attachView;
			var doomed = texture;
			mDevice.DestroyTextureView(ref doomedView);
			mDevice.DestroyTexture(ref doomed);
			return false;
		}

		mAtlasTextures[slot] = texture;
		mAtlasAttachViews[slot] = attachView;
		mAtlasSampleViews[slot] = sampleView;
		mAtlasStates[slot] = .Undefined;
		mGeneration++;
		return true;
	}

	/// A frame in flight may still be sampling what is being replaced, so it is retired where
	/// a queue is wired and the device drained where one is not.
	private void RetireTexture(ref ITexture texture, ref ITextureView attachView,
		ref ITextureView sampleView)
	{
		if (texture == null)
			return;

		if (mRetire != null)
		{
			mRetire.Retire(sampleView);
			mRetire.Retire(attachView);
			mRetire.Retire(texture);
		}
		else
		{
			mDevice.WaitIdle();
			mDevice.DestroyTextureView(ref sampleView);
			mDevice.DestroyTextureView(ref attachView);
			mDevice.DestroyTexture(ref texture);
		}

		texture = null;
		attachView = null;
		sampleView = null;
	}

	private void Shutdown()
	{
		if (mDevice == null)
			return;

		for (int slot < cMaxFramesInFlight)
		{
			if (mSampleViews[slot] != null)
				mDevice.DestroyTextureView(ref mSampleViews[slot]);
			if (mAttachViews[slot] != null)
				mDevice.DestroyTextureView(ref mAttachViews[slot]);
			if (mTextures[slot] != null)
				mDevice.DestroyTexture(ref mTextures[slot]);

			if (mAtlasSampleViews[slot] != null)
				mDevice.DestroyTextureView(ref mAtlasSampleViews[slot]);
			if (mAtlasAttachViews[slot] != null)
				mDevice.DestroyTextureView(ref mAtlasAttachViews[slot]);
			if (mAtlasTextures[slot] != null)
				mDevice.DestroyTexture(ref mAtlasTextures[slot]);
		}
	}
}
