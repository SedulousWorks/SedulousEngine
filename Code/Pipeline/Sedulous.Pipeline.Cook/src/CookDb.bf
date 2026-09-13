using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.VFS;

namespace Sedulous.Pipeline.Cook;

/// The persisted pipeline state: what each source cooked to last time.
///
/// A missing, corrupt or differently versioned file loads as EMPTY, which re-plans everything.
/// That is the right failure: a cook that ran too much is slow, and one that ran too little is
/// wrong.
class CookDb
{
	public const uint32 cVersion = 1;
	public const String cDefaultName = "cook.db";

	private Dictionary<Guid, CookRecord> mRecords = new .() ~ delete _;
	private List<CookRecord> mStorage = new .() ~ DeleteContainerAndItems!(_);

	public CookRecord Find(Guid source)
		=> mRecords.TryGetValue(source, let record) ? record : null;

	public CookRecord Upsert(Guid source)
	{
		if (let existing = Find(source))
			return existing;

		let record = new CookRecord();
		record.Source = source;
		mStorage.Add(record);
		mRecords[source] = record;
		return record;
	}

	public void Remove(Guid source)
	{
		if (!mRecords.Remove(source))
			return;
		for (int i < mStorage.Count)
		{
			if (mStorage[i].Source == source)
			{
				delete mStorage[i];
				mStorage.RemoveAt(i);
				return;
			}
		}
	}

	public void ForEach(delegate void(CookRecord) action)
	{
		for (let record in mStorage)
			action(record);
	}

	public int Count => mStorage.Count;

	public void Load(IFileSystem cache, StringView name = cDefaultName)
	{
		ClearAndDeleteItems!(mStorage);
		mRecords.Clear();

		let stream = cache.Open(name, .Read);
		if (stream == null)
			return;
		defer delete stream;

		let serializer = scope BinarySerializer(stream, .Read);
		uint32 version = 0;
		uint64 count = 0;
		SerializeValue(serializer, "version", ref version);
		if (!serializer.IsOk || (version != cVersion))
			return; // another build wrote it, so nothing here can be trusted

		SerializeValue(serializer, "count", ref count);
		for (uint64 i = 0; serializer.IsOk && (i < count); ++i)
		{
			let record = new CookRecord();
			// THROUGH the interface: [Serializable] emits an explicit implementation.
			((ISerializable)record).Serialize(serializer);
			if (!serializer.IsOk)
			{
				delete record;
				break;
			}
			mStorage.Add(record);
			mRecords[record.Source] = record;
		}

		if (!serializer.IsOk)
		{
			// Corrupt: everything re-plans rather than half the project cooking against
			// records that may or may not describe it.
			ClearAndDeleteItems!(mStorage);
			mRecords.Clear();
		}
	}

	public Result<void, ErrorCode> Save(IFileSystem cache, StringView name = cDefaultName)
	{
		let writable = cache as IWritableFileSystem;
		if (writable == null)
			return .Err(.NotSupported);

		let buffer = scope MemoryStream();
		let serializer = scope BinarySerializer(buffer, .Write);
		uint32 version = cVersion;
		uint64 count = (uint64)mStorage.Count;
		SerializeValue(serializer, "version", ref version);
		SerializeValue(serializer, "count", ref count);
		for (let record in mStorage)
			((ISerializable)record).Serialize(serializer);

		if (!serializer.IsOk)
			return .Err(.Internal);
		return writable.Save(name, buffer.Bytes);
	}
}
