using System;

namespace Samples.VGSandbox;

class Program
{
	public static int Main(String[] args)
	{
		let app = scope VGSandboxApp();
		return app.Run(args);
	}
}
