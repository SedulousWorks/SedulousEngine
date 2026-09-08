using System;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Graphics;
using Sedulous.Runtime;
using Sedulous.Shell;

namespace Sedulous.Runtime.Client;

/// The editor embedding adapter.
///
/// An application programs against IApplicationHost and runs UNCHANGED standalone or
/// inside an editor. This routes Context to an EMBEDDED runtime context, owned by the
/// embedder and distinct from the outer host's own, while sharing the outer host's shell
/// and its REAL graphics device.
///
/// The embedded application renders into a viewport texture rather than an OS window, so
/// there is no main render window and opening one is refused. Exit means "stop the play
/// session", and only the embedder knows what that entails, so it supplies the meaning
/// through a handler.
class EmbeddedApplicationHost : IApplicationHost
{
	private IApplicationHost mOuter;
	private Context mRuntimeContext;
	private delegate void(int) mOnExit = null;

	/// `outer` is the real host, whose shell and device are borrowed; `runtimeContext` is
	/// the embedded context the hosted application configures and runs in. Both borrowed.
	public this(IApplicationHost outer, Context runtimeContext)
	{
		mOuter = outer;
		mRuntimeContext = runtimeContext;
	}

	public Context Context => mRuntimeContext;
	public IShell Shell => mOuter.Shell;
	public GraphicsDevice Graphics => mOuter.Graphics;

	/// Null, always. Code that attaches a root UI to the main window has to tolerate that
	/// here exactly as it does for a headless run.
	public RenderWindow MainRenderWindow => null;

	public RenderWindow OpenWindow(WindowSettings windowSettings, RenderWindowDesc renderDesc)
	{
		GlobalLog(.Warning, "EmbeddedApplicationHost: the embedded application asked for an OS window, refused");
		return null;
	}

	public void CloseWindow(RenderWindow window) {}

	/// Installs what exit MEANS. The CALLER owns the delegate and must keep it alive for
	/// as long as it is installed.
	public void SetExitHandler(delegate void(int) handler) => mOnExit = handler;

	public void RequestExit(int code = 0)
	{
		if (mOnExit != null)
		{
			mOnExit(code);
			return;
		}
		GlobalLog(.Warning, "EmbeddedApplicationHost: the embedded application asked to exit({}), no handler", code);
	}
}
