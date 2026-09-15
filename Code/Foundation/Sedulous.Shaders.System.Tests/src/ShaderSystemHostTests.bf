using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VFS;
using Sedulous.Core.IO;
using Sedulous.RHI;
using Sedulous.RHI.Null;
using Sedulous.Shaders;

namespace Sedulous.Shaders.System.Tests;

/// The one place that decides between compiling on demand and serving a cooked pack.
class ShaderSystemHostTests
{
	/// A scratch DATA ROOT: the host reads its corpus from the mount's Shaders folder, the
	/// same layout a checkout and a dist both have, so the fixture builds that rather than
	/// dropping the file at the mount's top level.
	private static void MakeRoot(StringView name, String outPath)
	{
		global::System.IO.Path.GetTempPath(outPath).IgnoreError();
		outPath.AppendF("sedulous_host_{}", name);
		RemoveDirectoryRecursive(outPath);
		CreateDirectory(outPath);

		let shaderDir = PathJoin(outPath, ShaderSystemHost.cShaderFolder, .. scope String());
		CreateDirectory(shaderDir);

		let path = PathJoin(shaderDir, "hosted.ps.hlsl", .. scope String());
		let source = "float4 main() : SV_Target0 { return float4(1, 1, 1, 1); }\n";
		WriteFile(path, .((uint8*)source.Ptr, source.Length)).IgnoreError();
	}

	private static IDevice MakeDevice(IBackend* outBackend)
	{
		let backend = NullRhi.CreateBackend();
		*outBackend = backend;
		let adapters = backend.EnumerateAdapters();
		if (adapters.IsEmpty)
			return null;
		if (adapters[0].CreateDevice(.()) case .Ok(let device))
			return device;
		return null;
	}

	private static bool HaveDxc()
	{
		let compiler = scope Sedulous.Shaders.ShaderCompiler();
		return compiler.Initialize() case .Ok;
	}

	/// With a compiler and a source root, the host compiles on demand.
	///
	/// This is the DEV FIRST rule: hot reload is the payoff for having a source tree, and
	/// losing it must be a deliberate choice rather than a side effect of a file being
	/// nearby.
	[Test]
	public static void DevelopmentWinsWhenBothAreAvailable()
	{
		if (!HaveDxc()) { Console.WriteLine("SKIP: no DXC runtime"); return; }

		let root = MakeRoot("dev", .. scope String());
		defer { RemoveDirectoryRecursive(root); }

		IBackend backend = null;
		let device = MakeDevice(&backend);
		Test.Assert(device != null);
		defer
		{
			device.Destroy();
			backend.Destroy();
			delete backend;
		}

		let host = scope ShaderSystemHost();
		Test.Assert(host.Initialize(device, scope NativeFileSystem(root)) case .Ok);
		Test.Assert(host.IsReady);
		Test.Assert(!host.UsingPack, "a source root means compiling on demand");
		Test.Assert(host.PackVariantCount == 0);

		// The provider was attached, so a shader nothing registered still resolves.
		Test.Assert(host.GetVariant("hosted", .Fragment, .None) != null);
	}

	/// Forcing pack mode with no pack present falls back to compiling rather than failing:
	/// a request to use a pack that does not exist should not take the renderer down.
	[Test]
	public static void ForcingPackWithoutOneFallsBackToCompiling()
	{
		if (!HaveDxc()) { Console.WriteLine("SKIP: no DXC runtime"); return; }

		let root = MakeRoot("forcepack", .. scope String());
		defer { RemoveDirectoryRecursive(root); }

		IBackend backend = null;
		let device = MakeDevice(&backend);
		Test.Assert(device != null);
		defer
		{
			device.Destroy();
			backend.Destroy();
			delete backend;
		}

		let host = scope ShaderSystemHost();
		Test.Assert(host.Initialize(device, scope NativeFileSystem(root), .ForcePack) case .Ok);
		Test.Assert(host.IsReady);
		Test.Assert(!host.UsingPack, "there was no pack to use");
		Test.Assert(host.GetVariant("hosted", .Fragment, .None) != null,
			"and the shader still resolves");
	}

	/// With no source root the host is still ready, because explicitly registered shaders
	/// remain a supported configuration, but nothing resolves from files.
	[Test]
	public static void AMissingRootLeavesOnlyRegisteredShaders()
	{
		if (!HaveDxc()) { Console.WriteLine("SKIP: no DXC runtime"); return; }

		IBackend backend = null;
		let device = MakeDevice(&backend);
		Test.Assert(device != null);
		defer
		{
			device.Destroy();
			backend.Destroy();
			delete backend;
		}

		let host = scope ShaderSystemHost();
		Test.Assert(host.Initialize(device, scope NativeFileSystem("/no/such/shader/root"), .ForceDev) case .Ok);
		Test.Assert(host.IsReady, "a compiler alone is enough to be ready");
		Test.Assert(!host.UsingPack);
		Test.Assert(host.GetVariant("hosted", .Fragment, .None) == null,
			"but nothing resolves from files");

		host.System.RegisterSource("inline", .Fragment,
			"float4 main() : SV_Target0 { return 0; }");
		Test.Assert(host.GetVariant("inline", .Fragment, .None) != null,
			"while a registered source still works");
	}

	/// Shutdown is idempotent and leaves nothing ready, which is what a second call during
	/// teardown must not turn into a double free.
	[Test]
	public static void ShutdownIsIdempotent()
	{
		if (!HaveDxc()) { Console.WriteLine("SKIP: no DXC runtime"); return; }

		let root = MakeRoot("shutdown", .. scope String());
		defer { RemoveDirectoryRecursive(root); }

		IBackend backend = null;
		let device = MakeDevice(&backend);
		Test.Assert(device != null);
		defer
		{
			device.Destroy();
			backend.Destroy();
			delete backend;
		}

		let host = scope ShaderSystemHost();
		Test.Assert(host.Initialize(device, scope NativeFileSystem(root)) case .Ok);
		Test.Assert(host.IsReady);

		host.Shutdown();
		Test.Assert(!host.IsReady);
		Test.Assert(host.GetVariant("hosted", .Fragment, .None) == null);

		host.Shutdown();
		Test.Assert(!host.IsReady, "a second shutdown changes nothing");
	}
}
