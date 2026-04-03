namespace Sedulous.ShaderReflection;

using System;
using System.Collections;
using System.Diagnostics;
using Sedulous.RHI;

/// Layout derivation utilities for shader reflection.
/// Given reflected shaders, derives bind group layouts, pipeline layouts, and vertex attributes.
static class ReflectionUtils
{
	/// Merges bindings from multiple reflected shaders into bind group layout entries.
	/// Bindings at the same (set, binding) are merged — their stage flags are OR'd together.
	/// Returns .Err if conflicting types are found at the same (set, binding).
	///
	/// outEntriesPerSet: one List<BindGroupLayoutEntry> per set index.
	///   Sets are sorted by index with empty lists for gaps.
	///   Caller owns the outer list and must DeleteContainerAndItems.
	public static Result<void> DeriveBindGroupLayouts(
		Span<ReflectedShader> shaders,
		List<List<BindGroupLayoutEntry>> outEntriesPerSet)
	{
		// Map of (set, binding) → merged entry
		var merged = scope Dictionary<uint64, BindGroupLayoutEntry>();

		for (let shader in shaders)
		{
			for (let b in shader.Bindings)
			{
				let key = ((uint64)b.Set << 32) | (uint64)b.Binding;

				if (merged.TryGetValue(key, var existing))
				{
					// Same (set, binding) — types must match
					if (existing.Type != b.Type)
					{
						Debug.WriteLine(scope String()..AppendF(
							"ReflectionUtils: binding conflict at set={} binding={}: {} vs {}",
							b.Set, b.Binding, existing.Type, b.Type));
						return .Err;
					}

					// Merge stage visibility
					existing.Visibility |= b.Stages;

					// Take the larger count (for arrays)
					if (b.Count > existing.Count)
						existing.Count = b.Count;

					merged[key] = existing;
				}
				else
				{
					// Convert ReflectedBinding → BindGroupLayoutEntry
					BindGroupLayoutEntry entry = default;
					entry.Binding = b.Binding;
					entry.Visibility = b.Stages;
					entry.Type = b.Type;
					entry.Count = b.Count == 0 ? uint32.MaxValue : b.Count; // 0 = bindless → MaxValue
					entry.Label = b.Name;
					entry.TextureDimension = b.TextureDimension;
					entry.TextureMultisampled = b.TextureMultisampled;
					merged[key] = entry;
				}
			}
		}

		// Determine max set index
		uint32 maxSet = 0;
		for (let (key, _) in merged)
		{
			let set = (uint32)(key >> 32);
			if (set > maxSet)
				maxSet = set;
		}

		// Build per-set entry lists
		if (merged.Count > 0)
		{
			for (uint32 s = 0; s <= maxSet; s++)
				outEntriesPerSet.Add(new List<BindGroupLayoutEntry>());

			for (let (key, entry) in merged)
			{
				let set = (uint32)(key >> 32);
				outEntriesPerSet[(int)set].Add(entry);
			}

			// Sort entries within each set by binding index
			for (let entries in outEntriesPerSet)
				entries.Sort(scope (a, b) => a.Binding <=> b.Binding);
		}

		return .Ok;
	}

	/// Derives push constant ranges from multiple reflected shaders.
	/// Merges ranges at the same offset by OR-ing stage flags.
	public static void DerivePushConstantRanges(
		Span<ReflectedShader> shaders,
		List<PushConstantRange> outRanges)
	{
		for (let shader in shaders)
		{
			for (let pc in shader.PushConstants)
			{
				// Check if a range with the same offset/size already exists
				bool found = false;
				for (int i = 0; i < outRanges.Count; i++)
				{
					if (outRanges[i].Offset == pc.Offset && outRanges[i].Size == pc.Size)
					{
						var existing = outRanges[i];
						existing.Stages |= pc.Stages;
						outRanges[i] = existing;
						found = true;
						break;
					}
				}

				if (!found)
				{
					outRanges.Add(.()
					{
						Offset = pc.Offset,
						Size = pc.Size,
						Stages = pc.Stages
					});
				}
			}
		}
	}

	/// Derives VertexAttribute array from a reflected vertex shader.
	/// Assigns sequential offsets based on format sizes, sorted by location.
	/// Caller should adjust offsets if using interleaved layouts with padding.
	public static void DeriveVertexAttributes(
		ReflectedShader vertexShader,
		List<VertexAttribute> outAttributes)
	{
		// Copy and sort by location
		var sorted = scope List<ReflectedVertexInput>();
		for (let input in vertexShader.VertexInputs)
			sorted.Add(input);
		sorted.Sort(scope (a, b) => a.Location <=> b.Location);

		uint32 offset = 0;
		for (let input in sorted)
		{
			outAttributes.Add(.()
			{
				Format = input.Format,
				Offset = offset,
				ShaderLocation = input.Location
			});
			offset += FormatByteSize(input.Format);
		}
	}

	/// Returns the byte size of a vertex format.
	public static uint32 FormatByteSize(VertexFormat format)
	{
		switch (format)
		{
		case .Uint8x2, .Sint8x2, .Unorm8x2, .Snorm8x2:       return 2;
		case .Uint8x4, .Sint8x4, .Unorm8x4, .Snorm8x4:       return 4;
		case .Uint16x2, .Sint16x2, .Unorm16x2, .Snorm16x2,
			 .Float16x2:                                        return 4;
		case .Uint16x4, .Sint16x4, .Unorm16x4, .Snorm16x4,
			 .Float16x4:                                        return 8;
		case .Float32:                                          return 4;
		case .Float32x2:                                        return 8;
		case .Float32x3:                                        return 12;
		case .Float32x4:                                        return 16;
		case .Uint32:                                           return 4;
		case .Uint32x2:                                         return 8;
		case .Uint32x3:                                         return 12;
		case .Uint32x4:                                         return 16;
		case .Sint32:                                           return 4;
		case .Sint32x2:                                         return 8;
		case .Sint32x3:                                         return 12;
		case .Sint32x4:                                         return 16;
		default:                                                return 4;
		}
	}
}
