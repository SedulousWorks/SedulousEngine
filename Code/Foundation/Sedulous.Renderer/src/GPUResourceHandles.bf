namespace Sedulous.Renderer;

using System;

/// Handle to a GPU mesh in the GPUResourceManager.
public struct GPUMeshHandle : IHashable, IEquatable<GPUMeshHandle>
{
	public uint32 Index;
	public uint32 Generation;

	public static Self Invalid = .() { Index = uint32.MaxValue, Generation = 0 };

	public bool IsValid => Index != uint32.MaxValue;

	public int GetHashCode() => (int)(Index ^ (Generation << 16));

	public bool Equals(GPUMeshHandle other) => Index == other.Index && Generation == other.Generation;
	public static bool operator ==(Self lhs, Self rhs) => lhs.Index == rhs.Index && lhs.Generation == rhs.Generation;
	public static bool operator !=(Self lhs, Self rhs) => !(lhs == rhs);
}

/// Handle to a GPU texture in the GPUResourceManager.
public struct GPUTextureHandle : IHashable, IEquatable<GPUTextureHandle>
{
	public uint32 Index;
	public uint32 Generation;

	public static Self Invalid = .() { Index = uint32.MaxValue, Generation = 0 };

	public bool IsValid => Index != uint32.MaxValue;

	public int GetHashCode() => (int)(Index ^ (Generation << 16));

	public bool Equals(GPUTextureHandle other) => Index == other.Index && Generation == other.Generation;
	public static bool operator ==(Self lhs, Self rhs) => lhs.Index == rhs.Index && lhs.Generation == rhs.Generation;
	public static bool operator !=(Self lhs, Self rhs) => !(lhs == rhs);
}

/// Handle to a GPU bone buffer in the GPUResourceManager.
public struct GPUBoneBufferHandle : IHashable, IEquatable<GPUBoneBufferHandle>
{
	public uint32 Index;
	public uint32 Generation;

	public static Self Invalid = .() { Index = uint32.MaxValue, Generation = 0 };

	public bool IsValid => Index != uint32.MaxValue;

	public int GetHashCode() => (int)(Index ^ (Generation << 16));

	public bool Equals(GPUBoneBufferHandle other) => Index == other.Index && Generation == other.Generation;
	public static bool operator ==(Self lhs, Self rhs) => lhs.Index == rhs.Index && lhs.Generation == rhs.Generation;
	public static bool operator !=(Self lhs, Self rhs) => !(lhs == rhs);
}
