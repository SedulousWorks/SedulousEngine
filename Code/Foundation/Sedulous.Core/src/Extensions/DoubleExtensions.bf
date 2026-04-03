namespace System;

extension Double
{
	public static bool IsPositiveInfinity(double f)
	{
		return f == double.PositiveInfinity;
	}

	public static bool IsNegativeInfinity(double f)
	{
		return f == double.NegativeInfinity;
	}
}