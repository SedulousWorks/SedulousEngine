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
	/// True when valid. Otherwise outError NAMES THE OFFENDING FIELD, because that message
	/// travels to an agent as an invalid-params response and is the only thing it can act on.
	///
	/// Undeclared fields are ignored: this subset does not enforce additionalProperties.
	public static bool ValidateArgs(JsonValue arguments, JsonValue schema, String outError)
	{
		outError.Clear();

		if ((arguments == null) || !arguments.IsObject)
		{
			outError.Set("arguments must be a JSON object");
			return false;
		}

		if (schema != null)
		{
			if (let required = schema.Get("required"))
			{
				for (int i = 0; i < required.Count; i++)
				{
					let key = required.At(i).AsString();
					if (!arguments.Has(key))
					{
						outError.AppendF("missing required field '{}'", key);
						return false;
					}
				}
			}
		}

		let properties = (schema != null) ? schema.Get("properties") : null;
		if (properties == null)
			return true;

		for (int i = 0; i < arguments.Count; i++)
		{
			let key = arguments.KeyAt(i);
			let property = properties.Get(key);
			// Undeclared: not this schema's business.
			if (property == null)
				continue;

			let value = arguments.Get(key);
			let type = (property.Get("type") != null) ? property.Get("type").AsString() : "";
			if (!MatchesType(value, type))
			{
				outError.AppendF("field '{}' must be of type {}", key, type);
				return false;
			}

			if (let choices = property.Get("enum"))
			{
				if (!choices.IsArray)
					continue;

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
					outError.AppendF("field '{}' is not one of the allowed values", key);
					return false;
				}
			}
		}

		return true;
	}
}
