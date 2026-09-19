using System;
using System.Collections;
using System.Threading;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;
using Sedulous.VFS;

namespace Sedulous.Pipeline.Cook;

/// Plans and runs a cook.
///
/// The split into a plan and an execution, and the further split of the execution into a
/// MAIN THREAD phase and a worker phase, is not decoration. The content databases' group trees
/// and identity indices are not safe to touch from two threads, so everything that mutates
/// them happens in one place, on the thread that owns them, before any worker starts.
///
/// The incident behind that: planning and sweeping on the worker while the main thread
/// imported and deleted produced garbage deserialisation, and it looked like a content
/// corruption bug rather than a race.
class CookDriver
{
	/// The depth past which a read dependency chain is treated as a cycle.
	private const int32 cMaxDepth = 64;

	private ContentDatabase mSourceDb;
	private ContentDatabase mCookedDb;
	private BuilderRegistry mBuilders;

	/// Nullable: a project whose data is all embedded has no source files.
	private IFileSystem mSources;
	/// Nullable: a one shot cook and a test both run without persistence.
	private IFileSystem mCache;
	private JobSystem mJobs;

	private CookDb mDb = new .() ~ delete _;
	private CookTarget mTarget = .Host;

	private ContentDatabase mHostCookedDb = null;
	private CookDb mHostRecords = null;

	private Dictionary<Guid, uint64> mRecipeMemo = new .() ~ delete _;
	private Dictionary<Guid, List<CookFileMemo>> mPendingMemos = new .()
		~ { for (let entry in _) DeleteContainerAndItems!(entry.value); delete _; };

	private Monitor mRecordLock = new .() ~ delete _;

	public this(ContentDatabase sourceDb, ContentDatabase cookedDb, BuilderRegistry builders,
		IFileSystem sourcesMount, IFileSystem cacheMount, JobSystem jobs = null)
	{
		mSourceDb = sourceDb;
		mCookedDb = cookedDb;
		mBuilders = builders;
		mSources = sourcesMount;
		mCache = cacheMount;
		mJobs = jobs;

		if (mCache != null)
			mDb.Load(mCache);
	}

	public CookDb Db => mDb;

	/// The export target this driver cooks for.
	///
	/// It SALTS the recipe of a variant builder, so a texture re-cooks per target, and reaches
	/// every build through the context. Set it before planning.
	public CookTarget Target
	{
		get => mTarget;
		set => mTarget = value;
	}

	/// Turns on platform invariant copy forward: cooking a per target database, an INVARIANT
	/// product whose recipe matches the host's is copied rather than cooked again.
	///
	/// The host's already loaded records are what gate the copy: matching recipes on an
	/// unsalted builder mean identical inputs, so the host's bytes are exactly what this cook
	/// would produce.
	public void SetCopyForwardSource(ContentDatabase hostCookedDb, CookDb hostRecords)
	{
		mHostCookedDb = hostCookedDb;
		mHostRecords = hostRecords;
	}

	/// The reusable per target cook step: cooks `sourceDb` for `target` into `targetCookedDb`,
	/// carrying platform invariant products forward from the already cooked host database,
	/// gated by the host's records, instead of cooking them again. `targetCache` is the
	/// target's own cook records mount. The cooker's --target and the web export both drive
	/// this; `force` re-cooks everything.
	public static void CookForTarget(ContentDatabase sourceDb, ContentDatabase targetCookedDb,
		ContentDatabase hostCookedDb, CookDb hostRecords, BuilderRegistry builders, IFileSystem sources,
		IFileSystem targetCache, CookTarget target, CookStats outStats, JobSystem jobs = null,
		bool force = false, CookProgress progress = null)
	{
		let driver = scope CookDriver(sourceDb, targetCookedDb, builders, sources, targetCache, jobs);
		driver.Target = target;
		driver.SetCopyForwardSource(hostCookedDb, hostRecords);
		let plan = scope CookPlan();
		driver.Plan(plan, force);
		driver.Execute(plan, outStats, progress);
	}

	// ==================== planning ====================

	/// The dirty set for the whole project, plus the orphans.
	public void Plan(CookPlan outPlan, bool force = false)
	{
		mRecipeMemo.Clear();

		let instances = scope List<Instance>();
		CollectInstances(mSourceDb.RootGroup, instances);

		let levels = scope Dictionary<Guid, int32>();
		for (let instance in instances)
			PlanInstance(instance, force, outPlan, levels, null);

		SortByLevel(outPlan.Dirty);

		// The orphan sweep: records whose source instance is gone.
		mDb.ForEach(scope [&] (record) =>
			{
				if (mSourceDb.GetInstance(record.Source) == null)
					outPlan.Orphans.Add(record.Source);
			});
	}

	/// A SCOPED plan: the requested roots plus their dependency closure, transitively, so a
	/// material's textures cook with it.
	///
	/// `force` re-cooks the ROOTS whatever their state; a dependency reached through the
	/// closure keeps its normal clean check. No orphan sweep, which is a whole project concern.
	/// This is what lets a large project cook one group at a time rather than all of it.
	public void PlanFor(Span<Guid> roots, CookPlan outPlan, bool force = false)
	{
		mRecipeMemo.Clear();

		let queue = scope List<Guid>();
		for (let id in roots)
			queue.Add(id);

		let levels = scope Dictionary<Guid, int32>();
		var head = 0;
		while (head < queue.Count)
		{
			let id = queue[head++];
			if (outPlan.Reachable.Contains(id))
				continue;
			outPlan.Reachable.Add(id);

			let instance = mSourceDb.GetInstance(id);
			if (instance == null)
				continue;

			var isRoot = false;
			for (let root in roots)
			{
				if (root == id)
				{
					isRoot = true;
					break;
				}
			}

			let deps = scope AssetDependencies();
			PlanInstance(instance, force && isRoot, outPlan, levels, deps);
			for (let dep in deps.Reads)
				queue.Add(dep);
			for (let dep in deps.References)
				queue.Add(dep);
		}

		SortByLevel(outPlan.Dirty);
	}

	/// Scans one source instance and appends it when dirty.
	///
	/// `outDeps`, when given, receives its dependencies even if it was CLEAN: a scoped plan
	/// walks the closure through clean items too, since something dirty may sit beneath one.
	private void PlanInstance(Instance instance, bool force, CookPlan plan,
		Dictionary<Guid, int32> levels, AssetDependencies outDeps)
	{
		let typeName = scope String();
		instance.TypeName.ToString(typeName);
		let builder = mBuilders.FindByTypeName(typeName);
		if (builder == null)
		{
			plan.Unbuildable++;
			return;
		}

		let item = new CookItem();
		var keep = false;
		defer { if (!keep) delete item; }

		item.Source = instance.Id;
		instance.GetPath(item.Path);
		item.Builder = builder;
		item.AssetObject = instance.ReadObject();

		if (item.AssetObject == null)
		{
			// An unknown type identity, or a source written under a data version this build
			// does not support. The STORED identity goes into the message so the failure is
			// debuggable from the log alone.
			GlobalLog(.Warning,
				"Cook: '{}' failed to deserialize. Its stored type is '{}' and its identity {}, which usually means an unknown type name or a stale record. Delete and re-import if re-cooking does not recover it",
				item.Path, instance.TypeName, instance.Id);
			plan.Unbuildable++;
			return;
		}

		let asset = Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(item.AssetObject)) as Asset;
		if (asset == null)
		{
			GlobalLog(.Warning, "Cook: '{}' has a builder but is not an asset", item.Path);
			plan.Unbuildable++;
			return;
		}

		let scanContext = scope AssetBuildContext();
		scanContext.Sources = mSources;
		scanContext.Database = mSourceDb;
		builder.ScanDependencies(asset, scanContext, item.Deps);

		if (outDeps != null)
		{
			for (let file in item.Deps.Files)
				outDeps.AddFile(file.Value);
			for (let stream in item.Deps.SourceStreams)
				outDeps.AddSourceStream(stream);
			outDeps.Reads.AddRange(item.Deps.Reads);
			outDeps.References.AddRange(item.Deps.References);
		}

		item.RecipeHash = ComputeRecipe(instance, asset, builder, item.Deps, 0);
		item.Level = ReadDepth(item.Source, item.Deps, levels, 0);

		let record = mDb.Find(item.Source);
		let productExists = mCookedDb.GetInstance(item.Source) != null;
		let clean = !force && (record != null) && !record.Failed
			&& (record.RecipeHash == item.RecipeHash) && productExists;

		if (clean)
		{
			plan.UpToDate++;
		}
		else
		{
			plan.Dirty.Add(item);
			keep = true;
		}
	}

	private static void CollectInstances(Group group, List<Instance> outInstances)
	{
		if (group == null)
			return;
		for (let instance in group.Instances)
			outInstances.Add(instance);
		for (let child in group.Groups)
			CollectInstances(child, outInstances);
	}
}
