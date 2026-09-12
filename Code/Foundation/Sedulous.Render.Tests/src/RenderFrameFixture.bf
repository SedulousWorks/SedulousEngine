using System;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Materials;
using Sedulous.Materials.PipelineCache;
using Sedulous.RHI;
using Sedulous.RHI.Null;
using Sedulous.Render;
using Sedulous.Shaders;

namespace Sedulous.Render.Tests;

/// A NULL DEVICE, the real shader compiler over the engine's own shaders, and a frame driver
/// brought up on them.
///
/// The point is the whole dispatch path: extraction, the sort, the mesh upload, the pipeline
/// build, the graph's declaration and its execution. Nothing here checks what a shader
/// computes; it checks that the passes are declared and the pipelines built at all, which is
/// exactly what a null device can answer and a data layer test cannot.
///
/// The shaders are found by WALKING UP from the working directory, the same way the sample
/// does: a Beef workspace has no compiled in source root, and the tests run from the
/// workspace root or from the build output.
class RenderFrameFixture
{
	public IBackend Backend;
	public IDevice Device;
	public ShaderCompiler Compiler ~ delete _;
	public FileShaderSourceProvider Provider ~ delete _;
	public ShaderSystem Shaders ~ delete _;
	public PipelineStateCache PsoCache ~ delete _;
	public MaterialSystem Materials ~ delete _;

	public ITexture Color;
	public ITextureView ColorView;
	public ICommandPool Pool;
	public ICommandEncoder Encoder;

	/// False when this checkout has no shader directory, which is the one thing that makes
	/// the frame tests unrunnable rather than failing.
	public bool Ready { get; private set; }

	public this(uint32 width = 128, uint32 height = 128, uint32 framesInFlight = 2)
	{
		Backend = NullRhi.CreateBackend();
		Device = Backend.EnumerateAdapters()[0].CreateDevice(.()).Value;

		var desc = TextureDesc.RenderTarget(.BGRA8Unorm, width, height, 1, "test.color");
		desc.Label = "RenderFrameFixture.this";
		Color = Device.CreateTexture(desc).Value;

		var viewDesc = TextureViewDesc();
		viewDesc.Label = "RenderFrameFixture.this";
		viewDesc.Format = .BGRA8Unorm;
		ColorView = Device.CreateTextureView(Color, viewDesc).Value;

		Pool = Device.CreateCommandPool(.Graphics).Value;
		Encoder = Pool.CreateEncoder().Value;

		Compiler = new ShaderCompiler();
		if (Compiler.Initialize() case .Err)
			return;

		let root = scope String();
		if (!FindShaderRoot(root))
			return;

		Provider = new FileShaderSourceProvider();
		if (Provider.Initialize(root) case .Err)
			return;

		Shaders = new ShaderSystem(Compiler, Device);
		Shaders.SetSourceProvider(Provider);
		let includePaths = scope StringView[1](root);
		Shaders.SetIncludePaths(includePaths);

		PsoCache = new PipelineStateCache(Shaders, Device);
		Materials = new MaterialSystem();
		if (Materials.Initialize(Device) case .Err)
			return;

		Ready = true;
	}

	public ~this()
	{
		// The material system holds groups built on the device, so it goes before the device.
		if (Materials != null)
		{
			delete Materials;
			Materials = null;
		}
		if (PsoCache != null)
		{
			delete PsoCache;
			PsoCache = null;
		}
		if (Shaders != null)
		{
			delete Shaders;
			Shaders = null;
		}

		if (Encoder != null)
			Pool.DestroyEncoder(ref Encoder);
		if (Pool != null)
			Device.DestroyCommandPool(ref Pool);
		if (ColorView != null)
			Device.DestroyTextureView(ref ColorView);
		if (Color != null)
			Device.DestroyTexture(ref Color);

		if (Device != null)
			Device.Destroy();
		if (Backend != null)
		{
			Backend.Destroy();
			delete Backend;
		}
	}

	/// A camera looking at the origin from a few units back, which frames a unit cube.
	public static ViewCamera LookingAtTheOrigin(float distance = 5.0f)
	{
		var camera = ViewCamera();
		camera.View = Float4x4.LookAtRH(.(0, 0, distance), .(0, 0, 0), .(0, 1, 0));
		camera.Projection = Float4x4.PerspectiveFovRH(1.0472f, 1.0f, 0.1f, 100.0f);
		camera.Position = .(0, 0, distance);
		camera.FarZ = 100.0f;
		return camera;
	}

	private static bool FindShaderRoot(String outPath)
	{
		let current = scope String();
		GetCurrentDirectory(current);

		for (int depth < 8)
		{
			let candidate = scope:: String();
			PathJoin(current, "Data/Shaders", candidate);
			if (Directory.Exists(candidate))
			{
				outPath.Set(candidate);
				return true;
			}

			let parent = scope:: String();
			PathParent(current, parent);
			if (parent.IsEmpty || (parent == current))
				break;
			current.Set(parent);
		}
		return false;
	}
}
