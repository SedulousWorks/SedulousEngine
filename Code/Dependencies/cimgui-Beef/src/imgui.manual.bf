// Manual Beef bindings for types not in cimgui JSON definitions.
// These are C++ template instantiations, STB internals, and other types
// that the cimgui generator doesn't output.

using System;

namespace cimgui_Beef;

// ============================================================================
// Callback typedefs
// ============================================================================

typealias ImGuiErrorCallback = function void(ImGuiContext* ctx, void* user_data, char8* msg);

// ============================================================================
// STB internal types
// ============================================================================

[CRepr]
struct StbUndoRecord
{
	public int32 @where;
	public int32 insert_length;
	public int32 delete_length;
	public int32 char_storage;
}

[CRepr]
struct StbUndoState
{
	public StbUndoRecord[99] undo_rec;   // IMSTB_TEXTEDIT_UNDOSTATECOUNT
	public int32[999] undo_char;         // IMSTB_TEXTEDIT_UNDOCHARCOUNT (CHARTYPE = int)
	public int16 undo_point;
	public int16 redo_point;
	public int32 undo_char_point;
	public int32 redo_char_point;
}

[CRepr]
struct STB_TexteditState
{
	public int32 cursor;
	public int32 select_start;
	public int32 select_end;
	public uint8 insert_mode;
	public int32 row_count_per_page;
	public uint8 cursor_at_end_of_line;
	public uint8 initialized;
	public uint8 has_preferred_x;
	public uint8 single_line;
	public uint8 padding1;
	public uint8 padding2;
	public uint8 padding3;
	public float preferred_x;
	public StbUndoState undostate;
}

// stbrp_coord = int
[CRepr]
struct stbrp_node
{
	public int32 x;
	public int32 y;
	public stbrp_node* next;
}

// ============================================================================
// Template container instantiations
// ============================================================================

// ImBitArray<BITCOUNT=155, OFFSET=-512> (ImBitArrayForNamedKeys)
// Storage size = (155 + 31) >> 5 = 5
[CRepr]
struct ImBitArrayForNamedKeys
{
	public uint32[5] Data;
}

// ImPool<T> = { ImVector<T> Buf, ImGuiStorage Map, ImPoolIdx FreeIdx, ImPoolIdx AliveCount }
[CRepr]
struct ImPool_ImGuiTable
{
	public ImVector_ImGuiTable Buf;
	public ImGuiStorage Map;
	public int32 FreeIdx;
	public int32 AliveCount;
}

[CRepr]
struct ImPool_ImGuiTabBar
{
	public ImVector_ImGuiTabBar Buf;
	public ImGuiStorage Map;
	public int32 FreeIdx;
	public int32 AliveCount;
}

[CRepr]
struct ImPool_ImGuiMultiSelectState
{
	public ImVector_ImGuiMultiSelectState Buf;
	public ImGuiStorage Map;
	public int32 FreeIdx;
	public int32 AliveCount;
}

// ImChunkStream<T> = { ImVector<char> Buf }
[CRepr]
struct ImChunkStream_ImGuiWindowSettings
{
	public ImVector_char8 Buf;
}

[CRepr]
struct ImChunkStream_ImGuiTableSettings
{
	public ImVector_char8 Buf;
}

// ImStableVector<ImFontBaked, 32> = { int Size, int Capacity, ImVector<ImFontBaked*> Blocks }
[CRepr]
struct ImStableVector_ImFontBaked__32
{
	public int32 Size;
	public int32 Capacity;
	public ImVector_void Blocks; // ImVector<ImFontBaked*>
}

// ImVector<void*> helper for ImStableVector Blocks
[CRepr]
struct ImVector_void
{
	public int32 Size;
	public int32 Capacity;
	public void** Data;
}

// ============================================================================
// Internal structs used by template containers
// ============================================================================

// ImVector<char> for ImChunkStream
[CRepr]
struct ImVector_char8
{
	public int32 Size;
	public int32 Capacity;
	public char8* Data;
}

// ImVector<ImGuiTable> (for ImPool)
[CRepr]
struct ImVector_ImGuiTable
{
	public int32 Size;
	public int32 Capacity;
	public ImGuiTable* Data;
}

// ImVector<ImGuiTabBar> (for ImPool)
[CRepr]
struct ImVector_ImGuiTabBar
{
	public int32 Size;
	public int32 Capacity;
	public ImGuiTabBar* Data;
}

// ImVector<ImGuiMultiSelectState> (for ImPool)
[CRepr]
struct ImVector_ImGuiMultiSelectState
{
	public int32 Size;
	public int32 Capacity;
	public ImGuiMultiSelectState* Data;
}

// ============================================================================
// Docking internals (defined in imgui.cpp, not exposed in headers)
// ============================================================================

enum ImGuiDockRequestType : int32
{
	ImGuiDockRequestType_None = 0,
	ImGuiDockRequestType_Dock,
	ImGuiDockRequestType_Undock,
	ImGuiDockRequestType_Split,
}

[CRepr]
struct ImGuiDockRequest
{
	public int32 Type;              // ImGuiDockRequestType
	public ImGuiWindow* DockTargetWindow;
	public ImGuiDockNode* DockTargetNode;
	public ImGuiWindow* DockPayload;
	public int32 DockSplitDir;      // ImGuiDir
	public float DockSplitRatio;
	public bool DockSplitOuter;
	public ImGuiWindow* UndockTargetWindow;
	public ImGuiDockNode* UndockTargetNode;
}

[CRepr]
struct ImGuiDockNodeSettings
{
	public uint32 ID;               // ImGuiID
	public uint32 ParentNodeId;     // ImGuiID
	public uint32 ParentWindowId;   // ImGuiID
	public uint32 SelectedTabId;    // ImGuiID
	public int8 SplitAxis;          // signed char
	public char8 Depth;
	public int32 Flags;             // ImGuiDockNodeFlags
	public ImVec2ih Pos;
	public ImVec2ih Size;
	public ImVec2ih SizeRef;
}

// ============================================================================
// Font system internals
// ============================================================================

[CRepr]
struct ImFontLoader
{
	public char8* Name;
	public function bool(ImFontAtlas*) LoaderInit;
	public function void(ImFontAtlas*) LoaderShutdown;
	public function bool(ImFontAtlas*, ImFontConfig*) FontSrcInit;
	public function void(ImFontAtlas*, ImFontConfig*) FontSrcDestroy;
	public function bool(ImFontAtlas*, ImFontConfig*, uint16) FontSrcContainsGlyph;
	public function bool(ImFontAtlas*, ImFontConfig*, ImFontBaked*, void*) FontBakedInit;
	public function void(ImFontAtlas*, ImFontConfig*, ImFontBaked*, void*) FontBakedDestroy;
	public function bool(ImFontAtlas*, ImFontConfig*, ImFontBaked*, void*, uint16, ImFontGlyph*, float*) FontBakedLoadGlyph;
	public uint FontBakedSrcLoaderDataSize;
}

[CRepr]
struct ImFontAtlasPostProcessData
{
	public ImFontAtlas* FontAtlas;
	public ImFont* Font;
	public ImFontConfig* FontSrc;
	public ImFontBaked* FontBaked;
	public ImFontGlyph* Glyph;
	public void* Pixels;
	public int32 Format;     // ImTextureFormat
	public int32 Pitch;
	public int32 Width;
	public int32 Height;
}

[CRepr]
struct ImFontAtlasBuilder
{
	public stbrp_context_opaque PackContext; // auto-generated in cimgui.bf
	public ImVector_stbrp_node_im PackNodes;
	public ImVector_ImTextureRect Rects;     // auto-generated in cimgui.bf
	public ImVector_ImFontAtlasRectEntry RectsIndex;
	public ImVector_uint8 TempBuffer;
	public int32 RectsIndexFreeListStart;
	public int32 RectsPackedCount;
	public int32 RectsPackedSurface;
	public int32 RectsDiscardedCount;
	public int32 RectsDiscardedSurface;
	public int32 FrameCount;
	public ImVec2i MaxRectSize;
	public ImVec2i MaxRectBounds;
	public bool LockDisableResize;
	public bool PreloadedAllGlyphsRanges;
	public ImStableVector_ImFontBaked__32 BakedPool;
	public ImGuiStorage BakedMap;
	public int32 BakedDiscardedCount;
	public int32 PackIdMouseCursors;    // ImFontAtlasRectId
	public int32 PackIdLinesTexData;    // ImFontAtlasRectId
}

// ImVector helpers for ImFontAtlasBuilder (only types not auto-generated)
[CRepr]
struct ImVector_stbrp_node_im
{
	public int32 Size;
	public int32 Capacity;
	public stbrp_node* Data;
}

[CRepr]
struct ImVector_ImFontAtlasRectEntry
{
	public int32 Size;
	public int32 Capacity;
	public ImFontAtlasRectEntry* Data;
}

[CRepr]
struct ImVector_uint8
{
	public int32 Size;
	public int32 Capacity;
	public uint8* Data;
}
