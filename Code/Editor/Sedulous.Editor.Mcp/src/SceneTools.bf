using System;
using Sedulous.Core;
using Sedulous.Content;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Scene.Resource;

namespace Sedulous.Editor.Mcp;

/// scene_read / scene_write / scene_validate + prefab_read / prefab_write, over the XML
/// TEXT sources: files are truth and the editor is not involved. This is what makes an agent
/// scene capable headlessly, structural authoring through the same stream the editor saves.
///
/// Writes validate FIRST and refuse with the reasons; a passing write stores the agent's XML
/// verbatim, since the reader accepted it and the editor and the cook will too.
static class SceneTools
{
	/// One read/write pair's identity, owned by its tools.
	private class Document
	{
		public ProjectSession Session;
		public String WantedType = new .() ~ delete _;
		public String Sibling = new .() ~ delete _;
		public String Kind = new .() ~ delete _;
		public bool SingleRoot = false;
	}

	public static void Register(McpServer server, ProjectSession session)
	{
		RegisterRead(server, session, "scene_read", McpTools.cSceneDocument, "prefab_read", "scene");
		RegisterRead(server, session, "prefab_read", McpTools.cPrefabDocument, "scene_read", "prefab");

		let validateSchema = scope SchemaBuilder();
		validateSchema.Str("xml", "scene XML text to validate");
		validateSchema.Str("guid", "a scene/prefab asset guid whose stored stream to validate");
		server.RegisterTool("scene_validate",
			"""
			Validate scene/prefab XML without writing anything - use this as the validation loop when authoring scenes. Pass `xml` (raw text) OR `guid` (validate the stored stream). Returns {valid, error?, warnings[], sceneName, entityCount, rootCount}. Component payloads are parsed through every engine manager, so a warning names a genuinely unknown component type.
			""",
			validateSchema.Build(), .ReadOnly,
			new (arguments, outResult, outError) => Validate(session, arguments, outResult, outError));

		RegisterWrite(server, session, "scene_write", McpTools.cSceneDocument, "prefab_write", "scene", false);
		RegisterWrite(server, session, "prefab_write", McpTools.cPrefabDocument, "scene_write", "prefab", true);
	}

	private static Document MakeDocument(ProjectSession session, StringView wantedType, StringView sibling,
		StringView kind, bool singleRoot)
	{
		let document = new Document();
		document.Session = session;
		document.WantedType.Set(wantedType);
		document.Sibling.Set(sibling);
		document.Kind.Set(kind);
		document.SingleRoot = singleRoot;
		return document;
	}

	private static void RegisterRead(McpServer server, ProjectSession session, StringView tool,
		StringView wantedType, StringView sibling, StringView kind)
	{
		let document = MakeDocument(session, wantedType, sibling, kind, false);
		let schema = scope SchemaBuilder();
		schema.Str("guid", scope $"the {kind} asset's guid", true);
		server.RegisterTool(tool,
			scope $"Read a {kind}'s XML source (the exact text the editor saves and the cook consumes). Returns {{name, xml}}. Read this before editing; write changes back with {kind}_write.",
			schema.Build(), .ReadOnly,
			new (arguments, outResult, outError) => Read(document, arguments, outResult, outError),
			document);
	}

	private static void RegisterWrite(McpServer server, ProjectSession session, StringView tool,
		StringView wantedType, StringView sibling, StringView kind, bool singleRoot)
	{
		let document = MakeDocument(session, wantedType, sibling, kind, singleRoot);
		let schema = scope SchemaBuilder();
		schema.Str("xml", scope $"the {kind} XML text to store", true);
		schema.Str("guid", scope $"an existing {kind} asset to overwrite");
		schema.Str("name", "name for a NEW asset (when no guid)");
		schema.Str("group", "slash-joined group path for a NEW asset (default root)");
		server.RegisterTool(tool,
			scope $"Write a {kind}'s XML source. VALIDATES FIRST and refuses with the reasons on failure (nothing is written then). Pass `guid` to overwrite an existing {kind} OR `name` (+ optional `group` path) to create a new one. On success the XML is stored verbatim as the asset's source of truth.",
			schema.Build(), .Overwrites,
			new (arguments, outResult, outError) => Write(document, arguments, outResult, outError),
			document);
	}

	/// {guid} resolved to an instance of the wanted document type; a wrong type hit says
	/// which sibling tool to use instead.
	private static Instance ResolveDocument(Document document, StringView guidText, String outError)
	{
		if (!document.Session.IsOpen)
		{
			outError.Append(McpTools.cNoProject);
			return null;
		}
		if (!McpTools.ParseGuid(guidText, outError, let id))
			return null;
		let instance = document.Session.Project.SourceDb.GetInstance(id);
		if (instance == null)
		{
			outError.AppendF("no asset with guid {} in the open project", guidText);
			return null;
		}
		if (instance.TypeName != document.WantedType)
		{
			outError.AppendF("'{}' is a {}, not a {} - use {} instead", instance.Name, instance.TypeName,
				document.WantedType, document.Sibling);
			return null;
		}
		return instance;
	}

	private static bool Read(Document document, JsonValue arguments, JsonValue outResult, String outError)
	{
		let instance = ResolveDocument(document, McpTools.ArgString(arguments, "guid", .. scope .()), outError);
		if (instance == null)
			return false;
		let xml = scope String();
		if (!McpTools.ReadSceneStream(instance, xml))
		{
			outError.AppendF("'{}' has no scene stream (never saved?)", instance.Name);
			return false;
		}
		outResult.Set("name", JsonValue.MakeString(instance.Name));
		outResult.Set("xml", JsonValue.MakeString(xml));
		return true;
	}

	private static bool Validate(ProjectSession session, JsonValue arguments, JsonValue outResult, String outError)
	{
		let xml = McpTools.ArgString(arguments, "xml", .. scope .());
		let guidText = McpTools.ArgString(arguments, "guid", .. scope .());
		if (xml.IsEmpty == guidText.IsEmpty)
		{
			outError.Append("pass exactly one of `xml` (text to validate) or `guid` (stored stream to validate)");
			return false;
		}
		if (!guidText.IsEmpty)
		{
			if (!session.IsOpen)
			{
				outError.Append(McpTools.cNoProject);
				return false;
			}
			if (!McpTools.ParseGuid(guidText, outError, let id))
				return false;
			let instance = session.Project.SourceDb.GetInstance(id);
			if (instance == null)
			{
				outError.AppendF("no asset with guid {} in the open project", guidText);
				return false;
			}
			if (!McpTools.ReadSceneStream(instance, xml))
			{
				outError.AppendF("'{}' has no scene stream to validate", instance.Name);
				return false;
			}
		}
		let report = scope SceneParseReport();
		SceneValidation.Parse(xml, report);
		let json = report.ToJson();
		defer delete json;
		for (let key in json.Keys)
			outResult.Set(key, json.Get(key).Clone());
		return true;
	}

	private static bool Write(Document document, JsonValue arguments, JsonValue outResult, String outError)
	{
		let session = document.Session;
		if (!session.IsOpen)
		{
			outError.Append(McpTools.cNoProject);
			return false;
		}
		let xml = McpTools.ArgString(arguments, "xml", .. scope .());
		if (xml.IsEmpty)
		{
			outError.Append("`xml` is required and was empty");
			return false;
		}
		let report = scope SceneParseReport();
		SceneValidation.Parse(xml, report);
		if (!report.Valid)
		{
			let refusal = report.ToJson();
			defer delete refusal;
			outError.AppendF("refused - the XML did not validate: {}. Full report: {}", report.Error,
				refusal.ToString(.. scope .()));
			return false;
		}
		if (document.SingleRoot && (report.RootCount != 1))
		{
			outError.AppendF("refused - a prefab must have exactly ONE root entity (found {}); re-parent the extra roots under one root first", report.RootCount);
			return false;
		}

		let guidText = McpTools.ArgString(arguments, "guid", .. scope .());
		Instance instance = null;
		if (!guidText.IsEmpty)
		{
			instance = ResolveDocument(document, guidText, outError);
			if (instance == null)
				return false;
		}
		else
		{
			let name = McpTools.ArgString(arguments, "name", .. scope .());
			if (name.IsEmpty)
			{
				outError.Append("pass `guid` (overwrite existing) or `name` (create new)");
				return false;
			}
			let group = McpTools.ResolveGroupPath(session.Project.SourceDb.RootGroup,
				McpTools.ArgString(arguments, "group", .. scope .()));
			// CreateInstance hands back an existing same named instance, which a NEW asset
			// must never silently overwrite: overwriting is what `guid` is for.
			if (group.GetInstance(name) != null)
			{
				outError.AppendF("'{}' already exists in that group - pass its guid to overwrite it, or another name", name);
				return false;
			}
			instance = group.CreateInstance(name, document.WantedType);
			if (instance == null)
			{
				outError.AppendF("could not create '{}'", name);
				return false;
			}
		}

		// The primary document, for name discovery, then the verbatim XML stream.
		let documentName = report.SceneName.IsEmpty ? StringView(instance.Name) : StringView(report.SceneName);
		Result<void, ErrorCode> wroteObject;
		if (document.WantedType == McpTools.cSceneDocument)
		{
			let doc = scope SceneDocument();
			doc.Name.Set(documentName);
			wroteObject = instance.WriteObject(doc);
		}
		else
		{
			let doc = scope PrefabDocument();
			doc.Name.Set(documentName);
			wroteObject = instance.WriteObject(doc);
		}
		if (wroteObject case .Err)
		{
			outError.AppendF("failed writing the {} document envelope", document.Kind);
			return false;
		}
		if (instance.WriteData(SceneStorage.cStreamName, .((uint8*)xml.Ptr, xml.Length), .Text) case .Err)
		{
			outError.Append("failed writing the scene stream to disk");
			return false;
		}

		let json = report.ToJson();
		defer delete json;
		for (let key in json.Keys)
			outResult.Set(key, json.Get(key).Clone());
		outResult.Set("guid", McpTools.GuidToJson(instance.Id));
		outResult.Set("name", JsonValue.MakeString(instance.Name));
		outResult.Set("written", JsonValue.MakeBool(true));
		if (document.Session.OnAssetWritten != null)
			document.Session.OnAssetWritten(instance.Id);
		return true;
	}
}
