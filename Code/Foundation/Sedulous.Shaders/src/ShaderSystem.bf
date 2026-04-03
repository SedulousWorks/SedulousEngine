namespace Sedulous.Shaders;

using System;
using System.IO;
using System.Collections;
using Sedulous.RHI;

/// Main shader system facade.
/// Handles shader loading, compilation, and caching.
/// Three-tier lookup: memory cache → disk cache → compile from source.
class ShaderSystem : IDisposable
{
	private ShaderCompiler mCompiler ~ delete _;
	private ShaderCache mCache ~ delete _;
	private IDevice mDevice;

	/// Path to shader source files.
	private List<String> mShaderSourcePaths = new .() ~ DeleteContainerAndItems!(_);

	/// Include paths for shader compilation.
	private List<String> mIncludePaths = new .() ~ DeleteContainerAndItems!(_);

	/// Target format (SPIRV for Vulkan, DXIL for DX12).
	public ShaderTarget Target = .SPIRV;

	/// Whether the shader system is initialized.
	public bool IsInitialized => mCompiler != null;

	/// Access to the shader cache.
	public ShaderCache Cache => mCache;

	/// Default constructor - call Initialize() before use.
	public this()
	{
	}

	public ~this()
	{
	}

	/// Access to the shader compiler.
	public ShaderCompiler Compiler => mCompiler;

	/// Initializes the shader system.
	/// - device: RHI device for creating shader modules
	/// - shaderSourcePath: Path to shader source files
	/// - cachePath: Optional path for disk cache (null to disable)
	public Result<void> Initialize(IDevice device, Span<StringView> shaderSourcePaths, StringView cachePath = default)
	{
		mDevice = device;

		// Store shader source path
		for (var path in shaderSourcePaths)
		{
			mShaderSourcePaths.Add(new String(path));
		}

		// Initialize compiler
		if (mCompiler != null)
		{
			delete mCompiler;
			mCompiler = null;
		}
		mCompiler = new ShaderCompiler();
		if (mCompiler.Initialize() case .Err)
		{
			delete mCompiler;
			mCompiler = null;
			return .Err;
		}

		// Add shader source path as include path
		for (var path in mShaderSourcePaths)
		{
			mCompiler.AddIncludePath(path);
		}

		// Add any additional include paths
		for (let path in mIncludePaths)
			mCompiler.AddIncludePath(path);

		// Initialize cache
		if (mCache != null)
		{
			delete mCache;
			mCache = null;
		}
		mCache = new ShaderCache(device);
		mCache.Target = Target;

		if (!cachePath.IsEmpty)
		{
			if (mCache.SetCachePath(cachePath) case .Err)
			{
				// Non-fatal: just disable disk caching
			}
		}

		return .Ok;
	}

	/// Adds an include path for shader compilation.
	public void AddIncludePath(StringView path)
	{
		mIncludePaths.Add(new String(path));
		if (mCompiler != null)
			mCompiler.AddIncludePath(path);
	}

	/// Sets the base path for shader source files.
	/// Compatibility method for old ShaderLibrary API.
	public void AddShaderPath(StringView path)
	{
		mShaderSourcePaths.Add(new String(path));
		// Also add as include path
		if (mCompiler != null)
			mCompiler.AddIncludePath(path);
	}

	/// Gets a compiled shader module.
	/// Looks up in cache first, compiles from source if not found.
	public Result<ShaderModule> GetShader(
		StringView name,
		ShaderStage stage,
		ShaderFlags flags = .None)
	{
		let key = ShaderVariantKey(name, stage, flags);

		// Check cache (memory → disk)
		if (let cached = mCache.TryGet(key))
			return cached;

		// Load source and compile
		return CompileShader(key);
	}

	/// Gets a vertex/fragment shader pair.
	public Result<(ShaderModule vert, ShaderModule frag)> GetShaderPair(
		StringView name,
		ShaderFlags flags = .None)
	{
		let vertexResult = GetShader(name, .Vertex, flags);
		if (vertexResult case .Err)
			return .Err;

		let fragmentResult = GetShader(name, .Fragment, flags);
		if (fragmentResult case .Err)
			return .Err;

		return (vertexResult.Value, fragmentResult.Value);
	}

	/// Compiles a shader from source.
	private Result<ShaderModule> CompileShader(ShaderVariantKey key)
	{
		// Build source file path
		String sourceFile = scope .();

		for(var path in mShaderSourcePaths)
		{
			sourceFile.Clear();
			GetShaderSourcePath(path, key, sourceFile);
			if(File.Exists(sourceFile))
			{
				break;
			}
		}

		if (!File.Exists(sourceFile))
		{
			Console.WriteLine("Shader source not found: {}", sourceFile);
			return .Err;
		}

		// Load source
		String source = scope .();
		if (File.ReadAllText(sourceFile, source) case .Err)
		{
			Console.WriteLine("Failed to read shader source: {}", sourceFile);
			return .Err;
		}

		// Compile
		switch (mCompiler.CompileToModule(source, key, Target, default, mDevice))
		{
		case .Ok(let module):
			// Add to cache
			mCache.Add(module, mCache.DiskCacheEnabled);
			return module;

		case .Err:
			return .Err;
		}
	}

	/// Compiles a shader from inline source (not loaded from file).
	public Result<ShaderModule> CompileFromSource(
		StringView source,
		StringView name,
		ShaderStage stage,
		ShaderFlags flags = .None)
	{
		let key = ShaderVariantKey(name, stage, flags);

		// Check cache first
		if (let cached = mCache.TryGet(key))
			return cached;

		// Compile
		switch (mCompiler.CompileToModule(source, key, Target, default, mDevice))
		{
		case .Ok(let module):
			mCache.Add(module, mCache.DiskCacheEnabled);
			return module;

		case .Err:
			return .Err;
		}
	}

	/// Gets the full path to a shader source file.
	private void GetShaderSourcePath(StringView shaderSourcePath, ShaderVariantKey key, String outPath)
	{
		Path.InternalCombine(outPath, shaderSourcePath, key.Name);

		// Append extension based on stage
		switch (key.Stage)
		{
		case .Vertex:
			outPath.Append(".vert.hlsl");
		case .Fragment:
			outPath.Append(".frag.hlsl");
		case .Compute:
			outPath.Append(".comp.hlsl");
		default:
			outPath.Append(".hlsl");
		}
	}

	/// Precompiles commonly used shader variants.
	/// Call this during loading to avoid runtime compilation stalls.
	public void PrecompileVariants(StringView name, Span<ShaderFlags> variants)
	{
		for (let flags in variants)
		{
			// Compile vertex shader
			let vertexKey = ShaderVariantKey(name, .Vertex, flags);
			if (mCache.TryGet(vertexKey) == null)
				CompileShader(vertexKey);

			// Compile fragment shader
			let fragmentKey = ShaderVariantKey(name, .Fragment, flags);
			if (mCache.TryGet(fragmentKey) == null)
				CompileShader(fragmentKey);
		}
	}

	/// Clears all cached shaders (memory and disk).
	public void ClearCache()
	{
		if (mCache != null)
			mCache.ClearAll();
	}

	/// Clears memory cache only (keeps disk cache).
	public void ClearMemoryCache()
	{
		if (mCache != null)
			mCache.ClearMemory();
	}

	/// Sets the disk cache path.
	public Result<void> SetCachePath(StringView path)
	{
		if (mCache != null)
			return mCache.SetCachePath(path);
		return .Err;
	}

	/// Gets shader system statistics.
	public void GetStats(String outStats)
	{
		outStats.AppendF("Shader System Statistics:\n");
		outStats.AppendF("  Source paths:\n");
		if(mShaderSourcePaths.Count == 0)
		{
			outStats.AppendF("    None set\n");
		}else{
			for(var path in mShaderSourcePaths)
			{
				outStats.AppendF("    {}\n", path);
			}
		}
		outStats.AppendF("  Target: {}\n", Target);
		outStats.AppendF("  Include paths: {}\n", mIncludePaths.Count);

		if (mCache != null)
		{
			outStats.Append("\nCache:\n");
			mCache.GetStats(outStats);
		}
	}

	public void Dispose()
	{
		delete mCache;
		mCache = null;

		delete mCompiler;
		mCompiler = null;
	}
}
