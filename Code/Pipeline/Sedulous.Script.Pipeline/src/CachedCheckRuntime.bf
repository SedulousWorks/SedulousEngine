using System;
using System.Collections;
using System.Threading;
using Sedulous.Profiler;
using Sedulous.Script;

namespace Sedulous.Script.Pipeline;

/// The runtime a language's checks share. Binding the surface is nearly all of a check's time
/// (about half a second), compiling a few milliseconds, so it is made once, on first use, and
/// again only when the surface changes (its Revision: a plugin's types joined or left). Its lock
/// serialises the checks, which an agent's tool may run from another thread. Each cook owns one.
class CachedCheckRuntime
{
	/// BORROWED: the cook's surface, for the cook's life.
	private ScriptSurface mSurface;
	private delegate ScriptRuntime() mMake ~ delete _;
	private Monitor mLock = new .() ~ delete _;
	private ScriptRuntime mRuntime = null ~ delete _;
	private uint64 mRevision = 0;
	private uint32 mBuildCount = 0;

	/// `make` makes an unbound runtime of the language; OWNERSHIP of it transfers.
	public this(ScriptSurface surface, delegate ScriptRuntime() make)
	{
		mSurface = surface;
		mMake = make;
	}

	/// How many times the runtime has been made.
	public uint32 BuildCount => mBuildCount;

	/// Runs `check` on the runtime, under the lock. False when none could be made.
	public bool Run(delegate bool(ScriptRuntime runtime) check)
	{
		using (mLock.Enter())
		{
			let runtime = Current();
			return (runtime != null) && check(runtime);
		}
	}

	/// Makes the runtime now if it is missing or out of date (for a worker, ahead of the first
	/// check).
	public void Prepare()
	{
		using (mLock.Enter())
			Current();
	}

	/// The surface's API as the runtime binds it, for completion and the API browser.
	public void DescribeApi(List<ScriptApiType> outTypes)
	{
		using (mLock.Enter())
		{
			let runtime = Current();
			if (runtime != null)
				runtime.DescribeBoundApi(outTypes);
		}
	}

	/// The surface's API as the declarations file an outside editor reads; false when no runtime
	/// could be made or it writes none.
	public bool Declarations(String outFileName, String outText)
	{
		using (mLock.Enter())
		{
			let runtime = Current();
			if (runtime == null)
				return false;
			runtime.Declarations(outFileName, outText);
			return !outFileName.IsEmpty;
		}
	}

	// The runtime, made again if the surface changed since; the caller holds the lock.
	private ScriptRuntime Current()
	{
		if (mSurface == null)
			return null;
		// Read before binding: a type added meanwhile makes it again next time.
		let revision = mSurface.Revision;
		if ((mRuntime != null) && (revision == mRevision))
			return mRuntime;
		DeleteAndNullify!(mRuntime);
		using (ProfileScope("Script.Cook.MakeEngine"))
			mRuntime = mMake();
		if (mRuntime == null)
			return null;
		using (ProfileScope("Script.Cook.RegisterApi"))
			mRuntime.Bind(mSurface);
		ClearAndDeleteItems!(mRuntime.Problems);
		mRevision = revision;
		mBuildCount++;
		return mRuntime;
	}
}
