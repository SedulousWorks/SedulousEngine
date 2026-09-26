using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Script;

namespace Sedulous.Script.Resource;

/// Fills a script class record from a compiled class: the editor properties its annotations
/// declare and the handlers it declares. What the cook does, and what a headless host does
/// for a class it compiled itself.
///
/// A property is a field WITH an annotation, the `[...]` in front of its declaration; a field
/// without one is not a property, whatever its access:
///
///     [4.0, "Units per second"]   float speed;      // Float, default 4, a description
///     [null, "What to follow"]    Entity target;    // Entity, no default
///     ["asset:AudioClip"]         Guid clip;        // Asset, an AudioClip reference
///
/// The field's declared type picks the kind (float, int, bool, string, Color, Float3,
/// Entity); a Guid field whose first token is `"asset:<Type>"` is an asset reference. The
/// first token is the default, and a quoted second token is the description the inspector
/// shows. An annotated field of any other type is an error, so a typo never silently drops a
/// property. A handler is any `on` prefixed method.
static class ScriptHarvest
{
	/// What the host injects into every instance that declares it.
	public const String cSelf = "self";
	public const String cScene = "scene";

	/// False when the class is not in the module, or an annotated field cannot be a
	/// property; the reason goes to outProblems when given.
	public static bool Harvest(ScriptRuntime runtime, StringView moduleName, StringView className, ScriptClassSource outSource,
		List<String> outProblems = null)
	{
		let members = scope List<ScriptMemberDesc>();
		defer { ClearAndDeleteItems(members); }
		if (!runtime.DescribeClass(moduleName, className, members))
		{
			outProblems?.Add(new $"no class '{className}' in the source");
			return false;
		}

		ClearAndDeleteItems!(outSource.Properties);
		ClearAndDeleteItems!(outSource.Handlers);
		// Starting a coroutine is a call in the source; a class that never makes it pays
		// nothing at teardown.
		outSource.UsesCoroutines = outSource.Source.Contains("startCoroutine");
		bool ok = true;
		for (let m in members)
		{
			if (m.IsMethod)
			{
				if (m.Name.StartsWith("on") && (m.Name.Length > 2) && m.Name[2].IsUpper)
					outSource.Handlers.Add(new String(m.Name));
				continue;
			}
			if (m.Metadata.IsEmpty)
				continue; // not a property

			let tokens = scope List<String>();
			defer { ClearAndDeleteItems(tokens); }
			SplitTopLevel(m.Metadata, tokens);
			StringView firstToken = tokens.IsEmpty ? "" : tokens[0];
			let typeName = NormalizeTypeName(m.TypeName);

			let desc = new ScriptPropertyDesc();
			desc.Name.Set(m.Name);
			desc.Hash = ScriptPropertyNames.HashOf(m.Name);
			if (!ResolvePropertyType(typeName, firstToken, ref desc.Type, desc.AssetType))
			{
				outProblems?.Add(new $"{className}: property '{m.Name}' has unsupported type '{typeName}' (valid: float, int, bool, string, Color, Float3, Entity, or Guid tagged \"asset:<Type>\")");
				delete desc;
				ok = false;
				continue;
			}
			ParseDefault(desc.Type, firstToken, ref desc.Default);
			if ((tokens.Count > 1) && IsQuoted(tokens[1]))
				Unquote(tokens[1], desc.Description);
			outSource.Properties.Add(desc);
		}
		return ok;
	}

	/// The declared type without `const ` and a trailing `@`.
	private static StringView NormalizeTypeName(StringView declaration)
	{
		var t = declaration;
		t.Trim();
		if (t.StartsWith("const "))
		{
			t = t.Substring(6);
			t.Trim();
		}
		while (!t.IsEmpty && ((t[t.Length - 1] == '@') || t[t.Length - 1].IsWhiteSpace))
			t.RemoveFromEnd(1);
		return t;
	}

	private static bool IsIntTypeName(StringView t)
	{
		switch (t)
		{
		case "int", "int8", "int16", "int32", "int64", "uint", "uint8", "uint16", "uint32", "uint64": return true;
		default: return false;
		}
	}

	private static bool ResolvePropertyType(StringView typeName, StringView firstToken, ref ScriptPropertyType outKind, String outAssetType)
	{
		outAssetType.Clear();
		if ((typeName == "float") || (typeName == "double")) { outKind = .Float; return true; }
		if (IsIntTypeName(typeName)) { outKind = .Int; return true; }
		switch (typeName)
		{
		case "bool": outKind = .Bool; return true;
		case "string": outKind = .String; return true;
		case "Color": outKind = .Color; return true;
		case "Float3": outKind = .Vec3; return true;
		case "Entity": outKind = .Entity; return true;
		case "Guid":
			// A Guid property is a typed asset reference, declared by an `asset:<Type>` tag
			// in the first token.
			if (IsQuoted(firstToken))
			{
				let tag = Unquote(firstToken, .. scope .());
				const String cPrefix = "asset:";
				if ((tag.Length > cPrefix.Length) && tag.StartsWith(cPrefix))
				{
					outKind = .Asset;
					outAssetType.Set(tag.Substring(cPrefix.Length));
					return true;
				}
			}
			return false;
		default: return false;
		}
	}

	/// The default from the first token: what the language can say literally, scalars, bool,
	/// a quoted string, a `(r, g, b[, a])` or `(x, y, z)` list, and `null` for a reference.
	private static void ParseDefault(ScriptPropertyType type, StringView firstToken, ref ScriptPropertyValue outValue)
	{
		outValue.Kind = type;
		var token = firstToken;
		token.Trim();
		if (token.IsEmpty || (token == "null"))
			return;
		switch (type)
		{
		case .Float: outValue.Number = ParseNumber(token);
		case .Int: outValue.Number = (double)(int64)ParseNumber(token);
		case .Bool: outValue.Boolean = (token == "true");
		case .String: outValue.Text = Unquote(token, .. new String());
		case .Color:
			float[4] n = .(1, 1, 1, 1);
			if (ParseNumberList(token, ref n) >= 3)
				outValue.Color = .(n[0], n[1], n[2], n[3]);
		case .Vec3:
			float[4] n = .(0, 0, 0, 0);
			if (ParseNumberList(token, ref n) >= 3)
				outValue.Vector = .(n[0], n[1], n[2]);
		default:
			// Entity and asset defaults are only null; an override carries the guid.
		}
	}

	private static double ParseNumber(StringView text)
	{
		var t = text;
		t.Trim();
		// A float literal's `f` suffix is the language's, not the number's.
		if (t.EndsWith("f") || t.EndsWith("F"))
			t.RemoveFromEnd(1);
		return double.Parse(t).GetValueOrDefault();
	}

	/// Up to four numbers from `(a, b, c[, d])` or a bare `a, b, c`.
	private static int ParseNumberList(StringView text, ref float[4] outValues)
	{
		var body = text;
		body.Trim();
		if ((body.Length >= 2) && ((body[0] == '(') || (body[0] == '[') || (body[0] == '{')))
			body = body.Substring(1, body.Length - 2);
		int count = 0;
		for (var piece in body.Split(','))
		{
			if (count >= 4)
				break;
			piece.Trim();
			if (!piece.IsEmpty)
				outValues[count++] = (float)ParseNumber(piece);
		}
		return count;
	}

	private static bool IsQuoted(StringView text)
	{
		var t = text;
		t.Trim();
		return (t.Length >= 2) && (t[0] == '"') && (t[t.Length - 1] == '"');
	}

	/// One layer of surrounding quotes off, with \" and \\ unescaped; the trimmed text as it
	/// is when not quoted.
	private static void Unquote(StringView text, String outText)
	{
		outText.Clear();
		var t = text;
		t.Trim();
		if (!IsQuoted(t))
		{
			outText.Append(t);
			return;
		}
		let body = t.Substring(1, t.Length - 2);
		for (int i = 0; i < body.Length; i++)
		{
			if ((body[i] == '\\') && (i + 1 < body.Length) && ((body[i + 1] == '"') || (body[i + 1] == '\\')))
			{
				outText.Append(body[i + 1]);
				i++;
				continue;
			}
			outText.Append(body[i]);
		}
	}

	/// The annotation's top level comma separated tokens, trimmed, honouring string literals
	/// and (), [], {} nesting, so a `(1, 0, 0)` default is one token.
	private static void SplitTopLevel(StringView content, List<String> outTokens)
	{
		int begin = 0;
		int depth = 0;
		bool inString = false;
		for (int i = 0; i < content.Length; i++)
		{
			let c = content[i];
			if (inString)
			{
				if (c == '\\')
				{
					i++;
					continue;
				}
				if (c == '"')
					inString = false;
				continue;
			}
			switch (c)
			{
			case '"': inString = true;
			case '(', '[', '{': depth++;
			case ')', ']', '}': if (depth > 0) depth--;
			case ',':
				if (depth == 0)
				{
					var token = content.Substring(begin, i - begin);
					token.Trim();
					outTokens.Add(new String(token));
					begin = i + 1;
				}
			default:
			}
		}
		var last = content.Substring(begin);
		last.Trim();
		outTokens.Add(new String(last));
	}
}
