using System;
using Sedulous.Core.IO;

namespace Sedulous.Core.Tests;

/// Passes everything to the stream underneath and counts the reads that reach it, so a
/// test can see a reader stop rather than only that it failed.
class CountingStream : IStream
{
	private IStream mInner;

	public int Reads;

	public this(IStream inner)
	{
		mInner = inner;
	}

	public override bool IsValid => mInner.IsValid;

	public override int Read(Span<uint8> destination)
	{
		Reads++;
		return mInner.Read(destination);
	}

	public override int Write(Span<uint8> source) => mInner.Write(source);
	public override int64 Seek(int64 offset, SeekOrigin origin) => mInner.Seek(offset, origin);
	public override int64 Tell() => mInner.Tell();
	public override int64 Size() => mInner.Size();
}
