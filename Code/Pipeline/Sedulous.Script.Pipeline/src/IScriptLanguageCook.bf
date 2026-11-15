using System;
using System.Collections;
using Sedulous.Script;
using Sedulous.Script.Resource;

namespace Sedulous.Script.Pipeline;

/// The per language cook: compile checks the source and harvests the class record from
/// it. A language's library provides one and registers it by language id, mirroring the
/// backends; the builder resolves it and never names a language.
interface IScriptLanguageCook
{
	/// Folded into the builder's version: bump when the cook's output changes.
	int32 CookVersion => 1;

	/// A hash of the surface the cook compiles against (ScriptSurface.RuntimeHash), folded into
	/// the products' recipes so a changed surface (a plugin enabled, removed or updated) recooks
	/// them; nought: none.
	uint64 SurfaceHash => 0;

	/// The source a new asset of this language and tier starts with. A behaviour's class is
	/// `className` (a valid identifier: ScriptCreators.ClassNameFor makes one); the level and
	/// game tiers keep their reserved class names and ignore it.
	void NewAssetTemplate(ScriptTier tier, StringView className, String outSource);

	/// Compiles `source` and harvests the class it plays into the record, reporting anything
	/// wrong into `problems`. The class is ScriptClasses.Choose's by `className` (the asset's
	/// recorded class; empty: the one named like `sourceName`'s file): that one, else the
	/// source's only class. False when the source does not compile, or declares several classes
	/// and none so named.
	/// The files the source includes are read through `includes` (null: none can be, so a script
	/// that includes one fails), and recorded in the record's Includes.
	bool Cook(StringView source, StringView sourceName, StringView className, ScriptClassSource outRecord, List<String> problems,
		IScriptIncludeReader includes = null);

	/// Compile checks `source` as Cook would, WITHOUT running any of it and without the
	/// harvest: the problems into `problems`, the class it plays (chosen by `className` as Cook
	/// chooses it; empty when it declares none) into `outClassName`. For checking a script as it
	/// is typed. False when it does not compile or the class cannot be chosen. Against the
	/// surface less the `hidden` types (by full name): a platform without a plugin lacks that
	/// plugin's types, and a script that uses one does not compile there.
	bool Check(StringView source, StringView sourceName, StringView className, String outClassName, List<String> problems, Span<StringView> hidden,
		IScriptIncludeReader includes = null);

	/// The paths `source`'s include directives name, as written, in order (none for a language
	/// without one): resolved, they are the files a cook depends on.
	void ListIncludes(StringView source, List<String> outPaths) { }

	/// Builds what Check uses before the first check needs it, so a project's first script page
	/// does not wait for it. Callable from a worker thread.
	void PrepareCheck() { }

	/// The API a script checked here can use, described for completion and the API browser, when
	/// `surface` is the one the cook checks against: true then. False, `outTypes` untouched, for
	/// another surface or a cook that keeps nothing for its checks.
	bool DescribeApi(ScriptSurface surface, List<ScriptApiType> outTypes) => false;

	/// How many times Check has made the runtime it keeps for checks: once, and again each time
	/// the surface changes. 0 for a language whose every check builds its own.
	uint32 CheckRuntimeBuildCount => 0;
}
