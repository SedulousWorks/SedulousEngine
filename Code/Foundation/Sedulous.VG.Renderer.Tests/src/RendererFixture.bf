using System;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.RHI.Null;
using Sedulous.VG.Renderer;

namespace Sedulous.VG.Renderer.Tests;

/// A null device, two shader modules, and a renderer brought up on them.
///
/// The modules carry no real code: the null backend takes whatever it is handed, and every
/// decision under test is about which pipeline and bind group a command picks rather than
/// about what a shader computes.
class RendererFixture
{
	public IBackend Backend;
	public IDevice Device;
	public IShaderModule VertexShader;
	public IShaderModule FragmentShader;
	public IShaderModule DistanceFieldShader;
	public IShaderModule GradRadialShader;
	public IShaderModule GradConicShader;
	public VGRenderer Renderer = new .() ~ delete _;

	public const int32 FrameCount = 2;

	public this(bool withStencil = false, bool withOptionalShaders = false)
	{
		Backend = NullRhi.CreateBackend();
		Device = Backend.EnumerateAdapters()[0].CreateDevice(.()).Value;

		VertexShader = CreateModule();
		FragmentShader = CreateModule();

		if (withOptionalShaders)
		{
			DistanceFieldShader = CreateModule();
			GradRadialShader = CreateModule();
			GradConicShader = CreateModule();
		}

		var config = VGTargetConfig();
		if (withStencil)
			config.DepthStencilFormat = VGRenderer.PickStencilCapableFormat(Device, 1);

		Test.Assert(Renderer.Initialize(Device, VertexShader, FragmentShader, .BGRA8Unorm,
			FrameCount, DistanceFieldShader, GradRadialShader, GradConicShader, config) case .Ok);
	}

	private IShaderModule CreateModule()
	{
		uint8[4] code = .(1, 2, 3, 4);
		var desc = ShaderModuleDesc();
		desc.Code = .(&code[0], 4);
		return Device.CreateShaderModule(desc).Value;
	}

	public ~this()
	{
		// The renderer holds pipelines and buffers built on the device, so it goes first.
		delete Renderer;
		Renderer = null;

		DestroyModule(ref GradConicShader);
		DestroyModule(ref GradRadialShader);
		DestroyModule(ref DistanceFieldShader);
		DestroyModule(ref FragmentShader);
		DestroyModule(ref VertexShader);

		if (Device != null)
			Device.Destroy();
		if (Backend != null)
			Backend.Destroy();
	}

	private void DestroyModule(ref IShaderModule module)
	{
		if (module != null)
			Device.DestroyShaderModule(ref module);
		module = null;
	}
}
