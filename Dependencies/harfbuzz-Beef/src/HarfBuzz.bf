using System;

namespace harfbuzz_Beef;

/*
 * HarfBuzz - OpenType text shaping.
 *
 * Source: https://github.com/harfbuzz/harfbuzz
 * Version: 14.5.1
 * License: "Old MIT" (harfbuzz/COPYING); the Universal Shaping Engine tables partly MIT
 * (harfbuzz/src/ms-use/COPYING).
 *
 * HarfBuzz is a C API already, so this binds it directly with no wrapper in between. It
 * declares only what the engine's shaper calls: blobs, faces and fonts over a font file in
 * memory, a buffer of UTF-32 shaped with a direction, script and language, the glyphs and
 * positions read back, and the GSUB closure the bakers use to find the glyphs a font's
 * substitutions reach. The rest of the library is there to bind when it is needed.
 *
 * Nothing above the font services sees these types: the engine's own ITextShaper is the
 * interface, and HarfBuzz one implementation of it.
 */

[CRepr] struct hb_blob_t;
[CRepr] struct hb_face_t;
[CRepr] struct hb_font_t;
[CRepr] struct hb_buffer_t;
[CRepr] struct hb_set_t;
[CRepr] struct hb_unicode_funcs_t;
[CRepr] struct hb_language_impl_t;

typealias hb_bool_t = int32;
typealias hb_codepoint_t = uint32;
typealias hb_position_t = int32;
typealias hb_mask_t = uint32;
typealias hb_tag_t = uint32;
/// An ISO 15924 tag, as HB_TAG builds it.
typealias hb_script_t = uint32;
/// Interned: equal languages are the same pointer.
typealias hb_language_t = hb_language_impl_t*;
typealias hb_destroy_func_t = function void(void* user_data);

enum hb_direction_t : int32
{
	HB_DIRECTION_INVALID = 0,
	HB_DIRECTION_LTR = 4,
	HB_DIRECTION_RTL,
	HB_DIRECTION_TTB,
	HB_DIRECTION_BTT
}

enum hb_memory_mode_t : int32
{
	HB_MEMORY_MODE_DUPLICATE,
	/// The caller keeps the bytes alive and unchanged for the blob's lifetime.
	HB_MEMORY_MODE_READONLY,
	HB_MEMORY_MODE_WRITABLE,
	HB_MEMORY_MODE_READONLY_MAY_MAKE_WRITABLE
}

enum hb_buffer_cluster_level_t : int32
{
	HB_BUFFER_CLUSTER_LEVEL_MONOTONE_GRAPHEMES = 0,
	/// Clusters in characters, in order: what GlyphPosition counts.
	HB_BUFFER_CLUSTER_LEVEL_MONOTONE_CHARACTERS = 1,
	HB_BUFFER_CLUSTER_LEVEL_CHARACTERS = 2,
	HB_BUFFER_CLUSTER_LEVEL_GRAPHEMES = 3,
	HB_BUFFER_CLUSTER_LEVEL_DEFAULT = HB_BUFFER_CLUSTER_LEVEL_MONOTONE_GRAPHEMES
}

/// After hb_shape, `codepoint` is the glyph index.
[CRepr]
struct hb_glyph_info_t
{
	public hb_codepoint_t codepoint;
	private hb_mask_t mask;
	public uint32 cluster;
	private uint32 var1;
	private uint32 var2;
}

/// In font units unless the font's scale was set.
[CRepr]
struct hb_glyph_position_t
{
	public hb_position_t x_advance;
	public hb_position_t y_advance;
	public hb_position_t x_offset;
	public hb_position_t y_offset;
	private uint32 var0;
}

[CRepr]
struct hb_feature_t
{
	public hb_tag_t tag;
	public uint32 value;
	public uint32 start;
	public uint32 end;
}

static
{
	public static hb_tag_t HB_TAG(char8 c1, char8 c2, char8 c3, char8 c4) =>
		((uint32)(uint8)c1 << 24) | ((uint32)(uint8)c2 << 16) | ((uint32)(uint8)c3 << 8) | (uint32)(uint8)c4;

	public const hb_tag_t HB_TAG_NONE = 0;
	public const hb_codepoint_t HB_CODEPOINT_INVALID = uint32.MaxValue;
	public const hb_codepoint_t HB_SET_VALUE_INVALID = HB_CODEPOINT_INVALID;
	public const hb_tag_t HB_OT_TAG_GSUB = 0x47535542; // 'GSUB'
	public const hb_language_t HB_LANGUAGE_INVALID = null;

	public const hb_script_t HB_SCRIPT_COMMON = 0x5A797979; // 'Zyyy'
	public const hb_script_t HB_SCRIPT_INHERITED = 0x5A696E68; // 'Zinh'
	public const hb_script_t HB_SCRIPT_UNKNOWN = 0x5A7A7A7A; // 'Zzzz'
	public const hb_script_t HB_SCRIPT_INVALID = HB_TAG_NONE;

	// ---- blobs, faces and fonts ------------------------------------------------------

	[CLink]
	public static extern hb_blob_t* hb_blob_create(char8* data, uint32 length, hb_memory_mode_t mode,
		void* user_data, hb_destroy_func_t destroy);
	[CLink]
	public static extern void hb_blob_destroy(hb_blob_t* blob);

	/// References the blob: it may be destroyed after.
	[CLink]
	public static extern hb_face_t* hb_face_create(hb_blob_t* blob, uint32 index);
	[CLink]
	public static extern void hb_face_destroy(hb_face_t* face);
	[CLink]
	public static extern uint32 hb_face_get_upem(hb_face_t* face);

	/// References the face: it may be destroyed after.
	[CLink]
	public static extern hb_font_t* hb_font_create(hb_face_t* face);
	[CLink]
	public static extern void hb_font_destroy(hb_font_t* font);
	/// BORROWED from the font.
	[CLink]
	public static extern hb_face_t* hb_font_get_face(hb_font_t* font);
	[CLink]
	public static extern void hb_font_get_scale(hb_font_t* font, int32* x_scale, int32* y_scale);
	[CLink]
	public static extern hb_bool_t hb_font_get_nominal_glyph(hb_font_t* font, hb_codepoint_t unicode, hb_codepoint_t* glyph);

	// ---- buffers and shaping ---------------------------------------------------------

	[CLink]
	public static extern hb_buffer_t* hb_buffer_create();
	[CLink]
	public static extern void hb_buffer_destroy(hb_buffer_t* buffer);
	[CLink]
	public static extern void hb_buffer_set_direction(hb_buffer_t* buffer, hb_direction_t direction);
	[CLink]
	public static extern hb_direction_t hb_buffer_get_direction(hb_buffer_t* buffer);
	[CLink]
	public static extern void hb_buffer_set_script(hb_buffer_t* buffer, hb_script_t script);
	[CLink]
	public static extern void hb_buffer_set_language(hb_buffer_t* buffer, hb_language_t language);
	/// Fills in whatever of the direction, script and language is still unset.
	[CLink]
	public static extern void hb_buffer_guess_segment_properties(hb_buffer_t* buffer);
	[CLink]
	public static extern void hb_buffer_set_cluster_level(hb_buffer_t* buffer, hb_buffer_cluster_level_t cluster_level);
	/// Adds `item_length` characters from `item_offset` of `text`; the rest is context.
	[CLink]
	public static extern void hb_buffer_add_utf32(hb_buffer_t* buffer, uint32* text, int32 text_length,
		uint32 item_offset, int32 item_length);
	[CLink]
	public static extern uint32 hb_buffer_get_length(hb_buffer_t* buffer);
	/// BORROWED from the buffer, valid until it changes.
	[CLink]
	public static extern hb_glyph_info_t* hb_buffer_get_glyph_infos(hb_buffer_t* buffer, uint32* length);
	/// BORROWED from the buffer, valid until it changes.
	[CLink]
	public static extern hb_glyph_position_t* hb_buffer_get_glyph_positions(hb_buffer_t* buffer, uint32* length);

	[CLink]
	public static extern void hb_shape(hb_font_t* font, hb_buffer_t* buffer, hb_feature_t* features, uint32 num_features);

	// ---- scripts and languages -------------------------------------------------------

	/// `len` -1 reads to the terminating nul.
	[CLink]
	public static extern hb_language_t hb_language_from_string(char8* str, int32 len);
	[CLink]
	public static extern hb_script_t hb_script_from_iso15924_tag(hb_tag_t tag);
	[CLink]
	public static extern hb_direction_t hb_script_get_horizontal_direction(hb_script_t script);
	[CLink]
	public static extern hb_unicode_funcs_t* hb_unicode_funcs_get_default();
	[CLink]
	public static extern hb_script_t hb_unicode_script(hb_unicode_funcs_t* ufuncs, hb_codepoint_t unicode);

	// ---- sets and the substitution closure -------------------------------------------

	[CLink]
	public static extern hb_set_t* hb_set_create();
	[CLink]
	public static extern void hb_set_destroy(hb_set_t* set);
	[CLink]
	public static extern void hb_set_add(hb_set_t* set, hb_codepoint_t codepoint);
	[CLink]
	public static extern void hb_set_union(hb_set_t* set, hb_set_t* other);
	[CLink]
	public static extern void hb_set_subtract(hb_set_t* set, hb_set_t* other);
	/// Start from HB_SET_VALUE_INVALID; false once past the last.
	[CLink]
	public static extern hb_bool_t hb_set_next(hb_set_t* set, hb_codepoint_t* codepoint);

	/// The lookups of `table_tag` the scripts, languages and features name; null for any.
	[CLink]
	public static extern void hb_ot_layout_collect_lookups(hb_face_t* face, hb_tag_t table_tag, hb_tag_t* scripts,
		hb_tag_t* languages, hb_tag_t* features, hb_set_t* lookup_indexes);
	/// Adds to `glyphs` every glyph the lookups can substitute from those already in it.
	[CLink]
	public static extern void hb_ot_layout_lookups_substitute_closure(hb_face_t* face, hb_set_t* lookups, hb_set_t* glyphs);
}
