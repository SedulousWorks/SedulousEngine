namespace SnowlineTools;

class Program
{
	public static int Main(System.String[] args)
	{
		if (args.Count > 0)
		{
			let rest = scope System.String[args.Count - 1];
			for (int i < rest.Count)
				rest[i] = args[i + 1];
			if (args[0] == "mcp")
				return Sedulous.Editor.McpMain.McpMain.Run(rest);
			if (args[0] == "cook")
				return Sedulous.Editor.CookMain.CookMain.Run(rest);
			if (args[0] == "export")
				return Sedulous.Editor.ExportMain.ExportMain.Run(rest);
		}
		System.Console.Error.WriteLine("usage: SnowlineTools mcp|cook|export [arguments]");
		return 2;
	}
}
