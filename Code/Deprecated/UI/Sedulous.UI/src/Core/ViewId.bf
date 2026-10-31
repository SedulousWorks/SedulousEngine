using System;
using System.Threading;

namespace Sedulous.UI;

/// A unique identifier for a view.
///
/// Managers track views by this rather than by pointer: a view that has been deleted simply
/// fails to resolve, where a raw pointer would still look valid and be read.
struct ViewId : IHashable, IEquatable<ViewId>
{
	private uint32 mValue = 0;
	private static uint32 sNextId = 1;

	/// Nought never belongs to a view, so a default constructed ViewId is unusable by
	/// accident rather than pointing at whichever view was made first.
	public static readonly ViewId Invalid = .();

	public static ViewId Create()
	{
		// ExchangeAdd answers the value BEFORE the add, so the counter starting at one makes
		// the first minted id one and leaves nought permanently unissued.
		return .() { mValue = Interlocked.ExchangeAdd(ref sNextId, 1) };
	}

	public bool IsValid => mValue != 0;
	/// The raw value, for use as a dictionary key.
	public uint32 RawValue => mValue;

	public int GetHashCode() => (int)mValue;
	public bool Equals(ViewId other) => mValue == other.mValue;

	[Commutable]
	public static bool operator==(ViewId a, ViewId b) => a.mValue == b.mValue;

	public override void ToString(String strBuffer) => strBuffer.AppendF("ViewId({})", mValue);
}
