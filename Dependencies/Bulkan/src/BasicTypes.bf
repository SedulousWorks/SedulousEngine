using System;
namespace Bulkan;

[CRepr] struct VkDeviceSize : uint64
{
	public static T operator implicit<T>(Self self)
		where T : operator implicit uint64
	{
		return (.)(uint64)self;
	}
}

[CRepr] struct VkDeviceAddress : uint64
{
	public static T operator implicit<T>(Self self)
		where T : operator implicit uint64
	{
		return (.)(uint64)self;
	}

	public static Self operator implicit<T>(T value)
	{
		return (.)value;
	}
}

[CRepr] struct VkSampleMask : uint32
{
	public static T operator implicit<T>(Self self)
		where T : operator implicit uint32
	{
		return (.)(uint32)self;
	}

	public static Self operator implicit<T>(T value)
	{
		return (.)value;
	}
}

[CRepr] struct VkFlags : uint32
{
	public static T operator implicit<T>(Self self)
		where T : operator implicit uint32
	{
		return (.)(uint32)self;
	}
}

[CRepr] struct VkFlags64 : uint64
{
	public static T operator implicit<T>(Self self)
		where T : operator implicit uint64
	{
		return (.)(uint64)self;
	}
}

[CRepr] struct VkBufferViewCreateFlags : VkFlags { }
