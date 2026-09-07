using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;

namespace Sedulous.Shaders;

/// Builds and owns a ready to use ShaderSystem for a device.
///
/// This exists so the pack versus development decision is made ONCE, in one place, and every
/// consumer resolves shaders the same way. The two modes:
///
///   development  DXC plus a file provider over the shader root, compiling on demand with
///                hot reload
///   shipped      a cooked pack beside the executable, prebuilt blobs in the device's
///                format, no compiler at all
///
/// DEVELOPMENT WINS whenever both a compiler and a source root exist. A stray pack next to
/// the binaries must never quietly take over a working development setup, because that kills
/// hot reload with one log line and nothing else. Losing it has to be a choice.
class ShaderSystemHost
{
	private const String cPackFileName = "shaders.dpak";
	/// Set in the environment to test a shipped configuration on a development machine.
	private const String cPackEnvironmentVariable = "OPTION_USE_SHADER_PACK";

	private ShaderCompiler mCompiler = null ~ delete _;
	private CookedShaderPack mPack = null ~ delete _;
	private FileShaderSourceProvider mProvider = null ~ delete _;
	private ShaderSystem mShaders = null ~ delete _;

	public ~this()
	{
		Shutdown();
	}

	public ShaderSystem System => mShaders;
	public bool IsReady => mShaders != null;
	/// Whether prebuilt blobs are being served rather than compiled on demand.
	public bool UsingPack => mPack != null;
	/// The cooked variant count in pack mode, zero otherwise. For diagnostics.
	public int PackVariantCount => (mPack != null) ? mPack.Count : 0;

	/// Builds the shader system for a device.
	///
	/// `engineShaderRoot` is the development HLSL source root. Returns an error only when
	/// NEITHER a compiler nor a pack is available, since nothing could then resolve a
	/// shader.
	public Result<void> Initialize(Sedulous.RHI.IDevice device, StringView engineShaderRoot,
		ShaderPackPolicy policy = .Automatic)
	{
		// DXC is OPTIONAL: it is only needed in development. A shipped build with a cooked
		// pack renders with no compiler at all.
		let compiler = new ShaderCompiler();
		if (compiler.Initialize() case .Err)
			delete compiler;
		else
			mCompiler = compiler;

		let root = scope String(engineShaderRoot);
		if (!DirectoryExists(root) && DirectoryExists("Shaders"))
			root.Set("Shaders"); // a relocated build, where the shipped layout applies

		let devPossible = (mCompiler != null) && DirectoryExists(root);
		let wantPack = WantPack(policy, devPossible);
		let havePack = wantPack && LoadPack();

		if ((mCompiler == null) && !havePack)
			return .Err;

		mShaders = (mCompiler != null) ? new ShaderSystem(mCompiler, device)
			: new ShaderSystem(device);

		if (havePack)
		{
			mShaders.SetCookedPack(mPack);
			Console.WriteLine(scope $"Sedulous.Shaders: cooked pack with {mPack.Count} variants{(mCompiler != null) ? ", and registered sources still compile" : ""}");
			return .Ok;
		}

		if (wantPack)
		{
			Console.Error.WriteLine("Sedulous.Shaders: pack mode was requested but no usable shaders.dpak was found, so this falls back to compiling on demand");
		}
		AttachFileProvider(root);
		return .Ok;
	}

	private bool WantPack(ShaderPackPolicy policy, bool devPossible)
	{
		switch (policy)
		{
		case .ForcePack:
			return true;
		case .ForceDev:
			return false;
		case .Automatic:
			if (!devPossible)
				return true;
			// Development works, so only an explicit environment override chooses the pack.
			// An unset variable is an error rather than an empty string, so the failure IS
			// the answer here.
			let value = scope String();
			if (Environment.GetEnvironmentVariable(cPackEnvironmentVariable, value) case .Err)
				return false;
			return !value.IsEmpty;
		}
	}

	private void AttachFileProvider(StringView root)
	{
		let provider = new FileShaderSourceProvider();
		if (provider.Initialize(root) case .Err)
		{
			// No source root: only an explicit RegisterSource will resolve anything.
			delete provider;
			Console.Error.WriteLine(scope $"Sedulous.Shaders: the shader root '{root}' was not found, so only explicitly registered shaders will resolve");
			return;
		}

		mProvider = provider;
		mShaders.SetSourceProvider(mProvider);
		StringView[1] includePaths = .(mProvider.RootDirectory);
		mShaders.SetIncludePaths(includePaths);
	}

	/// Resolves a variant to a GPU module, or null when nothing is ready.
	public Sedulous.RHI.IShaderModule GetVariant(StringView name, ShaderStage stage,
		ShaderFlags flags)
	{
		if (mShaders == null)
			return null;
		return mShaders.GetVariant(name, stage, flags);
	}

	public void Shutdown()
	{
		// The shader system goes FIRST: it owns the cached GPU modules and destroys them
		// through the device, which must still be alive.
		delete mShaders;
		mShaders = null;
		delete mProvider;
		mProvider = null;
		delete mPack;
		mPack = null;
		delete mCompiler;
		mCompiler = null;
	}

	/// Looks for the pack beside the executable, then in the working directory.
	///
	/// Beside the executable first because that is what survives a relocated build.
	private bool LoadPack()
	{
		let candidates = scope List<String>();
		defer { ClearAndDeleteItems!(candidates); }

		let executableDirectory = scope String();
		GetExecutableDirectory(executableDirectory);
		if (!executableDirectory.IsEmpty)
			candidates.Add(PathJoin(executableDirectory, cPackFileName, .. new String()));
		candidates.Add(new String(cPackFileName));

		for (let path in candidates)
		{
			if (!FileExists(path))
				continue;

			let stream = scope FileStream(path, .Read);
			if (!stream.IsValid)
				continue;

			let pack = new CookedShaderPack();
			// An empty pack is treated as no pack: it would resolve nothing, and falling
			// back to development is better than failing every lookup.
			if ((pack.Read(stream) case .Ok) && !pack.IsEmpty)
			{
				mPack = pack;
				return true;
			}
			delete pack;
		}
		return false;
	}
}
