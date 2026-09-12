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

	/// Name and stage to HLSL.
	private Dictionary<uint64, String> mSources = new Dictionary<uint64, String>()
		~ DeleteDictionaryAndValues!(_);
	/// The declared mask per PROVIDER FETCHED source, which is the development half of the
	/// canonicalization contract. An explicitly registered source has no entry and compiles
	/// the raw flags.
	private Dictionary<uint64, ShaderFlags> mDeclaredMasks = new .() ~ delete _;
	/// Keys already complained about, so a per frame retry does not drown the log.
	private HashSet<uint64> mLoggedFailures = new HashSet<uint64>() ~ delete _;
	/// Variant to the GPU module it owns.
	private Dictionary<ShaderVariantKey, Sedulous.RHI.IShaderModule> mCache = new .() ~ delete _;
	private Dictionary<uint64, uint64> mVersions = new Dictionary<uint64, uint64>() ~ delete _;
	private List<String> mIncludePaths = new List<String>() ~ DeleteContainerAndItems!(_);

	/// The DXC optimization level every on demand compile asks for. Three is what Raptor
	/// compiles at and what a build wants.
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
	public CookedShaderPack CookedPack => mPack;

	/// Registers a stage's HLSL, taking an owned copy.
	///
	/// An explicitly registered source is compiled with the RAW requested flags. It sits
	/// outside the corpus lattice by definition, so there is no declared mask to intersect
	/// with and every requested define is applied.
	public void RegisterSource(StringView name, ShaderStage stage, StringView hlsl)
	{
		let key = SourceKey(name, stage);
		if (mSources.TryGetValue(key, let existing))
			delete existing;
		mSources[key] = new String(hlsl);
		// Explicit registration overrides whatever a provider fetch had decided.
		mDeclaredMasks.Remove(key);
	}

	/// The provider is BORROWED and may be null.
	public void SetSourceProvider(IShaderSourceProvider provider) => mProvider = provider;

	/// The cooked pack is BORROWED. Setting it puts this into shipped mode, where a request
	/// is canonicalized against the stage's declared mask and looked up rather than
	/// compiled, and a miss is a loud cook coverage bug.
	public void SetCookedPack(CookedShaderPack pack) => mPack = pack;

	/// The include search paths for resolving a shared .hlsli, copied.
	public void SetIncludePaths(Span<StringView> paths)
	{
		ClearAndDeleteItems!(mIncludePaths);
		for (let path in paths)
			mIncludePaths.Add(new String(path));
	}

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
	/// Null when the source is unknown or the compile failed. A FAILURE IS NOT CACHED, so a
	/// later request retries, which is what makes fixing a shader and saving it work.
	public Sedulous.RHI.IShaderModule GetVariant(StringView name, ShaderStage stage, ShaderFlags flags)
	{
		if (mPack == null)
			return GetCompiledVariant(name, stage, flags);

		// An explicitly registered source beats the pack. The engine pack covers the engine
		// corpus, while registered sources carry bespoke inline shaders and user shader
		// assets, and those must keep resolving in pack mode or a custom material shader
		// dies in a shipped build.
		if (mSources.ContainsKey(SourceKey(name, stage)))
		{
			if (mCompiler != null)
				return GetCompiledVariant(name, stage, flags);

			ReportRegisteredSourceInPackMode(name, stage);
			return null;
		}
		return GetCookedVariant(name, stage, flags);
	}

	/// Destroys every cached variant of a shader and bumps its version, which is the reload
	/// signal a pipeline cache polls. Returns how many were dropped.
	public int InvalidateShader(StringView name)
	{
		let nameHash = ShaderFlagNames.ShaderNameHash(name);

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

		let module = Compile(mSources[sourceKey], stage, canonical);
		if (module == null)
			return null;

		mCache[key] = module;
		return module;
	}

	private bool FetchFromProvider(StringView name, ShaderStage stage, uint64 sourceKey)
	{
		if (mProvider == null)
			return false;

		let fetched = new String();
		if (!mProvider.FetchSource(name, stage, fetched))
		{
			delete fetched;
			return false;
		}
		mSources[sourceKey] = fetched;

		// A corpus source carries the variant directive; absent means single variant, the
		// same rule the cook applies.
		let directive = ShaderVariants.ParseVariantDirective(fetched);
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

		var desc = Sedulous.RHI.ShaderModuleDesc();
		desc.Code = blob;
		if (!(mDevice.CreateShaderModule(desc) case .Ok(let module)))
			return null;

		mCache[key] = module;
		return module;
	}

	private Sedulous.RHI.IShaderModule Compile(StringView source, ShaderStage stage, ShaderFlags flags)
	{
		// Compiler free pack mode: on demand compilation is simply unavailable.
		if (mCompiler == null)
			return null;

		let isDX12 = mDevice.Type == .DX12;
		let target = isDX12 ? ShaderTarget.DXIL : ShaderTarget.SPIRV;

		let defines = scope List<ShaderDefine>();
		ShaderFlagNames.AppendDefines(flags, defines);

		let includeViews = scope List<StringView>();
		for (let path in mIncludePaths)
			includeViews.Add(path);

		var options = CompileOptions();
		options.ShaderModel = "6_0";
		options.OptimizationLevel = OptimizationLevel;
		options.Defines = defines;
		options.IncludePaths = includeViews;
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

		var compiled = mCompiler.Compile(.((uint8*)source.Ptr, source.Length), stage, "main",
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

	private void ReportRegisteredSourceInPackMode(StringView name, ShaderStage stage)
	{
		let key = SourceKey(name, stage);
		if (mLoggedFailures.Contains(key))
			return;
		mLoggedFailures.Add(key);
		Console.Error.WriteLine(scope $"Sedulous.Shaders: registered source '{name}' stage {stage} cannot be compiled in compiler free pack mode; cook it to bytecode or ship a compiler");
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
