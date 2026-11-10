#!/usr/bin/env python3
"""The engine SDK for a release: what a game project builds its editor, player and tools against.

  python3 Code/Tools/pack-sdk.py <out-dir> [--platform Linux64] [--manager <dir>] [--beef <pin>]
                                 [--toolchain <zip> [--toolchain-release <tag>]]
  python3 Code/Tools/pack-sdk.py --check [--platform Linux64] [--manager <dir>]

Packs, from what git tracks in this checkout:
- the library projects under the folders a project's workspace reads (ProjectBuild.cSdkLibraryDirs:
  Code/Foundation, Engine, Pipeline, Editor and Plugins) less the test projects (*.Tests and their
  *.TestSupport), each project's folder whole;
- each Dependencies/<dep> project less its tests and samples: its BeefProj.toml, its src/, the
  dist/ files its configs name for the platform and for wasm32, and the dependency's licence
  files; not its C sources or build scripts. And Dependencies/THIRD-PARTY-NOTICES.txt;
- the stock editor's and MCP host's BeefProj.toml, which a project's workspace generation reads;
- Bin/Naga and Bin/Tint: the platform's binary, VERSION and PROVENANCE.md;
- Data/.dataroot, Data/Engine, Data/Editor less Mock/, Data/Branding and Data/Templates less Tools/;
- Documentation/Shipping (the game code and MCP guides), LICENSE and CHANGELOG.md;
- with --manager, the project manager's build (its ShippingRelease output folder: the executable,
  the shared libraries beside it and the notices) under ProjectManager/;
and writes sdk.json and README-SDK.md at the root.

It writes sedulous-sdk-<display>-<platform>.zip (the SDK's root at the zip's root, each entry's
Unix mode in its external attributes, fixed timestamps) and the release's index for the platform,
sdk-<platform>.json: version, label, display, platform, archive, sha256, size, unpackedSize, beef
(the toolchain pin, --beef), and with --toolchain the toolchain's archive, sha256, size and the
release whose files carry it (--toolchain-release; absent when it is this release). The project
manager lists a release's engine from that index and checks the download against its digest.
sdk.json holds version, label, display, buildNumber, platform, beef and created (the packed
commit's time), which the manager and the build read back. The version is the engine's own with
its label (Code/Engine/Sedulous.Engine.Project/src/EngineVersion.bf): pack from the release commit.

--check packs nothing. It fails when a packed project depends on a project that is not packed (the
templates' projects too), when a packed project's config for the platform or wasm32 names a
$(ProjectDir) or $(WorkspaceDir)/.. path that is not packed, when a packed source's
Compiler.ReadText or ReadBinary path is not packed, when a path a project's workspace generation
reads is missing (the stock projects, the startup libraries IsSdk asks for, Bin, the plugins'
manifests), or, with --manager, when the folder has no manager. A pack runs the same check first.

Run by hand, in a checkout (only tracked files go in), and attach the zip and the index to the
GitHub release v<display>: there is no workflow that does it. The same files pack to the same bytes.
"""
import argparse, fnmatch, hashlib, importlib.util, json, os, posixpath, re, subprocess, sys, zipfile

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
VERSION_FILE = os.path.join(ROOT, "Code", "Engine", "Sedulous.Engine.Project", "src", "EngineVersion.bf")
PROJECT_BUILD = os.path.join(ROOT, "Code", "Editor", "Sedulous.Editor.Projects", "src", "ProjectBuild.bf")
MANAGER_LAUNCHER = os.path.join(ROOT, "Code", "Editor", "Sedulous.Editor.App", "src", "ManagerLauncher.bf")
NOTICES_SCRIPT = os.path.join(ROOT, "Code", "Tools", "third-party-notices.py")

# Beef's platform names, and the folder of each under Bin/<tool>/bin.
BIN_FOLDERS = {"Linux64": "linux-x86_64", "Win64": "win-x64"}
WASM = "wasm32"
DATA = ["Data/.dataroot", "Data/Engine", "Data/Editor", "Data/Branding", "Data/Templates"]
DATA_LEFT_OUT = ["Data/Editor/Mock", "Data/Templates/Tools"]
ROOT_FILES = ["LICENSE", "CHANGELOG.md", "Dependencies/THIRD-PARTY-NOTICES.txt"]
DOCS = "Documentation/Shipping"
TOOLS = ["Bin/Naga", "Bin/Tint"]
# A dependency's own files that are its licence, notices or where it came from.
LICENCE_NAMES = re.compile(r"^(LICEN[CS]E|COPYING|NOTICE|PROVENANCE|ThirdPartyNotices)[^/]*$|\.LICENSE$|\.PROVENANCE\.md$", re.I)
# What a dependency carries besides the library a game links: its tests and samples.
DEPENDENCY_LEFT_OUT = re.compile(r"(-Test|\.Test|\.Tests)$")
DEPENDENCY_LEFT_OUT_DIRS = ["Dependencies/Bulkan/VulkanTriangle", "Dependencies/Win32-Beef/Samples"]
# A config's settings that name where a build writes, not what it reads.
OUTPUT_KEYS = {"TargetDirectory", "TargetName"}
FIXED_TIME = (2026, 1, 1, 0, 0, 0)
# The README a packed SDK carries at its root.
README = """# Sedulous Engine {display} SDK ({platform})

This is the engine as a game project builds against it: its library projects as source, the
native libraries they link, the editor's and the engine's data, and the project templates.

Run `ProjectManager/Sedulous.Tools.ProjectManager`: it lists this SDK, makes projects from its
templates and opens each in its own editor, which it builds over this SDK the first time. A build
needs BeefBuild (the manager's Toolchain page installs the one this SDK was built with) and the
system's linker (Linux: clang++ or c++, and ar).

Leave the folder as it is: projects pinned to it name its path. The licences of the third-party
libraries are in Dependencies/THIRD-PARTY-NOTICES.txt, the engine's in LICENSE.
"""


def fail(message):
    sys.exit("pack-sdk: " + message)


def read_text(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


def engine_version():
    """String, Label and BuildNumber of the engine's version file."""
    text = read_text(VERSION_FILE)
    found = re.search(r'public const String String = "([0-9]+\.[0-9]+\.[0-9]+)";', text)
    label = re.search(r'public const String Label = "([^"]*)";', text)
    build = re.search(r'public const uint32 BuildNumber = ([0-9]+);', text)
    if not found or not label or not build:
        fail(f"no version, label or build number in {VERSION_FILE}")
    return found.group(1), label.group(1), int(build.group(1))


def string_constants(path):
    """The `public const String` and `String[n]` constants of a Beef source, the arrays as lists
    with a constant they name resolved."""
    text = read_text(path)
    single = dict(re.findall(r'public const String (\w+) = "([^"]*)";', text))
    arrays = {}
    for name, items in re.findall(r'public const String\[\d+\] (\w+) = \.\(([^)]*)\);', text):
        values = []
        for item in (part.strip() for part in items.split(",")):
            values.append(item[1:-1] if item.startswith('"') else single[item])
        arrays[name] = values
    return single, arrays, text


def build_layout():
    """What a project's workspace generation reads of an SDK, from ProjectBuild itself: the library
    folders, the stock projects and the startup libraries IsSdk asks for (folder/name)."""
    single, arrays, text = string_constants(PROJECT_BUILD)
    body = re.search(r"public static bool IsSdk\(StringView root\)(.*?)\n\t}", text, re.S)
    if not body:
        fail(f"no IsSdk in {PROJECT_BUILD}")
    startups = []
    for folder, name, each in re.findall(r'HasProject\(root, "([^"]+)", (\w+)(\[i\])?\)', body.group(1)):
        for project in (arrays[name] if each else [single[name]]):
            startups.append(f"{folder}/{project}")
    if not startups:
        fail(f"IsSdk in {PROJECT_BUILD} asks for no project")
    return {
        "libraryDirs": [d for d in arrays["cSdkLibraryDirs"] if d != "Dependencies"],
        "pluginsDir": single["cSdkPluginsDir"],
        "stock": [single["cStockEditorProject"], single["cStockWebProject"], single["cStockToolsProject"]],
        "webDir": single["cStockWebDir"],
        "startups": startups,
    }


def manager_names():
    single, _, _ = string_constants(MANAGER_LAUNCHER)
    return single["cManagerFolder"], single["cManagerName"]


def notices_components():
    """third-party-notices.py's list: each component's licence files under Dependencies/."""
    sys.dont_write_bytecode = True # read, not cached beside the script
    spec = importlib.util.spec_from_file_location("third_party_notices", NOTICES_SCRIPT)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module.COMPONENTS


def tracked():
    """Every tracked file, relative with forward slashes, and the executable ones."""
    out = subprocess.run(["git", "ls-files", "-s", "-z"], cwd=ROOT, check=True, capture_output=True).stdout.decode("utf-8")
    files, executable, links = [], set(), []
    for record in out.split("\0"):
        if not record:
            continue
        meta, path = record.split("\t", 1)
        mode = meta.split()[0]
        if mode == "160000":
            continue # a submodule: its files are not this checkout's
        if mode == "120000":
            links.append(path)
            continue
        if not os.path.isfile(os.path.join(ROOT, path)):
            continue # deleted in the working tree
        files.append(path)
        if mode == "100755":
            executable.add(path)
    return files, executable, links


def under(path, folder):
    return path == folder or path.startswith(folder + "/")


class ProjectReader:
    """The TOML of a BeefProj.toml, read as Beef reads it: a key given twice keeps its last value
    (strict TOML refuses the file), and [[...]] arrays of tables are passed by."""

    def __init__(self, text):
        self.text, self.i = text, 0

    def error(self, what):
        line = self.text.count("\n", 0, self.i) + 1
        raise ValueError(f"{what} at line {line}")

    def skip(self, newlines=True):
        while self.i < len(self.text):
            c = self.text[self.i]
            if c == "#":
                end = self.text.find("\n", self.i)
                self.i = len(self.text) if end < 0 else end
            elif c in " \t\r" or (newlines and c == "\n"):
                self.i += 1
            else:
                return

    def key(self):
        parts = []
        while True:
            self.skip(False)
            c = self.text[self.i:self.i + 1]
            if c in ('"', "'"):
                parts.append(self.string())
            else:
                found = re.match(r"[A-Za-z0-9_\-]+", self.text[self.i:])
                if not found:
                    self.error("a key expected")
                parts.append(found.group(0))
                self.i += len(found.group(0))
            self.skip(False)
            if self.text[self.i:self.i + 1] != ".":
                return parts
            self.i += 1

    def string(self):
        quote = self.text[self.i]
        self.i += 1
        out = []
        while self.i < len(self.text):
            c = self.text[self.i]
            self.i += 1
            if c == quote:
                return "".join(out)
            if c == "\\" and quote == '"':
                escaped = self.text[self.i]
                self.i += 1
                out.append({"n": "\n", "t": "\t", "r": "\r", "b": "\b", "f": "\f"}.get(escaped, escaped))
            elif c == "\n":
                break
            else:
                out.append(c)
        self.error("an unterminated string")

    def value(self):
        self.skip(False)
        c = self.text[self.i:self.i + 1]
        if c in ('"', "'"):
            return self.string()
        if c == "[":
            self.i += 1
            items = []
            while True:
                self.skip()
                if self.text[self.i:self.i + 1] == "]":
                    self.i += 1
                    return items
                items.append(self.value())
                self.skip()
                if self.text[self.i:self.i + 1] == ",":
                    self.i += 1
        if c == "{":
            self.i += 1
            table = {}
            while True:
                self.skip(False)
                if self.text[self.i:self.i + 1] == "}":
                    self.i += 1
                    return table
                keys = self.key()
                if self.text[self.i:self.i + 1] != "=":
                    self.error("= expected")
                self.i += 1
                self.put(table, keys, self.value())
                self.skip(False)
                if self.text[self.i:self.i + 1] == ",":
                    self.i += 1
        found = re.match(r"[^\s,\]}#]+", self.text[self.i:])
        if not found:
            self.error("a value expected")
        self.i += len(found.group(0))
        return found.group(0)

    @staticmethod
    def put(table, keys, value):
        for k in keys[:-1]:
            table = table.setdefault(k, {})
        table[keys[-1]] = value

    def read(self):
        root = {}
        current = root
        while True:
            self.skip()
            if self.i >= len(self.text):
                return root
            if self.text.startswith("[[", self.i):
                end = self.text.find("]]", self.i)
                if end < 0:
                    self.error("an unterminated table header")
                self.i = end + 2
                current = {} # an array of tables: nothing read here needs one
            elif self.text[self.i] == "[":
                self.i += 1
                keys = self.key()
                if self.text[self.i:self.i + 1] != "]":
                    self.error("] expected")
                self.i += 1
                current = root
                for k in keys:
                    current = current.setdefault(k, {})
            else:
                keys = self.key()
                if self.text[self.i:self.i + 1] != "=":
                    self.error("= expected")
                self.i += 1
                self.put(current, keys, self.value())


def read_project(path):
    try:
        return ProjectReader(read_text(os.path.join(ROOT, path))).read()
    except (OSError, ValueError, IndexError) as error:
        fail(f"{path} does not read: {error}")


def project_name(project, path):
    name = project.get("Project", {}).get("Name")
    if not name:
        fail(f"{path} names no project")
    return name


def dependency_names(project):
    return [name for name in project.get("Dependencies", {}) if name != "corlib"]


def config_strings(project, platforms):
    """Each setting's text (every string of a list) of the project's configs for `platforms`, with
    its config's name, less the settings that name outputs."""
    for config, by_platform in project.get("Configs", {}).items():
        for platform, settings in by_platform.items():
            if platform not in platforms:
                continue
            for key, value in settings.items():
                if key in OUTPUT_KEYS:
                    continue
                for text in (value if isinstance(value, list) else [value]):
                    if isinstance(text, str):
                        yield f"{config}.{platform}.{key}", text


MACRO_PATH = re.compile(r'\$\((ProjectDir|WorkspaceDir)\)([^\s"\\;,]*)')


def named_paths(project, project_dir, platforms):
    """(where, macro, path relative to the root) for every $(ProjectDir) and $(WorkspaceDir) path the
    project's configs for `platforms` name. $(WorkspaceDir)/.. is the SDK's root, as generation makes it
    for the stock projects; a path may be a glob."""
    for where, text in config_strings(project, platforms):
        for macro, rest in MACRO_PATH.findall(text):
            rest = rest.split("@", 1)[0] # emcc's --preload-file <path>@<mount>
            base = project_dir if macro == "ProjectDir" else "Code"
            yield where, macro, posixpath.normpath(posixpath.join(base, rest.lstrip("/")))


def strip_comments_and_text_blocks(source):
    """The source with its comments and multi-line string literals (text a generator writes, not code
    the compiler reads) blanked, its ordinary strings kept."""
    out, i, n = [], 0, len(source)
    while i < n:
        if source.startswith('"""', i):
            end = source.find('"""', i + 3)
            i = n if end < 0 else end + 3
        elif source.startswith("//", i):
            end = source.find("\n", i)
            i = n if end < 0 else end
        elif source.startswith("/*", i):
            end = source.find("*/", i + 2)
            i = n if end < 0 else end + 2
        elif source[i] == '"':
            j = i + 1
            while j < n and source[j] != '"' and source[j] != "\n":
                j += 2 if source[j] == "\\" else 1
            out.append(source[i:j + 1])
            i = j + 1
        elif source[i] == "'":
            j = i + 1
            while j < n and source[j] != "'" and source[j] != "\n":
                j += 2 if source[j] == "\\" else 1
            out.append(source[i:j + 1])
            i = j + 1
        else:
            out.append(source[i])
            i += 1
    return "".join(out)


COMPILER_READ = re.compile(r'Compiler\.Read(?:Text|Binary)\(\s*"([^"]*)"\s*\)')


class Sdk:
    """What goes in the SDK: each packed path (relative to the root) and where it comes from."""

    def __init__(self, platform, manager):
        self.platform = platform
        self.manager = manager
        self.files = {} # packed path -> (source path, executable)
        self.projects = {} # project name -> its BeefProj.toml, packed
        self.parsed = {} # BeefProj.toml -> its table
        self.problems = []
        self.layout = build_layout()
        self.manager_folder, self.manager_name = manager_names()

    def add(self, path, executable=False, source=None):
        self.files[path] = (source or os.path.join(ROOT, path), executable)

    def add_project(self, path):
        project = read_project(path)
        name = project_name(project, path)
        if name in self.projects:
            self.problems.append(f"{path} and {self.projects[name]} are both project {name}")
        self.projects[name] = path
        self.parsed[path] = project
        return project

    def gather(self):
        files, executable, links = tracked()
        for link in links:
            if any(under(link, d) for d in self.layout["libraryDirs"] + DATA + TOOLS + ["Dependencies", DOCS]):
                self.problems.append(f"{link} is a symbolic link, which the SDK's zip does not carry")
        file_set = set(files)

        # The library projects, each folder whole, less the tests and what supports only them.
        library_files = [f for f in files if any(under(f, d) for d in self.layout["libraryDirs"])]
        left_out = []
        for f in library_files:
            if f.endswith("/BeefProj.toml"):
                folder = posixpath.dirname(f)
                if re.search(r"\.(Tests|TestSupport)$", posixpath.basename(folder)):
                    left_out.append(folder)
                else:
                    self.add_project(f)
        for f in library_files:
            if not any(under(f, d) for d in left_out):
                self.add(f, f in executable)

        # The dependencies: each project's own files, the dist files it names, the licences.
        dep_projects = []
        for f in files:
            if not (f.startswith("Dependencies/") and f.endswith("/BeefProj.toml")):
                continue
            folder = posixpath.dirname(f)
            if DEPENDENCY_LEFT_OUT.search(posixpath.basename(folder)) or any(under(folder, d) for d in DEPENDENCY_LEFT_OUT_DIRS):
                continue
            dep_projects.append(folder)
            project = self.add_project(f)
            self.add(f)
            for g in files:
                if under(g, folder + "/src"):
                    self.add(g, g in executable)
            for where, macro, path in named_paths(project, folder, {self.platform, WASM}):
                if macro != "ProjectDir" or not under(path, folder + "/dist"):
                    continue
                for g in self.matching(path, file_set):
                    self.add(g, g in executable)
        for dep in sorted({f.split("/")[1] for f in files if f.startswith("Dependencies/") and f.count("/") >= 2}):
            for f in files:
                if posixpath.dirname(f) == f"Dependencies/{dep}" and LICENCE_NAMES.search(posixpath.basename(f)):
                    self.add(f)
        for _, _, _, licence_files in notices_components():
            for relative in licence_files:
                path = "Dependencies/" + relative
                if path in file_set:
                    self.add(path)
                else:
                    self.problems.append(f"the notices name {path}, which is not tracked")

        # The stock projects generation reads (the web player is a library project, packed above).
        for stock in self.layout["stock"]:
            if stock in file_set:
                if stock not in self.files:
                    self.add_project(stock)
                    self.add(stock)
            else:
                self.problems.append(f"generation reads {stock}, which is not tracked")

        # The shader tools, for the platform.
        folder = BIN_FOLDERS.get(self.platform)
        for tool in TOOLS:
            for f in files:
                if not under(f, tool):
                    continue
                inner = f[len(tool) + 1:]
                if "/" not in inner or (folder and under(inner, "bin/" + folder)):
                    self.add(f, f in executable)

        # Data, the shipping docs and the root files.
        for f in files:
            if (any(under(f, d) for d in DATA) and not any(under(f, d) for d in DATA_LEFT_OUT)) or under(f, DOCS):
                self.add(f, f in executable)
        for f in ROOT_FILES:
            if f in file_set:
                self.add(f)
            else:
                self.problems.append(f"{f} is not tracked")

        # The templates' projects are a new project's own; their dependencies must be packed.
        for f in list(self.files):
            if under(f, "Data/Templates") and f.endswith("/BeefProj.toml"):
                self.parsed[f] = read_project(f)

        if self.manager:
            self.gather_manager()

    def matching(self, pattern, file_set):
        if any(c in pattern for c in "*?["):
            return sorted(f for f in file_set if fnmatch.fnmatchcase(f, pattern))
        if pattern in file_set:
            return [pattern]
        prefix = pattern + "/"
        return sorted(f for f in file_set if f.startswith(prefix))

    def gather_manager(self):
        folder = os.path.abspath(self.manager)
        exe = self.manager_name + (".exe" if self.platform == "Win64" else "")
        if not os.path.isfile(os.path.join(folder, exe)):
            self.problems.append(f"{folder} has no {exe}: build Sedulous.Tools.ProjectManager in ShippingRelease")
            return
        for name in sorted(os.listdir(folder)):
            path = os.path.join(folder, name)
            if not os.path.isfile(path):
                continue
            shared = name.endswith((".so", ".dll", ".dylib")) or ".so." in name
            if name == exe or shared or name == "THIRD-PARTY-NOTICES.txt":
                self.add(f"{self.manager_folder}/{name}", name == exe or shared or os.access(path, os.X_OK), path)

    def check(self):
        """Every problem with what gather chose, as lines; none when the SDK would build a project."""
        problems = list(self.problems)
        packed = set(self.files)

        # The dependency closure.
        for path, project in sorted(self.parsed.items()):
            template = under(path, "Data/Templates")
            for name in dependency_names(project):
                if template and "__GAME" in name:
                    continue
                if name not in self.projects:
                    problems.append(f"{path} depends on {name}, which is not packed")

        # What each packed project's configs name.
        named = 0
        for path, project in sorted(self.parsed.items()):
            if under(path, "Data/Templates"):
                continue
            folder = posixpath.dirname(path)
            stock = path in self.layout["stock"] and not under(path, self.layout["webDir"])
            for where, macro, target in named_paths(project, folder, {self.platform, WASM}):
                named += 1
                if macro == "WorkspaceDir" and not stock:
                    problems.append(f"{path} {where} names $(WorkspaceDir), which in a game's workspace is the game's Code/")
                elif not self.matching(target, packed):
                    problems.append(f"{path} {where} names {target}, which is not packed")

        # What packed sources read as they compile.
        reads = 0
        for f in sorted(packed):
            if not f.endswith(".bf") or under(f, "Data/"):
                continue
            source = read_text(self.files[f][0])
            if "Compiler.Read" not in source:
                continue
            source = strip_comments_and_text_blocks(source)
            project_dir = self.project_dir_of(f)
            for relative in COMPILER_READ.findall(source):
                reads += 1
                target = posixpath.normpath(posixpath.join(project_dir, relative))
                if target not in packed:
                    problems.append(f"{f} reads {relative} as it compiles ({target}), which is not packed")

        # What generation and the manager read of an SDK.
        for startup in self.layout["startups"]:
            if f"{startup}/BeefProj.toml" not in packed:
                problems.append(f"IsSdk asks for {startup}, which is not packed")
        for stock in self.layout["stock"]:
            if stock not in packed:
                problems.append(f"generation reads {stock}, which is not packed")
        folder = BIN_FOLDERS.get(self.platform)
        if not folder:
            problems.append(f"no shader tools are known for {self.platform}")
        else:
            for tool in TOOLS:
                if not any(under(f, f"{tool}/bin/{folder}") for f in packed):
                    problems.append(f"{tool} has no binary for {self.platform}")
        plugins = self.layout["pluginsDir"]
        for f in sorted(packed):
            if under(f, plugins) and f.endswith("/BeefProj.toml"):
                package = f[len(plugins) + 1:].split("/")[0]
                if f"{plugins}/{package}/Plugin.xml" not in packed:
                    problems.append(f"plugin package {package} has no Plugin.xml")
        if "Data/.dataroot" not in packed:
            problems.append("Data/.dataroot is not packed: nothing would find the SDK's data")
        return problems, named, reads

    def project_dir_of(self, source):
        folder = posixpath.dirname(source)
        while folder and folder + "/BeefProj.toml" not in self.files:
            folder = posixpath.dirname(folder)
        return folder


def head_time():
    """When the packed commit was made (UTC, ISO 8601): the SDK's created, the same for every pack of it."""
    stamp = subprocess.run(["git", "log", "-1", "--format=%ct"], cwd=ROOT, check=True, capture_output=True).stdout.decode().strip()
    import datetime
    return datetime.datetime.fromtimestamp(int(stamp), datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def sha256(path):
    digest = hashlib.sha256()
    with open(path, "rb") as f:
        for block in iter(lambda: f.read(1 << 20), b""):
            digest.update(block)
    return digest.hexdigest()


def write_zip(path, entries):
    """entries: (name, bytes or a source path, executable), sorted. The bytes the zip unpacks to."""
    unpacked = 0
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for name, data, executable in entries:
            info = zipfile.ZipInfo(name, date_time=FIXED_TIME) # fixed: the same files pack the same
            info.compress_type = zipfile.ZIP_DEFLATED
            info.create_system = 3 # Unix, so the mode below is read back on extract
            info.external_attr = (0o100000 | (0o755 if executable else 0o644)) << 16
            if not isinstance(data, bytes):
                with open(data, "rb") as f:
                    data = f.read()
            unpacked += len(data)
            z.writestr(info, data, compresslevel=9)
    return unpacked


def main():
    parser = argparse.ArgumentParser(prog="Code/Tools/pack-sdk.py", description="Packs the engine SDK for a release.")
    parser.add_argument("out", nargs="?", help="the folder the zip and the index are written into")
    parser.add_argument("--platform", default="Linux64", help="Beef's name of the platform the SDK is for (Linux64)")
    parser.add_argument("--manager", help="the project manager's ShippingRelease build folder")
    parser.add_argument("--beef", default="", help="the toolchain the SDK was built and tested with (its pin)")
    parser.add_argument("--toolchain", help="that toolchain's zip, named in the index")
    parser.add_argument("--toolchain-release", default="", help="the release (tag) whose files carry the toolchain's zip, when not this one")
    parser.add_argument("--check", action="store_true", help="check what would be packed; write nothing")
    args = parser.parse_args()
    if not args.check and not args.out:
        parser.error("an output folder, or --check")
    if args.toolchain_release and not args.toolchain:
        parser.error("--toolchain-release names the release of a --toolchain")

    sdk = Sdk(args.platform, args.manager)
    sdk.gather()
    problems, named, reads = sdk.check()
    size = sum(os.path.getsize(source) for source, _ in sdk.files.values())
    if problems:
        for line in problems:
            print("pack-sdk: " + line, file=sys.stderr)
        fail(f"{len(problems)} problems; nothing packed")
    print(f"pack-sdk: {len(sdk.projects)} projects closed over their dependencies, {named} config paths and "
          f"{reads} compile-time reads packed, {len(sdk.layout['startups'])} startup libraries and "
          f"{len(sdk.layout['stock'])} stock projects present; {len(sdk.files)} files, {size // 1024} KB "
          f"for {args.platform}")
    if args.check:
        return

    version, label, build_number = engine_version()
    display = version + ("-" + label if label else "")
    platform_name = args.platform.lower()
    info = {"version": version, "label": label, "display": display, "buildNumber": build_number,
            "platform": args.platform, "beef": args.beef, "created": head_time()}
    entries = [(name, source, executable) for name, (source, executable) in sdk.files.items()]
    entries.append(("sdk.json", (json.dumps(info, indent=2) + "\n").encode("utf-8"), False))
    entries.append(("README-SDK.md", README.format(display=display, platform=args.platform).encode("utf-8"), False))
    entries.sort(key=lambda entry: entry[0])

    out = os.path.abspath(args.out)
    os.makedirs(out, exist_ok=True)
    archive = f"sedulous-sdk-{display}-{platform_name}.zip"
    path = os.path.join(out, archive)
    unpacked = write_zip(path, entries)
    index = {"version": version, "label": label, "display": display, "platform": args.platform, "archive": archive,
             "sha256": sha256(path), "size": os.path.getsize(path), "unpackedSize": unpacked, "beef": args.beef}
    if args.toolchain:
        toolchain = {"archive": os.path.basename(args.toolchain), "sha256": sha256(args.toolchain),
                     "size": os.path.getsize(args.toolchain)}
        if args.toolchain_release:
            toolchain["release"] = args.toolchain_release
        index["toolchain"] = toolchain
    index_name = f"sdk-{platform_name}.json"
    with open(os.path.join(out, index_name), "w", encoding="utf-8") as f:
        json.dump(index, f, indent=2)
        f.write("\n")
    print(f"{archive}: {len(entries)} files, {os.path.getsize(path) // 1024} KB packed, {unpacked // 1024} KB unpacked"
          + ("" if args.manager else " (no project manager: pass --manager)"))
    print(f"{index_name}: {display} for {args.platform}")


if __name__ == "__main__":
    main()
