using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Shaders;
using Sedulous.Shaders.Resource;

namespace Sedulous.Shaders.Pipeline;

/// One error in a shader: where (the file it is in, which may be an engine library file the shader
/// includes; 1 based line and column, nought when unknown) and what.
class ShaderDiagnostic
{
	public String File = new .() ~ delete _;
	public uint32 Line = 0;
	public uint32 Column = 0;
	public String Message = new .() ~ delete _;

	/// `file:line:column: message`, `file:line: message` or, for the whole file,
	/// `file: message`: the form the Console and the cook print and a terminal makes clickable.
	public void Format(String outText)
	{
		if (Line == 0)
			outText.AppendF("{}: {}", File, Message); // about the whole file
		else if (Column != 0)
			outText.AppendF("{}:{}:{}: {}", File, Line, Column, Message);
		else
			outText.AppendF("{}:{}: {}", File, Line, Message);
	}
}

/// Which variants a check compiles. The cook proves every one; a live check as you type compiles
/// each stage's base variant, the one every draw starts from, and leaves the flags to the cook so
/// typing stays responsive.
enum ShaderCheckDepth : uint8
{
	case BaseVariants;
	case EveryVariant;
}

struct ShaderCheckOptions
{
	public StringView VertexEntryPoint = "VSMain";
	public StringView FragmentEntryPoint = "PSMain";
	/// The engine's Shaders/ folder, the include path; empty is none.
	public StringView ShaderLibrary = default;
	public ShaderCheckDepth Depth = .EveryVariant;
	/// A compiler to reuse (a page checking on every pause in typing); null: one is made for
	/// this check.
	public ShaderCompiler Compiler = null;

	public this() {}
}

/// A surface shader's shading model (its `// surface:` line); None for a low-level shader.
enum SurfaceModel : uint8
{
	case None;
	case Lit;
	case Unlit;
}

/// One program a shader compiles to: what the shader system registers under the shader's name
/// plus `Suffix` (empty for the main one).
class ShaderCheckProgram
{
	public String Suffix = new .() ~ delete _;
	public String Text = new .() ~ delete _;
	public String VertexEntryPoint = new .() ~ delete _;
	public String FragmentEntryPoint = new .() ~ delete _;
	public ShaderFlags VertexMask = .None;
	public ShaderFlags FragmentMask = .None;
}

/// What a check found. `Expanded`, the masks, `Block` and `Programs` are valid whenever the
/// properties block parsed (`Expanded` and the masks are the main program's); `Errors` empty means
/// the shader compiles at the depth asked.
class ShaderCheck
{
	/// A surface shader's lattices: the template's, the same for every surface shader.
	public const ShaderFlags cSurfaceForwardVertexMask = .Skinned | .Instanced;
	public const ShaderFlags cSurfaceForwardFragmentMask = .AlphaTest | .GBuffer | .Dither;
	public const ShaderFlags cSurfaceDepthVertexMask = .Skinned | .Instanced | .AlphaTest;
	public const ShaderFlags cSurfaceDepthFragmentMask = .AlphaTest;

	public ShaderPropertiesBlock Block = new .() ~ delete _;
	public String Expanded = new .() ~ delete _;
	public ShaderFlags VertexMask = .None;
	public ShaderFlags FragmentMask = .None;
	public SurfaceModel Surface = .None;
	/// A surface shader's Vertex(): its depth programs replace the built-ins.
	public bool HasVertex = false;
	public List<ShaderCheckProgram> Programs = new .() ~ DeleteContainerAndItems!(_);
	public List<ShaderDiagnostic> Errors = new .() ~ DeleteContainerAndItems!(_);

	public bool IsOk => Errors.IsEmpty;

	/// Checks a shader's text as the cook would, saved as `file` (the name errors carry): the
	/// properties block expanded, both stages' variant lattices read, every flag the file tests
	/// declared, the variants compiled with DXC. The errors come back as data rather than logged:
	/// the cook logs them and fails, the editor's shader page puts them on the lines as you type,
	/// the MCP tools return them. One check, so the three never disagree about a shader.
	///
	/// A low-level shader is one program, its stages' entries and lattices its own; a surface
	/// shader (a `// surface:` line) three, assembled around its Surface() and Vertex() from the
	/// engine's templates: the forward program, `.depth` and `.pick`.
	public void Run(StringView text, StringView file, ShaderCheckOptions options = .())
	{
		// The properties block becomes the set-2 declarations; `#line` keeps the author's line
		// numbers for everything after it.
		ShaderProperties.Expand(text, file, Expanded, Block);
		for (let error in Block.Errors)
			Fail(file, error.Line, error.Message);
		if (!Block.IsOk)
			return;

		let directive = ParseSurfaceDirective(text, let directiveLine, let badWord);
		if (!badWord.IsEmpty)
		{
			Fail(file, directiveLine, scope $"'{badWord}' is not a surface model (lit or unlit)");
			return;
		}
		Surface = directive;

		if (Surface == .None)
		{
			// Each stage's lattice; a flag the file tests but no stage declares would never be
			// compiled (the corpus's drift lint, over both stages).
			VertexMask = ShaderVariants.ParseStageVariantDirective(text, .Vertex).Mask;
			FragmentMask = ShaderVariants.ParseStageVariantDirective(text, .Fragment).Mask;
			let main = new ShaderCheckProgram();
			main.Text.Set(Expanded);
			main.VertexEntryPoint.Set(options.VertexEntryPoint);
			main.FragmentEntryPoint.Set(options.FragmentEntryPoint);
			main.VertexMask = VertexMask;
			main.FragmentMask = FragmentMask;
			Programs.Add(main);
		}
		else
		{
			// The variants are the template's; a variants line would say otherwise.
			if (ShaderVariants.ParseStageVariantDirective(text, .Vertex).Present
				|| ShaderVariants.ParseStageVariantDirective(text, .Fragment).Present)
			{
				Fail(file, 0, "a surface shader's variants are the engine's: remove its // variants lines");
				return;
			}
			HasVertex = DefinesVertexFunction(text);
			var hasAlphaCutoff = false;
			for (let property in Block.Properties)
				hasAlphaCutoff |= (property.Name == "AlphaCutoff") && (property.Type == .Float);
			(StringView suffix, StringView pass, ShaderFlags vertexMask, ShaderFlags fragmentMask)[3] passes = .(
				("", "forward.hlsli", cSurfaceForwardVertexMask, cSurfaceForwardFragmentMask),
				(ShaderSource.cDepthProgramSuffix, "depth.hlsli", cSurfaceDepthVertexMask, cSurfaceDepthFragmentMask),
				(ShaderSource.cPickProgramSuffix, "pick.hlsli", cSurfaceDepthVertexMask, cSurfaceDepthFragmentMask));
			for (let pass in passes)
			{
				let program = new ShaderCheckProgram();
				program.Suffix.Set(pass.suffix);
				SurfaceProgramText(Expanded, file, Surface, HasVertex, hasAlphaCutoff, pass.pass, program.Text);
				program.VertexEntryPoint.Set("VSMain");
				program.FragmentEntryPoint.Set("PSMain");
				program.VertexMask = pass.vertexMask;
				program.FragmentMask = pass.fragmentMask;
				Programs.Add(program);
			}
			Expanded.Set(Programs[0].Text);
			VertexMask = cSurfaceForwardVertexMask;
			FragmentMask = cSurfaceForwardFragmentMask;
		}

		let undeclared = scope List<StringView>();
		ShaderVariants.FindUndeclaredFlagUses(text, VertexMask | FragmentMask, undeclared);
		for (let flag in undeclared)
		{
			if (Surface == .None)
				Fail(file, 0, scope $"tests {flag} but no stage declares it (add it to a // variants(vertex): or // variants(fragment): line)");
			else
				Fail(file, 0, scope $"tests {flag}, which a surface shader does not compile");
		}
		if (!undeclared.IsEmpty)
			return;

		var compiler = options.Compiler;
		ShaderCompiler owned = null;
		defer { delete owned; }
		if (compiler == null)
		{
			owned = new ShaderCompiler();
			if (owned.Initialize() case .Err)
			{
				Fail(file, 0, "the DXC compiler is unavailable");
				return;
			}
			compiler = owned;
		}

		StringView[1] includePaths = .(options.ShaderLibrary);
		let variants = scope List<ShaderFlags>();
		let defines = scope List<ShaderDefine>();
		for (let program in Programs)
		{
			if (!CompileProgram(program, file, options, compiler, includePaths, variants, defines))
				break; // the next program would report the same error in the author's text
		}
		ReportEngineNameClashes(file);
	}

	/// Compiles a program's stages at the depth asked; false at its first failure, recorded.
	private bool CompileProgram(ShaderCheckProgram program, StringView file, ShaderCheckOptions options,
		ShaderCompiler compiler, StringView[1] includePaths, List<ShaderFlags> variants, List<ShaderDefine> defines)
	{
		let preserveInterface = ShaderVariants.ParsePreserveInterfaceDirective(program.Text);
		var includes = includePaths;
		(ShaderStage stage, StringView entryPoint, ShaderFlags mask)[2] stages = .(
			(.Vertex, program.VertexEntryPoint, program.VertexMask),
			(.Fragment, program.FragmentEntryPoint, program.FragmentMask));
		for (let stage in stages)
		{
			variants.Clear();
			if (options.Depth == .EveryVariant)
				ShaderVariants.EnumerateVariants(stage.mask, variants);
			else
				variants.Add(.None);
			for (let flags in variants)
			{
				defines.Clear();
				ShaderFlagNames.AppendDefines(flags, defines);
				var compile = CompileOptions();
				compile.Defines = defines;
				if (!options.ShaderLibrary.IsEmpty)
					compile.IncludePaths = includes;
				compile.BindingShifts = BindingShifts.Standard;
				compile.BindingShiftSets = 4;
				compile.SourceName = file;
				compile.PreserveInterface = preserveInterface; // as the runtime compiles it
				var result = compiler.Compile(.((uint8*)program.Text.Ptr, program.Text.Length), stage.stage, stage.entryPoint,
					.SPIRV, compile);
				defer result.Dispose();
				if (result.Success)
					continue;

				let first = Errors.Count;
				if (!ParseCompilerDiagnostics(result.Messages, Errors))
					Fail(file, 0, result.Messages.IsEmpty ? "the compile failed" : result.Messages);
				// The flags the failing compile had, when it had any: an error under a flag reads
				// differently from one in every variant. (Not the stage: DXC compiles the whole
				// file for each, so an error anywhere fails the first stage tried.)
				if (!defines.IsEmpty)
				{
					let context = scope String(" (under ");
					for (int d < defines.Count)
					{
						if (d > 0)
							context.Append(' ');
						context.Append(defines[d].Name);
					}
					context.Append(')');
					for (int i = first; i < Errors.Count; i++)
						Errors[i].Message.Append(context);
				}
				// One stage's first failure says what is wrong; the rest repeat it.
				return false;
			}
		}
		return true;
	}

	/// A property named like one of the engine's own declarations (the vertex stage's `Tint`, say)
	/// is a redefinition DXC reports in the engine's file: reported at the property instead.
	private void ReportEngineNameClashes(StringView file)
	{
		const String cRedefinition = "redefinition of '";
		for (let diagnostic in Errors)
		{
			if ((diagnostic.File == file) || !diagnostic.Message.StartsWith(cRedefinition))
				continue;
			let rest = diagnostic.Message.Substring(cRedefinition.Length);
			let quote = rest.IndexOf('\'');
			if (quote < 0)
				continue;
			let name = rest.Substring(0, quote);
			for (let property in Block.Properties)
			{
				if (property.Name != name)
					continue;
				let message = scope String()..AppendF("property '{}' takes a name the engine's shaders already use ({}:{}); rename it",
					name, diagnostic.File, diagnostic.Line);
				diagnostic.Message.Set(message);
				diagnostic.File.Set(file);
				diagnostic.Line = property.Line;
				diagnostic.Column = 0;
				break;
			}
		}
	}

	/// The `// surface: lit` (or `unlit`) line, where the file says it is a surface shader: its
	/// model and 1 based line. A `// surface:` line with another word puts it in `outBad`.
	public static SurfaceModel ParseSurfaceDirective(StringView text, out uint32 outLine, out StringView outBad)
	{
		const String cTag = "// surface:";
		outLine = 0;
		outBad = default;
		uint32 number = 0;
		for (var line in text.Split('\n'))
		{
			number++;
			line.Trim();
			if (!line.StartsWith(cTag))
				continue;
			var word = line.Substring(cTag.Length);
			word.Trim();
			outLine = number;
			if (word == "lit")
				return .Lit;
			if (word == "unlit")
				return .Unlit;
			outBad = word;
			return .None;
		}
		return .None;
	}

	/// Whether the text defines `void Vertex(` outside a comment (a commented-out example in a
	/// starter is not one).
	public static bool DefinesVertexFunction(StringView text)
	{
		bool IsIdent(char8 c) => c.IsLetterOrDigit || (c == '_');
		let n = text.Length;
		int i = 0;
		while (i < n)
		{
			if ((text[i] == '/') && (i + 1 < n) && (text[i + 1] == '/'))
			{
				while ((i < n) && (text[i] != '\n'))
					i++;
				continue;
			}
			if ((text[i] == '/') && (i + 1 < n) && (text[i + 1] == '*'))
			{
				i += 2;
				while ((i + 1 < n) && !((text[i] == '*') && (text[i + 1] == '/')))
					i++;
				i += 2;
				continue;
			}
			if ((i + 4 < n) && (text.Substring(i, 4) == "void") && ((i == 0) || !IsIdent(text[i - 1])) && !IsIdent(text[i + 4]))
			{
				var k = i + 4;
				while ((k < n) && text[k].IsWhiteSpace)
					k++;
				if ((k + 6 <= n) && (text.Substring(k, 6) == "Vertex"))
				{
					k += 6;
					while ((k < n) && ((text[k] == ' ') || (text[k] == '\t')))
						k++;
					if ((k < n) && (text[k] == '('))
						return true;
				}
			}
			i++;
		}
		return false;
	}

	/// One of a surface shader's programs: the engine's API, the author's (expanded) text with its
	/// own line numbers, the glue and the pass's template.
	public static void SurfaceProgramText(StringView expanded, StringView file, SurfaceModel model, bool hasVertex,
		bool hasAlphaCutoff, StringView passTemplate, String outText)
	{
		outText.Append("// preserve-interface\n"); // a variant that does not read an input keeps it
		outText.Append("#define SURFACE_PROGRAM 1\n");
		outText.Append((model == .Lit) ? "#define SURFACE_LIT 1\n" : "#define SURFACE_UNLIT 1\n");
		if (hasVertex)
			outText.Append("#define SURFACE_HAS_VERTEX 1\n");
		if (hasAlphaCutoff)
			outText.Append("#define SURFACE_HAS_ALPHA_CUTOFF 1\n");
		outText.Append("#include \"surface/surface.hlsli\"\n");
		outText.AppendF("#line 1 \"{}\"\n", file);
		outText.Append(expanded);
		outText.AppendF("\n#include \"surface/glue.hlsli\"\n#include \"surface/{}\"\n", passTemplate);
	}

	private void Fail(StringView file, uint32 line, StringView message)
	{
		let diagnostic = new ShaderDiagnostic();
		diagnostic.File.Set(file);
		diagnostic.Line = line;
		diagnostic.Message.Set(message);
		Errors.Add(diagnostic);
	}

	/// Reads the errors out of DXC's message text, one per `path:line:col: error: message` line
	/// (or `fatal error:`); notes, warnings, the source excerpts and the caret lines are skipped.
	/// The path is split off from its right, so a drive letter's colon stays in it. True when at
	/// least one error was found.
	public static bool ParseCompilerDiagnostics(StringView messages, List<ShaderDiagnostic> outErrors)
	{
		StringView[2] markers = .(": fatal error: ", ": error: ");
		var found = false;
		for (var line in messages.Split('\n'))
		{
			if (line.EndsWith('\r'))
				line.RemoveFromEnd(1);
			for (let marker in markers)
			{
				let at = line.IndexOf(marker);
				if (at < 0)
					continue;
				// `path:line:col` before the marker.
				let location = line.Substring(0, at);
				let columnColon = location.LastIndexOf(':');
				let lineColon = (columnColon > 0) ? location.Substring(0, columnColon).LastIndexOf(':') : -1;
				if (lineColon < 0)
					break;
				let lineNumber = uint32.Parse(location.Substring(lineColon + 1, columnColon - lineColon - 1));
				let columnNumber = uint32.Parse(location.Substring(columnColon + 1));
				if ((lineNumber case .Err) || (columnNumber case .Err))
					break;
				let diagnostic = new ShaderDiagnostic();
				diagnostic.File.Set(location.Substring(0, lineColon));
				diagnostic.Line = lineNumber.Value;
				diagnostic.Column = columnNumber.Value;
				diagnostic.Message.Set(line.Substring(at + marker.Length));
				outErrors.Add(diagnostic);
				found = true;
				break;
			}
		}
		return found;
	}
}
