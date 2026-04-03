using System;
using System.Globalization;

namespace Sedulous.Core.Mathematics;

/// <summary>
/// Represents an angle in radians.
/// </summary>
struct Radians : IEquatable<Radians>, IInterpolatable<Radians>, IEquatable, IHashable
{
    /// <summary>
    /// Initializes a new instance of the <see cref="Radians"/> structure.
    /// </summary>
    /// <param name="value">The value in radians.</param>
    public this(float value)
    {
        this.value = value;
    }

    /// <summary>
    /// Implicitly converts an instance of the <see cref="Radians"/> structure to its underlying value.
    /// </summary>
    /// <param name="value">The value to convert.</param>
    /// <returns>The converted value.</returns>
    public static implicit operator float(Radians value)
    {
        return value.Value;
    }

    /// <summary>
    /// Explicitly converts a single-precision floating point value to a new instance of the <see cref="Radians"/> structure.
    /// </summary>
    /// <param name="value">The value to convert.</param>
    /// <returns>The converted value.</returns>
    public static explicit operator Radians(float value)
    {
        return Radians(value);
    }
    
    /// <summary>
    /// Adds two values in radians.
    /// </summary>
    /// <param name="r1">The first value to add.</param>
    /// <param name="r2">The second value to add.</param>
    /// <returns>The sum of the specified values.</returns>
    public static Radians operator +(Radians r1, Radians r2)
    {
        return Radians(r1.Value + r2.Value);
    }

    /// <summary>
    /// Adds two values in radians.
    /// </summary>
    /// <param name="r1">The first value to add.</param>
    /// <param name="r2">The second value to add.</param>
    /// <returns>The sum of the specified values.</returns>
    public static Radians operator +(Radians r1, float r2)
    {
        return Radians(r1.Value + r2);
    }

    /// <summary>
    /// Subtracts a value in radians from another value in radians.
    /// </summary>
    /// <param name="r1">The first value to subtract.</param>
    /// <param name="r2">The second value to subtract.</param>
    /// <returns>The difference of the specified values.</returns>
    public static Radians operator -(Radians r1, Radians r2)
    {
        return Radians(r1.Value - r2.Value);
    }

    /// <summary>
    /// Subtracts a value in radians from another value in radians.
    /// </summary>
    /// <param name="r1">The first value to subtract.</param>
    /// <param name="r2">The second value to subtract.</param>
    /// <returns>The difference of the specified values.</returns>
    public static Radians operator -(Radians r1, float r2)
    {
        return Radians(r1.Value - r2);
    }

    /// <summary>
    /// Multiplies two values in radians.
    /// </summary>
    /// <param name="r1">The first value to multiply.</param>
    /// <param name="r2">The second value to multiply.</param>
    /// <returns>The product of the specified values.</returns>
    public static Radians operator *(Radians r1, Radians r2)
    {
        return Radians(r1.Value * r2.Value);
    }

    /// <summary>
    /// Multiplies two values in radians.
    /// </summary>
    /// <param name="r1">The first value to multiply.</param>
    /// <param name="r2">The second value to multiply.</param>
    /// <returns>The product of the specified values.</returns>
    public static Radians operator *(Radians r1, float r2)
    {
        return Radians(r1.Value * r2);
    }

    /// <summary>
    /// Divides two values in radians.
    /// </summary>
    /// <param name="r1">The first value to divide.</param>
    /// <param name="r2">The second value to divide.</param>
    /// <returns>The quotient of the specified values.</returns>
    public static Radians operator /(Radians r1, Radians r2)
    {
        return Radians(r1.Value / r2.Value);
    }

    /// <summary>
    /// Divides two values in radians.
    /// </summary>
    /// <param name="r1">The first value to divide.</param>
    /// <param name="r2">The second value to divide.</param>
    /// <returns>The quotient of the specified values.</returns>
    public static Radians operator /(Radians r1, float r2)
    {
        return Radians(r1.Value / r2);
    }

    /// <summary>
    /// Negates the specified value in radians.
    /// </summary>
    /// <param name="r1">The value to negate.</param>
    /// <returns>The negated value.</returns>
    public static Radians operator -(Radians r1)
    {
        return Radians(-r1.Value);
    }
    
    /// <summary>
    /// Creates a new instance of the <see cref="Radians"/> structure in terms of pi.
    /// </summary>
    /// <param name="n">The number to multiply by pi in order to calculate a value in radians.</param>
    /// <returns>A new instance of the <see cref="Radians"/> structure with a value equal to pi times the specified factor.</returns>
    public static Radians FromPi(float n)
    {
        return Radians((float)(Math.PI_f * n));
    }

    /// <summary>
    /// Creates a new instance of the <see cref="Radians"/> structure in terms of tau.
    /// </summary>
    /// <param name="n">The number to multiply by tau in order to calculate a value in radians.</param>
    /// <returns>A new instance of the <see cref="Radians"/> structure with a value equal to tau times the specified factor.</returns>
    public static Radians FromTau(float n)
    {
        return Radians((float)(2.0 * Math.PI_f * n));
    }

    /// <summary>
    /// Creates a new instance of the <see cref="Radians"/> structure equivalent to the specified number of degrees.
    /// </summary>
    /// <param name="degrees">The angle in degrees to convert to radians.</param>
    /// <returns>A new instance of the <see cref="Radians"/> structure equivalent to the specified number of degrees.</returns>
    public static Radians FromDegrees(float degrees)
    {
        return Radians(degrees * RadiansPerDegree);
    }

    /// <summary>
    /// Normalizes the specified value to the range [0-2pi).
    /// </summary>
    /// <param name="radians">The value to normalize.</param>
    /// <returns>The normalized value.</returns>
    public static Radians Normalize(Radians radians)
    {
        var angle = radians.value % (float)(2.0 * Math.PI_f);
        return angle >= 0 ? Radians(angle) : Radians((float)(angle + 2.0 * Math.PI_f));
    }

    /// <inheritdoc/>
    public override void ToString(String str) => Value.ToString(str);

    /// <summary>
    /// Compares this instance to the specified angle and returns an integer that indicates whether the value
    /// of this instance is less than, equal to, or greater than the value of the specified angle.
    /// </summary>
    /// <param name="other">The angle to compare to this instance.</param>
    /// <returns>A value that indicates the relative order of the objects being compared.</returns>
    public int CompareTo(Radians other)
    {
        return value.CompareTo(other.value);
    }
	public static int operator<=>(Radians a, Radians b)
	{
		return a.CompareTo(b);
	}

    /// <summary>
    /// Compares this instance to the specified angle and returns an integer that indicates whether the value
    /// of this instance is less than, equal to, or greater than the value of the specified angle.
    /// </summary>
    /// <param name="other">The angle to compare to this instance.</param>
    /// <returns>A value that indicates the relative order of the objects being compared.</returns>
    public int CompareTo(float other)
    {
        return value.CompareTo(other);
    }
	public static int operator<=>(Radians a, float b)
	{
		return a.CompareTo(b);
	}

    /// <summary>
    /// Converts the angle to a value in degrees.
    /// </summary>
    /// <returns>The radian value converted to degrees.</returns>
    public float ToDegrees()
    {
        return value * DegreesPerRadian;
    }

    /// <summary>
    /// Interpolates between this value and the specified value.
    /// </summary>
    /// <param name="target">The target value.</param>
    /// <param name="t">A value between 0.0 and 1.0 representing the interpolation factor.</param>
    /// <returns>The interpolated value.</returns>
    public Radians Interpolate(Radians target, float t)
    {
        var angle = Tweening.Lerp(this.value, target.value, t);
        return Radians(angle);
    }

    /// <summary>
    /// Gets an instance which represents zero radians.
    /// </summary>
    public static Radians Zero
    {
        get { return Radians(0); }
    }
    
    /// <summary>
    /// Gets an instance which represents π / 4 radians.
    /// </summary>
    public static Radians PiOver4
    {
        get { return Radians((float)Math.PI_f / 4f); }
    }

    /// <summary>
    /// Gets an instance which represents π / 2 radians.
    /// </summary>
    public static Radians PiOver2
    {
        get { return Radians((float)Math.PI_f / 2f); }
    }

    /// <summary>
    /// Gets an instance which represents π radians.
    /// </summary>
    public static Radians Pi
    {
        get { return Radians((float)Math.PI_f); }
    }

    /// <summary>
    /// Gets an instance which represents 2π radians.
    /// </summary>
    public static Radians TwoPi
    {
        get { return Radians((float)Math.PI_f * 2f); }
    }

    /// <summary>
    /// Gets the value in radians.
    /// </summary>
    public float Value
    {
        get { return value; }
    }
    
    /// <summary>
    /// Gets a value indicating whether this is a normalized angle in the range of [0-2pi).
    /// </summary>
    public bool IsNormalized
    {
        get { return value >= 0 && value < (float)(2.0 * Math.PI_f); }
    }

    /// <summary>
    /// The number of radians in one degree.
    /// </summary>
    public const float RadiansPerDegree = 1f / DegreesPerRadian;

    /// <summary>
    /// The number of degrees in one radian.
    /// </summary>
    public const float DegreesPerRadian = 57.2957795f;

    /// <summary>
    /// Evaluates the specified string to determine whether it is suffixed by pi or tau,
    /// and determines the scaling factor to apply as a result.
    /// </summary>
    /// <param name="s">The string to evaluate for a suffix.</param>
    /// <param name="factor">The scaling factor to apply to the string's numeric portion.</param>
    /// <returns>The string's suffix, or <see langword="null"/> if it has no suffix.</returns>
    private static String EvaluateSuffix(String s, out float factor)
    {
        if (s.EndsWith("tau"))
        {
            factor = (float)Math.PI_f * 2f;
            return "tau";
        }
        if (s.EndsWith("τ"))
        {
            factor = (float)Math.PI_f * 2f;
            return "τ";
        }
        if (s.EndsWith("pi"))
        {
            factor = (float)Math.PI_f;
            return "pi";
        }
        if (s.EndsWith("π"))
        {
            factor = (float)Math.PI_f;
            return "π";
        }
        factor = 1f;
        return null;
    }

    /// <summary>
    /// Parses the fractional factor of a string representation of an angle.
    /// </summary>
    /// <param name="s">A string containing the fractional factor to parse.</param>
    /// <param name="style">A set of <see cref="NumberStyles"/> values indicating which elements are present in <paramref name="s"/>.</param>
    /// <param name="provider">A format provider that provides culture-specific formatting information.</param>
    /// <param name="fraction">A single-precision floating point value that is equivalent to the specified string.</param>
    /// <returns><see langword="true"/> if the string was able to be parsed; otherwise, <see langword="false"/>.</returns>
    /*private static bool TryParseFraction(String s, NumberStyles style, IFormatProvider provider, out float fraction)
    {
        var ix = s.IndexOf('/');
        if (ix < 0)
        {
            return float.TryParse(s, style, provider, out fraction);
        }
        
        float numerator, denominator;

        if (!float.TryParse(s.Substring(0, ix), style, provider, out numerator))
        {
            fraction = 0;
            return false;
        }

        if (!float.TryParse(s.Substring(ix + 1), style, provider, out denominator))
        {
            fraction = 0;
            return false;
        }

        fraction = numerator / denominator;
        return true;
    }*/

    // Property values.
    private readonly float value;
}
