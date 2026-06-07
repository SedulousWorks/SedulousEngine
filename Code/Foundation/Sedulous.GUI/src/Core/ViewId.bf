namespace Sedulous.GUI;

using System;
using System.Threading;

/// Unique identifier for a view. Used by managers (Input, Focus, DragDrop)
/// to track views safely without raw pointers. If a view is deleted,
/// lookups by its ViewId return null.
public struct ViewId : IHashable, IEquatable<ViewId>
{
	private uint32 mValue;

	private static int32 sNextId = 1;

	public static readonly ViewId Invalid = .() { mValue = 0 };

	/// Creates a new unique ViewId.
	public static ViewId Create()
	{
		let id = (uint32)(Interlocked.Increment(ref sNextId, .Relaxed) - 1);
		return .() { mValue = id };
	}

	public bool IsValid => mValue != 0;

	/// Raw uint32 value for use as dictionary key.
	public uint32 RawValue => mValue;

	public int GetHashCode() => (int)mValue;

	public bool Equals(ViewId other) => mValue == other.mValue;
	public static bool operator ==(ViewId a, ViewId b) => a.mValue == b.mValue;
	public static bool operator !=(ViewId a, ViewId b) => a.mValue != b.mValue;

	public override void ToString(String strBuffer)
	{
		strBuffer.AppendF("ViewId({})", mValue);
	}
}
