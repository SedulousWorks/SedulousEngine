namespace Sedulous.Renderer.Debug;

using System;
using Sedulous.RHI;
using Sedulous.DebugFont;

/// GPU resource backing for DebugDraw: the font atlas, a comparison/regular sampler,
/// a bind group exposing both, and per-frame-in-flight vertex buffers for line and
/// overlay geometry.
///
/// Owned by RenderContext alongside LightBuffer / ShadowSystem / SkinningSystem.
public class DebugDrawSystem : IDisposable
{
	public const int32 MaxFramesInFlight = 2;

	// Upper bounds for per-frame geometry. Increase if you hit these.
	public const uint32 MaxLineVertices = 65536;        // 32 768 line segments
	public const uint32 MaxOverlayVertices = 131072;    // ~21 800 textured quads

	private IDevice mDevice;

	// Font atlas
	private ITexture mFontTexture ~ if (mDevice != null) mDevice.DestroyTexture(ref _);
	private ITextureView mFontTextureView ~ if (mDevice != null) mDevice.DestroyTextureView(ref _);
	private ISampler mFontSampler ~ if (mDevice != null) mDevice.DestroySampler(ref _);

	// Bind group (set 2 — material frequency — holds font texture + sampler)
	private IBindGroupLayout mDebugBindGroupLayout ~ if (mDevice != null) mDevice.DestroyBindGroupLayout(ref _);
	private IBindGroup mDebugBindGroup ~ if (mDevice != null) mDevice.DestroyBindGroup(ref _);

	// Per-frame vertex buffers
	private IBuffer[MaxFramesInFlight] mLineVertexBuffers;
	private IBuffer[MaxFramesInFlight] mOverlayVertexBuffers;

	public ITexture FontTexture => mFontTexture;
	public ITextureView FontTextureView => mFontTextureView;
	public ISampler FontSampler => mFontSampler;
	public IBindGroupLayout DebugBindGroupLayout => mDebugBindGroupLayout;
	public IBindGroup DebugBindGroup => mDebugBindGroup;

	public IBuffer GetLineVertexBuffer(int32 frameIndex) => mLineVertexBuffers[frameIndex % MaxFramesInFlight];
	public IBuffer GetOverlayVertexBuffer(int32 frameIndex) => mOverlayVertexBuffers[frameIndex % MaxFramesInFlight];

	public Result<void> Initialize(IDevice device, IQueue queue)
	{
		mDevice = device;

		// --- Font texture ---
		let fontData = DebugFont.GenerateTextureData();
		defer delete fontData;

		TextureDesc texDesc = .()
		{
			Label = "DebugFont Atlas",
			Width = (uint32)DebugFont.TextureWidth,
			Height = (uint32)DebugFont.TextureHeight,
			Depth = 1,
			Format = .R8Unorm,
			Usage = .Sampled | .CopyDst,
			Dimension = .Texture2D,
			MipLevelCount = 1,
			ArrayLayerCount = 1,
			SampleCount = 1
		};
		if (device.CreateTexture(texDesc) case .Ok(let tex))
			mFontTexture = tex;
		else
			return .Err;

		// Upload the pixel data (synchronous — init only).
		TextureDataLayout uploadLayout = .()
		{
			Offset = 0,
			BytesPerRow = (uint32)DebugFont.TextureWidth,
			RowsPerImage = (uint32)DebugFont.TextureHeight
		};
		Extent3D extent = .()
		{
			Width = (uint32)DebugFont.TextureWidth,
			Height = (uint32)DebugFont.TextureHeight,
			Depth = 1
		};
		TransferHelper.WriteTextureSync(queue, device, mFontTexture,
			Span<uint8>(fontData.Ptr, fontData.Count),
			uploadLayout, extent);

		TextureViewDesc viewDesc = .()
		{
			Label = "DebugFont View",
			Format = .R8Unorm,
			Dimension = .Texture2D
		};
		if (device.CreateTextureView(mFontTexture, viewDesc) case .Ok(let view))
			mFontTextureView = view;
		else
			return .Err;

		// Nearest sampler for crisp pixel font.
		SamplerDesc samplerDesc = .()
		{
			Label = "DebugFont Sampler",
			MinFilter = .Nearest,
			MagFilter = .Nearest,
			MipmapFilter = .Nearest,
			AddressU = .ClampToEdge,
			AddressV = .ClampToEdge,
			AddressW = .ClampToEdge
		};
		if (device.CreateSampler(samplerDesc) case .Ok(let sampler))
			mFontSampler = sampler;
		else
			return .Err;

		// Bind group layout: t0 font, s0 sampler (at Material slot — set 2).
		BindGroupLayoutEntry[2] entries = .(
			.SampledTexture(0, .Fragment, .Texture2D),
			.Sampler(0, .Fragment)
		);
		BindGroupLayoutDesc layoutDesc = .()
		{
			Label = "DebugFont BindGroup Layout",
			Entries = entries
		};
		if (device.CreateBindGroupLayout(layoutDesc) case .Ok(let layout))
			mDebugBindGroupLayout = layout;
		else
			return .Err;

		BindGroupEntry[2] bgEntries = .(
			BindGroupEntry.Texture(mFontTextureView),
			BindGroupEntry.Sampler(mFontSampler)
		);
		BindGroupDesc bgDesc = .()
		{
			Label = "DebugFont BindGroup",
			Layout = mDebugBindGroupLayout,
			Entries = bgEntries
		};
		if (device.CreateBindGroup(bgDesc) case .Ok(let bg))
			mDebugBindGroup = bg;
		else
			return .Err;

		// Per-frame vertex buffers.
		for (int i = 0; i < MaxFramesInFlight; i++)
		{
			BufferDesc lineDesc = .()
			{
				Label = "DebugLine Vertices",
				Size = (uint64)(MaxLineVertices * DebugVertex.SizeInBytes),
				Usage = .Vertex,
				Memory = .CpuToGpu
			};
			if (device.CreateBuffer(lineDesc) case .Ok(let lineBuf))
				mLineVertexBuffers[i] = lineBuf;
			else
				return .Err;

			BufferDesc overlayDesc = .()
			{
				Label = "DebugOverlay Vertices",
				Size = (uint64)(MaxOverlayVertices * DebugTextVertex.SizeInBytes),
				Usage = .Vertex,
				Memory = .CpuToGpu
			};
			if (device.CreateBuffer(overlayDesc) case .Ok(let overlayBuf))
				mOverlayVertexBuffers[i] = overlayBuf;
			else
				return .Err;
		}

		return .Ok;
	}

	public void Dispose()
	{
		if (mDevice == null) return;
		for (int i = 0; i < MaxFramesInFlight; i++)
		{
			if (mLineVertexBuffers[i] != null)
				mDevice.DestroyBuffer(ref mLineVertexBuffers[i]);
			if (mOverlayVertexBuffers[i] != null)
				mDevice.DestroyBuffer(ref mOverlayVertexBuffers[i]);
		}
	}
}
