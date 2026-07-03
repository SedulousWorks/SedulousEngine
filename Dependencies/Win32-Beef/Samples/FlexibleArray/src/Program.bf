namespace FlexibleArray;

using Win32.NetworkManagement.IpHelper;
using System;
using System.Diagnostics;

class Program
{
	public static void Main()
	{
		uint32 bufLen = 0;

		GetInterfaceInfo(null, &bufLen);

		IP_INTERFACE_INFO* info = (.)scope uint8[bufLen]*;

		GetInterfaceInfo(info, &bufLen);

		for (int i = 0; i < info.NumAdapters; i++)
		{
			Debug.WriteLine("{}", scope String(&info.Adapter[i].Name));
		}
	}
}