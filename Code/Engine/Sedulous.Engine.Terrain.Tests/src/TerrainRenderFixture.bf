using System;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.RHI;
using Sedulous.RHI.Null;
using Sedulous.Shaders;

namespace Sedulous.Engine.Terrain.Tests;

/// A null device, a colour target, an encoder, and the REAL shader compiler over the engine's
/// own terrain shaders.
///
/// The point is that the draw path is exercised end to end: nothing here checks what a shader
/// computes, but the renderer emits no draws at all without a pipeline, and there is no
/// pipeline without the shaders having built.
///
/// The shaders are found by WALKING UP from the working directory, a Beef workspace having no
/// compiled in source root.
class TerrainRenderFixture
{
	public IBackend Backend;
	public IDevice Device;
	public ShaderCompiler Compiler ~ delete _;
	public FileShaderSourceProvider Provider ~ delete _;
	public ShaderSystem Shaders ~ delete _;

	public ITexture Color;
	public ITextureView ColorView;
	public ICommandPool Pool;
	public ICommandEncoder Encoder;

	/// False when this checkout has no shader directory, which is the one thing that makes
	/// these unrunnable rather than failing.
	public bool Ready { get; private set; }

	public this(uint32 width = 256, uint32 height = 256)
	{
		Backend = NullRhi.CreateBackend();
		Device = Backend.EnumerateAdapters()[0].CreateDevice(.()).Value;

		var desc = TextureDesc.RenderTarget(.BGRA8Unorm, width, height, 1, "terrain.test.color");
		Color = Device.CreateTexture(desc).Value;

		var viewDesc = TextureViewDesc();
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
		// Nothing here reads the bytecode's quality, and optimization is most of what the
		// compiler spends its time on.
		Shaders.OptimizationLevel = 0;
		Shaders.SetSourceProvider(Provider);
		let includePaths = scope StringView[1](root);
		Shaders.SetIncludePaths(includePaths);

		Ready = true;
	}

	public ~this()
	{
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
