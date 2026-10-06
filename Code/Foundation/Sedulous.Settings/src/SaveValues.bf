using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Settings;

enum SaveValueKind : uint8
{
	Bool,
	Int,
	Float,
	Text,
	/// A list of numbers, set and read whole (a recorded run).
	Floats
}

/// A settings section whose fields are not known ahead: a game's saved values (a best time, a
/// high score, an unlocked level, its own options), each a key and a typed value.
///
/// A save file is then an ordinary settings file holding one SaveValues section, with the
/// store's envelope and unknown section passthrough. Kept sorted by key, so a saved file reads
/// (and diffs) the same way every time.
class SaveValues : ISerializable
{
	public class Entry
	{
		public String Key = new .() ~ delete _;
		public SaveValueKind Kind = .Int;
		public bool BoolValue;
		public int32 IntValue;
		public float FloatValue;
		public String TextValue = new .() ~ delete _;
		public List<float> FloatsValue = new .() ~ delete _;
	}

	/// Kinds are written by name, so a save file reads in a text editor and a kind added later
	/// does not renumber the others.
	private static readonly String[5] sKindNames = .("bool", "int", "float", "text", "floats");

	private List<Entry> mEntries = new .() ~ DeleteContainerAndItems!(_);

	/// Makes the section loadable by its type name. Safe to call again.
	public static void Register(SerializableRegistry registry = null)
	{
		let target = (registry != null) ? registry : GlobalSerializableRegistry;
		target.Register(TypeIdOf("Sedulous.Settings.SaveValues"), () => new SaveValues());
	}

	public int Count => mEntries.Count;
	public Entry this[int index] => mEntries[index];
	public bool Has(StringView key) => Find(key) != null;

	// Each setter answers whether the stored value changed (a new key, another kind or another
	// value), which is what tells the owner the file needs writing.

	public bool SetBool(StringView key, bool value)
	{
		let entry = Slot(key, let inserted);
		let changed = inserted || (entry.Kind != .Bool) || (entry.BoolValue != value);
		Reset(entry, .Bool);
		entry.BoolValue = value;
		return changed;
	}

	public bool SetInt(StringView key, int32 value)
	{
		let entry = Slot(key, let inserted);
		let changed = inserted || (entry.Kind != .Int) || (entry.IntValue != value);
		Reset(entry, .Int);
		entry.IntValue = value;
		return changed;
	}

	public bool SetFloat(StringView key, float value)
	{
		let entry = Slot(key, let inserted);
		let changed = inserted || (entry.Kind != .Float) || (entry.FloatValue != value);
		Reset(entry, .Float);
		entry.FloatValue = value;
		return changed;
	}

	public bool SetText(StringView key, StringView value)
	{
		let entry = Slot(key, let inserted);
		let changed = inserted || (entry.Kind != .Text) || (entry.TextValue != value);
		Reset(entry, .Text);
		entry.TextValue.Set(value);
		return changed;
	}

	public bool SetFloats(StringView key, Span<float> values)
	{
		let entry = Slot(key, let inserted);
		var changed = inserted || (entry.Kind != .Floats) || (entry.FloatsValue.Count != values.Length);
		for (int i = 0; !changed && (i < values.Length); i++)
			changed = entry.FloatsValue[i] != values[i];
		Reset(entry, .Floats);
		entry.FloatsValue.AddRange(values);
		return changed;
	}

	// A value read as another kind than it was written answers the fallback, except that an
	// int reads as a float: a whole number is still a number.

	public bool GetBool(StringView key, bool fallback)
	{
		let entry = Find(key);
		return ((entry != null) && (entry.Kind == .Bool)) ? entry.BoolValue : fallback;
	}

	public int32 GetInt(StringView key, int32 fallback)
	{
		let entry = Find(key);
		return ((entry != null) && (entry.Kind == .Int)) ? entry.IntValue : fallback;
	}

	public float GetFloat(StringView key, float fallback)
	{
		let entry = Find(key);
		if (entry == null)
			return fallback;
		if (entry.Kind == .Float)
			return entry.FloatValue;
		return (entry.Kind == .Int) ? (float)entry.IntValue : fallback;
	}

	/// The text, valid until the value is next changed; the fallback when there is none.
	public StringView GetText(StringView key, StringView fallback)
	{
		let entry = Find(key);
		return ((entry != null) && (entry.Kind == .Text)) ? entry.TextValue : fallback;
	}

	/// The list into `outValues` (cleared first), answering whether there was one: false, the list
	/// left empty, when the key is absent or holds another kind. A list is not a number to
	/// GetFloat.
	public bool GetFloats(StringView key, List<float> outValues)
	{
		outValues.Clear();
		let entry = Find(key);
		if ((entry == null) || (entry.Kind != .Floats))
			return false;
		outValues.AddRange(entry.FloatsValue);
		return true;
	}

	/// Answers whether there was a value to remove.
	public bool Remove(StringView key)
	{
		let at = LowerBound(key);
		if ((at < mEntries.Count) && (mEntries[at].Key == key))
		{
			delete mEntries[at];
			mEntries.RemoveAt(at);
			return true;
		}
		return false;
	}

	/// Answers whether there was anything to clear.
	public bool Clear()
	{
		let had = !mEntries.IsEmpty;
		ClearAndDeleteItems!(mEntries);
		return had;
	}

	public void Serialize(ISerializer ar)
	{
		let writing = ar.Mode == .Write;
		uint32 count = writing ? (uint32)mEntries.Count : 0;
		ar.Key("values");
		ar.BeginArray(ref count);
		if (!writing)
			ClearAndDeleteItems!(mEntries);

		for (uint32 i < count)
		{
			let entry = writing ? mEntries[(int)i] : new Entry();
			let kind = scope String(sKindNames[(int)entry.Kind]);
			ar.BeginObject();
			Sedulous.Core.Serialization.Serialize(ar, "key", entry.Key);
			Sedulous.Core.Serialization.Serialize(ar, "kind", kind);
			if (!writing && !KindFromName(kind, out entry.Kind))
			{
				// A kind this build does not know (a newer build wrote it): that value is
				// skipped, the rest of the save still reads, and the next write drops it. Exact in
				// a keyed format (a save file is XML), which reads the next entry by its own key;
				// a positional payload cannot size a value it does not know.
				delete entry;
				ar.EndObject();
				continue;
			}
			switch (entry.Kind)
			{
			case .Bool: SerializeValue(ar, "value", ref entry.BoolValue);
			case .Int: SerializeValue(ar, "value", ref entry.IntValue);
			case .Float: SerializeValue(ar, "value", ref entry.FloatValue);
			case .Text: Sedulous.Core.Serialization.Serialize(ar, "value", entry.TextValue);
			case .Floats:
				ar.Key("value");
				SerializeList(ar, entry.FloatsValue);
			}
			ar.EndObject();

			if (!writing)
			{
				// A file edited by hand may be out of order or repeat a key: insert in order,
				// the later value winning.
				let at = LowerBound(entry.Key);
				if ((at < mEntries.Count) && (mEntries[at].Key == entry.Key))
				{
					delete mEntries[at];
					mEntries[at] = entry;
				}
				else
				{
					mEntries.Insert(at, entry);
				}
			}
		}
		ar.EndArray();
	}

	private static bool KindFromName(StringView name, out SaveValueKind kind)
	{
		for (int i < sKindNames.Count)
		{
			if (sKindNames[i] == name)
			{
				kind = (SaveValueKind)i;
				return true;
			}
		}
		kind = .Int;
		return false;
	}

	private static void Reset(Entry entry, SaveValueKind kind)
	{
		entry.Kind = kind;
		entry.BoolValue = false;
		entry.IntValue = 0;
		entry.FloatValue = 0.0f;
		entry.TextValue.Clear();
		entry.FloatsValue.Clear();
	}

	private int LowerBound(StringView key)
	{
		int low = 0;
		int high = mEntries.Count;
		while (low < high)
		{
			let mid = low + (high - low) / 2;
			if (StringView.Compare(mEntries[mid].Key, key) < 0)
				low = mid + 1;
			else
				high = mid;
		}
		return low;
	}

	private Entry Find(StringView key)
	{
		let at = LowerBound(key);
		return ((at < mEntries.Count) && (mEntries[at].Key == key)) ? mEntries[at] : null;
	}

	/// The entry for `key`, inserted in order when new (`inserted` says which).
	private Entry Slot(StringView key, out bool inserted)
	{
		let at = LowerBound(key);
		inserted = !((at < mEntries.Count) && (mEntries[at].Key == key));
		if (inserted)
		{
			let entry = new Entry();
			entry.Key.Set(key);
			mEntries.Insert(at, entry);
		}
		return mEntries[at];
	}
}
