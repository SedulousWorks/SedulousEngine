using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.Validation;

/// Wraps a backend so everything reached through it is watched.
class ValidatedBackend : IBackend
{
	private IBackend mInner;
	private List<ValidatedAdapter> mAdapters = new .() ~ DeleteContainerAndItems!(_);
	private List<IAdapter> mAdapterHandles = new .() ~ delete _;

	public this(IBackend inner) => mInner = inner;

	public IBackend Inner => mInner;
	public bool IsInitialized => mInner.IsInitialized;

	/// Wrapped ONCE and kept, so repeated calls hand back the same adapters and a caller
	/// comparing them across calls is not surprised.
	public Span<IAdapter> EnumerateAdapters()
	{
		if (!mInner.IsInitialized)
			ValidationLog.Error("Backend.EnumerateAdapters: the backend is not initialised");

		let inner = mInner.EnumerateAdapters();
		if (mAdapterHandles.Count != inner.Length)
		{
			ClearAndDeleteItems!(mAdapters);
			mAdapterHandles.Clear();
			for (int i < inner.Length)
			{
				let wrapper = new ValidatedAdapter(inner[i]);
				mAdapters.Add(wrapper);
				mAdapterHandles.Add(wrapper);
			}
		}
		return mAdapterHandles;
	}

	/// A null window handle produces a surface that presents nowhere, and backends differ
	/// on whether they notice.
	public Result<ISurface> CreateSurface(void* windowHandle, void* displayHandle,
		SurfacePlatform platform)
	{
		if (windowHandle == null)
			ValidationLog.Error("Backend.CreateSurface: windowHandle is null");
		return mInner.CreateSurface(windowHandle, displayHandle, platform);
	}

	public void Destroy() => mInner.Destroy();
}
