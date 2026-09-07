using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.Null;

/// The null backend: one adapter, and surfaces from any handle at all.
class NullBackend : IBackend
{
	private NullAdapter mAdapter = new .() ~ delete _;
	private IAdapter[1] mAdapters;
	private List<NullSurface> mSurfaces = new .() ~ DeleteContainerAndItems!(_);

	public this()
	{
		mAdapters[0] = mAdapter;
		IsInitialized = true;
	}

	public bool IsInitialized { get; private set; }

	public Span<IAdapter> EnumerateAdapters() => .(&mAdapters[0], 1);

	/// Succeeds for ANY handle, including null: there is no windowing system to reject it,
	/// and refusing would make a headless swap chain test impossible.
	public Result<ISurface> CreateSurface(void* windowHandle, void* displayHandle,
		SurfacePlatform platform)
	{
		let surface = new NullSurface();
		mSurfaces.Add(surface);
		return .Ok(surface);
	}

	public void Destroy() {}
}
