using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Content;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Runtime;
using Sedulous.Editor.Project;
using Sedulous.Editor.Mcp;

namespace Dialogue;

/// Dialogue.Tooling: the Tooling part of the engine's official dialogue package, which the editor,
/// the exporter and the MCP host load. It adds two MCP tools that every MCP host serves while the
/// plugin is loaded, over the open project:
///   * dialogue_validate: the cook's checks over one dialogue file or every one, each problem with
///     its line, without cooking.
///   * dialogue_read: one dialogue file's conversations as the cook reads them: their lines with
///     ids, choices, commands, jumps and the flags each reads and writes.
/// Writing stays the text's (asset_data_write, or the file itself), then dialogue_validate.
[AlwaysInclude]
class DialogueToolingPart : PluginPart
{
	public const String cManifest = Compiler.ReadText("../Plugin.xml");
	public const String cValidateTool = "dialogue_validate";
	public const String cReadTool = "dialogue_read";

	static this()
	{
		PluginRegistry.Register(new DialogueToolingPart());
	}

	public override StringView PluginId => "dialogue";
	public override PluginPartKind Kind => .Tooling;
	public override StringView ManifestXml => cManifest;

	public override void Load(PluginContext context)
	{
		let tools = context.Find<McpPluginServices>();
		let settings = context.Settings<DialogueSettings>();
		if ((tools == null) || (settings == null))
			return;
		tools.AddTools(new (target) =>
			{
				let session = target.Session;
				target.RegisterTool(cValidateTool,
					"The cook's checks over a dialogue file (`asset`, its guid) or, with no `asset`, every one in the open project, without cooking: each file's problems with their lines (errors stop its cook; warnings do not). Run it after writing a dialogue file's text.",
					scope SchemaBuilder().Str("asset", "A dialogue file's guid; none checks every one").Build(), .ReadOnly,
					new (arguments, outResult, outError) => Validate(session, settings, arguments, outResult, outError));
				target.RegisterTool(cReadTool,
					"A dialogue file's conversations as the cook reads them (`asset`, its guid): each conversation's lines with their ids, speakers and texts, its choices and their answers, its commands with their arguments, its jumps, and the flags it reads and writes; and the file's problems.",
					scope SchemaBuilder().Str("asset", "A dialogue file's guid", true).Build(), .ReadOnly,
					new (arguments, outResult, outError) => Read(session, settings, arguments, outResult, outError));
			});
	}

	static bool Validate(ProjectSession session, DialogueSettings settings, JsonValue arguments, JsonValue outResult, String outError)
	{
		if (!session.IsOpen)
		{
			outError.Append(McpTools.cNoProject);
			return false;
		}
		let project = session.Project;
		let files = scope List<Instance>();
		let given = arguments.Get("asset");
		if ((given != null) && !given.AsString().IsEmpty)
		{
			let one = FileArgument(project, arguments, outError);
			if (one == null)
				return false;
			files.Add(one);
		}
		else if (let root = project.SourceDb.RootGroup)
			DialogueProject.DialogueAssetsOf(root, files);
		let results = JsonValue.MakeArray();
		int errors = 0;
		let error = scope String();
		for (let instance in files)
		{
			let result = JsonValue.MakeObject();
			result.Set("asset", JsonValue.MakeString(instance.Id.ToString(.. scope .())));
			result.Set("name", JsonValue.MakeString(instance.Name));
			let parse = scope DialogueParse();
			if (Check(project, settings, instance, parse, error..Clear()))
			{
				int fileErrors = 0;
				result.Set("problems", Problems(parse, ref fileErrors));
				result.Set("ok", JsonValue.MakeBool(fileErrors == 0));
				errors += fileErrors;
			}
			else
			{
				result.Set("ok", JsonValue.MakeBool(false));
				result.Set("error", JsonValue.MakeString(error));
				errors++;
			}
			results.Add(result);
		}
		outResult.Set("files", results);
		outResult.Set("errors", JsonValue.MakeNumber(errors));
		return true;
	}

	static bool Read(ProjectSession session, DialogueSettings settings, JsonValue arguments, JsonValue outResult, String outError)
	{
		if (!session.IsOpen)
		{
			outError.Append(McpTools.cNoProject);
			return false;
		}
		let instance = FileArgument(session.Project, arguments, outError);
		if (instance == null)
			return false;
		let parse = scope DialogueParse();
		if (!Check(session.Project, settings, instance, parse, outError))
			return false;
		let conversations = JsonValue.MakeArray();
		for (let conversation in parse.Conversations)
			conversations.Add(Conversation(parse, conversation));
		int errors = 0;
		outResult.Set("asset", JsonValue.MakeString(instance.Id.ToString(.. scope .())));
		outResult.Set("name", JsonValue.MakeString(instance.Name));
		outResult.Set("conversations", conversations);
		outResult.Set("problems", Problems(parse, ref errors));
		return true;
	}

	/// The dialogue file `instance`'s text, checked as the cook checks it, into `outParse`; false
	/// when its source cannot be read (`outError` says why).
	static bool Check(EditorProject project, DialogueSettings settings, Instance instance, DialogueParse outParse, String outError)
	{
		let stored = instance.ReadObject();
		defer { delete stored; }
		let file = stored as DialogueAsset;
		if (file == null)
		{
			outError.Append("not a dialogue file");
			return false;
		}
		DialogueSourceReader read = scope (fileName, outText) =>
			{
				let bytes = scope List<uint8>();
				if (ReadFile(project.SourceFile(fileName, .. scope .()), bytes) case .Err)
					return false;
				if (!bytes.IsEmpty)
					outText.Append(StringView((char8*)bytes.Ptr, bytes.Count));
				return true;
			};
		let text = scope String();
		if (!read(file.FileName.Value, text))
		{
			outError.AppendF("its source {} is missing", file.FileName.Value);
			return false;
		}
		DialogueCook.CheckDialogueText(text, settings, instance.Id, project.SourceDb, read, outParse);
		return true;
	}

	/// The file's problems, each with its line and severity; its errors counted into `errors`.
	static JsonValue Problems(DialogueParse parse, ref int errors)
	{
		let problems = JsonValue.MakeArray();
		for (let problem in parse.Problems)
		{
			let entry = JsonValue.MakeObject();
			entry.Set("line", JsonValue.MakeNumber(problem.Line));
			entry.Set("severity", JsonValue.MakeString(problem.Warning ? "warning" : "error"));
			entry.Set("message", JsonValue.MakeString(problem.Message));
			problems.Add(entry);
			if (!problem.Warning)
				errors++;
		}
		return problems;
	}

	static JsonValue Strings(List<String> values)
	{
		let array = JsonValue.MakeArray();
		for (let value in values)
			array.Add(JsonValue.MakeString(value));
		return array;
	}

	static void AddOnce(List<String> list, StringView value)
	{
		for (let seen in list)
		{
			if (seen == value)
				return;
		}
		list.Add(new .(value));
	}

	static StringView TextOf(DialogueParse parse, StringView id)
	{
		for (let line in parse.Lines)
		{
			if (line.Id == id)
				return line.Text;
		}
		return "";
	}

	/// A conversation as dialogue_read gives it.
	static JsonValue Conversation(DialogueParse parse, DialogueConversation conversation)
	{
		let lines = JsonValue.MakeArray();
		let choices = JsonValue.MakeArray();
		let commands = JsonValue.MakeArray();
		let jumps = JsonValue.MakeArray();
		let reads = scope List<String>();
		defer { ClearAndDeleteItems!(reads); }
		let writes = scope List<String>();
		defer { ClearAndDeleteItems!(writes); }
		let steps = conversation.Steps;
		for (int i < steps.Count)
		{
			let step = steps[i];
			switch (step.Kind)
			{
			case .Line:
				let line = JsonValue.MakeObject();
				line.Set("id", JsonValue.MakeString(step.LineId));
				line.Set("line", JsonValue.MakeNumber(step.SourceLine));
				line.Set("speaker", JsonValue.MakeString(step.Speaker));
				if (!step.Mood.IsEmpty)
					line.Set("mood", JsonValue.MakeString(step.Mood));
				line.Set("text", JsonValue.MakeString(TextOf(parse, step.LineId)));
				lines.Add(line);
			case .Choice:
				let answers = JsonValue.MakeArray();
				for (int a = 1; (a <= step.Count) && (i + a < steps.Count); a++)
				{
					let answer = JsonValue.MakeObject();
					answer.Set("id", JsonValue.MakeString(steps[i + a].LineId));
					answer.Set("text", JsonValue.MakeString(TextOf(parse, steps[i + a].LineId)));
					answers.Add(answer);
				}
				let choice = JsonValue.MakeObject();
				choice.Set("line", JsonValue.MakeNumber(step.SourceLine));
				choice.Set("answers", answers);
				choices.Add(choice);
			case .Command:
				let given = JsonValue.MakeObject();
				for (let argument in step.Arguments)
				{
					if (argument.Present)
						given.Set(argument.Name, JsonValue.MakeString(argument.Text));
				}
				let command = JsonValue.MakeObject();
				command.Set("name", JsonValue.MakeString(step.Name));
				command.Set("line", JsonValue.MakeNumber(step.SourceLine));
				command.Set("arguments", given);
				if (step.Waits)
					command.Set("waits", JsonValue.MakeBool(true));
				if (step.Leaves)
					command.Set("leaves", JsonValue.MakeBool(true));
				commands.Add(command);
			case .Jump:
				if (step.File.IsEmpty)
					jumps.Add(JsonValue.MakeString(step.Name));
				else
					jumps.Add(JsonValue.MakeString(scope $"{step.Name} in {step.File}"));
			case .If:
				AddOnce(reads, step.Flag);
			case .Set, .Clear:
				AddOnce(writes, step.Flag);
			default:
				break;
			}
		}
		let result = JsonValue.MakeObject();
		result.Set("id", JsonValue.MakeString(conversation.Id));
		if (!conversation.Level.IsEmpty)
			result.Set("level", JsonValue.MakeString(conversation.Level));
		result.Set("lines", lines);
		result.Set("choices", choices);
		result.Set("commands", commands);
		result.Set("jumps", jumps);
		result.Set("flagsRead", Strings(reads));
		result.Set("flagsWritten", Strings(writes));
		return result;
	}

	/// The dialogue file the `asset` argument names (its guid), or null with `outError` saying why.
	static Instance FileArgument(EditorProject project, JsonValue arguments, String outError)
	{
		let given = arguments.Get("asset");
		let text = (given != null) ? given.AsString() : "";
		Guid id = .();
		if (Guid.Parse(text) case .Ok(let parsed))
			id = parsed;
		else
		{
			outError.Append("`asset` is a dialogue file's guid");
			return null;
		}
		let instance = project.SourceDb.GetInstance(id);
		if ((instance == null) || (instance.TypeName != typeof(DialogueAsset).GetFullName(.. scope .())))
		{
			outError.AppendF("no dialogue file {}", text);
			return null;
		}
		return instance;
	}
}
