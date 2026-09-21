using System;
using System.Collections;

namespace Sedulous.Json;

/// A JSON document node: null, bool, number, string, array or object.
///
/// A value OWNS its children, and Add and Set TAKE OWNERSHIP of what they are given. At and
/// Get hand back a BORROWED reference to the live child, which is the same shape the XML
/// document uses; a caller who wants an independent value asks for one with Clone.
///
/// A missing element or member is NULL rather than a null-typed value, so an absent member
/// and a member that is present and null are distinguishable, and nothing shares a mutable
/// sentinel.
///
/// Numbers are doubles, which is JSON's own model. Objects keep INSERTION ORDER, in parallel
/// key and value lists, because a wire protocol wants a deterministic byte output; lookup is
/// linear, which is right for wire sized objects and wrong for a large one.
class JsonValue
{
	private JsonType mType = .Null;
	private bool mBool = false;
	private double mNumber = 0.0;
	private String mString;
	/// Array elements, or an object's values, parallel to the keys.
	private List<JsonValue> mItems;
	/// Object member names. Null unless this is an object.
	private List<String> mKeys;

	public this() {}

	public this(bool value)
	{
		mType = .Bool;
		mBool = value;
	}

	public this(double value)
	{
		mType = .Number;
		mNumber = value;
	}

	public this(StringView value)
	{
		mType = .String;
		mString = new .(value);
	}

	public ~this()
	{
		ReleaseContents();
	}

	public static JsonValue MakeNull() => new JsonValue();
	public static JsonValue MakeBool(bool value) => new JsonValue(value);
	public static JsonValue MakeNumber(double value) => new JsonValue(value);
	public static JsonValue MakeString(StringView value) => new JsonValue(value);

	public static JsonValue MakeArray()
	{
		let value = new JsonValue();
		value.mType = .Array;
		return value;
	}

	public static JsonValue MakeObject()
	{
		let value = new JsonValue();
		value.mType = .Object;
		return value;
	}

	public JsonType Type => mType;
	public bool IsNull => mType == .Null;
	public bool IsBool => mType == .Bool;
	public bool IsNumber => mType == .Number;
	public bool IsString => mType == .String;
	public bool IsArray => mType == .Array;
	public bool IsObject => mType == .Object;

	/// The fallbacks are what make a wire read total: a field of the wrong type reads as the
	/// default rather than failing the whole message.
	public bool AsBool(bool fallback = false) => (mType == .Bool) ? mBool : fallback;
	public double AsNumber(double fallback = 0.0) => (mType == .Number) ? mNumber : fallback;
	public int64 AsInt(int64 fallback = 0) => (mType == .Number) ? (int64)mNumber : fallback;

	/// BORROWED, and empty when this is not a string.
	public StringView AsString() => (mType == .String) ? StringView(mString) : StringView();

	/// The element count of an array, or the member count of an object. Nought for anything
	/// else.
	public int Count => (mItems != null) ? mItems.Count : 0;

	/// The element at an index, BORROWED, or null when this is not an array or the index
	/// names nothing.
	public JsonValue At(int index)
	{
		if ((mType != .Array) || (mItems == null) || (index < 0) || (index >= mItems.Count))
			return null;
		return mItems[index];
	}

	/// Appends, TAKING OWNERSHIP. A value that is not an array becomes an empty one first,
	/// which is what lets a fresh value be built up without being declared an array.
	public void Add(JsonValue value)
	{
		if (mType != .Array)
		{
			ReleaseContents();
			mType = .Array;
		}
		if (mItems == null)
			mItems = new .();
		mItems.Add(value);
	}

	public bool Has(StringView key) => (mType == .Object) && (IndexOfKey(key) >= 0);

	/// The member, BORROWED, or null when this is not an object or has no such member.
	public JsonValue Get(StringView key)
	{
		if (mType != .Object)
			return null;
		let index = IndexOfKey(key);
		return (index >= 0) ? mItems[index] : null;
	}

	/// Sets a member, TAKING OWNERSHIP. Overwriting deletes what was there and KEEPS THE
	/// POSITION, so the object's order is its insertion order whatever is written over it.
	public void Set(StringView key, JsonValue value)
	{
		if (mType != .Object)
		{
			ReleaseContents();
			mType = .Object;
		}
		if (mItems == null)
			mItems = new .();
		if (mKeys == null)
			mKeys = new .();

		let index = IndexOfKey(key);
		if (index < 0)
		{
			mKeys.Add(new String(key));
			mItems.Add(value);
		}
		else
		{
			delete mItems[index];
			mItems[index] = value;
		}
	}

	/// Removes a member and deletes it. False when there was none.
	public bool Remove(StringView key)
	{
		if (mType != .Object)
			return false;
		let index = IndexOfKey(key);
		if (index < 0)
			return false;

		delete mKeys[index];
		mKeys.RemoveAt(index);
		delete mItems[index];
		mItems.RemoveAt(index);
		return true;
	}

	/// The member names in insertion order. BORROWED, and empty unless this is an object.
	public Span<String> Keys =>
		(mKeys != null) ? Span<String>(mKeys.Ptr, mKeys.Count) : Span<String>();

	/// The member name at an index, BORROWED, or empty when the index names nothing.
	public StringView KeyAt(int index)
	{
		if ((mType != .Object) || (mKeys == null) || (index < 0) || (index >= mKeys.Count))
			return .();
		return mKeys[index];
	}

	/// An INDEPENDENT copy, owned by the caller.
	public JsonValue Clone()
	{
		let copy = new JsonValue();
		copy.mType = mType;
		copy.mBool = mBool;
		copy.mNumber = mNumber;
		if (mString != null)
			copy.mString = new .(mString);
		if (mItems != null)
		{
			copy.mItems = new .();
			for (let item in mItems)
				copy.mItems.Add(item.Clone());
		}
		if (mKeys != null)
		{
			copy.mKeys = new .();
			for (let key in mKeys)
				copy.mKeys.Add(new String(key));
		}
		return copy;
	}

	/// The JSON text for this value, appended to outText.
	public void ToString(String outText, bool pretty = false) =>
		JsonWriter.Write(this, outText, pretty);

	/// The parse's value, or a Null value on any error, so a caller that does not care why
	/// never sees a half built document. JsonParser.Parse is the erroring path.
	public static JsonValue Parse(StringView text)
	{
		let result = scope JsonParseResult();
		JsonParser.Parse(text, result);
		return result.TakeValue();
	}

	private int IndexOfKey(StringView key)
	{
		if (mKeys == null)
			return -1;
		for (int i = 0; i < mKeys.Count; i++)
		{
			if (mKeys[i] == key)
				return i;
		}
		return -1;
	}

	/// Empties this value back to Null, deleting whatever it held.
	private void ReleaseContents()
	{
		delete mString;
		mString = null;
		if (mItems != null)
		{
			DeleteContainerAndItems!(mItems);
			mItems = null;
		}
		if (mKeys != null)
		{
			DeleteContainerAndItems!(mKeys);
			mKeys = null;
		}
		mType = .Null;
		mBool = false;
		mNumber = 0.0;
	}
}
