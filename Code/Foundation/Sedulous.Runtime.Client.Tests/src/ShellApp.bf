using Sedulous.Shell;

namespace Sedulous.Runtime.Client.Tests;

/// Records the shell it can see during Configure, which is the earliest an application
/// runs at all.
class ShellApp : IApplication
{
	public IShell SeenShell = null;

	public void Configure(IApplicationHost host) => SeenShell = host.Shell;
}
