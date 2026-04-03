using System;
using System.Collections;
using SDL3;
using Sedulous.Shell.Input;
using Sedulous.Core;

namespace Sedulous.Shell.SDL3;

/// SDL3 implementation of touch input.
class SDL3Touch : ITouch
{
	private List<TouchPoint> mTouchPoints = new .() ~ delete _;
	private bool mHasTouch;

	private EventAccessor<TouchEventDelegate> mOnTouchDown = new .() ~ delete _;
	private EventAccessor<TouchEventDelegate> mOnTouchUp = new .() ~ delete _;
	private EventAccessor<TouchEventDelegate> mOnTouchMove = new .() ~ delete _;

	public int TouchCount => mTouchPoints.Count;
	public bool HasTouch => mHasTouch;

	public EventAccessor<TouchEventDelegate> OnTouchDown => mOnTouchDown;
	public EventAccessor<TouchEventDelegate> OnTouchUp => mOnTouchUp;
	public EventAccessor<TouchEventDelegate> OnTouchMove => mOnTouchMove;

	public this()
	{
		// Check if touch devices are available
		int32 count = 0;
		let devices = SDL_GetTouchDevices(&count);
		mHasTouch = devices != null && count > 0;
	}

	public bool GetTouchPoint(int index, out TouchPoint point)
	{
		if (index >= 0 && index < mTouchPoints.Count)
		{
			point = mTouchPoints[index];
			return true;
		}
		point = ?;
		return false;
	}

	/// Handles an SDL touch finger down event.
	public void HandleFingerDown(SDL_TouchFingerEvent* e)
	{
		let point = TouchPoint(e.fingerID, e.x, e.y, e.pressure);
		mTouchPoints.Add(point);
		mOnTouchDown.[Friend]Invoke(point);
	}

	/// Handles an SDL touch finger up event.
	public void HandleFingerUp(SDL_TouchFingerEvent* e)
	{
		let point = TouchPoint(e.fingerID, e.x, e.y, e.pressure);

		// Remove the touch point
		for (int i = 0; i < mTouchPoints.Count; i++)
		{
			if (mTouchPoints[i].ID == e.fingerID)
			{
				mTouchPoints.RemoveAt(i);
				break;
			}
		}

		mOnTouchUp.[Friend]Invoke(point);
	}

	/// Handles an SDL touch finger motion event.
	public void HandleFingerMotion(SDL_TouchFingerEvent* e)
	{
		let point = TouchPoint(e.fingerID, e.x, e.y, e.pressure);

		// Update existing touch point
		for (int i = 0; i < mTouchPoints.Count; i++)
		{
			if (mTouchPoints[i].ID == e.fingerID)
			{
				mTouchPoints[i] = point;
				break;
			}
		}

		mOnTouchMove.[Friend]Invoke(point);
	}
}
