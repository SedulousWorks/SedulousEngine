using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Mcp;

/// The diagnostics tools: log_read / log_write / known_issues. The host adds ONE
/// EditorLogBuffer to the global logger first thing in main, so every line the engine logs
/// (cook warnings, scene load errors, subsystem output) is captured with a sequence;
/// log_read polls it incrementally, log_write drops an agent marker INTO the same stream
/// to correlate the agent's actions with the engine's output, and known_issues returns the
/// curated register so an agent checks whether a symptom is known before re-diagnosing it.
static class LogTools
{
	private class Context
	{
		public EditorLogBuffer Buffer;
		/// Resolved absolute path of KnownIssues.md, empty when not found: the tool then
		/// errs with guidance rather than being absent, so an agent learns why.
		public String KnownIssuesPath = new .() ~ delete _;
	}

	private static StringView[5] cLevels = .("trace", "debug", "info", "warning", "error");

	public static LogLevel ParseLevel(StringView name, LogLevel fallback)
	{
		switch (name)
		{
		case "trace": return .Trace;
		case "debug": return .Debug;
		case "info": return .Information;
		case "warning": return .Warning;
		case "error": return .Error;
		default: return fallback;
		}
	}

	public static StringView LevelName(LogLevel level)
	{
		switch (level)
		{
		case .Trace: return "trace";
		case .Debug: return "debug";
		case .Information: return "info";
		case .Warning: return "warning";
		case .Error: return "error";
		case .Critical: return "critical";
		default: return "none";
		}
	}

	public static void Register(McpServer server, EditorLogBuffer buffer, StringView knownIssuesPath)
	{
		let context = new Context();
		context.Buffer = buffer;
		context.KnownIssuesPath.Set(knownIssuesPath);

		let readSchema = scope SchemaBuilder();
		readSchema.Number("sinceSequence", "only entries with sequence > this (default 0 = everything buffered)");
		readSchema.Integer("limit", "maximum entries to return, newest kept (default 200)");
		readSchema.Enum("minLevel", cLevels, "only entries at or above this level (default trace = all)");
		readSchema.Str("category", "only entries with exactly this category (e.g. Cook, Scene)");
		server.RegisterTool("log_read",
			"""
			Read the host's captured engine log (cook warnings, scene-load errors, subsystem output, agent markers). Poll incrementally: pass the lastSequence from the previous call as sinceSequence to get only what is new. Returns the newest `limit` matching entries; `dropped` > 0 means the ring overflowed and old entries were lost.
			""",
			readSchema.Build(), .ReadOnly,
			new (arguments, outResult, outError) => Read(context, arguments, outResult),
			context);

		let writeSchema = scope SchemaBuilder();
		writeSchema.Str("message", "the marker text", true);
		writeSchema.Enum("level", cLevels, "log level (default info)");
		server.RegisterTool("log_write",
			"""
			Write a marker line into the host's engine log (category 'Agent'). Use it to correlate your actions with engine output: drop a marker before a risky operation, then log_read from the returned sequence to see exactly what the engine said afterwards.
			""",
			writeSchema.Build(), .Creates,
			new (arguments, outResult, outError) => Write(context, arguments, outResult, outError));

		server.RegisterTool("known_issues",
			"""
			The engine's curated known-issues register (read-only): user-visible limitations with impact and workaround. Check it when you hit an error or odd behavior BEFORE re-diagnosing: if the symptom matches a recorded issue, report the match and apply its workaround instead of proposing a fix for something already known or deliberately deferred.
			""",
			scope SchemaBuilder().Build(), .ReadOnly,
			new (arguments, outResult, outError) => KnownIssues(context, outResult, outError));
	}

	private static bool Read(Context context, JsonValue arguments, JsonValue outResult)
	{
		let since = (uint64)McpTools.ArgNumber(arguments, "sinceSequence", 0);
		let limitRaw = McpTools.ArgNumber(arguments, "limit", 0);
		let limit = limitRaw > 0 ? (int)limitRaw : 200;
		let minLevel = ParseLevel(McpTools.ArgString(arguments, "minLevel", .. scope .()), .Trace);
		let category = McpTools.ArgString(arguments, "category", .. scope .());

		let collected = scope List<EditorLogEntry>();
		defer { ClearAndDeleteItems(collected); }
		let lastSequence = context.Buffer.CollectSince(since, collected);

		let matching = scope List<EditorLogEntry>();
		for (let entry in collected)
		{
			if (entry.Level < minLevel)
				continue;
			if (!category.IsEmpty && (entry.Category != category))
				continue;
			matching.Add(entry);
		}
		let start = matching.Count > limit ? matching.Count - limit : 0;
		let entries = JsonValue.MakeArray();
		for (int i = start; i < matching.Count; i++)
		{
			let entry = matching[i];
			let json = JsonValue.MakeObject();
			json.Set("sequence", JsonValue.MakeNumber((double)entry.Sequence));
			json.Set("level", JsonValue.MakeString(LevelName(entry.Level)));
			json.Set("category", JsonValue.MakeString(entry.Category));
			json.Set("message", JsonValue.MakeString(entry.Message));
			entries.Add(json);
		}
		outResult.Set("entries", entries);
		outResult.Set("lastSequence", JsonValue.MakeNumber((double)lastSequence));
		outResult.Set("dropped", JsonValue.MakeNumber((double)context.Buffer.DroppedCount));
		return true;
	}

	private static bool Write(Context context, JsonValue arguments, JsonValue outResult, String outError)
	{
		let message = McpTools.ArgString(arguments, "message", .. scope .());
		if (message.IsEmpty)
		{
			outError.Append("message must not be empty");
			return false;
		}
		let level = ParseLevel(McpTools.ArgString(arguments, "level", .. scope .()), .Information);
		// Through the global logger, so the marker lands in every sink the host has, the
		// stderr mirror included, and not only in the buffer.
		GlobalLog(level, "Agent: {}", message);
		outResult.Set("written", JsonValue.MakeBool(true));
		outResult.Set("sequence", JsonValue.MakeNumber((double)context.Buffer.LatestSequence));
		return true;
	}

	private static bool KnownIssues(Context context, JsonValue outResult, String outError)
	{
		if (context.KnownIssuesPath.IsEmpty)
		{
			outError.Append("KnownIssues.md was not found near the host executable - run the MCP host from inside the engine checkout");
			return false;
		}
		let bytes = scope List<uint8>();
		if (ReadFile(context.KnownIssuesPath, bytes) case .Err)
		{
			outError.AppendF("could not read '{}'", context.KnownIssuesPath);
			return false;
		}
		outResult.Set("path", JsonValue.MakeString(context.KnownIssuesPath));
		outResult.Set("text", JsonValue.MakeString(StringView((char8*)bytes.Ptr, bytes.Count)));
		return true;
	}
}
