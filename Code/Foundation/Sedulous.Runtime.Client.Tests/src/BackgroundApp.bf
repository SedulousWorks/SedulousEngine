using System.Collections;
using Sedulous.Graphics;
using Sedulous.Runtime;

namespace Sedulous.Runtime.Client.Tests;

/// Hears the app go to the background and back, and keeps the order the host tells it in.
class BackgroundSubsystem : Subsystem
{
	public List<int> Order = null; // borrowed: the application's
	public int Updates = 0;

	public override void Update(float deltaTime) { Updates++; }
	public override void OnEnterBackground() { Order.Add(2); }
	public override void OnEnterForeground() { Order.Add(3); }
}

/// 1, 2: the app then the subsystem going; 3, 4: the subsystem then the app coming back.
class BackgroundApp : IApplication
{
	public List<int> Order = new .() ~ delete _;
	public BackgroundSubsystem Subsystem = null;
	public int Renders = 0;
	public bool SwapGoneWhenAppHeard = false;
	public RenderWindow Window = null;

	public void Configure(IApplicationHost host)
	{
		Subsystem = host.Subsystems.AddSubsystem<BackgroundSubsystem>();
		Subsystem.Order = Order;
	}

	public void OnEnterBackground(IApplicationHost host)
	{
		Order.Add(1);
		SwapGoneWhenAppHeard = Window.IsSuspended;
	}

	public void OnEnterForeground(IApplicationHost host) { Order.Add(4); }

	public void OnRenderWindow(IApplicationHost host, ref FrameContext frame) { Renders++; }
}
