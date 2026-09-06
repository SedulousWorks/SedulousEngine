namespace System
{
	extension Guid
	{
		public void GetString(String str)
		{
			str.AppendF("{0:X}", mA);
			str.Append("-");
			str.AppendF("{0:X}", mB);
			str.Append("-");
			str.AppendF("{0:X}", mC);
			str.Append("-");
			str.AppendF("{0:X}", mD);
			str.AppendF("{0:X}", mE);
			str.Append("-");
			str.AppendF("{0:X}", mF);
			str.AppendF("{0:X}", mG);
			str.AppendF("{0:X}", mH);
			str.AppendF("{0:X}", mI);
			str.AppendF("{0:X}", mJ);
			str.AppendF("{0:X}", mK);
		}
	}
}