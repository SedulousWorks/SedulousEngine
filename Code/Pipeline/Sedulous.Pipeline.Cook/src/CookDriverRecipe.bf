using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Pipeline.Core;
using Sedulous.VFS;

namespace Sedulous.Pipeline.Cook;

/// The recipe hash and the dependency depth, which is what decides whether anything cooks at
/// all.
extension CookDriver
{
	/// Every input folded into one number: the envelope, the source files, the declared
	/// streams, the builder's version, the target where it matters, and the recipes of what
	/// this reads.
	///
	/// Guarded against a read dependency CYCLE by depth rather than by a visited set, because
	/// the memo already collapses a diamond and only a real cycle can reach the limit.
	private uint64 ComputeRecipe(Instance instance, Asset asset, IAssetBuilder builder,
		AssetDependencies deps, int32 depth)
	{
		if (mRecipeMemo.TryGetValue(instance.Id, let memo))
			return memo;
		if (depth > cMaxDepth)
		{
			GlobalLog(.Warning, "Cook: a read dependency cycle reaches '{}'",
				instance.GetPath(.. scope String()));
			return 0;
		}

		var h = HashBytes(null, 0);

		// The source envelope, which carries the import settings, the identity and the
		// directory of embedded streams.
		{
			let envelope = instance.OpenEnvelope();
			let envelopeHash = (envelope != null) ? RecipeHash.HashStream(envelope) : 0;
			if (envelope != null)
				delete envelope;
			h = RecipeHash.Fold(h, (uint64)'E', envelopeHash);
		}

		// The source files: the implicit one, then the declared extras in declaration order.
		let previous = mDb.Find(instance.Id);
		let memos = new List<CookFileMemo>();
		if (!asset.FileName.IsEmpty)
			h = RecipeHash.Fold(h, (uint64)'F', HashSourceFile(asset.FileName.Value, previous, memos));
		for (let file in deps.Files)
			h = RecipeHash.Fold(h, (uint64)'F', HashSourceFile(file.Value, previous, memos));

		if (mPendingMemos.GetAndRemove(instance.Id) case .Ok(let stale))
			DeleteContainerAndItems!(stale.value);
		mPendingMemos[instance.Id] = memos;

		// The declared embedded streams, which are sidecar files the envelope's own hash does
		// not cover.
		for (let streamName in deps.SourceStreams)
		{
			let stream = instance.ReadData(streamName);
			h = RecipeHash.Fold(h, (uint64)'S', (stream != null) ? RecipeHash.HashStream(stream) : 0);
			if (stream != null)
				delete stream;
		}

		// The builder's own version, which is how a cook logic change forces a re-cook.
		h = RecipeHash.Fold(h, (uint64)'V', (uint64)builder.Version);

		// The platform salt, on a VARIANT builder ONLY, so the same source produces a distinct
		// product per target while an invariant one keeps a target independent recipe and can
		// copy forward untouched.
		if (builder.Variance == .PlatformVariant)
		{
			h = RecipeHash.Fold(h, (uint64)'T',
				HashBytes(mTarget.Id.Ptr, mTarget.Id.Length, HashBytes(null, 0)));
		}

		// The reads, SORTED so the fold is deterministic, each chained recursively.
		let reads = scope List<Guid>();
		reads.AddRange(deps.Reads);
		SortGuids(reads);
		for (var read in reads)
		{
			h = RecipeHash.Fold(h, (uint64)'R', RecipeOf(read, depth + 1));
			// The identity's own BYTES rather than its fields, which are private: what the
			// fold needs is that a different identity hashes differently, not which half of it
			// went in first.
			h = RecipeHash.Fold(h, (uint64)'G', HashBytes(&read, sizeof(Guid), HashBytes(null, 0)));
		}

		mRecipeMemo[instance.Id] = h;
		return h;
	}

	/// The recipe of a read dependency, or nought when it is not something this build cooks.
	private uint64 RecipeOf(Guid read, int32 depth)
	{
		let dep = mSourceDb.GetInstance(read);
		if (dep == null)
			return 0;

		let typeName = scope String();
		dep.TypeName.ToString(typeName);
		let depBuilder = mBuilders.FindByTypeName(typeName);
		if (depBuilder == null)
			return 0;

		let depObject = dep.ReadObject();
		if (depObject == null)
			return 0;
		defer delete depObject;

		let depAsset = Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(depObject)) as Asset;
		if (depAsset == null)
			return 0;

		let scanContext = scope AssetBuildContext();
		scanContext.Sources = mSources;
		scanContext.Database = mSourceDb;
		let depDeps = scope AssetDependencies();
		depBuilder.ScanDependencies(depAsset, scanContext, depDeps);
		return ComputeRecipe(dep, depAsset, depBuilder, depDeps, depth);
	}

	/// One source file's content hash, MEMOIZED against the previous record by size and
	/// modification time where the mount can answer for them.
	///
	/// A missing file hashes as nought, which still changes the recipe when it appears.
	private uint64 HashSourceFile(StringView path, CookRecord previous, List<CookFileMemo> outMemos)
	{
		let stat = mSources as IStatFileSystem;
		FileStatInfo info = default;
		let hasStat = (stat != null) && stat.Stat(path, out info);

		if (hasStat && (previous != null))
		{
			for (let old in previous.Files)
			{
				if ((old.Path == path) && (old.Size == info.Size)
					&& (old.ModifiedTicks == info.ModifiedTicks))
				{
					// Untouched since the last cook, so its hash stands and the file is never
					// read.
					let memo = new CookFileMemo();
					memo.Path.Set(old.Path);
					memo.Size = old.Size;
					memo.ModifiedTicks = old.ModifiedTicks;
					memo.ContentHash = old.ContentHash;
					outMemos.Add(memo);
					return memo.ContentHash;
				}
			}
		}

		uint64 hash = 0;
		if (mSources != null)
		{
			let stream = mSources.Open(path, .Read);
			if (stream != null)
			{
				hash = RecipeHash.HashStream(stream);
				delete stream;
			}
		}

		let memo = new CookFileMemo();
		memo.Path.Set(path);
		memo.ContentHash = hash;
		if (hasStat)
		{
			memo.Size = info.Size;
			memo.ModifiedTicks = info.ModifiedTicks;
		}
		outMemos.Add(memo);
		return hash;
	}

	/// How deep an item's read chain runs, which is the level it cooks at: nought reads first.
	private int32 ReadDepth(Guid source, AssetDependencies deps, Dictionary<Guid, int32> levels,
		int32 depth)
	{
		if (levels.TryGetValue(source, let known))
			return known;
		if (depth > cMaxDepth)
			return depth; // a cycle, already warned about while hashing

		int32 level = 0;
		for (let read in deps.Reads)
		{
			let dep = mSourceDb.GetInstance(read);
			if (dep == null)
				continue;

			let typeName = scope String();
			dep.TypeName.ToString(typeName);
			let depBuilder = mBuilders.FindByTypeName(typeName);
			if (depBuilder == null)
				continue;

			let depObject = dep.ReadObject();
			if (depObject == null)
				continue;
			defer delete depObject;

			let depAsset = Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(depObject)) as Asset;
			if (depAsset == null)
				continue;

			let scanContext = scope AssetBuildContext();
			scanContext.Sources = mSources;
			scanContext.Database = mSourceDb;
			let depDeps = scope AssetDependencies();
			depBuilder.ScanDependencies(depAsset, scanContext, depDeps);

			let depLevel = ReadDepth(read, depDeps, levels, depth + 1);
			if ((depLevel + 1) > level)
				level = depLevel + 1;
		}

		levels[source] = level;
		return level;
	}

	/// Sorted by their BYTES, which is all determinism needs: the fold must see the same order
	/// every time, and which order that is does not matter.
	private static void SortGuids(List<Guid> guids)
	{
		guids.Sort(scope (a, b) =>
			{
				var left = a;
				var right = b;
				return Internal.MemCmp(&left, &right, sizeof(Guid));
			});
	}
}
