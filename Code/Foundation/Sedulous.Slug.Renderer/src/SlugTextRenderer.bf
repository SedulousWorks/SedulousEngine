using System;
using System.Collections;
using Sedulous.Slug;
using Sedulous.RHI;
using Sedulous.Shaders;

namespace Sedulous.Slug.Renderer;

/// High-level GPU text renderer using the Slug algorithm.
/// Multi-buffered for proper frame pacing — no sync stalls.
///
/// Usage pattern:
///   1. Initialize() once with font + texture data
///   2. Each frame: Prepare(frameIndex) -> OnRender(renderPass, frameIndex)
public class SlugTextRenderer : IDisposable
{
	private IDevice mDevice;
	private int32 mFrameCount;
	private SlugFont mFont;
	private bool mInitialized;

	// Static resources (shared across all frames)
	private ITexture mCurveTexture;
	private ITexture mBandTexture;
	private ITextureView mCurveTextureView;
	private ITextureView mBandTextureView;
	private IShaderModule mVertShader;
	private IShaderModule mFragShader;
	private bool mOwnsShaders = true;
	private IRenderPipeline mPipeline;
	private IPipelineLayout mPipelineLayout;
	private IBindGroupLayout mBindGroupLayout;
	private IBindGroup mTextureBindGroup;

	// Per-frame resources (double/triple buffered)
	private IBuffer[] mVertexBuffers;
	private IBuffer[] mIndexBuffers;
	private IBuffer[] mUniformBuffers;
	private IBindGroup[] mBindGroups; // per-frame: uniform buffer + shared textures

	// CPU-side geometry staging
	private List<Vertex4U> mVertices = new .() ~ delete _;
	private List<Triangle16> mTriangles = new .() ~ delete _;

	// Buffer capacities
	private const int32 MAX_VERTICES = 8192;
	private const int32 MAX_TRIANGLES = 4096;

	public bool IsInitialized => mInitialized;
	public SlugFont Font => mFont;

	public this(IDevice device)
	{
		mDevice = device;
	}

	/// Initialize the renderer.
	/// frameCount should match the swapchain image count (typically 2 or 3).
	/// shaderSystem must be initialized with the path to shaders.
	public Result<void> Initialize(
		SlugFont font,
		SlugTextureBuilder.BuildResult textureData,
		int32 frameCount,
		TextureFormat renderTargetFormat,
		ShaderSystem shaderSystem)
	{
		mFont = font;
		mFrameCount = frameCount;

		if (CreateStaticTextures(textureData) case .Err) return .Err;
		if (UploadTextures(textureData) case .Err) return .Err;
		if (LoadShaders(shaderSystem) case .Err) return .Err;
		if (CreateLayouts() case .Err) return .Err;
		if (CreatePipeline(renderTargetFormat) case .Err) return .Err;
		if (CreatePerFrameResources() case .Err) return .Err;
		if (CreateBindGroups() case .Err) return .Err;

		mInitialized = true;
		return .Ok;
	}

	/// Prepare text geometry for the given frame. Call before the render pass.
	/// Builds vertex/index data on CPU and uploads to the frame's GPU buffers.
	public void Prepare(int32 frameIndex, uint32 viewportWidth, uint32 viewportHeight)
	{
		if (!mInitialized)
			return;

		// Update uniforms for this frame
		var uniforms = SlugUniforms.Ortho2D((float)viewportWidth, (float)viewportHeight);

		let uniformData = Span<uint8>((uint8*)&uniforms, sizeof(SlugUniforms));
		TransferHelper.WriteMappedBuffer(mUniformBuffers[frameIndex], 0, uniformData);

		// Upload staged geometry
		if (mVertices.Count > 0)
		{
			let vertexData = Span<uint8>((uint8*)mVertices.Ptr, mVertices.Count * sizeof(Vertex4U));
			TransferHelper.WriteMappedBuffer(mVertexBuffers[frameIndex], 0, vertexData);

			let indexData = Span<uint8>((uint8*)mTriangles.Ptr, mTriangles.Count * sizeof(Triangle16));
			TransferHelper.WriteMappedBuffer(mIndexBuffers[frameIndex], 0, indexData);
		}
	}

	/// Render the prepared text. Call inside a render pass.
	public void Render(IRenderPassEncoder renderPass, int32 frameIndex)
	{
		if (!mInitialized || mTriangles.Count == 0)
			return;

		renderPass.SetPipeline(mPipeline);
		renderPass.SetBindGroup(0, mBindGroups[frameIndex]);
		renderPass.SetVertexBuffer(0, mVertexBuffers[frameIndex]);
		renderPass.SetIndexBuffer(mIndexBuffers[frameIndex], .UInt16);
		renderPass.DrawIndexed((uint32)(mTriangles.Count * 3));
	}

	/// Clear the geometry staging buffer. Call at the start of each frame before adding text.
	public void Begin()
	{
		mVertices.Clear();
		mTriangles.Clear();
	}

	/// Add text to the staging buffer. Call between Begin() and Prepare().
	public void DrawText(StringView text, float x, float y, float fontSize, Color4U color = .White)
	{
		var x;
		if (mFont == null)
			return;

		for (let c in text.DecodedChars)
		{
			let glyph = mFont.GetGlyph((uint32)c);
			if (glyph == null)
				continue;

			if (glyph.HasCurves)
				AddGlyphQuad(glyph, x, y, fontSize, color);

			x += glyph.AdvanceWidth * fontSize;
		}
	}

	/// Measure text width without rendering.
	public float MeasureText(StringView text, float fontSize)
	{
		if (mFont == null) return 0;
		return SlugGeometryBuilder.MeasureString(mFont, text, fontSize);
	}

	// ==================== Geometry Building ====================

	private void AddGlyphQuad(SlugGlyphData glyph, float posX, float posY, float emScale, Color4U color)
	{
		if (mVertices.Count + 4 > MAX_VERTICES)
			return; // Buffer full

		let bb = ref glyph.BoundingBox;
		let x0 = posX + bb.min.x * emScale;
		let y0 = posY + bb.min.y * emScale;
		let x1 = posX + bb.max.x * emScale;
		let y1 = posY + bb.max.y * emScale;

		// Outward-pointing normals for dynamic dilation (shader normalizes these).
		// Each corner points diagonally outward from the quad center.
		let nx = 1.0f;
		let ny = 1.0f;

		let glyphLocPacked = SlugGeometryBuilder.PackUint16Pair(glyph.BandLocation[0], glyph.BandLocation[1]);
		// bandMax.x = max vertical band index, bandMax.y = max horizontal band index
		let bandMaxX = (uint16)(uint32)Math.Max(0, (int32)glyph.BandCount[0] - 1); // vBands - 1
		let bandMaxY = (uint16)(uint32)Math.Max(0, (int32)glyph.BandCount[1] - 1); // hBands - 1
		let bandMaxPacked = SlugGeometryBuilder.PackUint16Pair(bandMaxX, bandMaxY);

		// Inverse Jacobian: relates em-space to object-space.
		// For uniform scaling: jac = 1/emScale on diagonal.
		let invScale = 1.0f / emScale;
		let bandScaleX = glyph.BandScale.x;
		let bandScaleY = glyph.BandScale.y;
		let bandOffsetX = -bb.min.x * bandScaleX;
		let bandOffsetY = -bb.min.y * bandScaleY;

		let baseIndex = (uint16)mVertices.Count;

		// Bottom-left, bottom-right, top-right, top-left
		mVertices.Add(.() { position = .(x0, y0, -nx, -ny), texcoord = .(bb.min.x, bb.min.y, glyphLocPacked, bandMaxPacked),
			jacobian = .(invScale, 0, 0, invScale), banding = .(bandScaleX, bandScaleY, bandOffsetX, bandOffsetY), color = color });
		mVertices.Add(.() { position = .(x1, y0, nx, -ny), texcoord = .(bb.max.x, bb.min.y, glyphLocPacked, bandMaxPacked),
			jacobian = .(invScale, 0, 0, invScale), banding = .(bandScaleX, bandScaleY, bandOffsetX, bandOffsetY), color = color });
		mVertices.Add(.() { position = .(x1, y1, nx, ny), texcoord = .(bb.max.x, bb.max.y, glyphLocPacked, bandMaxPacked),
			jacobian = .(invScale, 0, 0, invScale), banding = .(bandScaleX, bandScaleY, bandOffsetX, bandOffsetY), color = color });
		mVertices.Add(.() { position = .(x0, y1, -nx, ny), texcoord = .(bb.min.x, bb.max.y, glyphLocPacked, bandMaxPacked),
			jacobian = .(invScale, 0, 0, invScale), banding = .(bandScaleX, bandScaleY, bandOffsetX, bandOffsetY), color = color });

		mTriangles.Add(.((uint16)(baseIndex + 0), (uint16)(baseIndex + 1), (uint16)(baseIndex + 2)));
		mTriangles.Add(.((uint16)(baseIndex + 0), (uint16)(baseIndex + 2), (uint16)(baseIndex + 3)));
	}

	// ==================== Resource Creation ====================

	private Result<void> CreateStaticTextures(SlugTextureBuilder.BuildResult textureData)
	{
		let cs = textureData.CurveTextureSize;
		let bs = textureData.BandTextureSize;

		switch (mDevice.CreateTexture(TextureDesc.Texture2D((.)cs.x, (.)cs.y, .RGBA16Float, .CopyDst | .Sampled)))
		{
		case .Ok(let val): mCurveTexture = val;
		case .Err: return .Err;
		}

		switch (mDevice.CreateTextureView(mCurveTexture, .() { Format = .RGBA16Float }))
		{
		case .Ok(let val): mCurveTextureView = val;
		case .Err: return .Err;
		}

		switch (mDevice.CreateTexture(TextureDesc.Texture2D((.)bs.x, (.)bs.y, .RGBA16Uint, .CopyDst | .Sampled)))
		{
		case .Ok(let val): mBandTexture = val;
		case .Err: return .Err;
		}

		switch (mDevice.CreateTextureView(mBandTexture, .() { Format = .RGBA16Uint }))
		{
		case .Ok(let val): mBandTextureView = val;
		case .Err: return .Err;
		}

		return .Ok;
	}

	private Result<void> UploadTextures(SlugTextureBuilder.BuildResult textureData)
	{
		let cs = textureData.CurveTextureSize;
		let bs = textureData.BandTextureSize;

		var curveLayout = TextureDataLayout() { BytesPerRow = (uint32)(cs.x * 8) };
		curveLayout.BytesPerRow = ((curveLayout.BytesPerRow + 255) / 256) * 256;
		var curveExtent = Extent3D((.)cs.x, (.)cs.y);
		TransferHelper.WriteTextureSync(mDevice.GetQueue(.Graphics), mDevice, mCurveTexture, Span<uint8>(textureData.CurveTextureData), curveLayout, curveExtent);

		var bandLayout = TextureDataLayout() { BytesPerRow = (uint32)(bs.x * 8) };
		bandLayout.BytesPerRow = ((bandLayout.BytesPerRow + 255) / 256) * 256;
		var bandExtent = Extent3D((.)bs.x, (.)bs.y);
		TransferHelper.WriteTextureSync(mDevice.GetQueue(.Graphics), mDevice, mBandTexture, Span<uint8>(textureData.BandTextureData), bandLayout, bandExtent);

		return .Ok;
	}

	private Result<void> LoadShaders(ShaderSystem shaderSystem)
	{
		// Loads slug.vert.hlsl and slug.frag.hlsl from the shader source path
		let pairResult = shaderSystem.GetShaderPair("slug");
		if (pairResult case .Err)
			return .Err;

		let pair = pairResult.Value;
		mVertShader = pair.vert.Module;
		mFragShader = pair.frag.Module;
		mOwnsShaders = false; // ShaderSystem cache owns the modules

		return .Ok;
	}

	private Result<void> CreateLayouts()
	{
		// Single bind group (set 0): uniform buffer (b0) + curve texture (t0) + band texture (t1)
		// All in space0 to match HLSL register declarations.
		// Vulkan backend auto-applies binding shifts (b0->0, t0->1000, t1->1001).
		BindGroupLayoutEntry[3] entries = .(
			.UniformBuffer(0, .Vertex),
			.SampledTexture(0, .Fragment),
			.SampledTexture(1, .Fragment)
		);
		switch (mDevice.CreateBindGroupLayout(.(entries)))
		{
		case .Ok(let val): mBindGroupLayout = val;
		case .Err: return .Err;
		}

		IBindGroupLayout[1] bgLayouts = .(mBindGroupLayout);
		switch (mDevice.CreatePipelineLayout(.(bgLayouts)))
		{
		case .Ok(let val): mPipelineLayout = val;
		case .Err: return .Err;
		}

		return .Ok;
	}

	private Result<void> CreatePipeline(TextureFormat renderTargetFormat)
	{
		VertexAttribute[5] attrs = .(
			.(.Float4, 0, 0),
			.(.Float4, 16, 1),
			.(.Float4, 32, 2),
			.(.Float4, 48, 3),
			.(.UByte4Normalized, 64, 4)
		);
		VertexBufferLayout[1] vtxBufs = .(.((.)sizeof(Vertex4U), attrs));
		ColorTargetState[1] targets = .(.(renderTargetFormat, .AlphaBlend));

		RenderPipelineDesc pipelineDesc = .()
		{
			Layout = mPipelineLayout,
			Vertex = .() { Shader = .(mVertShader, "main"), Buffers = vtxBufs },
			Fragment = .() { Shader = .(mFragShader, "main"), Targets = targets },
			Primitive = .() { Topology = .TriangleList, CullMode = .None },
			DepthStencil = null
		};

		switch (mDevice.CreateRenderPipeline(pipelineDesc))
		{
		case .Ok(let val): mPipeline = val;
		case .Err: return .Err;
		}

		return .Ok;
	}

	private Result<void> CreatePerFrameResources()
	{
		mVertexBuffers = new IBuffer[mFrameCount];
		mIndexBuffers = new IBuffer[mFrameCount];
		mUniformBuffers = new IBuffer[mFrameCount];
		mBindGroups = new IBindGroup[mFrameCount];

		for (int32 i = 0; i < mFrameCount; i++)
		{
			// Vertex buffer: host-visible for direct CPU writes (no staging needed)
			switch (mDevice.CreateBuffer(.((uint64)(MAX_VERTICES * sizeof(Vertex4U)), .Vertex, .CpuToGpu)))
			{
			case .Ok(let val): mVertexBuffers[i] = val;
			case .Err: return .Err;
			}

			// Index buffer: host-visible
			switch (mDevice.CreateBuffer(.((uint64)(MAX_TRIANGLES * sizeof(Triangle16)), .Index, .CpuToGpu)))
			{
			case .Ok(let val): mIndexBuffers[i] = val;
			case .Err: return .Err;
			}

			// Uniform buffer: host-visible
			switch (mDevice.CreateBuffer(.((uint64)sizeof(SlugUniforms), .Uniform, .CpuToGpu)))
			{
			case .Ok(let val): mUniformBuffers[i] = val;
			case .Err: return .Err;
			}
		}

		return .Ok;
	}

	private Result<void> CreateBindGroups()
	{
		// Per-frame bind groups: each has its own uniform buffer + shared textures
		for (int32 i = 0; i < mFrameCount; i++)
		{
			BindGroupEntry[3] entries = .(
				.Buffer(mUniformBuffers[i], 0, 0),
				.Texture(mCurveTextureView),
				.Texture(mBandTextureView)
			);
			switch (mDevice.CreateBindGroup(.(mBindGroupLayout, entries)))
			{
			case .Ok(let val): mBindGroups[i] = val;
			case .Err: return .Err;
			}
		}

		return .Ok;
	}

	// ==================== Cleanup ====================

	public void Dispose()
	{
		mInitialized = false;

		// Per-frame bind groups
		if (mBindGroups != null)
		{
			for (var bg in ref mBindGroups)
				if (bg != null) mDevice.DestroyBindGroup(ref bg);
			delete mBindGroups;
			mBindGroups = null;
		}

		// Per-frame buffers
		if (mVertexBuffers != null)
		{
			for (var buf in ref mVertexBuffers)
				if (buf != null) mDevice.DestroyBuffer(ref buf);
			delete mVertexBuffers;
			mVertexBuffers = null;
		}
		if (mIndexBuffers != null)
		{
			for (var buf in ref mIndexBuffers)
				if (buf != null) mDevice.DestroyBuffer(ref buf);
			delete mIndexBuffers;
			mIndexBuffers = null;
		}
		if (mUniformBuffers != null)
		{
			for (var buf in ref mUniformBuffers)
				if (buf != null) mDevice.DestroyBuffer(ref buf);
			delete mUniformBuffers;
			mUniformBuffers = null;
		}

		// Pipeline
		if (mPipeline != null) mDevice.DestroyRenderPipeline(ref mPipeline);
		if (mPipelineLayout != null) mDevice.DestroyPipelineLayout(ref mPipelineLayout);
		if (mBindGroupLayout != null) mDevice.DestroyBindGroupLayout(ref mBindGroupLayout);

		// Shaders (only destroy if we own them)
		if (mOwnsShaders)
		{
			if (mVertShader != null) mDevice.DestroyShaderModule(ref mVertShader);
			if (mFragShader != null) mDevice.DestroyShaderModule(ref mFragShader);
		}
		mVertShader = null;
		mFragShader = null;

		// Texture views then textures
		if (mCurveTextureView != null) mDevice.DestroyTextureView(ref mCurveTextureView);
		if (mBandTextureView != null) mDevice.DestroyTextureView(ref mBandTextureView);
		if (mCurveTexture != null) mDevice.DestroyTexture(ref mCurveTexture);
		if (mBandTexture != null) mDevice.DestroyTexture(ref mBandTexture);
	}
}
