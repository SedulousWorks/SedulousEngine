using System;

namespace Bulkan;

[CRepr]
public struct VkInstance : IEquatable<VkInstance>, IHashable
{
	public readonly int Handle;
	public this(int existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(int handle) => Self(handle);
	public static implicit operator int(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, int right) => left.Handle == right;
	public static bool operator !=(Self left, int right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkPhysicalDevice : IEquatable<VkPhysicalDevice>, IHashable
{
	public readonly int Handle;
	public this(int existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(int handle) => Self(handle);
	public static implicit operator int(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, int right) => left.Handle == right;
	public static bool operator !=(Self left, int right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkDevice : IEquatable<VkDevice>, IHashable
{
	public readonly int Handle;
	public this(int existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(int handle) => Self(handle);
	public static implicit operator int(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, int right) => left.Handle == right;
	public static bool operator !=(Self left, int right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkQueue : IEquatable<VkQueue>, IHashable
{
	public readonly int Handle;
	public this(int existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(int handle) => Self(handle);
	public static implicit operator int(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, int right) => left.Handle == right;
	public static bool operator !=(Self left, int right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkCommandBuffer : IEquatable<VkCommandBuffer>, IHashable
{
	public readonly int Handle;
	public this(int existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(int handle) => Self(handle);
	public static implicit operator int(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, int right) => left.Handle == right;
	public static bool operator !=(Self left, int right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkDeviceMemory : IEquatable<VkDeviceMemory>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkCommandPool : IEquatable<VkCommandPool>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkBuffer : IEquatable<VkBuffer>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkBufferView : IEquatable<VkBufferView>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkImage : IEquatable<VkImage>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkImageView : IEquatable<VkImageView>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkShaderModule : IEquatable<VkShaderModule>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkPipeline : IEquatable<VkPipeline>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkPipelineLayout : IEquatable<VkPipelineLayout>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkSampler : IEquatable<VkSampler>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkDescriptorSet : IEquatable<VkDescriptorSet>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkDescriptorSetLayout : IEquatable<VkDescriptorSetLayout>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkDescriptorPool : IEquatable<VkDescriptorPool>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkFence : IEquatable<VkFence>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkSemaphore : IEquatable<VkSemaphore>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkEvent : IEquatable<VkEvent>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkQueryPool : IEquatable<VkQueryPool>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkFramebuffer : IEquatable<VkFramebuffer>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkRenderPass : IEquatable<VkRenderPass>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkPipelineCache : IEquatable<VkPipelineCache>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkPipelineBinaryKHR : IEquatable<VkPipelineBinaryKHR>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkIndirectCommandsLayoutNV : IEquatable<VkIndirectCommandsLayoutNV>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkIndirectCommandsLayoutEXT : IEquatable<VkIndirectCommandsLayoutEXT>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkIndirectExecutionSetEXT : IEquatable<VkIndirectExecutionSetEXT>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkDescriptorUpdateTemplate : IEquatable<VkDescriptorUpdateTemplate>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkDescriptorUpdateTemplateKHR : IEquatable<VkDescriptorUpdateTemplateKHR>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkSamplerYcbcrConversion : IEquatable<VkSamplerYcbcrConversion>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkSamplerYcbcrConversionKHR : IEquatable<VkSamplerYcbcrConversionKHR>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkValidationCacheEXT : IEquatable<VkValidationCacheEXT>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkAccelerationStructureKHR : IEquatable<VkAccelerationStructureKHR>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkAccelerationStructureNV : IEquatable<VkAccelerationStructureNV>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkPerformanceConfigurationINTEL : IEquatable<VkPerformanceConfigurationINTEL>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkBufferCollectionFUCHSIA : IEquatable<VkBufferCollectionFUCHSIA>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkDeferredOperationKHR : IEquatable<VkDeferredOperationKHR>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkPrivateDataSlot : IEquatable<VkPrivateDataSlot>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkPrivateDataSlotEXT : IEquatable<VkPrivateDataSlotEXT>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkCuModuleNVX : IEquatable<VkCuModuleNVX>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkCuFunctionNVX : IEquatable<VkCuFunctionNVX>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkOpticalFlowSessionNV : IEquatable<VkOpticalFlowSessionNV>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkMicromapEXT : IEquatable<VkMicromapEXT>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkShaderEXT : IEquatable<VkShaderEXT>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkTensorARM : IEquatable<VkTensorARM>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkTensorViewARM : IEquatable<VkTensorViewARM>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkDataGraphPipelineSessionARM : IEquatable<VkDataGraphPipelineSessionARM>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkShaderInstrumentationARM : IEquatable<VkShaderInstrumentationARM>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkDisplayKHR : IEquatable<VkDisplayKHR>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkDisplayModeKHR : IEquatable<VkDisplayModeKHR>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkSurfaceKHR : IEquatable<VkSurfaceKHR>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkSwapchainKHR : IEquatable<VkSwapchainKHR>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkDebugReportCallbackEXT : IEquatable<VkDebugReportCallbackEXT>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkDebugUtilsMessengerEXT : IEquatable<VkDebugUtilsMessengerEXT>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkVideoSessionKHR : IEquatable<VkVideoSessionKHR>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkVideoSessionParametersKHR : IEquatable<VkVideoSessionParametersKHR>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkSemaphoreSciSyncPoolNV : IEquatable<VkSemaphoreSciSyncPoolNV>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkCudaModuleNV : IEquatable<VkCudaModuleNV>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkCudaFunctionNV : IEquatable<VkCudaFunctionNV>, IHashable
{
	public readonly uint64 Handle;
	public this(uint64 existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (uint64)(int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(uint64 handle) => Self(handle);
	public static implicit operator uint64(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((uint64)(int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, uint64 right) => left.Handle == right;
	public static bool operator !=(Self left, uint64 right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

[CRepr]
public struct VkExternalComputeQueueNV : IEquatable<VkExternalComputeQueueNV>, IHashable
{
	public readonly int Handle;
	public this(int existingHandle) { Handle = existingHandle; }
	public this(void* existingHandle) { Handle = (int)existingHandle; }
	public static Self Null => Self(0);
	public static implicit operator Self(int handle) => Self(handle);
	public static implicit operator int(Self self) => self.Handle;
	public static implicit operator Self(void* handle) => Self((int)handle);
	public static implicit operator void*(Self self) => (void*)(int)self.Handle;
	public static bool operator ==(Self left, Self right) => left.Handle == right.Handle;
	public static bool operator !=(Self left, Self right) => left.Handle != right.Handle;
	public static bool operator ==(Self left, int right) => left.Handle == right;
	public static bool operator !=(Self left, int right) => left.Handle != right;
	public bool Equals(Self h) => Handle == h.Handle;

	public int GetHashCode() { return (.)Handle; }
}

