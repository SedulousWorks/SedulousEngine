namespace TowerDefense;

using System;
using Sedulous.Shell.SDL3;
using Sedulous.RuntimeGraphics;
using Sedulous.Runtime.Client;

class Program
{
	public static int Main(String[] args)
	{
		let shell = scope SDL3Shell();
		if (shell.Initialize() case .Err)
		{
			Console.WriteLine("ERROR: Failed to initialize shell");
			return 1;
		}
		defer shell.Shutdown();

		let graphicsResult = GraphicsDevice.Create(.() { EnableValidation = true });
		if (graphicsResult case .Err)
		{
			Console.WriteLine("ERROR: Failed to create graphics device");
			return 1;
		}
		let graphics = graphicsResult.Value;
		defer delete graphics;

		let app = scope TowerDefenseApp();
		return ApplicationHost.RunApplication(app, shell, graphics);
	}
}
