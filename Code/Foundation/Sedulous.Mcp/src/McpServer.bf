using System;
using System.Collections;
using Sedulous.Json;

namespace Sedulous.Mcp;

/// The protocol layer: JSON-RPC 2.0, the MCP lifecycle, and the tool and resource registry.
///
/// Transport abstract on purpose. Tools and resources REGISTER against a server rather than
/// being switched on inside it, so a host contributes what it has without this layer knowing
/// what hosts exist.
///
/// Implements the v1 subset: initialize, ping, tools/list, tools/call, resources/list and
/// resources/read.
class McpServer
{
	/// The pinned protocol revision. A client asking for another is answered with THIS one,
	/// because it is the only one this server actually speaks.
	public const String ProtocolVersion = "2025-06-18";

	private List<Tool> mTools = new .() ~ DeleteContainerAndItems!(_);
	private List<Resource> mResources = new .() ~ DeleteContainerAndItems!(_);
	private List<ResourceProvider> mProviders = new .() ~ DeleteContainerAndItems!(_);
	private String mServerName = new .("engine-mcp") ~ delete _;
	private String mServerVersion = new .("0.1.0") ~ delete _;

	public StringView ServerName => mServerName;
	public StringView ServerVersion => mServerVersion;
	public int ToolCount => mTools.Count;
	public int ResourceCount => mResources.Count;

	public void SetServerInfo(StringView name, StringView version)
	{
		mServerName.Set(name);
		mServerVersion.Set(version);
	}

	/// Registers a tool. OWNERSHIP of the schema and the handler transfers.
	/// The context, when given, is owned by the tool and deleted with it: a handler's closure
	/// cannot clean up after itself.
	public void RegisterTool(StringView name, StringView description, JsonValue inputSchema,
		Tool.Handler handler, Object context = null)
	{
		mTools.Add(new Tool(name, description, inputSchema, handler, context));
	}

	/// Registers a static resource. OWNERSHIP of the reader transfers.
	public void RegisterResource(StringView uri, StringView name, StringView mimeType,
		StringView description, Resource.Reader reader)
	{
		mResources.Add(new Resource(uri, name, mimeType, description, reader));
	}

	/// Registers a dynamic set. OWNERSHIP transfers.
	public void RegisterResourceProvider(ResourceProvider provider)
	{
		mProviders.Add(provider);
	}

	/// Handles ONE message, appending the response line to outResponse.
	///
	/// False for a NOTIFICATION, which by definition gets no reply. Malformed input never
	/// throws: it becomes a protocol error line, because a crash on bad input is a denial of
	/// service on a process an agent is driving.
	public bool HandleLine(StringView line, String outResponse)
	{
		let parsed = scope JsonParseResult();
		JsonParser.Parse(line, parsed);

		if (!parsed.Ok)
			return WriteError(null, .ParseError, "Parse error", outResponse);

		let message = parsed.Value;
		// A top level array is a batch, which later revisions of the specification dropped.
		if (message.IsArray)
			return WriteError(null, .InvalidRequest, "Batch requests are not supported",
				outResponse);
		if (!message.IsObject)
			return WriteError(null, .InvalidRequest, "Invalid Request", outResponse);

		let method = message.Get("method");
		let id = message.Get("id");
		let hasId = message.Has("id");

		if ((method == null) || !method.IsString)
		{
			if (hasId)
				return WriteError(id, .InvalidRequest,
					"Invalid Request: 'method' must be a string", outResponse);
			// A malformed notification is ignored, which is what JSON-RPC asks for.
			return false;
		}

		// No id means a notification. Every one of them, including initialized and cancelled,
		// is accepted SILENTLY.
		if (!hasId)
			return false;

		let response = Dispatch(method.AsString(), message.Get("params"), id);
		defer delete response;
		response.ToString(outResponse);
		return true;
	}

	// ---- Dispatch ---------------------------------------------------------------------------

	private JsonValue Dispatch(StringView method, JsonValue parameters, JsonValue id)
	{
		switch (method)
		{
		case "initialize": return Initialize(id);
		case "ping": return MakeResult(id, JsonValue.MakeObject());
		case "tools/list": return ToolsList(id);
		case "tools/call": return ToolsCall(id, parameters);
		case "resources/list": return ResourcesList(id);
		case "resources/read": return ResourcesRead(id, parameters);
		default:
			return MakeError(id, .MethodNotFound, scope $"method not found: {method}");
		}
	}

	private JsonValue Initialize(JsonValue id)
	{
		let result = JsonValue.MakeObject();
		result.Set("protocolVersion", JsonValue.MakeString(ProtocolVersion));

		let capabilities = JsonValue.MakeObject();
		// Present but empty: the presence of the key is what advertises the capability.
		capabilities.Set("tools", JsonValue.MakeObject());
		capabilities.Set("resources", JsonValue.MakeObject());
		result.Set("capabilities", capabilities);

		let info = JsonValue.MakeObject();
		info.Set("name", JsonValue.MakeString(mServerName));
		info.Set("version", JsonValue.MakeString(mServerVersion));
		result.Set("serverInfo", info);

		return MakeResult(id, result);
	}

	private JsonValue ToolsList(JsonValue id)
	{
		let tools = JsonValue.MakeArray();
		for (let tool in mTools)
		{
			let entry = JsonValue.MakeObject();
			entry.Set("name", JsonValue.MakeString(tool.Name));
			entry.Set("description", JsonValue.MakeString(tool.Description));
			entry.Set("inputSchema", tool.InputSchema.Clone());
			tools.Add(entry);
		}

		let result = JsonValue.MakeObject();
		result.Set("tools", tools);
		return MakeResult(id, result);
	}

	private JsonValue ToolsCall(JsonValue id, JsonValue parameters)
	{
		let name = (parameters != null) ? parameters.Get("name") : null;
		if ((name == null) || !name.IsString)
			return MakeError(id, .InvalidParams, "tools/call requires a string 'name'");

		let tool = FindTool(name.AsString());
		if (tool == null)
			return MakeError(id, .InvalidParams, scope $"unknown tool '{name.AsString()}'");

		// Absent arguments are an empty object, so a tool taking none needs no special case.
		var arguments = parameters.Get("arguments");
		JsonValue owned = null;
		defer delete owned;
		if ((arguments == null) || arguments.IsNull)
		{
			owned = JsonValue.MakeObject();
			arguments = owned;
		}

		let schemaError = scope String();
		if (!McpSchema.ValidateArgs(arguments, tool.InputSchema, schemaError))
			return MakeError(id, .InvalidParams, schemaError);

		// BOTH outcomes are successful JSON-RPC responses. A tool that fails is reported as
		// error CONTENT, because the failure is the agent's business rather than the
		// protocol's.
		let item = JsonValue.MakeObject();
		item.Set("type", JsonValue.MakeString("text"));

		let result = JsonValue.MakeObject();
		let toolResult = JsonValue.MakeObject();
		defer delete toolResult;
		let toolError = scope String();

		if (tool.Run(arguments, toolResult, toolError))
		{
			item.Set("text", JsonValue.MakeString(toolResult.ToString(.. scope String())));
			result.Set("isError", JsonValue.MakeBool(false));
		}
		else
		{
			item.Set("text", JsonValue.MakeString(toolError));
			result.Set("isError", JsonValue.MakeBool(true));
		}

		let content = JsonValue.MakeArray();
		content.Add(item);
		result.Set("content", content);
		return MakeResult(id, result);
	}

	private JsonValue ResourcesList(JsonValue id)
	{
		let dynamic = scope List<Resource>();
		defer { ClearAndDeleteItems!(dynamic); }
		for (let provider in mProviders)
			provider.List(dynamic);

		let entries = JsonValue.MakeArray();
		for (let resource in mResources)
			entries.Add(DescribeResource(resource));
		for (let resource in dynamic)
			entries.Add(DescribeResource(resource));

		let result = JsonValue.MakeObject();
		result.Set("resources", entries);
		return MakeResult(id, result);
	}

	private JsonValue ResourcesRead(JsonValue id, JsonValue parameters)
	{
		let uriValue = (parameters != null) ? parameters.Get("uri") : null;
		if ((uriValue == null) || !uriValue.IsString)
			return MakeError(id, .InvalidParams, "resources/read requires a string 'uri'");

		let uri = scope String(uriValue.AsString());
		let text = scope String();
		let error = scope String();
		let mimeType = scope String();

		if (let resource = FindResource(uri))
		{
			mimeType.Set(resource.MimeType);
			if ((resource.Read == null) || !resource.Read(text, error))
				return MakeError(id, .InternalError, error);
		}
		else if (!ReadFromProviders(uri, text, error, mimeType))
		{
			return error.IsEmpty
				? MakeError(id, .InvalidParams, scope $"unknown resource '{uri}'")
				: MakeError(id, .InternalError, error);
		}

		let entry = JsonValue.MakeObject();
		entry.Set("uri", JsonValue.MakeString(uri));
		entry.Set("mimeType", JsonValue.MakeString(mimeType));
		entry.Set("text", JsonValue.MakeString(text));

		let contents = JsonValue.MakeArray();
		contents.Add(entry);

		let result = JsonValue.MakeObject();
		result.Set("contents", contents);
		return MakeResult(id, result);
	}

	/// Offers the uri to each provider in turn. True when one answered; an error left behind
	/// means a provider CLAIMED the uri and failed, which is a different answer from nobody
	/// owning it.
	private bool ReadFromProviders(StringView uri, String outText, String outError,
		String outMimeType)
	{
		for (let provider in mProviders)
		{
			switch (provider.Read(uri, outText, outError))
			{
			case .NotMine:
				continue;
			case .Failed:
				if (outError.IsEmpty)
					outError.Set("resource read failed");
				return false;
			case .Ok:
				// The mime type comes from the provider's own listing, which is the only
				// place that knows it.
				outMimeType.Set("text/plain");
				let listed = scope List<Resource>();
				defer { ClearAndDeleteItems!(listed); }
				provider.List(listed);
				for (let entry in listed)
				{
					if (entry.Uri == uri)
					{
						outMimeType.Set(entry.MimeType);
						break;
					}
				}
				return true;
			}
		}
		return false;
	}

	private static JsonValue DescribeResource(Resource resource)
	{
		let entry = JsonValue.MakeObject();
		entry.Set("uri", JsonValue.MakeString(resource.Uri));
		entry.Set("name", JsonValue.MakeString(resource.Name));
		entry.Set("mimeType", JsonValue.MakeString(resource.MimeType));
		entry.Set("description", JsonValue.MakeString(resource.Description));
		return entry;
	}

	private Tool FindTool(StringView name)
	{
		for (let tool in mTools)
		{
			if (tool.Name == name)
				return tool;
		}
		return null;
	}

	private Resource FindResource(StringView uri)
	{
		for (let resource in mResources)
		{
			if (resource.Uri == uri)
				return resource;
		}
		return null;
	}

	// ---- Envelopes ---------------------------------------------------------------------------

	/// The response envelope. The id is ECHOED VERBATIM, so a string id stays a string and a
	/// number stays a number, which is what a client matches its request against.
	private static JsonValue Envelope(JsonValue id)
	{
		let response = JsonValue.MakeObject();
		response.Set("jsonrpc", JsonValue.MakeString("2.0"));
		response.Set("id", (id != null) ? id.Clone() : JsonValue.MakeNull());
		return response;
	}

	private static JsonValue MakeResult(JsonValue id, JsonValue result)
	{
		let response = Envelope(id);
		response.Set("result", result);
		return response;
	}

	private static JsonValue MakeError(JsonValue id, RpcError code, StringView message)
	{
		let error = JsonValue.MakeObject();
		error.Set("code", JsonValue.MakeNumber((double)(int32)code));
		error.Set("message", JsonValue.MakeString(message));

		let response = Envelope(id);
		response.Set("error", error);
		return response;
	}

	private static bool WriteError(JsonValue id, RpcError code, StringView message,
		String outResponse)
	{
		let response = MakeError(id, code, message);
		defer delete response;
		response.ToString(outResponse);
		return true;
	}
}
