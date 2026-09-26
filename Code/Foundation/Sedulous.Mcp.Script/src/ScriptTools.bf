using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Json;
using Sedulous.Mcp;
using Sedulous.Script;

namespace Sedulous.Mcp.Script;

/// The scripting tool contribution: script_api.
///
/// Dumps the PER BACKEND bound API: the exact script visible names and signatures a language
/// actually bound, spelled the way a script writes them, so an agent writes a correct script
/// instead of guessing from the engine's names. The surface says what exists; a backend's
/// DescribeBoundApi says what it bound and how it spelled it, which differs per language and
/// drops what a backend could not bind. That is the answer a script author needs.
///
/// Backend neutral: the languages are whatever the host registered in ScriptBackends, read
/// LIVE at call time; each is bound afresh against the surface the host hands in and read
/// back. A cached listing would be a stale one, and this tool's whole value is being true.
static class ScriptTools
{
	/// State the handler closes over, owned by the tool so it dies with it.
	private class Context
	{
		public ScriptSurface Surface;
	}

	/// Registers script_api against `server`. `surface` is the surface each backend binds,
	/// the pipeline surface in a cooking host, and must outlive the server.
	public static void Register(McpServer server, ScriptSurface surface)
	{
		let context = new Context();
		context.Surface = surface;

		let schema = scope SchemaBuilder();
		schema.Str("language", "backend language id (e.g. \"angelscript\"); default: all");
		server.RegisterTool("script_api",
			"""
			The per-backend bound scripting API: every script-visible type and member a language actually binds, spelled the way scripts use it, each type with its availability domain (inPlayer=false means authoring only: the type exists for tools and cooks but not in a shipped player). Use it to write correct scripts. Optional 'language' narrows to one backend.
			""",
			schema.Build(), .ReadOnly,
			new (arguments, outResult, outError) => ScriptApi(context, arguments, outResult, outError),
			context);
	}

	private static bool ScriptApi(Context context, JsonValue arguments, JsonValue outResult,
		String outError)
	{
		let wanted = scope String();
		let argument = arguments.Get("language");
		if ((argument != null) && argument.IsString)
			wanted.Set(argument.AsString());

		let languages = scope List<String>();
		defer { ClearAndDeleteItems(languages); }
		ScriptBackends.CollectLanguages(languages);

		let described = JsonValue.MakeArray();
		bool matched = false;
		for (let language in languages)
		{
			if (!wanted.IsEmpty && (language != wanted))
				continue;
			matched = true;
			described.Add(DescribeBackend(language, context.Surface));
		}

		if (!wanted.IsEmpty && !matched)
		{
			delete described;
			outError.AppendF("no scripting backend registered for language '{}'", wanted);
			return false;
		}
		outResult.Set("languages", described);
		return true;
	}

	/// {language, typeCount, types:[{scriptName, isNamespace, typeFullName?, domain?,
	/// inPlayer?, members:[{name, signature, isStatic, kind}]}]} for one backend, from a
	/// throwaway runtime bound against the surface.
	private static JsonValue DescribeBackend(StringView language, ScriptSurface surface)
	{
		let backend = JsonValue.MakeObject();
		backend.Set("language", JsonValue.MakeString(language));

		let types = JsonValue.MakeArray();
		let runtime = ScriptBackends.Create(language);
		if (runtime != null)
		{
			defer delete runtime;
			runtime.Bind(surface);

			let api = scope List<ScriptApiType>();
			defer { ClearAndDeleteItems(api); }
			runtime.DescribeBoundApi(api);
			for (let t in api)
			{
				let entry = JsonValue.MakeObject();
				entry.Set("scriptName", JsonValue.MakeString(t.ScriptName));
				entry.Set("isNamespace", JsonValue.MakeBool(t.IsNamespace));
				// The availability domain, from the surface type behind the binding: an
				// agent must know that an asset type exists for authoring but NOT in a
				// shipped player. inPlayer is the robust bit; domain the readable name.
				if (!t.TypeFullName.IsEmpty)
				{
					entry.Set("typeFullName", JsonValue.MakeString(t.TypeFullName));
					if (let info = surface.Find(t.TypeFullName))
					{
						entry.Set("domain", JsonValue.MakeString(info.Domain));
						entry.Set("inPlayer", JsonValue.MakeBool(info.Domain == ScriptDomains.Runtime));
					}
				}
				let members = JsonValue.MakeArray();
				for (let m in t.Members)
				{
					let member = JsonValue.MakeObject();
					member.Set("name", JsonValue.MakeString(m.Name));
					member.Set("signature", JsonValue.MakeString(m.Signature));
					member.Set("isStatic", JsonValue.MakeBool(m.IsStatic));
					member.Set("kind", JsonValue.MakeString(KindName(m.Kind)));
					members.Add(member);
				}
				entry.Set("members", members);
				types.Add(entry);
			}
		}
		backend.Set("typeCount", JsonValue.MakeNumber((double)types.Count));
		backend.Set("types", types);
		return backend;
	}

	private static StringView KindName(ScriptApiMemberKind kind)
	{
		switch (kind)
		{
		case .Property: return "property";
		case .Constant: return "constant";
		case .Method: return "method";
		}
	}
}
