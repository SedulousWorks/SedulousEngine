using System;

namespace Sedulous.Resource;

/// Routes Ref binds through the async path for the duration of a scope.
///
/// A scene load flips this on around resolving its resources, so the whole scene's set
/// decodes on workers instead of one blocking build after another. The caller then pumps
/// to completion behind a loading screen.
///
/// Restores the PREVIOUS mode rather than turning it off, so nesting works and an early
/// return cannot leave the manager in async mode for everything that follows.
struct AsyncBindScope : IDisposable
{
	private ResourceManager mManager;
	private bool mPrevious;

	public this(ResourceManager manager)
	{
		mManager = manager;
		mPrevious = manager.AsyncBindsEnabled;
		manager.SetAsyncBinds(true);
	}

	public void Dispose()
	{
		if (mManager != null)
			mManager.SetAsyncBinds(mPrevious);
	}
}
