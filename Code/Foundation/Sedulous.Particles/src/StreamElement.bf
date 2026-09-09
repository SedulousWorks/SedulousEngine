using System;
using Sedulous.Core;

namespace Sedulous.Particles;

/// Maps a Beef type to its stream tag, so typed access can be CHECKED rather than a blind cast.
static class StreamElement
{
	/// The tag for T, or null for a type no stream holds.
	public static StreamElementType? Of<T>()
	{
		if (typeof(T) == typeof(float))
			return .Float;
		if (typeof(T) == typeof(Float2))
			return .Float2;
		if (typeof(T) == typeof(Float3))
			return .Float3;
		if (typeof(T) == typeof(Float4))
			return .Float4;
		if (typeof(T) == typeof(int32))
			return .Int32;
		return null;
	}
}
