using System;

namespace Sedulous.Core;

/// A LIVE leak check on Linux, the counterpart of the Windows debug runtime's real time
/// detection. The Linux runtime has no leak checker; LeakSanitizer, preloaded, has one, and
/// exports `__lsan_do_recoverable_leak_check`, which scans for unreachable allocations right
/// now and prints them without stopping the process. Nothing is linked: the symbol is looked
/// up in whatever was preloaded, so a run without it is a no-op.
///
/// ENV_LEAK_CHECK_SECONDS=<s> runs it every s seconds; call Check to run one on demand.
static class LeakProbe
{
	private static bool sResolved = false;
	private static function void() sCheck = null;
	private static double sInterval = 0;
	private static double sSince = 0;

	/// Whether a checker is reachable at all.
	public static bool Available
	{
		get
		{
			Resolve();
			return sCheck != null;
		}
	}

	/// Runs one check; false when none is preloaded.
	public static bool Check()
	{
		Resolve();
		if (sCheck == null)
			return false;
		Console.Error.WriteLine("[LeakProbe] live leak check");
		sCheck();
		return true;
	}

	/// The periodic check, driven from a frame loop.
	public static void Update(double deltaSeconds)
	{
		Resolve();
		if ((sCheck == null) || (sInterval <= 0))
			return;
		sSince += deltaSeconds;
		if (sSince < sInterval)
			return;
		sSince = 0;
		Check();
	}

	private static void Resolve()
	{
		if (sResolved)
			return;
		sResolved = true;
#if BF_PLATFORM_LINUX
		sCheck = (function void())dlsym(null, "__lsan_do_recoverable_leak_check");
		if (sCheck == null)
			return;
		let raw = scope String();
		if ((Environment.GetEnvironmentVariable("ENV_LEAK_CHECK_SECONDS", raw) case .Ok) && !raw.IsEmpty)
			sInterval = double.Parse(raw).GetValueOrDefault();
		if (sInterval > 0)
			Console.Error.WriteLine(scope $"[LeakProbe] LeakSanitizer present, checking every {sInterval}s");
		else
			Console.Error.WriteLine("[LeakProbe] LeakSanitizer present");
#endif
	}

#if BF_PLATFORM_LINUX
	/// RTLD_DEFAULT is a null handle on glibc.
	[CLink]
	private static extern void* dlsym(void* handle, char8* name);
#endif
}
