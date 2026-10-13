using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Shaders;

/// A material parameter's type as a properties block declares it.
enum ShaderPropertyType : uint8
{
	case Float;
	case Float2;
	case Float3;
	case Float4;
	case Int;
	/// An authored sRGB rgba; the shader reads it linear (a float4).
	case Color;
	/// An authored sRGB rgb, linear intensity in w (a float4).
	case ColorHdr;
	/// A Texture2D.
	case Texture;
	case TextureCube;
	case Sampler;
}

/// One declaration of a properties block, laid out.
class ShaderProperty
{
	public String Name = new .() ~ delete _;
	public ShaderPropertyType Type = .Float;
	/// The default (an int's in X).
	public Float4 Value = .(0, 0, 0, 0);
	public bool HasRange = false;
	public float RangeMin = 0.0f;
	public float RangeMax = 0.0f;
	/// Where it is declared, 1 based.
	public uint32 Line = 0;
	/// A uniform's byte offset in the cbuffer.
	public uint32 Offset = 0;
	/// A uniform's byte size; nought for a texture or sampler.
	public uint32 Size = 0;
	/// A texture's tN or a sampler's sN.
	public uint32 Binding = 0;
}

/// A malformed line of a properties block.
class ShaderPropertyError
{
	/// 1 based.
	public uint32 Line = 0;
	public String Message = new .() ~ delete _;
}

/// What ShaderProperties.Parse found. Present false: the source declares no block, which is a
/// valid shader with no material parameters.
class ShaderPropertiesBlock
{
	public bool Present = false;
	/// The byte offset of the `properties` line's start.
	public int Begin = 0;
	/// The byte offset just past the closing brace's line.
	public int End = 0;
	/// The `properties` line, 1 based.
	public uint32 FirstLine = 0;
	/// The closing brace's line.
	public uint32 LastLine = 0;
	/// In declaration order.
	public List<ShaderProperty> Properties = new .() ~ DeleteContainerAndItems!(_);
	public List<ShaderPropertyError> Errors = new .() ~ DeleteContainerAndItems!(_);
	/// The cbuffer's size, nought when there are no uniforms.
	public uint32 UniformSize = 0;

	public bool IsOk => Errors.IsEmpty;

	public ShaderProperty Find(StringView name)
	{
		for (let property in Properties)
			if (property.Name == name)
				return property;
		return null;
	}
}

/// The `properties { ... }` block a custom shader declares its material parameters in, and the
/// HLSL generated from it. The block is the ONE declaration of a shader's material layout: the
/// engine replaces it with the set-2 declarations (the `Material` cbuffer, the textures and the
/// samplers), so the layout a material is cooked with and the one the shader reads cannot
/// disagree.
///
///     properties
///     {
///         Color   BaseColor = (1, 1, 1, 1);
///         float   Bands     = 3   [1, 8];
///         Texture AlbedoMap;
///         Sampler MainSampler;
///     }
///
/// One declaration per line: a type, a name, an optional default and, for a float or an int, an
/// optional [min, max] range (the editor's slider). The cbuffer follows HLSL's packing rules,
/// through PackCbufferMember, which MaterialBuilder uses too.
static class ShaderProperties
{
	private struct TypeRow
	{
		public StringView Keyword;
		public ShaderPropertyType Type;
		/// Nought for a resource, which takes no default.
		public uint32 Components;
		public StringView Hlsl;

		public this(StringView keyword, ShaderPropertyType type, uint32 components, StringView hlsl)
		{
			Keyword = keyword; Type = type; Components = components; Hlsl = hlsl;
		}
	}

	private static TypeRow[10] sTypes = .(
		.("float", .Float, 1, "float"),
		.("float2", .Float2, 2, "float2"),
		.("float3", .Float3, 3, "float3"),
		.("float4", .Float4, 4, "float4"),
		.("int", .Int, 1, "int"),
		.("Color", .Color, 4, "float4"),
		.("ColorHdr", .ColorHdr, 4, "float4"),
		.("Texture", .Texture, 0, "Texture2D"),
		.("TextureCube", .TextureCube, 0, "TextureCube"),
		.("Sampler", .Sampler, 0, "SamplerState"));

	/// HLSL's cbuffer packing, the one rule every material block is laid out by: a member is
	/// aligned to its own size and never crosses a 16 byte row (a float3 then a float share a
	/// row; a float2 at 12 moves to 16). Returns the member's offset and advances `cursor` past
	/// it.
	public static uint32 PackCbufferMember(ref uint32 cursor, uint32 size)
	{
		var offset = cursor;
		if ((size > 0) && ((offset / 16) != ((offset + size - 1) / 16)))
			offset = (offset + 15) & ~(uint32)15;
		cursor = offset + size;
		return offset;
	}

	/// A cbuffer's size: its members' extent rounded up to a whole row.
	public static uint32 CbufferSize(uint32 cursor) => (cursor + 15) & ~(uint32)15;

	/// The HLSL type a property declares.
	public static StringView HlslType(ShaderPropertyType type) => RowOf(type).Hlsl;

	/// Finds and parses the source's properties block into `outBlock`. Errors carry their line;
	/// the block's place (Begin, End, FirstLine, LastLine) is what Expand replaces.
	public static void Parse(StringView source, ShaderPropertiesBlock outBlock)
	{
		var line = (uint32)0;
		let start = FindBlockStart(source, ref line);
		if (start >= source.Length)
			return; // no block: a shader without material parameters
		outBlock.Present = true;
		outBlock.Begin = start;
		outBlock.FirstLine = line;

		// The opening brace: after the keyword on its line, or alone on a following line.
		var at = start;
		while ((at < source.Length) && (source[at] != '{'))
		{
			if (source[at] == '\n')
				line++;
			at++;
		}
		if (at >= source.Length)
		{
			AddError(outBlock, outBlock.FirstLine, "properties needs a { ... } block");
			outBlock.End = source.Length;
			outBlock.LastLine = line;
			return;
		}
		at++; // past {

		// Declarations, a line at a time, to the closing brace.
		var closed = false;
		while (at < source.Length)
		{
			var lineEnd = at;
			while ((lineEnd < source.Length) && (source[lineEnd] != '\n'))
				lineEnd++;
			var text = source.Substring(at, lineEnd - at);
			// A trailing `//` comment is not part of the declaration.
			let comment = text.IndexOf("//");
			if (comment >= 0)
				text = text.Substring(0, comment);
			text.Trim();
			if (!text.IsEmpty && (text[0] == '}'))
			{
				closed = true;
				outBlock.LastLine = line;
				outBlock.End = (lineEnd < source.Length) ? lineEnd + 1 : lineEnd;
				if (text.Length > 1)
					AddError(outBlock, line, "nothing may follow the block's }");
				break;
			}
			if (!text.IsEmpty)
				ParseDeclaration(outBlock, text, line);
			if (lineEnd >= source.Length)
				break;
			at = lineEnd + 1;
			line++;
		}
		if (!closed)
		{
			AddError(outBlock, outBlock.FirstLine, "the properties block has no closing }");
			outBlock.End = source.Length;
			outBlock.LastLine = line;
			return;
		}

		// Lay out: uniforms by HLSL's packing, textures t0.. and samplers s0.. in declaration
		// order (what the material system assigns a material with this property list).
		uint32 cursor = 0;
		uint32 textures = 0;
		uint32 samplers = 0;
		var anyUniform = false;
		for (let property in outBlock.Properties)
		{
			switch (property.Type)
			{
			case .Texture, .TextureCube:
				property.Binding = textures++;
			case .Sampler:
				property.Binding = samplers++;
			default:
				property.Size = RowOf(property.Type).Components * 4;
				property.Offset = PackCbufferMember(ref cursor, property.Size);
				anyUniform = true;
			}
		}
		outBlock.UniformSize = anyUniform ? CbufferSize(cursor) : 0;
	}

	/// The set-2 declarations a block stands for: the `Material` cbuffer (members in order, which
	/// HLSL packs exactly as PackCbufferMember did), then each texture and sampler at its slot.
	public static void GenerateMaterialDeclarations(ShaderPropertiesBlock block, String outHlsl)
	{
		if (block.UniformSize > 0)
		{
			outHlsl.Append("cbuffer Material : register(b0, space2) {\n");
			for (let property in block.Properties)
			{
				if (property.Size == 0)
					continue;
				outHlsl.AppendF("    {} {}; // offset {}\n", RowOf(property.Type).Hlsl, property.Name, property.Offset);
			}
			outHlsl.Append("};\n");
		}
		for (let property in block.Properties)
		{
			if (property.Size != 0)
				continue;
			let register = (property.Type == .Sampler) ? "s" : "t";
			outHlsl.AppendF("{} {} : register({}{}, space2);\n", RowOf(property.Type).Hlsl, property.Name, register,
				property.Binding);
		}
	}

	/// The source as the compiler sees it: the properties block replaced by its declarations,
	/// then `#line` so every line after it keeps the number (and file name) its author sees. A
	/// source with no block is returned as it is. The parse lands in `outBlock`, for its table and
	/// its errors.
	public static void Expand(StringView source, StringView fileName, String outSource, ShaderPropertiesBlock outBlock)
	{
		Parse(source, outBlock);
		if (!outBlock.Present)
		{
			outSource.Append(source);
			return;
		}
		outSource.Append(source.Substring(0, outBlock.Begin));
		GenerateMaterialDeclarations(outBlock, outSource);
		outSource.AppendF("#line {}", outBlock.LastLine + 1);
		if (!fileName.IsEmpty)
			outSource.AppendF(" \"{}\"", fileName);
		outSource.Append('\n');
		outSource.Append(source.Substring(outBlock.End));
	}

	private static TypeRow RowOf(ShaderPropertyType type)
	{
		for (let row in sTypes)
			if (row.Type == type)
				return row;
		return sTypes[0];
	}

	private static bool IsSpace(char8 c) => (c == ' ') || (c == '\t') || (c == '\r');
	private static bool IsIdentifierStart(char8 c) => c.IsLetter || (c == '_');
	private static bool IsIdentifier(char8 c) => c.IsLetterOrDigit || (c == '_');

	private static void AddError(ShaderPropertiesBlock block, uint32 line, StringView message)
	{
		let error = new ShaderPropertyError();
		error.Line = line;
		error.Message.Set(message);
		block.Errors.Add(error);
	}

	/// The `properties` line: a line whose first token is the word `properties`. Its start
	/// offset, or the source's length when there is none.
	private static int FindBlockStart(StringView source, ref uint32 outLine)
	{
		let keyword = "properties";
		var lineStart = 0;
		var line = (uint32)1;
		while (lineStart < source.Length)
		{
			var lineEnd = lineStart;
			while ((lineEnd < source.Length) && (source[lineEnd] != '\n'))
				lineEnd++;
			var k = lineStart;
			while ((k < lineEnd) && IsSpace(source[k]))
				k++;
			let after = k + keyword.Length;
			if ((after <= lineEnd) && (source.Substring(k, keyword.Length) == keyword)
				&& ((after == lineEnd) || !IsIdentifier(source[after])))
			{
				outLine = line;
				return lineStart;
			}
			lineStart = lineEnd + 1;
			line++;
		}
		return source.Length;
	}

	/// A cursor over one declaration line.
	private struct LineReader
	{
		public StringView Text;
		public int At;

		public this(StringView text) { Text = text; At = 0; }

		public bool AtEnd => At >= Text.Length;
		public char8 Peek => AtEnd ? '\0' : Text[At];

		public void SkipSpace() mut
		{
			while (!AtEnd && IsSpace(Text[At]))
				At++;
		}

		public bool Take(char8 c) mut
		{
			SkipSpace();
			if (Peek == c)
			{
				At++;
				return true;
			}
			return false;
		}

		public StringView Identifier() mut
		{
			SkipSpace();
			let start = At;
			if (!AtEnd && IsIdentifierStart(Peek))
			{
				while (!AtEnd && IsIdentifier(Peek))
					At++;
			}
			return Text.Substring(start, At - start);
		}

		/// A decimal number: a sign, digits, an optional fraction and exponent.
		public bool Number(out float value) mut
		{
			value = 0.0f;
			SkipSpace();
			let start = At;
			if ((Peek == '-') || (Peek == '+'))
				At++;
			var digits = false;
			while (!AtEnd && (Peek.IsDigit || (Peek == '.')))
			{
				digits = digits || (Peek != '.');
				At++;
			}
			if (digits && ((Peek == 'e') || (Peek == 'E')))
			{
				At++;
				if ((Peek == '-') || (Peek == '+'))
					At++;
				while (!AtEnd && Peek.IsDigit)
					At++;
			}
			if (!digits)
			{
				At = start;
				return false;
			}
			if (float.Parse(Text.Substring(start, At - start)) case .Ok(let parsed))
			{
				value = parsed;
				return true;
			}
			At = start;
			return false;
		}
	}

	/// One declaration line, already stripped of a trailing `//` comment.
	private static void ParseDeclaration(ShaderPropertiesBlock block, StringView text, uint32 line)
	{
		var reader = LineReader(text);
		let typeWord = reader.Identifier();
		TypeRow row = default;
		var known = false;
		for (let candidate in sTypes)
		{
			if (candidate.Keyword == typeWord)
			{
				row = candidate;
				known = true;
				break;
			}
		}
		if (!known)
		{
			AddError(block, line, scope $"unknown property type '{typeWord}' (float, float2, float3, float4, int, Color, ColorHdr, Texture, TextureCube, Sampler)");
			return;
		}
		let name = reader.Identifier();
		if (name.IsEmpty)
		{
			AddError(block, line, "a property needs a name after its type");
			return;
		}
		if (block.Find(name) != null)
		{
			AddError(block, line, scope $"'{name}' is declared twice");
			return;
		}

		let property = new ShaderProperty();
		property.Name.Set(name);
		property.Type = row.Type;
		property.Line = line;
		// Defaults when none is written: white for a colour, black at intensity 1 for an HDR
		// colour (no glow), zero otherwise.
		if (property.Type == .Color)
			property.Value = .(1, 1, 1, 1);
		else if (property.Type == .ColorHdr)
			property.Value = .(0, 0, 0, 1);

		if (!ParseRest(block, ref reader, row, property, line))
		{
			delete property;
			return;
		}
		block.Properties.Add(property);
	}

	/// The default, the range and the terminating `;`: false, with the error added, when the
	/// line is malformed.
	private static bool ParseRest(ShaderPropertiesBlock block, ref LineReader reader, TypeRow row, ShaderProperty property,
		uint32 line)
	{
		if (reader.Take('='))
		{
			if (row.Components == 0)
			{
				AddError(block, line, "a texture or sampler takes no default");
				return false;
			}
			float[4] values = .(0, 0, 0, 0);
			var count = 0;
			if (reader.Take('('))
			{
				repeat
				{
					if ((count == 4) || !reader.Number(out values[count]))
					{
						AddError(block, line, "a default is a number or (a, b, ...)");
						return false;
					}
					count++;
				}
				while (reader.Take(','));
				if (!reader.Take(')'))
				{
					AddError(block, line, "a default's ( has no )");
					return false;
				}
			}
			else if (reader.Number(out values[0]))
			{
				count = 1;
			}
			else
			{
				AddError(block, line, "a default is a number or (a, b, ...)");
				return false;
			}
			// A colour may leave its alpha out (opaque).
			let colour = (property.Type == .Color) || (property.Type == .ColorHdr);
			let colourWithoutAlpha = colour && (count == 3);
			if ((count != (int)row.Components) && !colourWithoutAlpha)
			{
				AddError(block, line, scope $"'{property.Name}' is a {row.Keyword}: its default needs {row.Components} {(row.Components == 1) ? "value" : "values"}");
				return false;
			}
			property.Value = .(values[0], values[1], values[2], colourWithoutAlpha ? 1.0f : values[3]);
		}

		if (reader.Take('['))
		{
			if ((property.Type != .Float) && (property.Type != .Int))
			{
				AddError(block, line, "a [min, max] range is for a float or an int");
				return false;
			}
			if (!reader.Number(out property.RangeMin) || !reader.Take(',') || !reader.Number(out property.RangeMax)
				|| !reader.Take(']'))
			{
				AddError(block, line, "a range is [min, max]");
				return false;
			}
			if (property.RangeMin > property.RangeMax)
			{
				AddError(block, line, "a range's min is above its max");
				return false;
			}
			property.HasRange = true;
		}

		if (!reader.Take(';'))
		{
			AddError(block, line, "a declaration ends with ;");
			return false;
		}
		reader.SkipSpace();
		if (!reader.AtEnd)
		{
			AddError(block, line, "one declaration per line");
			return false;
		}
		return true;
	}
}
