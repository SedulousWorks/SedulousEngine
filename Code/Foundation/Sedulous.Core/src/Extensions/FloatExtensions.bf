namespace System;

extension Float
{
	public static bool IsPositiveInfinity(float f)
	{
		return f == float.PositiveInfinity;
	}

	public static bool IsNegativeInfinity(float f)
	{
		return f == float.NegativeInfinity;
	}
}