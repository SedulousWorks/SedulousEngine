using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;

namespace Sedulous.Pipeline.Importer;

/// The path and plan work every importer repeats.
///
/// Hand written rather than reached for from the core path helpers: these take and give
/// STRING VIEWS into the caller's own path, so the common cases cost no allocation, and the
/// lowercase rule for extensions is the routing key rather than a formatting choice.
static class ImportPaths
{
	/// The lowercased extension of a path, without the dot, appended to `outExtension`.
	public static void ExtensionLower(StringView path, String outExtension)
	{
		var dot = path.Length;
		for (int i = path.Length; i > 0; --i)
		{
			let c = path[i - 1];
			if (c == '.')
			{
				dot = i;
				break;
			}
			if ((c == '/') || (c == '\\'))
				break;
		}
		for (int i = dot; i < path.Length; ++i)
		{
			let c = path[i];
			outExtension.Append(((c >= 'A') && (c <= 'Z')) ? (char8)(c + 32) : c);
		}
	}

	/// The final path component: "/a/b/foo.png" gives "foo.png".
	public static StringView FileNameOf(StringView path)
	{
		for (int i = path.Length; i > 0; --i)
		{
			let c = path[i - 1];
			if ((c == '/') || (c == '\\'))
				return path.Substring(i);
		}
		return path;
	}

	/// The stem, which is what an instance gets named: "foo.png" gives "foo".
	public static StringView StemOf(StringView fileName)
	{
		for (int i = fileName.Length; i > 0; --i)
		{
			if (fileName[i - 1] == '.')
				return fileName.Substring(0, i - 1);
		}
		return fileName;
	}

	/// The plan of a SINGLE asset importer: one entry named after the file's stem. The shared
	/// DescribeImport for a texture, an image, audio, a font, a heightfield or a splat map.
	public static void SingleAssetPlan(StringView sourcePath, ImportPlan outPlan)
	{
		let stem = StemOf(FileNameOf(sourcePath));
		outPlan.Add(new ImportPlanEntry(.Asset, stem, stem));
	}

	/// The instance name a single asset importer should CLAIM: the user's rename when the
	/// selection carries one, and the stem otherwise.
	public static StringView SingleAssetName(ImportOptions options, StringView stem)
		=> (options != null) ? options.SelectionName(.Asset, stem) : stem;

	/// Re-import memory for a single asset importer: the asset a PREVIOUS import of this source
	/// created in the group, with its CURRENT name as the stored rename.
	///
	/// Matched by the typed file name back reference rather than by name, so an asset the user
	/// renamed is still found. The type name filters candidates before the envelope read,
	/// which is the expensive part.
	public static void SingleAssetStoredSelection(Group group, StringView sourcePath,
		StringView typeName, ImportPlan outPlan)
	{
		let fileName = FileNameOf(sourcePath);
		if (fileName.IsEmpty)
			return;

		for (let instance in group.Instances)
		{
			if (instance.TypeName != typeName)
				continue;

			// THE CALLER OWNS what the read returns.
			let object = instance.ReadObject();
			if (object == null)
				continue;
			defer delete object;

			// An interface handle reaches its class through the object it is part of.
			let asset = Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object)) as Asset;
			if ((asset == null) || (asset.FileName.Value != fileName))
				continue;

			outPlan.Add(new ImportPlanEntry(.Asset, StemOf(fileName), instance.Name));
			return;
		}
	}

	// === the import ledger ===

	/// Where a project keeps its import ledger: `<cacheRoot>/imports.txt`, the project's cache,
	/// ignored by version control (an OS path is the importing machine's, never the project's).
	public static void ImportLedgerPath(StringView cacheRoot, String outPath) => PathJoin(cacheRoot, "imports.txt", outPath);

	/// Appends the OS file `sourcesName` (a file under the sources tree) was last imported from;
	/// nothing when the ledger does not say (no ledger, a file from before it, or one copied in by
	/// hand).
	public static void ImportOriginOf(StringView ledgerPath, StringView sourcesName, String outOrigin)
	{
		if (ledgerPath.IsEmpty)
			return;
		let bytes = scope List<uint8>();
		if (ReadFile(ledgerPath, bytes) case .Err)
			return;
		let found = scope String();
		for (let line in StringView((char8*)bytes.Ptr, bytes.Count).Split('\n'))
		{
			let tab = line.IndexOf('\t');
			if ((tab >= 0) && (line.Substring(0, tab) == sourcesName))
				found.Set(line.Substring(tab + 1)); // the last line for it wins
		}
		outOrigin.Append(found);
	}

	/// The data stream an import's primary asset keeps its settings in (ImportOptions.SettingsText).
	public const String cImportSettingsStream = "importSettings";

	/// Records `options`' settings with `primary` (the asset an import made first), so a reimport
	/// starts from them; nothing when the importer has no settings.
	public static void RecordImportSettings(Instance primary, ImportOptions options)
	{
		if ((primary == null) || (options == null) || !options.HasSettings)
			return;
		let text = options.SettingsText(.. scope .());
		primary.WriteData(cImportSettingsStream, Span<uint8>((uint8*)text.Ptr, text.Length), .Text).IgnoreError();
	}

	/// The settings `instance` recorded (RecordImportSettings), appended; nothing when it has none.
	public static void RecordedImportSettings(Instance instance, String outText)
	{
		let stream = instance.ReadData(cImportSettingsStream);
		if (stream == null)
			return;
		defer delete stream;
		let size = (int)stream.Size();
		if (size <= 0)
			return;
		let bytes = scope List<uint8>();
		bytes.GrowUninitialized(size);
		if (stream.Read(Span<uint8>(bytes.Ptr, size)) != size)
			return;
		outText.Append((char8*)bytes.Ptr, size);
	}

	/// Notes that `sourcesName` came from `origin`, its line replaced.
	public static void RecordImportOrigin(StringView ledgerPath, StringView sourcesName, StringView origin)
	{
		if (ledgerPath.IsEmpty)
			return;
		let text = scope String();
		let bytes = scope List<uint8>();
		if (ReadFile(ledgerPath, bytes) case .Ok)
		{
			for (let line in StringView((char8*)bytes.Ptr, bytes.Count).Split('\n'))
			{
				let tab = line.IndexOf('\t');
				if (line.IsEmpty || ((tab >= 0) && (line.Substring(0, tab) == sourcesName)))
					continue;
				text.Append(line, "\n");
			}
		}
		text.Append(sourcesName, "\t", origin, "\n");
		let folder = PathParent(ledgerPath, .. scope .());
		if (!folder.IsEmpty && !DirectoryExists(folder))
			CreateDirectory(folder);
		WriteFile(ledgerPath, .((uint8*)text.Ptr, text.Length)).IgnoreError();
	}

	private static bool SameBytes(List<uint8> a, List<uint8> b)
	{
		if (a.Count != b.Count)
			return false;
		for (int i < a.Count)
		{
			if (a[i] != b[i])
				return false;
		}
		return true;
	}

	/// The name under the sources tree a copy of `sourcePath` takes, from what is there and the
	/// ledger alone: its own file name when that is free or this file's own copy (`mayOverwrite`,
	/// or the ledger saying it came from `sourcePath`); else, when that name is ANOTHER file's (the
	/// ledger names another origin, or the caller says it may not overwrite), the next free one
	/// ("a.2.png"), unless the bytes there are `bytes` (shared, nothing lost). Noted in the ledger
	/// as `sourcePath`'s. For a copy made later (a deferred write); CopyIntoSources copies at once.
	public static void SourcesNameFor(ImportContext context, StringView sourcePath, String outName,
		bool mayOverwrite = true, List<uint8> bytes = null)
	{
		let fileName = FileNameOf(sourcePath);
		let stem = StemOf(fileName);
		let @extension = fileName.Substring(stem.Length); // with its dot
		let name = scope String(fileName);
		let target = scope String();
		let origin = scope String();
		for (int n = 2; ; n++)
		{
			target.Clear();
			PathJoin(context.SourcesRoot, name, target);
			if (!FileExists(target))
				break;
			origin.Clear();
			ImportOriginOf(context.LedgerPath, name, origin);
			if (origin.IsEmpty ? mayOverwrite : (origin == sourcePath))
				break; // this file's own copy
			if (bytes != null)
			{
				let existing = scope List<uint8>();
				if ((ReadFile(target, existing) case .Ok) && SameBytes(existing, bytes))
					break; // the very same bytes: shared, nothing lost
			}
			name.Clear();
			name.AppendF("{}.{}{}", stem, n, @extension); // another file's: the next name
		}
		RecordImportOrigin(context.LedgerPath, name, sourcePath);
		outName.Append(name);
	}

	/// Copies an OS file into the project's sources tree under SourcesNameFor's name, appending
	/// the sources relative name the asset should reference.
	///
	/// An existing file with the SAME bytes is left untouched, so nothing downstream re-cooks.
	/// CHANGED bytes overwrite this file's own copy (a re-import has to see the edited file; the
	/// older skip if present behaviour silently kept a stale source forever), and never another
	/// file's.
	public static Result<void, ErrorCode> CopyIntoSources(ImportContext context,
		StringView sourcePath, String outFileName, bool mayOverwrite = true)
	{
		if (FileNameOf(sourcePath).IsEmpty)
			return .Err(.InvalidArgument);

		let bytes = scope List<uint8>();
		if (ReadFile(sourcePath, bytes) case .Err(let error))
			return .Err(error);

		let name = scope String();
		SourcesNameFor(context, sourcePath, name, mayOverwrite, bytes);
		let target = scope String();
		PathJoin(context.SourcesRoot, name, target);

		if (FileExists(target))
		{
			let existing = scope List<uint8>();
			if ((ReadFile(target, existing) case .Ok) && SameBytes(existing, bytes))
			{
				outFileName.Append(name);
				return .Ok; // identical, so no touch and no re-cook churn
			}
		}

		if (WriteFile(target, bytes) case .Err(let writeError))
			return .Err(writeError);

		outFileName.Append(name);
		return .Ok;
	}

	// === name clashes ===

	/// The sources file an asset instance names, appended (nothing when it is not an Asset).
	private static void AssetFileOf(Instance instance, String outFileName)
	{
		// THE CALLER OWNS what the read returns.
		let object = instance.ReadObject();
		if (object == null)
			return;
		defer delete object;
		// An interface handle reaches its class through the object it is part of.
		if (let asset = Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object)) as Asset)
			outFileName.Append(asset.FileName.Value);
	}

	/// What taking `name` in `group` for a `typeName` asset made from `sourcePath` meets. A
	/// same-type asset whose source is this file's copy under the sources tree (the ledger saying it
	/// came from this path, or, saying nothing, the same file name) is this file's earlier import.
	public static void FindImportClash(Group group, StringView name, StringView typeName,
		StringView sourcePath, StringView ledgerPath, ImportClash outClash)
	{
		outClash.Clear();
		outClash.Name.Set(name);
		let existing = group.GetInstance(name);
		if (existing == null)
			return;
		outClash.Existing = existing;
		outClash.ExistingType.Set(existing.TypeName);
		if (existing.TypeName != typeName)
		{
			outClash.Kind = .OtherType;
			return;
		}
		outClash.Kind = .SameType;
		// Its file under the sources tree: this file's name, or a name the copy took beside another's ("a.2.png").
		let held = scope String();
		AssetFileOf(existing, held);
		if (held.IsEmpty)
			return;
		let origin = scope String();
		ImportOriginOf(ledgerPath, held, origin);
		if (!origin.IsEmpty)
		{
			if (origin == sourcePath)
				outClash.Kind = .Reimport;
			return;
		}
		if (held == FileNameOf(sourcePath))
			outClash.Kind = .Reimport; // before the ledger: the file name decides, as it did
	}

	/// The clash said for a person, appended: what holds the name and what to do.
	public static void DescribeImportClash(ImportClash clash, String outText)
	{
		switch (clash.Kind)
		{
		case .OtherType:
			outText.AppendF("'{}' is already a {} here: import it under another name.", clash.Name, clash.ExistingType);
		case .SameType:
			outText.AppendF("'{}' is already here, made from another file: replace it, or keep both.", clash.Name);
		case .None, .Reimport:
		}
	}

	/// Whether the import may go on over `clash` with `choice`.
	public static bool ImportClashAllows(ImportClash clash, ImportConflictChoice choice)
		=> (clash.Kind == .None) || (clash.Kind == .Reimport) || ((clash.Kind == .SameType) && (choice != .Refuse));

	/// The clash a SINGLE-ASSET importer's file meets: its Asset entry's target in `plan` (the
	/// user's rename), else the file's stem, for `typeName`. IFileImporter.FindClash's default.
	public static void SingleAssetClash(Group group, StringView sourcePath, StringView typeName,
		ImportPlan plan, StringView ledgerPath, ImportClash outClash)
	{
		let stem = StemOf(FileNameOf(sourcePath));
		let entry = (plan != null) ? plan.Find(.Asset, stem) : null;
		let name = ((entry != null) && !entry.TargetName.IsEmpty) ? StringView(entry.TargetName) : stem;
		FindImportClash(group, name, typeName, sourcePath, ledgerPath, outClash);
	}

	/// The asset a SINGLE-ASSET importer writes: its name (the user's, else the stem) claimed in
	/// `group` by the clash rule and the context's choice, and the file copied into the sources
	/// tree, never over another file's copy. `outFileName` gets the copy's name for the asset's
	/// file name. Refused (AlreadyExists) for an asset of another type, or of its type from another
	/// file when the choice is Refuse; nothing is copied or made then.
	public static Result<Instance, ErrorCode> ClaimSingleAsset(ImportContext context, Group group,
		ImportOptions options, StringView sourcePath, StringView typeName, String outFileName)
	{
		let stem = StemOf(FileNameOf(sourcePath));
		let name = scope String(SingleAssetName(options, stem));
		let clash = scope ImportClash();
		FindImportClash(group, name, typeName, sourcePath, context.LedgerPath, clash);
		if (!ImportClashAllows(clash, context.OnConflict))
			return .Err(.AlreadyExists);
		Instance reuse = null;
		var overwriteOwn = false; // its copy under the sources tree is the asset's own, to be overwritten
		if ((clash.Kind == .Reimport) || ((clash.Kind == .SameType) && (context.OnConflict == .Replace)))
		{
			reuse = clash.Existing;
			let held = scope String();
			AssetFileOf(reuse, held);
			overwriteOwn = held == FileNameOf(sourcePath);
		}
		else if (clash.Kind == .SameType)
		{
			let free = scope String();
			group.UniqueInstanceName(name, free); // KeepBoth
			name.Set(free);
		}
		let copied = scope String();
		if (CopyIntoSources(context, sourcePath, copied, overwriteOwn) case .Err(let error))
			return .Err(error);
		let instance = (reuse != null) ? reuse : group.CreateInstance(name, typeName);
		if (instance == null)
			return .Err(.Unknown);
		outFileName.Append(copied);
		return .Ok(instance);
	}
}
