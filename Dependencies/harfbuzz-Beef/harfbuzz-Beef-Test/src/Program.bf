using harfbuzz_Beef;
using System;
using System.IO;
using System.Collections;

namespace harfbuzz_Beef_Test;

/// Exercises the binding end to end against the real library: shape "office" in Roboto, which
/// ligates the "fi", and close the ligature's substitutions over the glyphs of "fi".
class Program
{
	/// Roboto ships in the engine's data; run from this folder or the repository.
	static bool FindFont(String outPath)
	{
		for (let candidate in StringView[]("../../Data/Assets/fonts/roboto/Roboto-Regular.ttf",
			"../../../Data/Assets/fonts/roboto/Roboto-Regular.ttf", "Data/Assets/fonts/roboto/Roboto-Regular.ttf"))
		{
			if (File.Exists(candidate))
			{
				outPath.Set(candidate);
				return true;
			}
		}
		return false;
	}

	static int Run()
	{
		let path = scope String();
		if (!FindFont(path))
		{
			Console.WriteLine("No Roboto-Regular.ttf found.");
			return 1;
		}
		let bytes = scope List<uint8>();
		if (File.ReadAll(path, bytes) case .Err)
			return 1;

		let blob = hb_blob_create((char8*)bytes.Ptr, (uint32)bytes.Count, .HB_MEMORY_MODE_READONLY, null, null);
		let face = hb_face_create(blob, 0);
		hb_blob_destroy(blob);
		let font = hb_font_create(face);
		defer hb_font_destroy(font);
		defer hb_face_destroy(face);

		uint32[6] text = .((.)'o', (.)'f', (.)'f', (.)'i', (.)'c', (.)'e');
		let buffer = hb_buffer_create();
		defer hb_buffer_destroy(buffer);
		hb_buffer_add_utf32(buffer, &text[0], 6, 0, 6);
		hb_buffer_set_cluster_level(buffer, .HB_BUFFER_CLUSTER_LEVEL_MONOTONE_CHARACTERS);
		hb_buffer_guess_segment_properties(buffer);
		hb_shape(font, buffer, null, 0);

		uint32 count = 0;
		let infos = hb_buffer_get_glyph_infos(buffer, &count);
		let positions = hb_buffer_get_glyph_positions(buffer, &count);
		Console.WriteLine("office: {} glyphs", count);
		for (uint32 i < count)
			Console.WriteLine("  glyph {} cluster {} advance {}", infos[i].codepoint, infos[i].cluster, positions[i].x_advance);
		if (hb_buffer_get_direction(buffer) != .HB_DIRECTION_LTR)
			return 1;
		// o, f, fi, c, e: the ligature starts at the second f, character 2.
		if ((count != 5) || (infos[2].cluster != 2) || (infos[3].cluster != 4))
			return 1;

		// The closure from f and i reaches the ligature.
		hb_codepoint_t f = 0, i = 0;
		if ((hb_font_get_nominal_glyph(font, (.)'f', &f) == 0) || (hb_font_get_nominal_glyph(font, (.)'i', &i) == 0))
			return 1;
		let lookups = hb_set_create();
		defer hb_set_destroy(lookups);
		hb_ot_layout_collect_lookups(face, HB_OT_TAG_GSUB, null, null, null, lookups);
		let glyphs = hb_set_create();
		defer hb_set_destroy(glyphs);
		hb_set_add(glyphs, f);
		hb_set_add(glyphs, i);
		hb_ot_layout_lookups_substitute_closure(face, lookups, glyphs);
		bool reachesLigature = false;
		var glyph = HB_SET_VALUE_INVALID;
		while (hb_set_next(glyphs, &glyph) != 0)
		{
			if (glyph == infos[2].codepoint)
				reachesLigature = true;
		}
		if (!reachesLigature)
			return 1;

		let arabic = hb_unicode_script(hb_unicode_funcs_get_default(), 0x0644);
		if (hb_script_get_horizontal_direction(arabic) != .HB_DIRECTION_RTL)
			return 1;
		return 0;
	}

	public static int Main()
	{
		let result = Run();
		Console.WriteLine(result == 0 ? "harfbuzz binding OK." : "harfbuzz binding FAILED.");
		return result;
	}
}
