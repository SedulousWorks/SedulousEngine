using System;
using System.Collections;

namespace Sedulous.GUI;

// A GUI's named values, which markup and scripts bind to (after RmlUi's data models). Each name
// is an observable value, so a binding that reads `score` follows it with no subscription; a name
// read before it is set is still followed, and takes its first value when one arrives. Values
// are Variants: whatever the game, a script or a widget writes.
//
// The conversions bindings need live here too: a value meets a property of another type (a
// script's number for a slider's float, a count for a label's text), and two values compare
// across numeric types, so writing back what was just read is no change.
//
// These are corlib's Variants (System.Variant; Sedulous.GUI.Variant is a model's cell value). One
// is a bitwise value: a copy shares an object or an owned buffer with the one it came from. So
// text is COPIED (the data model keeps its own), a read hands out a
// borrowed view, and a conversion returns a Variant the caller disposes. A value wider than a
// pointer (a StringView) is a buffer the Variant allocates: whoever creates one disposes it.
//
// A node is a value too (a script's Gui.SetNode): held weakly, as a script holds one, by its
// Node.ElementRef, so the value reads as no node once the node is gone. The model keeps a reference
// on the element table while it holds one, as a node does, since the model can outlive its GUI
// (a binding or a tween holds it).

static
{
	/// A numeric Variant's value as double (bool counts as 0 or 1); false when it holds no number.
	public static bool NumberOf(System.Variant v, out double outValue)
	{
		outValue = 0.0;
		let type = v.VariantType;
		if (type == typeof(double)) { outValue = v.Get<double>(); return true; }
		if (type == typeof(float)) { outValue = v.Get<float>(); return true; }
		if (type == typeof(int32)) { outValue = v.Get<int32>(); return true; }
		if (type == typeof(int64)) { outValue = (double)v.Get<int64>(); return true; }
		// Beef's own: an integer literal is an `int`.
		if (type == typeof(int)) { outValue = (double)v.Get<int>(); return true; }
		if (type == typeof(uint)) { outValue = (double)v.Get<uint>(); return true; }
		if (type == typeof(uint32)) { outValue = v.Get<uint32>(); return true; }
		if (type == typeof(uint64)) { outValue = (double)v.Get<uint64>(); return true; }
		if (type == typeof(bool)) { outValue = v.Get<bool>() ? 1.0 : 0.0; return true; }
		return false;
	}

	/// The node a Variant holds (a Node.ElementRef, as Gui.SetNode stores one), or null: when it
	/// holds none, or the node is gone.
	public static Node NodeOf(System.Variant v)
	{
		if (v.VariantType != typeof(Node.ElementRef))
			return null;
		let held = v.Get<Node.ElementRef>();
		return (held.Table != null) ? held.Table.Resolve(held.Slot, held.Generation) : null;
	}

	/// Whether the Variant holds text: a String or a StringView.
	public static bool IsText(System.Variant v) => (v.VariantType == typeof(String)) || (v.VariantType == typeof(StringView));

	/// The text a Variant holds (empty when it holds none), a view of it.
	public static StringView TextOf(System.Variant v)
	{
		if (v.VariantType == typeof(String))
		{
			let s = v.Get<String>();
			return (s != null) ? (StringView)s : default;
		}
		if (v.VariantType == typeof(StringView))
			return v.Get<StringView>();
		return default;
	}

	/// A Variant that holds `value` and owns its own copy of the text.
	public static System.Variant TextVariant(StringView value) => System.Variant.Create(new String(value), true);

	/// A copy of `value` that owns what it holds: text copied, a value type copied, an object
	/// (other than text) shared by reference.
	public static System.Variant CopyVariant(System.Variant value)
	{
		if (IsText(value))
			return TextVariant(TextOf(value));
		if (!value.HasValue)
			return default;
		if (value.IsObject)
			return System.Variant.CreateFromVariant(value);
		// A value type by its bytes, wherever they are: corlib's CreateFromVariant keeps a borrowed
		// view's POINTER as the value of a small struct (a view of a double came out as its address).
		var source = value;
		return System.Variant.Create(value.VariantType, source.DataPtr);
	}

	/// Appends `value` as text: a string as it is, a whole number without a fraction, another
	/// number in its shortest form, a boolean as true or false; nothing otherwise.
	public static void FormatVariant(System.Variant value, String outText)
	{
		if (IsText(value))
		{
			outText.Append(TextOf(value));
			return;
		}
		if (value.VariantType == typeof(bool))
		{
			outText.Append(value.Get<bool>() ? "true" : "false");
			return;
		}
		if (!NumberOf(value, let n))
			return;
		if (value.VariantType == typeof(float))
		{
			let f = value.Get<float>();
			if (f != (float)(int64)f)
			{
				f.ToString(outText); // its own shortest form (0.4), not its widening's
				return;
			}
		}
		if ((Math.Abs(n) < 1e15) && (n == (double)(int64)n))
		{
			((int64)n).ToString(outText);
			return;
		}
		n.ToString(outText); // the shortest form that reads back as the same number
	}

	/// `value` as a Variant of `target`'s type: numbers convert among numeric types and from text,
	/// anything formats to text, and numbers or "true"/"false" to bool. Empty when it cannot. The
	/// caller disposes the result (it owns its text).
	public static System.Variant ConvertVariant(System.Variant value, Type target)
	{
		if (!value.HasValue)
			return default;
		if (target == typeof(String))
		{
			let text = new String();
			FormatVariant(value, text);
			return System.Variant.Create(text, true);
		}
		if (value.VariantType == target)
			return CopyVariant(value);
		var numeric = NumberOf(value, var n);
		if (!numeric && IsText(value))
		{
			let text = TextOf(value)..Trim();
			if ((target == typeof(bool)) && ((text == "true") || (text == "false")))
				return System.Variant.Create(text == "true");
			if (double.Parse(text) case .Ok(let parsed))
			{
				n = parsed;
				numeric = true;
			}
		}
		if (!numeric)
			return default;
		let whole = (int64)((n < 0.0) ? n - 0.5 : n + 0.5); // to the nearest
		if (target == typeof(float)) return System.Variant.Create((float)n);
		if (target == typeof(double)) return System.Variant.Create(n);
		if (target == typeof(int32)) return System.Variant.Create((int32)whole);
		if (target == typeof(int64)) return System.Variant.Create(whole);
		if (target == typeof(uint32)) return System.Variant.Create((uint32)((whole < 0) ? 0 : whole));
		if (target == typeof(uint64)) return System.Variant.Create((uint64)((whole < 0) ? 0 : whole));
		if (target == typeof(int)) return System.Variant.Create((int)whole);
		if (target == typeof(uint)) return System.Variant.Create((uint)((whole < 0) ? 0 : whole));
		if (target == typeof(bool)) return System.Variant.Create(n != 0.0);
		return default;
	}

	/// Whether two values are the same value: numbers across numeric types, text by its bytes, two
	/// empties; other types only when both are empty (they cannot be compared generically).
	public static bool VariantsEqual(System.Variant a, System.Variant b)
	{
		if (!a.HasValue || !b.HasValue)
			return !a.HasValue && !b.HasValue;
		if (NumberOf(a, let x) && NumberOf(b, let y))
			return x == y;
		if (IsText(a) && IsText(b))
			return TextOf(a) == TextOf(b);
		if ((a.VariantType == typeof(Node.ElementRef)) && (b.VariantType == typeof(Node.ElementRef)))
		{
			let first = a.Get<Node.ElementRef>();
			let second = b.Get<Node.ElementRef>();
			return (first.Table === second.Table) && (first.Slot == second.Slot) && (first.Generation == second.Generation);
		}
		return false;
	}
}

/// Shared by its GUIContext and every binding to it (each holds a reference), so a binding never
/// outlives it.
class DataModel : RefCounted
{
	private class Entry
	{
		public String Name = new .() ~ delete _;
		public System.Variant Value ~ { DataModel.LetGoOf(_); _.Dispose(); };
		public bool HasValue = false;
		/// The tween moving it.
		public uint64 TweenOwner = 0;
		public Observable Changed = new .() ~ delete _;
	}

	private List<Entry> mEntries = new .() ~ DeleteContainerAndItems!(_);

	/// The value named `name` (empty when unset); a read a binding records, set or not. A view
	/// of the model's own value: valid until the name is set again.
	public System.Variant Get(StringView name)
	{
		let entry = EntryFor(name);
		entry.Changed.Track();
		return System.Variant.CreateFromVariantRef(ref entry.Value);
	}

	/// Sets `name` (whatever reads it follows); false when it already held that value. The model
	/// keeps its own copy: the caller keeps what it passed.
	public bool Set(StringView name, System.Variant value)
	{
		let entry = EntryFor(name);
		if (entry.HasValue && VariantsEqual(entry.Value, value))
			return false;
		LetGoOf(entry.Value);
		entry.Value.Dispose();
		entry.Value = CopyVariant(value);
		if (entry.Value.VariantType == typeof(Node.ElementRef))
			entry.Value.Get<Node.ElementRef>().Table?.AddRef(); // let go of in LetGoOf
		entry.HasValue = true;
		entry.Changed.Notify();
		return true;
	}

	/// The value named `name`, read without a binding following it (a tween reading where it
	/// starts). A view, as Get's is.
	public System.Variant Peek(StringView name)
	{
		for (let entry in mEntries)
		{
			if (entry.Name == name)
				return System.Variant.CreateFromVariantRef(ref entry.Value);
		}
		return default;
	}

	/// The tween now moving `name`: a tween starting claims it, so the one before it sees it was
	/// replaced and stops where it is. 0 when none has.
	public void ClaimTween(StringView name, uint64 owner) => EntryFor(name).TweenOwner = owner;

	public uint64 TweenOwnerOf(StringView name)
	{
		for (let entry in mEntries)
		{
			if (entry.Name == name)
				return entry.TweenOwner;
		}
		return 0;
	}

	public bool Has(StringView name)
	{
		for (let entry in mEntries)
		{
			if (entry.Name == name)
				return entry.HasValue;
		}
		return false;
	}

	/// Lets go of the table reference a node value holds (taken in Set).
	private static void LetGoOf(System.Variant value)
	{
		if (value.VariantType == typeof(Node.ElementRef))
			value.Get<Node.ElementRef>().Table?.ReleaseRef();
	}

	private Entry EntryFor(StringView name)
	{
		for (let entry in mEntries)
		{
			if (entry.Name == name)
				return entry;
		}
		let entry = new Entry();
		entry.Name.Set(name);
		mEntries.Add(entry);
		return entry;
	}
}
