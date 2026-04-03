using System;

namespace Sedulous.Fonts;

/// Key for font cache lookups (path + pixel height)
public struct FontCacheKey : IHashable, IEquatable<FontCacheKey>
{
	public String Path;
	public float PixelHeight;

	public this(StringView path, float pixelHeight)
	{
		Path = new String(path);
		PixelHeight = pixelHeight;
	}

	public int GetHashCode()
	{
		int hash = Path?.GetHashCode() ?? 0;
		hash = hash * 31 + (int)(PixelHeight * 100);
		return hash;
	}

	public bool Equals(FontCacheKey other)
	{
		if (Path == null && other.Path == null)
			return Math.Abs(PixelHeight - other.PixelHeight) < 0.001f;
		if (Path == null || other.Path == null)
			return false;
		return Path == other.Path && Math.Abs(PixelHeight - other.PixelHeight) < 0.001f;
	}

	public void Dispose() mut
	{
		delete Path;
		Path = null;
	}
}
