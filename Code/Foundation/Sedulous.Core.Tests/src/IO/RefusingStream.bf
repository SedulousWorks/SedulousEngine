using System;
using Sedulous.Core.IO;

namespace Sedulous.Core.Tests;

/// A stream that accepts and yields nothing.
///
/// MemoryStream always accepts a write and FileStream only refuses once the disk does, so
/// this is the only way to reach BinaryWriter's short-write path from a test.
class RefusingStream : IStream
{
	public override bool IsValid => true;
	public override int Read(Span<uint8> destination) => 0;
	public override int Write(Span<uint8> source) => 0;
	public override int64 Seek(int64 offset, SeekOrigin origin) => -1;
	public override int64 Tell() => 0;
	public override int64 Size() => 0;
}
