using System;
using System.Collections;

namespace Sedulous.Runtime.Client.Tests;

/// Records the order the lifecycle hooks fire in, and registers its subsystem in
/// Configure, which is where an application's subsystems belong.
///
/// The fixed step is half a second so the accumulator arithmetic is exact rather than
/// approximately sixty hertz.
class LifecycleApp : IApplication
{
	public enum Hook { Configure = 1, Startup, Launch, Update, Exit, Shutdown }

	public List<Hook> Order = new .() ~ delete _;
	public CountingSubsystem Subsystem = null;
	public int FixedUpdates = 0;
	public bool SubsystemLiveAtStartup = false;

	public ApplicationSettings Settings
	{
		get
		{
			var settings = ApplicationSettings();
			settings.FixedTimeStep = 0.5f;
			return settings;
		}
	}

	public void Configure(IApplicationHost host)
	{
		Order.Add(.Configure);
		Subsystem = host.Context.AddSubsystem<CountingSubsystem>();
	}

	public void OnStartup(IApplicationHost host)
	{
		Order.Add(.Startup);
		// Configure ran BEFORE Context.Startup, so by now the subsystem is initialised.
		SubsystemLiveAtStartup = Subsystem.IsInitialized;
	}

	public void OnLaunch(IApplicationHost host) => Order.Add(.Launch);
	public void OnFixedUpdate(IApplicationHost host, float fixedDeltaTime) { FixedUpdates++; }
	public void OnUpdate(IApplicationHost host, float deltaTime) => Order.Add(.Update);
	public void OnExit(IApplicationHost host) => Order.Add(.Exit);
	public void OnShutdown(IApplicationHost host) => Order.Add(.Shutdown);

	public int CountOf(Hook hook)
	{
		int count = 0;
		for (let entry in Order)
		{
			if (entry == hook)
				count++;
		}
		return count;
	}
}
