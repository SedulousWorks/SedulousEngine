using System;
using Sedulous.Core;
using Sedulous.Materials;
using Sedulous.Materials.PipelineCache;
using Sedulous.RHI;
using Sedulous.RHI.Null;
using Sedulous.Shaders;

namespace Sedulous.Materials.PipelineCache.Tests;

/// A null device, a shader system fed from a COOKED PACK, a pipeline layout, and the cache.
///
/// The pack rather than a compiler, because nothing here is about compiling: the cache
/// wants a module to point at and a version to poll. Driving it this way also means the
/// tests run everywhere rather than only where a shader compiler happens to be installed.
class PipelineCacheFixture
{
	public IBackend Backend;
	public IDevice Device;
	public CookedShaderPack Pack = new .() ~ delete _;
	public ShaderSystem Shaders ~ delete _;
	public IPipelineLayout Layout;
	public PipelineStateCache Cache ~ delete _;

	public this()
	{
		Backend = NullRhi.CreateBackend();
		Device = Backend.EnumerateAdapters()[0].CreateDevice(.()).Value;

		Shaders = new ShaderSystem(Device);
		Shaders.SetCookedPack(Pack);

		Layout = Device.CreatePipelineLayout(.()).Value;
		Cache = new PipelineStateCache(Shaders, Device);
	}

	public ~this()
	{
		// The cache holds pipelines built on the device, and the system holds modules, so
		// both go before the device does.
		delete Cache;
		Cache = null;
		delete Shaders;
		Shaders = null;

		if (Layout != null)
			Device.DestroyPipelineLayout(ref Layout);
		if (Device != null)
			Device.Destroy();
		if (Backend != null)
		{
			Backend.Destroy();
			delete Backend;
		}
	}

	/// Puts a variant in the pack. The bytes are never executed: the null backend takes
	/// whatever it is handed, and the cache only needs a module to point at.
	public void Cook(StringView name, Sedulous.Shaders.ShaderStage stage,
		ShaderFlags flags = .None)
	{
		uint8[4] blob = .(1, 2, 3, 4);
		Pack.Add(name, stage, flags, ShaderSystem.SelectCookedFormat(Device.PreferredShaderFormat),
			.(&blob[0], 4));
	}

	/// The usual pair.
	public void CookBothStages(StringView name)
	{
		Cook(name, .Vertex);
		Cook(name, .Fragment);
	}
}
