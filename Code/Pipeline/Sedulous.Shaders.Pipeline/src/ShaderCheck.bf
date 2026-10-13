using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Shaders;

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

/// What a check found. `Expanded`, the masks and `Block` are valid whenever the properties block
/// parsed; `Errors` empty means the shader compiles at the depth asked.
class ShaderCheck
{
	public ShaderPropertiesBlock Block = new .() ~ delete _;
	public String Expanded = new .() ~ delete _;
	public ShaderFlags VertexMask = .None;
	public ShaderFlags FragmentMask = .None;
	public List<ShaderDiagnostic> Errors = new .() ~ DeleteContainerAndItems!(_);

	public bool IsOk => Errors.IsEmpty;

	/// Checks a shader's text as the cook would, saved as `file` (the name errors carry): the
	/// properties block expanded, both stages' variant lattices read, every flag the file tests
	/// declared, the variants compiled with DXC. The errors come back as data rather than logged:
	/// the cook logs them and fails, the editor's shader page puts them on the lines as you type,
	/// the MCP tools return them. One check, so the three never disagree about a shader.
	public void Run(StringView text, StringView file, ShaderCheckOptions options = .())
	{
		// The properties block becomes the set-2 declarations; `#line` keeps the author's line
		// numbers for everything after it.
		ShaderProperties.Expand(text, file, Expanded, Block);
		for (let error in Block.Errors)
			Fail(file, error.Line, error.Message);
		if (!Block.IsOk)
			return;

		// Each stage's lattice; a flag the file tests but no stage declares would never be
		// compiled (the corpus's drift lint, over both stages).
		VertexMask = ShaderVariants.ParseStageVariantDirective(text, .Vertex).Mask;
		FragmentMask = ShaderVariants.ParseStageVariantDirective(text, .Fragment).Mask;
		let undeclared = scope List<StringView>();
		ShaderVariants.FindUndeclaredFlagUses(text, VertexMask | FragmentMask, undeclared);
		for (let flag in undeclared)
			Fail(file, 0, scope $"tests {flag} but no stage declares it (add it to a // variants(vertex): or // variants(fragment): line)");
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

		let preserveInterface = ShaderVariants.ParsePreserveInterfaceDirective(text);
		StringView[1] includePaths = .(options.ShaderLibrary);
		(ShaderStage stage, StringView entryPoint, ShaderFlags mask)[2] stages = .(
			(.Vertex, options.VertexEntryPoint, VertexMask),
			(.Fragment, options.FragmentEntryPoint, FragmentMask));
		let variants = scope List<ShaderFlags>();
		let defines = scope List<ShaderDefine>();
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
					compile.IncludePaths = includePaths;
				compile.BindingShifts = BindingShifts.Standard;
				compile.BindingShiftSets = 4;
				compile.SourceName = file;
				compile.PreserveInterface = preserveInterface; // as the runtime compiles it
				var result = compiler.Compile(.((uint8*)Expanded.Ptr, Expanded.Length), stage.stage, stage.entryPoint,
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
				return;
			}
		}
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
