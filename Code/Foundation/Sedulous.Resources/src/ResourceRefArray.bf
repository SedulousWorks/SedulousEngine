namespace Sedulous.Resources;

using System;

/// Fixed-capacity array of ResourceRef values with a count.
/// TCapacity is the maximum number of refs (e.g., ResourceRefArray<8>).
/// The Path strings in each ResourceRef are owned — call Dispose() to free them.
[Reflect(.NonStaticFields)]
struct ResourceRefArray<TCapacity> : IDisposable where TCapacity : const int
{
	public int32 Count;
	public ResourceRef[TCapacity] Refs;

	public ref ResourceRef this[int index] { get mut => ref Refs[index]; }
	public ref ResourceRef this[int32 index] { get mut => ref Refs[(int)index]; }

	public void Add(ResourceRef @ref) mut
	{
		Runtime.Assert(Count < TCapacity);
		Refs[Count++] = @ref;
	}

	public void RemoveAt(int32 index) mut
	{
		Runtime.Assert(index >= 0 && index < Count);
		Refs[index].Dispose();
		// Shift remaining elements down
		for (int32 i = index; i < Count - 1; i++)
			Refs[i] = Refs[i + 1];
		Refs[Count - 1] = .();
		Count--;
	}

	public void Clear() mut
	{
		for (int32 i = 0; i < Count; i++)
			Refs[i].Dispose();
		Refs = .();
		Count = 0;
	}

	public void Dispose() mut
	{
		for (int32 i = 0; i < Count; i++)
			Refs[i].Dispose();
	}
}
