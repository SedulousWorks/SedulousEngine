using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Engine.Composition;

namespace Sedulous.Editor.Mcp;

/// Parses scene XML into a scratch scene carrying the FULL engine manager set, so component
/// payloads validate through their real managers exactly as the editor and the cooked scene
/// reader would parse them. Only a genuinely unknown component type is skipped, as a
/// warning the capture keeps.
static class SceneValidation
{
	/// Fills `outReport` from `xml`. The transcode is the same pass the export runs. With
	/// `outSourceText`, a valid scene also comes back as the source text the editor would save
	/// for it (a scene with its settings, a prefab without): what a write stores.
	public static void Parse(StringView xml, SceneParseReport outReport, String outSourceText = null,
		bool includeSettings = true)
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
		{
			// The transcode's binary half cannot carry a record of a type this host has no
			// code for, so it says it drops them; the source a write stores keeps them as they
			// are. The report says both, so an agent is not told its data went.
			if (line.Contains("unresolved component record(s) captured in the other encoding"))
			{
				outReport.Warnings.Add(new $"{scratch.UnresolvedComponents.Length} component record(s) of types this host has no code for: a write keeps them in the source as they are, but a cook by this host leaves them out of the cooked scene (the project's own editor has their code)");
				continue;
			}
			if (line.Contains("unresolved settings record(s) captured in the other encoding"))
			{
				outReport.Warnings.Add(new $"{scratch.UnresolvedSettingsRecords.Length} settings record(s) of systems this host has no code for: a write keeps them in the source as they are, but a cook by this host leaves them out of the cooked scene (the project's own editor has their code)");
				continue;
			}
			outReport.Warnings.Add(new String(line));
		}
		if (transcoded case .Err(let error))
		{
			outReport.Valid = false;
			outReport.Error.Set(scope $"the scene stream did not parse ({error}) - fix the XML and validate again");
			return;
		}
		if (outSourceText != null)
		{
			if (SceneStorage.SourceText(scratch, includeSettings, outSourceText) case .Err(let serializeError))
			{
				outReport.Valid = false;
				outReport.Error.Set(scope $"the scene parsed but did not serialize ({serializeError})");
				return;
			}
		}
		outReport.Valid = true;
		outReport.SceneName.Set(scratch.Name);
		outReport.EntityCount = (int)scratch.EntityCount;
		// The instances park unresolved: the parse has no database to spawn them from.
		scratch.ForEachPendingPrefabInstance(scope [&](pending) => { outReport.PrefabIds.Add(pending.PrefabId); });
		var root = scratch.FirstRoot;
		while (root.IsAssigned)
		{
			outReport.RootCount++;
			root = scratch.GetNextSibling(root);
		}
	}
}
