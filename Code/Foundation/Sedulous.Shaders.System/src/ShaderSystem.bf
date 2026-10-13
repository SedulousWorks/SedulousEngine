using System;
using System.Collections;
using Sedulous.Core;
// NOT `using Sedulous.RHI`: its ShaderStage is a different type from this module's, and a
// blanket using makes every mention of the name ambiguous. The four RHI types are qualified
// instead, which is also what marks this file as the seam between the two.

namespace Sedulous.Shaders;

/// Compile on demand, then cache, per shader variant.
///
/// The layer above the stateless compiler that the material and pipeline layers build on.
/// It needs an RHI device to create modules, which is why it lives apart from the RHI free
/// shader module.
///
/// Two modes, and the SAME canonicalization in both:
///   development  a compiler and a source provider, compiling a variant on first request
///   shipped      a cooked pack, serving prebuilt blobs with no compiler at all
///
/// Dev and shipped must canonicalize identically or a build behaves differently from what
/// was tested, which is the whole reason the declared mask is carried in the pack.
class ShaderSystem
{
	private ShaderCompiler mCompiler;
	private Sedulous.RHI.IDevice mDevice;
	private IShaderSourceProvider mProvider = null;
	private CookedShaderPack mPack = null;

	/// A stage's source and the name of its function in it.
	private class Source
	{
		public String Hlsl = new .() ~ delete _;
		public String EntryPoint = new .() ~ delete _;
	}

	/// Name and stage to HLSL and entry point.
	private Dictionary<uint64, Source> mSources = new .() ~ DeleteDictionaryAndValues!(_);
	/// The declared mask per PROVIDER FETCHED source, which is the development half of the
	/// canonicalization contract. An explicitly registered source has no entry and compiles
	/// the raw flags.
	private Dictionary<uint64, ShaderFlags> mDeclaredMasks = new .() ~ delete _;
	/// Keys already complained about, so a per frame retry does not drown the log.
	private HashSet<uint64> mLoggedFailures = new HashSet<uint64>() ~ delete _;
	/// Variants that compiled and failed (see GetVariant); forgotten when the source changes.
	private HashSet<ShaderVariantKey> mFailedVariants = new .() ~ delete _;
	/// Variant to the GPU module it owns.
	private Dictionary<ShaderVariantKey, Sedulous.RHI.IShaderModule> mCache = new .() ~ delete _;
	private Dictionary<uint64, uint64> mVersions = new Dictionary<uint64, uint64>() ~ delete _;
	/// BORROWED from whoever set it, usually the file provider.
	private IShaderIncludeResolver mIncludeResolver = null;

	/// The DXC optimization level every on demand compile asks for. Three is what a build
	/// wants.
	///
	/// A test suite is the reason this is settable: optimization is most of what DXC spends
	/// its time on, and a test that only needs a module back gets it nearly three times
	/// sooner at zero. Nothing downstream of here reads the bytecode's quality.
	public int32 OptimizationLevel = 3;

	/// The compiler and the device are BORROWED and must outlive this.
	public this(ShaderCompiler compiler, Sedulous.RHI.IDevice device)
	{
		mCompiler = compiler;
		mDevice = device;
	}

	/// Compiler free construction, for a shipped build serving a pack.
	///
	/// The on demand compile path is then unavailable, and a registered source cannot be
	/// served: that is what "no compiler ships" means.
	public this(Sedulous.RHI.IDevice device)
	{
		mCompiler = null;
		mDevice = device;
	}

	public ~this()
	{
		DestroyAll();
	}

	public IShaderSourceProvider SourceProvider => mProvider;
	/// How many variants failed and wait for their source to change.
	public int FailedVariantCount => mFailedVariants.Count;
	public CookedShaderPack CookedPack => mPack;

	/// Registers a stage's HLSL, taking an owned copy, and the entry point that stage's
	/// function is called in it (one file may serve both stages as VSMain and PSMain).
	///
	/// With a declared variant mask (a cooked shader asset's lattice) requests canonicalize onto
	/// it, as the corpus's do; without one the RAW requested flags compile, every requested
	/// define applied. Registering forgets the shader's failed variants.
	public void RegisterSource(StringView name, ShaderStage stage, StringView hlsl, StringView entryPoint,
		ShaderFlags? declaredMask = null)
	{
		let key = SourceKey(name, stage);
		if (mSources.TryGetValue(key, let existing))
			delete existing;
		let source = new Source();
		source.Hlsl.Set(hlsl);
		source.EntryPoint.Set(entryPoint);
		mSources[key] = source;
		// Explicit registration overrides whatever a provider fetch had decided.
		if (declaredMask.HasValue)
			mDeclaredMasks[key] = declaredMask.Value;
		else
			mDeclaredMasks.Remove(key);
		ForgetFailures(ShaderFlagNames.ShaderNameHash(name));
	}

	/// The provider is BORROWED and may be null.
	public void SetSourceProvider(IShaderSourceProvider provider) => mProvider = provider;

	/// The cooked pack is BORROWED. Setting it puts this into shipped mode, where a request
	/// is canonicalized against the stage's declared mask and looked up rather than
	/// compiled, and a miss is a loud cook coverage bug.
	public void SetCookedPack(CookedShaderPack pack) => mPack = pack;

	/// Where a shared .hlsli is resolved from, BORROWED.
	///
	/// This replaces a list of native directories: the compiler asks the resolver rather than
	/// opening a path, so a corpus behind a mount or a pak serves includes the same way a
	/// directory does.
	public void SetIncludeResolver(IShaderIncludeResolver resolver) => mIncludeResolver = resolver;

	/// Asks the provider what changed, drops those sources and their variants, and bumps
	/// their versions so a pipeline cache rebuilds.
	///
	/// Call once per frame. Returns how many shaders reloaded.
	public int PumpReloads()
	{
		if (mProvider == null)
			return 0;

		let changed = scope List<String>();
		defer { ClearAndDeleteItems!(changed); }
		if (!mProvider.PollChanges(changed))
			return 0;

		for (let name in changed)
		{
			// Dropped rather than refetched here: the next request pulls it, so a shader
			// nothing asks for costs nothing to reload.
			RemoveSource(name);
			InvalidateShader(name);
		}
		// A registered shader (a project's) may include a changed library file; the provider
		// cannot say which, so every remembered failure gets another compile.
		mFailedVariants.Clear();
		return changed.Count;
	}

	/// Drops the cached source text for every stage of a shader.
	public void RemoveSource(StringView name)
	{
		ShaderStage[3] stages = .(.Vertex, .Fragment, .Compute);
		for (let stage in stages)
		{
			let key = SourceKey(name, stage);
			if (mSources.TryGetValue(key, let existing))
			{
				delete existing;
				mSources.Remove(key);
			}
			mDeclaredMasks.Remove(key);
		}
	}

	/// The GPU module for a variant, compiled or looked up on first request and cached.
	///
	/// Null when the source is unknown or the compile failed. A failed variant is remembered
	/// until its source changes (RegisterSource, InvalidateShader, a reload), so a broken shader
	/// is compiled and reported once, not every frame the renderer asks for it; fixing it and
	/// saving still works.
	public Sedulous.RHI.IShaderModule GetVariant(StringView name, ShaderStage stage, ShaderFlags flags)
	{
		if (mPack == null)
			return GetCompiledVariant(name, stage, flags);

		// A registered source (a project's shader, a bespoke inline one) compiles while a
		// compiler is here: the editor's source is newer than any pack. Without one (a shipped
		// build), or when the source is empty (an export stripped it and cooked the shader into
		// the pack instead: a dist's player can still carry a compiler, a dev build does), the
		// pack serves it like the corpus, with its entry points and lattices, and only a variant
		// it lacks is a loud miss.
		if ((mCompiler != null) && mSources.TryGetValue(SourceKey(name, stage), let registered) && !registered.Hlsl.IsEmpty)
			return GetCompiledVariant(name, stage, flags);
		return GetCookedVariant(name, stage, flags);
	}

	/// Destroys every cached variant of a shader and bumps its version, which is the reload
	/// signal a pipeline cache polls. Returns how many were dropped.
	public int InvalidateShader(StringView name)
	{
		let nameHash = ShaderFlagNames.ShaderNameHash(name);
		ForgetFailures(nameHash);

		let toRemove = scope List<ShaderVariantKey>();
		for (let pair in mCache)
		{
			if (pair.key.NameHash != nameHash)
				continue;
			if (pair.value != null)
			{
				var module = pair.value;
				mDevice.DestroyShaderModule(ref module);
			}
			toRemove.Add(pair.key);
		}
		for (let key in toRemove)
			mCache.Remove(key);

		BumpVersion(nameHash);
		return toRemove.Count;
	}

	/// A shader's monotonic version, bumped on each invalidation.
	///
	/// A pipeline cache stamps its pipelines with this and rebuilds when it changes. Zero
	/// for a shader never registered or invalidated.
	public uint64 Version(StringView name)
	{
		if (mVersions.TryGetValue(ShaderFlagNames.ShaderNameHash(name), let version))
			return version;
		return 0;
	}

	/// The blob format this device consumes.
	private CookedShaderFormat FormatForDevice()
		=> SelectCookedFormat(mDevice.PreferredShaderFormat);

	/// Maps the RHI's shader format onto the pack's.
	///
	/// The two enums are parallel but distinct, because the pack layer is RHI free. Pure, so
	/// the mapping is testable without a live device.
	public static CookedShaderFormat SelectCookedFormat(Sedulous.RHI.ShaderFormat format)
	{
		switch (format)
		{
		case .DXIL: return .Dxil;
		case .WGSL: return .Wgsl;
		case .SpirV: return .SpirV;
		}
	}

	/// The development path: resolve the source, canonicalize, compile, cache.
	///
	/// A provider fetched source is canonicalized against its declared mask EXACTLY as the
	/// cooked path does. That is what makes development and a shipped build agree, and it
	/// dedupes variants: a pixel shader that ignores SKINNED stops recompiling per skin.
	private Sedulous.RHI.IShaderModule GetCompiledVariant(StringView name, ShaderStage stage,
		ShaderFlags flags)
	{
		let sourceKey = SourceKey(name, stage);
		if (!mSources.ContainsKey(sourceKey))
		{
			if (!FetchFromProvider(name, stage, sourceKey))
				return null;
		}

		var canonical = flags;
		if (mDeclaredMasks.TryGetValue(sourceKey, let mask))
			canonical = ShaderVariants.CanonicalizeFlags(flags, mask);

		let key = ShaderVariantKey(ShaderFlagNames.ShaderNameHash(name), stage, canonical);
		if (mCache.TryGetValue(key, let cached))
			return cached;

		// A variant that failed waits for its source to change: compiled and reported once, not
		// every frame the renderer asks for it.
		if (mFailedVariants.Contains(key))
			return null;
		let source = mSources[sourceKey];
		let module = Compile(source.Hlsl, source.EntryPoint, stage, canonical);
		if (module == null)
		{
			mFailedVariants.Add(key);
			return null;
		}

		mCache[key] = module;
		return module;
	}

	private bool FetchFromProvider(StringView name, ShaderStage stage, uint64 sourceKey)
	{
		if (mProvider == null)
			return false;

		let fetched = new Source();
		if (!mProvider.FetchSource(name, stage, fetched.Hlsl, fetched.EntryPoint))
		{
			delete fetched;
			return false;
		}
		mSources[sourceKey] = fetched;

		// A corpus source carries the variant directive; absent means single variant, the
		// same rule the cook applies.
		let directive = ShaderVariants.ParseVariantDirective(fetched.Hlsl);
		mDeclaredMasks[sourceKey] = directive.Present ? directive.Mask : .None;
		return true;
	}

	/// The shipped path: canonicalize, look up the prebuilt blob, create the module.
	///
	/// Cached under the CANONICAL key, so requests differing only in ignored flags share one
	/// module.
	private Sedulous.RHI.IShaderModule GetCookedVariant(StringView name, ShaderStage stage, ShaderFlags flags)
	{
		let nameHash = ShaderFlagNames.ShaderNameHash(name);
		let canonical = ShaderVariants.CanonicalizeFlags(flags,
			mPack.DeclaredMask(nameHash, stage));

		let key = ShaderVariantKey(nameHash, stage, canonical);
		if (mCache.TryGetValue(key, let cached))
			return cached;

		let format = FormatForDevice();
		if (!(mPack.Find(nameHash, stage, canonical, format) case .Ok(let blob)))
		{
			ReportCookMiss(name, nameHash, stage, flags, canonical, format);
			return null;
		}

		// The entry the cook compiled this stage for; a pack without one predates entry names
		// (format 3) and is refused at load, so empty here is a cook bug.
		let entryPoint = mPack.EntryPoint(nameHash, stage);
		if (entryPoint.IsEmpty)
		{
			Console.Error.WriteLine(scope $"Sedulous.Shaders: cooked shader '{name}' stage {stage} has no entry point in the pack");
			return null;
		}

		var desc = Sedulous.RHI.ShaderModuleDesc();
		desc.Code = blob;
		desc.EntryPoint = entryPoint;
		if (!(mDevice.CreateShaderModule(desc) case .Ok(let module)))
			return null;

		mCache[key] = module;
		return module;
	}

	private Sedulous.RHI.IShaderModule Compile(StringView source, StringView entryPoint, ShaderStage stage,
		ShaderFlags flags)
	{
		// Compiler free pack mode: on demand compilation is simply unavailable.
		if (mCompiler == null)
			return null;

		let isDX12 = mDevice.Type == .DX12;
		let target = isDX12 ? ShaderTarget.DXIL : ShaderTarget.SPIRV;

		let defines = scope List<ShaderDefine>();
		ShaderFlagNames.AppendDefines(flags, defines);

		var options = CompileOptions();
		options.ShaderModel = "6_0";
		options.OptimizationLevel = OptimizationLevel;
		options.Defines = defines;
		options.IncludeResolver = mIncludeResolver;
		options.PreserveInterface = ShaderVariants.ParsePreserveInterfaceDirective(source);
		if (!isDX12)
		{
			// Vulkan and WebGPU: shift the register spaces so HLSL b, t, u and s registers
			// do not collide in SPIR-V.
			options.BindingShifts = BindingShifts.Standard;
			options.BindingShiftSets = 4;
			if (mDevice.Type == .WebGPU)
			{
				// naga rejects the SPIR-V 1.4 and later instructions a vulkan1.3 compile
				// emits.
				options.SpirvTargetEnvironment = "vulkan1.1";
			}
		}

		var compiled = mCompiler.Compile(.((uint8*)source.Ptr, source.Length), stage, entryPoint,
			target, options);
		defer compiled.Dispose();

		if (!compiled.Success)
		{
			if (!compiled.Messages.IsEmpty)
				Console.Error.WriteLine(scope $"Sedulous.Shaders: variant compile failed: {compiled.Messages}");
			return null;
		}

		var desc = Sedulous.RHI.ShaderModuleDesc();
		desc.Code = compiled.Bytecode;
		desc.EntryPoint = entryPoint;
		if (mDevice.CreateShaderModule(desc) case .Ok(let module))
			return module;
		return null;
	}

	/// Loud, but ONCE per variant: a pipeline layer retries every frame, and a full pack
	/// dump per frame would drown the log.
	private void ReportCookMiss(StringView name, uint64 nameHash, ShaderStage stage,
		ShaderFlags requested, ShaderFlags canonical, CookedShaderFormat format)
	{
		let missKey = (SourceKey(name, stage) &* FnvPrime) ^ ((uint64)canonical << 32);
		if (mLoggedFailures.Contains(missKey))
			return;
		mLoggedFailures.Add(missKey);

		let mask = mPack.DeclaredMask(nameHash, stage);
		Console.Error.WriteLine(scope $"Sedulous.Shaders: cooked variant missing from the pack, which is a cook coverage bug: '{name}' stage {stage} canonical flags {(uint32)canonical} (requested {(uint32)requested}, declared mask {(uint32)mask}, format {format})");

		// What the pack DID cook for this stage, so the gap shows its shape rather than
		// only its absence.
		mPack.ForEachVariant(nameHash, stage, scope (flags, cookedFormat) =>
			{
				Console.Error.WriteLine(scope $"    the pack has: flags {(uint32)flags} format {cookedFormat}");
			});
	}

	private void DestroyAll()
	{
		for (let pair in mCache)
		{
			if (pair.value != null)
			{
				var module = pair.value;
				mDevice.DestroyShaderModule(ref module);
			}
		}
		mCache.Clear();
	}

	/// Drops the remembered failures of a shader's variants: its source changed.
	private void ForgetFailures(uint64 nameHash)
	{
		let forget = scope List<ShaderVariantKey>();
		for (let key in mFailedVariants)
			if (key.NameHash == nameHash)
				forget.Add(key);
		for (let key in forget)
			mFailedVariants.Remove(key);
	}

	private static uint64 SourceKey(StringView name, ShaderStage stage)
		=> (ShaderFlagNames.ShaderNameHash(name) &* FnvPrime) ^ (uint64)stage;

	private void BumpVersion(uint64 nameHash)
	{
		if (mVersions.TryGetValue(nameHash, let version))
			mVersions[nameHash] = version + 1;
		else
			mVersions[nameHash] = 1;
	}
}
