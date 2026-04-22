using System;

namespace Sedulous.GUI;

/// Unique identifier for UI elements.
/// Uses a monotonically increasing counter to guarantee uniqueness.
public struct UIElementId : IEquatable<UIElementId>, IHashable
{
	/// The invalid/default element ID.
	public static readonly UIElementId Invalid = .(0);

	private uint64 mValue;

	/// Global counter for generating unique IDs.
	private static uint64 sNextId = 1;

	private this(uint64 value)
	{
		mValue = value;
	}

	/// Generates a new unique element ID.
	public static UIElementId Generate()
	{
		let id = sNextId;
		sNextId++;
		return .(id);
	}

	/// The raw value of the ID.
	public uint64 Value => mValue;

	/// Whether this is a valid (non-zero) ID.
	public bool IsValid => mValue != 0;

	public bool Equals(UIElementId other)
	{
		return mValue == other.mValue;
	}

	public int GetHashCode()
	{
		return (int)mValue;
	}

	public static bool operator ==(UIElementId lhs, UIElementId rhs)
	{
		return lhs.mValue == rhs.mValue;
	}

	public static bool operator !=(UIElementId lhs, UIElementId rhs)
	{
		return lhs.mValue != rhs.mValue;
	}

	public override void ToString(String strBuffer)
	{
		strBuffer.AppendF("UIElementId({0})", mValue);
	}
}
