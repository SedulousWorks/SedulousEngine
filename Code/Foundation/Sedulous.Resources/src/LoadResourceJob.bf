using System;
using Sedulous.Jobs;

namespace Sedulous.Resources;

/// Job for asynchronously loading a resource.
class LoadResourceJob<T> : Job<Result<ResourceHandle<T>, ResourceLoadError>> where T : IResource
{
	private ResourceSystem mResourceSystem;
	private String mPath = new .() ~ delete _;
	private bool mFromCache;
	private bool mCacheIfLoaded;
	private delegate void(Result<ResourceHandle<T>, ResourceLoadError>) mOnCompleted ~ { if (mOwnsDelegate) delete _; };
	private bool mOwnsDelegate;

	public this(
		ResourceSystem resourceSystem,
		StringView path,
		bool fromCache,
		bool cacheIfLoaded,
		JobFlags flags,
		delegate void(Result<ResourceHandle<T>, ResourceLoadError>) onCompleted,
		bool ownsDelegate)
		: base(scope $"Load:{path}", flags)
	{
		mResourceSystem = resourceSystem;
		mPath.Set(path);
		mFromCache = fromCache;
		mCacheIfLoaded = cacheIfLoaded;
		mOnCompleted = onCompleted;
		mOwnsDelegate = ownsDelegate;
	}

	protected override Result<ResourceHandle<T>, ResourceLoadError> OnExecute()
	{
		return mResourceSystem.LoadResource<T>(mPath, mFromCache, mCacheIfLoaded);
	}

	protected override void OnCompleted()
	{
		mOnCompleted?.Invoke(mResult);
	}
}
