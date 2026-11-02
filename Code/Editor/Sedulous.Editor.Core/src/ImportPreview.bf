using System;
using System.Collections;
using System.Threading;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.Editor.Core;

// What the import window shows of a file before it is imported (Raptor's import-window spec). A
// domain registers a preview factory for the asset types it imports, as it registers pages; the
// window asks for the one nearest the type the file's importer lists it by
// (IFileImporter.ListedTypeName), and shows its view with its facts under it. A type with no
// preview shows its facts alone. A preview reads the source file itself (nothing has been imported
// yet), off the main thread through the ImportPreviewReader, so a drop of large files never holds
// the window: it shows that it is reading, then its result.

/// One read a preview started. Cancelled when the preview goes, so its result is dropped.
class ImportPreviewRead : RefCounted
{
	private volatile bool mCancelled = false;

	public void Cancel() { mCancelled = true; }
	public bool Cancelled => mCancelled;
}

/// Runs the previews' reads on a worker of their own and hands each result back on the main
/// thread. Not the editor's job service: that runs one job at a time so a cook never races the
/// databases, and a preview queued behind a cook would wait for it; a preview only reads its
/// source file. The worker starts with the first read.
class ImportPreviewReader
{
	/// A read the worker finished, waiting for Pump.
	private class Finished
	{
		public ImportPreviewRead Ticket ~ _.ReleaseRef();
		public delegate void() Done ~ delete _;
	}

	private JobSystem mJobs = null;
	private Monitor mLock = new .() ~ delete _;
	/// Filled by the worker, under mLock.
	private List<Finished> mDone = new .() ~ DeleteContainerAndItems!(_);
	private volatile int32 mInFlight = 0;

	/// The reads still running finish (nothing they hold leaks); none is handed back.
	public ~this()
	{
		if (mJobs != null)
		{
			mJobs.WaitForAll();
			delete mJobs;
		}
	}

	/// Runs `read` on the worker, then `done` on the main thread in Pump; each is skipped once the
	/// returned read is cancelled. `read` must not touch the GUI or anything the main thread
	/// changes: it fills what `done` shows. TAKES OWNERSHIP of both delegates; the returned read
	/// carries a reference of the caller's.
	public ImportPreviewRead Read(delegate void() read, delegate void() done)
	{
		if (mJobs == null)
			mJobs = new JobSystem(1);
		let ticket = new ImportPreviewRead(); // the caller's reference
		ticket.AddRef(); // the job's, handed on to Finished
		Interlocked.Increment(ref mInFlight);
		mJobs.Submit(new [=this, =ticket, =read, =done] () =>
			{
				if (!ticket.Cancelled)
					read();
				delete read; // what it captured goes here, on the worker
				let finished = new Finished();
				finished.Ticket = ticket;
				finished.Done = done;
				using (mLock.Enter())
					mDone.Add(finished);
			});
		return ticket;
	}

	/// Hands back the reads finished since the last Pump (the editor's frame calls it).
	public void Pump()
	{
		let finished = scope List<Finished>();
		using (mLock.Enter())
		{
			finished.AddRange(mDone);
			mDone.Clear();
		}
		for (let read in finished)
		{
			Interlocked.Decrement(ref mInFlight);
			if (!read.Ticket.Cancelled)
				read.Done();
			delete read;
		}
	}

	/// Reads started and not yet handed back.
	public int32 InFlight => mInFlight;

	/// Waits for every read, then hands them back (tests; a host closing).
	public void Finish()
	{
		if (mJobs != null)
			mJobs.WaitForAll();
		Pump();
	}
}

/// One file's preview, made for the window and dropped (deleted) when another file is chosen.
interface IImportPreview
{
	/// What the preview pane shows. BORROWED: the preview keeps a reference, and a parent takes
	/// its own.
	Node View { get; }
	/// The line under it, a fact each ("2048 x 2048", "RGBA, 8-bit"); empty while it reads and when
	/// the file did not read.
	Span<String> Facts { get; }
	/// Set by the window: called when the preview's facts change (its read arrived). TAKES
	/// OWNERSHIP; null clears it.
	void SetOnChanged(delegate void() onChanged);
	/// Called by the window when the file's settings changed, for a preview that shows them.
	void OnSettingsChanged()
	{
	}
}

/// Makes previews of the files an importer lists by one asset type (and, by nearest type
/// dispatch, its subclasses, unless a nearer factory is registered).
interface IImportPreviewFactory
{
	Type AssetType { get; }
	/// A preview of the source file at `path`, its read started on `reader` (borrowed: it outlives
	/// the preview), OWNED by the caller; null when it shows nothing of it. `options` are the file's
	/// settings (null when it has none), BORROWED: alive as long as the preview, for one that shows
	/// what they will do.
	IImportPreview Create(StringView path, Sedulous.Pipeline.Importer.ImportOptions options, ImportPreviewReader reader);
}

/// The import previews, by asset type: the factory nearest along a type's base chain wins, as
/// the page factories' does.
class ImportPreviewRegistry
{
	private List<IImportPreviewFactory> mFactories = new .() ~ DeleteContainerAndItems!(_);
	/// FindByName's types by full name, remembered; null is a name no type has. Keys owned.
	private Dictionary<String, Type> mTypesByName = new .() ~ DeleteDictionaryAndKeys!(_);

	/// TAKES OWNERSHIP. A factory with no asset type is dropped.
	public void Register(IImportPreviewFactory factory)
	{
		if ((factory == null) || (factory.AssetType == null))
		{
			delete factory;
			return;
		}
		mFactories.Add(factory);
	}

	public int Count => mFactories.Count;

	/// The factory for `type`'s nearest registered type along its base chain; null when none.
	public IImportPreviewFactory Find(Type type)
	{
		for (var t = type; t != null; t = t.BaseType)
		{
			for (let factory in mFactories)
			{
				if (factory.AssetType == t)
					return factory;
			}
		}
		return null;
	}

	/// Find for the type of FULL name `typeFullName`, as an importer names the type it lists a file
	/// by; null when no type has the name.
	public IImportPreviewFactory FindByName(StringView typeFullName)
	{
		if (typeFullName.IsEmpty)
			return null;
		Type type;
		if (mTypesByName.TryGetValue(scope String(typeFullName), let known))
			type = known;
		else
		{
			type = EditorPageRegistry.FindTypeByFullName(typeFullName);
			mTypesByName[new String(typeFullName)] = type;
		}
		return (type != null) ? Find(type) : null;
	}
}
