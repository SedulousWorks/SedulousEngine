using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Json;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.Mcp;

/// A build job as the MCP tools answer it: project_build's and build_status's build, and the
/// player's build in project_export's answer, one shape for all three.
static class BuildJobJson
{
	/// How many diagnostics a build lists by default, errors first; the counts say how many
	/// there are.
	public const int cMaxDiagnostics = 50;

	/// `job` into `outResult`: {id, target, state, steps, step, error, durationMs, errorCount,
	/// warningCount, diagnostics (errors first, at most `maxDiagnostics`), diagnosticsOmitted,
	/// executables}.
	public static void Write(BuildJob job, JsonValue outResult, int maxDiagnostics = cMaxDiagnostics)
	{
		let state = job.State;
		outResult.Set("id", JsonValue.MakeNumber(job.Id));
		outResult.Set("target", JsonValue.MakeString(TargetName(job.Target)));
		outResult.Set("state", JsonValue.MakeString(StateName(state)));
		let game = ProjectBuild.GameName(job.Settings.Name, .. scope .());
		let steps = JsonValue.MakeArray();
		for (int i < job.StepCount)
			steps.Add(StepJson(ProjectBuild.EntryName(game, job.StepEntry(i), .. scope .()), job.StepConfig(i)));
		outResult.Set("steps", steps);
		let project = scope String();
		let config = scope String();
		job.GetStep(project, config);
		outResult.Set("step", project.IsEmpty ? JsonValue.MakeNull() : StepJson(project, config));
		let error = job.GetError(.. scope .());
		if (!error.IsEmpty)
			outResult.Set("error", JsonValue.MakeString(error));
		outResult.Set("durationMs", JsonValue.MakeNumber((double)job.DurationMs));
		DiagnosticsJson(job, outResult, maxDiagnostics);
		let made = scope List<String>();
		defer { ClearAndDeleteItems!(made); }
		job.GetExecutables(made);
		let executables = JsonValue.MakeArray();
		for (let path in made)
			executables.Add(JsonValue.MakeString(path));
		outResult.Set("executables", executables);
	}

	private static JsonValue StepJson(StringView project, StringView config)
	{
		let step = JsonValue.MakeObject();
		step.Set("project", JsonValue.MakeString(project));
		step.Set("config", JsonValue.MakeString(config));
		return step;
	}

	/// The job's counts and its diagnostics, errors first, at most `maxDiagnostics`, each file
	/// relative to the project when inside it.
	private static void DiagnosticsJson(BuildJob job, JsonValue outResult, int maxDiagnostics)
	{
		let diagnostics = scope List<BuildDiagnostic>();
		defer { ClearAndDeleteItems!(diagnostics); }
		job.GetDiagnostics(diagnostics);
		let projectDir = Absolute(job.ProjectDirectory, .. scope .());
		int errors = 0;
		for (let diagnostic in diagnostics)
		{
			if (diagnostic.Severity == .Error)
				errors++;
		}
		let list = JsonValue.MakeArray();
		for (let severity in BuildSeverity[2](.Error, .Warning))
		{
			for (let diagnostic in diagnostics)
			{
				if (list.Count >= maxDiagnostics)
					break;
				if (diagnostic.Severity == severity)
					list.Add(DiagnosticJson(diagnostic, projectDir));
			}
		}
		outResult.Set("errorCount", JsonValue.MakeNumber(errors));
		outResult.Set("warningCount", JsonValue.MakeNumber(diagnostics.Count - errors));
		outResult.Set("diagnostics", list);
		outResult.Set("diagnosticsOmitted", JsonValue.MakeNumber(diagnostics.Count - list.Count));
	}

	private static JsonValue DiagnosticJson(BuildDiagnostic diagnostic, StringView projectDir)
	{
		let json = JsonValue.MakeObject();
		json.Set("severity", JsonValue.MakeString((diagnostic.Severity == .Error) ? "error" : "warning"));
		if (diagnostic.HasPlace)
		{
			json.Set("file", JsonValue.MakeString(RelativeFile(diagnostic.File, projectDir, .. scope .())));
			json.Set("line", JsonValue.MakeNumber(diagnostic.Line));
			json.Set("column", JsonValue.MakeNumber(diagnostic.Column));
		}
		if (!diagnostic.Code.IsEmpty)
			json.Set("code", JsonValue.MakeString(diagnostic.Code));
		json.Set("message", JsonValue.MakeString(diagnostic.Message));
		if (!diagnostic.Notes.IsEmpty)
		{
			let notes = JsonValue.MakeArray();
			for (let note in diagnostic.Notes)
			{
				let noteJson = JsonValue.MakeObject();
				noteJson.Set("message", JsonValue.MakeString(note.Message));
				if (!note.File.IsEmpty)
				{
					noteJson.Set("file", JsonValue.MakeString(RelativeFile(note.File, projectDir, .. scope .())));
					noteJson.Set("line", JsonValue.MakeNumber(note.Line));
					noteJson.Set("column", JsonValue.MakeNumber(note.Column));
				}
				notes.Add(noteJson);
			}
			json.Set("notes", notes);
		}
		return json;
	}

	/// `file` relative to `projectDir` when it lies inside it, as it is otherwise (an engine
	/// file BeefBuild compiled beside the game's).
	public static void RelativeFile(StringView file, StringView projectDir, String outPath)
	{
		if (!projectDir.IsEmpty && (file.Length > projectDir.Length + 1) && file.StartsWith(projectDir) && PathIsSeparator(file[projectDir.Length]))
			outPath.Set(file.Substring(projectDir.Length + 1));
		else
			outPath.Set(file);
	}

	/// `path` against the current directory when relative, less its trailing separators: the
	/// form BeefBuild names files in.
	private static void Absolute(StringView path, String outPath)
	{
		if (path.IsEmpty || PathIsAbsolute(path))
			outPath.Set(path);
		else
			PathJoin(GetCurrentDirectory(.. scope .()), path, outPath);
		while ((outPath.Length > 1) && PathIsSeparator(outPath[outPath.Length - 1]))
			outPath.RemoveFromEnd(1);
	}

	public static StringView TargetName(BuildTarget target)
	{
		switch (target)
		{
		case .Editor: return "editor";
		default: return "player";
		}
	}

	public static StringView StateName(BuildJobState state)
	{
		switch (state)
		{
		case .Queued: return "queued";
		case .Generating: return "generating";
		case .Building: return "building";
		case .Succeeded: return "succeeded";
		case .Failed: return "failed";
		default: return "cancelled";
		}
	}
}
