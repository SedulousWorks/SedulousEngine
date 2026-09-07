using System;

namespace Sedulous.Core;

/// A string's identity as a hash, without the string.
///
/// For names that are compared and keyed on but never shown: a channel name, a parameter
/// name, an event name. Cheap to store, cheap to compare, and it makes the name a value
/// rather than an allocation.
///
/// The TEXT IS NOT KEPT. This is an identity, not a name, and it cannot be turned back
/// into one. Anything a person will read has to keep the string as well.
struct StringHash : IHashable
{
	private uint64 mValue;

	/// Zero means NO VALUE, which is why a default constructed one is not a valid
	/// identity: it is the one hash a real string is assumed never to produce.
	public this() { mValue = 0; }

	public this(StringView text) { mValue = HashText(text); }

	public uint64 Value => mValue;
	public bool IsValid => mValue != 0;

	[Commutable]
	public static bool operator==(StringHash a, StringHash b) => a.mValue == b.mValue;

	/// Finalised rather than used raw: FNV's low bits are not well distributed, and a
	/// dictionary takes the low bits.
	public int GetHashCode() => (int)HashInteger(mValue);
}
