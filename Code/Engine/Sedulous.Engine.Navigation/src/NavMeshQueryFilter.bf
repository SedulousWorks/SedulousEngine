namespace Sedulous.Engine.Navigation;

using System;
using recastnavigation_Beef;

/// Wrapper for Detour query filter.
class NavMeshQueryFilter
{
	private dtQueryFilterHandle mHandle;
	private bool mOwnsHandle;

	/// Creates a new query filter with default settings.
	public this()
	{
		mHandle = dtAllocQueryFilter();
		mOwnsHandle = true;
	}

	/// Creates a wrapper around an existing handle.
	public this(dtQueryFilterHandle handle, bool ownsHandle = false)
	{
		mHandle = handle;
		mOwnsHandle = ownsHandle;
	}

	public ~this()
	{
		if (mOwnsHandle && mHandle != null)
		{
			dtFreeQueryFilter(mHandle);
			mHandle = null;
		}
	}

	/// Gets the underlying handle.
	public dtQueryFilterHandle Handle => mHandle;

	/// Gets the area cost for a specific area.
	public float GetAreaCost(int32 areaIndex)
	{
		if (mHandle == null)
			return 1.0f;
		return dtQueryFilterGetAreaCost(mHandle, areaIndex);
	}

	/// Sets the area cost for a specific area.
	public void SetAreaCost(int32 areaIndex, float cost)
	{
		if (mHandle != null)
			dtQueryFilterSetAreaCost(mHandle, areaIndex, cost);
	}

	/// Gets the include flags.
	public uint16 IncludeFlags
	{
		get
		{
			if (mHandle == null)
				return 0xFFFF;
			return dtQueryFilterGetIncludeFlags(mHandle);
		}
		set
		{
			if (mHandle != null)
				dtQueryFilterSetIncludeFlags(mHandle, value);
		}
	}

	/// Gets the exclude flags.
	public uint16 ExcludeFlags
	{
		get
		{
			if (mHandle == null)
				return 0;
			return dtQueryFilterGetExcludeFlags(mHandle);
		}
		set
		{
			if (mHandle != null)
				dtQueryFilterSetExcludeFlags(mHandle, value);
		}
	}
}
