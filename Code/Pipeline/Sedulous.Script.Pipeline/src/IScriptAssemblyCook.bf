using System;
using System.Collections;
using Sedulous.Script.Resource;

namespace Sedulous.Script.Pipeline;

/// One source file of a project assembly: its path in the sources and its text.
class ScriptAssemblyFile
{
	public String Path = new .() ~ delete _;
	public String Text = new .() ~ delete _;
}

/// A language's project build, for a language whose classes build together: the project file
/// and every source of the language under its folder, built into one assembly with every public
/// class described. Registered in ScriptAssemblyCooks by language, beside the language's class
/// cook (whose BuildsInAssembly says its classes cook from it).
interface IScriptAssemblyCook
{
	/// The project file's extension, lowercase without the dot.
	StringView ProjectExtension { get; }
	/// The sources' extension, lowercase without the dot.
	StringView SourceExtension { get; }
	/// Folded into the project builder's version: a toolchain change rebuilds.
	int32 CookVersion => 0;

	/// Builds `projectPath` (its text `project`) with `sources` into `outAssembly`: the image, its
	/// symbols, every public class's description. Problems, each at its file and line, into
	/// `problems`. False when it does not build.
	bool Build(StringView projectPath, StringView project, Span<ScriptAssemblyFile> sources, ScriptAssemblySource outAssembly,
		List<String> problems);

	/// The project file a project named `name` starts with.
	void NewProjectTemplate(StringView name, String outText);

	/// Files this machine's tools read beside a project (an IDE's path to the engine), each a path
	/// relative to the project's folder and its text. Written when the project is made and at every
	/// cook, they keep the project file itself free of any one machine's paths; never an input to
	/// the build, and kept out of version control. None by default.
	void LocalFiles(List<ScriptAssemblyFile> outFiles) { }
}
