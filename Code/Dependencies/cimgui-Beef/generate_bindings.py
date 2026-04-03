#!/usr/bin/env python3
"""Generate Beef language bindings from cimgui JSON definition files."""

import json
import os
import re
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
JSON_DIR = os.path.join(SCRIPT_DIR, "cimgui", "generator", "output")
OUTPUT_FILE = os.path.join(SCRIPT_DIR, "src", "cimgui.bf")

# C type -> Beef type mapping
TYPE_MAP = {
    "int": "int32",
    "unsigned int": "uint32",
    "short": "int16",
    "unsigned short": "uint16",
    "signed char": "int8",
    "unsigned char": "uint8",
    "signed short": "int16",
    "signed int": "int32",
    "long long": "int64",
    "signed long long": "int64",
    "unsigned long long": "uint64",
    "float": "float",
    "double": "double",
    "bool": "bool",
    "void": "void",
    "char": "char8",
    "size_t": "uint",
    "FILE*": "void*",
    "ImFileHandle": "void*",
    "va_list": "void*",
    # ImGui primitive typedefs
    "ImS8": "int8",
    "ImU8": "uint8",
    "ImS16": "int16",
    "ImU16": "uint16",
    "ImS32": "int32",
    "ImU32": "uint32",
    "ImS64": "int64",
    "ImU64": "uint64",
    "ImGuiID": "uint32",
    "ImDrawIdx": "uint16",
    "ImWchar16": "uint16",
    "ImWchar32": "uint32",
    "ImWchar": "uint16",  # Default without WCHAR32
    "ImTextureID": "uint64",
    "ImGuiKeyChord": "int32",
    "ImGuiSelectionUserData": "int64",
    "ImFontAtlasRectId": "int32",
    "ImPoolIdx": "int32",
    "ImGuiTableColumnIdx": "int16",
    "ImGuiTableDrawChannelIdx": "uint16",
    "ImGuiKeyRoutingIndex": "int16",
    "ImBitArrayPtr": "uint32*",
    "ImStbTexteditState": "STB_TexteditState",
    # Template types -> opaque void (these are C++ templates, not usable directly)
    "T": "void",
    "T*": "void*",
    # Callback typedefs
    "ImGuiContextHookCallback": "function void(ImGuiContext*, ImGuiContextHook*)",
    # Special ImVector types used in function params but not in struct fields
    "ImVector_const_charPtr": "ImVector_const_charPtr",
}

# Types that are used as int-based flags/enums
INT_FLAG_TYPES = {
    "ImGuiCol", "ImGuiCond", "ImGuiDataType", "ImGuiMouseButton",
    "ImGuiMouseCursor", "ImGuiStyleVar", "ImGuiTableBgTarget",
    "ImDrawFlags", "ImDrawListFlags", "ImDrawTextFlags", "ImFontFlags",
    "ImFontAtlasFlags", "ImGuiBackendFlags", "ImGuiButtonFlags",
    "ImGuiChildFlags", "ImGuiColorEditFlags", "ImGuiConfigFlags",
    "ImGuiComboFlags", "ImGuiDockNodeFlags", "ImGuiDragDropFlags",
    "ImGuiFocusedFlags", "ImGuiHoveredFlags", "ImGuiInputFlags",
    "ImGuiInputTextFlags", "ImGuiItemFlags", "ImGuiListClipperFlags",
    "ImGuiPopupFlags", "ImGuiMultiSelectFlags", "ImGuiSelectableFlags",
    "ImGuiSliderFlags", "ImGuiTabBarFlags", "ImGuiTabItemFlags",
    "ImGuiTableFlags", "ImGuiTableColumnFlags", "ImGuiTableRowFlags",
    "ImGuiTreeNodeFlags", "ImGuiViewportFlags", "ImGuiWindowFlags",
    # Internal flag types
    "ImGuiDataAuthority", "ImGuiLayoutType", "ImGuiActivateFlags",
    "ImGuiDebugLogFlags", "ImGuiFocusRequestFlags", "ImGuiItemStatusFlags",
    "ImGuiOldColumnFlags", "ImGuiLogFlags", "ImGuiNavRenderCursorFlags",
    "ImGuiNavMoveFlags", "ImGuiNextItemDataFlags", "ImGuiNextWindowDataFlags",
    "ImGuiScrollFlags", "ImGuiSeparatorFlags", "ImGuiTextFlags",
    "ImGuiTooltipFlags", "ImGuiTypingSelectFlags", "ImGuiWindowBgClickFlags",
    "ImGuiWindowRefreshFlags",
}

# Types with _c suffix that we rename (strip the _c)
C_SUFFIX_TYPES = {
    "ImVec2_c": "ImVec2",
    "ImVec4_c": "ImVec4",
    "ImRect_c": "ImRect",
    "ImColor_c": "ImColor",
    "ImTextureRef_c": "ImTextureRef",
    "ImVec2i_c": "ImVec2i",
}

# Structs that should be opaque (forward-declared only, not fully defined)
OPAQUE_STRUCTS = {
    "ImGuiContext",
    # C++ template types - opaque in bindings
    "ImBitArray", "ImChunkStream", "ImPool", "ImSpanAllocator",
}

# Structs defined manually in imgui.manual.bf (skip both generation and forward decl)
MANUAL_STRUCTS = {
    "STB_TexteditState", "stbrp_node",
    "ImFontAtlasBuilder", "ImFontAtlasPostProcessData", "ImFontLoader",
    "ImGuiDockNodeSettings", "ImGuiDockRequest",
}

# Function prefixes to skip entirely (C++ template-based, use T* generics)
SKIP_FUNCTION_PREFIXES = (
    "ImBitArray_", "ImChunkStream_", "ImPool_", "ImSpanAllocator_",
    "ImStableVector_", "ImVector_", "ImSpan_",
)

# Track which ImVector/ImSpan types we've generated (globally to avoid duplicates)
generated_helper_types = set()


def load_json(filename):
    path = os.path.join(JSON_DIR, filename)
    with open(path, "r") as f:
        return json.load(f)


def strip_all_const(t):
    """Thoroughly strip all const qualifiers from a type string."""
    # Remove 'const ' prefix/infix
    t = t.replace("const ", " ")
    # Remove trailing 'const' (e.g., "char*const")
    t = re.sub(r'\bconst\b', '', t)
    # Clean up extra whitespace
    t = re.sub(r'\s+', ' ', t).strip()
    return t


def map_type(c_type):
    """Map a C type string to a Beef type string."""
    if not c_type:
        return "void"

    t = c_type.strip()

    # Thorough const removal
    t = strip_all_const(t)

    # Handle "char*[]" or "char* []" -> char8** (array of string pointers)
    if re.match(r'^char\s*\*\s*\[\s*\]$', t):
        return "char8**"

    # Handle function pointers: type (*)(params)
    fn_match = re.match(r'(.+?)\s*\(\*\)\s*\((.+)\)', t)
    if fn_match:
        ret = map_type(fn_match.group(1))
        params_str = fn_match.group(2)
        if params_str.strip() == "void":
            return f"function {ret}()"
        param_list = []
        for p in split_params(params_str):
            p = p.strip()
            if not p:
                continue
            # Parse "type name" -> just map the type
            mapped = map_fn_ptr_param(p)
            param_list.append(mapped)
        return f"function {ret}({', '.join(param_list)})"

    # Handle pointers
    if t.endswith("*"):
        inner = t[:-1].strip()
        if inner.endswith("*"):
            # Double pointer
            return map_type(inner) + "*"
        mapped = map_type(inner)
        return mapped + "*"

    # Handle arrays like float[4], char[32]
    arr_match = re.match(r'(.+?)\[(\d+)\]', t)
    if arr_match:
        inner_type = map_type(arr_match.group(1).strip())
        size = arr_match.group(2)
        return f"{inner_type}[{size}]"

    # _c suffix types
    if t in C_SUFFIX_TYPES:
        return C_SUFFIX_TYPES[t]

    # Direct mapping
    if t in TYPE_MAP:
        return TYPE_MAP[t]

    # Int flag types -> int32
    if t in INT_FLAG_TYPES:
        return "int32"

    # ImVector types
    if t.startswith("ImVector_"):
        return t

    # ImSpan concrete types
    if t.startswith("ImSpan_"):
        return t

    # Known struct/enum types - pass through
    return t


def map_fn_ptr_param(param_str):
    """Map a function pointer parameter (which may include a name) to just a Beef type."""
    param_str = strip_all_const(param_str).strip()

    if not param_str or param_str == "void":
        return "void"

    # Handle nested function pointers
    if "(*)" in param_str:
        return map_type(param_str)

    # Handle pointer types with names like "ImGuiContext* ctx"
    # The name is the last word if the type part has known patterns
    parts = param_str.rsplit(None, 1)
    if len(parts) == 2:
        type_candidate = parts[0].strip()
        name_candidate = parts[1].strip()

        # If name_candidate looks like a name (identifier, not a type keyword)
        # and type_candidate looks like a complete type
        if (re.match(r'^[a-zA-Z_]\w*$', name_candidate) and
                not name_candidate.startswith("Im") and
                name_candidate not in TYPE_MAP and
                name_candidate not in INT_FLAG_TYPES):
            return map_type(type_candidate)

        # If type ends with *, the last word is definitely a name
        if type_candidate.endswith("*"):
            return map_type(type_candidate)

    # No name found, map the whole thing as a type
    return map_type(param_str)


def split_params(params_str):
    """Split a C parameter list by commas, respecting parentheses."""
    result = []
    depth = 0
    current = ""
    for ch in params_str:
        if ch == '(':
            depth += 1
            current += ch
        elif ch == ')':
            depth -= 1
            current += ch
        elif ch == ',' and depth == 0:
            result.append(current)
            current = ""
        else:
            current += ch
    if current.strip():
        result.append(current)
    return result


def sanitize_name(name):
    """Sanitize a name for Beef (handle reserved words)."""
    beef_reserved = {"in", "out", "ref", "base", "this", "new", "delete",
                     "override", "virtual", "abstract", "readonly", "params",
                     "scope", "where", "is", "as", "default", "internal",
                     "repeat", "function"}
    if name in beef_reserved:
        return "@" + name
    return name


def generate_enums(enums_data, locations):
    """Generate Beef enum declarations."""
    lines = []

    # Group private extensions with their base enums
    private_enums = {}
    regular_enums = {}

    for enum_name, values in enums_data.items():
        if "Private_" in enum_name:
            base = enum_name.replace("Private_", "_")
            if base not in private_enums:
                private_enums[base] = []
            private_enums[base].extend(values)
        else:
            regular_enums[enum_name] = values

    for enum_name, values in sorted(regular_enums.items()):
        beef_name = enum_name.rstrip("_")
        if beef_name == enum_name and not enum_name.endswith("_"):
            beef_name = enum_name

        seen_values = set()
        has_dupes = False
        for v in values:
            cv = v.get("calc_value", 0)
            if cv in seen_values:
                has_dupes = True
                break
            seen_values.add(cv)

        all_values = list(values)
        if enum_name in private_enums:
            all_values.extend(private_enums[enum_name])
            has_dupes = True

        if has_dupes:
            lines.append("[AllowDuplicates]")
        lines.append(f"enum {beef_name} : int32")
        lines.append("{")

        for v in all_values:
            member_name = v["name"]
            calc_val = v.get("calc_value", 0)
            expr = v.get("value", str(calc_val))

            if _is_simple_expr(expr):
                lines.append(f"\t{member_name} = {expr},")
            else:
                lines.append(f"\t{member_name} = {calc_val},")

        lines.append("}")
        lines.append("")

    return "\n".join(lines)


def _is_simple_expr(expr):
    """Check if an expression is simple enough to use directly in Beef."""
    return bool(re.match(r'^[\d\s\-|<>()xXa-fA-F]+$', expr))


def get_imvector_base_name(ftype):
    """Extract the ImVector type name without pointer suffix."""
    name = ftype.strip()
    while name.endswith("*"):
        name = name[:-1].strip()
    return name


def generate_imvector(vec_type_name, elem_type, lines):
    """Generate an ImVector struct if not already generated."""
    global generated_helper_types
    base_name = get_imvector_base_name(vec_type_name)
    if base_name in generated_helper_types:
        return
    # Map the element type
    elem_mapped = map_type(elem_type)
    lines.append(f"[CRepr]")
    lines.append(f"struct {base_name}")
    lines.append("{")
    lines.append(f"\tpublic int32 Size;")
    lines.append(f"\tpublic int32 Capacity;")
    lines.append(f"\tpublic {elem_mapped}* Data;")
    lines.append("}")
    lines.append("")
    generated_helper_types.add(base_name)


def generate_imspan(span_type_name, elem_type, lines):
    """Generate an ImSpan struct (pointer pair)."""
    global generated_helper_types
    if span_type_name in generated_helper_types:
        return
    elem_mapped = map_type(elem_type)
    lines.append(f"[CRepr]")
    lines.append(f"struct {span_type_name}")
    lines.append("{")
    lines.append(f"\tpublic {elem_mapped}* Data;")
    lines.append(f"\tpublic {elem_mapped}* DataEnd;")
    lines.append("}")
    lines.append("")
    generated_helper_types.add(span_type_name)


def parse_fn_ptr_type(ftype):
    """Parse a function pointer type string into a Beef function type."""
    ftype = strip_all_const(ftype)
    fn_match = re.match(r'(.+?)\(\*\)\s*\((.+)\)', ftype)
    if not fn_match:
        return None
    ret = map_type(fn_match.group(1).strip())
    params_str = fn_match.group(2).strip()
    if params_str == "void":
        return f"function {ret}()"
    param_parts = []
    for p in split_params(params_str):
        mapped = map_fn_ptr_param(p.strip())
        param_parts.append(mapped)
    return f"function {ret}({', '.join(param_parts)})"


def generate_structs(structs_data, locations):
    """Generate Beef struct declarations."""
    lines = []

    for struct_name, fields in sorted(structs_data.items()):
        # Skip opaque and manually-defined types
        if struct_name in OPAQUE_STRUCTS or struct_name in MANUAL_STRUCTS:
            continue

        # Handle _c suffix renaming
        beef_name = C_SUFFIX_TYPES.get(struct_name, struct_name)

        # Pre-generate any ImVector/ImSpan types needed by this struct
        for f in fields:
            ftype = f.get("type", "")
            base_ftype = get_imvector_base_name(ftype)

            if base_ftype.startswith("ImVector_"):
                elem_type = f.get("template_type", "void")
                generate_imvector(base_ftype, elem_type, lines)

            if ftype.startswith("ImSpan_"):
                elem_type = f.get("template_type", "void")
                generate_imspan(ftype, elem_type, lines)

        lines.append(f"[CRepr]")
        lines.append(f"struct {beef_name}")
        lines.append("{")

        # Handle bitfields: group consecutive bitfields
        i = 0
        while i < len(fields):
            f = fields[i]
            fname = f["name"]
            ftype = f.get("type", "void")

            # Handle bitfields using Beef [Bitfield] attributes
            if "bitfield" in f:
                bitfields = []
                total_bits = 0
                while i < len(fields) and "bitfield" in fields[i]:
                    bf = fields[i]
                    bits = int(bf["bitfield"])
                    bf_type = map_type(bf.get("type", "unsigned int"))
                    bitfields.append((bf["name"], bits, bf_type))
                    total_bits += bits
                    i += 1

                if total_bits <= 8:
                    backing_type = "uint8"
                elif total_bits <= 16:
                    backing_type = "uint16"
                elif total_bits <= 32:
                    backing_type = "uint32"
                else:
                    backing_type = "uint64"

                for bf_name, bf_bits, bf_type in bitfields:
                    lines.append(f"\t[Bitfield<{bf_type}>(.Public, .Bits({bf_bits}), \"{sanitize_name(bf_name)}\")]")
                lines.append(f"\tprivate {backing_type} mBitfield_{bitfields[0][0]};")
                continue

            i += 1

            # Handle arrays in field name: "fieldname[N]"
            arr_match = re.match(r'(\w+)\[(.+)\]', fname)
            if arr_match:
                actual_name = arr_match.group(1)
                arr_size = f.get("size", arr_match.group(2))
                beef_type = map_type(ftype)
                try:
                    size_int = int(str(arr_size))
                    lines.append(f"\tpublic {beef_type}[{size_int}] {sanitize_name(actual_name)};")
                except (ValueError, TypeError):
                    size_str = str(arr_size)
                    lines.append(f"\tpublic {beef_type}[{size_str}] {sanitize_name(actual_name)};")
                continue

            # Handle anonymous union fields
            if fname == "" and ftype.startswith("union {"):
                # Parse "union { Type1 Name1; Type2 Name2[N]; ... }"
                union_body = ftype[len("union {"):]
                if union_body.endswith("}"):
                    union_body = union_body[:-1]
                members = [m.strip() for m in union_body.split(";") if m.strip()]
                lines.append(f"\t[CRepr, Union]")
                lines.append(f"\tpublic struct")
                lines.append("\t{")
                for member in members:
                    # Handle array members like "int BackupInt[2]"
                    arr_m = re.match(r'(.+?)\s+(\w+)\[(\d+)\]$', member)
                    if arr_m:
                        mtype = map_type(arr_m.group(1).strip())
                        mname = arr_m.group(2)
                        msize = arr_m.group(3)
                        lines.append(f"\t\tpublic {mtype}[{msize}] {sanitize_name(mname)};")
                        continue
                    # Handle pointer members like "void* val_p"
                    ptr_m = re.match(r'(.+?\*+)\s+(\w+)$', member)
                    if ptr_m:
                        mtype = map_type(ptr_m.group(1).strip())
                        mname = ptr_m.group(2)
                        lines.append(f"\t\tpublic {mtype} {sanitize_name(mname)};")
                        continue
                    # Handle simple members like "float val_f"
                    simple_m = re.match(r'(\S+)\s+(\w+)$', member)
                    if simple_m:
                        mtype = map_type(simple_m.group(1).strip())
                        mname = simple_m.group(2)
                        lines.append(f"\t\tpublic {mtype} {sanitize_name(mname)};")
                        continue
                lines.append("\t};")
                continue

            # Handle function pointer fields
            if "(*)" in ftype:
                beef_type = parse_fn_ptr_type(ftype)
                if beef_type:
                    lines.append(f"\tpublic {beef_type} {sanitize_name(fname)};")
                    continue

            beef_type = map_type(ftype)
            lines.append(f"\tpublic {beef_type} {sanitize_name(fname)};")

        lines.append("}")
        lines.append("")

    return "\n".join(lines)


def should_skip_function(func_name):
    """Check if a function should be skipped (template-based, etc.)."""
    for prefix in SKIP_FUNCTION_PREFIXES:
        if func_name.startswith(prefix):
            return True
    return False


def generate_functions(defs_data):
    """Generate Beef extern function declarations."""
    lines = []

    for func_name, overloads in sorted(defs_data.items()):
        for overload in overloads:
            ov_name = overload.get("ov_cimguiname", func_name)

            # Skip template-based functions
            if should_skip_function(ov_name):
                continue

            args_t = overload.get("argsT", [])

            # Skip va_list functions
            has_va_list = any(a.get("type", "") == "va_list" for a in args_t)
            if has_va_list:
                continue

            # Skip functions with unresolvable template types
            has_template_type = False
            for arg in args_t:
                arg_type = arg.get("type", "")
                if arg_type in ("T*", "T", "ImChunkStream_T*"):
                    has_template_type = True
                    break
            ret_type_raw = overload.get("ret", "void")
            if ret_type_raw in ("T*", "T"):
                has_template_type = True
            if has_template_type:
                continue

            # Get return type
            ret_type = overload.get("ret", "void")
            if overload.get("constructor"):
                stname = overload.get("stname", "")
                ret_type = f"{stname}*"

            beef_ret = map_type(ret_type)

            # Build parameter list
            params = []
            skip_func = False
            for arg in args_t:
                arg_type = arg.get("type", "void")
                arg_name = arg.get("name", "")

                if not arg_name or arg_type == "...":
                    continue

                beef_type = map_type(arg_type)
                # In C, array params decay to pointers (e.g. float[4] -> float*)
                arr_param_match = re.match(r'(.+)\[\d+\]$', beef_type)
                if arr_param_match:
                    beef_type = arr_param_match.group(1) + "*"
                safe_name = sanitize_name(arg_name)
                params.append(f"{beef_type} {safe_name}")

            if skip_func:
                continue

            param_str = ", ".join(params) if params else ""

            lines.append(f"\t[CLink]")
            lines.append(f"\tpublic static extern {beef_ret} {ov_name}({param_str});")
            lines.append("")

    return "\n".join(lines)


def generate_forward_decls():
    """Generate forward declarations for opaque types."""
    lines = []
    for name in sorted(OPAQUE_STRUCTS):
        lines.append(f"[CRepr] struct {name};")
    lines.append("")
    # Comment out types defined in imgui.manual.bf
    lines.append("// Defined in imgui.manual.bf:")
    for name in sorted(MANUAL_STRUCTS):
        lines.append(f"// [CRepr] struct {name};")
    lines.append("")
    return "\n".join(lines)


def generate_typealias():
    """Generate type aliases for callback types."""
    lines = []
    lines.append("typealias ImGuiInputTextCallback = function int32(ImGuiInputTextCallbackData* data);")
    lines.append("typealias ImGuiSizeCallback = function void(ImGuiSizeCallbackData* data);")
    lines.append("typealias ImGuiMemAllocFunc = function void*(uint sz, void* user_data);")
    lines.append("typealias ImGuiMemFreeFunc = function void(void* ptr, void* user_data);")
    lines.append("typealias ImDrawCallback = function void(ImDrawList* parent_list, ImDrawCmd* cmd);")
    lines.append("")
    return "\n".join(lines)


def main():
    print("Loading JSON definitions...")
    enums_and_structs = load_json("structs_and_enums.json")
    definitions = load_json("definitions.json")
    typedefs = load_json("typedefs_dict.json")

    enums_data = enums_and_structs.get("enums", {})
    structs_data = enums_and_structs.get("structs", {})
    locations = enums_and_structs.get("locations", {})

    print(f"Found {len(enums_data)} enums, {len(structs_data)} structs, {len(definitions)} function groups")

    total_funcs = sum(len(v) for v in definitions.values())
    print(f"Total function overloads: {total_funcs}")

    print("Generating Beef bindings...")

    output = []
    output.append("// Auto-generated Beef bindings for cimgui (Dear ImGui 1.92.6 docking)")
    output.append("// Generated by generate_bindings.py")
    output.append("// Do not edit manually - regenerate from cimgui JSON definitions")
    output.append("")
    output.append("using System;")
    output.append("")
    output.append("namespace cimgui_Beef;")
    output.append("")

    # Forward declarations for opaque types
    output.append("// Forward declarations (opaque types)")
    output.append(generate_forward_decls())

    # Type aliases
    output.append("// Callback type aliases")
    output.append(generate_typealias())

    # Enums
    output.append("// Enums")
    output.append(generate_enums(enums_data, locations))

    # Extra ImVector types used in function params but not in struct fields
    output.append("// Extra ImVector types")
    output.append("[CRepr]")
    output.append("struct ImVector_const_charPtr")
    output.append("{")
    output.append("\tpublic int32 Size;")
    output.append("\tpublic int32 Capacity;")
    output.append("\tpublic char8** Data;")
    output.append("}")
    output.append("")

    # Structs
    output.append("// Structs")
    output.append(generate_structs(structs_data, locations))

    # Functions
    output.append("// Function declarations")
    output.append("static")
    output.append("{")
    output.append(generate_functions(definitions))
    output.append("}")
    output.append("")

    # Write output
    content = "\n".join(output)
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        f.write(content)

    print(f"Generated {OUTPUT_FILE}")
    print(f"File size: {len(content)} bytes, {content.count(chr(10))} lines")


if __name__ == "__main__":
    main()
