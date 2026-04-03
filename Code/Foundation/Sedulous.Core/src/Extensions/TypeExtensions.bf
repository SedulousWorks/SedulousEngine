namespace System;

extension Type
{
	public bool IsAssignableFrom(Type type)
	{
		if(type == null)
		{
			return false;
		}

		return type == this || type.IsSubtypeOf(this);
	}
}