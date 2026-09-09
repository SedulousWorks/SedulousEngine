using System;
using System.Collections;
using Sedulous.Json;

namespace Sedulous.Mcp;

/// A fluent builder for the JSON Schema SUBSET this layer emits and validates.
///
/// Deliberately small: objects of scalars, arrays and enums, with descriptions and a required
/// list. Writing schemas as strings by hand is how they drift from the code that reads them,
/// and a general schema engine is far more than a tool argument list needs.
///
/// The builder OWNS what it accumulates until Build, which hands back a fresh value.
class SchemaBuilder
{
	private JsonValue mProperties = JsonValue.MakeObject() ~ delete _;
	private JsonValue mRequired = JsonValue.MakeArray() ~ delete _;

	public SchemaBuilder Str(StringView name, StringView description = "",
		bool required = false) => Scalar(name, "string", description, required);

	public SchemaBuilder Number(StringView name, StringView description = "",
		bool required = false) => Scalar(name, "number", description, required);

	/// An integer is a number on the wire: JSON has no separate integer type, so this differs
	/// from Number only in what it tells a reader.
	public SchemaBuilder Integer(StringView name, StringView description = "",
		bool required = false) => Scalar(name, "integer", description, required);

	public SchemaBuilder Boolean(StringView name, StringView description = "",
		bool required = false) => Scalar(name, "boolean", description, required);

	/// A string constrained to a fixed set.
	public SchemaBuilder Enum(StringView name, Span<StringView> values,
		StringView description = "", bool required = false)
	{
		let property = JsonValue.MakeObject();
		property.Set("type", JsonValue.MakeString("string"));
		if (!description.IsEmpty)
			property.Set("description", JsonValue.MakeString(description));

		let choices = JsonValue.MakeArray();
		for (let value in values)
			choices.Add(JsonValue.MakeString(value));
		property.Set("enum", choices);

		return Add(name, property, required);
	}

	/// An array whose elements are one scalar type.
	public SchemaBuilder Arr(StringView name, StringView itemType, StringView description = "",
		bool required = false)
	{
		let property = JsonValue.MakeObject();
		property.Set("type", JsonValue.MakeString("array"));
		if (!description.IsEmpty)
			property.Set("description", JsonValue.MakeString(description));

		let items = JsonValue.MakeObject();
		items.Set("type", JsonValue.MakeString(itemType));
		property.Set("items", items);

		return Add(name, property, required);
	}

	/// The escape hatch: a fully formed property schema, for a nested object or array.
	/// OWNERSHIP TRANSFERS.
	public SchemaBuilder Property(StringView name, JsonValue propertySchema,
		bool required = false) => Add(name, propertySchema, required);

	/// The finished object schema. The caller OWNS it, and the builder keeps its own copy so
	/// it can be built more than once.
	public JsonValue Build()
	{
		let schema = JsonValue.MakeObject();
		schema.Set("type", JsonValue.MakeString("object"));
		schema.Set("properties", mProperties.Clone());
		schema.Set("required", mRequired.Clone());
		return schema;
	}

	private SchemaBuilder Scalar(StringView name, StringView type, StringView description,
		bool required)
	{
		let property = JsonValue.MakeObject();
		property.Set("type", JsonValue.MakeString(type));
		if (!description.IsEmpty)
			property.Set("description", JsonValue.MakeString(description));
		return Add(name, property, required);
	}

	private SchemaBuilder Add(StringView name, JsonValue property, bool required)
	{
		if (required)
			mRequired.Add(JsonValue.MakeString(name));
		mProperties.Set(name, property);
		return this;
	}
}
