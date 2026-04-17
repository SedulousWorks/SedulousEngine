namespace Sedulous.UI;

using System;
using System.Threading;

/// Unique identifier for a View, generated via atomic counter.
/// Used as the key in UIContext's element registry for safe weak references.
public struct ViewId : IHashable, IEquatable<ViewId>
{
	private static int32 sNextId = 1;

	public readonly int32 Value;

	private this(int32 value) { Value = value; }

	public static ViewId Generate()
	{
		let id = Interlocked.Increment(ref sNextId, .Relaxed) - 1;
		return .(id);
	}

	public static readonly ViewId Invalid = .(0);
	public bool IsValid => Value != 0;

	public int GetHashCode() => Value;
	public bool Equals(ViewId other) => Value == other.Value;

	public static bool operator==(ViewId a, ViewId b) => a.Value == b.Value;
	public static bool operator!=(ViewId a, ViewId b) => a.Value != b.Value;
}
