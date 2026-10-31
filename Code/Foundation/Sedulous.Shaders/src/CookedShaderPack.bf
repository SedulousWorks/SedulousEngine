using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;

namespace Sedulous.Shaders;

/// A compiler free store of cooked shader variants, keyed by name, stage, flags and format.
///
/// A shipped build carries no DXC and no naga: every variant the runtime can request is
/// precompiled into this at export time and looked up by the distribution's source provider.
/// One pack can hold several formats, since a desktop build may ship SPIR-V and DXIL
/// together; an export stages only the target backend's.
///
/// It is self describing on purpose, carrying the name table, so tooling can still enumerate
/// what is inside without a separate manifest.
class CookedShaderPack
{
	/// "DSPK" little endian.
	private const uint32 cMagic = 0x4b505344;
	/// Version 2 added the declared mask table; 3 the entry point table; 4 the effect tables. An
	/// older pack is refused: it would run every stage as `main`, so the export cooks it again
	/// (and below 4 too: a pack is cooked with the engine that reads it).
	private const uint32 cVersion = 4;

	private class Entry
	{
		public uint64 NameHash;
		public ShaderStage Stage;
		public ShaderFlags Flags;
		public CookedShaderFormat Format;
		public List<uint8> Blob = new List<uint8>() ~ delete _;
	}

	private List<Entry> mEntries = new List<Entry>() ~ DeleteContainerAndItems!(_);
	/// Combined key to index into mEntries.
	private Dictionary<uint64, int> mIndex = new Dictionary<uint64, int>() ~ delete _;
	/// Name hash to name, for enumeration.
	private Dictionary<uint64, String> mNames = new Dictionary<uint64, String>()
		~ DeleteDictionaryAndValues!(_);
	/// Mask key to the declared flag bits.
	private Dictionary<uint64, uint32> mDeclaredMasks = new Dictionary<uint64, uint32>() ~ delete _;
	/// Mask key to the entry point that stage was cooked for.
	private Dictionary<uint64, String> mEntryPoints = new .() ~ DeleteDictionaryAndValues!(_);
	/// The corpus's effect tables.
	private ShaderEffectLibrary mEffects = new .() ~ delete _;

	/// Records a copy of an effect's table (an `effect` block of the corpus's includes), so a
	/// game reads an effect's parameters without its sources. False, with the reason, when its
	/// name or its flag is already recorded.
	public bool AddEffect(ShaderEffect effect, String outError) => mEffects.Add(effect, outError);

	/// The effect tables the cook recorded. Stable while the pack is not modified.
	public ShaderEffectLibrary Effects => mEffects;

	public int Count => mEntries.Count;
	public bool IsEmpty => mEntries.IsEmpty;

	/// Adds one cooked variant, copying the blob.
	///
	/// Re-adding a variant OVERWRITES in place rather than appending: a pushed duplicate
	/// would stay orphaned in the entry list and be serialised, and counted, twice.
	public void Add(StringView name, ShaderStage stage, ShaderFlags flags,
		CookedShaderFormat format, Span<uint8> blob)
	{
		let nameHash = ShaderFlagNames.ShaderNameHash(name);
		if (!mNames.ContainsKey(nameHash))
			mNames[nameHash] = new String(name);

		let key = CombineKey(nameHash, stage, flags, format);
		if (mIndex.TryGetValue(key, let existing))
		{
			FillEntry(mEntries[existing], nameHash, stage, flags, format, blob);
			return;
		}

		let entry = new Entry();
		FillEntry(entry, nameHash, stage, flags, format, blob);
		mIndex[key] = mEntries.Count;
		mEntries.Add(entry);
	}

	private static void FillEntry(Entry entry, uint64 nameHash, ShaderStage stage,
		ShaderFlags flags, CookedShaderFormat format, Span<uint8> blob)
	{
		entry.NameHash = nameHash;
		entry.Stage = stage;
		entry.Flags = flags;
		entry.Format = format;
		entry.Blob.Clear();
		if (!blob.IsEmpty)
			entry.Blob.AddRange(blob);
	}

	/// Records a stage's declared variant mask so a shipped runtime can canonicalize a
	/// request onto a variant that was actually cooked.
	///
	/// The cook calls this once per stage. Absent means None, which is single variant.
	public void AddDeclaredMask(StringView name, ShaderStage stage, ShaderFlags mask)
	{
		mDeclaredMasks[MaskKey(ShaderFlagNames.ShaderNameHash(name), stage)] = (uint32)mask;
	}

	/// The declared mask for a name and stage, or None when the stage declared none or is
	/// absent entirely.
	public ShaderFlags DeclaredMask(uint64 nameHash, ShaderStage stage)
	{
		if (mDeclaredMasks.TryGetValue(MaskKey(nameHash, stage), let mask))
			return (ShaderFlags)mask;
		return .None;
	}

	public ShaderFlags DeclaredMask(StringView name, ShaderStage stage)
		=> DeclaredMask(ShaderFlagNames.ShaderNameHash(name), stage);

	/// Records the entry point a stage was cooked for, its function's name in the source; the
	/// runtime gives it to the module it creates, so pipelines run the function the source
	/// declares. The cook calls this once per stage.
	public void AddEntryPoint(StringView name, ShaderStage stage, StringView entryPoint)
	{
		let key = MaskKey(ShaderFlagNames.ShaderNameHash(name), stage);
		if (mEntryPoints.TryGetValue(key, let existing))
			existing.Set(entryPoint);
		else
			mEntryPoints[key] = new String(entryPoint);
	}

	/// The entry point a name and stage were cooked for; empty when the stage is absent.
	/// Stable while the pack is not modified.
	public StringView EntryPoint(uint64 nameHash, ShaderStage stage)
	{
		if (mEntryPoints.TryGetValue(MaskKey(nameHash, stage), let entryPoint))
			return entryPoint;
		return default;
	}

	public StringView EntryPoint(StringView name, ShaderStage stage)
		=> EntryPoint(ShaderFlagNames.ShaderNameHash(name), stage);

	/// The cooked blob, or an empty span when absent, which at runtime is a cook coverage
	/// bug rather than a normal miss.
	public Result<Span<uint8>> Find(uint64 nameHash, ShaderStage stage, ShaderFlags flags,
		CookedShaderFormat format)
	{
		if (mIndex.TryGetValue(CombineKey(nameHash, stage, flags, format), let index))
			return .Ok(mEntries[index].Blob);
		return .Err;
	}

	public Result<Span<uint8>> Find(StringView name, ShaderStage stage, ShaderFlags flags,
		CookedShaderFormat format)
		=> Find(ShaderFlagNames.ShaderNameHash(name), stage, flags, format);

	/// Every variant the pack holds for a name and stage.
	///
	/// Diagnostic: the runtime miss path reports what WAS cooked against the request that
	/// missed, so a coverage gap shows its shape, a wrong format or wrong flags, instead of
	/// just "missing".
	public void ForEachVariant(uint64 nameHash, ShaderStage stage,
		delegate void(ShaderFlags flags, CookedShaderFormat format) visit)
	{
		for (let entry in mEntries)
		{
			if ((entry.NameHash == nameHash) && (entry.Stage == stage))
				visit(entry.Flags, entry.Format);
		}
	}

	/// The distinct shader names in the pack, appended as owned strings.
	public void CollectNames(List<String> outNames)
	{
		for (let pair in mNames)
			outNames.Add(new String(pair.value));
	}

	public Result<void> Write(IStream stream)
	{
		let writer = scope BinaryWriter(stream);
		writer.Write<uint32>(cMagic);
		writer.Write<uint32>(cVersion);

		writer.Write<uint32>((uint32)mNames.Count);
		for (let pair in mNames)
		{
			writer.Write<uint64>(pair.key);
			writer.WriteString(pair.value);
		}

		writer.Write<uint32>((uint32)mDeclaredMasks.Count);
		for (let pair in mDeclaredMasks)
		{
			writer.Write<uint64>(pair.key);
			writer.Write<uint32>(pair.value);
		}

		writer.Write<uint32>((uint32)mEntryPoints.Count);
		for (let pair in mEntryPoints)
		{
			writer.Write<uint64>(pair.key);
			writer.WriteString(pair.value);
		}

		writer.Write<uint32>((uint32)mEntries.Count);
		for (let entry in mEntries)
		{
			writer.Write<uint64>(entry.NameHash);
			writer.Write<uint32>((uint32)entry.Stage);
			writer.Write<uint32>((uint32)entry.Flags);
			writer.Write<uint32>((uint32)entry.Format);
			writer.Write<uint32>((uint32)entry.Blob.Count);
			writer.WriteBytes(entry.Blob);
		}

		writer.Write<uint32>((uint32)mEffects.Count);
		for (let effect in mEffects.All)
		{
			writer.WriteString(effect.Name);
			writer.Write<uint32>((uint32)effect.Flag);
			writer.Write<uint32>(effect.GateIndex);
			writer.Write<uint32>(effect.UniformSize);
			writer.Write<uint32>((uint32)effect.Properties.Count);
			for (let property in effect.Properties)
			{
				writer.WriteString(property.Name);
				writer.Write<uint32>((uint32)property.Type);
				writer.Write<float>(property.Value.X);
				writer.Write<float>(property.Value.Y);
				writer.Write<float>(property.Value.Z);
				writer.Write<float>(property.Value.W);
				writer.Write<uint32>(property.HasRange ? 1 : 0);
				writer.Write<float>(property.RangeMin);
				writer.Write<float>(property.RangeMax);
				writer.Write<uint32>(property.Line);
				writer.Write<uint32>(property.Offset);
				writer.Write<uint32>(property.Size);
				writer.Write<uint32>(property.Binding);
			}
		}
		return writer.IsOk ? .Ok : .Err;
	}

	public Result<void> Read(IStream stream)
	{
		Clear();

		let reader = scope BinaryReader(stream);
		uint32 magic = 0;
		uint32 version = 0;
		reader.Read<uint32>(out magic);
		reader.Read<uint32>(out version);
		if (!reader.IsOk || (magic != cMagic) || (version != cVersion))
			return .Err;

		if (ReadNames(reader, stream) case .Err)
			return .Err;
		if (ReadMasks(reader, stream) case .Err)
			return .Err;
		if (ReadEntryPoints(reader, stream) case .Err)
			return .Err;
		if (ReadEntries(reader, stream) case .Err)
			return .Err;
		if (!reader.IsOk)
			return .Err;
		if (ReadEffects(reader, stream) case .Err)
			return .Err;

		return reader.IsOk ? .Ok : .Err;
	}

	/// How many bytes are left in the stream.
	///
	/// Every count and length read below is bounded by this, so a truncated or corrupt pack
	/// fails cleanly instead of attempting a multi gigabyte allocation on a garbage length.
	private static uint64 Remaining(IStream stream)
	{
		let size = stream.Size();
		let position = stream.Tell();
		if ((size < 0) || (position < 0) || (size <= position))
			return 0;
		return (uint64)(size - position);
	}

	private Result<void> ReadNames(BinaryReader reader, IStream stream)
	{
		uint32 count = 0;
		reader.Read<uint32>(out count);
		// Hash and length are 12 bytes minimum per record.
		if (count > Remaining(stream) / 12)
			return .Err;

		for (uint32 i = 0; (i < count) && reader.IsOk; ++i)
		{
			uint64 nameHash = 0;
			reader.Read<uint64>(out nameHash);
			let name = new String();
			reader.ReadString(name);
			if (mNames.TryGetValue(nameHash, let existing))
			{
				delete existing;
				mNames[nameHash] = name;
			}
			else
			{
				mNames[nameHash] = name;
			}
		}
		return .Ok;
	}

	private Result<void> ReadMasks(BinaryReader reader, IStream stream)
	{
		uint32 count = 0;
		reader.Read<uint32>(out count);
		// Key and mask are 12 bytes per record.
		if (count > Remaining(stream) / 12)
			return .Err;

		for (uint32 i = 0; (i < count) && reader.IsOk; ++i)
		{
			uint64 key = 0;
			uint32 mask = 0;
			reader.Read<uint64>(out key);
			reader.Read<uint32>(out mask);
			mDeclaredMasks[key] = mask;
		}
		return .Ok;
	}

	private Result<void> ReadEntryPoints(BinaryReader reader, IStream stream)
	{
		uint32 count = 0;
		reader.Read<uint32>(out count);
		// Key and length are 12 bytes minimum per record.
		if (count > Remaining(stream) / 12)
			return .Err;

		for (uint32 i = 0; (i < count) && reader.IsOk; ++i)
		{
			uint64 key = 0;
			reader.Read<uint64>(out key);
			let entryPoint = scope String();
			reader.ReadString(entryPoint);
			if (mEntryPoints.TryGetValue(key, let existing))
				existing.Set(entryPoint);
			else
				mEntryPoints[key] = new String(entryPoint);
		}
		return .Ok;
	}

	private Result<void> ReadEntries(BinaryReader reader, IStream stream)
	{
		uint32 count = 0;
		reader.Read<uint32>(out count);
		// The fixed header of an entry is 24 bytes.
		if (count > Remaining(stream) / 24)
			return .Err;

		for (uint32 i = 0; (i < count) && reader.IsOk; ++i)
		{
			let entry = new Entry();
			uint32 stage = 0;
			uint32 flags = 0;
			uint32 format = 0;
			uint32 blobLength = 0;
			reader.Read<uint64>(out entry.NameHash);
			reader.Read<uint32>(out stage);
			reader.Read<uint32>(out flags);
			reader.Read<uint32>(out format);
			reader.Read<uint32>(out blobLength);
			entry.Stage = (ShaderStage)stage;
			entry.Flags = (ShaderFlags)flags;
			entry.Format = (CookedShaderFormat)format;

			if (!reader.IsOk || ((uint64)blobLength > Remaining(stream)))
			{
				delete entry;
				return .Err;
			}

			if (blobLength > 0)
			{
				entry.Blob.Count = (int)blobLength;
				reader.ReadBytes(.(entry.Blob.Ptr, (int)blobLength));
			}
			if (!reader.IsOk)
			{
				delete entry;
				break;
			}

			mIndex[CombineKey(entry.NameHash, entry.Stage, entry.Flags, entry.Format)] =
				mEntries.Count;
			mEntries.Add(entry);
		}
		return .Ok;
	}

	private Result<void> ReadEffects(BinaryReader reader, IStream stream)
	{
		uint32 count = 0;
		reader.Read<uint32>(out count);
		// A name's length, the flag, the gate, the size and the count: 20 bytes minimum.
		if (count > Remaining(stream) / 20)
			return .Err;

		let error = scope String();
		for (uint32 i = 0; (i < count) && reader.IsOk; ++i)
		{
			let effect = scope ShaderEffect();
			uint32 flag = 0;
			uint32 propertyCount = 0;
			reader.ReadString(effect.Name);
			reader.Read<uint32>(out flag);
			reader.Read<uint32>(out effect.GateIndex);
			reader.Read<uint32>(out effect.UniformSize);
			reader.Read<uint32>(out propertyCount);
			effect.Flag = (ShaderFlags)flag;
			// The fixed bytes of a property: 52.
			if (!reader.IsOk || (propertyCount > Remaining(stream) / 52))
				return .Err;
			for (uint32 k = 0; (k < propertyCount) && reader.IsOk; ++k)
			{
				let property = new ShaderProperty();
				effect.Properties.Add(property);
				uint32 type = 0;
				uint32 hasRange = 0;
				reader.ReadString(property.Name);
				reader.Read<uint32>(out type);
				reader.Read<float>(out property.Value.X);
				reader.Read<float>(out property.Value.Y);
				reader.Read<float>(out property.Value.Z);
				reader.Read<float>(out property.Value.W);
				reader.Read<uint32>(out hasRange);
				reader.Read<float>(out property.RangeMin);
				reader.Read<float>(out property.RangeMax);
				reader.Read<uint32>(out property.Line);
				reader.Read<uint32>(out property.Offset);
				reader.Read<uint32>(out property.Size);
				reader.Read<uint32>(out property.Binding);
				property.Type = (ShaderPropertyType)type;
				property.HasRange = hasRange != 0;
			}
			// A cook records each effect once.
			if (!reader.IsOk || !mEffects.Add(effect, error))
				return .Err;
		}
		return .Ok;
	}

	private void Clear()
	{
		mEffects.Clear();
		ClearAndDeleteItems!(mEntries);
		mIndex.Clear();
		for (let pair in mNames)
			delete pair.value;
		mNames.Clear();
		mDeclaredMasks.Clear();
		for (let pair in mEntryPoints)
			delete pair.value;
		mEntryPoints.Clear();
	}

	private static uint64 MaskKey(uint64 nameHash, ShaderStage stage)
		=> (nameHash << 4) ^ (uint64)stage;

	private static uint64 CombineKey(uint64 nameHash, ShaderStage stage, ShaderFlags flags,
		CookedShaderFormat format)
	{
		// The FNV prime spreads the name hash before the small fields are folded in, so two
		// names differing in one bit do not land in adjacent buckets.
		var key = nameHash &* FnvPrime;
		key ^= ((uint64)stage << 16) | ((uint64)flags << 3) | (uint64)format;
		return key;
	}
}
