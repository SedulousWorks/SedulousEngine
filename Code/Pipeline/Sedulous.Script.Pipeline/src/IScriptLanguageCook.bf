using System;
using System.Collections;
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
	bool Cook(StringView source, StringView sourceName, StringView className, ScriptClassSource outRecord, List<String> problems);

	/// Compile checks `source` as Cook would, WITHOUT running any of it and without the
	/// harvest: the problems into `problems`, the class it plays (chosen by `className` as Cook
	/// chooses it; empty when it declares none) into `outClassName`. For checking a script as it
	/// is typed. False when it does not compile or the class cannot be chosen. Against the
	/// surface less the `hidden` types (by full name): a platform without a plugin lacks that
	/// plugin's types, and a script that uses one does not compile there.
	bool Check(StringView source, StringView sourceName, StringView className, String outClassName, List<String> problems, Span<StringView> hidden);
}
