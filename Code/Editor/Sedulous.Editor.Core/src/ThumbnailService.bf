using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.Image;
using Sedulous.Image.IO;
using Sedulous.UI;
using Sedulous.VFS;

namespace Sedulous.Editor.Core;

/// Asset thumbnails: resolves a content instance's guid to a small preview drawable. Icon
/// first display is the CONSUMER's job; Get returns null until a thumbnail exists and
/// OnThumbnailReady fires the swap in. Nothing here blocks the UI.
///
/// Per asset type generators, registered by the app, unknown types keeping their icon, run
/// on the job service's LIGHT lane; results land in a content keyed disk cache,
/// <project>/.cache/thumbs/<guid>-<recipeHash>.png, a stale hash detected by the file name
/// and replaced, deleting the directory always safe, and in a map of OWNING drawables.
///
/// Threading: Get, Invalidate and OnThumbnailReady are MAIN thread; generation and PNG IO
/// run on the light worker; completion fires on the main thread from the job service's
/// Update. An in flight job owns a heap slot both closures see, so a Reset mid flight is
/// safe: the slot's alive flag is cleared and the completion still deletes it.
///
/// One per open project: the app Configures it on open and Resets it on close.
class ThumbnailService
{
	public typealias Resolve = delegate Instance(Guid id);
	public typealias ContentHash = delegate uint64(Guid id);

	/// The thumbnail edge, square; the generators letterbox to it.
	public const uint32 cThumbnailSize = 128;
	/// The scheduling budget: at most this many loads in flight, so a bind sweep over a big
	/// folder trickles instead of flooding the light lane; the NEXT Get for a skipped id
	/// schedules it once a slot frees, every bind re-querying.
	public const int cMaxInFlight = 8;

	/// An entry with a null drawable is the negative cache: no thumbnail, stop scheduling.
	private class Entry
	{
		public OwnedThumbnailDrawable Drawable = null ~ { if (_ != null) _.ReleaseRef(); };
	}

	/// The heap slot both closures own. The flags are main thread; the worker touches only
	/// Pixels, Ok, Negative and StaleDiskFile.
	private class JobSlot
	{
		public Guid Id = .Empty;
		/// Cleared by Reset; the completion then only frees the slot.
		public bool ServiceAlive = true;
		public bool Ok = false;
		/// Cache "no thumbnail".
		public bool Negative = false;
		/// The disk cache failed to load AND there is no payload to regenerate from, Prepare
		/// having been skipped because the file existed: delete it, retry fully next Get.
		public bool StaleDiskFile = false;
		/// The worker's output; handed to the drawable on success.
		public Image Pixels = new .() ~ delete _;
		public List<uint8> Payload = new .() ~ delete _;
		/// Empty is RAM only: an unknown content hash.
		public String DiskPath = new .() ~ delete _;
		/// Borrowed; the generators live on the service. Null on a load only slot.
		public IThumbnailGenerator Generator = null;
	}

	private String mCacheDirectory = new .() ~ delete _;
	private NativeFileSystem mSources = null ~ delete _;
	private Resolve mResolve = null ~ delete _;
	private ContentHash mContentHash = null ~ delete _;
	private EditorJobService mJobs = null;
	private List<IThumbnailGenerator> mGenerators = new .() ~ DeleteContainerAndItems!(_);
	private List<ISceneThumbnailGenerator> mSceneGenerators = new .() ~ DeleteContainerAndItems!(_);
	private Dictionary<Guid, Entry> mEntries = new .() ~ DeleteDictionaryAndValues!(_);
	private List<JobSlot> mInFlight = new .() ~ delete _;
	private List<SceneThumbnailJob> mSceneQueue = new .() ~ delete _;
	private bool mSceneJobActive = false;
	private Guid mActiveSceneJob = .Empty;

	/// The swap in signal: a thumbnail for this guid became available. MAIN thread.
	public delegate void(Guid id) OnThumbnailReady ~ delete _;

	public ~this()
	{
		Reset();
	}

	/// TAKES OWNERSHIP.
	public void RegisterGenerator(IThumbnailGenerator generator) => mGenerators.Add(generator);
	public void RegisterSceneGenerator(ISceneThumbnailGenerator generator) => mSceneGenerators.Add(generator);
	public int GeneratorCount => mGenerators.Count;
	public int SceneGeneratorCount => mSceneGenerators.Count;

	/// Project open wiring: where the cache lives, how to resolve instances, the job lane,
	/// the content hash source and the sources root. Previous state is dropped; the delegates
	/// are OWNED.
	public void Configure(StringView cacheDirectory, Resolve resolve, EditorJobService jobs,
		ContentHash contentHash, StringView sourcesRoot)
	{
		Reset();
		mCacheDirectory.Set(cacheDirectory);
		mResolve = resolve;
		mJobs = jobs;
		mContentHash = contentHash;
		mSources = new NativeFileSystem(sourcesRoot);
	}

	/// Project close: drops the cache and detaches. An in flight job completes harmlessly
	/// against its slot.
	public void Reset()
	{
		for (let slot in mInFlight)
			slot.ServiceAlive = false;
		mInFlight.Clear();
		mSceneQueue.Clear();
		mSceneJobActive = false;
		mActiveSceneJob = .Empty;
		DeleteDictionaryAndValues!(mEntries);
		mEntries = new .();
		mCacheDirectory.Clear();
		DeleteAndNullify!(mResolve);
		DeleteAndNullify!(mContentHash);
		mJobs = null;
		DeleteAndNullify!(mSources);
	}

	/// The resolved thumbnail, BORROWED, or null when none exists yet and the caller keeps
	/// its type icon. A miss schedules a load or a generate on the light lane and
	/// OnThumbnailReady fires when the swap in is ready. Main thread only.
	public Drawable Get(Guid id)
	{
		if (!id.IsSet || (mJobs == null) || (mResolve == null))
			return null;
		if (mEntries.TryGetValue(id, let entry))
			return entry.Drawable;
		ScheduleLoad(id);
		return null;
	}

	/// Drops a cached thumbnail, on a cook or an import; the next Get regenerates. The hash
	/// named files make even a missed invalidation self healing.
	public void Invalidate(Guid id)
	{
		if (mEntries.GetAndRemove(id) case .Ok(let pair))
			delete pair.value;
	}

	/// Drops the whole cache, a cook having finished and the hashes moved. An unchanged asset
	/// reloads from its unchanged file, cheap; a changed one regenerates.
	public void InvalidateAll()
	{
		DeleteDictionaryAndValues!(mEntries);
		mEntries = new .();
	}

	public int CachedCount => mEntries.Count;

	// ---- the GPU lane, driven by the stage one job at a time ----

	/// The next queued GPU job, or an empty one. The job stays taken until AcceptSceneResult
	/// for its id; a second call while one is out returns empty, the one in flight rule.
	public SceneThumbnailJob TakeSceneJob()
	{
		if (mSceneJobActive || mSceneQueue.IsEmpty)
			return .();
		let job = mSceneQueue.PopFront();
		mSceneJobActive = true;
		mActiveSceneJob = job.Id;
		return job;
	}

	/// The stage finished, or failed, the active job: published exactly like a CPU generate,
	/// the PNG on the light lane, the entry, OnThumbnailReady. TAKES OWNERSHIP of `pixels`.
	/// A failure caches a negative so Get stops rescheduling until Invalidate.
	public void AcceptSceneResult(Guid id, Image pixels, bool ok)
	{
		// Only the ACTIVE job may complete; a Reset between Take and Accept cleared the
		// flag and the result is dropped.
		if (!mSceneJobActive || (mActiveSceneJob != id))
		{
			delete pixels;
			return;
		}
		mSceneJobActive = false;
		mActiveSceneJob = .Empty;
		if (!ok)
		{
			GlobalLog(.Warning, "Thumbnails: stage render failed for {} (cached negative)", id);
			delete pixels;
			Store(id, null);
			return;
		}
		// Persisted on the light lane, the PNG encode off the main thread, and published
		// now: the drawable owns its pixels, so the UI swaps in before the file lands.
		let hash = (mContentHash != null) ? mContentHash(id) : 0;
		if ((hash != 0) && (mJobs != null))
		{
			let file = new Image(pixels.Width, pixels.Height, pixels.Format, pixels.PixelData);
			file.SetColorSpace(pixels.ColorSpace);
			let path = new String();
			CachePathFor(id, hash, path);
			mJobs.SubmitLight(new [=file, =path]() => { ImageIO.SaveImage(file, path, .PNG).IgnoreError(); },
				new [=file, =path]() => { delete file; delete path; });
		}
		let drawable = new OwnedThumbnailDrawable(pixels);
		Store(id, drawable);
		if (OnThumbnailReady != null)
			OnThumbnailReady(id);
	}

	public int QueuedSceneJobs => mSceneQueue.Count + (mSceneJobActive ? 1 : 0);

	// ---- the light lane ----

	private void ScheduleLoad(Guid id)
	{
		if (mInFlight.Count >= cMaxInFlight)
			return;
		for (let flight in mInFlight)
			if (flight.Id == id)
				return;
		let instance = mResolve(id);
		if (instance == null)
		{
			Store(id, null);
			return;
		}
		let generator = GeneratorFor(instance.TypeName);
		let sceneGenerator = (generator == null) ? SceneGeneratorFor(instance.TypeName) : null;
		if ((generator == null) && (sceneGenerator == null))
		{
			Store(id, null);
			return;
		}

		let slot = new JobSlot();
		slot.Id = id;
		slot.Generator = generator;
		// An unknown content hash, mid cook or no record yet, is RAM only: never a cache
		// file that can never match again. The cook finished invalidation regenerates with
		// the real hash and THEN persists.
		let hash = (mContentHash != null) ? mContentHash(id) : 0;
		if (hash != 0)
			CachePathFor(id, hash, slot.DiskPath);
		let diskHit = !slot.DiskPath.IsEmpty && FileExists(slot.DiskPath);

		if (generator == null)
		{
			// A GPU generated type with no cached file goes to the scene queue; a cached file
			// loads on the light lane like any other, a stale one self healing through the
			// StaleDiskFile path which then queues the GPU job.
			if (!diskHit)
			{
				delete slot;
				if (mActiveSceneJob == id)
					return;
				for (let queued in mSceneQueue)
					if (queued.Id == id)
						return;
				mSceneQueue.Add(.() { Id = id, Generator = sceneGenerator });
				return;
			}
		}
		else if (!diskHit)
		{
			// MAIN thread Prepare: the worker never touches the content database. A failure
			// is a negative entry, logged once here rather than every frame.
			if (generator.Prepare(instance, mSources, slot.Payload) case .Err(let error))
			{
				GlobalLog(.Warning, "Thumbnails: prepare failed for '{}' ({}): {}", instance.Name, instance.TypeName, error);
				Store(id, null);
				delete slot;
				return;
			}
		}

		mInFlight.Add(slot);
		mJobs.SubmitLight(new [=slot]() => { Produce(slot); }, new [=slot, =this]() => { CompleteLoad(slot); });
	}

	/// LIGHT worker: the disk cache first, else generate and persist.
	private static void Produce(JobSlot slot)
	{
		if (!slot.DiskPath.IsEmpty && (ImageIO.LoadImage(slot.DiskPath, slot.Pixels) case .Ok))
		{
			slot.Ok = true;
			return;
		}
		if ((slot.Generator == null) || (slot.Payload.IsEmpty && !slot.DiskPath.IsEmpty))
		{
			// A load only slot whose file would not load, or a file that existed at
			// schedule time and is stale or corrupt: delete it and retry fully next Get.
			slot.StaleDiskFile = true;
			return;
		}
		if (slot.Generator.Generate(slot.Payload, slot.Pixels) case .Err)
		{
			slot.Negative = true;
			return;
		}
		slot.Ok = true;
		if (!slot.DiskPath.IsEmpty)
			ImageIO.SaveImage(slot.Pixels, slot.DiskPath, .PNG).IgnoreError();
	}

	/// Main thread. The service may have been Reset mid flight; the slot's flag is the guard
	/// and the slot is always deleted here.
	private void CompleteLoad(JobSlot slot)
	{
		if (slot.ServiceAlive)
		{
			mInFlight.Remove(slot);
			if (slot.Ok)
			{
				let pixels = slot.Pixels;
				slot.Pixels = null;
				Store(slot.Id, new OwnedThumbnailDrawable(pixels));
				if (OnThumbnailReady != null)
					OnThumbnailReady(slot.Id);
			}
			else if (slot.StaleDiskFile)
			{
				// The unloadable file goes and NOTHING is cached: the next Get takes the
				// full path and overwrites it.
				GlobalLog(.Warning, "Thumbnails: stale cache file replaced for {}", slot.Id);
				DeleteFile(slot.DiskPath);
			}
			else
			{
				GlobalLog(.Warning, "Thumbnails: generate failed for {} (cached negative)", slot.Id);
				Store(slot.Id, null);
			}
		}
		delete slot;
	}

	/// Inserts or replaces the entry; a null drawable is the negative cache.
	private void Store(Guid id, OwnedThumbnailDrawable drawable)
	{
		if (mEntries.GetAndRemove(id) case .Ok(let pair))
			delete pair.value;
		let entry = new Entry();
		entry.Drawable = drawable;
		mEntries[id] = entry;
	}

	private IThumbnailGenerator GeneratorFor(StringView typeName)
	{
		let names = scope List<StringView>();
		for (let generator in mGenerators)
		{
			names.Clear();
			generator.AssetTypeNames(names);
			for (let covered in names)
				if (AssetTypeNames.Matches(typeName, covered))
					return generator;
		}
		return null;
	}

	private ISceneThumbnailGenerator SceneGeneratorFor(StringView typeName)
	{
		let names = scope List<StringView>();
		for (let generator in mSceneGenerators)
		{
			names.Clear();
			generator.AssetTypeNames(names);
			for (let covered in names)
				if (AssetTypeNames.Matches(typeName, covered))
					return generator;
		}
		return null;
	}

	private void CachePathFor(Guid id, uint64 hash, String outPath)
	{
		outPath.Clear();
		outPath.AppendF("{}/{}-{}.png", mCacheDirectory, id, hash);
	}
}
