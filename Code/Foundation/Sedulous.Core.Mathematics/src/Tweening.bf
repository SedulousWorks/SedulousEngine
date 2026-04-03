namespace Sedulous.Core.Mathematics;

/// <summary>
/// Contains methods for tweening values.
/// </summary>
static class Tweening
{
	/// <summary>
	/// Tweens the specified values.
	/// </summary>
	/// <param name="tweenStart">The start value.</param>
	/// <param name="tweenEnd">The end value.</param>
	/// <param name="fn">The easing function to apply.</param>
	/// <param name="t">A value between 0.0 and 1.0 indicating the current position in the tween.</param>
	/// <returns>A value which is interpolated from the specified start and end values.</returns>
	public static bool Tween(bool tweenStart, bool tweenEnd, EasingFunction fn, float t)
	{
	    return (fn ?? Easings.EaseInLinear)(t) < 1.0f ? tweenStart : tweenEnd;
	}

	/// <summary>
	/// Performs a linear interpolation between the specified values.
	/// </summary>
	/// <param name="lerpStart">The start value.</param>
	/// <param name="lerpEnd">The end value.</param>
	/// <param name="t">A value between 0.0 and 1.0 indicating the current position in the interpolation.</param>
	/// <returns>A value which is interpolated from the specified start and end values.</returns>
	public static bool Lerp(bool lerpStart, bool lerpEnd, float t)
	{
	    return t < 1.0f ? lerpStart : lerpEnd;
	}

	/// <summary>
	/// Tweens the specified values.
	/// </summary>
	/// <param name="tweenStart">The start value.</param>
	/// <param name="tweenEnd">The end value.</param>
	/// <param name="fn">The easing function to apply.</param>
	/// <param name="t">A value between 0.0 and 1.0 indicating the current position in the tween.</param>
	/// <returns>A value which is interpolated from the specified start and end values.</returns>
	public static uint8 Tween(uint8 tweenStart, uint8 tweenEnd, EasingFunction fn, float t)
	{
	    if (tweenEnd < tweenStart)
	    {
	        return Tween(tweenEnd, tweenStart, fn, 1f - t);
	    }
	    var delta = (tweenEnd - tweenStart);
	    return (uint8)(tweenStart + (delta * (fn ?? Easings.EaseInLinear)(t)));
	}

	/// <summary>
	/// Performs a linear interpolation between the specified values.
	/// </summary>
	/// <param name="lerpStart">The start value.</param>
	/// <param name="lerpEnd">The end value.</param>
	/// <param name="t">A value between 0.0 and 1.0 indicating the current position in the interpolation.</param>
	/// <returns>A value which is interpolated from the specified start and end values.</returns>
	public static uint8 Lerp(uint8 lerpStart, uint8 lerpEnd, float t)
	{
	    if (lerpEnd < lerpStart)
	    {
	        return Lerp(lerpEnd, lerpStart, 1f - t);
	    }
	    var delta = (lerpEnd - lerpStart);
	    return (uint8)(lerpStart + (delta * t));
	}

	/// <summary>
	/// Tweens the specified values.
	/// </summary>
	/// <param name="tweenStart">The start value.</param>
	/// <param name="tweenEnd">The end value.</param>
	/// <param name="fn">The easing function to apply.</param>
	/// <param name="t">A value between 0.0 and 1.0 indicating the current position in the tween.</param>
	/// <returns>A value which is interpolated from the specified start and end values.</returns>
	public static int8 Tween(int8 tweenStart, int8 tweenEnd, EasingFunction fn, float t)
	{
	    var delta = (tweenEnd - tweenStart);
	    return (int8)(tweenStart + (delta * (fn ?? Easings.EaseInLinear)(t)));
	}

	/// <summary>
	/// Performs a linear interpolation between the specified values.
	/// </summary>
	/// <param name="lerpStart">The start value.</param>
	/// <param name="lerpEnd">The end value.</param>
	/// <param name="t">A value between 0.0 and 1.0 indicating the current position in the interpolation.</param>
	/// <returns>A value which is interpolated from the specified start and end values.</returns>
	public static int8 Lerp(int8 lerpStart, int8 lerpEnd, float t)
	{
	    var delta = (lerpEnd - lerpStart);
	    return (int8)(lerpStart + (delta * t));
	}

	/// <summary>
	/// Tweens the specified values.
	/// </summary>
	/// <param name="tweenStart">The start value.</param>
	/// <param name="tweenEnd">The end value.</param>
	/// <param name="fn">The easing function to apply.</param>
	/// <param name="t">A value between 0.0 and 1.0 indicating the current position in the tween.</param>
	/// <returns>A value which is interpolated from the specified start and end values.</returns>
	public static char8 Tween(char8 tweenStart, char8 tweenEnd, EasingFunction fn, float t)
	{
	    if (tweenEnd < tweenStart)
	    {
	        return Tween(tweenEnd, tweenStart, fn, 1f - t);
	    }
	    var delta = (tweenEnd - tweenStart);
	    return (char8)((uint8)tweenStart + (delta * (fn ?? Easings.EaseInLinear)(t)));
	}

	/// <summary>
	/// Performs a linear interpolation between the specified values.
	/// </summary>
	/// <param name="lerpStart">The start value.</param>
	/// <param name="lerpEnd">The end value.</param>
	/// <param name="t">A value between 0.0 and 1.0 indicating the current position in the interpolation.</param>
	/// <returns>A value which is interpolated from the specified start and end values.</returns>
	public static char8 Lerp(char8 lerpStart, char8 lerpEnd, float t)
	{
	    if (lerpEnd < lerpStart)
	    {
	        return Lerp(lerpEnd, lerpStart, 1f - t);
	    }
	    var delta = (lerpEnd - lerpStart);
	    return (char8)((uint8)lerpStart + (delta * t));
	}

	/// <summary>
	/// Tweens the specified values.
	/// </summary>
	/// <param name="tweenStart">The start value.</param>
	/// <param name="tweenEnd">The end value.</param>
	/// <param name="fn">The easing function to apply.</param>
	/// <param name="t">A value between 0.0 and 1.0 indicating the current position in the tween.</param>
	/// <returns>A value which is interpolated from the specified start and end values.</returns>
	public static int16 Tween(int16 tweenStart, int16 tweenEnd, EasingFunction fn, float t)
	{
	    var delta = (tweenEnd - tweenStart);
	    return (int16)(tweenStart + (delta * (fn ?? Easings.EaseInLinear)(t)));
	}

	/// <summary>
	/// Performs a linear interpolation between the specified values.
	/// </summary>
	/// <param name="lerpStart">The start value.</param>
	/// <param name="lerpEnd">The end value.</param>
	/// <param name="t">A value between 0.0 and 1.0 indicating the current position in the interpolation.</param>
	/// <returns>A value which is interpolated from the specified start and end values.</returns>
	public static int16 Lerp(int16 lerpStart, int16 lerpEnd, float t)
	{
	    var delta = (lerpEnd - lerpStart);
	    return (int16)(lerpStart + (delta * t));
	}

	/// <summary>
	/// Tweens the specified values.
	/// </summary>
	/// <param name="tweenStart">The start value.</param>
	/// <param name="tweenEnd">The end value.</param>
	/// <param name="fn">The easing function to apply.</param>
	/// <param name="t">A value between 0.0 and 1.0 indicating the current position in the tween.</param>
	/// <returns>A value which is interpolated from the specified start and end values.</returns>
	public static uint16 Tween(uint16 tweenStart, uint16 tweenEnd, EasingFunction fn, float t)
	{
	    if (tweenEnd < tweenStart)
	    {
	        return Tween(tweenEnd, tweenStart, fn, 1f - t);
	    }
	    var delta = (tweenEnd - tweenStart);
	    return (uint16)(tweenStart + (delta * (fn ?? Easings.EaseInLinear)(t)));
	}

	/// <summary>
	/// Performs a linear interpolation between the specified values.
	/// </summary>
	/// <param name="lerpStart">The start value.</param>
	/// <param name="lerpEnd">The end value.</param>
	/// <param name="t">A value between 0.0 and 1.0 indicating the current position in the interpolation.</param>
	/// <returns>A value which is interpolated from the specified start and end values.</returns>
	public static uint16 Lerp(uint16 lerpStart, uint16 lerpEnd, float t)
	{
	    if (lerpEnd < lerpStart)
	    {
	        return Lerp(lerpEnd, lerpStart, 1f - t);
	    }
	    var delta = (lerpEnd - lerpStart);
	    return (uint16)(lerpStart + (delta * t));
	}

	/// <summary>
	/// Tweens the specified values.
	/// </summary>
	/// <param name="tweenStart">The start value.</param>
	/// <param name="tweenEnd">The end value.</param>
	/// <param name="fn">The easing function to apply.</param>
	/// <param name="t">A value between 0.0 and 1.0 indicating the current position in the tween.</param>
	/// <returns>A value which is interpolated from the specified start and end values.</returns>
	public static int32 Tween(int32 tweenStart, int32 tweenEnd, EasingFunction fn, float t)
	{
	    var delta = (tweenEnd - tweenStart);
	    return (int32)(tweenStart + (delta * (fn ?? Easings.EaseInLinear)(t)));
	}

	/// <summary>
	/// Performs a linear interpolation between the specified values.
	/// </summary>
	/// <param name="lerpStart">The start value.</param>
	/// <param name="lerpEnd">The end value.</param>
	/// <param name="t">A value between 0.0 and 1.0 indicating the current position in the interpolation.</param>
	/// <returns>A value which is interpolated from the specified start and end values.</returns>
	public static int32 Lerp(int32 lerpStart, int32 lerpEnd, float t)
	{
	    var delta = (lerpEnd - lerpStart);
	    return (int32)(lerpStart + (delta * t));
	}

	/// <summary>
	/// Tweens the specified values.
	/// </summary>
	/// <param name="tweenStart">The start value.</param>
	/// <param name="tweenEnd">The end value.</param>
	/// <param name="fn">The easing function to apply.</param>
	/// <param name="t">A value between 0.0 and 1.0 indicating the current position in the tween.</param>
	/// <returns>A value which is interpolated from the specified start and end values.</returns>
	public static uint32 Tween(uint32 tweenStart, uint32 tweenEnd, EasingFunction fn, float t)
	{
	    if (tweenEnd < tweenStart)
	    {
	        return Tween(tweenEnd, tweenStart, fn, 1f - t);
	    }
	    var delta = (tweenEnd - tweenStart);
	    return (uint32)(tweenStart + (delta * (fn ?? Easings.EaseInLinear)(t)));
	}

	/// <summary>
	/// Performs a linear interpolation between the specified values.
	/// </summary>
	/// <param name="lerpStart">The start value.</param>
	/// <param name="lerpEnd">The end value.</param>
	/// <param name="t">A value between 0.0 and 1.0 indicating the current position in the interpolation.</param>
	/// <returns>A value which is interpolated from the specified start and end values.</returns>
	public static uint32 Lerp(uint32 lerpStart, uint32 lerpEnd, float t)
	{
	    if (lerpEnd < lerpStart)
	    {
	        return Lerp(lerpEnd, lerpStart, 1f - t);
	    }
	    var delta = (lerpEnd - lerpStart);
	    return (uint32)(lerpStart + (delta * t));
	}

	/// <summary>
	/// Tweens the specified values.
	/// </summary>
	/// <param name="tweenStart">The start value.</param>
	/// <param name="tweenEnd">The end value.</param>
	/// <param name="fn">The easing function to apply.</param>
	/// <param name="t">A value between 0.0 and 1.0 indicating the current position in the tween.</param>
	/// <returns>A value which is interpolated from the specified start and end values.</returns>
	public static int64 Tween(int64 tweenStart, int64 tweenEnd, EasingFunction fn, float t)
	{
	    var delta = (tweenEnd - tweenStart);
	    return (int64)(tweenStart + (delta * (fn ?? Easings.EaseInLinear)(t)));
	}

	/// <summary>
	/// Performs a linear interpolation between the specified values.
	/// </summary>
	/// <param name="lerpStart">The start value.</param>
	/// <param name="lerpEnd">The end value.</param>
	/// <param name="t">A value between 0.0 and 1.0 indicating the current position in the interpolation.</param>
	/// <returns>A value which is interpolated from the specified start and end values.</returns>
	public static int64 Lerp(int64 lerpStart, int64 lerpEnd, float t)
	{
	    var delta = (lerpEnd - lerpStart);
	    return (int64)(lerpStart + (delta * t));
	}

	/// <summary>
	/// Tweens the specified values.
	/// </summary>
	/// <param name="tweenStart">The start value.</param>
	/// <param name="tweenEnd">The end value.</param>
	/// <param name="fn">The easing function to apply.</param>
	/// <param name="t">A value between 0.0 and 1.0 indicating the current position in the tween.</param>
	/// <returns>A value which is interpolated from the specified start and end values.</returns>
	public static uint64 Tween(uint64 tweenStart, uint64 tweenEnd, EasingFunction fn, float t)
	{
	    if (tweenEnd < tweenStart)
	    {
	        return Tween(tweenEnd, tweenStart, fn, t);
	    }
	    var delta = (tweenEnd - tweenStart);
	    return (uint64)(tweenStart + (delta * (fn ?? Easings.EaseInLinear)(t)));
	}

	/// <summary>
	/// Performs a linear interpolation between the specified values.
	/// </summary>
	/// <param name="lerpStart">The start value.</param>
	/// <param name="lerpEnd">The end value.</param>
	/// <param name="t">A value between 0.0 and 1.0 indicating the current position in the interpolation.</param>
	/// <returns>A value which is interpolated from the specified start and end values.</returns>
	public static uint64 Lerp(uint64 lerpStart, uint64 lerpEnd, float t)
	{
	    if (lerpEnd < lerpStart)
	    {
	        return Lerp(lerpEnd, lerpStart, 1f - t);
	    }
	    var delta = (lerpEnd - lerpStart);
	    return (uint64)(lerpStart + (delta * t));
	}

	/// <summary>
	/// Tweens the specified values.
	/// </summary>
	/// <param name="tweenStart">The start value.</param>
	/// <param name="tweenEnd">The end value.</param>
	/// <param name="fn">The easing function to apply.</param>
	/// <param name="t">A value between 0.0 and 1.0 indicating the current position in the tween.</param>
	/// <returns>A value which is interpolated from the specified start and end values.</returns>
	public static float Tween(float tweenStart, float tweenEnd, EasingFunction fn, float t)
	{
	    var delta = (tweenEnd - tweenStart);
	    return tweenStart + (delta * (fn ?? Easings.EaseInLinear)(t));
	}

	/// <summary>
	/// Performs a linear interpolation between the specified values.
	/// </summary>
	/// <param name="lerpStart">The start value.</param>
	/// <param name="lerpEnd">The end value.</param>
	/// <param name="t">A value between 0.0 and 1.0 indicating the current position in the interpolation.</param>
	/// <returns>A value which is interpolated from the specified start and end values.</returns>
	public static float Lerp(float lerpStart, float lerpEnd, float t)
	{
	    var delta = (lerpEnd - lerpStart);
	    return lerpStart + (delta * t);
	}

	/// <summary>
	/// Tweens the specified values.
	/// </summary>
	/// <param name="tweenStart">The start value.</param>
	/// <param name="tweenEnd">The end value.</param>
	/// <param name="fn">The easing function to apply.</param>
	/// <param name="t">A value between 0.0 and 1.0 indicating the current position in the tween.</param>
	/// <returns>A value which is interpolated from the specified start and end values.</returns>
	public static double Tween(double tweenStart, double tweenEnd, EasingFunction fn, float t)
	{
	    var delta = (tweenEnd - tweenStart);
	    return tweenStart + (delta * (fn ?? Easings.EaseInLinear)(t));
	}

	/// <summary>
	/// Performs a linear interpolation between the specified values.
	/// </summary>
	/// <param name="lerpStart">The start value.</param>
	/// <param name="lerpEnd">The end value.</param>
	/// <param name="t">A value between 0.0 and 1.0 indicating the current position in the interpolation.</param>
	/// <returns>A value which is interpolated from the specified start and end values.</returns>
	public static double Lerp(double lerpStart, double lerpEnd, float t)
	{
	    var delta = (lerpEnd - lerpStart);
	    return lerpStart + (delta * t);
	}
}