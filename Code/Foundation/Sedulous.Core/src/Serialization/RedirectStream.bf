using System;
using Sedulous.Core.IO;

namespace Sedulous.Core.Serialization;

/// A stream that forwards to a target that can be swapped underneath it.
///
/// BinarySerializer's reader and writer are bound to one of these once, so entering a
/// framed region can redirect every transfer into a sub-stream without rebinding them.
class RedirectStream : IStream
{
	public IStream Target;

	public override bool IsValid => (Target != null) && Target.IsValid;
	public override int Read(Span<uint8> destination) => (Target != null) ? Target.Read(destination) : 0;
	public override int Write(Span<uint8> source) => (Target != null) ? Target.Write(source) : 0;
	public override int64 Seek(int64 offset, SeekOrigin origin) => (Target != null) ? Target.Seek(offset, origin) : -1;
	public override int64 Tell() => (Target != null) ? Target.Tell() : -1;
	public override int64 Size() => (Target != null) ? Target.Size() : -1;
}
