using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Image;
using Sedulous.RHI;
using Sedulous.Texture;
using Sedulous.VG;

namespace Sedulous.VG.Renderer;

/// Draws a batch through the RHI.
///
/// It does NOT own the device or the swap chain. It owns its pipelines, its per frame
/// buffers, and a cache of the GPU textures it uploaded.
class VGRenderer
{
	/// Pad, repeat and mirror: one bind group slot each, because the spread picks the
	/// sampler and the sampler is part of the bind group.
	private const int cSpreadCount = 3;

	/// The stencil bit planes, which must match what the fill phases assume: the top bit
	/// is the clip mask and the low seven accumulate fill winding.
	private const uint8 cClipBit = 0x80;
	private const uint8 cWindingMask = 0x7F;

	/// The INITIAL per frame vertex capacity. It grows on demand.
	private const int32 cInitialVertexCapacity = 131072;

	/// The ceiling growth stops at. Past this a draw list is refused rather than consuming
	/// unbounded memory.
	private const int32 cMaxVertexCapacity = 131072 * 16;

	/// One slot per SLICE, which in practice means one per surface, and one per layer.
	private const int32 cMaxUniformSlots = 256;

	/// Layer targets come in sizes rounded up to a bucket, so a layer that changes size a little
	/// (an animated panel) keeps its target; the composite samples just the content's part.
	private const uint32 cLayerTargetBucket = 64;
	/// The BeginFrames of a frame slot a layer target may go unused before it is freed.
	private const int32 cLayerTargetIdleFrames = 120;

	/// The dynamic offset alignment, which is larger than the uniforms themselves.
	private const int32 cUniformSlotSize = 256;

	private const int cBlendVariantCount = 3;
	private const int cClippedBlendCount = 4;

	private IDevice mDevice;
	private IQueue mQueue;
	private int32 mFrameCount = 0;
	private TextureFormat mTargetFormat = .BGRA8UnormSrgb;
	private VGTargetConfig mTargetConfig = .();
	private bool mInitialized = false;
	private VGRenderStats mLastRenderStats = .();
	private VGRenderStats mLastLayerStats = .();

	// Borrowed: the shader system owns these and outlives the renderer. Kept so a blend
	// variant can be built lazily on first use.
	private IShaderModule mVertexModule;
	private IShaderModule mFragmentModule;
	private IShaderModule mDistanceFieldModule;
	private IShaderModule mGradRadialModule;
	private IShaderModule mGradConicModule;
	private IShaderModule mBoxShadowModule;
	/// Analytic boxes (VGDrawMode.Box): a vertex shader of their own as well.
	private IShaderModule mBoxVertexModule;
	private IShaderModule mBoxFragmentModule;
	/// Layer composites (VGDrawMode.Layer).
	private IShaderModule mLayerFragmentModule;

	private IBindGroupLayout mBindGroupLayout;
	private IPipelineLayout mPipelineLayout;

	private IRenderPipeline mPipeline;
	private IRenderPipeline mDistanceFieldPipeline;
	private IRenderPipeline mGradRadialPipeline;
	private IRenderPipeline mGradConicPipeline;
	/// Nullable: a host that never supplies the shadow shader draws no box shadows at all,
	/// rather than drawing the quadrant quads as flat colour.
	private IRenderPipeline mBoxShadowPipeline;
	/// Nullable likewise: box vertices are not VG vertices, so no other pipeline can draw them.
	private IRenderPipeline mBoxPipeline;
	/// Nullable likewise: a layer target holds premultiplied colour, which the default shader
	/// would multiply again.
	private IRenderPipeline mLayerPipeline;
	/// The layer blur (vg_blur), nullable: without it a blurred layer composites sharp.
	private IRenderPipeline mBlurPipeline;
	private IRenderPipeline mStencilWriteNonZero;
	private IRenderPipeline mStencilWriteEvenOdd;
	private IRenderPipeline mCoverPipeline;
	private IRenderPipeline mCoverGradRadialPipeline;
	private IRenderPipeline mCoverGradConicPipeline;
	private IRenderPipeline mClippedWriteNonZero;
	private IRenderPipeline mClippedWriteEvenOdd;
	private IRenderPipeline mClipApplyPipeline;
	private IRenderPipeline mClipClearPipeline;

	/// Indexed by blend mode minus one, then by kind: the Normal variants are the eagerly
	/// built pipelines above.
	private IRenderPipeline[cBlendVariantCount][PipelineKind.Count] mBlendPipelines;
	/// Indexed by blend mode, then by kind. Normal IS a variant here, because clipping
	/// changes the stencil state whatever the blend is.
	private IRenderPipeline[cClippedBlendCount][PipelineKind.Count] mClippedPipelines;

	/// Clamp, for images and padded gradients alike. Repeat would bleed the opposite edge
	/// into the bilinear taps at zero and one.
	private ISampler mSampler;
	private ISampler mSamplerRepeat;
	private ISampler mSamplerMirror;

	private List<IBuffer> mVertexBuffers = new .() ~ delete _;
	private List<IBuffer> mIndexBuffers = new .() ~ delete _;
	private List<IBuffer> mUniformBuffers = new .() ~ delete _;

	/// Only ever grows. An overflowing Prepare raises it and skips that slice; the buffers
	/// are resized at the next BeginFrame, when the slot's previous submission is done.
	private int32 mTargetVertexCapacity = cInitialVertexCapacity;
	private List<int32> mFrameVertexCapacity = new .() ~ delete _;
	private bool mCapacityWarned = false;

	private List<CachedTexture> mTextureCache = new .() ~ DeleteContainerAndItems!(_);
	private List<(CachedTexture Entry, int32 FramesLeft)> mRetiredTextures = new .() ~ delete _;

	private List<ImageData> mBatchTextures = new .() ~ delete _;
	private List<VGCommand> mDrawCommands = new .() ~ delete _;
	/// This frame's slices' layers (VGRenderSlice.LayerStart).
	private List<PreparedLayer> mLayers = new .() ~ delete _;
	/// Every frame slot's layer targets, each tagged with its slot.
	private List<LayerTarget> mLayerTargets = new .() ~ DeleteContainerAndItems!(_);

	private List<uint32> mFrameVertexOffsets = new .() ~ delete _;
	private List<uint32> mFrameIndexOffsets = new .() ~ delete _;
	private List<uint32> mFrameUniformSlotCount = new .() ~ delete _;

	public ~this()
	{
		Dispose();
	}

	public bool IsInitialized => mInitialized;

	/// Whether Initialize was given a stencil capable target. A host gates the context's
	/// stencil fills on this.
	public bool StencilFillsSupported => mCoverPipeline != null;

	public int CachedTextureCount => mTextureCache.Count;
	public int RetiredTextureCount => mRetiredTextures.Count;

	/// The stencil capable format a device actually accepts at this sample count, probed
	/// with a tiny texture.
	///
	/// Probed rather than assumed, because drivers commonly support only ONE of the two
	/// combined formats. Undefined means none, and the host then skips the stencil config.
	public static TextureFormat PickStencilCapableFormat(IDevice device, uint32 sampleCount)
	{
		for (let format in scope TextureFormat[](
			.Depth24PlusStencil8, .Depth32FloatStencil8, .Stencil8))
		{
			var desc = TextureDesc();
			desc.Dimension = .Texture2D;
			desc.Format = format;
			desc.Width = 4;
			desc.Height = 4;
			desc.Depth = 1;
			desc.Usage = .DepthStencil;
			desc.SampleCount = sampleCount;

			if (device.CreateTexture(desc) case .Ok(var probe))
			{
				device.DestroyTexture(ref probe);
				return format;
			}
		}
		return .Undefined;
	}

	/// Brings the renderer up against a device and the already compiled shader modules.
	///
	/// The optional modules each unlock a pipeline family. Passing none of them leaves a
	/// renderer that draws ordinary geometry and silently SKIPS the commands it has no
	/// pipeline for, which is what keeps a stale batch from drawing winding fans as colour.
	public Result<void, ErrorCode> Initialize(IDevice device, IShaderModule vertexShader,
		IShaderModule fragmentShader, TextureFormat targetFormat, int32 frameCount,
		IShaderModule distanceFieldFragmentShader = null, IShaderModule gradRadialFragmentShader = null,
		IShaderModule gradConicFragmentShader = null, VGTargetConfig targetConfig = .(),
		IShaderModule boxShadowFragmentShader = null, IShaderModule boxVertexShader = null,
		IShaderModule boxFragmentShader = null, IShaderModule layerFragmentShader = null,
		IShaderModule blurVertexShader = null, IShaderModule blurFragmentShader = null)
	{
		mDevice = device;
		mQueue = device.GetQueue(.Graphics, 0);
		mTargetFormat = targetFormat;
		mFrameCount = frameCount;
		mTargetConfig = targetConfig;

		mVertexModule = vertexShader;
		mFragmentModule = fragmentShader;
		mDistanceFieldModule = distanceFieldFragmentShader;
		mGradRadialModule = gradRadialFragmentShader;
		mGradConicModule = gradConicFragmentShader;
		mBoxShadowModule = boxShadowFragmentShader;
		mBoxVertexModule = boxVertexShader;
		mBoxFragmentModule = boxFragmentShader;
		mLayerFragmentModule = layerFragmentShader;

		if (CreateSamplers() case .Err)
			return .Err(.Unknown);
		if (CreateLayouts() case .Err)
			return .Err(.Unknown);

		if (!(CreatePipeline(vertexShader, fragmentShader, .None) case .Ok(out mPipeline)))
			return .Err(.Unknown);

		if (distanceFieldFragmentShader != null)
		{
			if (!(CreatePipeline(vertexShader, distanceFieldFragmentShader, .None)
				case .Ok(out mDistanceFieldPipeline)))
				return .Err(.Unknown);
		}
		if (gradRadialFragmentShader != null)
		{
			if (!(CreatePipeline(vertexShader, gradRadialFragmentShader, .None)
				case .Ok(out mGradRadialPipeline)))
				return .Err(.Unknown);
		}
		if (gradConicFragmentShader != null)
		{
			if (!(CreatePipeline(vertexShader, gradConicFragmentShader, .None)
				case .Ok(out mGradConicPipeline)))
				return .Err(.Unknown);
		}
		// The box shadow family, for the UI's blurred rounded rects. Direct fills only.
		if (boxShadowFragmentShader != null)
		{
			if (!(CreatePipeline(vertexShader, boxShadowFragmentShader, .None)
				case .Ok(out mBoxShadowPipeline)))
				return .Err(.Unknown);
		}
		// The analytic box family (VGContext.DrawBox): its own vertex layout and shaders.
		if ((boxVertexShader != null) && (boxFragmentShader != null))
		{
			if (!(CreatePipeline(boxVertexShader, boxFragmentShader, .None, .Normal, false, true)
				case .Ok(out mBoxPipeline)))
				return .Err(.Unknown);
		}
		// The layer composite (VGContext.PushLayer): samples a premultiplied target.
		if (layerFragmentShader != null)
		{
			if (!(CreatePipeline(vertexShader, layerFragmentShader, .None) case .Ok(out mLayerPipeline)))
				return .Err(.Unknown);
		}
		// The layer blur (a layer's Blur): one axis of a Gaussian over its target.
		if ((blurVertexShader != null) && (blurFragmentShader != null))
		{
			if (!(CreateBlurPipeline(blurVertexShader, blurFragmentShader) case .Ok(out mBlurPipeline)))
				return .Err(.Unknown);
		}

		// The stencil families exist only with a host provided attachment.
		if (targetConfig.DepthStencilFormat != .Undefined)
		{
			if (CreateStencilPipelines(vertexShader, fragmentShader, gradRadialFragmentShader,
				gradConicFragmentShader) case .Err)
				return .Err(.Unknown);
		}

		if (CreatePerFrameResources() case .Err)
			return .Err(.Unknown);

		mFrameVertexOffsets.Resize(frameCount);
		mFrameIndexOffsets.Resize(frameCount);
		mFrameUniformSlotCount.Resize(frameCount);

		mInitialized = true;
		return .Ok;
	}

	private Result<void, ErrorCode> CreateStencilPipelines(IShaderModule vertexShader,
		IShaderModule fragmentShader, IShaderModule gradRadial, IShaderModule gradConic)
	{
		if (!(CreatePipeline(vertexShader, fragmentShader, .WriteNonZero)
			case .Ok(out mStencilWriteNonZero)))
			return .Err(.Unknown);
		if (!(CreatePipeline(vertexShader, fragmentShader, .WriteEvenOdd)
			case .Ok(out mStencilWriteEvenOdd)))
			return .Err(.Unknown);
		if (!(CreatePipeline(vertexShader, fragmentShader, .Cover) case .Ok(out mCoverPipeline)))
			return .Err(.Unknown);

		// A cover per fragment variant, so a gradient fill covers with its own exact per
		// pixel shader rather than an approximation.
		if (gradRadial != null)
		{
			if (!(CreatePipeline(vertexShader, gradRadial, .Cover)
				case .Ok(out mCoverGradRadialPipeline)))
				return .Err(.Unknown);
		}
		if (gradConic != null)
		{
			if (!(CreatePipeline(vertexShader, gradConic, .Cover)
				case .Ok(out mCoverGradConicPipeline)))
				return .Err(.Unknown);
		}

		if (!(CreatePipeline(vertexShader, fragmentShader, .ClipApply)
			case .Ok(out mClipApplyPipeline)))
			return .Err(.Unknown);
		if (!(CreatePipeline(vertexShader, fragmentShader, .ClipClear)
			case .Ok(out mClipClearPipeline)))
			return .Err(.Unknown);

		return .Ok;
	}

	// === per frame ===

	/// Resets a frame slot's ring offsets. Called once before that frame's first Prepare.
	public void BeginFrame(int32 frameIndex)
	{
		// Retired textures age here. Freeing at eviction time would destroy bind groups a
		// submitted frame is still referencing.
		for (int i = mRetiredTextures.Count - 1; i >= 0; i--)
		{
			var retired = mRetiredTextures[i];
			retired.FramesLeft--;
			if (retired.FramesLeft > 0)
			{
				mRetiredTextures[i] = retired;
				continue;
			}

			DisposeCachedTexture(retired.Entry);
			delete retired.Entry;
			mRetiredTextures.RemoveAt(i);
		}

		mFrameVertexOffsets[frameIndex] = 0;
		mFrameIndexOffsets[frameIndex] = 0;
		mFrameUniformSlotCount[frameIndex] = 0;

		// Any pending growth applies NOW, while this slot is free for reuse.
		GrowFrameBuffers(frameIndex);

		mDrawCommands.Clear();
		mBatchTextures.Clear();
		mLayers.Clear();
		ReleaseLayerTargets(frameIndex);
	}

	/// Uploads one batch into the shared frame buffers, returning where it landed.
	public VGRenderSlice Prepare(VGBatch batch, int32 frameIndex, uint32 width, uint32 height)
	{
		// The eviction list is the cache's invalidation signal, and it is processed even
		// when the batch draws nothing and BEFORE any upload: a recycled allocation may
		// reuse an evicted address this very frame.
		for (let evicted in batch.EvictedTextures)
			EvictCachedTexture(evicted);

		if (batch.IsEmpty)
			return .();

		let vertexBytes = (uint32)(batch.Vertices.Count * VGRenderVertex.SizeInBytes);
		let indexBytes = (uint32)(batch.Indices.Count * sizeof(uint32));
		// The slice's boxes follow its ordinary vertices in the same buffer.
		let boxBytes = (uint32)(batch.BoxVertices.Count * VGBoxVertex.SizeInBytes);
		let vertexOffset = mFrameVertexOffsets[frameIndex];
		let indexOffset = mFrameIndexOffsets[frameIndex];
		let uniformSlot = mFrameUniformSlotCount[frameIndex];

		// A HARD cap rather than a growable one: a slot is per surface, and past sixty
		// four surfaces something else has gone wrong.
		if (uniformSlot >= (uint32)cMaxUniformSlots)
			return .();

		if (!FitsOrGrows(frameIndex, vertexOffset, vertexBytes + boxBytes, indexOffset, indexBytes))
			return .();

		let commandStart = (int32)mDrawCommands.Count;
		let textureBase = (int32)mBatchTextures.Count;

		let renderVertices = scope List<VGRenderVertex>();
		renderVertices.Reserve(batch.Vertices.Count);
		for (let vertex in batch.Vertices)
			renderVertices.Add(.(vertex));

		// The slice's layers: each kept to its parent (the canvas for the outermost), given a
		// uniform slot of its own (its projection over its bounds) and a target size. Parents go
		// first, by nesting depth: a backdrop blur makes a layer the parent of earlier ones.
		let layerBase = (int32)mLayers.Count;
		var nextUniformSlot = uniformSlot + 1;
		let order = scope List<int32>(batch.Layers.Count);
		for (int l < batch.Layers.Count)
		{
			var prepared = PreparedLayer();
			for (var p = batch.Layers[l].Parent; (p >= 0) && (prepared.Depth <= batch.Layers.Count);
				p = batch.Layers[p].Parent)
				prepared.Depth++;
			mLayers.Add(prepared);
			order.Add((int32)l);
		}
		// A stable insertion sort by depth: layers are few.
		for (int i = 1; i < order.Count; i++)
		{
			for (int j = i; (j > 0) && (mLayers[layerBase + order[j - 1]].Depth > mLayers[layerBase + order[j]].Depth); j--)
				Swap!(order[j - 1], order[j]);
		}
		for (let l in order)
		{
			let source = batch.Layers[l];
			var layer = ref mLayers[layerBase + l];
			layer.Parent = (source.Parent >= 0) ? (source.Parent + layerBase) : -1;
			var outer = Rectangle(0.0f, 0.0f, (float)width, (float)height);
			var parentValid = true;
			if (layer.Parent >= 0)
			{
				outer = mLayers[layer.Parent].Bounds;
				parentValid = mLayers[layer.Parent].Valid;
			}
			let x0 = Max(source.Bounds.X, outer.X);
			let y0 = Max(source.Bounds.Y, outer.Y);
			let x1 = Min(source.Bounds.X + source.Bounds.Width, outer.X + outer.Width);
			let y1 = Min(source.Bounds.Y + source.Bounds.Height, outer.Y + outer.Height);
			layer.Bounds = .(x0, y0, Max(0.0f, x1 - x0), Max(0.0f, y1 - y0));
			layer.Width = (uint32)layer.Bounds.Width;
			layer.Height = (uint32)layer.Bounds.Height;
			layer.TargetWidth = RoundUpToBucket(layer.Width);
			layer.TargetHeight = RoundUpToBucket(layer.Height);
			// A blur, in place or a backdrop's copy, takes two more slots, across then down;
			// without its pipeline, none.
			layer.Blur = (mBlurPipeline != null) ? source.Blur : 0.0f;
			layer.BackdropBlur = (mBlurPipeline != null) ? source.BackdropBlur : 0.0f;
			let blurs = (layer.Blur > 0.0f) || (layer.BackdropBlur > 0.0f);
			let slots = blurs ? 3u : 1u;
			layer.Valid = parentValid && (layer.Width > 0) && (layer.Height > 0)
				&& ((nextUniformSlot + slots) <= (uint32)cMaxUniformSlots);
			if (layer.Valid)
			{
				layer.UniformOffset = nextUniformSlot * (uint32)cUniformSlotSize;
				nextUniformSlot++;
				if (blurs)
				{
					layer.BlurUniformOffset = nextUniformSlot * (uint32)cUniformSlotSize;
					nextUniformSlot += 2;
				}
			}
		}
		// A composite samples its layer's target where its geometry lies: texcoords from
		// positions, over the target's bucketed size.
		for (let command in batch.Commands)
		{
			if ((command.DrawMode != .Layer) || (command.CompositeLayer < 0))
				continue;
			let layer = mLayers[command.CompositeLayer + layerBase];
			if (!layer.Valid)
				continue; // the composite is skipped at Render
			for (int k < command.IndexCount)
			{
				let at = (int)batch.Indices[command.StartIndex + k];
				if (at >= renderVertices.Count)
					continue;
				var vertex = ref renderVertices[at];
				vertex.TexCoord = .((vertex.Position[0] - layer.Bounds.X) / (float)layer.TargetWidth,
					(vertex.Position[1] - layer.Bounds.Y) / (float)layer.TargetHeight);
			}
		}

		if (vertexBytes > 0)
			WriteBuffer(mVertexBuffers[frameIndex], vertexOffset, renderVertices.Ptr, vertexBytes);
		if (boxBytes > 0)
			WriteBuffer(mVertexBuffers[frameIndex], vertexOffset + vertexBytes, batch.BoxVertices.Ptr, boxBytes);
		// Verbatim: they are relative to the slice's own vertex base, which the vertex
		// buffer offset supplies.
		if (indexBytes > 0)
			WriteBuffer(mIndexBuffers[frameIndex], indexOffset, batch.Indices.Ptr, indexBytes);

		// The commands index into a SHARED texture list, so their indices are rebased.
		mBatchTextures.AddRange(batch.Textures);
		for (var command in batch.Commands)
		{
			if (command.TextureIndex >= 0)
				command.TextureIndex += textureBase;
			if (command.Layer >= 0)
				command.Layer += layerBase;
			if (command.CompositeLayer >= 0)
				command.CompositeLayer += layerBase;
			mDrawCommands.Add(command);
		}

		var uniforms = VGUniforms();
		uniforms.Projection = OrthoOffCenter((float)width, (float)height);
		uniforms.DistanceFieldPixelRange = batch.DistanceFieldPixelRange;
		uniforms.DistanceFieldAtlasWidth = batch.DistanceFieldAtlasWidth;
		uniforms.DistanceFieldAtlasHeight = batch.DistanceFieldAtlasHeight;
		uniforms.BlendSpace = (mTargetConfig.BlendSpace == .Encoded) ? 1.0f : 0.0f;

		let uniformOffset = uniformSlot * (uint32)cUniformSlotSize;
		WriteBuffer(mUniformBuffers[frameIndex], uniformOffset, &uniforms, sizeof(VGUniforms));
		for (int l = layerBase; l < mLayers.Count; l++)
		{
			let layer = mLayers[l];
			if (!layer.Valid)
				continue;
			uniforms.Projection = OrthoOffCenter(layer.Bounds.X, layer.Bounds.Y, (float)layer.Width,
				(float)layer.Height);
			WriteBuffer(mUniformBuffers[frameIndex], layer.UniformOffset, &uniforms, sizeof(VGUniforms));
			if ((layer.Blur > 0.0f) || (layer.BackdropBlur > 0.0f))
			{
				var blur = VGBlurUniforms();
				blur.Region = .((float)layer.Width / (float)layer.TargetWidth,
					(float)layer.Height / (float)layer.TargetHeight);
				blur.Sigma = Max(layer.Blur, layer.BackdropBlur);
				blur.Radius = Ceil(3.0f * blur.Sigma);
				blur.Step = .(1.0f / (float)layer.TargetWidth, 0.0f); // across
				WriteBuffer(mUniformBuffers[frameIndex], layer.BlurUniformOffset, &blur, sizeof(VGBlurUniforms));
				blur.Step = .(0.0f, 1.0f / (float)layer.TargetHeight); // down
				WriteBuffer(mUniformBuffers[frameIndex], layer.BlurUniformOffset + (uint32)cUniformSlotSize, &blur,
					sizeof(VGBlurUniforms));
			}
		}

		for (int32 index = textureBase; index < (int32)mBatchTextures.Count; index++)
			UpdateTextureBindGroup(index, frameIndex, .Pad);

		mFrameVertexOffsets[frameIndex] = vertexOffset + vertexBytes + boxBytes;
		mFrameIndexOffsets[frameIndex] = indexOffset + indexBytes;
		mFrameUniformSlotCount[frameIndex] = nextUniformSlot;

		var slice = VGRenderSlice();
		slice.VertexByteOffset = vertexOffset;
		slice.IndexByteOffset = indexOffset;
		slice.BoxVertexByteOffset = vertexOffset + vertexBytes;
		slice.UniformByteOffset = uniformOffset;
		slice.DrawCommandStart = commandStart;
		slice.DrawCommandCount = (int32)mDrawCommands.Count - commandStart;
		slice.LayerStart = layerBase;
		slice.LayerCount = (int32)mLayers.Count - layerBase;
		slice.IsValid = true;
		return slice;
	}

	/// Whether this slice fits. When it does not, the TARGET capacity is raised and the
	/// slice skipped: the growth happens at the next BeginFrame, when the slot is free.
	///
	/// One frame may blank during a growth step and then render, rather than the surface
	/// staying blank for as long as the large draw list persists.
	private bool FitsOrGrows(int32 frameIndex, uint32 vertexOffset, uint32 vertexBytes,
		uint32 indexOffset, uint32 indexBytes)
	{
		let capacity = (uint32)mFrameVertexCapacity[frameIndex];
		let maxVertexBytes = capacity * (uint32)VGRenderVertex.SizeInBytes;
		// The index capacity always tracks three per vertex, which is one index per
		// triangle corner.
		let maxIndexBytes = capacity * 3 * (uint32)sizeof(uint32);

		if (((vertexOffset + vertexBytes) <= maxVertexBytes)
			&& ((indexOffset + indexBytes) <= maxIndexBytes))
			return true;

		let needed = ((vertexOffset + vertexBytes) / (uint32)VGRenderVertex.SizeInBytes) + 1;
		if (needed > (uint32)cMaxVertexCapacity)
		{
			// Once, so a persistently oversized draw list does not flood the log.
			if (!mCapacityWarned)
			{
				mCapacityWarned = true;
				GlobalLog(.Warning,
					"VG: a draw list needs {} vertices, past the {} ceiling. The surface will not fully render this frame.",
					needed, cMaxVertexCapacity);
			}
			return false;
		}

		var want = mTargetVertexCapacity;
		while (((uint32)want < needed) && (want < cMaxVertexCapacity))
			want *= 2;
		if (want > mTargetVertexCapacity)
			mTargetVertexCapacity = want;

		return false;
	}

	// === rendering ===

	/// Maps a command's content space clip into framebuffer coordinates.
	///
	/// Clamped to the content box FIRST and offset second, so a viewport sub rectangle's
	/// content can never bleed into a neighbouring view. Pure, so it is testable without a
	/// device.
	public static ScissorRect ComputeScissor(Rectangle clipRect, int32 viewportX, int32 viewportY,
		uint32 width, uint32 height)
	{
		// Ceil on the near edge and floor on the far one, so a partially covered pixel is
		// EXCLUDED rather than included: a scissor that grew by rounding would let content
		// spill a pixel past its clip.
		let startX = (int32)Ceil(Max(0.0f, clipRect.X));
		let startY = (int32)Ceil(Max(0.0f, clipRect.Y));
		let endX = (int32)Floor(Min(clipRect.X + clipRect.Width, (float)width));
		let endY = (int32)Floor(Min(clipRect.Y + clipRect.Height, (float)height));

		var rect = ScissorRect();
		rect.X = viewportX + startX;
		rect.Y = viewportY + startY;
		rect.Width = (uint32)Max(0, endX - startX);
		rect.Height = (uint32)Max(0, endY - startY);
		return rect;
	}

	/// Dispatches a slice's draws over the whole target.
	public void Render(IRenderPassEncoder renderPass, uint32 width, uint32 height, int32 frameIndex,
		VGRenderSlice slice) => Render(renderPass, 0, 0, width, height, frameIndex, slice);

	/// Dispatches a slice's draws into a VIEWPORT SUB RECTANGLE of the pass's target.
	///
	/// Content coordinates map to the rectangle at the given origin, and every scissor,
	/// the default one included, is clamped to it. The slice must have been prepared with
	/// the same extent, because that is what its projection was built from.
	public void Render(IRenderPassEncoder renderPass, int32 viewportX, int32 viewportY,
		uint32 width, uint32 height, int32 frameIndex, VGRenderSlice slice)
	{
		mLastRenderStats = .();
		if (!slice.IsValid || (slice.DrawCommandCount == 0))
			return;
		DrawCommands(renderPass, frameIndex, slice, -1, viewportX, viewportY, width, height,
			slice.UniformByteOffset, 0.0f, 0.0f, ref mLastRenderStats);
	}

	/// Draws the slice's offscreen layers (VGContext.PushLayer) into targets of their own, each
	/// in a pass of its own, innermost first, so the slice's Render can composite them.
	///
	/// Call it after Prepare and before the pass Render draws into, since passes do not nest. A
	/// layer this does not draw (no target, or no layer composite shader) has its composite
	/// skipped.
	public void RenderLayers(ICommandEncoder encoder, int32 frameIndex, VGRenderSlice slice)
	{
		mLastLayerStats = .();
		if (!slice.IsValid || (slice.LayerCount == 0) || (mLayerPipeline == null))
			return;

		// A parent draws its children's composites, so the deepest layers go first.
		let order = scope List<int32>(slice.LayerCount);
		for (int32 l = slice.LayerStart; l < slice.LayerStart + slice.LayerCount; l++)
			order.Add(l);
		for (int i = 1; i < order.Count; i++)
		{
			for (int j = i; (j > 0) && (mLayers[order[j - 1]].Depth < mLayers[order[j]].Depth); j--)
				Swap!(order[j - 1], order[j]);
		}
		for (let l in order)
		{
			var layer = ref mLayers[l];
			if (!layer.Valid)
				continue;
			let targetIndex = AcquireLayerTarget(frameIndex, layer.TargetWidth, layer.TargetHeight, false);
			if (targetIndex < 0)
				continue;
			let target = mLayerTargets[targetIndex];

			encoder.TransitionTexture(target.Color, .Undefined, .RenderTarget);
			if (target.Msaa != null)
				encoder.TransitionTexture(target.Msaa, .Undefined, .RenderTarget);
			if (target.DepthStencil != null)
				encoder.TransitionTexture(target.DepthStencil, .Undefined, .DepthStencilWrite);

			var color = ColorAttachment();
			color.View = (target.MsaaView != null) ? target.MsaaView : target.ColorView;
			color.ResolveTarget = (target.MsaaView != null) ? target.ColorView : null;
			color.LoadOp = .Clear;
			color.StoreOp = (target.MsaaView != null) ? .DontCare : .Store;
			color.ClearValue = .(0.0f, 0.0f, 0.0f, 0.0f);
			var desc = RenderPassDesc();
			desc.ColorAttachments.Add(color);
			if (target.DepthStencilView != null)
			{
				var depthStencil = DepthStencilAttachment();
				depthStencil.View = target.DepthStencilView;
				depthStencil.DepthLoadOp = .Clear;
				depthStencil.DepthStoreOp = .DontCare;
				depthStencil.StencilLoadOp = .Clear;
				depthStencil.StencilStoreOp = .DontCare;
				depthStencil.StencilClearValue = 0;
				desc.DepthStencilAttachment = depthStencil;
			}
			desc.Label = "VG layer";

			let pass = encoder.BeginRenderPass(desc);
			if (pass == null)
				continue;
			DrawCommands(pass, frameIndex, slice, l, 0, 0, layer.Width, layer.Height, layer.UniformOffset,
				layer.Bounds.X, layer.Bounds.Y, ref mLastLayerStats);
			pass.End();
			encoder.TransitionTexture(target.Color, .RenderTarget, .ShaderRead);
			if (layer.Blur > 0.0f)
				BlurLayer(encoder, frameIndex, layer, targetIndex, targetIndex);
			if (layer.BackdropBlur > 0.0f)
			{
				// A blurred copy for the backdrop shapes; the layer itself stays sharp.
				let copy = AcquireLayerTarget(frameIndex, layer.TargetWidth, layer.TargetHeight, true);
				if ((copy >= 0) && BlurLayer(encoder, frameIndex, layer, targetIndex, copy))
					layer.BackdropTarget = copy;
			}
			layer.Target = targetIndex;
			mLastLayerStats.Layers++;
		}
	}

	/// Dispatches the slice's commands that draw into `layer` (-1: the pass's own target) into
	/// the active pass: content coordinates offset by the origin (a layer's bounds) map to the
	/// viewport, through the projection at `uniformOffset`.
	private void DrawCommands(IRenderPassEncoder renderPass, int32 frameIndex, VGRenderSlice slice,
		int32 layer, int32 viewportX, int32 viewportY, uint32 width, uint32 height, uint32 uniformOffset,
		float originX, float originY, ref VGRenderStats stats)
	{
		renderPass.SetViewport((float)viewportX, (float)viewportY, (float)width, (float)height,
			0.0f, 1.0f);
		renderPass.SetPipeline(mPipeline);
		renderPass.SetVertexBuffer(0, mVertexBuffers[frameIndex], slice.VertexByteOffset);
		renderPass.SetIndexBuffer(mIndexBuffers[frameIndex], .UInt32, slice.IndexByteOffset);

		let dynamicOffsets = scope uint32[1](uniformOffset);
		// A sentinel below every valid index, so the first command always binds.
		var currentTextureIndex = -2;
		var currentSpread = VGGradientSpread.Pad;
		var currentPipeline = mPipeline;
		var currentStencilRef = -1;
		// The vertex buffer sits at the slice's boxes.
		var boxesBound = false;

		if (mCoverPipeline != null)
		{
			renderPass.SetStencilReference(0);
			currentStencilRef = 0;
		}

		let commandEnd = slice.DrawCommandStart + slice.DrawCommandCount;
		for (int32 i = slice.DrawCommandStart; i < commandEnd; i++)
		{
			var command = mDrawCommands[i];
			if ((command.IndexCount == 0) || (command.Layer != layer))
				continue;

			// A layer's composite samples the target RenderLayers drew it into; none, no draw. A
			// Layer mode draw with no layer samples its own texture (a premultiplied image).
			IBindGroup compositeGroup = null;
			if ((command.DrawMode == .Layer) && (command.CompositeLayer >= 0))
			{
				let known = (command.CompositeLayer >= 0) && (command.CompositeLayer < mLayers.Count);
				let target = !known ? -1
					: (command.Backdrop ? mLayers[command.CompositeLayer].BackdropTarget : mLayers[command.CompositeLayer].Target);
				if ((target < 0) || (mLayerTargets[target].BindGroup == null))
				{
					stats.Skipped++;
					continue;
				}
				compositeGroup = mLayerTargets[target].BindGroup;
			}

			// A stencil phase command with no pipeline is SKIPPED entirely. A context
			// should not emit one without stencil support, but a stale batch must not draw
			// its winding fans as visible colour.
			let pipeline = PipelineFor(command);
			if (pipeline == null)
			{
				stats.Skipped++;
				continue;
			}

			if (pipeline != currentPipeline)
			{
				renderPass.SetPipeline(pipeline);
				currentPipeline = pipeline;
				// A pipeline swap invalidates the binding, so the next command rebinds.
				currentTextureIndex = -2;
			}

			if ((mCoverPipeline != null) || (mClipApplyPipeline != null))
			{
				// The clip bit whenever the mask is involved: a clipped draw tests against
				// it, and the apply replaces with it. Zero otherwise, which is what an
				// unclipped cover compares against and what the clear replaces with.
				let wantsClipRef = (command.ClipMode == .Stencil)
					|| (command.FillPhase == .ClipApply);
				let wantedRef = wantsClipRef ? (int32)cClipBit : 0;
				if (wantedRef != currentStencilRef)
				{
					renderPass.SetStencilReference((uint32)wantedRef);
					currentStencilRef = wantedRef;
				}
			}

			if (compositeGroup != null)
			{
				renderPass.SetBindGroup(0, compositeGroup, dynamicOffsets);
				// The next texture draw binds its own again.
				currentTextureIndex = -2;
			}
			else if ((command.TextureIndex != currentTextureIndex) || (command.GradientSpread != currentSpread))
			{
				if (let bindGroup = GetBindGroupForTexture(command.TextureIndex, frameIndex,
					command.GradientSpread))
					renderPass.SetBindGroup(0, bindGroup, dynamicOffsets);
				currentTextureIndex = command.TextureIndex;
				currentSpread = command.GradientSpread;
			}

			// A layer's clips are in canvas coordinates; its target starts at its bounds.
			command.ClipRect.X -= originX;
			command.ClipRect.Y -= originY;
			ApplyScissor(renderPass, command, viewportX, viewportY, width, height);
			// Analytic boxes draw unindexed from their own part of the vertex buffer.
			let isBox = command.DrawMode == .Box;
			if (isBox != boxesBound)
			{
				renderPass.SetVertexBuffer(0, mVertexBuffers[frameIndex],
					isBox ? slice.BoxVertexByteOffset : slice.VertexByteOffset);
				boxesBound = isBox;
			}
			if (isBox)
				renderPass.Draw((uint32)command.IndexCount, 1, (uint32)command.StartIndex, 0);
			else
				renderPass.DrawIndexed((uint32)command.IndexCount, 1, (uint32)command.StartIndex, 0, 0);
			stats.Drawn++;
		}
	}

	/// What the LAST Render did with its commands. Observable headlessly, so the dispatch
	/// decisions can be checked on the null backend without a pixel probe.
	public VGRenderStats LastRenderStats => mLastRenderStats;
	/// What the last RenderLayers did: the layers it drew and their commands.
	public VGRenderStats LastLayerStats => mLastLayerStats;

	private static void ApplyScissor(IRenderPassEncoder renderPass, VGCommand command,
		int32 viewportX, int32 viewportY, uint32 width, uint32 height)
	{
		// Scissored: a rectangle clip alone, or one inside a path clip (with the stencil).
		let scissored = (command.ClipMode == .Scissor) || ((command.ClipMode == .Stencil) && command.Scissored);
		if (!scissored)
		{
			// Back to the whole viewport: a previous command may have narrowed it, and the
			// scissor is pass state rather than per draw.
			renderPass.SetScissor(viewportX, viewportY, width, height);
			return;
		}

		if ((command.ClipRect.Width <= 0.0f) || (command.ClipRect.Height <= 0.0f))
		{
			// A degenerate clip hides everything, which is what it asked for.
			renderPass.SetScissor(0, 0, 0, 0);
			return;
		}

		let scissor = ComputeScissor(command.ClipRect, viewportX, viewportY, width, height);
		renderPass.SetScissor(scissor.X, scissor.Y, scissor.Width, scissor.Height);
	}

	// === the texture cache ===

	/// Registers a CALLER OWNED view under an image identity, so drawing that image samples
	/// the given GPU texture rather than uploading pixels.
	///
	/// The view is not owned: the caller must unregister before destroying it.
	/// Re registering an existing key rebinds it, tearing the bind groups down to be
	/// rebuilt lazily.
	public void RegisterExternalTexture(ImageData key, ITextureView view)
	{
		if ((key == null) || (view == null) || (mDevice == null))
			return;

		for (let cached in mTextureCache)
		{
			if (cached.Source != key)
				continue;

			for (int i = 0; i < cached.BindGroups.Count; i++)
			{
				if (cached.BindGroups[i] != null)
				{
					var group = cached.BindGroups[i];
					mDevice.DestroyBindGroup(ref group);
				}
				cached.BindGroups[i] = null;
			}

			cached.View = view;
			cached.External = true;
			cached.GpuTexture = null;
			// An explicit re-register REFRESHES the identity, which is how a caller says
			// the key now means something new.
			cached.SourceId = key.InstanceId;
			return;
		}

		let cached = new CachedTexture();
		cached.Source = key;
		cached.SourceId = key.InstanceId;
		cached.View = view;
		cached.External = true;
		cached.BindGroups.Resize(mFrameCount * cSpreadCount);
		mTextureCache.Add(cached);
	}

	/// Drops a registered external view, tearing down its bind groups but never the
	/// caller's own view or texture. Safe for an unknown key.
	public void UnregisterExternalTexture(ImageData key)
	{
		if (key == null)
			return;

		for (int i = 0; i < mTextureCache.Count; i++)
		{
			if (mTextureCache[i].Source != key)
				continue;

			DisposeCachedTexture(mTextureCache[i]);
			delete mTextureCache[i];
			mTextureCache.RemoveAt(i);
			return;
		}
	}

	public bool IsExternalTextureRegistered(ImageData key)
	{
		if (key == null)
			return false;

		for (let cached in mTextureCache)
		{
			if (cached.Source == key)
				return cached.External;
		}
		return false;
	}

	/// Drops the entry for a key, which is an IDENTITY and is never dereferenced.
	///
	/// The GPU resources move to the retired list and are freed once every in flight frame
	/// has aged past them. An external entry is untouched: its owner invalidates it.
	public void EvictCachedTexture(ImageData key)
	{
		if (key == null)
			return;

		for (int i = 0; i < mTextureCache.Count; i++)
		{
			if ((mTextureCache[i].Source != key) || mTextureCache[i].External)
				continue;

			mRetiredTextures.Add((mTextureCache[i], mFrameCount));
			mTextureCache.RemoveAt(i);
			return;
		}
	}

	public void ClearTextureCache()
	{
		for (let cached in mTextureCache)
		{
			DisposeCachedTexture(cached);
			delete cached;
		}
		mTextureCache.Clear();

		for (let retired in mRetiredTextures)
		{
			DisposeCachedTexture(retired.Entry);
			delete retired.Entry;
		}
		mRetiredTextures.Clear();
	}

	private CachedTexture GetOrCreateCachedTexture(ImageData texture)
	{
		if (texture == null)
			return null;

		for (int i = 0; i < mTextureCache.Count; i++)
		{
			if (mTextureCache[i].Source != texture)
				continue;

			if (mTextureCache[i].SourceId == texture.InstanceId)
				return mTextureCache[i];

			// The same address with a DIFFERENT instance: the cached image was deleted and
			// the allocator reused its address. Without the id check this would serve the
			// dead image's texture.
			if (mTextureCache[i].External)
				return null; // Its owner must re-register.

			mRetiredTextures.Add((mTextureCache[i], mFrameCount));
			mTextureCache.RemoveAt(i);
			break;
		}

		let pixels = texture.PixelData;
		if (pixels.IsEmpty)
			return null;

		let width = texture.Width;
		let height = texture.Height;
		let format = TextureFormatUtils.Convert(texture.Format, texture.ColorSpace);

		var textureDesc = TextureDesc();
		textureDesc.Dimension = .Texture2D;
		textureDesc.Format = format;
		textureDesc.Width = width;
		textureDesc.Height = height;
		textureDesc.Depth = 1;
		textureDesc.Usage = .Sampled | .CopyDst;
		textureDesc.Label = "VG cached texture";

		if (!(mDevice.CreateTexture(textureDesc) case .Ok(let gpuTexture)))
			return null;

		if (mQueue != null)
		{
			if (mQueue.CreateTransferBatch() case .Ok(var batch))
			{
				var layout = TextureDataLayout();
				layout.BytesPerRow = width * PixelFormats.BytesPerPixel(texture.Format);
				layout.RowsPerImage = height;
				batch.WriteTexture(gpuTexture, pixels, layout, .(width, height, 1));
				batch.Submit().IgnoreError();
				mQueue.DestroyTransferBatch(ref batch);
			}
		}

		var viewDesc = TextureViewDesc();
		viewDesc.Format = format;
		if (!(mDevice.CreateTextureView(gpuTexture, viewDesc) case .Ok(let view)))
		{
			var doomed = gpuTexture;
			mDevice.DestroyTexture(ref doomed);
			return null;
		}

		let cached = new CachedTexture();
		cached.Source = texture;
		cached.SourceId = texture.InstanceId;
		cached.GpuTexture = gpuTexture;
		cached.View = view;
		cached.BindGroups.Resize(mFrameCount * cSpreadCount);
		mTextureCache.Add(cached);
		return cached;
	}

	private void UpdateTextureBindGroup(int32 textureIndex, int32 frameIndex,
		VGGradientSpread spread)
	{
		if (textureIndex >= (int32)mBatchTextures.Count)
			return;

		let texture = mBatchTextures[textureIndex];
		if (texture == null)
			return;

		let cached = GetOrCreateCachedTexture(texture);
		if ((cached == null) || (cached.View == null))
			return;

		let slot = (frameIndex * cSpreadCount) + (int)spread;
		if (cached.BindGroups[slot] != null)
			return;

		let entries = scope BindGroupEntry[3](
			BindGroupEntry.BufferEntry(mUniformBuffers[frameIndex], 0, sizeof(VGUniforms)),
			BindGroupEntry.TextureEntry(cached.View),
			BindGroupEntry.SamplerEntry(SamplerForSpread(spread)));

		var desc = BindGroupDesc();
		desc.Layout = mBindGroupLayout;
		desc.Entries = entries;

		if (mDevice.CreateBindGroup(desc) case .Ok(let group))
			cached.BindGroups[slot] = group;
	}

	private IBindGroup GetBindGroupForTexture(int32 textureIndex, int32 frameIndex,
		VGGradientSpread spread)
	{
		if (mBatchTextures.IsEmpty)
			return null;

		// A solid draw names no texture and samples the white one at index zero.
		int32 effectiveIndex = (textureIndex < 0) ? 0 : textureIndex;
		if (effectiveIndex >= (int32)mBatchTextures.Count)
			return null;

		let texture = mBatchTextures[effectiveIndex];
		if (texture == null)
			return null;

		// The padded groups were built during Prepare; the rarer repeat and mirror ones
		// build on first use, which is a device call and legal while the pass records.
		UpdateTextureBindGroup(effectiveIndex, frameIndex, spread);

		let slot = (frameIndex * cSpreadCount) + (int)spread;
		for (let cached in mTextureCache)
		{
			if (cached.Source == texture)
				return cached.BindGroups[slot];
		}
		return null;
	}

	private void DisposeCachedTexture(CachedTexture cached)
	{
		for (int i = 0; i < cached.BindGroups.Count; i++)
		{
			if (cached.BindGroups[i] == null)
				continue;
			var group = cached.BindGroups[i];
			mDevice.DestroyBindGroup(ref group);
			cached.BindGroups[i] = null;
		}

		// The view and the texture belong to the caller.
		if (cached.External)
			return;

		if (cached.View != null)
		{
			var view = cached.View;
			mDevice.DestroyTextureView(ref view);
			cached.View = null;
		}
		if (cached.GpuTexture != null)
		{
			var texture = cached.GpuTexture;
			mDevice.DestroyTexture(ref texture);
			cached.GpuTexture = null;
		}
	}

	// === pipelines ===

	/// The pipeline a command draws with, or null when it needs one that was never built.
	private IRenderPipeline PipelineFor(VGCommand command)
	{
		let blended = command.BlendMode != .Normal;
		let clipped = command.ClipMode == .Stencil;

		switch (command.FillPhase)
		{
		case .ClipApply:
			// Null means the stencil families were never configured, and the caller skips
			// the command.
			return mClipApplyPipeline;

		case .ClipClear:
			return mClipClearPipeline;

		case .StencilWrite:
			// Colour masked, so the BLEND is irrelevant. The clip is not: a clipped fill
			// must only accumulate winding inside the mask.
			if (clipped)
			{
				return (command.FillRule == .EvenOdd)
					? ClippedWrite(.WriteEvenOdd, ref mClippedWriteEvenOdd)
					: ClippedWrite(.WriteNonZero, ref mClippedWriteNonZero);
			}
			return (command.FillRule == .EvenOdd) ? mStencilWriteEvenOdd : mStencilWriteNonZero;

		case .StencilCover:
			if (mCoverPipeline == null)
				return null;

			if ((command.DrawMode == .GradientRadial) && (mCoverGradRadialPipeline != null))
			{
				return (blended || clipped) ? Variant(.CoverRadial, command.BlendMode, clipped)
					: mCoverGradRadialPipeline;
			}
			if ((command.DrawMode == .GradientConic) && (mCoverGradConicPipeline != null))
			{
				return (blended || clipped) ? Variant(.CoverConic, command.BlendMode, clipped)
					: mCoverGradConicPipeline;
			}
			return (blended || clipped) ? Variant(.Cover, command.BlendMode, clipped)
				: mCoverPipeline;

		case .Direct:
		}

		if (command.DrawMode == .Box)
		{
			// Box vertices are not VG vertices: no other pipeline can read them. SKIP when the
			// box shaders were not given (a context draws boxes analytically only when told).
			if (mBoxPipeline == null)
				return null;
			return (blended || clipped) ? Variant(.Box, command.BlendMode, clipped) : mBoxPipeline;
		}
		if (command.DrawMode == .Layer)
		{
			// A layer target holds premultiplied colour; the default shader would multiply it
			// again. SKIP when the composite shader was not given.
			if (mLayerPipeline == null)
				return null;
			return (blended || clipped) ? Variant(.Layer, command.BlendMode, clipped) : mLayerPipeline;
		}
		if ((command.DrawMode == .DistanceField) && (mDistanceFieldPipeline != null))
		{
			return (blended || clipped) ? Variant(.DistanceField, command.BlendMode, clipped)
				: mDistanceFieldPipeline;
		}
		if ((command.DrawMode == .GradientRadial) && (mGradRadialPipeline != null))
		{
			return (blended || clipped) ? Variant(.GradRadial, command.BlendMode, clipped)
				: mGradRadialPipeline;
		}
		if ((command.DrawMode == .GradientConic) && (mGradConicPipeline != null))
		{
			return (blended || clipped) ? Variant(.GradConic, command.BlendMode, clipped)
				: mGradConicPipeline;
		}
		if (command.DrawMode == .BoxShadow)
		{
			// No substitute exists: the default shader would paint the quadrant quads as flat
			// colour over everything around the box, so SKIP when the shader was not given.
			if (mBoxShadowPipeline == null)
				return null;
			return (blended || clipped) ? Variant(.BoxShadow, command.BlendMode, clipped)
				: mBoxShadowPipeline;
		}

		return (blended || clipped) ? Variant(.Default, command.BlendMode, clipped) : mPipeline;
	}

	/// The pipeline for a combination, built on FIRST USE.
	///
	/// Most content never leaves normal and unclipped, so these tables usually stay empty.
	///
	/// A failed BLEND variant falls back to the normal pipeline, because a draw with the
	/// wrong blend beats no draw. A failed CLIPPED one returns null instead: drawing
	/// unclipped would paint outside the clip, which is worse than not drawing.
	private IRenderPipeline Variant(PipelineKind kind, VGBlendMode blendMode, bool clipped)
	{
		let kindIndex = (int)kind;
		let existing = clipped ? mClippedPipelines[(int)blendMode][kindIndex]
			: mBlendPipelines[(int)blendMode - 1][kindIndex];
		if (existing != null)
			return existing;

		IShaderModule fragment = null;
		var role = StencilRole.None;

		switch (kind)
		{
		case .Default: fragment = mFragmentModule;
		case .DistanceField: fragment = mDistanceFieldModule;
		case .GradRadial: fragment = mGradRadialModule;
		case .GradConic: fragment = mGradConicModule;
		case .Cover:
			fragment = mFragmentModule;
			role = .Cover;
		case .CoverRadial:
			fragment = mGradRadialModule;
			role = .Cover;
		case .CoverConic:
			fragment = mGradConicModule;
			role = .Cover;
		case .BoxShadow: fragment = mBoxShadowModule;
		case .Box: fragment = mBoxFragmentModule;
		case .Layer: fragment = mLayerFragmentModule;
		}

		let isBox = kind == .Box;
		let vertex = isBox ? mBoxVertexModule : mVertexModule;
		let cannotBuild = (vertex == null) || (fragment == null)
			|| (clipped && (mTargetConfig.DepthStencilFormat == .Undefined));

		IRenderPipeline built = null;
		if (!cannotBuild)
		{
			if (!(CreatePipeline(vertex, fragment, role, blendMode, clipped, isBox)
				case .Ok(out built)))
				built = null;
		}

		if (clipped)
			mClippedPipelines[(int)blendMode][kindIndex] = built;
		else
			mBlendPipelines[(int)blendMode - 1][kindIndex] = built;

		if (built != null)
			return built;

		// The default pipeline is a tolerable stand in for a distance field or gradient
		// variant, which degrade to flat colour, but NEVER for a box shadow (it would paint the
		// quadrant quads as flat colour over everything around the box), a box (its vertices are
		// not VG vertices), nor a layer composite (it would multiply premultiplied colour again).
		// Skip instead.
		return (clipped || (kind == .BoxShadow) || isBox || (kind == .Layer)) ? null : mPipeline;
	}

	/// The clipped write pair, built lazily because it needs a stencil attachment.
	private IRenderPipeline ClippedWrite(StencilRole role, ref IRenderPipeline slot)
	{
		if (slot != null)
			return slot;

		if ((mVertexModule == null) || (mFragmentModule == null)
			|| (mTargetConfig.DepthStencilFormat == .Undefined))
			return null;

		if (CreatePipeline(mVertexModule, mFragmentModule, role, .Normal, true) case .Ok(let built))
		{
			slot = built;
			return slot;
		}

		// Skip the command rather than corrupt the mask.
		return null;
	}

	private Result<IRenderPipeline> CreatePipeline(IShaderModule vertexShader,
		IShaderModule fragmentShader, StencilRole role, VGBlendMode blendMode = .Normal,
		bool clipped = false, bool isBox = false)
	{
		let attributes = scope VertexAttribute[5](
			.(.Float32x2, 0, 0),
			.(.Float32x2, 8, 1),
			.(.Float32x4, 16, 2),
			.(.Float32, 32, 3),
			.(.Float32x2, 36, 4)); // effect: distance-field text effects
		// An analytic box's vertex (VGBoxVertex).
		let boxAttributes = scope VertexAttribute[10](
			.(.Float32x2, 0, 0), // position
			.(.Float32x2, 8, 1), // local
			.(.Float32x2, 16, 2), // half size
			.(.Float32x4, 24, 3), // radii
			.(.Float32x4, 40, 4), // borders
			.(.Float32x4, 56, 5), // fill
			.(.Float32x4, 72, 6), // border top
			.(.Float32x4, 88, 7), // border right
			.(.Float32x4, 104, 8), // border bottom
			.(.Float32x4, 120, 9)); // border left

		var vertexLayout = VertexBufferLayout();
		vertexLayout.Stride = isBox ? (uint32)VGBoxVertex.SizeInBytes : (uint32)VGRenderVertex.SizeInBytes;
		vertexLayout.Attributes = isBox ? boxAttributes : attributes;
		let vertexBuffers = scope VertexBufferLayout[1](vertexLayout);

		var colorTarget = ColorTargetState();
		colorTarget.Format = mTargetFormat;
		colorTarget.Blend = BlendFor(blendMode);

		// A colour masked pass writes only the stencil.
		if (IsColorMasked(role))
			colorTarget.WriteMask = .None;

		let colorTargets = scope ColorTargetState[1](colorTarget);

		var desc = RenderPipelineDesc();
		desc.Layout = mPipelineLayout;
		desc.Vertex.Shader = .(vertexShader, Sedulous.RHI.ShaderStage.Vertex);
		desc.Vertex.Buffers = vertexBuffers;

		var fragment = FragmentState();
		fragment.Shader = .(fragmentShader, Sedulous.RHI.ShaderStage.Fragment);
		fragment.Targets = colorTargets;
		desc.Fragment = fragment;

		desc.Primitive.Topology = .TriangleList;
		desc.Primitive.FrontFace = .CCW;
		// NO culling: the winding pass needs both faces, because that is how the front and
		// back operations produce a signed count.
		desc.Primitive.CullMode = .None;
		desc.Multisample.Count = mTargetConfig.SampleCount;
		desc.Multisample.AlphaToCoverageEnabled = false;

		// Every pipeline must declare the pass's attachment when the host provides one, for
		// compatibility, with depth fully disabled: vector graphics never touch depth.
		if (mTargetConfig.DepthStencilFormat != .Undefined)
			desc.DepthStencil = DepthStencilFor(role, clipped);

		if (mDevice.CreateRenderPipeline(desc) case .Ok(let pipeline))
			return .Ok(pipeline);
		return .Err;
	}

	private static bool IsColorMasked(StencilRole role)
		=> (role == .WriteNonZero) || (role == .WriteEvenOdd) || (role == .ClipApply)
			|| (role == .ClipClear);

	/// The blend state for a mode.
	///
	/// PREMULTIPLIED throughout: both fragment shaders output premultiplied colour. That
	/// removes the dark halo straight alpha leaves on an antialiased edge, and the double
	/// blend seam where a fringe overlaps a join. The other modes are the premultiplied
	/// formulations, alpha aware so a fill's transparent surround leaves the destination
	/// alone.
	private static BlendState? BlendFor(VGBlendMode mode)
	{
		switch (mode)
		{
		case .Additive:
			return BlendState.Additive;
		case .Multiply:
			return BlendState(.(.Dst, .OneMinusSrcAlpha, .Add), .(.One, .OneMinusSrcAlpha, .Add));
		case .Screen:
			return BlendState(.(.One, .OneMinusSrc, .Add), .(.One, .OneMinusSrcAlpha, .Add));
		case .Normal:
			return BlendState.PremultipliedAlpha;
		}
	}

	/// The stencil state for a role.
	private DepthStencilState DepthStencilFor(StencilRole role, bool clipped)
	{
		var state = DepthStencilState();
		state.Format = mTargetConfig.DepthStencilFormat;
		state.DepthTestEnabled = false;
		state.DepthWriteEnabled = false;
		state.DepthCompare = .Always;

		switch (role)
		{
		case .WriteNonZero:
			// The winding accumulates in the LOW bits only, so the clip mask survives.
			// Clipped, it accumulates only where the clip bit is set.
			state.StencilEnabled = true;
			state.StencilWriteMask = cWindingMask;
			state.StencilReadMask = cClipBit;
			state.StencilFront = .() {
				Compare = clipped ? .Equal : .Always,
				FailOp = .Keep, DepthFailOp = .Keep, PassOp = .IncrementWrap
			};
			state.StencilBack = .() {
				Compare = clipped ? .Equal : .Always,
				FailOp = .Keep, DepthFailOp = .Keep, PassOp = .DecrementWrap
			};

		case .WriteEvenOdd:
			// Invert flips the winding bits only, which is parity rather than a count.
			state.StencilEnabled = true;
			state.StencilWriteMask = cWindingMask;
			state.StencilReadMask = cClipBit;
			state.StencilFront = .() {
				Compare = clipped ? .Equal : .Always,
				FailOp = .Keep, DepthFailOp = .Keep, PassOp = .Invert
			};
			state.StencilBack = state.StencilFront;

		case .Cover:
			state.StencilEnabled = true;
			if (clipped)
			{
				// Inside means the clip bit set AND the winding non zero, which under a
				// full read mask is any value other than the clip bit alone. Replacing
				// with the clip reference zeroes the winding and RESTORES the mask in one
				// operation.
				state.StencilReadMask = 0xFF;
				state.StencilWriteMask = 0xFF;
				state.StencilFront = .() {
					Compare = .NotEqual, FailOp = .Keep, DepthFailOp = .Keep, PassOp = .Replace
				};
			}
			else
			{
				// Inside means the winding is non zero. Both the read and the zeroing write
				// stay in the winding bits, so the clip mask is ignored and preserved.
				//
				// Invert only ever yields all zeroes or all ones, so this one comparison
				// serves BOTH fill rules and the cover needs no per rule variant.
				state.StencilReadMask = cWindingMask;
				state.StencilWriteMask = cWindingMask;
				state.StencilFront = .() {
					Compare = .NotEqual, FailOp = .Zero, DepthFailOp = .Zero, PassOp = .Zero
				};
			}
			state.StencilBack = state.StencilFront;

		case .ClipApply:
			// The comparison is against the winding bits, where the clip reference reads as
			// zero, so this passes wherever the winding is non zero. Replacing with that
			// reference sets the mask and clears the winding at once; failing zeroes any
			// stray bits.
			state.StencilEnabled = true;
			state.StencilReadMask = cWindingMask;
			state.StencilWriteMask = 0xFF;
			state.StencilFront = .() {
				Compare = .NotEqual, FailOp = .Zero, DepthFailOp = .Zero, PassOp = .Replace
			};
			state.StencilBack = state.StencilFront;

		case .ClipClear:
			state.StencilEnabled = true;
			state.StencilReadMask = 0xFF;
			state.StencilWriteMask = 0xFF;
			state.StencilFront = .() {
				Compare = .Always, FailOp = .Keep, DepthFailOp = .Keep, PassOp = .Replace
			};
			state.StencilBack = state.StencilFront;

		case .None:
			if (clipped)
			{
				// An ordinary colour draw confined to the mask: a READ ONLY test, so the
				// draw cannot disturb the mask it is testing against.
				state.StencilEnabled = true;
				state.StencilReadMask = cClipBit;
				state.StencilWriteMask = 0;
				state.StencilFront = .() {
					Compare = .Equal, FailOp = .Keep, DepthFailOp = .Keep, PassOp = .Keep
				};
				state.StencilBack = state.StencilFront;
			}
		}

		return state;
	}

	// === device resources ===

	private Result<void, ErrorCode> CreateSamplers()
	{
		var desc = SamplerDesc();
		desc.AddressU = .ClampToEdge;
		desc.AddressV = .ClampToEdge;
		desc.AddressW = .ClampToEdge;
		if (!(mDevice.CreateSampler(desc) case .Ok(out mSampler)))
			return .Err(.Unknown);

		// The spread samplers: a gradient ramp wraps or mirrors, so the shader's raw
		// parameter tiles per pixel rather than being clamped per vertex.
		desc.AddressU = .Repeat;
		desc.AddressV = .Repeat;
		desc.AddressW = .Repeat;
		if (!(mDevice.CreateSampler(desc) case .Ok(out mSamplerRepeat)))
			return .Err(.Unknown);

		desc.AddressU = .MirrorRepeat;
		desc.AddressV = .MirrorRepeat;
		desc.AddressW = .MirrorRepeat;
		if (!(mDevice.CreateSampler(desc) case .Ok(out mSamplerMirror)))
			return .Err(.Unknown);

		return .Ok;
	}

	private ISampler SamplerForSpread(VGGradientSpread spread)
	{
		switch (spread)
		{
		case .Repeat: return mSamplerRepeat;
		case .Reflect: return mSamplerMirror;
		case .Pad: return mSampler;
		}
	}

	private Result<void, ErrorCode> CreateLayouts()
	{
		let entries = scope BindGroupLayoutEntry[3](
			BindGroupLayoutEntry.UniformBuffer(0, .Vertex | .Fragment),
			BindGroupLayoutEntry.SampledTexture(0, .Fragment),
			BindGroupLayoutEntry.Sampler(0, .Fragment));

		// ONE uniform buffer shared across slices, addressed by a dynamic offset. Without
		// this every surface would need its own buffer and its own bind group.
		entries[0].HasDynamicOffset = true;

		var layoutDesc = BindGroupLayoutDesc();
		layoutDesc.Entries = entries;
		if (!(mDevice.CreateBindGroupLayout(layoutDesc) case .Ok(out mBindGroupLayout)))
			return .Err(.Unknown);

		let layouts = scope IBindGroupLayout[1](mBindGroupLayout);
		var pipelineDesc = PipelineLayoutDesc();
		pipelineDesc.BindGroupLayouts = layouts;
		if (!(mDevice.CreatePipelineLayout(pipelineDesc) case .Ok(out mPipelineLayout)))
			return .Err(.Unknown);

		return .Ok;
	}

	private Result<void, ErrorCode> CreatePerFrameResources()
	{
		mVertexBuffers.Resize(mFrameCount);
		mIndexBuffers.Resize(mFrameCount);
		mUniformBuffers.Resize(mFrameCount);
		mFrameVertexCapacity.Resize(mFrameCount);

		for (int32 i = 0; i < mFrameCount; i++)
		{
			if (!(CreateGeometryBuffers(let vertexBuffer, let indexBuffer) case .Ok))
				return .Err(.Unknown);

			mVertexBuffers[i] = vertexBuffer;
			mIndexBuffers[i] = indexBuffer;
			mFrameVertexCapacity[i] = mTargetVertexCapacity;

			var uniformDesc = BufferDesc();
			uniformDesc.Size = (uint64)cMaxUniformSlots * cUniformSlotSize;
			uniformDesc.Usage = .Uniform;
			uniformDesc.Memory = .CpuToGpu;
			if (!(mDevice.CreateBuffer(uniformDesc) case .Ok(let uniformBuffer)))
				return .Err(.Unknown);
			mUniformBuffers[i] = uniformBuffer;
		}

		return .Ok;
	}

	private Result<void> CreateGeometryBuffers(out IBuffer outVertexBuffer, out IBuffer outIndexBuffer)
	{
		outVertexBuffer = null;
		outIndexBuffer = null;

		var vertexDesc = BufferDesc();
		vertexDesc.Size = (uint64)mTargetVertexCapacity * (uint64)VGRenderVertex.SizeInBytes;
		vertexDesc.Usage = .Vertex;
		vertexDesc.Memory = .CpuToGpu;
		if (!(mDevice.CreateBuffer(vertexDesc) case .Ok(let vertexBuffer)))
			return .Err;

		var indexDesc = BufferDesc();
		indexDesc.Size = (uint64)mTargetVertexCapacity * 3 * (uint64)sizeof(uint32);
		indexDesc.Usage = .Index;
		indexDesc.Memory = .CpuToGpu;
		if (!(mDevice.CreateBuffer(indexDesc) case .Ok(let indexBuffer)))
		{
			var doomed = vertexBuffer;
			mDevice.DestroyBuffer(ref doomed);
			return .Err;
		}

		outVertexBuffer = vertexBuffer;
		outIndexBuffer = indexBuffer;
		return .Ok;
	}

	/// Recreates one frame slot's geometry buffers at the current target capacity.
	///
	/// Called from BeginFrame, where the slot's previous submission has been awaited. The
	/// buffers are bound directly rather than through a bind group, so there are no
	/// descriptors to fix up.
	private void GrowFrameBuffers(int32 frameIndex)
	{
		if (mFrameVertexCapacity[frameIndex] >= mTargetVertexCapacity)
			return;

		if (!(CreateGeometryBuffers(let vertexBuffer, let indexBuffer) case .Ok))
			return;

		if (mVertexBuffers[frameIndex] != null)
		{
			var doomed = mVertexBuffers[frameIndex];
			mDevice.DestroyBuffer(ref doomed);
		}
		if (mIndexBuffers[frameIndex] != null)
		{
			var doomed = mIndexBuffers[frameIndex];
			mDevice.DestroyBuffer(ref doomed);
		}

		mVertexBuffers[frameIndex] = vertexBuffer;
		mIndexBuffers[frameIndex] = indexBuffer;
		mFrameVertexCapacity[frameIndex] = mTargetVertexCapacity;
	}

	private static void WriteBuffer(IBuffer buffer, uint64 offset, void* data, uint32 size)
	{
		if ((buffer == null) || (size == 0))
			return;

		let mapped = buffer.Map();
		if (mapped == null)
			return;

		Internal.MemCpy((uint8*)mapped + offset, data, (int)size);
		buffer.Unmap();
	}

	/// The projection of a layer: device content from (x, y) over width by height onto its target.
	private static Float4x4 OrthoOffCenter(float x, float y, float width, float height)
	{
		var m = OrthoOffCenter(width, height);
		m[3, 0] = -1.0f - (2.0f * x / width);
		m[3, 1] = 1.0f + (2.0f * y / height);
		return m;
	}

	private static uint32 RoundUpToBucket(uint32 size)
		=> (size + cLayerTargetBucket - 1) / cLayerTargetBucket * cLayerTargetBucket;

	/// Blurs a drawn layer's target into `intoIndex`, itself or a copy: across into a scratch
	/// target, then down, both single sampled since the content is resolved already. False, with
	/// nothing done, without a scratch target. Leaves both ends in ShaderRead.
	private bool BlurLayer(ICommandEncoder encoder, int32 frameIndex, PreparedLayer layer, int32 targetIndex,
		int32 intoIndex)
	{
		let scratchIndex = AcquireLayerTarget(frameIndex, layer.TargetWidth, layer.TargetHeight, true);
		if (scratchIndex < 0)
			return false;
		let target = mLayerTargets[targetIndex];
		let scratch = mLayerTargets[scratchIndex];
		let into = mLayerTargets[intoIndex];

		encoder.TransitionTexture(scratch.Color, .Undefined, .RenderTarget);
		BlurPass(encoder, layer, target, scratch, layer.BlurUniformOffset);
		encoder.TransitionTexture(scratch.Color, .RenderTarget, .ShaderRead);
		encoder.TransitionTexture(into.Color, (intoIndex == targetIndex) ? .ShaderRead : .Undefined, .RenderTarget);
		BlurPass(encoder, layer, scratch, into, layer.BlurUniformOffset + (uint32)cUniformSlotSize);
		encoder.TransitionTexture(into.Color, .RenderTarget, .ShaderRead);
		return true;
	}

	/// One axis of a layer's blur, `from` sampled into `into`.
	private void BlurPass(ICommandEncoder encoder, PreparedLayer layer, LayerTarget from, LayerTarget into,
		uint32 uniformOffset)
	{
		var color = ColorAttachment();
		color.View = into.ColorView;
		color.LoadOp = .Clear;
		color.StoreOp = .Store;
		color.ClearValue = .(0.0f, 0.0f, 0.0f, 0.0f);
		var desc = RenderPassDesc();
		desc.ColorAttachments.Add(color);
		desc.Label = "VG layer blur";
		let pass = encoder.BeginRenderPass(desc);
		if (pass == null)
			return;
		pass.SetViewport(0.0f, 0.0f, (float)layer.Width, (float)layer.Height, 0.0f, 1.0f);
		pass.SetScissor(0, 0, layer.Width, layer.Height);
		pass.SetPipeline(mBlurPipeline);
		let dynamicOffsets = scope uint32[1](uniformOffset);
		pass.SetBindGroup(0, from.BindGroup, dynamicOffsets);
		pass.Draw(3, 1, 0, 0);
		pass.End();
		mLastLayerStats.Drawn++;
	}

	/// The blur pipeline: no vertex buffer (one triangle from the vertex index), single sampled,
	/// no stencil, writing what it computes, since the target holds only the layer.
	private Result<IRenderPipeline> CreateBlurPipeline(IShaderModule vertexShader, IShaderModule fragmentShader)
	{
		var colorTarget = ColorTargetState();
		colorTarget.Format = mTargetFormat;
		let colorTargets = scope ColorTargetState[1](colorTarget);

		var desc = RenderPipelineDesc();
		desc.Layout = mPipelineLayout;
		desc.Vertex.Shader = .(vertexShader, Sedulous.RHI.ShaderStage.Vertex);
		var fragment = FragmentState();
		fragment.Shader = .(fragmentShader, Sedulous.RHI.ShaderStage.Fragment);
		fragment.Targets = colorTargets;
		desc.Fragment = fragment;
		desc.Primitive.Topology = .TriangleList;
		desc.Primitive.CullMode = .None;
		desc.Multisample.Count = 1;
		if (mDevice.CreateRenderPipeline(desc) case .Ok(let pipeline))
			return .Ok(pipeline);
		return .Err;
	}

	/// A free target of the size in the frame slot's pool, or a new one; -1 when the device
	/// cannot make it. `plain`: colour alone (a blur's scratch), else the renderer's sample count
	/// and stencil too.
	private int32 AcquireLayerTarget(int32 frameIndex, uint32 width, uint32 height, bool plain)
	{
		for (int i < mLayerTargets.Count)
		{
			let target = mLayerTargets[i];
			if ((target.Frame == frameIndex) && !target.InUse && (target.Width == width) && (target.Height == height)
				&& (target.Plain == plain))
			{
				target.InUse = true;
				return (int32)i;
			}
		}

		let target = new LayerTarget();
		target.Frame = frameIndex;
		target.Width = width;
		target.Height = height;
		target.InUse = true;
		target.Plain = plain;
		var made = (mDevice.CreateTexture(TextureDesc.RenderTarget(mTargetFormat, width, height, 1, "VG layer"))
			case .Ok(out target.Color))
			&& (mDevice.CreateTextureView(target.Color, .()) case .Ok(out target.ColorView));
		if (made && !plain && (mTargetConfig.SampleCount > 1))
		{
			var msaaDesc = TextureDesc.RenderTarget(mTargetFormat, width, height, mTargetConfig.SampleCount,
				"VG layer MSAA");
			msaaDesc.Usage = .RenderTarget;
			made = (mDevice.CreateTexture(msaaDesc) case .Ok(out target.Msaa))
				&& (mDevice.CreateTextureView(target.Msaa, .()) case .Ok(out target.MsaaView));
		}
		if (made && !plain && (mTargetConfig.DepthStencilFormat != .Undefined))
		{
			var depthDesc = TextureDesc();
			depthDesc.Dimension = .Texture2D;
			depthDesc.Format = mTargetConfig.DepthStencilFormat;
			depthDesc.Width = width;
			depthDesc.Height = height;
			depthDesc.Depth = 1;
			depthDesc.Usage = .DepthStencil;
			depthDesc.SampleCount = mTargetConfig.SampleCount;
			depthDesc.Label = "VG layer stencil";
			made = (mDevice.CreateTexture(depthDesc) case .Ok(out target.DepthStencil))
				&& (mDevice.CreateTextureView(target.DepthStencil, .()) case .Ok(out target.DepthStencilView));
		}
		if (made)
		{
			// The frame's uniforms, the target, and the clamp sampler.
			let entries = scope BindGroupEntry[3](
				BindGroupEntry.BufferEntry(mUniformBuffers[frameIndex], 0, sizeof(VGUniforms)),
				BindGroupEntry.TextureEntry(target.ColorView),
				BindGroupEntry.SamplerEntry(mSampler));
			var desc = BindGroupDesc();
			desc.Layout = mBindGroupLayout;
			desc.Entries = entries;
			made = mDevice.CreateBindGroup(desc) case .Ok(out target.BindGroup);
		}
		if (!made)
		{
			DisposeLayerTarget(target);
			delete target;
			return -1;
		}
		mLayerTargets.Add(target);
		return (int32)mLayerTargets.Count - 1;
	}

	/// The frame slot's work is done: its targets are free again, and those unused for a while
	/// are freed.
	private void ReleaseLayerTargets(int32 frameIndex)
	{
		for (int i = mLayerTargets.Count - 1; i >= 0; i--)
		{
			let target = mLayerTargets[i];
			if (target.Frame != frameIndex)
				continue;
			if (target.InUse)
			{
				target.InUse = false;
				target.IdleFrames = 0;
			}
			else if (++target.IdleFrames > cLayerTargetIdleFrames)
			{
				DisposeLayerTarget(target);
				delete target;
				mLayerTargets.RemoveAt(i);
			}
		}
	}

	private void DisposeLayerTarget(LayerTarget target)
	{
		if (target.BindGroup != null)
			mDevice.DestroyBindGroup(ref target.BindGroup);
		if (target.DepthStencilView != null)
			mDevice.DestroyTextureView(ref target.DepthStencilView);
		if (target.DepthStencil != null)
			mDevice.DestroyTexture(ref target.DepthStencil);
		if (target.MsaaView != null)
			mDevice.DestroyTextureView(ref target.MsaaView);
		if (target.Msaa != null)
			mDevice.DestroyTexture(ref target.Msaa);
		if (target.ColorView != null)
			mDevice.DestroyTextureView(ref target.ColorView);
		if (target.Color != null)
			mDevice.DestroyTexture(ref target.Color);
	}

	/// A layer as Prepare placed it: kept within its parent, with its projection's uniform slot.
	private struct PreparedLayer
	{
		public int32 Parent = -1;
		/// Device bounds, on whole pixels.
		public Rectangle Bounds = .();
		/// The content's size.
		public uint32 Width = 0;
		public uint32 Height = 0;
		/// The target's, bucketed.
		public uint32 TargetWidth = 0;
		public uint32 TargetHeight = 0;
		public uint32 UniformOffset = 0;
		/// The sigma, 0 for none or no blur pipeline.
		public float Blur = 0.0f;
		/// A blurred copy's sigma, for backdrop composites.
		public float BackdropBlur = 0.0f;
		/// Its two passes' slots, across then down.
		public uint32 BlurUniformOffset = 0;
		/// Ancestors: parents draw after their children.
		public int32 Depth = 0;
		/// Into mLayerTargets, set by RenderLayers.
		public int32 Target = -1;
		/// The blurred copy, set by RenderLayers.
		public int32 BackdropTarget = -1;
		public bool Valid = false;

		public this() {}
	}

	/// An offscreen target layers draw into, owned by one frame slot and reused once that slot's
	/// frame has finished on the GPU.
	private class LayerTarget
	{
		/// Single sampled, and what the composite samples.
		public ITexture Color;
		public ITextureView ColorView;
		/// When the renderer draws multisampled, resolved into Color.
		public ITexture Msaa;
		public ITextureView MsaaView;
		/// When the renderer's pipelines carry one.
		public ITexture DepthStencil;
		public ITextureView DepthStencilView;
		public IBindGroup BindGroup;
		public uint32 Width;
		public uint32 Height;
		public int32 Frame;
		public int32 IdleFrames;
		public bool InUse;
		/// Colour alone: a blur's scratch.
		public bool Plain;
	}

	/// An off centre orthographic projection with Y DOWN, which is what screen coordinates
	/// are: the origin is the top left corner and Y grows downward.
	private static Float4x4 OrthoOffCenter(float width, float height)
	{
		var m = Float4x4.Identity();
		m[0, 0] = 2.0f / width;
		m[1, 1] = -2.0f / height;
		m[2, 2] = -0.5f;
		m[3, 0] = -1.0f;
		m[3, 1] = 1.0f;
		m[3, 2] = 0.5f;
		return m;
	}

	public void Dispose()
	{
		if (mDevice == null)
			return;

		ClearTextureCache();
		for (let target in mLayerTargets)
			DisposeLayerTarget(target);
		ClearAndDeleteItems!(mLayerTargets);
		mLayers.Clear();

		DestroyBuffers(mUniformBuffers);
		DestroyBuffers(mIndexBuffers);
		DestroyBuffers(mVertexBuffers);

		for (int b = 0; b < cBlendVariantCount; b++)
		{
			for (int k = 0; k < PipelineKind.Count; k++)
				DestroyPipeline(ref mBlendPipelines[b][k]);
		}
		for (int b = 0; b < cClippedBlendCount; b++)
		{
			for (int k = 0; k < PipelineKind.Count; k++)
				DestroyPipeline(ref mClippedPipelines[b][k]);
		}

		DestroyPipeline(ref mClippedWriteNonZero);
		DestroyPipeline(ref mClippedWriteEvenOdd);
		DestroyPipeline(ref mClipApplyPipeline);
		DestroyPipeline(ref mClipClearPipeline);
		DestroyPipeline(ref mPipeline);
		DestroyPipeline(ref mDistanceFieldPipeline);
		DestroyPipeline(ref mGradRadialPipeline);
		DestroyPipeline(ref mGradConicPipeline);
		DestroyPipeline(ref mBoxShadowPipeline);
		DestroyPipeline(ref mBoxPipeline);
		DestroyPipeline(ref mLayerPipeline);
		DestroyPipeline(ref mBlurPipeline);
		DestroyPipeline(ref mStencilWriteNonZero);
		DestroyPipeline(ref mStencilWriteEvenOdd);
		DestroyPipeline(ref mCoverPipeline);
		DestroyPipeline(ref mCoverGradRadialPipeline);
		DestroyPipeline(ref mCoverGradConicPipeline);

		if (mPipelineLayout != null)
			mDevice.DestroyPipelineLayout(ref mPipelineLayout);
		if (mBindGroupLayout != null)
			mDevice.DestroyBindGroupLayout(ref mBindGroupLayout);

		if (mSampler != null)
			mDevice.DestroySampler(ref mSampler);
		if (mSamplerRepeat != null)
			mDevice.DestroySampler(ref mSamplerRepeat);
		if (mSamplerMirror != null)
			mDevice.DestroySampler(ref mSamplerMirror);

		mInitialized = false;
		mDevice = null;
	}

	private void DestroyPipeline(ref IRenderPipeline pipeline)
	{
		if (pipeline != null)
			mDevice.DestroyRenderPipeline(ref pipeline);
		pipeline = null;
	}

	private void DestroyBuffers(List<IBuffer> buffers)
	{
		for (int i = 0; i < buffers.Count; i++)
		{
			if (buffers[i] == null)
				continue;
			var buffer = buffers[i];
			mDevice.DestroyBuffer(ref buffer);
		}
		buffers.Clear();
	}
}
