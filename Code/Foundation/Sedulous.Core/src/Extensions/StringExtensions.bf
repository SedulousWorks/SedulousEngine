namespace System;

extension String
{
	public void SetF(StringView format, params Object[] args)
	{
		mLength = 0;
		AppendF(format, params args);
	}
}