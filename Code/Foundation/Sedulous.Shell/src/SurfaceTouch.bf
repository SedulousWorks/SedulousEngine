using Sedulous.Core;

namespace Sedulous.Shell;

/// The surface's touch: raw points transformed into NORMALISED content space, and only
/// those that land inside the surface.
///
/// Filtering as well as transforming, so the index a caller iterates is an index among the
/// touches on THIS surface. A point outside it is not reported at all rather than reported
/// with coordinates outside the range.
class SurfaceTouch : ITouch
{
	private InputSurface mSurface;

	public this(InputSurface surface) { mSurface = surface; }

	public int32 TouchCount
	{
		get
		{
			let raw = (mSurface.Raw != null) ? mSurface.Raw.Touch : null;
			if (raw == null)
				return 0;

			int32 count = 0;
			let total = raw.TouchCount;
			for (int32 i < total)
			{
				if (raw.GetTouchPoint(i, let point) && Transform(point, let _))
					count++;
			}
			return count;
		}
	}

	public bool GetTouchPoint(int32 index, out TouchPoint point)
	{
		point = default;

		let raw = (mSurface.Raw != null) ? mSurface.Raw.Touch : null;
		if ((raw == null) || (index < 0))
			return false;

		int32 seen = 0;
		let total = raw.TouchCount;
		for (int32 i < total)
		{
			if (!raw.GetTouchPoint(i, let candidate))
				continue;
			if (!Transform(candidate, let mapped))
				continue;

			if (seen == index)
			{
				point = mapped;
				return true;
			}
			seen++;
		}
		return false;
	}

	public bool HasTouch => TouchCount > 0;

	/// Raw normalised window coordinates to normalised content coordinates, or false when
	/// the point is outside the surface.
	private bool Transform(TouchPoint raw, out TouchPoint mapped)
	{
		mapped = default;

		let window = mSurface.WindowSize;
		let content = mSurface.Fit.ContentSize;
		// A zero sized window or content would divide by zero, and a surface that has not
		// been told its window size yet is the ordinary case at startup.
		if ((window.X <= 0.0f) || (window.Y <= 0.0f))
			return false;
		if ((content.X <= 0.0f) || (content.Y <= 0.0f))
			return false;

		// Touch arrives normalised to the window, so it is scaled up to window pixels
		// before the fit maps it, then back down to normalised content.
		if (!mSurface.Fit.ToContent(.(raw.X * window.X, raw.Y * window.Y), let inContent))
			return false;

		mapped = .(raw.Id, inContent.X / content.X, inContent.Y / content.Y, raw.Pressure);
		return true;
	}
}
