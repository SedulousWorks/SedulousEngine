namespace System;

extension Span<T>
{
	public bool SequenceEqual(Self other)
	{
		if (Length != other.Length)
			return false;

		for (int i = 0; i < Length; i++)
		{
			if (this[i] != other[i])
				return false;
		}

		return true;
	}
}