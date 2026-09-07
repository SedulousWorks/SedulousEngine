using System;
using System.Collections;
using Sedulous.Shell;

namespace Sedulous.Shell.SDL3;

/// The touch points currently down.
///
/// A list rather than a fixed set of slots, because a point's id is assigned by the driver
/// and is not an index: two fingers can carry ids that are far apart.
class SDL3Touch : ITouch
{
	private List<TouchPoint> mPoints = new .() ~ delete _;

	public int32 TouchCount => (int32)mPoints.Count;
	public bool HasTouch => !mPoints.IsEmpty;

	public bool GetTouchPoint(int32 index, out TouchPoint point)
	{
		if ((index < 0) || (index >= (int32)mPoints.Count))
		{
			point = .();
			return false;
		}
		point = mPoints[index];
		return true;
	}

	/// Updates in place when the id is already down, so a finger that moves stays ONE point
	/// rather than becoming a second one.
	public void AddOrUpdate(TouchPoint point)
	{
		for (int i < mPoints.Count)
		{
			if (mPoints[i].Id == point.Id)
			{
				mPoints[i] = point;
				return;
			}
		}
		mPoints.Add(point);
	}

	public void Remove(uint64 id)
	{
		for (int i = mPoints.Count - 1; i >= 0; i--)
		{
			if (mPoints[i].Id == id)
				mPoints.RemoveAt(i);
		}
	}
}
