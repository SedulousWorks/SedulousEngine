using System;

namespace Sedulous.Core.Mathematics;

extension Vector4
{
    /// <inheritdoc/>
    public int GetHashCode()
    {
        unchecked
        {
            var hash = 17;
            hash = hash * 23 + X.GetHashCode();
            hash = hash * 23 + Y.GetHashCode();
            hash = hash * 23 + Z.GetHashCode();
            hash = hash * 23 + W.GetHashCode();
            return hash;
        }
    }
    
    /// <summary>
    /// Compares two objects to determine whether they are equal.
    /// </summary>
    /// <param name="v1">The first value to compare.</param>
    /// <param name="v2">The second value to compare.</param>
    /// <returns><see langword="true"/> if the two values are equal; otherwise, <see langword="false"/>.</returns>
    public static bool operator ==(Vector4 v1, Vector4 v2)
    {
        return
            v1.X == v2.X &&
            v1.Y == v2.Y &&
            v1.Z == v2.Z &&
            v1.W == v2.W;
    }
    
    /// <summary>
    /// Compares two objects to determine whether they are unequal.
    /// </summary>
    /// <param name="v1">The first value to compare.</param>
    /// <param name="v2">The second value to compare.</param>
    /// <returns><see langword="true"/> if the two values are unequal; otherwise, <see langword="false"/>.</returns>
    public static bool operator !=(Vector4 v1, Vector4 v2)
    {
        return
            v1.X != v2.X ||
            v1.Y != v2.Y ||
            v1.Z != v2.Z ||
            v1.W != v2.W;
    }
    
    /// <inheritdoc/>
    public bool Equals(Object other)
    {
		if(let x = other as Self?)
			return Equals(x);
		return false;
    }
    
    /// <inheritdoc/>
    public bool Equals(Vector4 other)
    {
        return
            this.X == other.X &&
            this.Y == other.Y &&
            this.Z == other.Z &&
            this.W == other.W;
    }
}
