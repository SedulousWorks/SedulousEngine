using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Engine.SceneSurface;

namespace Sedulous.Editor.Mcp;

/// Parses scene XML into a scratch scene carrying the FULL engine manager set, so component
/// payloads validate through their real managers exactly as the editor and the cooked scene
/// reader would parse them. Only a genuinely unknown component type is skipped, as a
/// warning the capture keeps.
static class SceneValidation
{
	/// Fills `outReport` from `xml`. The transcode is the same pass the export runs.
	public static void Parse(StringView xml, SceneParseReport outReport)
	{
		let capture = scope SceneLogCapture();
		capture.Start();

		let stream = scope MemoryStream();
		stream.Write(.((uint8*)xml.Ptr, xml.Length));
		stream.Seek(0, .Begin);

		let scratch = scope Scene("validate");
		EngineSceneComposition.AddAllSceneManagers(scratch);
		let bytes = scope System.Collections.List<uint8>();
		let transcoded = SceneTranscode.ToBinary(stream, scratch, bytes, true);
		capture.Stop();

		for (let line in capture.Lines)
			outReport.Warnings.Add(new String(line));
		if (transcoded case .Err(let error))
		{
			outReport.Valid = false;
			outReport.Error.Set(scope $"the scene stream did not parse ({error}) - fix the XML and validate again");
			return;
		}
		outReport.Valid = true;
		outReport.SceneName.Set(scratch.Name);
		outReport.EntityCount = (int)scratch.EntityCount;
		var root = scratch.FirstRoot;
		while (root.IsAssigned)
		{
			outReport.RootCount++;
			root = scratch.GetNextSibling(root);
		}
	}
}
