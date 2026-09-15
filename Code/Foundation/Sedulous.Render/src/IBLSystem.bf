using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.RenderGraph;
using Sedulous.Shaders;

namespace Sedulous.Render;

/// Image based lighting: the split sum environment chain, PER SCENE.
///
/// Three products are built from each scene's sky. The environment cube is the source
/// radiance, written from whichever source the scene names. Nine spherical harmonic
/// coefficients carry the diffuse irradiance, which is cheaper, smoother and seamless where a
/// small irradiance cube is none of those. The prefiltered specular cube holds one importance
/// sampled level per roughness.
///
/// Shared across scenes: the integration lookup table, which the sky does not enter into, all
/// the pipelines, layouts and samplers, and the PROGRAMMATIC image and cubemap sources the
/// tools and samples set.
///
/// The rebuild only runs when a context's source has changed, but the products are imported
/// every frame, so the forward pass orders after them and samples them. A context's generation
/// comes from ONE system wide counter, so a value never collides across contexts and a
/// downstream bind group cache can key on it alone.
class IBLSystem
{
	public const uint32 cEnvResolution = 256;
	/// The environment's level pyramid, which the prefilter samples according to its density.
	public const int cEnvMips = 5;
	public const uint32 cPrefilterResolution = 256;
	/// The roughness of a level is its index over the last.
	public const int cPrefilterMips = 5;
	public const uint32 cBrdfResolution = 256;
	public const int cShCoeffCount = 9;

	/// A context whose scene has not rendered for this many frames is evicted, its page having
	/// been closed. Long enough that nothing in flight can still be referencing the products.
	public const uint64 cEvictAfterFrames = 600;

	private const TextureFormat cCubeFormat = .RGBA16Float;
	private const TextureFormat cBrdfFormat = .RG16Float;

	private IDevice mDevice;
	private ShaderSystem mShaders;

	private List<IblContext> mContexts = new .() ~ DeleteContainerAndItems!(_);
	private uint64 mFrame = 0;
	/// System wide, so context generations never collide.
	private uint64 mNextGeneration = 0;
	/// Stable context identities, never reused.
	private uint64 mNextContextUid = 0;
	/// The programmatic source's change tick. Contexts start at nought, so the first prepare
	/// of a textured sky sees a change.
	private uint64 mSourceStamp = 1;

	// The shared PROGRAMMATIC image source, uploaded once and sampled by the source pass.
	private ITexture mEquirectTexture = null;
	private ITextureView mEquirectView = null;
	private IBuffer mEquirectStaging = null;
	private ISampler mEquirectSampler = null;
	private IBindGroupLayout mEquirectLayout = null;
	private IPipelineLayout mEquirectPipelineLayout = null;
	private IRenderPipeline mEquirectPipeline = null;
	private IBindGroup mEquirectBindGroup = null;
	private uint32 mEquirectWidth = 0;
	private uint32 mEquirectHeight = 0;
	private bool mEquirectPending = false;

	// The shared PROGRAMMATIC cubemap source.
	private ITexture mSourceCube = null;
	private ITextureView mSourceCubeView = null;
	private IBuffer mCubemapStaging = null;
	private IRenderPipeline mCubemapPipeline = null;
	private IBindGroup mCubemapBindGroup = null;
	private uint32 mCubemapFaceSize = 0;
	private bool mCubemapPending = false;

	// The shared products and machinery.
	private ITexture mBrdfLut = null;
	private ITextureView mBrdfView = null;
	private ISampler mSampler = null;

	private IBindGroupLayout mEnvLayout = null;
	/// A single pixel cube bound where a pipeline's layout declares the environment group but
	/// the mode has no environment source. Every declared group must be bound.
	private ITexture mDummyEnvCube = null;
	private ITextureView mDummyEnvView = null;
	private IBindGroup mDummyEnvBindGroup = null;

	private IBindGroupLayout mShLayout = null;
	private IPipelineLayout mEnvOnlyLayout = null;
	private IPipelineLayout mPrefilterLayout = null;
	private IPipelineLayout mBrdfPipelineLayout = null;
	private IPipelineLayout mShPipelineLayout = null;

	private IRenderPipeline mEnvPipeline = null;
	private IRenderPipeline mAnalyticPipeline = null;
	private IRenderPipeline mDownsamplePipeline = null;
	private IRenderPipeline mPrefilterPipeline = null;
	private IRenderPipeline mBrdfPipeline = null;
	private IComputePipeline mShPipeline = null;

	private ResourceState mBrdfState = .Undefined;
	private RGHandle mBrdfHandle = .Invalid;

	private bool mReady = false;
	/// The lookup table is constant, so it is generated once rather than per sky change.
	private bool mBrdfDone = false;
	private uint64 mPipelineShaderVersion = 0;

	public this(IDevice device, ShaderSystem shaders)
	{
		mDevice = device;
		mShaders = shaders;
	}

	public ~this()
	{
		Shutdown();
	}

	public Result<void> Initialize()
	{
		if (!CreateSharedResources())
			return .Err;
		if (!CreatePipelines())
			return .Err;
		return .Ok;
	}

	/// The integration lookup table, which the sky does not enter into and every scene shares.
	public ITextureView BrdfView => mBrdfView;
	public RGHandle BrdfHandle => mBrdfHandle;
	public uint64 ShBytes => sizeof(float) * 4 * cShCoeffCount;
	public float MaxLod => (float)(cPrefilterMips - 1);
	public bool Ready => mReady;
	public int ContextCount => mContexts.Count;

	/// Opens the frame: imports the shared table, declares its one time build, advances the
	/// clock, and evicts the contexts whose scenes have not rendered in a long while.
	public void BeginFrame(RenderGraph graph)
	{
		// A shader change rebuilds every pipeline and re runs the whole precompute, the cached
		// results being stale. Polled BEFORE the ready gate, so a broken shader turns the
		// system off and a later good one turns it back on.
		let shaderVersion = ShaderVersion();
		if (mPipelineShaderVersion != shaderVersion)
		{
			mPipelineShaderVersion = shaderVersion;
			// Only once the layouts are live, which is to say once initialised.
			if (mEnvOnlyLayout != null)
			{
				mReady = RebuildPipelinesForReload();
				if (mReady)
				{
					for (var context in mContexts)
					{
						DestroyContext(context);
						delete context;
					}
					mContexts.Clear();
					mBrdfDone = false;
				}
			}
		}

		if (!mReady)
			return;

		mFrame++;

		mBrdfHandle = graph.ImportTarget("ibl.brdf", mBrdfLut, mBrdfView, ResourceState.ShaderRead,
			mBrdfState);
		mBrdfState = .ShaderRead;

		if (!mBrdfDone)
		{
			DeclareBrdf(graph, mBrdfHandle);
			mBrdfDone = true;
		}

		for (int i = mContexts.Count - 1; i >= 0; i--)
		{
			if ((mFrame - mContexts[i].LastUsedFrame) > cEvictAfterFrames)
			{
				DestroyContext(mContexts[i]);
				delete mContexts[i];
				mContexts.RemoveAt(i);
			}
		}
	}

	/// Finds or creates the SCENE's context, applies its authored sky and sun, imports its
	/// products into this frame's graph, and declares the rebuild when it is dirty. Null when
	/// the system is not available.
	public IblContext Prepare(Object scene, SkySnapshot sky, Float3 sunDir, RenderGraph graph)
	{
		if (!mReady)
			return null;

		IblContext context = null;
		for (var candidate in mContexts)
		{
			if (candidate.Scene == scene)
			{
				context = candidate;
				break;
			}
		}

		if (context == null)
		{
			let fresh = new IblContext();
			fresh.Scene = scene;
			fresh.Uid = ++mNextContextUid;
			if (!CreateContextResources(fresh))
			{
				DestroyContext(fresh);
				delete fresh;
				return null;
			}
			mContexts.Add(fresh);
			context = fresh;
		}

		context.LastUsedFrame = mFrame;

		// Only the fields BAKED INTO the cube re dirty it. The sun's angular size is drawn
		// live by the sky pass, so changing it rebuilds nothing.
		if (!PrecomputeEqual(sky, context.Sky))
			context.Dirty = true;

		if ((sunDir.X != context.SunDir.X) || (sunDir.Y != context.SunDir.Y)
			|| (sunDir.Z != context.SunDir.Z))
		{
			context.SunDir = sunDir;
			context.Dirty = true;
		}

		// A programmatic source changed, so the textured modes rebake.
		if ((context.SourceStamp != mSourceStamp)
			&& ((sky.Mode == .HDREquirect) || (sky.Mode == .Cubemap)))
			context.Dirty = true;
		context.SourceStamp = mSourceStamp;

		// The scene's OWN sky texture: rebuild the group when the PRODUCT changes, which is
		// detected by identity and never by the pointer, since a reload reuses freed addresses
		// and a deferred destruction keeps the old view alive for the frames in flight.
		if (sky.TextureUid != context.ExternalUid)
		{
			DestroyExternalBindGroups(context);
			context.ExternalUid = sky.TextureUid;

			if (sky.Texture != null)
			{
				if (sky.TextureIsCube)
				{
					if (EnsureCubemapPipeline())
						context.ExternalCubeBindGroup = MakeSourceBindGroup(mEnvLayout,
							sky.Texture, mSampler);
				}
				else
				{
					if (EnsureEquirectPipeline())
						context.ExternalEquirectBindGroup = MakeSourceBindGroup(mEquirectLayout,
							sky.Texture, mEquirectSampler);
				}
			}

			context.Dirty = true;
		}

		// Always store the latest: the sky pass reads the sun's size and intensity live.
		context.Sky = sky;

		ProcessContext(context, graph);
		return context;
	}

	/// Sets the shared PROGRAMMATIC image source, which is the tools' and samples' pixel path.
	/// A scene's own sky texture takes precedence over it.
	public void SetEquirect(uint32 width, uint32 height, Span<float> rgba)
	{
		if (!mReady || (width == 0) || (height == 0)
			|| ((uint64)rgba.Length < (uint64)width * height * 4))
			return;

		DestroyEquirect();

		var textureDesc = TextureDesc();
		textureDesc.Format = .RGBA32Float;
		textureDesc.Width = width;
		textureDesc.Height = height;
		textureDesc.Usage = .Sampled | .CopyDst;
		textureDesc.Label = "ibl.equirect";
		if (!(mDevice.CreateTexture(textureDesc) case .Ok(let texture)))
			return;
		mEquirectTexture = texture;

		var viewDesc = TextureViewDesc();
		viewDesc.Format = .RGBA32Float;
		viewDesc.Dimension = .Texture2D;
		if (!(mDevice.CreateTextureView(texture, viewDesc) case .Ok(let view)))
		{
			DestroyEquirect();
			return;
		}
		mEquirectView = view;

		let bytes = (uint64)width * height * 4 * sizeof(float);
		var stagingDesc = BufferDesc();
		stagingDesc.Size = bytes;
		stagingDesc.Usage = .CopySrc;
		stagingDesc.Memory = .CpuToGpu;
		stagingDesc.Label = "ibl.equirectStaging";
		if (!(mDevice.CreateBuffer(stagingDesc) case .Ok(let staging)))
		{
			DestroyEquirect();
			return;
		}
		mEquirectStaging = staging;

		let mapped = staging.Map();
		if (mapped != null)
		{
			Internal.MemCpy(mapped, rgba.Ptr, (int)bytes);
			staging.Unmap();
		}

		if (!EnsureEquirectPipeline())
		{
			DestroyEquirect();
			return;
		}

		mEquirectBindGroup = MakeSourceBindGroup(mEquirectLayout, mEquirectView, mEquirectSampler);
		if (mEquirectBindGroup == null)
		{
			DestroyEquirect();
			return;
		}

		mEquirectWidth = width;
		mEquirectHeight = height;
		mEquirectPending = true;
		mSourceStamp++;
	}

	/// Sets the shared PROGRAMMATIC cubemap source: six faces concatenated in the order right,
	/// left, up, down, forward, back, each of them the face size squared times four bytes.
	public void SetCubemap(uint32 faceSize, Span<uint8> sixFaces)
	{
		let faceBytes = (uint64)faceSize * faceSize * 4;
		if (!mReady || (faceSize == 0) || ((uint64)sixFaces.Length < faceBytes * 6))
			return;

		DestroyCubemap();

		// An sRGB format, so the hardware decodes the encoded faces to linear on sampling: the
		// environment cube is a linear working space texture, and without this the sky reads
		// washed out.
		var textureDesc = TextureDesc();
		textureDesc.Format = .RGBA8UnormSrgb;
		textureDesc.Width = faceSize;
		textureDesc.Height = faceSize;
		textureDesc.ArrayLayerCount = 6;
		textureDesc.Usage = .Sampled | .CopyDst;
		textureDesc.Label = "ibl.srcCube";
		if (!(mDevice.CreateTexture(textureDesc) case .Ok(let texture)))
			return;
		mSourceCube = texture;

		var viewDesc = TextureViewDesc();
		viewDesc.Format = .RGBA8UnormSrgb;
		viewDesc.Dimension = .TextureCube;
		viewDesc.ArrayLayerCount = 6;
		if (!(mDevice.CreateTextureView(texture, viewDesc) case .Ok(let view)))
		{
			DestroyCubemap();
			return;
		}
		mSourceCubeView = view;

		var stagingDesc = BufferDesc();
		stagingDesc.Size = faceBytes * 6;
		stagingDesc.Usage = .CopySrc;
		stagingDesc.Memory = .CpuToGpu;
		stagingDesc.Label = "ibl.srcCubeStaging";
		if (!(mDevice.CreateBuffer(stagingDesc) case .Ok(let staging)))
		{
			DestroyCubemap();
			return;
		}
		mCubemapStaging = staging;

		let mapped = staging.Map();
		if (mapped != null)
		{
			Internal.MemCpy(mapped, sixFaces.Ptr, (int)(faceBytes * 6));
			staging.Unmap();
		}

		if (!EnsureCubemapPipeline())
		{
			DestroyCubemap();
			return;
		}

		mCubemapBindGroup = MakeSourceBindGroup(mEnvLayout, mSourceCubeView, mSampler);
		if (mCubemapBindGroup == null)
		{
			DestroyCubemap();
			return;
		}

		mCubemapFaceSize = faceSize;
		mCubemapPending = true;
		mSourceStamp++;
	}

	/// Copies a pending source from its staging buffer BEFORE the graph executes, so the
	/// environment build samples an uploaded and readable source.
	public void Upload(ICommandEncoder encoder)
	{
		if (mEquirectPending && (mEquirectTexture != null) && (mEquirectStaging != null))
		{
			encoder.TransitionTexture(mEquirectTexture, .Undefined, .CopyDst);

			var region = BufferTextureCopyRegion();
			region.BytesPerRow = mEquirectWidth * 4 * sizeof(float);
			region.RowsPerImage = mEquirectHeight;
			region.TextureExtent = .(mEquirectWidth, mEquirectHeight, 1);
			encoder.CopyBufferToTexture(mEquirectStaging, mEquirectTexture, region);

			encoder.TransitionTexture(mEquirectTexture, .CopyDst, .ShaderRead);
			mEquirectPending = false;
		}

		if (mCubemapPending && (mSourceCube != null) && (mCubemapStaging != null))
		{
			encoder.TransitionTexture(mSourceCube, .Undefined, .CopyDst);

			let faceBytes = (uint64)mCubemapFaceSize * mCubemapFaceSize * 4;
			for (uint32 face = 0; face < 6; face++)
			{
				var region = BufferTextureCopyRegion();
				region.BufferOffset = faceBytes * face;
				region.BytesPerRow = mCubemapFaceSize * 4;
				region.RowsPerImage = mCubemapFaceSize;
				region.TextureArrayLayer = face;
				region.TextureExtent = .(mCubemapFaceSize, mCubemapFaceSize, 1);
				encoder.CopyBufferToTexture(mCubemapStaging, mSourceCube, region);
			}

			encoder.TransitionTexture(mSourceCube, .CopyDst, .ShaderRead);
			mCubemapPending = false;
		}
	}

	private uint64 ShaderVersion()
	{
		return mShaders.Version("ibl_fs") + mShaders.Version("ibl_procenv")
			+ mShaders.Version("ibl_analytic") + mShaders.Version("ibl_equirect")
			+ mShaders.Version("ibl_cubemap") + mShaders.Version("ibl_downsample")
			+ mShaders.Version("ibl_prefilter") + mShaders.Version("ibl_brdf")
			+ mShaders.Version("ibl_sh");
	}

	/// Imports one context's products and, when it is dirty, declares the whole rebuild.
	private void ProcessContext(IblContext context, RenderGraph graph)
	{
		context.PrefilterHandle = graph.ImportTarget("ibl.prefilter", context.PrefilterCube,
			context.PrefilterView, ResourceState.ShaderRead, context.PrefilterState);
		context.PrefilterState = .ShaderRead;

		context.ShHandle = graph.ImportBuffer("ibl.sh", context.ShBuffer);

		// The environment is imported every frame too: the sky pass reads it for the visible
		// backdrop.
		context.EnvHandle = graph.ImportTarget("ibl.env", context.EnvCube, context.EnvView,
			ResourceState.ShaderRead, context.EnvState);
		context.EnvState = .ShaderRead;

		if (!context.Dirty && (context.BakeWarmup == 0))
			return;

		if (context.BakeWarmup > 0)
			context.BakeWarmup--;

		// The generation tracks PRODUCT IDENTITY, which consumers key their caches on, so it
		// only moves on a real change of content. A warmup rebake renders the same content
		// into the same textures; bumping there would churn every downstream cache for the
		// whole warmup window.
		if (context.Dirty)
			context.Generation = ++mNextGeneration;
		context.Dirty = false;

		// The source into the environment's six faces. The scene's OWN texture wins over the
		// programmatic one when both are present.
		let envHandle = context.EnvHandle;
		let equirectBindGroup = (context.ExternalEquirectBindGroup != null)
			? context.ExternalEquirectBindGroup
			: mEquirectBindGroup;
		let cubemapBindGroup = (context.ExternalCubeBindGroup != null)
			? context.ExternalCubeBindGroup
			: mCubemapBindGroup;

		let useEquirect = (context.Sky.Mode == .HDREquirect) && (equirectBindGroup != null);
		let useCubemap = (context.Sky.Mode == .Cubemap) && (cubemapBindGroup != null);
		let useAnalytic = (context.Sky.Mode == .Analytic);

		let envPipeline = useEquirect ? mEquirectPipeline
			: useCubemap ? mCubemapPipeline
			: useAnalytic ? mAnalyticPipeline
			: mEnvPipeline;

		// The gradient and analytic skies have no source at all, so the dummy is bound to
		// satisfy the declared group.
		let envBindGroup = useEquirect ? equirectBindGroup
			: useCubemap ? cubemapBindGroup
			: mDummyEnvBindGroup;

		for (uint32 face = 0; face < 6; face++)
		{
			let push = MakeSkyPush(context, (int32)face);
			graph.AddRenderPass("ibl.env.face", scope (builder) =>
				{
					builder.SetColorTarget(0, envHandle, .Clear, .Store, .Black, .(0, 1, face, 1));
					builder.SetViewport(0, 0, cEnvResolution, cEnvResolution);
					builder.NeverCull();

					builder.SetExecute(new (encoder) =>
						{
							encoder.SetPipeline(envPipeline);
							if (envBindGroup != null)
								encoder.SetBindGroup(0, envBindGroup);

							var constants = push;
							encoder.SetPushConstants(.Fragment, 0, sizeof(IblPush), &constants);
							encoder.Draw(3, 1, 0, 0);
						});
				});
		}

		DeclareEnvMips(context, graph, envHandle);
		DeclareShProjection(context, graph, envHandle, context.ShHandle);
		DeclarePrefilter(context, graph, envHandle, context.PrefilterHandle);
	}

	private static IblPush MakeSkyPush(IblContext context, int32 face)
	{
		var push = IblPush();
		push.FaceIndex = face;
		push.Mode = (int32)context.Sky.Mode;
		push.SkyIntensity = context.Sky.Intensity;
		push.Sun = .(context.SunDir.X, context.SunDir.Y, context.SunDir.Z,
			context.Sky.SunAngularSize);
		push.Horizon = .(context.Sky.Horizon.X, context.Sky.Horizon.Y, context.Sky.Horizon.Z,
			context.Sky.SunIntensity);
		push.Zenith = .(context.Sky.Zenith.X, context.Sky.Zenith.Y, context.Sky.Zenith.Z,
			context.Sky.Rotation);
		push.Ground = .(context.Sky.Ground.X, context.Sky.Ground.Y, context.Sky.Ground.Z,
			context.Sky.Turbidity);
		return push;
	}

	/// Equal as far as the fields BAKED INTO the cube go, which is what decides a rebuild. The
	/// sun's angular size is excluded: it only affects the disc the sky pass draws.
	private static bool PrecomputeEqual(SkySnapshot a, SkySnapshot b)
	{
		return (a.Mode == b.Mode) && (a.Intensity == b.Intensity) && (a.Rotation == b.Rotation)
			&& (a.TextureUid == b.TextureUid)
			&& (a.Horizon.X == b.Horizon.X) && (a.Horizon.Y == b.Horizon.Y)
			&& (a.Horizon.Z == b.Horizon.Z)
			&& (a.Zenith.X == b.Zenith.X) && (a.Zenith.Y == b.Zenith.Y)
			&& (a.Zenith.Z == b.Zenith.Z)
			&& (a.Ground.X == b.Ground.X) && (a.Ground.Y == b.Ground.Y)
			&& (a.Ground.Z == b.Ground.Z)
			&& (a.SunIntensity == b.SunIntensity) && (a.Turbidity == b.Turbidity);
	}

	private void DeclareShProjection(IblContext context, RenderGraph graph, RGHandle envHandle,
		RGHandle shHandle)
	{
		let shBindGroup = context.ShBindGroup;
		graph.AddComputePass("ibl.sh", scope (builder) =>
			{
				builder.ReadTexture(envHandle);
				builder.WriteStorage(shHandle);

				builder.SetComputeExecute(new (encoder) =>
					{
						if (shBindGroup == null)
							return;

						encoder.SetPipeline(mShPipeline);
						encoder.SetBindGroup(0, shBindGroup);
						encoder.Dispatch(1, 1, 1);
					});
			});
	}

	/// Box downsamples the environment's level pyramid, each level from the one before it. A
	/// pass reads ONLY the finer level, through a single level view, and renders the coarser,
	/// so the read and the write never touch the same slice and the graph's own barriers
	/// serialise the chain.
	private void DeclareEnvMips(IblContext context, RenderGraph graph, RGHandle envHandle)
	{
		for (uint32 mip = 1; mip < cEnvMips; mip++)
		{
			let resolution = cEnvResolution >> mip;
			let sourceBindGroup = context.EnvMipBindGroups[mip - 1];

			for (uint32 face = 0; face < 6; face++)
			{
				var push = IblPush();
				push.FaceIndex = (int32)face;

				graph.AddRenderPass("ibl.env.mip", scope (builder) =>
					{
						builder.ReadTexture(envHandle, .(mip - 1, 1, 0, 6));
						builder.SetColorTarget(0, envHandle, .Clear, .Store, .Black,
							.(mip, 1, face, 1));
						builder.SetViewport(0, 0, resolution, resolution);
						builder.NeverCull();

						builder.SetExecute(new (encoder) =>
							{
								encoder.SetPipeline(mDownsamplePipeline);
								encoder.SetBindGroup(0, sourceBindGroup);

								var constants = push;
								encoder.SetPushConstants(.Fragment, 0, sizeof(IblPush), &constants);
								encoder.Draw(3, 1, 0, 0);
							});
					});
			}
		}
	}

	private void DeclarePrefilter(IblContext context, RenderGraph graph, RGHandle envHandle,
		RGHandle prefilterHandle)
	{
		let envBindGroup = context.EnvBindGroup;

		for (uint32 mip = 0; mip < cPrefilterMips; mip++)
		{
			let resolution = cPrefilterResolution >> mip;
			let roughness = (cPrefilterMips > 1)
				? (float)mip / (float)(cPrefilterMips - 1)
				: 0.0f;

			for (uint32 face = 0; face < 6; face++)
			{
				var push = IblPush();
				push.FaceIndex = (int32)face;
				push.Roughness = roughness;

				graph.AddRenderPass("ibl.prefilter", scope (builder) =>
					{
						builder.ReadTexture(envHandle);
						builder.SetColorTarget(0, prefilterHandle, .Clear, .Store, .Black,
							.(mip, 1, face, 1));
						builder.SetViewport(0, 0, resolution, resolution);
						builder.NeverCull();

						builder.SetExecute(new (encoder) =>
							{
								encoder.SetPipeline(mPrefilterPipeline);
								encoder.SetBindGroup(0, envBindGroup);

								var constants = push;
								encoder.SetPushConstants(.Fragment, 0, sizeof(IblPush), &constants);
								encoder.Draw(3, 1, 0, 0);
							});
					});
			}
		}
	}

	private void DeclareBrdf(RenderGraph graph, RGHandle brdfHandle)
	{
		graph.AddRenderPass("ibl.brdf", scope (builder) =>
			{
				builder.SetColorTarget(0, brdfHandle, .Clear, .Store, .Black);
				builder.SetViewport(0, 0, cBrdfResolution, cBrdfResolution);
				builder.NeverCull();

				builder.SetExecute(new (encoder) =>
					{
						encoder.SetPipeline(mBrdfPipeline);
						encoder.Draw(3, 1, 0, 0);
					});
			});
	}

	private IBindGroup MakeSourceBindGroup(IBindGroupLayout layout, ITextureView view,
		ISampler sampler)
	{
		var entries = BindGroupEntry[2](
			BindGroupEntry.TextureEntry(view),
			BindGroupEntry.SamplerEntry(sampler));

		var desc = BindGroupDesc();
		desc.Layout = layout;
		desc.Entries = .(&entries[0], 2);

		if (!(mDevice.CreateBindGroup(desc) case .Ok(let bindGroup)))
			return null;
		return bindGroup;
	}

	private bool CreateSharedResources()
	{
		var brdfDesc = TextureDesc();
		brdfDesc.Format = cBrdfFormat;
		brdfDesc.Width = cBrdfResolution;
		brdfDesc.Height = cBrdfResolution;
		brdfDesc.Usage = .RenderTarget | .Sampled;
		brdfDesc.Label = "ibl.brdf";
		if (!(mDevice.CreateTexture(brdfDesc) case .Ok(let brdf)))
			return false;
		mBrdfLut = brdf;

		var brdfViewDesc = TextureViewDesc();
		brdfViewDesc.Format = cBrdfFormat;
		brdfViewDesc.Dimension = .Texture2D;
		if (!(mDevice.CreateTextureView(brdf, brdfViewDesc) case .Ok(let brdfView)))
			return false;
		mBrdfView = brdfView;

		var samplerDesc = SamplerDesc();
		samplerDesc.MinFilter = .Linear;
		samplerDesc.MagFilter = .Linear;
		samplerDesc.MipmapFilter = .Linear;
		samplerDesc.AddressU = .ClampToEdge;
		samplerDesc.AddressV = .ClampToEdge;
		samplerDesc.AddressW = .ClampToEdge;
		samplerDesc.Label = "ibl.sampler";
		if (!(mDevice.CreateSampler(samplerDesc) case .Ok(let sampler)))
			return false;
		mSampler = sampler;

		return true;
	}

	private bool CreateContextResources(IblContext context)
	{
		// The environment cube and its levels: the first holds the full resolution radiance,
		// and the rest are box downsampled so the prefilter can sample a pre averaged level
		// according to its density, which is what keeps the fireflies out.
		var envDesc = TextureDesc();
		envDesc.Format = cCubeFormat;
		envDesc.Width = cEnvResolution;
		envDesc.Height = cEnvResolution;
		envDesc.ArrayLayerCount = 6;
		envDesc.MipLevelCount = cEnvMips;
		envDesc.Usage = .RenderTarget | .Sampled;
		envDesc.Label = "ibl.env";
		if (!(mDevice.CreateTexture(envDesc) case .Ok(let envCube)))
			return false;
		context.EnvCube = envCube;

		var envViewDesc = TextureViewDesc();
		envViewDesc.Format = cCubeFormat;
		envViewDesc.Dimension = .TextureCube;
		envViewDesc.ArrayLayerCount = 6;
		envViewDesc.MipLevelCount = cEnvMips;
		if (!(mDevice.CreateTextureView(envCube, envViewDesc) case .Ok(let envView)))
			return false;
		context.EnvView = envView;

		for (int mip < cEnvMips)
		{
			var mipViewDesc = TextureViewDesc();
			mipViewDesc.Format = cCubeFormat;
			mipViewDesc.Dimension = .TextureCube;
			mipViewDesc.BaseMipLevel = (uint32)mip;
			mipViewDesc.MipLevelCount = 1;
			mipViewDesc.ArrayLayerCount = 6;
			if (!(mDevice.CreateTextureView(envCube, mipViewDesc) case .Ok(let mipView)))
				return false;
			context.EnvMipViews[mip] = mipView;
		}

		var prefilterDesc = TextureDesc();
		prefilterDesc.Format = cCubeFormat;
		prefilterDesc.Width = cPrefilterResolution;
		prefilterDesc.Height = cPrefilterResolution;
		prefilterDesc.ArrayLayerCount = 6;
		prefilterDesc.MipLevelCount = cPrefilterMips;
		prefilterDesc.Usage = .RenderTarget | .Sampled;
		prefilterDesc.Label = "ibl.prefilter";
		if (!(mDevice.CreateTexture(prefilterDesc) case .Ok(let prefilterCube)))
			return false;
		context.PrefilterCube = prefilterCube;

		var prefilterViewDesc = TextureViewDesc();
		prefilterViewDesc.Format = cCubeFormat;
		prefilterViewDesc.Dimension = .TextureCube;
		prefilterViewDesc.ArrayLayerCount = 6;
		prefilterViewDesc.MipLevelCount = cPrefilterMips;
		if (!(mDevice.CreateTextureView(prefilterCube, prefilterViewDesc) case .Ok(let preView)))
			return false;
		context.PrefilterView = preView;

		// The coefficients: written by the compute, read by the forward.
		var shDesc = BufferDesc();
		shDesc.Size = ShBytes;
		shDesc.Usage = .Storage;
		shDesc.Memory = .GpuOnly;
		shDesc.Label = "ibl.sh";
		if (!(mDevice.CreateBuffer(shDesc) case .Ok(let shBuffer)))
			return false;
		context.ShBuffer = shBuffer;

		// The whole chain, which the prefilter samples, and then each level as a source.
		context.EnvBindGroup = MakeSourceBindGroup(mEnvLayout, context.EnvView, mSampler);
		if (context.EnvBindGroup == null)
			return false;

		for (int mip < cEnvMips)
		{
			context.EnvMipBindGroups[mip] = MakeSourceBindGroup(mEnvLayout,
				context.EnvMipViews[mip], mSampler);
			if (context.EnvMipBindGroups[mip] == null)
				return false;
		}

		var shEntries = BindGroupEntry[3](
			BindGroupEntry.TextureEntry(context.EnvView),
			BindGroupEntry.SamplerEntry(mSampler),
			BindGroupEntry.BufferEntry(shBuffer, 0, ShBytes));

		var shBindGroupDesc = BindGroupDesc();
		shBindGroupDesc.Layout = mShLayout;
		shBindGroupDesc.Entries = .(&shEntries[0], 3);
		if (!(mDevice.CreateBindGroup(shBindGroupDesc) case .Ok(let shBindGroup)))
			return false;
		context.ShBindGroup = shBindGroup;

		// Build the products on the first prepare.
		context.Dirty = true;
		return true;
	}

	private void DestroyExternalBindGroups(IblContext context)
	{
		if (context.ExternalEquirectBindGroup != null)
			mDevice.DestroyBindGroup(ref context.ExternalEquirectBindGroup);
		if (context.ExternalCubeBindGroup != null)
			mDevice.DestroyBindGroup(ref context.ExternalCubeBindGroup);
	}

	private void DestroyContext(IblContext context)
	{
		DestroyExternalBindGroups(context);

		if (context.ShBindGroup != null)
			mDevice.DestroyBindGroup(ref context.ShBindGroup);
		if (context.EnvBindGroup != null)
			mDevice.DestroyBindGroup(ref context.EnvBindGroup);

		for (int mip < cEnvMips)
		{
			if (context.EnvMipBindGroups[mip] != null)
				mDevice.DestroyBindGroup(ref context.EnvMipBindGroups[mip]);
		}

		if (context.ShBuffer != null)
			mDevice.DestroyBuffer(ref context.ShBuffer);
		if (context.PrefilterView != null)
			mDevice.DestroyTextureView(ref context.PrefilterView);
		if (context.PrefilterCube != null)
			mDevice.DestroyTexture(ref context.PrefilterCube);

		for (int mip < cEnvMips)
		{
			if (context.EnvMipViews[mip] != null)
				mDevice.DestroyTextureView(ref context.EnvMipViews[mip]);
		}

		if (context.EnvView != null)
			mDevice.DestroyTextureView(ref context.EnvView);
		if (context.EnvCube != null)
			mDevice.DestroyTexture(ref context.EnvCube);
	}

	private bool CreatePipelines()
	{
		let vertex = mShaders.GetVariant("ibl_fs", .Vertex, .None);
		if (vertex == null)
			return false;

		var dummyDesc = TextureDesc();
		dummyDesc.Format = .RGBA8Unorm;
		dummyDesc.Width = 1;
		dummyDesc.Height = 1;
		dummyDesc.ArrayLayerCount = 6;
		dummyDesc.Usage = .Sampled | .CopyDst;
		dummyDesc.Label = "ibl.dummy_env";
		if (!(mDevice.CreateTexture(dummyDesc) case .Ok(let dummyCube)))
			return false;
		mDummyEnvCube = dummyCube;

		var dummyViewDesc = TextureViewDesc();
		dummyViewDesc.Format = .RGBA8Unorm;
		dummyViewDesc.Dimension = .TextureCube;
		dummyViewDesc.ArrayLayerCount = 6;
		if (!(mDevice.CreateTextureView(dummyCube, dummyViewDesc) case .Ok(let dummyView)))
			return false;
		mDummyEnvView = dummyView;

		// The environment sample layout, which the prefilter and the downsample share.
		var envEntries = BindGroupLayoutEntry[2](
			BindGroupLayoutEntry.SampledTexture(0, .Fragment, .TextureCube),
			BindGroupLayoutEntry.Sampler(0, .Fragment));

		var envLayoutDesc = BindGroupLayoutDesc();
		envLayoutDesc.Entries = .(&envEntries[0], 2);
		if (!(mDevice.CreateBindGroupLayout(envLayoutDesc) case .Ok(let envLayout)))
			return false;
		mEnvLayout = envLayout;

		mDummyEnvBindGroup = MakeSourceBindGroup(mEnvLayout, mDummyEnvView, mSampler);
		if (mDummyEnvBindGroup == null)
			return false;

		// The gradient sky has no source, but its layout still declares the group, so its push
		// constants land in the same place as every other stage's.
		mEnvOnlyLayout = MakePipelineLayout(mEnvLayout);
		if (mEnvOnlyLayout == null)
			return false;

		mPrefilterLayout = MakePipelineLayout(mEnvLayout);
		if (mPrefilterLayout == null)
			return false;

		// The lookup table takes no inputs at all.
		var brdfLayoutDesc = PipelineLayoutDesc();
		if (!(mDevice.CreatePipelineLayout(brdfLayoutDesc) case .Ok(let brdfPipelineLayout)))
			return false;
		mBrdfPipelineLayout = brdfPipelineLayout;

		mEnvPipeline = MakeFullscreenPipeline(vertex, "ibl_procenv", mEnvOnlyLayout, cCubeFormat);
		mAnalyticPipeline = MakeFullscreenPipeline(vertex, "ibl_analytic", mEnvOnlyLayout,
			cCubeFormat);
		mDownsamplePipeline = MakeFullscreenPipeline(vertex, "ibl_downsample", mPrefilterLayout,
			cCubeFormat);
		mPrefilterPipeline = MakeFullscreenPipeline(vertex, "ibl_prefilter", mPrefilterLayout,
			cCubeFormat);
		mBrdfPipeline = MakeFullscreenPipeline(vertex, "ibl_brdf", mBrdfPipelineLayout,
			cBrdfFormat);

		if ((mEnvPipeline == null) || (mAnalyticPipeline == null) || (mDownsamplePipeline == null)
			|| (mPrefilterPipeline == null) || (mBrdfPipeline == null))
			return false;

		// The projection is a compute, its groups being per context.
		let compute = mShaders.GetVariant("ibl_sh", .Compute, .None);
		if (compute == null)
			return false;

		var shEntries = BindGroupLayoutEntry[3](
			BindGroupLayoutEntry.SampledTexture(0, .Compute, .TextureCube),
			BindGroupLayoutEntry.Sampler(0, .Compute),
			BindGroupLayoutEntry.StorageBuffer(0, .Compute, false, 16));

		var shLayoutDesc = BindGroupLayoutDesc();
		shLayoutDesc.Entries = .(&shEntries[0], 3);
		if (!(mDevice.CreateBindGroupLayout(shLayoutDesc) case .Ok(let shLayout)))
			return false;
		mShLayout = shLayout;

		var shLayouts = IBindGroupLayout[1](mShLayout);
		var shPipelineLayoutDesc = PipelineLayoutDesc();
		shPipelineLayoutDesc.BindGroupLayouts = .(&shLayouts[0], 1);
		if (!(mDevice.CreatePipelineLayout(shPipelineLayoutDesc) case .Ok(let shPipelineLayout)))
			return false;
		mShPipelineLayout = shPipelineLayout;

		var computeDesc = ComputePipelineDesc();
		computeDesc.Layout = mShPipelineLayout;
		computeDesc.Compute = .(compute, "main", .Compute);
		computeDesc.Label = "ibl.sh";
		if (!(mDevice.CreateComputePipeline(computeDesc) case .Ok(let shPipeline)))
			return false;
		mShPipeline = shPipeline;

		mReady = true;
		return true;
	}

	/// Rebuilds every pipeline against the reloaded shaders. The layouts survive. False when a
	/// shader no longer compiles.
	private bool RebuildPipelinesForReload()
	{
		let vertex = mShaders.GetVariant("ibl_fs", .Vertex, .None);
		let compute = mShaders.GetVariant("ibl_sh", .Compute, .None);
		if ((vertex == null) || (compute == null))
			return false;

		if (mEnvPipeline != null)
			mDevice.DestroyRenderPipeline(ref mEnvPipeline);
		if (mAnalyticPipeline != null)
			mDevice.DestroyRenderPipeline(ref mAnalyticPipeline);
		if (mDownsamplePipeline != null)
			mDevice.DestroyRenderPipeline(ref mDownsamplePipeline);
		if (mPrefilterPipeline != null)
			mDevice.DestroyRenderPipeline(ref mPrefilterPipeline);
		if (mBrdfPipeline != null)
			mDevice.DestroyRenderPipeline(ref mBrdfPipeline);
		if (mEquirectPipeline != null)
			mDevice.DestroyRenderPipeline(ref mEquirectPipeline);
		if (mCubemapPipeline != null)
			mDevice.DestroyRenderPipeline(ref mCubemapPipeline);
		if (mShPipeline != null)
			mDevice.DestroyComputePipeline(ref mShPipeline);

		mEnvPipeline = MakeFullscreenPipeline(vertex, "ibl_procenv", mEnvOnlyLayout, cCubeFormat);
		mAnalyticPipeline = MakeFullscreenPipeline(vertex, "ibl_analytic", mEnvOnlyLayout,
			cCubeFormat);
		mDownsamplePipeline = MakeFullscreenPipeline(vertex, "ibl_downsample", mPrefilterLayout,
			cCubeFormat);
		mPrefilterPipeline = MakeFullscreenPipeline(vertex, "ibl_prefilter", mPrefilterLayout,
			cCubeFormat);
		mBrdfPipeline = MakeFullscreenPipeline(vertex, "ibl_brdf", mBrdfPipelineLayout,
			cBrdfFormat);

		var computeDesc = ComputePipelineDesc();
		computeDesc.Layout = mShPipelineLayout;
		computeDesc.Compute = .(compute, "main", .Compute);
		computeDesc.Label = "ibl.sh";
		if (mDevice.CreateComputePipeline(computeDesc) case .Ok(let shPipeline))
			mShPipeline = shPipeline;

		// The image and cubemap pipelines rebuild lazily on their next use.
		return (mEnvPipeline != null) && (mAnalyticPipeline != null)
			&& (mDownsamplePipeline != null) && (mPrefilterPipeline != null)
			&& (mBrdfPipeline != null) && (mShPipeline != null);
	}

	private IPipelineLayout MakePipelineLayout(IBindGroupLayout bindGroupLayout)
	{
		var layouts = IBindGroupLayout[1](bindGroupLayout);
		var pushRange = PushConstantRange();
		pushRange.Stages = .Fragment;
		pushRange.Offset = 0;
		pushRange.Size = sizeof(IblPush);

		var desc = PipelineLayoutDesc();
		desc.BindGroupLayouts = .(&layouts[0], 1);
		desc.PushConstantRanges = .(&pushRange, 1);

		if (!(mDevice.CreatePipelineLayout(desc) case .Ok(let layout)))
			return null;
		return layout;
	}

	private IRenderPipeline MakeFullscreenPipeline(IShaderModule vertex, StringView fragmentName,
		IPipelineLayout layout, TextureFormat format)
	{
		let fragment = mShaders.GetVariant(fragmentName, .Fragment, .None);
		if (fragment == null)
			return null;

		var color = ColorTargetState();
		color.Format = format;

		var fragmentState = FragmentState();
		fragmentState.Shader = .(fragment, "main", .Fragment);
		fragmentState.Targets = .(&color, 1);

		var desc = RenderPipelineDesc();
		desc.Layout = layout;
		desc.Vertex.Shader = .(vertex, "main", .Vertex);
		desc.Fragment = fragmentState;
		desc.Primitive.Topology = .TriangleList;
		desc.Primitive.CullMode = .None;
		desc.Label = fragmentName;

		if (!(mDevice.CreateRenderPipeline(desc) case .Ok(let pipeline)))
			return null;
		return pipeline;
	}

	/// The image source's pipeline is built the first time one is set, most scenes being
	/// procedural.
	private bool EnsureEquirectPipeline()
	{
		if (mEquirectPipeline != null)
			return true;

		let vertex = mShaders.GetVariant("ibl_fs", .Vertex, .None);
		if (vertex == null)
			return false;

		// The layouts survive a shader reload.
		if (mEquirectLayout == null)
		{
			var entries = BindGroupLayoutEntry[2](
				BindGroupLayoutEntry.SampledTexture(0, .Fragment, .Texture2D),
				BindGroupLayoutEntry.Sampler(0, .Fragment));

			var layoutDesc = BindGroupLayoutDesc();
			layoutDesc.Entries = .(&entries[0], 2);
			if (!(mDevice.CreateBindGroupLayout(layoutDesc) case .Ok(let layout)))
				return false;
			mEquirectLayout = layout;

			mEquirectPipelineLayout = MakePipelineLayout(mEquirectLayout);
			if (mEquirectPipelineLayout == null)
				return false;
		}

		mEquirectPipeline = MakeFullscreenPipeline(vertex, "ibl_equirect",
			mEquirectPipelineLayout, cCubeFormat);
		if (mEquirectPipeline == null)
			return false;

		if (mEquirectSampler == null)
		{
			var samplerDesc = SamplerDesc();
			samplerDesc.MinFilter = .Linear;
			samplerDesc.MagFilter = .Linear;
			samplerDesc.MipmapFilter = .Linear;
			// Wrapping horizontally, since the image meets itself behind the camera.
			samplerDesc.AddressU = .Repeat;
			samplerDesc.AddressV = .ClampToEdge;
			samplerDesc.AddressW = .ClampToEdge;
			samplerDesc.Label = "ibl.equirectSampler";
			if (!(mDevice.CreateSampler(samplerDesc) case .Ok(let sampler)))
				return false;
			mEquirectSampler = sampler;
		}

		return true;
	}

	/// The cubemap source reuses the prefilter's layout, both sampling a cube through a push.
	private bool EnsureCubemapPipeline()
	{
		if (mCubemapPipeline != null)
			return true;
		if ((mPrefilterLayout == null) || (mEnvLayout == null))
			return false;

		let vertex = mShaders.GetVariant("ibl_fs", .Vertex, .None);
		if (vertex == null)
			return false;

		mCubemapPipeline = MakeFullscreenPipeline(vertex, "ibl_cubemap", mPrefilterLayout,
			cCubeFormat);
		return mCubemapPipeline != null;
	}

	private void DestroyCubemap()
	{
		if (mCubemapBindGroup != null)
			mDevice.DestroyBindGroup(ref mCubemapBindGroup);
		if (mCubemapStaging != null)
			mDevice.DestroyBuffer(ref mCubemapStaging);
		if (mSourceCubeView != null)
			mDevice.DestroyTextureView(ref mSourceCubeView);
		if (mSourceCube != null)
			mDevice.DestroyTexture(ref mSourceCube);
		mCubemapPending = false;
	}

	/// Frees the image source itself. The pipeline, layout and sampler persist, being built
	/// lazily once.
	private void DestroyEquirect()
	{
		if (mEquirectBindGroup != null)
			mDevice.DestroyBindGroup(ref mEquirectBindGroup);
		if (mEquirectStaging != null)
			mDevice.DestroyBuffer(ref mEquirectStaging);
		if (mEquirectView != null)
			mDevice.DestroyTextureView(ref mEquirectView);
		if (mEquirectTexture != null)
			mDevice.DestroyTexture(ref mEquirectTexture);
		mEquirectPending = false;
	}

	private void Shutdown()
	{
		if (mDevice == null)
			return;

		for (var context in mContexts)
			DestroyContext(context);

		DestroyCubemap();
		if (mCubemapPipeline != null)
			mDevice.DestroyRenderPipeline(ref mCubemapPipeline);

		DestroyEquirect();
		if (mEquirectPipeline != null)
			mDevice.DestroyRenderPipeline(ref mEquirectPipeline);
		if (mEquirectPipelineLayout != null)
			mDevice.DestroyPipelineLayout(ref mEquirectPipelineLayout);
		if (mEquirectLayout != null)
			mDevice.DestroyBindGroupLayout(ref mEquirectLayout);
		if (mEquirectSampler != null)
			mDevice.DestroySampler(ref mEquirectSampler);

		if (mShPipeline != null)
			mDevice.DestroyComputePipeline(ref mShPipeline);
		if (mDummyEnvBindGroup != null)
			mDevice.DestroyBindGroup(ref mDummyEnvBindGroup);
		if (mDummyEnvView != null)
			mDevice.DestroyTextureView(ref mDummyEnvView);
		if (mDummyEnvCube != null)
			mDevice.DestroyTexture(ref mDummyEnvCube);

		if (mEnvPipeline != null)
			mDevice.DestroyRenderPipeline(ref mEnvPipeline);
		if (mAnalyticPipeline != null)
			mDevice.DestroyRenderPipeline(ref mAnalyticPipeline);
		if (mDownsamplePipeline != null)
			mDevice.DestroyRenderPipeline(ref mDownsamplePipeline);
		if (mPrefilterPipeline != null)
			mDevice.DestroyRenderPipeline(ref mPrefilterPipeline);
		if (mBrdfPipeline != null)
			mDevice.DestroyRenderPipeline(ref mBrdfPipeline);

		if (mShPipelineLayout != null)
			mDevice.DestroyPipelineLayout(ref mShPipelineLayout);
		if (mEnvOnlyLayout != null)
			mDevice.DestroyPipelineLayout(ref mEnvOnlyLayout);
		if (mPrefilterLayout != null)
			mDevice.DestroyPipelineLayout(ref mPrefilterLayout);
		if (mBrdfPipelineLayout != null)
			mDevice.DestroyPipelineLayout(ref mBrdfPipelineLayout);

		if (mShLayout != null)
			mDevice.DestroyBindGroupLayout(ref mShLayout);
		if (mEnvLayout != null)
			mDevice.DestroyBindGroupLayout(ref mEnvLayout);
		if (mSampler != null)
			mDevice.DestroySampler(ref mSampler);
		if (mBrdfView != null)
			mDevice.DestroyTextureView(ref mBrdfView);
		if (mBrdfLut != null)
			mDevice.DestroyTexture(ref mBrdfLut);
	}
}
