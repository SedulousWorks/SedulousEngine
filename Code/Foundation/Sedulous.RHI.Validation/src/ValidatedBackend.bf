namespace Sedulous.RHI.Validation;

using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.Surface;

/// Validation wrapper for IBackend.
/// Factory entry point: CreateValidatedBackend(inner).
class ValidatedBackend : IBackend
{
	private IBackend mInner;
	private List<ValidatedAdapter> mAdapterWrappers = new .() ~ DeleteContainerAndItems!(_);

	public this(IBackend inner)
	{
		mInner = inner;
	}

	public bool IsInitialized => mInner.IsInitialized;

	public void EnumerateAdapters(List<IAdapter> adapters)
	{
		if (!mInner.IsInitialized)
		{
			ValidationLogger.Error("EnumerateAdapters called on uninitialized backend");
			return;
		}

		// Get inner adapters, then wrap them (cached)
		if (mAdapterWrappers.IsEmpty)
		{
			let innerAdapters = scope List<IAdapter>();
			mInner.EnumerateAdapters(innerAdapters);

			for (let adapter in innerAdapters)
			{
				mAdapterWrappers.Add(new ValidatedAdapter(adapter));
			}
		}

		for (let wrapper in mAdapterWrappers)
			adapters.Add(wrapper);
	}

	public Result<ISurface> CreateSurface(SurfaceInfo info)
	{
		if (info.Type == .Unspecified)
		{
			ValidationLogger.Error("CreateSurface: surface type is Unspecified");
			return .Err;
		}

		return mInner.CreateSurface(info);
	}

	public void Destroy()
	{
		mInner.Destroy();
	}

	/// The wrapped inner backend.
	public IBackend Inner => mInner;
}

/// Creates a validated wrapper around a backend.
/// All objects created through this backend will be validated.
static
{
	public static ValidatedBackend CreateValidatedBackend(IBackend inner)
	{
		return new ValidatedBackend(inner);
	}
}
