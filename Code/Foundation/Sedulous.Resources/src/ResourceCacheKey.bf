using System;

namespace Sedulous.Resources;

/// Key for identifying cached resources.
struct ResourceCacheKey : IHashable, IEquatable<ResourceCacheKey>
{
	private String mPath;
	private Type mType;

	/// Gets the resource path.
	public StringView Path => mPath;

	/// Gets the resource type.
	public Type ResourceType => mType;

	public this(StringView path, Type type)
	{
		mPath = new String(path);
		mType = type;
	}

	/// Creates a deep copy of this key.
	public ResourceCacheKey Clone()
	{
		return .(mPath, mType);
	}

	public void Dispose() mut
	{
		delete mPath;
		mPath = null;
	}

	public int GetHashCode()
	{
		var hash = mPath.GetHashCode();
		hash = (hash * 397) ^ (int)Internal.UnsafeCastToPtr(mType);
		return hash;
	}

	public bool Equals(ResourceCacheKey other)
	{
		return mPath == other.mPath && mType == other.mType;
	}

	public static bool operator ==(ResourceCacheKey a, ResourceCacheKey b)
	{
		return a.Equals(b);
	}

	public static bool operator !=(ResourceCacheKey a, ResourceCacheKey b)
	{
		return !a.Equals(b);
	}
}
