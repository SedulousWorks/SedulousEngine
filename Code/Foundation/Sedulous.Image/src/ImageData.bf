using System;
using System.Threading;

namespace Sedulous.Image;

/// What every kind of image data can answer, whether it owns its pixels or points at
/// someone else's.
///
/// An abstract class rather than an interface because a Beef extension on an interface
/// only resolves through the interface's own static type, and because the instance id
/// below needs state.
abstract class ImageData
{
	private static int64 sNextInstanceId;

	/// A process unique id, minted per constructed instance.
	///
	/// A GPU cache keyed on identity MUST check this as well as the pointer. After a
	/// delete the allocator can hand a NEW image the SAME address, and a pointer-only key
	/// then serves the dead image's texture: that is the stale-preview bug, and it is
	/// baffling to diagnose from the symptom. Never key a cache on the reference alone.
	public readonly uint64 InstanceId = (uint64)Interlocked.Increment(ref sNextInstanceId);

	public abstract uint32 Width { get; }
	public abstract uint32 Height { get; }
	public abstract PixelFormat Format { get; }
	public abstract ImageColorSpace ColorSpace { get; }
	public abstract Span<uint8> PixelData { get; }
}
