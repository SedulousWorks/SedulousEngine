using System;
using Sedulous.Runtime.Client;

namespace Sedulous.Engine.Player.Web;

/// The player in a page: it tells the page when the game is running (its first update, so the
/// loading card can go) and when it has stopped (the card comes back, with a way to play again).
class WebPlayerApplication : PlayerApplication
{
	private bool mStarted = false;

	public this(PlayerOptions options) : base(options)
	{
	}

	public override void OnUpdate(IApplicationHost host, float deltaTime)
	{
		base.OnUpdate(host, deltaTime);
		if (!mStarted)
		{
			mStarted = true;
			WebPage.GameRunning();
		}
	}

	public override void OnShutdown(IApplicationHost host)
	{
		base.OnShutdown(host);
		WebPage.GameEnded(mStarted);
	}
}
