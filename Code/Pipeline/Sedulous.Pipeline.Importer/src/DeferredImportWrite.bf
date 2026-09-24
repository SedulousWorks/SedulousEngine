using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;

namespace Sedulous.Pipeline.Importer;

/// A BULK write an importer defers to the worker flush.
///
/// Three shapes in one class: a data stream write, an envelope write, and a raw file copy.
/// Serialisation runs on the worker too, which matters because rendering a large mesh source
/// to text is the single most expensive part of an import.
///
/// All three are pure file and mount IO with NO in memory database mutation, so they are safe
/// off the interface thread while the job lock keeps cooks out and queues deletes.
class DeferredImportWrite
{
	/// BORROWED: the database owns it.
	public Instance Instance = null;

	/// An envelope write when set, and OWNED.
	///
	/// Ownership has to sit here: the object is built during the fan out and nothing else is
	/// alive to hold it until the flush runs, the importer having returned long before.
	public ISerializable Object = null;

	/// A data stream write when set.
	public String StreamName = new .() ~ delete _;

	/// BORROWED from the importer's prepared payload, which is kept alive through the flush.
	public Span<uint8> View = .();

	/// Owned bytes, which take precedence over the borrowed view when present.
	public List<uint8> Owned = new .() ~ delete _;

	/// A LAZY payload: run on the worker immediately before the write, filling `Owned`.
	///
	/// What it holds is the import's CPU bulk, a mesh's conversion, its level of detail chain
	/// and its geometry serialization, so queueing the write costs microseconds and the work
	/// itself happens off the calling thread. OWNED here.
	///
	/// Whatever it captures has to outlive the FLUSH, not the import call: the caller keeps
	/// the prepared payload alive for exactly this reason.
	public delegate Result<void, ErrorCode>(List<uint8>) Produce = null ~ delete _;

	/// Scratch the producer captures and this write OWNS, so a lazy payload can hold a small
	/// working set without leaking it when the write is dropped unexecuted.
	public List<Object> ProduceOwned = new .() ~ DeleteContainerAndItems!(_);

	/// A raw copy when both paths are set.
	public String CopyFrom = new .() ~ delete _;
	public String CopyTo = new .() ~ delete _;

	public ~this()
	{
		// An interface handle reaches its object through the object it is part of, and the
		// virtual destructor then frees the concrete asset.
		if (Object != null)
			delete Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(Object));
	}

	public Span<uint8> Bytes => Owned.IsEmpty ? View : Span<uint8>(Owned.Ptr, Owned.Count);

	/// Runs the write on the worker, producing its bytes first when the payload is lazy.
	public Result<void, ErrorCode> Execute()
	{
		if (Produce != null)
		{
			if (Produce(Owned) case .Err(let error))
				return .Err(error);
			// Dropped once it has run, so a repeated Execute writes what was produced rather
			// than producing it again.
			DeleteAndNullify!(Produce);
		}

		if (!CopyFrom.IsEmpty && !CopyTo.IsEmpty)
			return ExecuteCopy();

		if (Instance == null)
			return .Err(.InvalidArgument);
		if (Object != null)
			return Instance.WriteObject(Object);
		return Instance.WriteData(StreamName, Bytes);
	}

	private Result<void, ErrorCode> ExecuteCopy()
	{
		let bytes = scope List<uint8>();
		if (ReadFile(CopyFrom, bytes) case .Err(let error))
			return .Err(error);

		// IDENTICAL bytes are left alone, so a re-import does not churn the modification time
		// and re-cook everything downstream of it.
		if (FileExists(CopyTo))
		{
			let existing = scope List<uint8>();
			if ((ReadFile(CopyTo, existing) case .Ok) && (existing.Count == bytes.Count))
			{
				var same = true;
				for (int i < bytes.Count)
				{
					if (existing[i] != bytes[i])
					{
						same = false;
						break;
					}
				}
				if (same)
					return .Ok;
			}
		}

		// A NESTED destination, which a model referencing "textures/x.jpg" produces, needs its
		// parents made first: the raw write does not create them, unlike the inline path's
		// mount save. Without this every nested texture copy fails and the import never ends.
		let slash = CopyTo.LastIndexOf('/');
		if (slash > 0)
			CreateDirectory(StringView(CopyTo, 0, slash));

		return WriteFile(CopyTo, bytes);
	}

	/// What the progress line calls this write.
	public StringView Label
	{
		get
		{
			if (!CopyTo.IsEmpty)
				return CopyTo;
			return (Instance != null) ? Instance.Name : "?";
		}
	}
}
