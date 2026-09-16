#!/usr/bin/env python3
"""Generate the Beef bindings from the vendored webgpu.h / wgpu.h.

  generate.py dist/include/webgpu/webgpu.h src/webgpu.bf
  generate.py dist/include/webgpu/wgpu.h    src/wgpu.bf

The headers are the source of truth, so a wgpu-native bump is a re-run rather
than a hand patch. The shape it emits was built against the hand written v29.0.0.0
bindings as the oracle - generating from the OLD headers reproduced them - with the
one deliberate departure described below: those bindings carried no struct defaults,
and going without them is a bug rather than a difference in taste.

What each C construct becomes:

  #define WGPU_X (v)                     -> public const uint32 WGPU_X = v;
  typedef struct WGPUXImpl* WGPUX        -> typealias WGPUX = void*;
  typedef enum WGPUX {..} WGPUX          -> enum WGPUX : int32 {..}
  typedef WGPUFlags WGPUX                -> typealias WGPUX = WGPUFlags;
  static const WGPUX WGPUX_Y = v         -> public const WGPUX WGPUX_Y = v;
  typedef struct WGPUX {..} WGPUX        -> [CRepr] struct WGPUX {..}
  typedef R (*WGPUProcX)(a)              -> typealias WGPUProcX = function R(a);
  WGPU_EXPORT R wgpuX(a)                 -> [CLink] public static extern R wgpuX(a);

A struct's WGPU_X_INIT macro comes across as FIELD INITIALISERS, so `.()` in Beef
means what starting from the macro means in C. That matters: several fields default
to a sentinel rather than to zero - a colour attachment's depthSlice to UNDEFINED, a
colour target's writeMask to All, a sampler's maxAnisotropy to 1 - and a zeroed one
is a different, usually invalid, request. The one place it does not reach is a fixed
array: `T[N] a = .()` zero fills in Beef instead of running each element's
initialisers, so an array of these has to be spelled `.(.(), .())`.
"""
import re
import sys

# The C spellings that carry no meaning across.
NOISE = [
    "WGPU_OBJECT_ATTRIBUTE", "WGPU_ENUM_ATTRIBUTE", "WGPU_STRUCTURE_ATTRIBUTE",
    "WGPU_FUNCTION_ATTRIBUTE", "WGPU_NULLABLE",
]

PRIMITIVES = {
    "uint8_t": "uint8", "uint16_t": "uint16", "uint32_t": "uint32", "uint64_t": "uint64",
    "int8_t": "int8", "int16_t": "int16", "int32_t": "int32", "int64_t": "int64",
    "size_t": "uint", "float": "float", "double": "double", "void": "void",
    "char": "char8", "int": "int32", "unsigned": "uint32", "bool": "bool",
}


def strip_noise(text):
    for token in NOISE:
        text = text.replace(token, " ")
    return text


def map_type(c_type):
    """One C declarator's type to its Beef spelling."""
    t = strip_noise(c_type)
    stars = t.count("*")
    t = t.replace("*", " ")
    # `const` carries nothing in Beef here, and neither does `struct`/`enum`.
    words = [w for w in t.split() if w not in ("const", "struct", "enum", "volatile")]
    if not words:
        return "void" + "*" * stars
    base = words[-1] if len(words) > 1 and words[0] in ("unsigned", "signed") else words[0]
    if len(words) == 2 and words[0] == "unsigned":
        base = {"char": "uint8", "short": "uint16", "int": "uint32", "long": "uint64"}.get(
            words[1], "uint32")
        return base + "*" * stars
    base = PRIMITIVES.get(base, base)
    return base + "*" * stars


def split_params(param_text):
    """C parameter list to Beef, respecting nesting so a function pointer survives."""
    param_text = strip_noise(param_text).strip()
    if not param_text or param_text == "void":
        return ""

    parts, depth, current = [], 0, ""
    for ch in param_text:
        if ch in "([":
            depth += 1
        elif ch in ")]":
            depth -= 1
        if ch == "," and depth == 0:
            parts.append(current)
            current = ""
            continue
        current += ch
    parts.append(current)

    out = []
    for part in parts:
        part = part.strip()
        if not part:
            continue
        # An inline function-pointer parameter: R (*name)(args).
        fn = re.match(r"^(.*?)\(\s*\*\s*(\w*)\s*\)\s*\((.*)\)$", part, re.S)
        if fn:
            ret = map_type(fn.group(1))
            inner = split_params(fn.group(3))
            out.append("function %s(%s) %s" % (ret, inner, fn.group(2) or "fn"))
            continue
        # An array parameter decays to a pointer.
        arr = re.match(r"^(.*?)(\w+)\s*\[\s*\d*\s*\]$", part, re.S)
        if arr:
            out.append("%s* %s" % (map_type(arr.group(1)), arr.group(2)))
            continue
        tokens = part.split()
        if len(tokens) == 1:
            out.append(map_type(part))
            continue
        name = tokens[-1].lstrip("*")
        c_type = part[: part.rfind(tokens[-1])] + "*" * tokens[-1].count("*")
        out.append("%s %s" % (map_type(c_type), name))
    return ", ".join(out)


def take_docs(lines, index):
    """The /** */ block immediately above `index`, verbatim, and where it began."""
    end = index - 1
    while end >= 0 and not lines[end].strip():
        end -= 1
    if end < 0 or not lines[end].strip().endswith("*/"):
        return [], index
    start = end
    while start >= 0 and not lines[start].strip().startswith("/**"):
        start -= 1
        if start >= 0 and lines[start].strip().endswith("*/") and start != end:
            return [], index
    if start < 0:
        return [], index
    return lines[start:end + 1], start


class Generator:
    def __init__(self, text):
        # Stripped ONCE, up front: the trailing attribute macros sit between a
        # type's closing brace and its name, so every declaration regex below
        # would otherwise have to spell them out.
        self.text = strip_noise(text)
        self.lines = self.text.split("\n")
        self.out = []
        self.flag_types = set(re.findall(r"^typedef\s+WGPUFlags\s+(\w+)\s*;", text, re.M))
        # Which enum each member belongs to, so an INIT default naming one can be
        # spelled the way Beef needs it: the member alone does not resolve.
        self.enum_of_member = {}
        for m in re.finditer(r"^typedef\s+enum\s+(\w+)\s*\{(.*?)\}\s*\1\s*;",
                             self.text, re.M | re.S):
            for line in m.group(2).split("\n"):
                e = re.match(r"\s*(\w+)\s*=\s*([^,]+)", line)
                if e:
                    self.enum_of_member[e.group(1)] = (m.group(1), e.group(2).strip())
        # Flag constants live in `static const WGPUFlagsType NAME = value;` lines.
        self.flag_value = {c: v.strip() for c, v in re.findall(
            r"^static\s+const\s+WGPU\w+\s+(\w+)\s*=\s*([^;]+);", self.text, re.M)}
        self.struct_defaults = self.init_defaults()

    def init_defaults(self):
        """The WGPU_*_INIT macros, as per-struct field defaults.

        The C header carries a designated-initialiser macro per struct, and a caller is
        MEANT to start from it: several fields default to a sentinel rather than to zero
        (depthSlice to UNDEFINED, a colour target's writeMask to All, maxAnisotropy to 1).
        Beef has no such idiom, and a zero-initialised struct silently means something
        else - a depth slice of 0 on a 2D view is a validation error, a write mask of 0
        writes nothing. So the defaults come across as FIELD INITIALISERS, which `.()`
        then applies for free.

        The one place that does not reach is a fixed array: `T[N] a = .()` zero-fills in
        Beef rather than running each element's initialisers, so an array of these has to
        be spelled `.(.(), .())`.
        """
        table = {}
        for m in re.finditer(
                r"#define\s+WGPU_\w+_INIT\s+_wgpu_MAKE_INIT_STRUCT\(\s*(\w+)\s*,\s*\{(.*?)\n\}\)",
                self.text, re.S):
            typ, body = m.group(1), m.group(2)
            fields = {}
            for line in body.split("\n"):
                f = re.search(r"/\*\.(\w+)=\*/\s*(.+?)\s*_wgpu_COMMA", line)
                if not f:
                    continue
                value = self.default_value(f.group(2).strip())
                if value is not None:
                    fields[f.group(1)] = value
            if fields:
                table[typ] = fields
        return table

    def default_value(self, value):
        """One INIT field's C value as Beef, or None where it is already zero.

        Zero needs nothing: Beef zero-initialises, and emitting it would only add noise.
        A nested _INIT is nothing here either - that struct carries its own initialisers,
        and Beef default-constructs a struct field.
        """
        if value in ("NULL", "0", "0.", "0.f", "0.0f", "false", "WGPU_FALSE"):
            return None
        # _wgpu_STRUCT_ZERO_INIT / _wgpu_ENUM_ZERO_INIT mean LITERAL ZERO, and the header
        # uses them deliberately where the nested struct's own defaults would be wrong: a
        # bind group layout entry zeroes all four binding kinds, so each reads as
        # BindingNotUsed rather than the Undefined its own INIT would give. They end in
        # _INIT, so they have to be caught before the nested rule below.
        if value.startswith("_wgpu_ENUM_ZERO_INIT") or value.startswith("_wgpu_STRUCT_ZERO_INIT"):
            return None
        if value.endswith("_INIT"):
            # A NESTED struct, spelled out rather than left implicit: Beef zero fills a
            # struct field that carries no initialiser of its own instead of running that
            # struct's. Without this a nested default is silently lost - which is how a
            # pipeline descriptor ends up with multisample.count 0 and will not build.
            return ".()"

        member = self.enum_of_member.get(value)
        if member:
            enum, literal = member
            if self.is_zero(literal):
                return None
            # A member spelled bare does not resolve in Beef; qualify it.
            return "%s.%s" % (enum, value)

        if value in self.flag_value:
            return None if self.is_zero(self.flag_value[value]) else value

        if re.match(r"^WGPU_[A-Z0-9_]+$", value):
            return value  # a sentinel constant, emitted by defines()

        if self.is_zero(value):
            return None
        if re.match(r"^-?(?:0x[0-9A-Fa-f]+|\d+)$", value):
            return value
        # A C float literal: 32.f and 0.5 are both legal there, neither is in Beef.
        f = re.match(r"^(-?\d*)\.(\d*)f?$", value)
        if f:
            return "%s.%sf" % (f.group(1) or "0", f.group(2) or "0")
        return None

    @staticmethod
    def is_zero(literal):
        try:
            return int(literal.strip().rstrip("uUlL"), 0) == 0
        except ValueError:
            return False

    def emit(self, s=""):
        self.out.append(s)

    def emit_docs(self, docs):
        for line in docs:
            self.emit(line.rstrip())

    # ---- the constructs ------------------------------------------------------------

    def handles(self):
        """Opaque object handles."""
        for m in re.finditer(r"^typedef\s+struct\s+(\w+Impl)\s*\*\s*(\w+)\s*;", self.text, re.M):
            self.emit("typealias %s = void*; // struct %s* %s" % (m.group(2), m.group(1), m.group(2)))

    def scalar_typedefs(self):
        for m in re.finditer(r"^typedef\s+(uint\d+_t|int\d+_t)\s+(\w+)\s*;", self.text, re.M):
            self.emit("typealias %s = %s;" % (m.group(2), PRIMITIVES[m.group(1)]))

    def defines(self):
        """#define constants, which are the sentinel values."""
        self.emit("static")
        self.emit("{")
        for m in re.finditer(r"^#define\s+(WGPU_[A-Z0-9_]+)\s+(.+?)\s*$", self.text, re.M):
            name, value = m.group(1), m.group(2).strip()
            if not value or "MAKE_INIT" in value or value.startswith("_wgpu"):
                continue
            # An include guard is a #define with no value, or one whose "value" is
            # the next directive; neither is a constant.
            if value.startswith("#") or name.endswith("_H_") or name.endswith("_H"):
                continue
            # The C spellings, each of which also decides the constant's Beef type.
            kind = "uint32"
            if "SIZE_MAX" in value:
                kind = "uint"
            elif "UINT64" in value or "ULL" in value:
                kind = "uint64"
            elif "NAN" in value or "FLT_" in value:
                kind = "float"
            value = re.sub(r"UINT(?:8|16|32|64)_C\s*\(([^)]*)\)", r"\1", value)
            value = (value.replace("UINT64_MAX", "uint64.MaxValue")
                          .replace("UINT32_MAX", "uint32.MaxValue")
                          .replace("UINT16_MAX", "uint16.MaxValue")
                          .replace("SIZE_MAX", "uint.MaxValue")
                          .replace("NAN", "float.NaN")
                          .rstrip("ULul"))
            docs, _ = take_docs(self.lines, self.text[: m.start()].count("\n"))
            self.emit_docs(docs)
            value = value.strip()
            while value.startswith("(") and value.endswith(")"):
                value = value[1:-1].strip()
            self.emit("\tpublic const %s %s = %s;" % (kind, name, value))
        self.emit("}")

    def enums(self):
        for m in re.finditer(r"^typedef\s+enum\s+(\w+)\s*\{(.*?)\}\s*\1\s*;", self.text, re.M | re.S):
            name, body = m.group(1), m.group(2)
            docs, _ = take_docs(self.lines, self.text[: m.start()].count("\n"))
            self.emit_docs(docs)
            self.emit("enum %s : int32" % name)
            self.emit("{")
            entries = []
            for line in body.split("\n"):
                e = re.match(r"\s*(\w+)\s*=\s*([^,]+)(,?)\s*$", line)
                if e:
                    entries.append((e.group(1), e.group(2).strip(), e.group(3)))
            for ename, value, comma in entries:
                self.emit("\t%s = %s%s" % (ename, value, comma))
            self.emit("}")
            self.emit()

    def flags(self):
        for name in sorted(self.flag_types):
            self.emit("typealias %s = WGPUFlags;" % name)
            consts = re.findall(
                r"^static\s+const\s+%s\s+(\w+)\s*=\s*([^;]+);" % name, self.text, re.M)
            if not consts:
                continue
            self.emit("static")
            self.emit("{")
            for cname, value in consts:
                self.emit("\tpublic const %s %s = %s;" % (name, cname, value.strip()))
            self.emit("}")
            self.emit()

    def callbacks_and_procs(self):
        for m in re.finditer(
                r"^typedef\s+([^;()]*?)\(\s*\*(\w+)\s*\)\s*\(([^;]*?)\)\s*;", self.text, re.M | re.S):
            ret, name, params = map_type(m.group(1)), m.group(2), split_params(m.group(3))
            docs, _ = take_docs(self.lines, self.text[: m.start()].count("\n"))
            self.emit_docs(docs)
            self.emit("typealias %s = function %s(%s);" % (name, ret, params))

    def structs(self):
        for m in re.finditer(r"^typedef\s+struct\s+(\w+)\s*\{(.*?)\n\}\s*\1\s*;",
                             self.text, re.M | re.S):
            name, body = m.group(1), m.group(2)
            docs, _ = take_docs(self.lines, self.text[: m.start()].count("\n"))
            self.emit_docs(docs)
            self.emit("[CRepr] struct %s" % name)
            self.emit("{")
            for field in self.fields(body, self.struct_defaults.get(name, {})):
                self.emit("\t" + field)
            self.emit("}")
            self.emit()

    def fields(self, body, defaults=None):
        out, pending = [], []
        defaults = defaults or {}
        lines = body.split("\n")
        i = -1
        while i + 1 < len(lines):
            i += 1
            raw = lines[i]
            line = raw.strip()
            if not line:
                continue
            # A nested anonymous union or struct: `union {` .. `} name;`. Beef spells
            # the union as an attribute on an inline struct.
            if line in ("union", "struct", "union {", "struct {"):
                kind = line.split()[0]
                depth, j, inner = 0, i, []
                while j < len(lines):
                    depth += lines[j].count("{") - lines[j].count("}")
                    if lines[j].strip().startswith("}") and depth <= 0:
                        break
                    if j > i and "{" not in lines[j]:
                        inner.append(lines[j])
                    j += 1
                tail = re.match(r"^\}\s*(\w+)\s*;", lines[j].strip()) if j < len(lines) else None
                out.extend(pending)
                pending = []
                out.append("%s public struct" % ("[Union]" if kind == "union" else "[CRepr]"))
                out.append("{")
                for f in self.fields("\n".join(inner), defaults):
                    out.append("\t" + f)
                out.append("} %s;" % (tail.group(1) if tail else "value"))
                i = j
                continue
            if line.startswith("/*") or line.startswith("*") or line.endswith("*/"):
                pending.append(raw.rstrip())
                continue
            if not line.endswith(";"):
                continue
            decl = strip_noise(line[:-1]).strip()
            fn = re.match(r"^(.*?)\(\s*\*\s*(\w+)\s*\)\s*\((.*)\)$", decl, re.S)
            if fn:
                out.extend(pending)
                pending = []
                out.append("public function %s(%s) %s;" % (
                    map_type(fn.group(1)), split_params(fn.group(3)), fn.group(2)))
                continue
            arr = re.match(r"^(.*?)(\w+)\s*\[\s*(\d+)\s*\]$", decl, re.S)
            if arr:
                out.extend(pending)
                pending = []
                out.append("public %s[%s] %s;" % (map_type(arr.group(1)), arr.group(3), arr.group(2)))
                continue
            tokens = decl.split()
            if len(tokens) < 2:
                pending = []
                continue
            fname = tokens[-1].lstrip("*")
            c_type = decl[: decl.rfind(tokens[-1])] + "*" * tokens[-1].count("*")
            out.extend(pending)
            pending = []
            default = defaults.get(fname)
            out.append("public %s %s%s;" % (map_type(c_type), fname,
                                            (" = " + default) if default else ""))
        return out

    def functions(self):
        found = [m for m in re.finditer(
            r"(?:^|\n)[ \t]*(?!typedef)([A-Za-z_][\w \t*]*?)[ \t]*(wgpu\w+)[ \t]*\((.*?)\)[ \t]*;",
            strip_noise(self.text).replace("WGPU_EXPORT", " "), re.S)
            if "(*" not in m.group(1)]
        if not found:
            return
        self.emit("static")
        self.emit("{")
        for m in found:
            ret, name, params = map_type(m.group(1)), m.group(2), split_params(m.group(3))
            docs, _ = take_docs(self.lines, self.text[: m.start()].count("\n"))
            self.emit_docs(docs)
            self.emit("\t[CLink] public static extern %s %s(%s);" % (ret, name, params))
        self.emit("}")

    def run(self):
        self.emit("using System;")
        self.emit("namespace wgpu_Beef;")
        self.emit()
        self.emit("// GENERATED by generate.py from the vendored headers. Do not edit by hand:")
        self.emit("// a wgpu-native bump is a re-run, and a hand edit is lost by the next one.")
        self.emit()
        self.scalar_typedefs()
        self.emit()
        self.handles()
        self.emit()
        self.defines()
        self.emit()
        self.enums()
        self.flags()
        self.callbacks_and_procs()
        self.emit()
        self.structs()
        self.functions()
        return "\n".join(self.out) + "\n"


if __name__ == "__main__":
    src, dst = sys.argv[1], sys.argv[2]
    open(dst, "w").write(Generator(open(src).read()).run())
    print("%s -> %s" % (src, dst))
