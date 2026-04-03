using System;
using System.Collections;

namespace Sedulous.OpenDDL;

/// <summary>
/// Represents a structure reference in an OpenDDL file.
/// A reference consists of a sequence of names that identify a path to a structure.
/// </summary>
class StructureRef
{
	private List<String> mNameArray = new .() ~ DeleteContainerAndItems!(_);
	private bool mGlobalRefFlag;

	/// <summary>
	/// Creates a new structure reference.
	/// </summary>
	/// <param name="global">True if this is a global reference, false for local.</param>
	public this(bool global = true)
	{
		mGlobalRefFlag = global;
	}

	/// <summary>
	/// Gets the array of names in this reference.
	/// For a null reference, this array is empty.
	/// </summary>
	public List<String> NameArray => mNameArray;

	/// <summary>
	/// Returns true if this reference is global (first name starts with $).
	/// Returns false if this reference is local (first name starts with %).
	/// </summary>
	public bool IsGlobal => mGlobalRefFlag;

	/// <summary>
	/// Returns true if this reference is local (first name starts with %).
	/// </summary>
	public bool IsLocal => !mGlobalRefFlag;

	/// <summary>
	/// Returns true if this is a null reference (empty name array).
	/// </summary>
	public bool IsNull => mNameArray.Count == 0;

	/// <summary>
	/// Returns the number of name segments in this reference.
	/// </summary>
	public int Count => mNameArray.Count;

	/// <summary>
	/// Gets the name at the specified index.
	/// </summary>
	public String this[int index] => mNameArray[index];

	/// <summary>
	/// Adds a name to this reference.
	/// The name should not include the $ or % prefix.
	/// </summary>
	public void AddName(StringView name)
	{
		mNameArray.Add(new String(name));
	}

	/// <summary>
	/// Resets this reference to an empty (null) state.
	/// </summary>
	/// <param name="global">Whether the new reference should be global.</param>
	public void Reset(bool global = true)
	{
		DeleteContainerAndItems!(mNameArray);
		mNameArray = new .();
		mGlobalRefFlag = global;
	}

	/// <summary>
	/// Parses a reference from text.
	/// </summary>
	/// <param name="text">The text to parse.</param>
	/// <param name="length">Receives the number of characters consumed.</param>
	/// <param name="reference">The reference to populate.</param>
	/// <returns>Ok on success, or an error code.</returns>
	public static DataResult Parse(StringView text, out int length, StructureRef reference)
	{
		length = 0;
		reference.Reset();

		if (text.IsEmpty)
			return .ReferenceInvalid;

		var remaining = text;

		// Check for "null"
		if (Lexer.ReadIdentifier(remaining, var idLen) == .Ok)
		{
			let identifier = remaining.Substring(0, idLen);
			if (identifier == "null")
			{
				length = idLen;
				return .Ok;
			}
		}

		// First name (can be global $ or local %)
		let firstChar = remaining[0];
		if (firstChar != '$' && firstChar != '%')
			return .ReferenceInvalid;

		reference.mGlobalRefFlag = (firstChar == '$');
		remaining = remaining.Substring(1);
		length = 1;

		// Read first identifier
		if (Lexer.ReadIdentifier(remaining, var nameLen) != .Ok)
			return .ReferenceInvalid;

		reference.AddName(remaining.Substring(0, nameLen));
		remaining = remaining.Substring(nameLen);
		length += nameLen;

		// Read subsequent local names
		while (!remaining.IsEmpty && remaining[0] == '%')
		{
			remaining = remaining.Substring(1);
			length++;

			if (Lexer.ReadIdentifier(remaining, var nextLen) != .Ok)
				return .ReferenceInvalid;

			reference.AddName(remaining.Substring(0, nextLen));
			remaining = remaining.Substring(nextLen);
			length += nextLen;
		}

		return .Ok;
	}

	/// <summary>
	/// Converts this reference to its string representation.
	/// </summary>
	public override void ToString(String strBuffer)
	{
		if (mNameArray.Count == 0)
		{
			strBuffer.Append("null");
			return;
		}

		strBuffer.Append(mGlobalRefFlag ? '$' : '%');
		strBuffer.Append(mNameArray[0]);

		for (var i = 1; i < mNameArray.Count; i++)
		{
			strBuffer.Append('%');
			strBuffer.Append(mNameArray[i]);
		}
	}

	/// <summary>
	/// Compares two references for equality.
	/// </summary>
	public bool Equals(StructureRef other)
	{
		if (other == null)
			return false;

		if (mNameArray.Count != other.mNameArray.Count)
			return false;

		if (mNameArray.Count > 0 && mGlobalRefFlag != other.mGlobalRefFlag)
			return false;

		for (var i = 0; i < mNameArray.Count; i++)
		{
			if (mNameArray[i] != other.mNameArray[i])
				return false;
		}

		return true;
	}

	public static bool operator ==(StructureRef lhs, StructureRef rhs)
	{
		if (lhs === null && rhs === null)
			return true;
		if (lhs === null || rhs === null)
			return false;
		return lhs.Equals(rhs);
	}

	public static bool operator !=(StructureRef lhs, StructureRef rhs)
	{
		return !(lhs == rhs);
	}
}
