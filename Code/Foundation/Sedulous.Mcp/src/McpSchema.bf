using System;
using Sedulous.Json;

namespace Sedulous.Mcp;

/// Validation against the schema subset SchemaBuilder emits.
static class McpSchema
{
	/// Whether a value matches a subset type tag.
	///
	/// An unknown or absent tag ACCEPTS, because a schema this validator does not understand
	/// should not turn a valid call into an error.
	public static bool MatchesType(JsonValue value, StringView type)
	{
		if (value == null)
			return false;

		switch (type)
		{
		case "string": return value.IsString;
		// The wire has no integer type, so both tags accept any number.
		case "number", "integer": return value.IsNumber;
		case "boolean": return value.IsBool;
		case "array": return value.IsArray;
		case "object": return value.IsObject;
		default: return true;
		}
	}

	/// Checks arguments against an object schema.
	///
	/// True when valid. Otherwise outError NAMES THE OFFENDING FIELD, by its path at any depth
	/// (`until.op`, `probes[0].field`), because that message travels to an agent as an
	/// invalid-params response and is the only thing it can act on.
	///
	/// An undeclared field is REFUSED, naming the ones the schema declares: a misspelt argument
	/// silently ignored is a call that does something other than what was asked (pie_run given
	/// `timeline` for `input` ran with no input at all; a probe given `field` for `fields` read
	/// worldPosition). The check reaches into a nested object that declares its `properties` and
	/// into each element of an array whose `items` does. A schema with additionalProperties true
	/// takes any field, and a nested object declaring no properties is a free map.
	public static bool ValidateArgs(JsonValue arguments, JsonValue schema, String outError)
	{
		outError.Clear();

		if ((arguments == null) || !arguments.IsObject)
		{
			outError.Set("arguments must be a JSON object");
			return false;
		}
		if (schema == null)
			return true;
		return ValidateObject(arguments, schema, "", outError);
	}

	/// An object against its schema; `path` is where it sits, empty at the top level.
	private static bool ValidateObject(JsonValue value, JsonValue schema, StringView path, String outError)
	{
		if (let required = schema.Get("required"))
		{
			for (int i = 0; i < required.Count; i++)
			{
				let key = required.At(i).AsString();
				if (!value.Has(key))
				{
					outError.Append("missing required field '");
					AppendPath(outError, path, key);
					outError.Append("'");
					return false;
				}
			}
		}

		let properties = schema.Get("properties");
		let openArg = schema.Get("additionalProperties");
		let open = (openArg != null) && openArg.IsBool && openArg.AsBool();

		for (int i = 0; i < value.Count; i++)
		{
			let key = value.KeyAt(i);
			let property = (properties != null) ? properties.Get(key) : null;
			if (property == null)
			{
				if (open)
					continue;
				if (path.IsEmpty)
					outError.AppendF("no argument '{}' (it takes", key);
				else
				{
					outError.Append("no field '");
					AppendPath(outError, path, key);
					outError.Append("' (it takes");
				}
				if ((properties == null) || (properties.Count == 0))
					outError.Append(" none)");
				else
				{
					outError.Append(": ");
					for (int j < properties.Count)
					{
						if (j > 0)
							outError.Append(", ");
						outError.Append(properties.KeyAt(j));
					}
					outError.Append(")");
				}
				return false;
			}

			let fieldPath = scope String();
			AppendPath(fieldPath, path, key);
			if (!ValidateValue(value.Get(key), property, fieldPath, outError))
				return false;
		}

		return true;
	}

	/// One value against its property schema: its type, its enum, and what it holds.
	private static bool ValidateValue(JsonValue value, JsonValue property, StringView path, String outError)
	{
		let type = (property.Get("type") != null) ? property.Get("type").AsString() : "";
		if (!MatchesType(value, type))
		{
			outError.AppendF("field '{}' must be of type {}", path, type);
			return false;
		}

		if (let choices = property.Get("enum"))
		{
			if (choices.IsArray)
			{
				var allowed = false;
				for (int j = 0; j < choices.Count; j++)
				{
					if (choices.At(j).AsString() == value.AsString())
					{
						allowed = true;
						break;
					}
				}
				if (!allowed)
				{
					outError.AppendF("field '{}' is not one of the allowed values", path);
					return false;
				}
			}
		}

		// A nested object declaring its fields is held to them; one declaring none is a map.
		if (value.IsObject && (property.Get("properties") != null))
			return ValidateObject(value, property, path, outError);

		if (value.IsArray)
		{
			if (let items = property.Get("items"))
			{
				if (items.IsObject)
				{
					for (int i < value.Count)
					{
						let itemPath = scope String()..AppendF("{}[{}]", path, i);
						if (!ValidateValue(value.At(i), items, itemPath, outError))
							return false;
					}
				}
			}
		}

		return true;
	}

	private static void AppendPath(String outPath, StringView path, StringView key)
	{
		if (!path.IsEmpty)
		{
			outPath.Append(path);
			outPath.Append('.');
		}
		outPath.Append(key);
	}
}
