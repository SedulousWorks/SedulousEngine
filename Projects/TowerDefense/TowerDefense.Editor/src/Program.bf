namespace TowerDefense.Editor;

using System;
using Sedulous.Runtime.Client;
using Sedulous.Editor;
using TowerDefense;

class Program
{
	static int Main(String[] args)
	{
		let app = scope TowerDefenseApp();
		let editor = scope EditorApplication();
		editor.App = app;
		return editor.Run(.() { Title = "Tower Defense Editor", Width = 1600, Height = 900, EnableShaderCache = true });
	}
}
