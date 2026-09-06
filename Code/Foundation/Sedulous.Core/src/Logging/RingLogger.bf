using System;
using System.Collections;

namespace Sedulous.Core.Logging;

/// Retains the most recent messages, for tools and in-app consoles.
///
/// Raptor holds these in a RingBuffer; this uses a List with an explicit head index
/// until Containers is ported, so a full buffer overwrites in place rather than shifting
/// every record on each write.
class RingLogger : BaseLogger
{
	private List<LogRecord> mRecords = new .() ~ delete _;
	private int mCapacity;
	private int mHead;

	public this(int capacity, LogLevel minimumLogLevel,
		StringView name = Compiler.ProjectName, ILogFormatter formatter = null,
		bool ownsFormatter = false)
		: base(minimumLogLevel, name, formatter, ownsFormatter)
	{
		mCapacity = capacity > 0 ? capacity : 1;
		mHead = 0;
	}

	public int Count => mRecords.Count;

	/// The level of a retained record. Index zero is the oldest.
	public LogLevel GetLevel(int index) => mRecords[(mHead + index) % mRecords.Count].Level;

	/// Appends a retained message to output. Index zero is the oldest.
	///
	/// The text is copied out rather than returned as a view, because a record is a
	/// value type: a view into one would point into whichever copy the caller holds.
	/// Taking the address of a local copy here is safe, since the view is consumed
	/// before the local goes out of scope.
	public void GetMessage(int index, String output)
	{
		var record = mRecords[(mHead + index) % mRecords.Count];
		if (record.Length > 0)
			output.Append(StringView(&record.Message[0], record.Length));
	}

	public void Clear()
	{
		mRecords.Clear();
		mHead = 0;
	}

	protected override void LogMessage(LogLevel logLevel, StringView message)
	{
		// Deliberately uninitialised: zeroing the whole record would clear 256 bytes per
		// line only to overwrite the front of it. The stored length bounds every read,
		// so nothing looks past what was written.
		LogRecord record = ?;
		record.Level = logLevel;
		record.Length = (int32)CopyTruncated(&record.Message[0], LogRecord.MessageCapacity,
			message);

		if (mRecords.Count < mCapacity)
		{
			mRecords.Add(record);
			return;
		}

		// Full: overwrite the oldest and advance the head.
		mRecords[mHead] = record;
		mHead = (mHead + 1) % mCapacity;
	}

	/// Copies as much as fits and returns how much that was. The stored length is what
	/// bounds a later read, so there is no terminator to keep in step with it.
	private static int CopyTruncated(char8* dst, int capacity, StringView src)
	{
		let n = (src.Length < capacity) ? src.Length : capacity;
		if (n > 0)
			Internal.MemCpy(dst, src.Ptr, n);
		return n;
	}
}
