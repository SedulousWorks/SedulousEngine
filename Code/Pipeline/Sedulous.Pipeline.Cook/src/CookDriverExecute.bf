using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;
using Sedulous.VFS;

namespace Sedulous.Pipeline.Cook;

/// The driver's execution half, split from the planning half by concern rather than by thread.
extension CookDriver
{
	/// Plan then build, for a caller that has no worker to hand: a command line, or a test.
	public void Execute(CookPlan plan, CookStats outStats, CookProgress progress = null)
	{
		PrepareProducts(plan);
		ExecuteBuilds(plan, outStats, progress);
	}

	/// The FIRST phase, which MUST run on the thread that owns the content databases.
	///
	/// It sweeps orphans, pre-creates every product instance, and snapshots the source
	/// pointers the builds will read. All of that mutates the databases' group trees and
	/// identity indices, which are not safe to touch from a worker while the main thread is
	/// importing or deleting.
	public void PrepareProducts(CookPlan plan)
	{
		for (let orphan in plan.Orphans)
		{
			if (mCookedDb.GetInstance(orphan) != null)
				mCookedDb.DeleteInstance(orphan).IgnoreError();
			mDb.Remove(orphan);
			plan.OrphansSweptCount++;
		}

		for (let item in plan.Dirty)
		{
			item.Product = EnsureProduct(item);
			item.SourceInstance = mSourceDb.GetInstance(item.Source);
			item.CopiedForward = TryCopyForward(item);
		}
	}

	/// The SECOND phase, which is worker safe: builds only.
	///
	/// No database queries happen here, every instance pointer having been snapshotted above.
	/// A worker reads the instances it was handed and writes its own product's files.
	public void ExecuteBuilds(CookPlan plan, CookStats outStats, CookProgress progress = null)
	{
		outStats.OrphansSwept = plan.OrphansSweptCount;

		let results = scope List<bool>();
		results.Count = plan.Dirty.Count;

		var done = 0;
		var begin = 0;
		while (begin < plan.Dirty.Count)
		{
			// The half open range of this dependency level.
			var end = begin;
			while ((end < plan.Dirty.Count) && (plan.Dirty[end].Level == plan.Dirty[begin].Level))
				end++;

			// A copied forward item was filled in on the main thread, so it skips the worker
			// build entirely and counts as succeeded.
			if ((mJobs != null) && ((end - begin) > 1))
			{
				let first = begin;
				mJobs.ParallelFor((int32)(end - begin), scope [&] (i) =>
					{
						let item = plan.Dirty[first + (int)i];
						results[first + (int)i] = item.CopiedForward ? true : CookOne(item);
					});
			}
			else
			{
				for (int i = begin; i < end; ++i)
					results[i] = plan.Dirty[i].CopiedForward ? true : CookOne(plan.Dirty[i]);
			}

			for (int i = begin; i < end; ++i)
			{
				if (!results[i])
					outStats.Failed++;
				else if (plan.Dirty[i].CopiedForward)
					outStats.CopiedForward++;
				else
					outStats.Cooked++;

				if (results[i])
					outStats.CookedProducts.Add(plan.Dirty[i].Source);

				done++;
				if ((progress != null) && (progress.OnItem != null))
					progress.OnItem(done, plan.Dirty.Count, plan.Dirty[i].Path, results[i]);
			}
			begin = end;
		}

		if (mCache != null)
		{
			if (mDb.Save(mCache) case .Err)
				GlobalLog(.Warning, "Cook: the pipeline database could not be saved");
		}
	}

	/// Carries an invariant product over from the host database when its recipe matches.
	///
	/// A VARIANT product, a texture, must cook per target and never comes through here. An
	/// invariant one that READS variant content gets a salted read dependency recipe, so its
	/// hashes differ and it correctly cooks again.
	private bool TryCopyForward(CookItem item)
	{
		if ((mHostCookedDb == null) || (item.Product == null) || (item.Builder == null))
			return false;
		if (item.Builder.Variance != .PlatformInvariant)
			return false;

		let hostRecord = (mHostRecords != null) ? mHostRecords.Find(item.Source) : null;
		if ((hostRecord == null) || hostRecord.Failed || (hostRecord.RecipeHash != item.RecipeHash))
			return false;

		if (mCookedDb.CopyContentForward(item.Product, mHostCookedDb, item.Source) case .Err)
			return false;

		// Stamped NOW, on the main thread, so the next target's cook sees it clean.
		StampRecord(item, false);
		return true;
	}

	/// The product instance for an item: the mirrored path, the SAME identity, stamped with the
	/// builder's product type.
	///
	/// Mutates the cooked database, so it belongs to the first phase.
	private Instance EnsureProduct(CookItem item)
	{
		if (item.Builder == null)
			return null;
		let productType = item.Builder.ProductType;
		if (productType == null)
			return null;

		let typeName = scope String();
		productType.GetFullName(typeName);

		if (let existing = mCookedDb.GetInstance(item.Source))
		{
			// An identity guard. A repeated identity across generations can leave this one on a
			// DIFFERENT product type, and writing this item's product into it would cross type
			// the envelope, so a reader would deserialize rubbish. Recreated with the right
			// type instead.
			if (existing.TypeName == typeName)
				return existing;
			mCookedDb.DeleteInstance(item.Source).IgnoreError();
		}

		let source = mSourceDb.GetInstance(item.Source);
		if (source == null)
			return null;
		let group = MirrorGroup(source.OwningGroup);

		// The same guard for a NAME collision: creating with an identity returns an existing
		// same named instance whatever ITS identity is, so a stale product from an earlier
		// generation, not yet swept, would silently keep its old one and break the rule that a
		// product carries its source's identity.
		if (let stale = group.GetInstance(source.Name))
		{
			if (stale.Id != item.Source)
				mCookedDb.DeleteInstance(stale.Id).IgnoreError();
		}

		return group.CreateInstanceWithId(item.Source, source.Name, typeName);
	}

	/// Cooks one item into its pre-created product and records what it did. Runs on a WORKER:
	/// no database mutation, only reads and this product's own file writes.
	private bool CookOne(CookItem item)
	{
		let source = item.SourceInstance;
		let asset = (item.AssetObject != null)
			? Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(item.AssetObject)) as Asset
			: null;
		if ((source == null) || (asset == null) || (item.Product == null))
			return false;

		let context = scope AssetBuildContext();
		context.Sources = mSources;
		context.Source = source;
		context.Output = item.Product;
		context.Database = mCookedDb;      // a cross reference resolves against cooked products
		context.SourceDatabase = mSourceDb; // and a cross asset SOURCE read against envelopes
		context.Serializers = mCookedDb.Serializers;
		context.Target = mTarget;
		context.Jobs = mJobs;

		let built = item.Builder.Build(asset, context);
		let ok = built case .Ok;

		StampRecord(item, !ok);
		if (!ok)
			GlobalLog(.Error, "Cook: '{}' failed to cook", item.Path);

		// The source object goes NOW rather than when the plan does: keeping every item's
		// deserialised object alive until the whole cook finished runs a large scene out of
		// memory.
		delete item.AssetObject;
		item.AssetObject = null;
		return ok;
	}

	/// Updates the record for an item. A FAILURE keeps the last good product but stays dirty,
	/// since a failed record never satisfies a clean check.
	private void StampRecord(CookItem item, bool failed)
	{
		using (mRecordLock.Enter())
		{
			let record = mDb.Upsert(item.Source);
			record.RecipeHash = item.RecipeHash;
			record.Failed = failed;

			if (mPendingMemos.GetAndRemove(item.Source) case .Ok(let entry))
			{
				ClearAndDeleteItems!(record.Files);
				record.Files.AddRange(entry.value);
				delete entry.value;
			}

			record.Reads.Clear();
			record.Reads.AddRange(item.Deps.Reads);
			record.References.Clear();
			record.References.AddRange(item.Deps.References);
		}
	}

	/// The cooked database group mirroring the source instance's.
	private Group MirrorGroup(Group sourceGroup)
	{
		let chain = scope List<StringView>();
		for (var walk = sourceGroup; (walk != null) && !walk.Name.IsEmpty; walk = walk.Parent)
			chain.Add(walk.Name);

		var group = mCookedDb.RootGroup;
		for (int i = chain.Count; i > 0; --i)
			group = group.CreateGroup(chain[i - 1]);
		return group;
	}

	private static void SortByLevel(List<CookItem> items)
	{
		// An insertion sort, which is STABLE: a plan is small and mostly ordered already, and
		// stability is what keeps two items at the same level in registration order.
		for (int i = 1; i < items.Count; ++i)
		{
			var j = i;
			while ((j > 0) && (items[j - 1].Level > items[j].Level))
			{
				let swap = items[j - 1];
				items[j - 1] = items[j];
				items[j] = swap;
				j--;
			}
		}
	}
}
