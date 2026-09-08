using System;
using System.Collections;
using Sedulous.Shell;

namespace Sedulous.Input.Tests;

/// A touch device a test moves fingers on by id.
class FakeTouch : ITouch
{
	private List<TouchPoint> mPoints = new .() ~ delete _;

	public int32 TouchCount => (int32)mPoints.Count;
	public bool HasTouch => !mPoints.IsEmpty;

	public bool GetTouchPoint(int32 index, out TouchPoint point)
	{
		point = .();
		if ((index < 0) || (index >= (int32)mPoints.Count))
			return false;
		point = mPoints[index];
		return true;
	}

	/// Moves the contact with this id, or starts it where it is put.
	public void Set(uint64 id, float x, float y)
	{
		for (int i = 0; i < mPoints.Count; i++)
		{
			if (mPoints[i].Id != id)
				continue;
			mPoints[i].X = x;
			mPoints[i].Y = y;
			return;
		}
		mPoints.Add(.(id, x, y));
	}

	public void Remove(uint64 id)
	{
		for (int i = 0; i < mPoints.Count; i++)
		{
			if (mPoints[i].Id == id)
			{
				mPoints.RemoveAt(i);
				return;
			}
		}
	}
}
