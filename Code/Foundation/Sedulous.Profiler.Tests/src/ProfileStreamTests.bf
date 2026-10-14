using System;
using Sedulous.Core.IO;
using Sedulous.Profiler;

namespace Sedulous.Profiler.Tests;

/// The profiler's stream: frames written with the tables they lean on and read back as a
/// capture, a source like the live store. A capture file is this stream saved; later a socket
/// carries the same bytes.
class ProfileStreamTests
{
	/// Three frames: scopes, a GPU pass with counts on the second, a counter on each.
	private static void Record(Profiler p)
	{
		let draws = p.RegisterCounter("Draws", .Count);
		p.Arm();
		for (uint32 f < 3)
		{
			p.BeginFrame();
			Test.Assert(p.BeginScope("Update"));
			Test.Assert(p.BeginScope((f == 2) ? "Late name" : "Physics"));
			p.EndScope();
			p.EndScope();
			p.SetCounter(draws, 10.0 + f);
			p.EndFrame();
		}
		var pass = GpuPassEvent(p.InternName("forward"), 0, 0, 100, 200);
		pass.HasCounts = true;
		pass.Counts.InputPrimitives = 12;
		pass.Counts.FragmentInvocations = 4096;
		p.SubmitGpuPasses(1, .(&pass, 1));
	}

	[Test]
	public static void ACaptureReadsBackFrameForFrame()
	{
		let p = scope Profiler();
		Record(p);
		let live = scope LiveProfileSource(p);

		let bytes = scope MemoryStream();
		let writer = scope ProfileStreamWriter(bytes);
		let header = scope StreamHeader();
		header.TickFrequency = live.TickFrequency;
		header.Application.Set("Probe");
		header.Platform.Set("Linux64");
		header.Build.Set("test");
		Test.Assert(writer.WriteHeader(header));
		for (var n = live.OldestFrame; n <= live.NewestFrame; n++)
		{
			if (let frame = live.Frame(n))
				Test.Assert(writer.WriteFrame(live, frame));
		}

		bytes.Seek(0, .Begin);
		let capture = scope ProfileCapture();
		Test.Assert(capture.Read(bytes));
		Test.Assert(capture.Header.Application == "Probe");
		Test.Assert(capture.Header.Build == "test");
		Test.Assert(capture.TickFrequency == live.TickFrequency);
		Test.Assert(capture.FrameCount == 3);
		Test.Assert(capture.OldestFrame == live.OldestFrame);
		Test.Assert(capture.NewestFrame == live.NewestFrame);
		Test.Assert(capture.NameCount == live.NameCount);
		Test.Assert(capture.Threads.Length == live.Threads.Length);
		Test.Assert(capture.Threads[0].Name == live.Threads[0].Name, scope $"[{capture.Threads[0].Name}] [{live.Threads[0].Name}] {capture.Threads[0].Index} {live.Threads[0].Index} {capture.Threads.Length}");
		Test.Assert(capture.Counters.Length == 1);
		Test.Assert(capture.Counters[0].Name == "Draws");
		Test.Assert(capture.Counters[0].Unit == .Count);

		for (var n = live.OldestFrame; n <= live.NewestFrame; n++)
		{
			let a = live.Frame(n);
			let b = capture.Frame(n);
			Test.Assert((a != null) && (b != null));
			Test.Assert(b.BeginTick == a.BeginTick);
			Test.Assert(b.EndTick == a.EndTick);
			Test.Assert(b.Threads.Count == a.Threads.Count);
			Test.Assert(b.Threads[0].Scopes.Count == a.Threads[0].Scopes.Count);
			for (int i < a.Threads[0].Scopes.Count)
			{
				let sa = a.Threads[0].Scopes[i];
				let sb = b.Threads[0].Scopes[i];
				Test.Assert(capture.NameOf(sb.Name) == live.NameOf(sa.Name));
				Test.Assert(sb.Depth == sa.Depth);
				Test.Assert(sb.BeginTick == sa.BeginTick);
				Test.Assert(sb.EndTick == sa.EndTick);
			}
			Test.Assert(b.GpuValid == a.GpuValid);
			Test.Assert(b.Gpu.Count == a.Gpu.Count);
			Test.Assert(b.Counters.Count == 1);
			Test.Assert(b.Counters[0].Value == a.Counters[0].Value);
		}
		let withGpu = capture.Frame(1);
		Test.Assert(withGpu.Gpu.Count == 1);
		Test.Assert(capture.NameOf(withGpu.Gpu[0].Name) == "forward");
		Test.Assert(withGpu.Gpu[0].BeginTick == 100);
		Test.Assert(withGpu.Gpu[0].HasCounts);
		Test.Assert(withGpu.Gpu[0].Counts.InputPrimitives == 12);
		Test.Assert(withGpu.Gpu[0].Counts.FragmentInvocations == 4096);
		Test.Assert(capture.NameOf(capture.Frame(2).Threads[0].Scopes[0].Name) == "Late name"
			|| capture.NameOf(capture.Frame(2).Threads[0].Scopes[1].Name) == "Late name");
		Test.Assert(capture.Frame(7) == null);
	}

	/// Written in two goes (as a live stream is): the second sends only what is new since.
	[Test]
	public static void TablesTravelOnceAFramesNewNamesJustBeforeIt()
	{
		let p = scope Profiler();
		p.Arm();
		p.BeginFrame();
		Test.Assert(p.BeginScope("First"));
		p.EndScope();
		p.EndFrame();
		let live = scope LiveProfileSource(p);
		let bytes = scope MemoryStream();
		let writer = scope ProfileStreamWriter(bytes);
		Test.Assert(writer.WriteHeader(scope StreamHeader()));
		Test.Assert(writer.WriteFrame(live, p.LatestFrame));
		let afterFirst = bytes.Size();
		Test.Assert(writer.WriteFrame(live, p.LatestFrame));
		let sameAgain = bytes.Size() - afterFirst; // no tables: just the frame chunk
		p.BeginFrame();
		Test.Assert(p.BeginScope("Second"));
		p.EndScope();
		p.EndFrame();
		let beforeThird = bytes.Size();
		Test.Assert(writer.WriteFrame(live, p.LatestFrame));
		Test.Assert(bytes.Size() - beforeThird > sameAgain, "carries the new name");
		bytes.Seek(0, .Begin);
		let capture = scope ProfileCapture();
		Test.Assert(!capture.Read(bytes), "the repeated frame number is refused");
		Test.Assert(capture.NameCount == 1, "read up to it");
		Test.Assert(capture.FrameCount == 1);
	}

	[Test]
	public static void AnUnknownChunkIsSkippedAForeignOrCutStreamRefused()
	{
		let p = scope Profiler();
		Record(p);
		let live = scope LiveProfileSource(p);
		let bytes = scope MemoryStream();
		let writer = scope ProfileStreamWriter(bytes);
		Test.Assert(writer.WriteHeader(scope StreamHeader()));
		// A chunk from a later version: tag 200, three bytes.
		uint8[8] unknown = .(200, 3, 0, 0, 0, 1, 2, 3);
		bytes.Write(unknown);
		Test.Assert(writer.WriteFrame(live, p.LatestFrame));
		bytes.Seek(0, .Begin);
		let capture = scope ProfileCapture();
		Test.Assert(capture.Read(bytes));
		Test.Assert(capture.FrameCount == 1);

		// Cut short in the frame chunk.
		let whole = bytes.Bytes;
		let cut = scope MemoryStream();
		cut.Write(.(whole.Ptr, whole.Length - 5));
		cut.Seek(0, .Begin);
		let partial = scope ProfileCapture();
		Test.Assert(!partial.Read(cut));

		// A length past the end is refused before anything is sized to it.
		let lying = scope MemoryStream();
		let liar = scope ProfileStreamWriter(lying);
		Test.Assert(liar.WriteHeader(scope StreamHeader()));
		uint8[5] huge = .(4, 0xFF, 0xFF, 0xFF, 0x7F);
		lying.Write(huge);
		lying.Seek(0, .Begin);
		Test.Assert(!scope ProfileCapture().Read(lying));

		// Not a profile stream at all.
		let other = scope MemoryStream();
		var notMagic = (uint32)0x12345678;
		other.Write(.((uint8*)&notMagic, sizeof(uint32)));
		other.Seek(0, .Begin);
		Test.Assert(!scope ProfileCapture().Read(other));
	}

	/// The bytes are the format's, field for field (Raptor reads them): a header of magic,
	/// version, a u64 frequency and three strings, then a names chunk of a tag, a u32 length,
	/// a u32 first id and a u32 count. A count once went out eight bytes wide, which a round
	/// trip through this reader alone could miss.
	[Test]
	public static void TheBytesAreTheFormatsFieldForField()
	{
		let p = scope Profiler();
		p.Arm();
		p.BeginFrame();
		Test.Assert(p.BeginScope("First"));
		p.EndScope();
		p.EndFrame();
		let live = scope LiveProfileSource(p);
		let bytes = scope MemoryStream();
		let writer = scope ProfileStreamWriter(bytes);
		Test.Assert(writer.WriteHeader(scope StreamHeader()));
		Test.Assert(bytes.Size() == 4 + 4 + 8 + 3 * 4);
		Test.Assert(writer.WriteFrame(live, p.LatestFrame));
		let b = bytes.Bytes;
		Test.Assert(*(uint32*)&b[0] == ProfileStream.Magic);
		Test.Assert(b[28] == (uint8)StreamChunk.Names);
		Test.Assert(*(uint32*)&b[29] == 4 + 4 + 4 + 5, scope $"names chunk {*(uint32*)&b[29]} bytes");
		Test.Assert(*(uint32*)&b[33] == 0);
		Test.Assert(*(uint32*)&b[37] == 1);
		Test.Assert(*(uint32*)&b[41] == 5);
		let threads = 45 + 5;
		Test.Assert(b[threads] == (uint8)StreamChunk.Threads);
		Test.Assert(*(uint32*)&b[threads + 1] == 4 + 4 + 4 + 4 + (uint32)p.Threads[0].Name.Length);
	}
}
