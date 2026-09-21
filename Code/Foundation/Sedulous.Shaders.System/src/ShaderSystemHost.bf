using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.VFS;

namespace Sedulous.Shaders;

/// Builds and owns a ready to use ShaderSystem for a device.
///
/// This exists so the pack versus development decision is made ONCE, in one place, and every
/// consumer resolves shaders the same way. The two modes:
///
///   development  DXC plus a file provider over the data mount's Shaders folder, compiling
///                on demand with hot reload
///   shipped      the cooked Shaders/shaders.dpak read from that same mount, prebuilt blobs
///                in the device's format, no compiler at all
///
/// BOTH read through the application's data mount and nothing else. There is no probing
/// beside the executable and none of the working directory: the application resolves the
/// data root once and hands the mount down.
///
/// DEVELOPMENT WINS whenever both a compiler and a source root exist. A stray pack next to
/// the binaries must never quietly take over a working development setup, because that kills
/// hot reload with one log line and nothing else. Losing it has to be a choice.
class ShaderSystemHost
{
	/// The layout under the data root, spelled once.
	public const String cShaderFolder = "Shaders";
	public const String cShaderPackFile = "shaders.dpak";
	public const String cShaderPackPath = "Shaders/shaders.dpak";

	/// Set in the environment to test a shipped configuration on a development machine.
	private const String cPackEnvironmentVariable = "OPTION_USE_SHADER_PACK";

	private ShaderCompiler mCompiler = null ~ delete _;
	private CookedShaderPack mPack = null ~ delete _;
	private FileShaderSourceProvider mProvider = null ~ delete _;
	private ShaderSystem mShaders = null ~ delete _;
	/// BORROWED: the application owns the data mount and outlives this.
	private IFileSystem mDataFileSystem = null;

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

	/// Builds the shader system for a device from the application's data mount, BORROWED for
	/// the host's lifetime.
	///
	/// Returns an error only when NEITHER a compiler nor a pack is available, since nothing
	/// could then resolve a shader.
	public Result<void> Initialize(Sedulous.RHI.IDevice device, IFileSystem dataFileSystem,
		ShaderPackPolicy policy = .Automatic)
	{
		// DXC is OPTIONAL: it is only needed in development. A shipped build with a cooked
		// pack renders with no compiler at all.
		let compiler = new ShaderCompiler();
		if (compiler.Initialize() case .Err)
			delete compiler;
		else
			mCompiler = compiler;

		mDataFileSystem = dataFileSystem;

		// Sources present means stage files, not the folder: a dist stages ONLY the cooked
		// pack under Shaders/, and an editor dist ships DXC too, so judging by the folder alone
		// put that dist in development mode over an empty corpus.
		let haveSources = (dataFileSystem != null) && HasShaderSources(dataFileSystem);
		let devPossible = (mCompiler != null) && haveSources;
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
			Console.Error.WriteLine(scope $"Sedulous.Shaders: pack mode was requested but no usable {cShaderPackPath} was found in the data root, so this falls back to compiling on demand");
		}
		AttachFileProvider();
		return .Ok;
	}

	/// True when Shaders/ holds at least one .hlsl stage file or .hlsli include, the
	/// development corpus; false for a missing folder or one holding only the cooked pack.
	private static bool HasShaderSources(IFileSystem dataFileSystem)
	{
		if (!dataFileSystem.Exists(cShaderFolder))
			return false;
		let enumerable = dataFileSystem as IEnumerableFileSystem;
		if (enumerable == null)
			return true; // a mount that cannot list: the folder is the only evidence

		let entries = scope List<DirEntry>();
		defer
		{
			for (var entry in ref entries)
				entry.Dispose();
		}
		if (enumerable.Enumerate(cShaderFolder, entries) case .Err)
			return false;
		for (let entry in entries)
		{
			if (entry.IsDirectory)
				continue;
			if (entry.Name.EndsWith(".hlsl") || entry.Name.EndsWith(".hlsli"))
				return true;
		}
		return false;
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

	private void AttachFileProvider()
	{
		let provider = new FileShaderSourceProvider();
		if ((mDataFileSystem == null)
			|| (provider.Initialize(mDataFileSystem, cShaderFolder) case .Err))
		{
			// No source folder: only an explicit RegisterSource will resolve anything.
			delete provider;
			Console.Error.WriteLine(scope $"Sedulous.Shaders: no {cShaderFolder} folder in the data root, so only explicitly registered shaders will resolve");
			return;
		}

		mProvider = provider;
		mShaders.SetSourceProvider(mProvider);
		// The provider is the include resolver too, so an #include is read back through the
		// same mount the sources came from.
		mShaders.SetIncludeResolver(mProvider);
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

	/// Reads the cooked pack from the data mount, and from nowhere else.
	///
	/// No probing beside the executable and none of the working directory: a dist stages its
	/// pack inside its own data root, so the mount is the only place it can be.
	private bool LoadPack()
	{
		if ((mDataFileSystem == null) || !mDataFileSystem.Exists(cShaderPackPath))
			return false;

		{
			let stream = mDataFileSystem.Open(cShaderPackPath, .Read);
			if (stream == null)
				return false;
			defer delete stream;

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
