namespace Sedulous.Editor.Core;

using System;
using System.IO;
using System.Collections;
using Sedulous.UI;
using Sedulous.Images;
using Sedulous.Core.Logging.Abstractions;
using Sedulous.VFS;
using Sedulous.VFS.Disk;

/// Holds one cached thumbnail. Owns its pixel data and the drawable that wraps
/// it; the service deletes both when the entry is evicted or invalidated.
class CachedThumbnail
{
	public Guid Id;
	public OwnedImageData Data ~ delete _;
	public ImageDrawable Drawable ~ _.ReleaseRef();
	public int64 SourceMtime;
	public int32 Width;
	public int32 Height;
}

/// One outstanding thumbnail request. Owned by the service while it sits in
/// the pending queue; the requesting cell holds a non-owning handle so it can
/// cancel before delivery. After the request finalizes (delivered or cancelled)
/// the service deletes the request.
///
/// `OwnerSlot` is a back-pointer to the cell's handle field. The service nulls
/// `*OwnerSlot` whenever it's about to delete the request (completion,
/// cancellation, or service shutdown) so the cell can't end up holding a
/// stale pointer. Cells that may outlive the service need to clear OwnerSlot
/// from their destructor; cells that may NOT outlive the service can rely on
/// the service to null their field for them.
class ThumbnailRequest
{
	public Guid Id;
	public String Uri = new .() ~ delete _;
	public String Extension = new .() ~ delete _;
	public int32 Width;
	public int32 Height;
	public delegate void(Drawable) OnReady ~ if (OwnsCallback) delete _;
	public bool OwnsCallback = true;
	public bool Cancelled;
	public ThumbnailRequest* OwnerSlot;

	/// Completion delegate handed to an async generator. Owned by the
	/// request so the service can free it after the generator's callback
	/// fires. Null for sync generators.
	public delegate void(OwnedImageData) AsyncCompletion ~ if (_ != null) delete _;
}

/// Asset thumbnail cache + dispatcher. Cells call `Request` to get a thumbnail
/// for an asset; the service answers from its in-memory cache synchronously,
/// from a disk cache on a later frame, or runs a per-extension generator (as
/// registered through `EditorContext.RegisterThumbnailGenerator`). When a
/// generator isn't registered the request resolves with a null drawable and
/// the cell keeps its default icon.
///
/// Generator dispatch is throttled - at most a couple of requests run per
/// frame from `Update()` so a folder full of textures doesn't stall the UI.
/// Disk cache writes happen inline after generation; reads happen inline
/// during request processing. Source mtime is recorded in a sidecar `.meta`
/// file next to each `.png` so stale entries get regenerated.
class ThumbnailService
{
	private EditorContext mContext;
	private ILogger mLogger;

	/// `<projectRoot>/.editor/thumbnails/` once a project is opened; empty
	/// otherwise. Empty disables disk caching - everything lives in memory.
	private String mDiskCacheDir = new .() ~ delete _;

	private Dictionary<Guid, CachedThumbnail> mCache = new .() ~ {
		for (let kv in _) delete kv.value;
		delete _;
	};

	private Queue<ThumbnailRequest> mPending = new .() ~ {
		// On shutdown null every still-pending request's owner slot so cells
		// outliving the service don't see a dangling pointer, then free the
		// requests themselves (the queue destructor only frees its own
		// internal array; without this the queued requests leak).
		for (let req in _)
		{
			if (req.OwnerSlot != null) *req.OwnerSlot = null;
			delete req;
		}
		delete _;
	};

	/// Requests currently dispatched to async generators - kept alive
	/// until the generator's completion callback fires. On shutdown we
	/// null OwnerSlot pointers (so any surviving cells don't dereference
	/// freed memory) and free the requests outright. The generator's
	/// closure still references the freed request, so the editor must
	/// drain in-flight async work before destroying the service - the
	/// editor's shutdown sequence guarantees the GPU is idle and all
	/// pending CompleteAsync callbacks have fired before this point.
	/// The list is owning so each surviving request is freed here too.
	private List<ThumbnailRequest> mInFlightAsync = new .() ~ {
		for (let req in _)
		{
			if (req.OwnerSlot != null) *req.OwnerSlot = null;
			delete req;
		}
		delete _;
	};

	/// Maximum number of pending requests processed per `Update()` call.
	/// Keeps a folder full of textures from stalling a single frame; the
	/// remaining requests light up over the next few frames.
	public int32 MaxRequestsPerFrame = 2;

	public this(EditorContext context, ILogger logger)
	{
		mContext = context;
		mLogger = logger;
	}

	/// Point the service at a project's disk cache directory. Creates the
	/// directory if it doesn't exist. Passing an empty StringView disables
	/// disk caching (e.g. when no project is open).
	public void SetProjectDirectory(StringView projectDir)
	{
		mDiskCacheDir.Clear();
		if (projectDir.Length == 0) return;

		mDiskCacheDir.Append(projectDir);
		// Use forward-slash uniformly - the rest of the editor mostly does.
		if (!mDiskCacheDir.EndsWith("/") && !mDiskCacheDir.EndsWith("\\"))
			mDiskCacheDir.Append('/');
		mDiskCacheDir.Append(".editor/thumbnails");

		if (!Directory.Exists(mDiskCacheDir))
		{
			if (Directory.CreateDirectory(mDiskCacheDir) case .Err(let err))
			{
				mLogger?.LogWarning("ThumbnailService: failed to create cache dir {}: {}", mDiskCacheDir, err);
				mDiskCacheDir.Clear();
			}
		}
	}

	/// Drain up to `MaxRequestsPerFrame` pending requests. Call once per
	/// frame from the main thread. Snapshots the queue size at the top
	/// so requests requeued during this tick (e.g., async generator
	/// declined transiently) wait until next frame instead of being
	/// re-processed in a loop.
	public void Update()
	{
		// Process up to MaxRequestsPerFrame NON-cancelled requests per
		// frame. Cancellations are essentially free (just delete) so
		// we don't count them against the budget - otherwise asset
		// cells that rebind every frame (e.g., scroll, layout pass)
		// fill the queue with stale cancellations that crowd out real
		// work. `MaxPopsPerFrame` caps absolute popping so a huge
		// queue of cancellations doesn't burn an entire frame.
		// `snapshotCount` ensures requests requeued by declined async
		// generators wait until next frame rather than spinning.
		const int32 MaxPopsPerFrame = 64;
		var slotsLeft = MaxRequestsPerFrame;
		var popsLeft = MaxPopsPerFrame;
		let snapshotCount = mPending.Count;
		var popped = 0;
		while (slotsLeft > 0 && popsLeft > 0 && popped < snapshotCount && mPending.Count > 0)
		{
			let req = mPending.PopFront();
			popsLeft--;
			popped++;
			let wasCancelled = req.Cancelled;
			FinalizeRequest(req); // sync path: deletes req. Async: keeps it alive or re-queues.
			if (!wasCancelled)
				slotsLeft--;
		}
	}

	/// Request a thumbnail for an asset. `ownerSlot` is the address of the
	/// caller's handle field - the service nulls `*ownerSlot` automatically
	/// when the request is delivered, cancelled, or the service shuts down,
	/// so the caller never sees a dangling pointer. Returns the same handle
	/// (also stored at `*ownerSlot`) or null when resolved synchronously
	/// (cache hit, no generator registered, empty Guid). Caller must call
	/// `Cancel(handle)` on rebind / detach so the request is dropped without
	/// firing a stale callback.
	public ThumbnailRequest Request(Guid id, StringView uri, StringView @extension,
		int32 width, int32 height,
		delegate void(Drawable) onReady, bool ownsCallback = true,
		ThumbnailRequest* ownerSlot = null)
	{
		// Empty Guid means the asset isn't registered - we have no stable
		// identity for the cache, so don't generate anything.
		if (id == .())
		{
			onReady(null);
			if (ownsCallback) delete onReady;
			return null;
		}

		// Memory cache hit: deliver immediately.
		if (mCache.TryGetValue(id, let cached))
		{
			onReady(cached.Drawable);
			if (ownsCallback) delete onReady;
			return null;
		}

		// Confirm a generator exists before queuing - no point in dispatching
		// a request whose generator is null.
		if (mContext.GetThumbnailGenerator(@extension) == null)
		{
			onReady(null);
			if (ownsCallback) delete onReady;
			return null;
		}

		let req = new ThumbnailRequest();
		req.Id = id;
		req.Uri.Set(uri);
		req.Extension.Set(@extension);
		req.Width = width;
		req.Height = height;
		req.OnReady = onReady;
		req.OwnsCallback = ownsCallback;
		req.OwnerSlot = ownerSlot;
		mPending.Add(req);
		return req;
	}

	/// Cancel a pending request. After this call returns, the request will
	/// not invoke its callback. The service still defers the actual delete
	/// to a later `Update()` so a cell calling Cancel inside its destructor
	/// doesn't race with the service - just mark it dead. The OwnerSlot is
	/// nulled here too so any subsequent access through the cell's handle
	/// is a safe no-op.
	public void Cancel(ThumbnailRequest req)
	{
		if (req == null) return;
		req.Cancelled = true;
		if (req.OwnerSlot != null)
		{
			*req.OwnerSlot = null;
			req.OwnerSlot = null;
		}
	}

	/// Common cleanup path - nulls OwnerSlot, runs ProcessRequest if the
	/// request wasn't cancelled. Sync requests are deleted here; async
	/// requests are transferred to mInFlightAsync and deleted when the
	/// generator's completion callback fires.
	private void FinalizeRequest(ThumbnailRequest req)
	{
		// Null out the cell's handle BEFORE running the callback or deleting
		// the request, so the cell can't read a stale pointer even from
		// within its own callback.
		if (req.OwnerSlot != null)
		{
			*req.OwnerSlot = null;
			req.OwnerSlot = null;
		}

		if (req.Cancelled)
		{
			delete req;
			return;
		}

		// Process the request; sync generators run inline, async ones hold
		// onto `req` via mInFlightAsync until their completion fires.
		bool ownedByService = ProcessRequest(req);
		if (!ownedByService)
			delete req;
	}

	/// Discard the cached thumbnail for an asset (memory + disk). Useful
	/// when the source asset is known to have changed.
	public void Invalidate(Guid id)
	{
		if (mCache.TryGetValue(id, let cached))
		{
			delete cached;
			mCache.Remove(id);
		}

		if (mDiskCacheDir.Length > 0)
		{
			let png = scope String();
			BuildDiskPath(id, ".png", png);
			let meta = scope String();
			BuildDiskPath(id, ".meta", meta);
			if (File.Exists(png)) File.Delete(png).IgnoreError();
			if (File.Exists(meta)) File.Delete(meta).IgnoreError();
		}
	}

	// ==================== Internals ====================

	/// Runs the generator for this request. Returns true if the service
	/// now owns the request (async path; caller must NOT delete it - the
	/// async completion will), false if the request has been resolved
	/// synchronously and the caller should delete it.
	private bool ProcessRequest(ThumbnailRequest req)
	{
		// Disk-cache hit + fresh -> load and serve.
		if (TryLoadFromDisk(req, var loaded))
		{
			InsertOrReplaceCache(req.Id, loaded);
			req.OnReady(loaded.Drawable);
			return false;
		}

		let gen = mContext.GetThumbnailGenerator(req.Extension);
		if (gen == null)
		{
			req.OnReady(null);
			return false;
		}

		// Async generator: dispatch and keep `req` alive in mInFlightAsync.
		// The completion callback we hand the generator owns delivery +
		// cleanup; service deletes both the request and the callback after
		// the generator invokes it.
		if (let asyncGen = gen as IAsyncAssetThumbnailGenerator)
		{
			// Stash the delegate on the request so the request's destructor
			// frees it (Beef requires explicit delete for `new` delegates).
			req.AsyncCompletion = new (data) => CompleteAsyncRequest(req, data);
			if (asyncGen.GenerateThumbnailAsync(req.Uri, req.Width, req.Height, req.AsyncCompletion))
			{
				// Accepted; the completion callback will fire on a later
				// frame and finalize the request.
				mInFlightAsync.Add(req);
				return true;
			}

			// Declined transiently (e.g., GPU renderer already has a job
			// in flight). Re-queue at the back of mPending so other items
			// get a chance first, then we try again next frame. Free the
			// completion delegate the generator didn't get to use; a new
			// one will be created when we retry.
			delete req.AsyncCompletion;
			req.AsyncCompletion = null;
			mPending.Add(req);
			return true; // service still owns req via mPending
		}

		// Sync generator path.
		OwnedImageData data = null;
		if (gen.GenerateThumbnail(req.Uri, req.Width, req.Height) case .Ok(let result))
			data = result;

		if (data == null)
		{
			mLogger?.LogWarning("Thumbnail generation failed for {} (extension {})", req.Uri, req.Extension);
			req.OnReady(null);
			return false;
		}

		FinishAsImage(req, data);
		return false;
	}

	/// Completes an async request after the generator delivers pixel data.
	/// Runs on the editor's main thread (the async generator is responsible
	/// for marshalling there). Handles both success (data != null) and
	/// failure (data == null) paths, and the cancellation race where the
	/// cell was unbound while GPU work was in flight.
	private void CompleteAsyncRequest(ThumbnailRequest req, OwnedImageData data)
	{
		// Remove from in-flight tracking. If we can't find it, it's already
		// been removed (shouldn't happen, but be defensive).
		mInFlightAsync.Remove(req);

		if (req.Cancelled)
		{
			// Cell unbound while GPU work was running; drop the pixels.
			if (data != null) delete data;
			delete req;
			return;
		}

		if (data == null)
		{
			mLogger?.LogWarning("Async thumbnail generation failed for {} (extension {})", req.Uri, req.Extension);
			req.OnReady(null);
			delete req;
			return;
		}

		FinishAsImage(req, data);
		delete req;
	}

	/// Shared finalization for sync + async success paths: build the
	/// cached entry, save it to disk, and deliver the drawable.
	private void FinishAsImage(ThumbnailRequest req, OwnedImageData data)
	{
		let drawable = new ImageDrawable(data);
		let entry = new CachedThumbnail();
		entry.Id = req.Id;
		entry.Data = data;
		entry.Drawable = drawable;
		entry.Width = req.Width;
		entry.Height = req.Height;
		entry.SourceMtime = GetSourceMtime(req.Uri);

		InsertOrReplaceCache(req.Id, entry);
		SaveToDisk(req, entry);
		req.OnReady(drawable);
	}

	/// Insert into mCache, deleting any prior entry for the same id so it
	/// doesn't leak. Dictionary indexer assignment overwrites the value
	/// without disposing the old one, which is a problem here since the
	/// values are owning class references.
	private void InsertOrReplaceCache(Guid id, CachedThumbnail entry)
	{
		if (mCache.TryGetValue(id, let existing))
			delete existing;
		mCache[id] = entry;
	}

	/// Last-write-time of the source file, or 0 if we can't tell (synthetic
	/// mounts, file-not-on-disk, etc.). Used only for cache freshness, so
	/// returning 0 just means the disk cache never invalidates - safer than
	/// silently regenerating each session.
	private int64 GetSourceMtime(StringView uri)
	{
		// Resolve the URI back to an absolute path via mount entries. The
		// mtime is only meaningful for disk-backed mounts.
		let absolute = scope String();
		for (let mount in mContext.MountEntries)
		{
			let scheme = scope $"{mount.Scheme}://";
			if (uri.StartsWith(scheme))
			{
				let locator = uri.Substring(scheme.Length);
				if (mount.Mount is FileSystemMount)
				{
					let disk = (FileSystemMount)mount.Mount;
					Path.InternalCombine(absolute, disk.RootPath, scope String(locator));
					break;
				}
			}
		}

		if (absolute.Length == 0 || !File.Exists(absolute))
			return 0;

		if (File.GetLastWriteTime(absolute) case .Ok(let dt))
			return dt.ToFileTime();
		return 0;
	}

	private void BuildDiskPath(Guid id, StringView suffix, String outPath)
	{
		outPath.Append(mDiskCacheDir);
		if (!outPath.EndsWith("/") && !outPath.EndsWith("\\"))
			outPath.Append('/');
		id.ToString(outPath);
		outPath.Append(suffix);
	}

	/// Attempt to load `req.Id`'s thumbnail from the on-disk cache. Returns
	/// true (and populates `out entry`) only if the cached file exists and
	/// its recorded source mtime matches the source file's current mtime.
	private bool TryLoadFromDisk(ThumbnailRequest req, out CachedThumbnail entry)
	{
		entry = null;
		if (mDiskCacheDir.Length == 0) return false;

		let png = scope String();
		BuildDiskPath(req.Id, ".png", png);
		let meta = scope String();
		BuildDiskPath(req.Id, ".meta", meta);

		if (!File.Exists(png) || !File.Exists(meta))
			return false;

		// Parse the sidecar - simple "mtime=<int64>" single line.
		let metaText = scope String();
		if (File.ReadAllText(meta, metaText) case .Err)
			return false;

		int64 recordedMtime = 0;
		if (metaText.StartsWith("mtime="))
		{
			let rest = StringView(metaText, 6);
			if (int64.Parse(rest) case .Ok(let v))
				recordedMtime = v;
		}

		let currentMtime = GetSourceMtime(req.Uri);
		// If we can't determine the current mtime, assume cache is valid -
		// otherwise we'd regenerate on every editor restart for mounts that
		// don't expose mtime. Only invalidate on a known mismatch.
		if (currentMtime != 0 && recordedMtime != currentMtime)
			return false;

		// Load the PNG.
		Image img = null;
		if (ImageLoaderFactory.LoadImage(png) case .Ok(let loaded))
			img = loaded;
		if (img == null)
			return false;
		defer delete img;

		// Convert Image -> OwnedImageData. Image owns its uint8[]; we copy
		// the span into OwnedImageData's owned buffer.
		let data = new OwnedImageData(img.Width, img.Height, img.Format, img.Data);
		let drawable = new ImageDrawable(data);

		entry = new CachedThumbnail();
		entry.Id = req.Id;
		entry.Data = data;
		entry.Drawable = drawable;
		entry.Width = req.Width;
		entry.Height = req.Height;
		entry.SourceMtime = currentMtime;
		return true;
	}

	private void SaveToDisk(ThumbnailRequest req, CachedThumbnail entry)
	{
		if (mDiskCacheDir.Length == 0) return;

		// Convert OwnedImageData -> Image for the writer (Image ctor copies).
		let buf = scope uint8[entry.Data.PixelData.Length];
		entry.Data.PixelData.CopyTo(Span<uint8>(buf));
		let img = scope Image(entry.Data.Width, entry.Data.Height, entry.Data.Format, buf);

		let png = scope String();
		BuildDiskPath(req.Id, ".png", png);

		if (ImageWriterFactory.SaveImage(img, png, .PNG) case .Err)
		{
			mLogger?.LogWarning("Thumbnail disk save failed for {}", png);
			return;
		}

		// Sidecar.
		let meta = scope String();
		BuildDiskPath(req.Id, ".meta", meta);
		let metaText = scope String();
		metaText.AppendF("mtime={}", entry.SourceMtime);
		if (File.WriteAllText(meta, metaText) case .Err)
		{
			mLogger?.LogWarning("Thumbnail sidecar save failed for {}", meta);
		}
	}
}
