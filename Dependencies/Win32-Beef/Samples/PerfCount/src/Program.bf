using Win32.System.Performance;
using Win32.Foundation;
using System;

namespace PerfCount;

class Program
{
	public static void Main()
	{
		LARGE_INTEGER frq = .();
		LARGE_INTEGER perfCount1 = .();
		QueryPerformanceFrequency(&frq);
		QueryPerformanceCounter(&perfCount1);
		while (true)
		{
			LARGE_INTEGER perfCountn = .();
			QueryPerformanceCounter(&perfCountn);
			int64 delta = perfCountn.QuadPart - perfCount1.QuadPart;
			double seconds = delta / (double)frq.QuadPart;
			Console.WriteLine(seconds);
		}
	}
}