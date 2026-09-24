using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.RenderGraph;
using Sedulous.Shaders;

namespace Sedulous.Render;

/// The GPU side of the debug drawing.
///
/// It owns the font atlas, the per view and frame vertex buffers, and the pipelines, and
/// declares two passes PER VIEW: the world space geometry, and the screen space text and
/// rectangles. Each merges a GLOBAL accumulator, the SCENE's own, and the VIEW's private one,
/// and projects through that view's matrix into its own sub rectangle of the target, which is
/// what keeps two scenes side by side from bleeding into each other.
///
/// The geometry has a depth tested bucket and an overlay one; the screen work is always drawn
/// on top.
class DebugDrawPass
{
	private const int cMaxViews = 8;
	private const int cMaxSlots = cMaxViews * 8;
	private const int cMaxGeomFormats = 4;

	private IDevice mDevice;
	private ShaderSystem mShaders;
	private uint32 mFramesInFlight;

	private IPipelineLayout mGeomLayout = null;
	private IPipelineLayout mScreenLayout = null;
	private IBindGroupLayout mScreenBindGroupLayout = null;
	private ISampler mSampler = null;

	private ITexture mFontTexture = null;
	private ITextureView mFontView = null;
	private IBindGroup mFontBindGroup = null;

	private DebugGeomPipelines[cMaxGeomFormats] mGeomPipelines = .();
	private IRenderPipeline mScreenPipeline = null;
	private TextureFormat mScreenFormat = .Undefined;
	private uint64 mScreenShaderVersion = 0;

	private IBuffer[cMaxSlots] mGeomBuffers;
	private uint64[cMaxSlots] mGeomCapacities;
	private IBuffer[cMaxSlots] mScreenBuffers;
	private uint64[cMaxSlots] mScreenCapacities;

	/// The staging the declares build into, reused rather than allocated per view.
	private List<DebugVertex> mGeomScratch = new .() ~ delete _;
	private List<DebugTextVertex> mScreenScratch = new .() ~ delete _;

	public this(IDevice device, ShaderSystem shaders, uint32 framesInFlight)
	{
		mDevice = device;
		mShaders = shaders;
		mFramesInFlight = (framesInFlight < 1) ? 1 : framesInFlight;
	}

	public ~this()
	{
		Shutdown();
	}

	public Result<void> Initialize()
	{
		// The geometry takes only the view matrix as a push, and no groups at all.
		var geomPush = PushConstantRange();
		geomPush.Stages = .Vertex;
		geomPush.Offset = 0;
		geomPush.Size = sizeof(Float4x4);
		// With no groups the push block sits at the FIRST space, not the second every other
		// shader uses, so a backend that emulates pushes with a uniform must put it there too.
		geomPush.BindGroupIndex = 0;

		var geomLayoutDesc = PipelineLayoutDesc();
		geomLayoutDesc.PushConstantRanges = .(&geomPush, 1);
		if (!(mDevice.CreatePipelineLayout(geomLayoutDesc) case .Ok(let geomLayout)))
			return .Err;
		mGeomLayout = geomLayout;

		// The screen work takes the font atlas and its sampler, and the inverse of the
		// viewport's size as a push.
		var screenEntries = BindGroupLayoutEntry[2](
			BindGroupLayoutEntry.SampledTexture(0, .Fragment),
			BindGroupLayoutEntry.Sampler(0, .Fragment));

		var screenBindGroupDesc = BindGroupLayoutDesc();
		screenBindGroupDesc.Entries = .(&screenEntries[0], 2);
		if (!(mDevice.CreateBindGroupLayout(screenBindGroupDesc) case .Ok(let screenBgLayout)))
			return .Err;
		mScreenBindGroupLayout = screenBgLayout;

		var screenLayouts = IBindGroupLayout[1](mScreenBindGroupLayout);
		var screenPush = PushConstantRange();
		screenPush.Stages = .Vertex;
		screenPush.Offset = 0;
		screenPush.Size = sizeof(float) * 4;

		var screenLayoutDesc = PipelineLayoutDesc();
		screenLayoutDesc.BindGroupLayouts = .(&screenLayouts[0], 1);
		screenLayoutDesc.PushConstantRanges = .(&screenPush, 1);
		if (!(mDevice.CreatePipelineLayout(screenLayoutDesc) case .Ok(let screenLayout)))
			return .Err;
		mScreenLayout = screenLayout;

		var samplerDesc = SamplerDesc();
		samplerDesc.MinFilter = .Nearest;
		samplerDesc.MagFilter = .Nearest;
		samplerDesc.AddressU = .ClampToEdge;
		samplerDesc.AddressV = .ClampToEdge;
		samplerDesc.AddressW = .ClampToEdge;
		samplerDesc.Label = "debug.fontSampler";
		if (!(mDevice.CreateSampler(samplerDesc) case .Ok(let sampler)))
			return .Err;
		mSampler = sampler;

		return CreateFontAtlas();
	}

	/// Declares one view's world space geometry: the three accumulators' lines and triangles,
	/// depth tested and overlaid, drawn through the view's matrix into its sub rectangle.
	public void DeclareGeometry(RenderGraph graph, RGHandle color, RGHandle depth,
		Float4x4 viewProj, DebugDraw global, DebugDraw scene, DebugDraw view,
		TextureFormat colorFormat, TextureFormat depthFormat, int32 viewportX, int32 viewportY,
		uint32 viewportWidth, uint32 viewportHeight, uint32 frameIndex, uint32 viewIndex)
	{
		// The four streams pack into ONE buffer, each drawn as its own range.
		mGeomScratch.Clear();

		AppendVertices(mGeomScratch, (global != null) ? global.LineVertices : default,
			(scene != null) ? scene.LineVertices : default,
			(view != null) ? view.LineVertices : default);
		let overlayLineStart = (uint32)mGeomScratch.Count;

		AppendVertices(mGeomScratch, (global != null) ? global.OverlayLineVertices : default,
			(scene != null) ? scene.OverlayLineVertices : default,
			(view != null) ? view.OverlayLineVertices : default);
		let triangleStart = (uint32)mGeomScratch.Count;

		AppendVertices(mGeomScratch, (global != null) ? global.TriangleVertices : default,
			(scene != null) ? scene.TriangleVertices : default,
			(view != null) ? view.TriangleVertices : default);
		let overlayTriangleStart = (uint32)mGeomScratch.Count;

		AppendVertices(mGeomScratch, (global != null) ? global.OverlayTriangleVertices : default,
			(scene != null) ? scene.OverlayTriangleVertices : default,
			(view != null) ? view.OverlayTriangleVertices : default);
		let total = (uint32)mGeomScratch.Count;

		if (total == 0)
			return;

		let slot = (int)(viewIndex % cMaxViews) * (int)mFramesInFlight
			+ (int)(frameIndex % mFramesInFlight);
		let buffer = UploadGeometry(slot, mGeomScratch);
		if (buffer == null)
			return;

		let pipelines = EnsurePipelines(colorFormat, depthFormat);
		if (pipelines < 0)
			return;

		let lineCount = overlayLineStart;
		let overlayLineCount = (uint32)(triangleStart - overlayLineStart);
		let triangleCount = (uint32)(overlayTriangleStart - triangleStart);
		let overlayTriangleCount = (uint32)(total - overlayTriangleStart);
		let entry = mGeomPipelines[pipelines];

		graph.AddRenderPass("debug.geom", scope (builder) =>
			{
				builder.SetColorTarget(0, color, .Load, .Store, .Black);
				// Depth TESTED, never sampled, so it is not read as a texture: doing both
				// would put the attachment in two layouts at once.
				builder.SetReadOnlyDepthTarget(depth);
				builder.SetViewport(viewportX, viewportY, viewportWidth, viewportHeight);
				builder.NeverCull();

				builder.SetExecute(new (encoder) =>
					{
						encoder.SetVertexBuffer(0, buffer, 0);

						// The pipeline is bound before the push, a push needing a bound layout.
						// All four share the one layout, so pushing the matrix again per
						// stream costs nothing.
						void Draw(IRenderPipeline pipeline, uint32 count, uint32 first)
						{
							var matrix = viewProj;
							encoder.SetPipeline(pipeline);
							encoder.SetPushConstants(.Vertex, 0, sizeof(Float4x4), &matrix);
							encoder.Draw(count, 1, first, 0);
						}

						if (lineCount > 0)
							Draw(entry.LineDepth, lineCount, 0);
						if (overlayLineCount > 0)
							Draw(entry.LineOverlay, overlayLineCount, overlayLineStart);
						if (triangleCount > 0)
							Draw(entry.TriangleDepth, triangleCount, triangleStart);
						if (overlayTriangleCount > 0)
							Draw(entry.TriangleOverlay, overlayTriangleCount,
								overlayTriangleStart);
					});
			});
	}

	/// Declares one view's screen space text and rectangles, built into pixel space quads and
	/// drawn over everything.
	public void DeclareScreen(RenderGraph graph, RGHandle color, Float4x4 viewProj,
		DebugDraw global, DebugDraw scene, DebugDraw view, TextureFormat colorFormat,
		int32 viewportX, int32 viewportY, uint32 viewportWidth, uint32 viewportHeight,
		uint32 frameIndex, uint32 viewIndex)
	{
		mScreenScratch.Clear();
		BuildScreenQuads(mScreenScratch, global, viewProj, viewportWidth, viewportHeight);
		BuildScreenQuads(mScreenScratch, scene, viewProj, viewportWidth, viewportHeight);
		BuildScreenQuads(mScreenScratch, view, viewProj, viewportWidth, viewportHeight);

		if (mScreenScratch.IsEmpty)
			return;

		let slot = (int)(viewIndex % cMaxViews) * (int)mFramesInFlight
			+ (int)(frameIndex % mFramesInFlight);
		let buffer = UploadScreen(slot, mScreenScratch);
		if (buffer == null)
			return;

		let pipeline = EnsureScreenPipeline(colorFormat);
		if (pipeline == null)
			return;

		let count = (uint32)mScreenScratch.Count;
		let push = float[4](1.0f / (float)viewportWidth, 1.0f / (float)viewportHeight, 0.0f, 0.0f);
		let bindGroup = mFontBindGroup;

		graph.AddRenderPass("debug.screen", scope (builder) =>
			{
				builder.SetColorTarget(0, color, .Load, .Store, .Black);
				builder.SetViewport(viewportX, viewportY, viewportWidth, viewportHeight);
				builder.NeverCull();

				builder.SetExecute(new (encoder) =>
					{
						encoder.SetPipeline(pipeline);
						encoder.SetBindGroup(0, bindGroup);
						encoder.SetVertexBuffer(0, buffer, 0);

						var constants = push;
						encoder.SetPushConstants(.Vertex, 0, sizeof(float) * 4, &constants[0]);
						encoder.Draw(count, 1, 0, 0);
					});
			});
	}

	private static void AppendVertices(List<DebugVertex> destination, Span<DebugVertex> a,
		Span<DebugVertex> b, Span<DebugVertex> c)
	{
		for (let vertex in a)
			destination.Add(vertex);
		for (let vertex in b)
			destination.Add(vertex);
		for (let vertex in c)
			destination.Add(vertex);
	}

	/// Emits pixel space quads for one accumulator's two dimensional commands and its world
	/// anchored text.
	private void BuildScreenQuads(List<DebugTextVertex> outVertices, DebugDraw draw,
		Float4x4 viewProj, uint32 viewportWidth, uint32 viewportHeight)
	{
		if (draw == null)
			return;

		let chars = draw.TextChars;

		for (let command in draw.Commands2D)
		{
			let packed = DebugDraw.PackColor(command.Color);

			if (command.Kind == .Rectangle)
			{
				let uv = DebugFont.SolidBlockUV;
				EmitQuad(outVertices, command.Position.X, command.Position.Y, command.Size.X,
					command.Size.Y, uv, packed);
				continue;
			}

			let width = (float)DebugFont.cCharWidth * command.Scale;
			let height = (float)DebugFont.cCharHeight * command.Scale;
			// A NEGATIVE x is DrawScreenTextRight's margin encoding: the pass drew those at
			// the raw negative x, which put right-aligned text off the LEFT edge.
			var x = DebugDraw.ResolveScreenTextX(command.Position.X, command.TextLength, width,
				viewportWidth);
			let y = command.Position.Y;

			for (int32 i = 0; i < command.TextLength; i++)
			{
				if (DebugFont.TryGetCharUV((char32)chars[command.TextStart + i], let uv))
					EmitQuad(outVertices, x, y, width, height, uv, packed);
				x += width;
			}
		}

		// The world anchored text: projected to pixels, then emitted as glyph quads.
		for (let command in draw.TextCommands3D)
		{
			let world = command.WorldPosition;
			let clipX = world.X * viewProj.M[0][0] + world.Y * viewProj.M[1][0]
				+ world.Z * viewProj.M[2][0] + viewProj.M[3][0];
			let clipY = world.X * viewProj.M[0][1] + world.Y * viewProj.M[1][1]
				+ world.Z * viewProj.M[2][1] + viewProj.M[3][1];
			let clipW = world.X * viewProj.M[0][3] + world.Y * viewProj.M[1][3]
				+ world.Z * viewProj.M[2][3] + viewProj.M[3][3];

			// Behind the camera.
			if (clipW <= 0.0f)
				continue;

			let ndcX = clipX / clipW;
			let ndcY = clipY / clipW;
			var x = (ndcX * 0.5f + 0.5f) * (float)viewportWidth;
			let y = (1.0f - (ndcY * 0.5f + 0.5f)) * (float)viewportHeight;

			let packed = DebugDraw.PackColor(command.Color);
			let width = (float)DebugFont.cCharWidth;
			let height = (float)DebugFont.cCharHeight;

			for (int32 i = 0; i < command.TextLength; i++)
			{
				if (DebugFont.TryGetCharUV((char32)chars[command.TextStart + i], let uv))
					EmitQuad(outVertices, x, y, width, height, uv, packed);
				x += width;
			}
		}
	}

	/// Two triangles, wound the same way as everything else the pass emits. The coordinates
	/// arrive as an origin and an opposite corner.
	private static void EmitQuad(List<DebugTextVertex> outVertices, float x, float y, float width,
		float height, Float4 uv, uint32 color)
	{
		let topLeft = DebugTextVertex(.(x, y, 0), .(uv.X, uv.Y), color);
		let topRight = DebugTextVertex(.(x + width, y, 0), .(uv.Z, uv.Y), color);
		let bottomRight = DebugTextVertex(.(x + width, y + height, 0), .(uv.Z, uv.W), color);
		let bottomLeft = DebugTextVertex(.(x, y + height, 0), .(uv.X, uv.W), color);

		outVertices.Add(topLeft);
		outVertices.Add(topRight);
		outVertices.Add(bottomRight);
		outVertices.Add(topLeft);
		outVertices.Add(bottomRight);
		outVertices.Add(bottomLeft);
	}

	private IBuffer UploadGeometry(int slot, List<DebugVertex> vertices)
	{
		if ((slot < 0) || (slot >= cMaxSlots))
			return null;

		let bytes = (uint64)vertices.Count * sizeof(DebugVertex);
		if (!EnsureBuffer(ref mGeomBuffers[slot], ref mGeomCapacities[slot], bytes))
			return null;

		let mapped = mGeomBuffers[slot].Map();
		if (mapped != null)
		{
			Internal.MemCpy(mapped, vertices.Ptr, (int)bytes);
			mGeomBuffers[slot].Unmap();
		}
		return mGeomBuffers[slot];
	}

	private IBuffer UploadScreen(int slot, List<DebugTextVertex> vertices)
	{
		if ((slot < 0) || (slot >= cMaxSlots))
			return null;

		let bytes = (uint64)vertices.Count * sizeof(DebugTextVertex);
		if (!EnsureBuffer(ref mScreenBuffers[slot], ref mScreenCapacities[slot], bytes))
			return null;

		let mapped = mScreenBuffers[slot].Map();
		if (mapped != null)
		{
			Internal.MemCpy(mapped, vertices.Ptr, (int)bytes);
			mScreenBuffers[slot].Unmap();
		}
		return mScreenBuffers[slot];
	}

	/// Grows a slot's buffer by doubling, so a frame that draws steadily stops reallocating.
	private bool EnsureBuffer(ref IBuffer buffer, ref uint64 capacity, uint64 bytes)
	{
		if ((buffer != null) && (capacity >= bytes))
			return true;

		if (buffer != null)
		{
			mDevice.DestroyBuffer(ref buffer);
			capacity = 0;
		}

		var newCapacity = (capacity > 0) ? capacity : 4096;
		while (newCapacity < bytes)
			newCapacity *= 2;

		var desc = BufferDesc();
		desc.Size = newCapacity;
		desc.Usage = .Vertex;
		desc.Memory = .CpuToGpu;
		desc.Label = "debug.vtx";

		if (!(mDevice.CreateBuffer(desc) case .Ok(let created)))
		{
			capacity = 0;
			return false;
		}

		buffer = created;
		capacity = newCapacity;
		return true;
	}

	/// The index of the entry for a pair of formats, or negative when it cannot be built.
	private int EnsurePipelines(TextureFormat colorFormat, TextureFormat depthFormat)
	{
		let shaderVersion = mShaders.Version("debug_geom");

		var index = -1;
		for (int i < cMaxGeomFormats)
		{
			if ((mGeomPipelines[i].LineDepth != null)
				&& (mGeomPipelines[i].ColorFormat == colorFormat)
				&& (mGeomPipelines[i].DepthFormat == depthFormat))
			{
				index = i;
				break;
			}
		}

		if ((index >= 0) && (mGeomPipelines[index].ShaderVersion == shaderVersion))
			return index;

		if (index < 0)
		{
			for (int i < cMaxGeomFormats)
			{
				if (mGeomPipelines[i].LineDepth == null)
				{
					index = i;
					break;
				}
			}
		}

		// More format pairs than the cache holds: the first is the one to evict.
		if (index < 0)
			index = 0;

		DestroyGeomPipelines(ref mGeomPipelines[index]);

		mGeomPipelines[index].LineDepth = MakeGeomPipeline(colorFormat, depthFormat, .LineList,
			Depth.NearerOrEqual);
		mGeomPipelines[index].LineOverlay = MakeGeomPipeline(colorFormat, depthFormat, .LineList,
			.Always);
		mGeomPipelines[index].TriangleDepth = MakeGeomPipeline(colorFormat, depthFormat,
			.TriangleList, Depth.NearerOrEqual);
		mGeomPipelines[index].TriangleOverlay = MakeGeomPipeline(colorFormat, depthFormat,
			.TriangleList, .Always);

		if ((mGeomPipelines[index].LineDepth == null) || (mGeomPipelines[index].LineOverlay == null)
			|| (mGeomPipelines[index].TriangleDepth == null)
			|| (mGeomPipelines[index].TriangleOverlay == null))
		{
			DestroyGeomPipelines(ref mGeomPipelines[index]);
			return -1;
		}

		mGeomPipelines[index].ColorFormat = colorFormat;
		mGeomPipelines[index].DepthFormat = depthFormat;
		mGeomPipelines[index].ShaderVersion = shaderVersion;
		return index;
	}

	private IRenderPipeline MakeGeomPipeline(TextureFormat colorFormat, TextureFormat depthFormat,
		PrimitiveTopology topology, CompareFunction compare)
	{
		let vertex = mShaders.GetVariant("debug_geom", .Vertex, .None);
		let fragment = mShaders.GetVariant("debug_geom", .Fragment, .None);
		if ((vertex == null) || (fragment == null))
			return null;

		var attributes = VertexAttribute[2](
			.(.Float32x3, 0, 0),
			.(.Unorm8x4, 12, 1));

		var bufferLayout = VertexBufferLayout();
		bufferLayout.Stride = sizeof(DebugVertex);
		bufferLayout.StepMode = .Vertex;
		bufferLayout.Attributes = .(&attributes[0], 2);

		var color = ColorTargetState();
		color.Format = colorFormat;
		color.Blend = BlendState.AlphaBlend;

		var fragmentState = FragmentState();
		fragmentState.Shader = .(fragment, "main", .Fragment);
		fragmentState.Targets = .(&color, 1);

		var depthStencil = DepthStencilState();
		depthStencil.Format = depthFormat;
		depthStencil.DepthWriteEnabled = false;
		depthStencil.DepthCompare = compare;

		var desc = RenderPipelineDesc();
		desc.Layout = mGeomLayout;
		desc.Vertex.Shader = .(vertex, "main", .Vertex);
		desc.Vertex.Buffers = .(&bufferLayout, 1);
		desc.Fragment = fragmentState;
		desc.Primitive.Topology = topology;
		desc.Primitive.CullMode = .None;
		desc.DepthStencil = depthStencil;
		desc.Label = "debug.geom";

		if (!(mDevice.CreateRenderPipeline(desc) case .Ok(let pipeline)))
			return null;
		return pipeline;
	}

	private IRenderPipeline EnsureScreenPipeline(TextureFormat colorFormat)
	{
		let shaderVersion = mShaders.Version("debug_screen");
		if ((mScreenPipeline != null) && (mScreenFormat == colorFormat)
			&& (mScreenShaderVersion == shaderVersion))
			return mScreenPipeline;

		if (mScreenPipeline != null)
			mDevice.DestroyRenderPipeline(ref mScreenPipeline);

		let vertex = mShaders.GetVariant("debug_screen", .Vertex, .None);
		let fragment = mShaders.GetVariant("debug_screen", .Fragment, .None);
		if ((vertex == null) || (fragment == null))
			return null;

		var attributes = VertexAttribute[3](
			.(.Float32x3, 0, 0),
			.(.Float32x2, 12, 1),
			.(.Unorm8x4, 20, 2));

		var bufferLayout = VertexBufferLayout();
		bufferLayout.Stride = sizeof(DebugTextVertex);
		bufferLayout.StepMode = .Vertex;
		bufferLayout.Attributes = .(&attributes[0], 3);

		var color = ColorTargetState();
		color.Format = colorFormat;
		color.Blend = BlendState.AlphaBlend;

		var fragmentState = FragmentState();
		fragmentState.Shader = .(fragment, "main", .Fragment);
		fragmentState.Targets = .(&color, 1);

		var desc = RenderPipelineDesc();
		desc.Layout = mScreenLayout;
		desc.Vertex.Shader = .(vertex, "main", .Vertex);
		desc.Vertex.Buffers = .(&bufferLayout, 1);
		desc.Fragment = fragmentState;
		desc.Primitive.Topology = .TriangleList;
		desc.Primitive.CullMode = .None;
		desc.Label = "debug.screen";

		if (!(mDevice.CreateRenderPipeline(desc) case .Ok(let pipeline)))
			return null;

		mScreenPipeline = pipeline;
		mScreenFormat = colorFormat;
		mScreenShaderVersion = shaderVersion;
		return mScreenPipeline;
	}

	private Result<void> CreateFontAtlas()
	{
		let pixels = scope List<uint8>();
		DebugFont.GenerateTextureData(pixels);

		let width = (uint32)DebugFont.cTextureWidth;
		let height = (uint32)DebugFont.cTextureHeight;

		var textureDesc = TextureDesc();
		textureDesc.Dimension = .Texture2D;
		textureDesc.Format = .R8Unorm;
		textureDesc.Width = width;
		textureDesc.Height = height;
		textureDesc.Depth = 1;
		textureDesc.ArrayLayerCount = 1;
		textureDesc.MipLevelCount = 1;
		textureDesc.Usage = .Sampled | .CopyDst;
		textureDesc.Label = "debug.font";
		if (!(mDevice.CreateTexture(textureDesc) case .Ok(let texture)))
			return .Err;
		mFontTexture = texture;

		var viewDesc = TextureViewDesc();
		viewDesc.Format = .R8Unorm;
		viewDesc.Dimension = .Texture2D;
		viewDesc.MipLevelCount = 1;
		viewDesc.ArrayLayerCount = 1;
		if (!(mDevice.CreateTextureView(texture, viewDesc) case .Ok(let view)))
			return .Err;
		mFontView = view;

		let queue = mDevice.GetQueue(.Graphics, 0);
		if (queue != null)
		{
			if (queue.CreateTransferBatch() case .Ok(var batch))
			{
				var layout = TextureDataLayout();
				layout.BytesPerRow = width;
				layout.RowsPerImage = height;
				batch.WriteTexture(texture, pixels, layout, .(width, height, 1));
				batch.Submit().IgnoreError();
				queue.DestroyTransferBatch(ref batch);
			}
		}

		var entries = BindGroupEntry[2](
			BindGroupEntry.TextureEntry(mFontView),
			BindGroupEntry.SamplerEntry(mSampler));

		var bindGroupDesc = BindGroupDesc();
		bindGroupDesc.Layout = mScreenBindGroupLayout;
		bindGroupDesc.Entries = .(&entries[0], 2);
		if (!(mDevice.CreateBindGroup(bindGroupDesc) case .Ok(let bindGroup)))
			return .Err;
		mFontBindGroup = bindGroup;

		return .Ok;
	}

	private void DestroyGeomPipelines(ref DebugGeomPipelines entry)
	{
		if (entry.LineDepth != null)
			mDevice.DestroyRenderPipeline(ref entry.LineDepth);
		if (entry.LineOverlay != null)
			mDevice.DestroyRenderPipeline(ref entry.LineOverlay);
		if (entry.TriangleDepth != null)
			mDevice.DestroyRenderPipeline(ref entry.TriangleDepth);
		if (entry.TriangleOverlay != null)
			mDevice.DestroyRenderPipeline(ref entry.TriangleOverlay);

		entry.ColorFormat = .Undefined;
		entry.DepthFormat = .Undefined;
	}

	private void Shutdown()
	{
		if (mDevice == null)
			return;

		for (int i < cMaxSlots)
		{
			if (mGeomBuffers[i] != null)
				mDevice.DestroyBuffer(ref mGeomBuffers[i]);
			if (mScreenBuffers[i] != null)
				mDevice.DestroyBuffer(ref mScreenBuffers[i]);
		}

		for (int i < cMaxGeomFormats)
			DestroyGeomPipelines(ref mGeomPipelines[i]);

		if (mScreenPipeline != null)
			mDevice.DestroyRenderPipeline(ref mScreenPipeline);
		if (mFontBindGroup != null)
			mDevice.DestroyBindGroup(ref mFontBindGroup);
		if (mFontView != null)
			mDevice.DestroyTextureView(ref mFontView);
		if (mFontTexture != null)
			mDevice.DestroyTexture(ref mFontTexture);
		if (mSampler != null)
			mDevice.DestroySampler(ref mSampler);
		if (mGeomLayout != null)
			mDevice.DestroyPipelineLayout(ref mGeomLayout);
		if (mScreenLayout != null)
			mDevice.DestroyPipelineLayout(ref mScreenLayout);
		if (mScreenBindGroupLayout != null)
			mDevice.DestroyBindGroupLayout(ref mScreenBindGroupLayout);
	}
}
