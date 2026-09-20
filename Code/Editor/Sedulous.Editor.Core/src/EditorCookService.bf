using System;
using System.Collections;
using System.Diagnostics;
using System.Threading;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.VFS;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Cook;

namespace Sedulous.Editor.Core;

/// The in editor face of the cook driver. Owns the project's sources and .cache mounts and a
/// CookDriver over the project databases, and runs cooks on a BACKGROUND thread, one at a
/// time, Traktor's build lock: the UI stays live, progress lines queue under a lock and
/// drain on the main thread from Update.
///
/// Three phases, so the UI never stalls AND nothing races: the plan on the worker, which
/// only READS the databases while their structure is frozen (every main thread structural
/// mutation gates through RunWhenIdle); PrepareProducts on the MAIN thread, the only phase
/// that mutates the cooked database, which main thread resource loads read at any time;
/// then the builds on the worker over snapshotted pointers.
///
/// The service also watches Sources/ through the native mount's stat sweep, polled every
/// couple of seconds from Update: an external edit queues an incremental cook. After every
/// cook LastCookedProducts lists the rebuilt guids for the application to hot reload.
///
/// The v1 hazard Traktor shares: editing a source asset WHILE a cook runs races the
/// driver's reads; the UI disables the cook triggers during a cook but does not lock edits.
class EditorCookService
{
	private const double cWatchPollSeconds = 2.0;

	private EditorProject mProject = null;
	private BuilderRegistry mBuilders = null;
	private NativeFileSystem mSources = null;
	private NativeFileSystem mCache = null;
	private JobSystem mJobs = null;
	private CookDriver mDriver = null;
	private Thread mWorker = null;
	private int32 mCooking = 0;
	private int32 mFinishedPending = 0;
	private int32 mPlanReady = 0;
	private uint64 mRevision = 0;
	private Monitor mQueueLock = new .() ~ delete _;
	private List<String> mQueue = new .() ~ DeleteContainerAndItems!(_);
	/// Worker written under the queue lock; the main thread copies at the finish.
	private List<Guid> mLastCooked = new .() ~ delete _;
	private List<Guid> mLastCookedMain = new .() ~ delete _;
	private int mLastCookedCount = 0;
	private int mLastFailedCount = 0;
	private int mLastCookedCountMain = 0;
	private int mLastFailedCountMain = 0;
	/// Main thread deferred mutations.
	private List<delegate void()> mIdleQueue = new .() ~ DeleteContainerAndItems!(_);
	/// A RequestCook that arrived while cooking.
	private bool mPendingCook = false;
	private bool mPendingForce = false;
	/// The merged scoped requests that arrived mid cook.
	private List<Guid> mPendingRoots = new .() ~ delete _;
	private bool mPendingRootsForce = false;
	/// Worker planned, main prepared, worker built.
	private CookPlan mPlan = new .() ~ delete _;
	private List<Guid> mPlanRoots = new .() ~ delete _;
	private bool mPlanForce = false;
	/// Borrowed; the sources mount owns it.
	private IChangeSource mWatcher = null;
	private List<String> mWatchChanged = new .() ~ DeleteContainerAndItems!(_);
	private int64 mLastWatchPoll = 0;

	/// Fired on the main thread, from Update, when a cook finishes.
	public delegate void() OnCookFinished ~ delete _;

	/// The external contributor to the mutation lock, wired by the app: a background EXPORT
	/// reads the source database's structure and packs cooked files from its worker, so
	/// mutations and new cooks hold off exactly as during a cook.
	public delegate bool() ExternalMutationLock ~ delete _;

	public ~this()
	{
		Shutdown();
	}

	/// Wires to the open project. `builders` outlives the service; the executable assembles
	/// the registry before the project opens.
	public void Initialize(EditorProject project, BuilderRegistry builders)
	{
		Shutdown();
		mProject = project;
		mBuilders = builders;
		mSources = new NativeFileSystem(project.SourcesRoot(.. scope .()));
		mCache = new NativeFileSystem(project.CacheRoot(.. scope .()));
		mJobs = new JobSystem();
		mDriver = new CookDriver(project.SourceDb, project.CookedDb, builders, mSources, mCache, mJobs);
		// Sources/ watched for external edits: a stat sweep, throttled from Update.
		mWatcher = mSources.ChangeSource;
		if (mWatcher != null)
			mWatcher.Track("");
		mLastWatchPoll = Stopwatch.GetTimestamp();
	}

	public void Shutdown()
	{
		JoinWorker();
		mWatcher = null;
		DeleteAndNullify!(mDriver);
		DeleteAndNullify!(mJobs);
		DeleteAndNullify!(mCache);
		DeleteAndNullify!(mSources);
		mProject = null;
	}

	public bool IsReady => mDriver != null;
	public bool IsCooking => Interlocked.Load(ref mCooking) != 0;

	/// True while ANY background reader of the databases is in flight, a cook or an external
	/// job. Every structural mutation gate and the watcher key on THIS, not IsCooking alone.
	public bool MutationLocked => IsCooking || ((ExternalMutationLock != null) && ExternalMutationLock());

	/// Fully quiescent: nothing in flight AND no remembered request waiting to re-issue. A
	/// "start after the cook" gate keys on THIS: between a finishing cook and its remembered
	/// re-issue there is an idle gap MutationLocked would mistake for done.
	public bool IsIdle => !MutationLocked && !mPendingCook && mPendingRoots.IsEmpty;

	/// Bumped when a cook finishes; the badges refresh off it.
	public uint64 Revision => mRevision;

	/// The instance's cook recipe hash, the thumbnail content key, or 0 when unknown: mid
	/// cook, the database being the worker's, or never cooked.
	public uint64 RecipeHashFor(Guid id)
	{
		if (!IsReady || IsCooking)
			return 0;
		let record = mDriver.Db.Find(id);
		return ((record != null) && !record.Failed) ? record.RecipeHash : 0;
	}

	/// Kicks a background cook. A request while one is running is REMEMBERED and re-issued
	/// when it finishes; without that a save during a cook silently loses its recook.
	/// `force` rebuilds everything.
	public void RequestCook(bool force = false)
	{
		if (!IsReady)
			return;
		if (MutationLocked)
		{
			mPendingCook = true;
			mPendingForce = mPendingForce || force;
			return;
		}
		JoinWorker();
		mPlanRoots.Clear();
		mPlanForce = force;
		StartPlan();
	}

	/// A scoped cook: the given sources plus their dependency closure. The same three phases;
	/// merged into the pending roots when a cook is in flight, since concurrent requests for
	/// overlapping roots replay as ONE scoped cook, and a pending FULL cook supersedes.
	public void RequestCookFor(Span<Guid> roots, bool force = false)
	{
		if (!IsReady || roots.IsEmpty)
			return;
		if (MutationLocked)
		{
			if (!mPendingCook)
			{
				for (let id in roots)
					if (!mPendingRoots.Contains(id))
						mPendingRoots.Add(id);
				mPendingRootsForce = mPendingRootsForce || force;
			}
			return;
		}
		JoinWorker();
		mPlanRoots.Clear();
		mPlanRoots.AddRange(roots);
		mPlanForce = force;
		StartPlan();
	}

	/// Phase 1, the plan on the worker.
	private void StartPlan()
	{
		Interlocked.Exchange(ref mCooking, 1);
		Interlocked.Exchange(ref mPlanReady, 0);
		delete mPlan;
		mPlan = new CookPlan();
		mWorker = new Thread(new () =>
			{
				if (mPlanRoots.IsEmpty)
					mDriver.Plan(mPlan, mPlanForce);
				else
					mDriver.PlanFor(mPlanRoots, mPlan, mPlanForce);
				Interlocked.Exchange(ref mPlanReady, 1);
			});
		mWorker.Start(false);
	}

	/// Phases 2 and 3: PrepareProducts on the main thread, then the build worker.
	public void StartBuilds()
	{
		JoinWorker();
		mDriver.PrepareProducts(mPlan);
		let total = mPlan.Dirty.Count;
		// A zero work plan runs SILENTLY: a page open or an import is cheap to request and
		// often finds everything cooked already.
		if ((total > 0) || !mPlan.Orphans.IsEmpty)
		{
			let planned = scope String();
			planned.AppendF("cooking {} asset(s)", total);
			if (!mPlan.Orphans.IsEmpty)
				planned.AppendF(", sweeping {} orphan(s)", mPlan.Orphans.Count);
			Post(planned);
		}
		mWorker = new Thread(new () =>
			{
				let progress = scope CookProgress();
				progress.OnItem = new (done, itemTotal, path, ok) =>
					{
						Post(scope $"{ok ? "cooked " : "FAILED "}{path} ({done}/{total})");
					};
				defer delete progress.OnItem;
				let stats = scope CookStats();
				mDriver.ExecuteBuilds(mPlan, stats, progress);
				if (stats.Cooked + stats.Failed + stats.OrphansSwept > 0)
					Post(scope $"cook finished: {stats.Cooked} cooked, {stats.Failed} failed");
				using (mQueueLock.Enter())
				{
					mLastCooked.Clear();
					mLastCooked.AddRange(stats.CookedProducts);
					mLastCookedCount = stats.Cooked;
					mLastFailedCount = stats.Failed;
				}
				Interlocked.Exchange(ref mCooking, 0);
				Interlocked.Exchange(ref mFinishedPending, 1);
			});
		mWorker.Start(false);
	}

	/// The main thread pump: drains the progress lines into `status`, the status bar and
	/// the console, and fires OnCookFinished after a cook completes.
	public void Update(delegate void(StringView line) status = null)
	{
		// The phase hand off: the plan worker finished.
		if (Interlocked.Exchange(ref mPlanReady, 0) != 0)
			StartBuilds();

		let drained = scope List<String>();
		defer { ClearAndDeleteItems(drained); }
		using (mQueueLock.Enter())
		{
			drained.AddRange(mQueue);
			mQueue.Clear();
		}
		for (let line in drained)
		{
			GlobalLog(.Information, "Cook: {}", line);
			if (status != null)
				status(line);
		}

		if (Interlocked.Exchange(ref mFinishedPending, 0) != 0)
		{
			mRevision++;
			using (mQueueLock.Enter())
			{
				mLastCookedMain.Clear();
				mLastCookedMain.AddRange(mLastCooked);
				mLastCookedCountMain = mLastCookedCount;
				mLastFailedCountMain = mLastFailedCount;
			}
			if (OnCookFinished != null)
				OnCookFinished();
		}

		// The deferred mutations queued while the worker read snapshotted instances, and a
		// request that arrived mid cook.
		if (!MutationLocked)
		{
			if (!mIdleQueue.IsEmpty)
			{
				let pending = scope List<delegate void()>();
				pending.AddRange(mIdleQueue);
				mIdleQueue.Clear();
				for (let action in pending)
				{
					action();
					delete action;
				}
			}
			if (mPendingCook)
			{
				mPendingCook = false;
				let force = mPendingForce;
				mPendingForce = false;
				mPendingRoots.Clear();
				mPendingRootsForce = false;
				RequestCook(force);
			}
			else if (!mPendingRoots.IsEmpty)
			{
				let roots = scope List<Guid>();
				roots.AddRange(mPendingRoots);
				mPendingRoots.Clear();
				let force = mPendingRootsForce;
				mPendingRootsForce = false;
				RequestCookFor(roots, force);
			}
		}

		// The watcher, throttled; held off while ANY background reader runs, since a mid
		// export cook would rewrite the very files the export is packing.
		if ((mWatcher != null) && !MutationLocked)
		{
			let now = Stopwatch.GetTimestamp();
			if ((now - mLastWatchPoll) >= (int64)(cWatchPollSeconds * 1000000))
			{
				mLastWatchPoll = now;
				ClearAndDeleteItems(mWatchChanged);
				if (mWatcher.Poll(mWatchChanged))
				{
					GlobalLog(.Information, "Cook: {} source file(s) changed - recooking", mWatchChanged.Count);
					RequestCook(false);
				}
			}
		}
	}

	/// Defers a MAIN THREAD source database mutation, an import or a delete, until no cook is
	/// in flight; immediately when idle. TAKES OWNERSHIP of `action`.
	public void RunWhenIdle(delegate void() action)
	{
		if (action == null)
			return;
		if (!MutationLocked)
		{
			action();
			delete action;
			return;
		}
		mIdleQueue.Add(action);
	}

	/// The products the most recent cook rebuilt, valid once OnCookFinished fired until the
	/// next finish. The app hot reloads these through the ResourceManager.
	public Span<Guid> LastCookedProducts => mLastCookedMain;
	public int LastCookedCount => mLastCookedCountMain;
	public int LastFailedCount => mLastFailedCountMain;

	public CookBadge BadgeFor(Instance instance)
	{
		if (!IsReady || (mBuilders == null))
			return .NoBuilder;
		if (mBuilders.FindByTypeName(instance.TypeName) == null)
			return .NoBuilder;
		if (IsCooking)
			return .Missing;
		let record = mDriver.Db.Find(instance.Id);
		if ((record != null) && record.Failed)
			return .Failed;
		let productExists = mProject.CookedDb.GetInstance(instance.Id) != null;
		return ((record != null) && productExists) ? .Cooked : .Missing;
	}

	private void Post(StringView message)
	{
		using (mQueueLock.Enter())
			mQueue.Add(new String(message));
	}

	private void JoinWorker()
	{
		if (mWorker != null)
		{
			mWorker.Join();
			delete mWorker;
			mWorker = null;
		}
	}
}
