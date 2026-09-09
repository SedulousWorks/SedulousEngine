using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.RenderGraph;
using Sedulous.Shaders;

namespace Sedulous.Render;

/// Resolves the multisampled depth and auxiliary targets down to single sampled ones.
///
/// The post effects read a normal, a velocity and a depth per PIXEL rather than per sample,
/// so a multisampled view has to hand them a resolved copy. This takes the FIRST SAMPLE of
/// each rather than averaging: averaging a depth or a normal across an edge produces a value
/// that describes neither surface.
///
/// One instance serves every view, since the pipeline does not depend on the view.
class MsaaResolvePass
{
	/// A cached group, and the input generation it was built for.
	private struct Entry
	{
		public IBindGroup BindGroup;
		public uint64 Generation;
	}

	private IDevice mDevice;
	private ShaderSystem mShaders;

	private IBindGroupLayout mLayout = null;
	private IPipelineLayout mPipelineLayout = null;
	private IRenderPipeline mPipeline = null;
	private TextureFormat mPipelineDepthFormat = .Undefined;
	private uint64 mPipelineShaderVersion = 0;

	/// Keyed by the depth view's address, with the generation held beside it: a transient is
	/// reallocated between frames, and the generation is what says so.
	private Dictionary<int, Entry> mBindGroups = new .() ~ delete _;

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
		// Four MULTISAMPLED textures and no sampler: the shader loads a given sample rather
		// than filtering, which is the only thing that makes sense across an edge.
		var entries = BindGroupLayoutEntry[4](
			BindGroupLayoutEntry.SampledTexture(0, .Fragment),
			BindGroupLayoutEntry.SampledTexture(1, .Fragment),
			BindGroupLayoutEntry.SampledTexture(2, .Fragment),
			BindGroupLayoutEntry.SampledTexture(3, .Fragment));

		for (int i < 4)
		{
			entries[i].TextureMultisampled = true;
			// A multisampled binding may not declare a FILTERABLE sample type: every one of
			// these is loaded rather than sampled, so unfilterable is both required and
			// correct. One backend tolerates the other spelling; the other rejects it.
			entries[i].TextureSampleType = .UnfilterableFloat;
		}

		var layoutDesc = BindGroupLayoutDesc();
		layoutDesc.Entries = .(&entries[0], 4);
		if (!(mDevice.CreateBindGroupLayout(layoutDesc) case .Ok(let layout)))
			return .Err;
		mLayout = layout;

		var layouts = IBindGroupLayout[1](mLayout);
		var pipelineLayoutDesc = PipelineLayoutDesc();
		pipelineLayoutDesc.BindGroupLayouts = .(&layouts[0], 1);
		if (!(mDevice.CreatePipelineLayout(pipelineLayoutDesc) case .Ok(let pipelineLayout)))
			return .Err;
		mPipelineLayout = pipelineLayout;

		// The pipeline itself is built lazily, keyed on the scene's depth format, so a host
		// using a different one still gets a valid pipeline.
		return .Ok;
	}

	/// Declares the resolve into fresh single sampled transients. Invalid handles mean no
	/// pass was emitted.
	public MsaaResolveOutputs DeclareResolve(RenderGraph graph, RGHandle msaaDepth,
		RGHandle msaaNormal, RGHandle msaaVelocity, RGHandle msaaMaterial,
		TextureFormat depthFormat, uint32 width, uint32 height)
	{
		var outputs = MsaaResolveOutputs();
		if ((width == 0) || (height == 0))
			return outputs;

		let shaderVersion = mShaders.Version("msaa_resolve");
		if ((mPipeline == null) || (shaderVersion != mPipelineShaderVersion)
			|| (depthFormat != mPipelineDepthFormat))
		{
			if (mPipeline != null)
				mDevice.DestroyRenderPipeline(ref mPipeline);

			mPipeline = MakePipeline(depthFormat);
			mPipelineShaderVersion = shaderVersion;
			mPipelineDepthFormat = depthFormat;
		}

		if (mPipeline == null)
			return outputs;

		outputs.Normal = graph.CreateTransient("msaa.resolvedNormal",
			.(RenderFormats.GNormal, width, height));
		outputs.Velocity = graph.CreateTransient("msaa.resolvedVelocity",
			.(RenderFormats.GVelocity, width, height));
		outputs.Material = graph.CreateTransient("msaa.resolvedMaterial",
			.(RenderFormats.GMaterial, width, height));
		outputs.Depth = graph.CreateTransient("msaa.resolvedDepth", .(depthFormat, width, height));

		let resolved = outputs;
		graph.AddRenderPass("msaa.resolve", scope [&] (builder) =>
			{
				builder.SetColorTarget(0, resolved.Normal, .DontCare, .Store);
				builder.SetColorTarget(1, resolved.Velocity, .DontCare, .Store);
				builder.SetColorTarget(2, resolved.Material, .DontCare, .Store);
				// The depth is written wholly through the shader's own depth output, so
				// there is nothing worth loading.
				builder.SetDepthTarget(resolved.Depth, .DontCare, .Store);

				builder.ReadTexture(msaaNormal);
				builder.ReadTexture(msaaVelocity);
				builder.ReadTexture(msaaMaterial);
				builder.ReadTexture(msaaDepth);

				builder.SetViewport(0, 0, width, height);
				builder.NeverCull();

				builder.SetExecute(new [=] (encoder) =>
					{
						let bindGroup = EnsureBindGroup(graph.GetTextureView(msaaNormal),
							graph.GetTextureView(msaaVelocity), graph.GetTextureView(msaaMaterial),
							graph.GetTextureView(msaaDepth), graph.GetTextureGeneration(msaaDepth));
						if (bindGroup == null)
							return;

						encoder.SetPipeline(mPipeline);
						encoder.SetBindGroup(0, bindGroup);
						encoder.Draw(3, 1, 0, 0);
					});
			});

		return outputs;
	}

	private IRenderPipeline MakePipeline(TextureFormat depthFormat)
	{
		let vertex = mShaders.GetVariant("msaa_resolve", .Vertex, .None);
		let fragment = mShaders.GetVariant("msaa_resolve", .Fragment, .None);
		if ((vertex == null) || (fragment == null))
			return null;

		var targets = ColorTargetState[3]();
		targets[0].Format = RenderFormats.GNormal;
		targets[1].Format = RenderFormats.GVelocity;
		targets[2].Format = RenderFormats.GMaterial;

		var fragmentState = FragmentState();
		fragmentState.Shader = .(fragment, "main", .Fragment);
		fragmentState.Targets = .(&targets[0], 3);

		// The depth is written from the shader, and a backend gates that write on the depth
		// TEST being enabled, so the test is on and always passes: the target's previous
		// contents are irrelevant to a fullscreen overwrite.
		var depthStencil = DepthStencilState();
		depthStencil.Format = depthFormat;
		depthStencil.DepthTestEnabled = true;
		depthStencil.DepthWriteEnabled = true;
		depthStencil.DepthCompare = .Always;

		var desc = RenderPipelineDesc();
		desc.Layout = mPipelineLayout;
		desc.Vertex.Shader = .(vertex, "main", .Vertex);
		desc.Fragment = fragmentState;
		desc.DepthStencil = depthStencil;
		desc.Primitive.Topology = .TriangleList;
		desc.Primitive.CullMode = .None;
		// The OUTPUT is single sampled, whatever the inputs are.
		desc.Multisample.Count = 1;
		desc.Label = "msaa_resolve";

		if (!(mDevice.CreateRenderPipeline(desc) case .Ok(let pipeline)))
			return null;

		return pipeline;
	}

	private IBindGroup EnsureBindGroup(ITextureView normal, ITextureView velocity,
		ITextureView material, ITextureView depth, uint64 generation)
	{
		if ((normal == null) || (velocity == null) || (material == null) || (depth == null))
			return null;

		let key = (int)(void*)Internal.UnsafeCastToPtr(depth);
		if (mBindGroups.TryGetValue(key, var existing))
		{
			if ((existing.Generation == generation) && (existing.BindGroup != null))
				return existing.BindGroup;

			if (existing.BindGroup != null)
				mDevice.DestroyBindGroup(ref existing.BindGroup);
		}

		var entries = BindGroupEntry[4](
			BindGroupEntry.TextureEntry(normal),
			BindGroupEntry.TextureEntry(velocity),
			BindGroupEntry.TextureEntry(material),
			BindGroupEntry.TextureEntry(depth));

		var desc = BindGroupDesc();
		desc.Layout = mLayout;
		desc.Entries = .(&entries[0], 4);

		if (!(mDevice.CreateBindGroup(desc) case .Ok(let bindGroup)))
			return null;

		mBindGroups[key] = .() { BindGroup = bindGroup, Generation = generation };
		return bindGroup;
	}

	private void Shutdown()
	{
		if (mDevice == null)
			return;

		for (var entry in ref mBindGroups.Values)
		{
			if (entry.BindGroup != null)
				mDevice.DestroyBindGroup(ref entry.BindGroup);
		}
		mBindGroups.Clear();

		if (mPipeline != null)
			mDevice.DestroyRenderPipeline(ref mPipeline);
		if (mPipelineLayout != null)
			mDevice.DestroyPipelineLayout(ref mPipelineLayout);
		if (mLayout != null)
			mDevice.DestroyBindGroupLayout(ref mLayout);
	}
}
