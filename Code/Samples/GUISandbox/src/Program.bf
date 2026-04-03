namespace GUISandbox;

using System;
using Sedulous.RHI;
using Sedulous.Runtime.Client;

class Program
{
	public static int Main(String[] args)
	{
		let app = scope GUISandboxApp();
		return app.Run(.() { Title = "Sedulous.GUI Sandbox", Width = 1280, Height = 720, ClearColor = .(0.1f, 0.1f, 0.15f, 1.0f), EnableDepth = false });
	}
}
