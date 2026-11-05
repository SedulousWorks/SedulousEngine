using System;
using Sedulous.VFS;

namespace Sedulous.Runtime.Client;

/// What a windowed application offers the plugins its process enables: the application host it
/// runs on (the graphics device, the shell, the subsystems) and the data mount engine data is
/// read through. A plugin finds it by type (PluginContext.Find<ClientServices>), and finds none
/// in a process with no window (a cook, an export), so it leaves out what needs one.
class ClientServices
{
	/// The host the application runs on. BORROWED.
	public IApplicationHost Host;
	/// The data mount ("Engine/Shaders/..."). BORROWED.
	public IFileSystem Data;
}
