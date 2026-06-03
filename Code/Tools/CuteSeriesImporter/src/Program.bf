namespace CuteSeriesImporter;

using System;
using System.IO;
using Sedulous.Models;
using Sedulous.Models.FBX;
using Sedulous.Images.STB;

class Program
{
	public static int Main(String[] args)
	{
		// Initialize loaders
		STBImageLoader.Initialize();
		FbxModels.Initialize();

		let manifestPath = scope String();
		String packFilter = null;
		String outputRoot = null;

		// Parse arguments
		for (int i = 0; i < args.Count; i++)
		{
			if ((args[i] == "--pack" || args[i] == "-p") && i + 1 < args.Count)
			{
				packFilter = args[++i];
			}
			else if ((args[i] == "--output" || args[i] == "-o") && i + 1 < args.Count)
			{
				outputRoot = args[++i];
			}
			else if (manifestPath.IsEmpty)
			{
				manifestPath.Set(args[i]);
			}
		}

		if (manifestPath.IsEmpty)
		{
			// Default: look for manifest next to executable
			let exeDir = scope String();
			Environment.GetExecutableFilePath(exeDir);
			Path.GetDirectoryPath(exeDir, exeDir);
			Path.InternalCombine(manifestPath, exeDir, "CuteSeriesManifest.xml");
		}

		if (!File.Exists(manifestPath))
		{
			Console.WriteLine("Manifest not found: {}", manifestPath);
			return 1;
		}

		Console.WriteLine("=== CuteSeries Importer ===");
		Console.WriteLine("Manifest: {}", manifestPath);

		let importer = scope ManifestImporter();

		if (packFilter != null)
		{
			importer.SetPackFilter(packFilter);
			Console.WriteLine("Pack filter: {}", packFilter);
		}

		if (outputRoot != null)
		{
			importer.SetOutputRoot(outputRoot);
			Console.WriteLine("Output root: {}", outputRoot);
		}

		if (importer.Run(manifestPath) case .Err)
		{
			Console.WriteLine("Import failed.");
			return 1;
		}

		Console.WriteLine("Import complete.");
		return 0;
	}
}
