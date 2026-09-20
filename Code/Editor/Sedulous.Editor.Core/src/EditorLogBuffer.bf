using System;
using System.Collections;
using System.Threading;
using Sedulous.Core.Logging;

namespace Sedulous.Editor.Core;

/// The editor's and the tools' log capture: ONE thread safe bounded logger, added to the
/// global CompositeLogger first thing in main, so every line the engine logs across the run
/// is retained and nothing has to swap the logger.
///
/// Entries keep full fidelity heap strings, where RingLogger truncates to a record's fixed
/// capacity, useless for a build error or a file path, and carry a monotonic sequence so a
/// main thread consumer, the console panel or the MCP log_read, polls incrementally with
/// CollectSince. When the ring is full the oldest entry drops but sequences keep advancing,
/// so a consumer can tell, and report, that it missed some.
///
/// The category is read off the message: the engine's convention is a "Subsystem: text"
/// prefix, and a line without one has an empty category.
class EditorLogBuffer : ILogger
{
	private List<EditorLogEntry> mEntries = new .() ~ DeleteContainerAndItems!(_);
	private int mCapacity;
	private int mHead = 0;
	private uint64 mNextSequence = 1;
	private uint64 mDropped = 0;
	private Monitor mLock = new .() ~ delete _;

	public LogLevel MinimumLogLevel { get; set; }
	public String Name { get; private set; } = new .() ~ delete _;

	public this(int capacity = 4096, LogLevel minimumLogLevel = .Trace,
		StringView name = Compiler.ProjectName)
	{
		mCapacity = capacity > 0 ? capacity : 1;
		MinimumLogLevel = minimumLogLevel;
		Name.Set(name);
	}

	public void Log(LogLevel logLevel, StringView format, params Object[] args)
	{
		if ((logLevel < MinimumLogLevel) || (logLevel >= .None))
			return;
		let message = scope String();
		message.AppendF(format, params args);
		Write(logLevel, message);
	}

	/// Retains one finished line. What Log does after formatting; also the way a host
	/// drops a marker of its own into the stream.
	public void Write(LogLevel level, StringView message)
	{
		using (mLock.Enter())
		{
			EditorLogEntry entry;
			if (mEntries.Count < mCapacity)
			{
				entry = new EditorLogEntry();
				mEntries.Add(entry);
			}
			else
			{
				// Full: overwrite the oldest in place and advance the head.
				entry = mEntries[mHead];
				mHead = (mHead + 1) % mCapacity;
				mDropped++;
			}
			entry.Level = level;
			SplitCategory(message, entry.Category, entry.Message);
			entry.Sequence = mNextSequence++;
		}
	}

	/// Appends a COPY of every retained entry with sequence > sinceSequence to `outEntries`,
	/// oldest first, and returns the new high water sequence to pass next time. The caller
	/// owns the copies.
	public uint64 CollectSince(uint64 sinceSequence, List<EditorLogEntry> outEntries)
	{
		using (mLock.Enter())
		{
			uint64 high = sinceSequence;
			for (int i < mEntries.Count)
			{
				let entry = mEntries[(mHead + i) % mEntries.Count];
				if (entry.Sequence > sinceSequence)
				{
					let copy = new EditorLogEntry();
					entry.CopyTo(copy);
					outEntries.Add(copy);
					high = entry.Sequence;
				}
			}
			return high;
		}
	}

	public int Count
	{
		get
		{
			using (mLock.Enter())
				return mEntries.Count;
		}
	}

	/// The sequence of the most recently written entry, 0 when nothing was written yet.
	public uint64 LatestSequence
	{
		get
		{
			using (mLock.Enter())
				return mNextSequence - 1;
		}
	}

	/// Entries evicted before a collection saw them, for an "N dropped" signal.
	public uint64 DroppedCount
	{
		get
		{
			using (mLock.Enter())
				return mDropped;
		}
	}

	public void Clear()
	{
		using (mLock.Enter())
		{
			ClearAndDeleteItems(mEntries);
			mHead = 0;
		}
	}

	/// "Prefix: text" becomes ("Prefix", "text") when the prefix is one identifier like
	/// token, letters, digits and dots, which is how the engine names the subsystem that
	/// spoke. Anything else is a message with no category.
	private static void SplitCategory(StringView line, String outCategory, String outMessage)
	{
		outCategory.Clear();
		outMessage.Clear();
		let colon = line.IndexOf(": ");
		if ((colon > 0) && (colon <= 40))
		{
			bool token = true;
			for (int i < colon)
			{
				let c = line[i];
				if (!(c.IsLetterOrDigit || (c == '.') || (c == '_')))
				{
					token = false;
					break;
				}
			}
			if (token)
			{
				outCategory.Set(line.Substring(0, colon));
				outMessage.Set(line.Substring(colon + 2));
				return;
			}
		}
		outMessage.Set(line);
	}
}
