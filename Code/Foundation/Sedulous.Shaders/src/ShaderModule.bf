namespace Sedulous.Shaders;

using System;
using Sedulous.RHI;

/// A compiled shader module with metadata.
/// Owns the compiled bytecode and associated RHI shader module.
class ShaderModule : IDisposable
{
	/// Variant key that identifies this shader.
	public readonly ShaderVariantKey Key;

	/// Compiled bytecode (SPIRV or DXIL).
	private uint8[] mBytecode ~ delete _;

	/// RHI shader module (created on demand).
	private IShaderModule mRhiModule;

	/// Device used to create RHI module.
	private IDevice mDevice;

	/// Whether this module is valid.
	public bool IsValid => mBytecode != null && mBytecode.Count > 0;

	/// Gets the compiled bytecode.
	public Span<uint8> Bytecode => mBytecode != null ? mBytecode : default;

	/// Gets the shader stage.
	public ShaderStage Stage => Key.Stage;

	/// Gets the shader flags.
	public ShaderFlags Flags => Key.Flags;

	/// Gets the shader name.
	public StringView Name => Key.Name;

	/// Gets the RHI shader module directly (compatibility property).
	/// Lazily creates the module if not already created.
	/// Returns null if no device is available or creation fails.
	public IShaderModule Module
	{
		get
		{
			if (mRhiModule == null && mDevice != null && IsValid)
				if(GetRhiModule() case .Err)
				{
					Runtime.FatalError();
				}
			return mRhiModule;
		}
	}

	public ~this()
	{
		ReleaseRhiModule();
	}

	/// Creates a shader module from compiled bytecode.
	public this(ShaderVariantKey key, Span<uint8> bytecode, IDevice device = null)
	{
		Key = key;
		mDevice = device;

		if (bytecode.Length > 0)
		{
			mBytecode = new uint8[bytecode.Length];
			bytecode.CopyTo(mBytecode);
		}
	}

	/// Gets or creates the RHI shader module.
	public Result<IShaderModule> GetRhiModule(IDevice device = null)
	{
		if (mRhiModule != null)
			return mRhiModule;

		if (!IsValid)
			return .Err;

		IDevice targetDevice = device != null ? device : mDevice;
		if (targetDevice == null)
			return .Err;

		String label = scope .();
		Key.ToString(label);

		let desc = ShaderModuleDesc()
		{
			Code = Span<uint8>((uint8*)mBytecode.Ptr, mBytecode.Count),
			Label = label
		};

		switch (targetDevice.CreateShaderModule(desc))
		{
		case .Ok(let module):
			mRhiModule = module;
			mDevice = targetDevice;
			return module;
		case .Err:
			return .Err;
		}
	}

	/// Releases the RHI module but keeps bytecode.
	public void ReleaseRhiModule()
	{
		if (mRhiModule != null && mDevice != null)
			mDevice.DestroyShaderModule(ref mRhiModule);
	}

	public void Dispose()
	{
		ReleaseRhiModule();
	}
}
