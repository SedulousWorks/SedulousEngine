using System;
namespace Bulkan;

	/// <summary>
	/// Structure specifying a two-dimensional subregion.
	/// </summary>
extension VkRect2D : IEquatable<VkRect2D>, IHashable
{
	/// <summary>
	/// An <see cref="VkRect2D"/> with all of its components set to zero.
	/// </summary>
	public static readonly VkRect2D Zero = .(VkOffset2D.Zero, VkExtent2D.Zero);

	/// <summary>
	/// Initializes a new instance of the <see cref="VkRect2D"/> structure.
	/// </summary>
	/// <param name="offset">The offset component of the rectangle.</param>
	/// <param name="extent">The extent component of the rectangle.</param>
	public this(VkOffset2D offset, VkExtent2D extent)
	{
		this.offset = offset;
		this.extent = extent;
	}

	/// <summary>
	/// Initializes a new instance of the <see cref="VkRect2D"/> structure.
	/// </summary>
	/// <param name="extent">The extent component of the rectangle.</param>
	public this(VkExtent2D extent)
	{
		this.offset = default(VkOffset2D);
		this.extent = extent;
	}

	/// <summary>
	/// Initializes a new instance of the <see cref="Rect2D"/> structure.
	/// </summary>
	/// <param name="x">The X component of the offset.</param>
	/// <param name="y">The Y component of the offset.</param>
	/// <param name="width">The width component of the extent.</param>
	/// <param name="height">The height component of the extent.</param>
	public this(int32 x, int32 y, uint32 width, uint32 height)
	{
		this.offset = VkOffset2D(x, y);
		this.extent = VkExtent2D() { width = width, height = height };
	}

	/// <summary>
	/// Initializes a new instance of the <see cref="Rect2D"/> structure.
	/// </summary>
	/// <param name="x">The X component of the offset.</param>
	/// <param name="y">The Y component of the offset.</param>
	/// <param name="width">The width component of the extent.</param>
	/// <param name="height">The height component of the extent.</param>
	public this(int32 x, int32 y, int32 width, int32 height)
	{
		this.offset = VkOffset2D(x, y);
		this.extent = VkExtent2D() { width = (uint32)width, height = (uint32)height };
	}

	/// <summary>
	/// Initializes a new instance of the <see cref="Rect2D"/> structure.
	/// </summary>
	/// <param name="width">The width component of the extent.</param>
	/// <param name="height">The height component of the extent.</param>
	public this(uint32 width, uint32 height)
	{
		this.offset = default(VkOffset2D);
		this.extent = VkExtent2D(width, height);
	}

	/// <summary>
	/// Determines whether the specified <see cref="VkRect2D"/> is equal to this instance.
	/// </summary>
	/// <param name="other">The <see cref="VkRect2D"/> to compare with this instance.</param>
	/// <returns>
	/// <c>true</c> if the specified <see cref="VkRect2D"/> is equal to this instance; otherwise, <c>false</c>.
	/// </returns>
	public bool Equals(VkRect2D other)
	{
		return other.offset.Equals(offset) && other.extent.Equals(extent);
	}

	/// <summary>
	/// Determines whether the specified <see cref="object"/> is equal to this instance.
	/// </summary>
	/// <param name="obj">The <see cref="object"/> to compare with this instance.</param>
	/// <returns>
	/// <c>true</c> if the specified <see cref="object"/> is equal to this instance; otherwise, <c>false</c>.
	/// </returns>
	public bool Equals(Object obj)
	{
		return obj is VkRect2D && Equals((VkRect2D)obj);
	}

	/// <summary>
	/// Returns the hash code for this instance.
	/// </summary>
	/// <returns>The hash code.</returns>
	public int GetHashCode()
	{
		int hashCode = extent.GetHashCode();
		hashCode = (hashCode * 397) ^ offset.GetHashCode();
		return hashCode;
	}

	/// <summary>
	/// Returns a boolean indicating whether the two given rectangles are equal.
	/// </summary>
	/// <param name="left">The first rectangle to compare.</param>
	/// <param name="right">The second rectangle to compare.</param>
	/// <returns><c>true</c> if the rectangles are equal; <c>false</c> otherwise.</returns>
	public static bool operator ==(VkRect2D left, VkRect2D right) => left.Equals(right);

	/// <summary>
	/// Returns a boolean indicating whether the two given rectangles are not equal.
	/// </summary>
	/// <param name="left">The first rectangle to compare.</param>
	/// <param name="right">The second rectangle to compare.</param>
	/// <returns>
	/// <c>true</c> if the rectangles are not equal; <c>false</c> if they are equal.
	/// </returns>
	public static bool operator !=(VkRect2D left, VkRect2D right) => !left.Equals(right);
}
