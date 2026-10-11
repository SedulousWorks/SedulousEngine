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

	/// A touchstart or touchmove: normalized over the canvas, and in the mouse's backing pixels.
	public void Upsert(TouchPoint point)
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
