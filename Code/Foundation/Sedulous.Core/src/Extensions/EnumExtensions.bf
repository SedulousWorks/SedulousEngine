namespace System;

extension Enum
{
	public static void MapValues<T>(delegate void(T member) mapFunction) where T : enum
	{
		for (var value in Enum.GetValues<T>())
		{
			mapFunction(value);
		}
	}
}