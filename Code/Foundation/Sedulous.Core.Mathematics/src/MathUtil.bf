using System;
namespace Sedulous.Core.Mathematics;

/// <summary>
/// Contains useful mathematical functions.
/// </summary>
public static class MathUtil
{
    /// <summary>
    /// Gets a value indicating whether the specified <see cref="float"/> value is zero to within a reasonable approximation.
    /// </summary>
    /// <param name="value">The value to evaluate.</param>
    /// <returns><see langword="true"/> if the specified value is zero or approximately zero; otherwise, <see langword="false"/>.</returns>
    public static bool IsApproximatelyZero(float value)
    {
        return Math.Abs(value) < 1E-7;
    }

    /// <summary>
    /// Gets a value indicating whether the specified <see cref="float"/> value is non-zero to within a reasonable approximation.
    /// </summary>
    /// <param name="value">The value to evaluate.</param>
    /// <returns><see langword="true"/> if the specified value is non-zero; otherwise, <see langword="false"/>.</returns>
    public static bool IsApproximatelyNonZero(float value)
    {
        return Math.Abs(value) >= 1E-7;
    }

    /// <summary>
    /// Gets a value indicating whether <paramref name="value1"/> is greater than <paramref name="value2"/> to within a reasonable approximation.
    /// </summary>
    /// <param name="value1">The first value to evaluate.</param>
    /// <param name="value2">The second value to evaluate.</param>
    /// <returns><see langword="true"/> if <paramref name="value1"/> is greater than <paramref name="value2"/>; otherwise, <see langword="false"/>.</returns>
    public static bool IsApproximatelyGreaterThan(float value1, float value2)
    {
        if (value1 == value2)
            return true;

        return Math.Abs(value1 - value2) >= 1E-7 && value1 > value2;
    }

    /// <summary>
    /// Gets a value indicating whether <paramref name="value1"/> is greater than or equal to <paramref name="value2"/> to within a reasonable approximation.
    /// </summary>
    /// <param name="value1">The first value to evaluate.</param>
    /// <param name="value2">The second value to evaluate.</param>
    /// <returns><see langword="true"/> if <paramref name="value1"/> is greater than or equal to <paramref name="value2"/>; otherwise, <see langword="false"/>.</returns>
    public static bool IsApproximatelyGreaterThanOrEqual(float value1, float value2)
    {
        if (value1 == value2)
            return true;

        return Math.Abs(value1 - value2) < 1E-7 || value1 > value2;
    }

    /// <summary>
    /// Gets a value indicating whether <paramref name="value1"/> is less than <paramref name="value2"/> to within a reasonable approximation.
    /// </summary>
    /// <param name="value1">The first value to evaluate.</param>
    /// <param name="value2">The second value to evaluate.</param>
    /// <returns><see langword="true"/> if <paramref name="value1"/> is less than <paramref name="value2"/>; otherwise, <see langword="false"/>.</returns>
    public static bool IsApproximatelyLessThan(float value1, float value2)
    {
        if (value1 == value2)
            return false;

        return Math.Abs(value1 - value2) >= 1E-7 && value1 < value2;
    }

    /// <summary>
    /// Gets a value indicating whether <paramref name="value1"/> is less than or equal to <paramref name="value2"/> to within a reasonable approximation.
    /// </summary>
    /// <param name="value1">The first value to evaluate.</param>
    /// <param name="value2">The second value to evaluate.</param>
    /// <returns><see langword="true"/> if <paramref name="value1"/> is less than or equal to <paramref name="value2"/>; otherwise, <see langword="false"/>.</returns>
    public static bool IsApproximatelyLessThanOrEqualTo(float value1, float value2)
    {
        if (value1 == value2)
            return true;

        return Math.Abs(value1 - value2) < 1E-7 || value1 < value2;
    }

    /// <summary>
    /// Gets a value indicating whether <paramref name="value1"/> is equal to <paramref name="value2"/> to within a reasonable approximation.
    /// </summary>
    /// <param name="value1">The first value to evaluate.</param>
    /// <param name="value2">The second value to evaluate.</param>
    /// <returns><see langword="true"/> if <paramref name="value1"/> is equal to <paramref name="value2"/>; otherwise, <see langword="false"/>.</returns>
    public static bool AreApproximatelyEqual(float value1, float value2)
    {
        if (value1 == value2)
            return true;

        return Math.Abs(value1 - value2) < 1E-7;
    }

    /// <summary>
    /// Gets a value indicating whether the specified <see cref="double"/> value is zero to within a reasonable approximation.
    /// </summary>
    /// <param name="value">The value to evaluate.</param>
    /// <returns><see langword="true"/> if the specified value is zero or approximately zero; otherwise, <see langword="false"/>.</returns>
    public static bool IsApproximatelyZero(double value)
    {
        return Math.Abs(value) < 1E-15;
    }

    /// <summary>
    /// Gets a value indicating whether the specified <see cref="double"/> value is non-zero to within a reasonable approximation.
    /// </summary>
    /// <param name="value">The value to evaluate.</param>
    /// <returns><see langword="true"/> if the specified value is non-zero; otherwise, <see langword="false"/>.</returns>
    public static bool IsApproximatelyNonZero(double value)
    {
        return Math.Abs(value) >= 1E-15;
    }

    /// <summary>
    /// Gets a value indicating whether <paramref name="value1"/> is greater than <paramref name="value2"/> to within a reasonable approximation.
    /// </summary>
    /// <param name="value1">The first value to evaluate.</param>
    /// <param name="value2">The second value to evaluate.</param>
    /// <returns><see langword="true"/> if <paramref name="value1"/> is greater than <paramref name="value2"/>; otherwise, <see langword="false"/>.</returns>
    public static bool IsApproximatelyGreaterThan(double value1, double value2)
    {
        if (value1 == value2)
            return false;

        return Math.Abs(value1 - value2) >= 1E-15 && value1 > value2;
    }

    /// <summary>
    /// Gets a value indicating whether <paramref name="value1"/> is greater than or equal to <paramref name="value2"/> to within a reasonable approximation.
    /// </summary>
    /// <param name="value1">The first value to evaluate.</param>
    /// <param name="value2">The second value to evaluate.</param>
    /// <returns><see langword="true"/> if <paramref name="value1"/> is greater than or equal to <paramref name="value2"/>; otherwise, <see langword="false"/>.</returns>
    public static bool IsApproximatelyGreaterThanOrEqual(double value1, double value2)
    {
        if (value1 == value2)
            return true;

        return Math.Abs(value1 - value2) < 1E-15 || value1 > value2;
    }

    /// <summary>
    /// Gets a value indicating whether <paramref name="value1"/> is less than <paramref name="value2"/> to within a reasonable approximation.
    /// </summary>
    /// <param name="value1">The first value to evaluate.</param>
    /// <param name="value2">The second value to evaluate.</param>
    /// <returns><see langword="true"/> if <paramref name="value1"/> is less than <paramref name="value2"/>; otherwise, <see langword="false"/>.</returns>
    public static bool IsApproximatelyLessThan(double value1, double value2)
    {
        if (value1 == value2)
            return true;

        return Math.Abs(value1 - value2) >= 1E-15 && value1 < value2;
    }

    /// <summary>
    /// Gets a value indicating whether <paramref name="value1"/> is less than or equal to <paramref name="value2"/> to within a reasonable approximation.
    /// </summary>
    /// <param name="value1">The first value to evaluate.</param>
    /// <param name="value2">The second value to evaluate.</param>
    /// <returns><see langword="true"/> if <paramref name="value1"/> is less than or equal to <paramref name="value2"/>; otherwise, <see langword="false"/>.</returns>
    public static bool IsApproximatelyLessThanOrEqualTo(double value1, double value2)
    {
        if (value1 == value2)
            return true;

        return Math.Abs(value1 - value2) < 1E-15 || value1 < value2;
    }

    /// <summary>
    /// Gets a value indicating whether <paramref name="value1"/> is equal to <paramref name="value2"/> to within a reasonable approximation.
    /// </summary>
    /// <param name="value1">The first value to evaluate.</param>
    /// <param name="value2">The second value to evaluate.</param>
    /// <returns><see langword="true"/> if <paramref name="value1"/> is equal to <paramref name="value2"/>; otherwise, <see langword="false"/>.</returns>
    public static bool AreApproximatelyEqual(double value1, double value2)
    {
        if (value1 == value2)
            return true;
        
        return Math.Abs(value1 - value2) < 1E-15;
    }        

    /// <summary>
    /// Finds the next power of two that is higher than the specified value.
    /// </summary>
    /// <param name="k">The value to evaluate.</param>
    /// <returns>The next power of two that is higher than the specified value.</returns>
    public static int32 FindNextPowerOfTwo(int32 k)
    {
		var k;
        k--;
        for (int i = 1; i < sizeof(int) * 8; i <<= 1)
        {
            k = k | k >> i;
        }
        return k + 1;
    }

    /// <summary>
    /// Clamps a value to the specified range.
    /// </summary>
    /// <param name="value">The value to clamp.</param>
    /// <param name="min">The minimum possible value.</param>
    /// <param name="max">The maximum possible value.</param>
    /// <returns>The clamped value.</returns>
    public static uint8 Clamp(uint8 value, uint8 min, uint8 max)
    {
        return (value > max) ? max : (value < min) ? min : value;
    }

    /// <summary>
    /// Clamps a value to the specified range.
    /// </summary>
    /// <param name="value">The value to clamp.</param>
    /// <param name="min">The minimum possible value.</param>
    /// <param name="max">The maximum possible value.</param>
    /// <returns>The clamped value.</returns>
    public static int16 Clamp(int16 value, int16 min, int16 max)
    {
        return (value > max) ? max : (value < min) ? min : value;
    }

    /// <summary>
    /// Clamps a value to the specified range.
    /// </summary>
    /// <param name="value">The value to clamp.</param>
    /// <param name="min">The minimum possible value.</param>
    /// <param name="max">The maximum possible value.</param>
    /// <returns>The clamped value.</returns>
    public static int32 Clamp(int32 value, int32 min, int32 max)
    {
        return (value > max) ? max : (value < min) ? min : value;
    }

    /// <summary>
    /// Clamps a value to the specified range.
    /// </summary>
    /// <param name="value">The value to clamp.</param>
    /// <param name="min">The minimum possible value.</param>
    /// <param name="max">The maximum possible value.</param>
    /// <returns>The clamped value.</returns>
    public static int64 Clamp(int64 value, int64 min, int64 max)
    {
        return (value > max) ? max : (value < min) ? min : value;
    }

    /// <summary>
    /// Clamps a value to the specified range.
    /// </summary>
    /// <param name="value">The value to clamp.</param>
    /// <param name="min">The minimum possible value.</param>
    /// <param name="max">The maximum possible value.</param>
    /// <returns>The clamped value.</returns>
    public static uint16 Clamp(uint16 value, uint16 min, uint16 max)
    {
        return (value > max) ? max : (value < min) ? min : value;
    }

    /// <summary>
    /// Clamps a value to the specified range.
    /// </summary>
    /// <param name="value">The value to clamp.</param>
    /// <param name="min">The minimum possible value.</param>
    /// <param name="max">The maximum possible value.</param>
    /// <returns>The clamped value.</returns>
    public static uint32 Clamp(uint32 value, uint32 min, uint32 max)
    {
        return (value > max) ? max : (value < min) ? min : value;
    }

    /// <summary>
    /// Clamps a value to the specified range.
    /// </summary>
    /// <param name="value">The value to clamp.</param>
    /// <param name="min">The minimum possible value.</param>
    /// <param name="max">The maximum possible value.</param>
    /// <returns>The clamped value.</returns>
    public static uint64 Clamp(uint64 value, uint64 min, uint64 max)
    {
        return (value > max) ? max : (value < min) ? min : value;
    }

    /// <summary>
    /// Clamps a value to the specified range.
    /// </summary>
    /// <param name="value">The value to clamp.</param>
    /// <param name="min">The minimum possible value.</param>
    /// <param name="max">The maximum possible value.</param>
    /// <returns>The clamped value.</returns>
    public static float Clamp(float value, float min, float max)
    {
        return (value > max) ? max : (value < min) ? min : value;
    }

    /// <summary>
    /// Clamps a value to the specified range.
    /// </summary>
    /// <param name="value">The value to clamp.</param>
    /// <param name="min">The minimum possible value.</param>
    /// <param name="max">The maximum possible value.</param>
    /// <returns>The clamped value.</returns>
    public static double Clamp(double value, double min, double max)
    {
        return (value > max) ? max : (value < min) ? min : value;
    }

    /// <summary>
    /// Linearly interpolates between two values.
    /// </summary>
    /// <param name="value1">Source value.</param>
    /// <param name="value2">Source value.</param>
    /// <param name="amount">Value between 0 and 1 indicating the weight of value2.</param>
    /// <returns>Interpolated value.</returns>
    public static uint8 Lerp(uint8 value1, uint8 value2, float amount)
    {
        return (uint8)(value1 + ((value2 - value1) * amount));
    }

    /// <summary>
    /// Linearly interpolates between two values.
    /// </summary>
    /// <param name="value1">Source value.</param>
    /// <param name="value2">Source value.</param>
    /// <param name="amount">Value between 0 and 1 indicating the weight of value2.</param>
    /// <returns>Interpolated value.</returns>
    public static int16 Lerp(int16 value1, int16 value2, float amount)
    {
        return (int16)(value1 + ((value2 - value1) * amount));
    }

    /// <summary>
    /// Linearly interpolates between two values.
    /// </summary>
    /// <param name="value1">Source value.</param>
    /// <param name="value2">Source value.</param>
    /// <param name="amount">Value between 0 and 1 indicating the weight of value2.</param>
    /// <returns>Interpolated value.</returns>
    public static int32 Lerp(int32 value1, int32 value2, float amount)
    {
        return (int32)(value1 + ((value2 - value1) * amount));
    }

    /// <summary>
    /// Linearly interpolates between two values.
    /// </summary>
    /// <param name="value1">Source value.</param>
    /// <param name="value2">Source value.</param>
    /// <param name="amount">Value between 0 and 1 indicating the weight of value2.</param>
    /// <returns>Interpolated value.</returns>
    public static int64 Lerp(int64 value1, int64 value2, float amount)
    {
        return (int64)(value1 + ((value2 - value1) * amount));
    }

    /// <summary>
    /// Linearly interpolates between two values.
    /// </summary>
    /// <param name="value1">Source value.</param>
    /// <param name="value2">Source value.</param>
    /// <param name="amount">Value between 0 and 1 indicating the weight of value2.</param>
    /// <returns>Interpolated value.</returns>
    public static uint16 Lerp(uint16 value1, uint16 value2, float amount)
    {
        return (uint16)(value1 + ((value2 - value1) * amount));
    }

    /// <summary>
    /// Linearly interpolates between two values.
    /// </summary>
    /// <param name="value1">Source value.</param>
    /// <param name="value2">Source value.</param>
    /// <param name="amount">Value between 0 and 1 indicating the weight of value2.</param>
    /// <returns>Interpolated value.</returns>
    public static uint32 Lerp(uint32 value1, uint32 value2, float amount)
    {
        return (uint32)(value1 + ((value2 - value1) * amount));
    }

    /// <summary>
    /// Linearly interpolates between two values.
    /// </summary>
    /// <param name="value1">Source value.</param>
    /// <param name="value2">Source value.</param>
    /// <param name="amount">Value between 0 and 1 indicating the weight of value2.</param>
    /// <returns>Interpolated value.</returns>
    public static uint64 Lerp(uint64 value1, uint64 value2, float amount)
    {
        return (uint64)(value1 + ((value2 - value1) * amount));
    }

    /// <summary>
    /// Linearly interpolates between two values.
    /// </summary>
    /// <param name="value1">Source value.</param>
    /// <param name="value2">Source value.</param>
    /// <param name="amount">Value between 0 and 1 indicating the weight of value2.</param>
    /// <returns>Interpolated value.</returns>
    public static float Lerp(float value1, float value2, float amount)
    {
        return value1 + ((value2 - value1) * amount);
    }

    /// <summary>
    /// Linearly interpolates between two values.
    /// </summary>
    /// <param name="value1">Source value.</param>
    /// <param name="value2">Source value.</param>
    /// <param name="amount">Value between 0 and 1 indicating the weight of value2.</param>
    /// <returns>Interpolated value.</returns>
    public static double Lerp(double value1, double value2, float amount)
    {
        return value1 + ((value2 - value1) * amount);
    }


	//-----------------------------------------------------------------------------//

	private const double OneRadianInDegrees = 57.2957795131;

	private const double OneDegreeInRadians = 0.01745329252;

	/// <summary>
	/// Represents the mathematical constant e.
	/// </summary>
	public const float E = (float)Math.E_f;

	/// <summary>
	/// Represents the log base ten of e.
	/// </summary>
	public const float Log10E = 0.4342945f;

	/// <summary>
	/// Represents the log base two of e.
	/// </summary>
	public const float Log2E = 1.442695f;

	/// <summary>
	/// Represents the value of pi.
	/// </summary>
	public const float Pi = (float)Math.PI_f;

	/// <summary>
	/// Represents the value of pi divided by two.
	/// </summary>
	public const float PiOver2 = (float)Math.PI_f / 2f;

	/// <summary>
	/// Represents the value of pi divided by four.
	/// </summary>
	public const float PiOver4 = (float)Math.PI_f / 4f;

	/// <summary>
	/// Represents the value of pi times two.
	/// </summary>
	public const float TwoPi = (float)Math.PI_f * 2f;

	/// <summary>
	/// The epsilon.
	/// </summary>
	public const float Epsilon = 1.1920929E-07f;

	/// <summary>
	/// Return the next power of two value of the specified argument.
	/// </summary>
	/// <param name="v">The value.</param>
	/// <returns>The next power of two.</returns>
	[Inline]
	public static int32 NextPowerOfTwo(int32 v)
	{
		var v;
		v--;
		v |= v >> 1;
		v |= v >> 2;
		v |= v >> 4;
		v |= v >> 8;
		v |= v >> 16;
		v++;
		return v;
	}

	/// <summary>
	/// Return the next power of two value of the specified argument.
	/// </summary>
	/// <param name="v">The value.</param>
	/// <returns>The next power of two.</returns>
	[Inline]
	public static uint64 NextPowerOfTwo(uint64 v)
	{
		var v;
		v--;
		v |= v >> 1;
		v |= v >> 2;
		v |= v >> 4;
		v |= v >> 8;
		v |= v >> 16;
		v++;
		return v;
	}

	/// <summary>
	/// Returns the Cartesian coordinate for one axis of a point that is defined by a given triangle and two normalized barycentric (areal) coordinates.
	/// </summary>
	/// <param name="value1">The coordinate on one axis of vertex 1 of the defining triangle.</param>
	/// <param name="value2">The coordinate on the same axis of vertex 2 of the defining triangle.</param>
	/// <param name="value3">The coordinate on the same axis of vertex 3 of the defining triangle.</param>
	/// <param name="amount1">The normalized barycentric (areal) coordinate b2, equal to the weighting factor for vertex 2, the coordinate of which is specified in value2.</param>
	/// <param name="amount2">The normalized barycentric (areal) coordinate b3, equal to the weighting factor for vertex 3, the coordinate of which is specified in value3.</param>
	/// <returns>Cartesian coordinate of the specified point with respect to the axis being used.</returns>
	[Inline]
	public static float Barycentric(float value1, float value2, float value3, float amount1, float amount2)
	{
		return value1 + amount1 * (value2 - value1) + amount2 * (value3 - value1);
	}

	/// <summary>
	/// Performs a Catmull-Rom interpolation using the specified positions.
	/// </summary>
	/// <param name="value1">The first position in the interpolation.</param>
	/// <param name="value2">The second position in the interpolation.</param>
	/// <param name="value3">The third position in the interpolation.</param>
	/// <param name="value4">The fourth position in the interpolation.</param>
	/// <param name="amount">Weighting factor.</param>
	/// <returns>A position that is the result of the Catmull-Rom interpolation.</returns>
	[Inline]
	public static float CatmullRom(float value1, float value2, float value3, float value4, float amount)
	{
		float num = amount * amount;
		float num2 = amount * num;
		return 0.5f * (2f * value2 + (0f - value1 + value3) * amount + (2f * value1 - 5f * value2 + 4f * value3 - value4) * num + (0f - value1 + 3f * value2 - 3f * value3 + value4) * num2);
	}

	/*/// <summary>
	/// Clamps a value between a minimum float and maximum float value.
	/// </summary>
	/// <param name="value">The value.</param>
	/// <param name="min">The minimum value. If value is less than min, min will be returned.</param>
	/// <param name="max">The maximum value. If value is greater than max, max will be returned.</param>
	/// <returns>The clamped value.</returns>
	[Inline]
	public static float Clamp(float value, float min, float max)
	{
		var value;
		value = ((value > max) ? max : value);
		value = ((value < min) ? min : value);
		return value;
	}*/

	/// <summary>
	/// Calculates the absolute value of the difference of two values.
	/// </summary>
	/// <param name="value1">Source value1.</param>
	/// <param name="value2">Source value2.</param>
	/// <returns>Distance between the two values.</returns>
	[Inline]
	public static float Distance(float value1, float value2)
	{
		return Math.Abs(value1 - value2);
	}

	/// <summary>
	/// Performs a Hermite spline interpolation.
	/// </summary>
	/// <param name="value1">Source value1.</param>
	/// <param name="tangent1">Source tangent1.</param>
	/// <param name="value2">Source value2.</param>
	/// <param name="tangent2">Source tangent2.</param>
	/// <param name="amount">Weighting factor.</param>
	/// <returns>The result of the Hermite spline interpolation.</returns>
	[Inline]
	public static float Hermite(float value1, float tangent1, float value2, float tangent2, float amount)
	{
		float num = amount * amount;
		float num2 = amount * num;
		float num7 = 2f * num2 - 3f * num + 1f;
		float num6 = -2f * num2 + 3f * num;
		float num5 = num2 - 2f * num + amount;
		float num4 = num2 - num;
		return value1 * num7 + value2 * num6 + tangent1 * num5 + tangent2 * num4;
	}

	/// <summary>
	/// Linearly interpolates between value1 and value2 by amount.
	/// The parameter amount is not clamped and values outside the range [0, 1] will result in a return value outside the range [value1, value2].
	/// Returns a positive number if c is to the left of the line going from a to b.
	/// </summary>
	/// <param name="a">The first vector.</param>
	/// <param name="b">The second vector.</param>
	/// <param name="c">The third vector.</param>
	/// <returns>Positive number if point is left, negative if point is right,
	/// and 0 if points are collinear.</returns>
	[Inline]
	public static float Area(ref Vector2 a, ref Vector2 b, ref Vector2 c)
	{
		return a.X * (b.Y - c.Y) + b.X * (c.Y - a.Y) + c.X * (a.Y - b.Y);
	}

	/*/// <summary>
	/// Lerps the specified value1.
	/// </summary>
	/// <param name="value1">The value1.</param>
	/// <param name="value2">The value2.</param>
	/// <param name="amount">The amount.</param>
	/// <example>
	/// When amount = 0 returns value1.
	/// When amount = 1 return value2.
	/// When amount = 0.5 returns the midpoint of value1 and value2.
	/// </example>
	/// <returns>Interpolated value.</returns>
	[Inline]
	public static float Lerp(float value1, float value2, float amount)
	{
		return value1 + (value2 - value1) * amount;
	}*/

	/// <summary>
	/// Linearly interpolates between value1 and value2 by amount.
	/// The parameter amount is clamped to the range [0, 1].
	/// </summary>
	/// <param name="value1">Source value1.</param>
	/// <param name="value2">Source value2.</param>
	/// <param name="amount">Value between 0 and 1 indicating the weight of value2.</param>
	/// <example>
	/// When amount = 0 returns value1.
	/// When amount = 1 return value2.
	/// When amount = 0.5 returns the midpoint of value1 and value2.
	/// </example>
	/// <returns>Interpolated value.</returns>
	[Inline]
	public static float LerpClamped(float value1, float value2, float amount)
	{
		return value1 + (value2 - value1) * Clamp(amount, 0f, 1f);
	}

	/// <summary>
	/// Calculates the linear parameter amount that produces the interpolant value within the range [value1, value2].
	/// </summary>
	/// <param name="value1">Source value1.</param>
	/// <param name="value2">Source value2.</param>
	/// <param name="value">Interpolant value.</param>
	/// <returns>The linear parameter amount.</returns>
	[Inline]
	public static float InverseLerp(float value1, float value2, float value)
	{
		return (value - value1) / (value2 - value1);
	}

	/// <summary>
	/// Returns the greater of two float values.
	/// </summary>
	/// <param name="value1">Source value1.</param>
	/// <param name="value2">Source value2.</param>
	/// <returns>The greater value.</returns>
	[Inline]
	public static float Max(float value1, float value2)
	{
		return Math.Max(value1, value2);
	}

	/// <summary>
	/// Returns the greater of two int32 values.
	/// </summary>
	/// <param name="value1">Source value1.</param>
	/// <param name="value2">Source value2.</param>
	/// <returns>The greater value.</returns>
	[Inline]
	public static int32 Max(int32 value1, int32 value2)
	{
		return Math.Max(value1, value2);
	}

	/// <summary>
	/// Returns the lesser of two or more values.
	/// </summary>
	/// <param name="value1">Source value1.</param>
	/// <param name="value2">Source value2.</param>
	/// <returns>The lesser value.</returns>
	[Inline]
	public static float Min(float value1, float value2)
	{
		return Math.Min(value1, value2);
	}

	/// <summary>
	/// Returns the greater of two <see cref="T:Sedulous.Core.Mathematics.Vector2" /> components.
	/// </summary>
	/// <param name="value">Source value.</param>
	/// <returns>The greater value.</returns>
	[Inline]
	public static float Max(ref Vector2 value)
	{
		float max = value.X;
		if (max < value.Y)
		{
			max = value.Y;
		}
		return max;
	}

	/// <summary>
	/// Returns the lesser of two <see cref="T:Sedulous.Core.Mathematics.Vector2" /> components.
	/// </summary>
	/// <param name="value">Source value.</param>
	/// <returns>The lesser value.</returns>
	[Inline]
	public static float Min(ref Vector2 value)
	{
		float min = value.X;
		if (min > value.Y)
		{
			min = value.Y;
		}
		return min;
	}

	/// <summary>
	/// Returns the greater of three <see cref="T:Sedulous.Core.Mathematics.Vector3" /> components.
	/// </summary>
	/// <param name="value">Source vector.</param>
	/// <returns>The greater value.</returns>
	[Inline]
	public static float Max(ref Vector3 value)
	{
		float max = value.X;
		if (max < value.Y)
		{
			max = value.Y;
		}
		if (max < value.Z)
		{
			max = value.Z;
		}
		return max;
	}

	/// <summary>
	/// Returns the lesser of three <see cref="T:Sedulous.Core.Mathematics.Vector3" /> components.
	/// </summary>
	/// <param name="value">Source vector.</param>
	/// <returns>The lesser value.</returns>
	[Inline]
	public static float Min(ref Vector3 value)
	{
		float min = value.X;
		if (min > value.Y)
		{
			min = value.Y;
		}
		if (min > value.Z)
		{
			min = value.Z;
		}
		return min;
	}

	/// <summary>
	/// Interpolates between two values using a cubic equation.
	/// </summary>
	/// <param name="value1">Source value1.</param>
	/// <param name="value2">Source value2.</param>
	/// <param name="amount">Weighting value.</param>
	/// <returns>Interpolated value.</returns>
	[Inline]
	public static float SmoothStep(float value1, float value2, float amount)
	{
		float num = Clamp(amount, 0f, 1f);
		return Lerp(value1, value2, num * num * (3f - 2f * num));
	}

	/// <summary>
	/// Changes a float value towards a desired goal over time.
	/// </summary>
	/// <param name="current">The current value.</param>
	/// <param name="target">The target value.</param>
	/// <param name="currentVelocity">The current velocity.</param>
	/// <param name="smoothTime">The time it will take to reach the target.</param>
	/// <param name="gameTime">The current game time (time between last frame).</param>
	/// <returns>The smooth value.</returns>
	[Inline]
	public static float SmoothDamp(float current, float target, ref float currentVelocity, float smoothTime, float gameTime)
	{
		var target;
		var smoothTime;
		smoothTime = Math.Max(0.0001f, smoothTime);
		float aux = 2f / smoothTime;
		float aux1 = aux * gameTime;
		float aux2 = 1f / (1f + aux1 + 0.48f * aux1 * aux1 + 0.235f * aux1 * aux1 * aux1);
		float aux3 = current - target;
		float aux4 = target;
		target = current - aux3;
		float single6 = (currentVelocity + aux * aux3) * gameTime;
		currentVelocity = (currentVelocity - aux * single6) * aux2;
		float single7 = target + (aux3 + single6) * aux2;
		if (aux4 - current > 0f == single7 > aux4)
		{
			single7 = aux4;
			currentVelocity = (single7 - aux4) / gameTime;
		}
		return single7;
	}

	/// <summary>
	/// Converts radians to degrees.
	/// </summary>
	/// <param name="radians">The angle in radians.</param>
	/// <returns>The angle in degrees.</returns>
	[Inline]
	public static float ToDegrees(float radians)
	{
		return (float)((double)radians * 57.2957795131);
	}

	/// <summary>
	/// Converts radians to degrees.
	/// </summary>
	/// <param name="radians">The angle in radians.</param>
	/// <returns>The angle in degrees.</returns>
	[Inline]
	public static float ToDegrees(double radians)
	{
		return (float)(radians * 57.2957795131);
	}

	/// <summary>
	/// Converts degrees to radians.
	/// </summary>
	/// <param name="degrees">The angle in degrees.</param>
	/// <returns>The angle in radians.</returns>
	[Inline]
	public static float ToRadians(float degrees)
	{
		return (float)((double)degrees * 0.01745329252);
	}

	/// <summary>
	/// Converts degrees to radians.
	/// </summary>
	/// <param name="degrees">The angle in degrees..</param>
	/// <returns>The angle in radians.</returns>
	[Inline]
	public static float ToRadians(double degrees)
	{
		return (float)(degrees * 0.01745329252);
	}

	/// <summary>
	/// Reduces a given angle to a value between π and -π.
	/// </summary>
	/// <param name="angle">The angle to reduce, in radians.</param>
	/// <returns>The new angle, in radians.</returns>
	[Inline]
	public static float WrapAngle(float angle)
	{
		var angle;
		angle = (float)Math.IEEERemainder(angle, 6.2831854820251465);
		if (angle <= -3.141593f)
		{
			angle += 6.283185f;
			return angle;
		}
		if (angle > 3.141593f)
		{
			angle -= 6.283185f;
		}
		return angle;
	}

	/// <summary>
	/// Checks if a floating point Value is equal to another,
	/// within a certain tolerance.
	/// </summary>
	/// <param name="value1">The first floating point Value.</param>
	/// <param name="value2">The second floating point Value.</param>
	/// <returns>True if the values are "equal", false otherwise.</returns>
	[Inline]
	public static bool FloatEquals(float value1, float value2)
	{
		return Math.Abs(value1 - value2) <= 1.1920929E-07f;
	}

	/// <summary>
	/// Checks if a floating point Value is equal to another,
	/// within a certain tolerance.
	/// </summary>
	/// <param name="value1">The first floating point Value.</param>
	/// <param name="value2">The second floating point Value.</param>
	/// <param name="delta">The floating point tolerance.</param>
	/// <returns>True if the values are "equal", false otherwise.</returns>
	[Inline]
	public static bool FloatEquals(float value1, float value2, float delta)
	{
		return FloatInRange(value1, value2 - delta, value2 + delta);
	}

	/// <summary>
	/// Checks if a floating point Value is within a specified
	/// range of values (inclusive).
	/// </summary>
	/// <param name="value">The Value to check.</param>
	/// <param name="min">The minimum Value.</param>
	/// <param name="max">The maximum Value.</param>
	/// <returns>True if the Value is within the range specified,
	/// false otherwise.</returns>
	[Inline]
	public static bool FloatInRange(float value, float min, float max)
	{
		if (value >= min)
		{
			return value <= max;
		}
		return false;
	}

	/// <summary>
	/// Divide value by alignment to get the minimum multiple higher than the value.
	/// </summary>
	/// <param name="value">The value to divide.</param>
	/// <param name="alignment">The alignment.</param>
	/// <returns>The multiply value.</returns>
	[Inline]
	public static uint32 DivideByMultiple(uint32 value, uint32 alignment)
	{
		return (value + alignment - 1) / alignment;
	}
}