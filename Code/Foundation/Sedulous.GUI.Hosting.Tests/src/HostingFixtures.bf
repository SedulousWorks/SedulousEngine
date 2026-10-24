using System;
using Sedulous.Core;
using Sedulous.GUI;
using Sedulous.RHI;
using Sedulous.RHI.Null;
using Sedulous.VG.SVG;

namespace Sedulous.GUI.Hosting.Tests;

/// What the hosting tests share: a Null device, shader modules of four dummy bytes (the Null
/// backend compiles nothing), and the pictures they bake.
static class HostingFixtures
{
	public const String cRedPicture = "<svg width='24' height='12'><rect width='24' height='12' fill='red'/></svg>";
	public const String cSquarePicture = "<svg width='8' height='8'><rect width='8' height='8'/></svg>";

	public static bool Near(float a, float b, float epsilon = 0.001f) => Math.Abs(a - b) <= epsilon;

	/// A module the caller destroys.
	public static IShaderModule MakeModule(IDevice device)
	{
		uint8[4] code = .(0, 0, 0, 0);
		var desc = ShaderModuleDesc();
		desc.Code = .(&code[0], 4);
		desc.EntryPoint = "main";
		if (device.CreateShaderModule(desc) case .Ok(let module))
			return module;
		return null;
	}

	/// A document the caller deletes.
	public static SVGDocument LoadPicture(StringView markup)
	{
		if (SVGLoader.Load(markup) case .Ok(let document))
			return document;
		return null;
	}
}

/// A Null backend and its device, the two VG shaders on it, and a command pool.
class NullRhiBed
{
	public IBackend Backend;
	public IDevice Device;
	public IShaderModule Vs;
	public IShaderModule Fs;
	public ICommandPool Pool;

	public this()
	{
		Backend = NullRhi.CreateBackend();
		Device = Backend.EnumerateAdapters()[0].CreateDevice(.()).Value;
		Vs = HostingFixtures.MakeModule(Device);
		Fs = HostingFixtures.MakeModule(Device);
		Pool = Device.CreateCommandPool(.Graphics).Value;
	}

	public ~this()
	{
		Device.DestroyCommandPool(ref Pool);
		Device.DestroyShaderModule(ref Fs);
		Device.DestroyShaderModule(ref Vs);
		Device.Destroy();
		Backend.Destroy();
		delete Backend;
	}

	/// The two shaders every draw needs.
	public VgShaderSet Shaders
	{
		get
		{
			var shaders = VgShaderSet();
			shaders.Vertex = Vs;
			shaders.Fragment = Fs;
			return shaders;
		}
	}

	/// An encoder on the pool, for Done.
	public ICommandEncoder Encoder()
	{
		return Pool.CreateEncoder().Value;
	}

	public void Done(ICommandEncoder encoder)
	{
		encoder.Finish();
		var made = encoder;
		Pool.DestroyEncoder(ref made);
	}
}
