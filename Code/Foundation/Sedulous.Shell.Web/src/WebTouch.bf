using System;
using System.Collections;
using Sedulous.Shell;

namespace Sedulous.Shell.Web;

/// The live fingers, keyed by the browser's touch identifier.
///
/// The identifier is what follows one contact from down to up, so a gesture survives other
/// fingers arriving and leaving mid way. Points are held rather than rebuilt each frame
/// because a touchmove carries only the fingers that moved.
class WebTouch : ITouch
{
	private List<TouchPoint> mPoints = new .() ~ delete _;

	public int32 TouchCount => (int32)mPoints.Count;
	public bool HasTouch => !mPoints.IsEmpty;

	public bool GetTouchPoint(int32 index, out TouchPoint point)
	{
		if ((index < 0) || (index >= (int32)mPoints.Count))
		{
			point = default;
			return false;
		}
		point = mPoints[index];
		return true;
	}

	public void Upsert(uint64 id, float x, float y)
	{
		for (int i < mPoints.Count)
		{
			if (mPoints[i].Id == id)
			{
				var existing = mPoints[i];
				existing.X = x;
				existing.Y = y;
				mPoints[i] = existing;
				return;
			}
		}
		mPoints.Add(.(id, x, y));
	}

	public void Remove(uint64 id)
	{
		for (int i < mPoints.Count)
		{
			if (mPoints[i].Id == id)
			{
				mPoints.RemoveAt(i);
				return;
			}
		}
	}

	public void Clear() => mPoints.Clear();
}
