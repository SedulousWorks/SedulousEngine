using System;
using System.Collections;

namespace Sedulous.RHI.Validation;

/// The live objects of ONE kind that a device handed out.
///
/// Tracking is what turns two silent mistakes into reported ones: destroying something
/// twice, or through the wrong device, and letting a device go while it still owns things.
/// Both are invisible without a list of what is outstanding.
///
/// One of these per resource kind, so the leak report can name what leaked.
class TrackedResources
{
	private String mName = new .() ~ delete _;
	private List<Object> mLive = new .() ~ delete _;

	public this(StringView name) => mName.Set(name);

	public StringView Name => mName;
	public int Count => mLive.Count;

	public void Add(Object resource)
	{
		if (resource != null)
			mLive.Add(resource);
	}

	/// Removes it, reporting whether it was actually there. FALSE means a double destroy,
	/// or an object from another device.
	public bool Remove(Object resource)
	{
		for (int i < mLive.Count)
		{
			if (mLive[i] === resource)
			{
				mLive.RemoveAt(i);
				return true;
			}
		}
		return false;
	}

	public bool Contains(Object resource)
	{
		for (let live in mLive)
		{
			if (live === resource)
				return true;
		}
		return false;
	}
}
