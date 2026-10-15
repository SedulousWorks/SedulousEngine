using System;
using System.Collections;
using Sedulous.Core.IO;

namespace Sedulous.Profiler;

/// The one encoding of profiler frames: a capture file (.aeprofile) is a stream saved, and later
/// a socket carries the same bytes. A stream is a header (the recording process: application,
/// platform, build, tick frequency), then chunks, each a tag, a byte length and its payload, so
/// a reader skips a chunk it does not know. The tables a frame's ids point into travel beside it
/// as deltas: names, threads and counters are sent when new, each once. Little-endian, as every
/// target is; the same bytes Raptor writes, so either engine reads the other's captures.
static class ProfileStream
{
	public const uint32 Magic = 0x46504541; // "AEPF"
	public const uint32 Version = 1;
}

enum StreamChunk : uint8
{
	/// First id, then names in id order.
	Names = 1,
	/// First index, then (index, name).
	Threads = 2,
	/// First id, then (name, unit).
	Counters = 3,
	/// One frame record.
	Frame = 4
}

/// Who recorded a stream.
class StreamHeader
{
	public uint64 TickFrequency;
	public String Application = new .() ~ delete _;
	public String Platform = new .() ~ delete _;
	public String Build = new .() ~ delete _;
}

/// Writes a stream: the header once, then frames, each preceded by whatever table entries it
/// needs that were not sent yet.
class ProfileStreamWriter
{
	private BinaryWriter mOut ~ delete _;
	/// Each chunk's payload is built here first, for its length.
	private MemoryStream mPayload = new .() ~ delete _;
	private uint32 mNamesSent;
	private uint32 mThreadsSent;
	private uint32 mCountersSent;

	/// The stream is borrowed and must outlive the writer.
	public this(IStream output)
	{
		mOut = new .(output);
	}

	public bool IsOk => mOut.IsOk;

	public bool WriteHeader(StreamHeader header)
	{
		mOut.Write(ProfileStream.Magic);
		mOut.Write(ProfileStream.Version);
		mOut.Write(header.TickFrequency);
		mOut.WriteString(header.Application);
		mOut.WriteString(header.Platform);
		mOut.WriteString(header.Build);
		return mOut.IsOk;
	}

	/// One frame of `source`, the tables it leans on first.
	public bool WriteFrame(IProfileSource source, FrameRecord frame)
	{
		SendTables(source);
		mPayload.Clear();
		let w = scope BinaryWriter(mPayload);
		w.Write(frame.FrameNumber);
		w.Write(frame.BeginTick);
		w.Write(frame.EndTick);
		w.Write((uint32)frame.Threads.Count);
		for (let thread in frame.Threads)
		{
			w.Write(thread.Thread);
			w.Write(thread.Dropped);
			w.Write((uint32)thread.Scopes.Count);
			for (let scopeEvent in thread.Scopes)
			{
				w.Write(scopeEvent.Name);
				w.Write(scopeEvent.Depth);
				w.Write(scopeEvent.BeginTick);
				w.Write(scopeEvent.EndTick);
			}
		}
		w.Write((uint8)(frame.GpuValid ? 1 : 0));
		w.Write((uint32)frame.Gpu.Count);
		for (let pass in frame.Gpu)
		{
			w.Write(pass.Name);
			w.Write(pass.Depth);
			w.Write(pass.Queue);
			w.Write(pass.BeginTick);
			w.Write(pass.EndTick);
			w.Write((uint8)(pass.HasCounts ? 1 : 0));
			if (pass.HasCounts)
				w.Write(pass.Counts);
		}
		w.Write((uint32)frame.Counters.Count);
		for (let value in frame.Counters)
		{
			w.Write(value.Counter);
			w.Write(value.Value);
		}
		return WriteChunk(.Frame);
	}

	private void SendTables(IProfileSource source)
	{
		let nameCount = source.NameCount;
		if (nameCount > mNamesSent)
		{
			mPayload.Clear();
			let w = scope BinaryWriter(mPayload);
			w.Write(mNamesSent);
			w.Write((uint32)(nameCount - mNamesSent)); // a uint32 difference widens: the format has four bytes
			for (uint32 id = mNamesSent; id < nameCount; id++)
				w.WriteString(source.NameOf(id));
			WriteChunk(.Names);
			mNamesSent = nameCount;
		}
		let threads = source.Threads;
		if ((uint32)threads.Length > mThreadsSent)
		{
			mPayload.Clear();
			let w = scope BinaryWriter(mPayload);
			w.Write(mThreadsSent);
			w.Write((uint32)((uint32)threads.Length - mThreadsSent));
			for (int i = (int)mThreadsSent; i < threads.Length; i++)
			{
				w.Write(threads[i].Index);
				w.WriteString(threads[i].Name);
			}
			WriteChunk(.Threads);
			mThreadsSent = (uint32)threads.Length;
		}
		let counters = source.Counters;
		if ((uint32)counters.Length > mCountersSent)
		{
			mPayload.Clear();
			let w = scope BinaryWriter(mPayload);
			w.Write(mCountersSent);
			w.Write((uint32)((uint32)counters.Length - mCountersSent));
			for (int i = (int)mCountersSent; i < counters.Length; i++)
			{
				w.WriteString(counters[i].Name);
				w.Write((uint8)counters[i].Unit);
			}
			WriteChunk(.Counters);
			mCountersSent = (uint32)counters.Length;
		}
	}

	/// The payload built in mPayload, behind its tag and length.
	private bool WriteChunk(StreamChunk tag)
	{
		let bytes = mPayload.Bytes;
		mOut.Write((uint8)tag);
		mOut.Write((uint32)bytes.Length);
		mOut.WriteBytes(bytes);
		return mOut.IsOk;
	}
}

/// A stream read back: its frames and tables, owned, read as a source.
class ProfileCapture : IProfileSource
{
	private StreamHeader mHeader = new .() ~ delete _;
	private List<String> mNames = new .() ~ DeleteContainerAndItems!(_);
	private List<ThreadInfo> mThreads = new .() ~ DeleteContainerAndItems!(_);
	private List<CounterInfo> mCounters = new .() ~ DeleteContainerAndItems!(_);
	private List<FrameRecord> mFrames = new .() ~ DeleteContainerAndItems!(_);

	/// Reads a whole stream; false (and a partial capture) on a malformed or foreign one.
	public bool Read(IStream input)
	{
		let r = scope BinaryReader(input);
		uint32 magic = 0;
		r.Read(out magic);
		uint32 version = 0;
		r.Read(out version);
		if (!r.IsOk || (magic != ProfileStream.Magic) || (version != ProfileStream.Version))
			return false;
		r.Read(out mHeader.TickFrequency);
		r.ReadString(mHeader.Application);
		r.ReadString(mHeader.Platform);
		r.ReadString(mHeader.Build);
		if (!r.IsOk)
			return false;

		let payload = scope MemoryStream();
		let bytes = scope List<uint8>();
		while (true)
		{
			uint8 tag = 0;
			if (input.Read(.(&tag, 1)) != 1)
				return true; // the end
			uint32 length = 0;
			r.Read(out length);
			if (!r.IsOk)
				return false;
			// A length longer than what is left cannot be real; refused before it sizes a buffer.
			if ((int64)length > input.Size() - input.Tell())
				return false;
			bytes.Count = (int)length;
			if (!r.ReadBytes(bytes))
				return false;
			payload.Clear();
			payload.Write(bytes);
			payload.Seek(0, .Begin);
			if (!ReadChunk((StreamChunk)tag, payload))
				return false;
		}
	}

	public StreamHeader Header => mHeader;
	public int FrameCount => mFrames.Count;

	public uint64 TickFrequency => mHeader.TickFrequency;
	public bool HasFrames => !mFrames.IsEmpty;
	public uint64 OldestFrame => mFrames.IsEmpty ? 0 : mFrames[0].FrameNumber;
	public uint64 NewestFrame => mFrames.IsEmpty ? 0 : mFrames.Back.FrameNumber;

	public FrameRecord Frame(uint64 frameNumber)
	{
		// Frames are in number order: a binary search.
		int lo = 0;
		int hi = mFrames.Count;
		while (lo < hi)
		{
			let mid = lo + (hi - lo) / 2;
			if (mFrames[mid].FrameNumber < frameNumber)
				lo = mid + 1;
			else
				hi = mid;
		}
		return ((lo < mFrames.Count) && (mFrames[lo].FrameNumber == frameNumber)) ? mFrames[lo] : null;
	}

	public StringView NameOf(uint32 id) => (id < (uint32)mNames.Count) ? mNames[(int)id] : StringView();
	public uint32 NameCount => (uint32)mNames.Count;
	public Span<ThreadInfo> Threads => mThreads;
	public Span<CounterInfo> Counters => mCounters;

	private bool ReadChunk(StreamChunk tag, IStream payload)
	{
		let r = scope BinaryReader(payload);
		switch (tag)
		{
		case .Names:
			uint32 first = 0;
			r.Read(out first);
			uint32 count = 0;
			r.Read(out count);
			if (!r.IsOk || (first != (uint32)mNames.Count))
				return false;
			for (uint32 i = 0; (i < count) && r.IsOk; i++)
			{
				let name = new String();
				r.ReadString(name);
				mNames.Add(name);
			}
			return r.IsOk;
		case .Threads:
			uint32 first = 0;
			r.Read(out first);
			uint32 count = 0;
			r.Read(out count);
			if (!r.IsOk || (first != (uint32)mThreads.Count))
				return false;
			for (uint32 i = 0; (i < count) && r.IsOk; i++)
			{
				let info = new ThreadInfo();
				r.Read(out info.Index);
				r.ReadString(info.Name);
				mThreads.Add(info);
			}
			return r.IsOk;
		case .Counters:
			uint32 first = 0;
			r.Read(out first);
			uint32 count = 0;
			r.Read(out count);
			if (!r.IsOk || (first != (uint32)mCounters.Count))
				return false;
			for (uint32 i = 0; (i < count) && r.IsOk; i++)
			{
				let info = new CounterInfo();
				r.ReadString(info.Name);
				uint8 unit = 0;
				r.Read(out unit);
				info.Unit = (CounterUnit)unit;
				mCounters.Add(info);
			}
			return r.IsOk;
		case .Frame:
			return ReadFrame(r);
		default:
			return true; // a chunk this reader does not know: skipped
		}
	}

	private bool ReadFrame(BinaryReader r)
	{
		let frame = new FrameRecord();
		r.Read(out frame.FrameNumber);
		r.Read(out frame.BeginTick);
		r.Read(out frame.EndTick);
		uint32 threadCount = 0;
		r.Read(out threadCount);
		for (uint32 t = 0; (t < threadCount) && r.IsOk; t++)
		{
			let thread = new ThreadFrame();
			frame.Threads.Add(thread);
			r.Read(out thread.Thread);
			r.Read(out thread.Dropped);
			uint32 scopeCount = 0;
			r.Read(out scopeCount);
			for (uint32 i = 0; (i < scopeCount) && r.IsOk; i++)
			{
				ScopeEvent scopeEvent = default;
				r.Read(out scopeEvent.Name);
				r.Read(out scopeEvent.Depth);
				r.Read(out scopeEvent.BeginTick);
				r.Read(out scopeEvent.EndTick);
				thread.Scopes.Add(scopeEvent);
			}
		}
		uint8 gpuValid = 0;
		r.Read(out gpuValid);
		uint32 gpuCount = 0;
		r.Read(out gpuCount);
		frame.GpuValid = gpuValid != 0;
		for (uint32 i = 0; (i < gpuCount) && r.IsOk; i++)
		{
			GpuPassEvent pass = default;
			r.Read(out pass.Name);
			r.Read(out pass.Depth);
			r.Read(out pass.Queue);
			r.Read(out pass.BeginTick);
			r.Read(out pass.EndTick);
			uint8 hasCounts = 0;
			r.Read(out hasCounts);
			pass.HasCounts = hasCounts != 0;
			if (pass.HasCounts)
				r.Read(out pass.Counts);
			frame.Gpu.Add(pass);
		}
		uint32 counterCount = 0;
		r.Read(out counterCount);
		for (uint32 i = 0; (i < counterCount) && r.IsOk; i++)
		{
			CounterValue value = default;
			r.Read(out value.Counter);
			r.Read(out value.Value);
			frame.Counters.Add(value);
		}
		// Frames come in number order.
		if (!r.IsOk || (!mFrames.IsEmpty && (frame.FrameNumber <= mFrames.Back.FrameNumber)))
		{
			delete frame;
			return false;
		}
		mFrames.Add(frame);
		return true;
	}
}
