using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.RHI;
using Sedulous.VFS;
using Sedulous.Content;
using Sedulous.Resource;
using Sedulous.Model;
using Sedulous.Model.IO;
using Sedulous.Model.GLTF;
using Sedulous.Model.FBX;
using Sedulous.Model.Resource;
using Sedulous.Engine.Composition;
using Sedulous.ModelImporter;

namespace Sedulous.Editor.ModelPreview;

// A model file opened for viewing without a project (the import window's model preview). The file
// loads through the model loaders (glTF and GLB; ufbx for FBX and OBJ) into the in-memory model,
// whose stats are shown. The model cooks into its own content database in a cache folder, and the
// cooked model binds through a resource manager with the engine's factories. The cache folder is
// named by the file's path, size and modification time, so reopening a model binds what was cooked
// before while a changed file cooks again. A record beside the cooked files keeps the model's guid
// and its stats.

/// A material as the file defines it: its name, how it shades, and the textures in its slots.
class ModelMaterialInfo
{
	public class Slot
	{
		/// "base color", "normal", ...
		public String SlotName = new .() ~ delete _;
		/// An index into ModelStats.TextureList.
		public uint32 Texture = 0;
	}

	public String Name = new .() ~ delete _;
	/// "PBR", "Phong", "Lambert", "Unlit".
	public String Shading = new .() ~ delete _;
	public List<Slot> Slots = new .() ~ DeleteContainerAndItems!(_);
}

/// A texture as the file defines it: its name, its size in pixels, and where its image is.
class ModelTextureInfo
{
	public String Name = new .() ~ delete _;
	public uint32 Width = 0;
	public uint32 Height = 0;
	/// The image's file name; empty when the image is inside the model file.
	public String File = new .() ~ delete _;
}

/// What a preview says of a model, counted from the file as it loaded.
class ModelStats
{
	public uint32 Meshes = 0;
	public uint32 Vertices = 0;
	public uint32 Triangles = 0;
	public uint32 Materials = 0;
	public uint32 Textures = 0;
	public uint32 Bones = 0;
	public uint32 Skins = 0;
	/// The animations' names, in the file's order, and their lengths.
	public List<String> Clips = new .() ~ DeleteContainerAndItems!(_);
	public List<float> ClipSeconds = new .() ~ delete _;
	/// The extent of the bounds, in the file's units.
	public Float3 Size = .Zero;
	/// Each material and its textures (after the loose texture rule).
	public List<ModelMaterialInfo> MaterialList = new .() ~ DeleteContainerAndItems!(_);
	public List<ModelTextureInfo> TextureList = new .() ~ DeleteContainerAndItems!(_);
}

static class ModelLibrary
{
	/// The file types the loaders read, for a dialog's filter and a folder scan.
	public const String cModelExtensions = "gltf;glb;fbx;obj";
	/// The version of the cache's cooked files. Raise it when the import changes what it makes, so a
	/// model opened again cooks afresh.
	public const uint32 cCacheVersion = 6; // 6: the record lists the materials and textures

	/// Whether `path` names a model file (by its extension, any case).
	public static bool IsModelFile(StringView path)
	{
		var dot = path.Length;
		while ((dot > 0) && (path[dot - 1] != '.') && (path[dot - 1] != '/'))
			--dot;
		if ((dot == 0) || (path[dot - 1] != '.'))
			return false;
		let suffix = path.Substring(dot);
		for (let known in StringView[4]("gltf", "glb", "fbx", "obj"))
		{
			if (suffix.Equals(known, true))
				return true;
		}
		return false;
	}

	/// A name for what is made from the file at `path`, appended: 16 hex digits hashed from its
	/// path, size, modification time and `version`, so a changed file or a raised version gets a
	/// new name. Nothing when the file does not exist.
	public static void FileKey(StringView path, uint32 version, String outKey)
	{
		if (!FileStat(path, let size, let modified))
			return;
		var hash = HashBytes(path.Ptr, path.Length);
		var sized = size;
		var stamped = modified;
		var versioned = version;
		hash = HashBytes(&sized, sizeof(int64), hash);
		hash = HashBytes(&stamped, sizeof(int64), hash);
		hash = HashBytes(&versioned, sizeof(uint32), hash);
		for (int i < 16)
			outKey.Append("0123456789abcdef"[(int)((hash >> (60 - 4 * i)) & 0xF)]);
	}

	/// The folder under `cacheRoot` that holds the cooked files for `path`, appended: named by
	/// FileKey with the cache version and by whether loose textures were applied, since they change
	/// what cooks. Nothing when the file does not exist.
	public static void CacheFolderFor(StringView cacheRoot, StringView path, String outFolder, bool looseTextures = true)
	{
		let key = FileKey(path, cCacheVersion * 2 + (looseTextures ? 1 : 0), .. scope .());
		if (!key.IsEmpty)
			PathJoin(cacheRoot, key, outFolder);
	}

	/// The loose texture rule: a material that names no colour texture (the link is often lost on
	/// export, common with FBX files from packs and extractions) takes an image beside the model
	/// file: the one named like the material, else the one named like the model, else the first PNG
	/// or JPEG in name order. Returns how many materials took an image.
	public static uint32 ApplyLooseTextures(Model model, StringView modelPath)
	{
		var slash = modelPath.Length;
		while ((slash > 0) && (modelPath[slash - 1] != '/') && (modelPath[slash - 1] != '\\'))
			--slash;
		StringView folder = ".";
		if (slash > 0)
			folder = modelPath.Substring(0, slash - 1);
		let modelStem = Stem(modelPath.Substring(slash));
		let images = scope List<String>();
		defer { ClearAndDeleteItems!(images); }
		ListDirectory(folder, scope [&] (name, isDirectory) =>
			{
				if (!isDirectory && IsImageFile(name))
					images.Add(new String(name));
			});
		if (images.IsEmpty)
			return 0;
		images.Sort(scope (a, b) => String.Compare(a, b, false)); // "the first" is the same each time
		String Find(StringView stem)
		{
			for (let image in images)
			{
				if (Stem(image).Equals(stem, true))
					return image;
			}
			return null;
		}
		let added = scope List<String>(); // the image file each added texture was made for (borrowed)
		let indices = scope List<int32>(); // and that texture's index in the model
		uint32 applied = 0;
		for (let material in model.Materials)
		{
			if ((material == null) || (material.BaseColorTextureIndex >= 0))
				continue;
			var chosen = Find(material.Name);
			if (chosen == null)
				chosen = Find(modelStem);
			if (chosen == null)
				chosen = images[0];
			int32 index = -1;
			for (int i < added.Count)
			{
				if (added[i] == chosen)
					index = indices[i];
			}
			if (index < 0)
			{
				let texture = new ModelTexture();
				texture.Name.Set(Stem(chosen));
				texture.Uri.Set(chosen);
				PathJoin(folder, chosen, texture.SourceFile);
				index = model.AddTexture(texture);
				added.Add(chosen);
				indices.Add(index);
			}
			material.BaseColorTextureIndex = index;
			material.BaseColorFactor = .(1.0f, 1.0f, 1.0f, 1.0f);
			applied++;
		}
		return applied;
	}

	/// A file's name, appended: what follows its last slash or backslash.
	public static void FileTitle(StringView path, String outTitle)
	{
		var start = path.Length;
		while ((start > 0) && (path[start - 1] != '/') && (path[start - 1] != '\\'))
			--start;
		outTitle.Append(path.Substring(start));
	}

	/// Counts the stats of a loaded model into `outStats`.
	public static void CountModel(Model model, ModelStats outStats)
	{
		for (let mesh in model.Meshes)
		{
			outStats.Meshes++;
			outStats.Vertices += (uint32)Math.Max(mesh.VertexCount, 0);
			// A mesh with no index buffer draws its vertices three at a time (glTF allows it).
			let corners = (mesh.IndexCount > 0) ? mesh.IndexCount : mesh.VertexCount;
			outStats.Triangles += (uint32)Math.Max(corners, 0) / 3;
		}
		outStats.Materials = (uint32)model.Materials.Length;
		outStats.Textures = (uint32)model.Textures.Length;
		for (let texture in model.Textures)
		{
			let info = new ModelTextureInfo();
			if (texture != null)
			{
				info.Name.Set(texture.Name);
				info.Width = (uint32)Math.Max(texture.Width, 0);
				info.Height = (uint32)Math.Max(texture.Height, 0);
				// The texture's own file (FBX, a DDS, the loose texture rule), else a glTF uri beside
				// the model; none when the image is inside the model file.
				if (!texture.SourceFile.IsEmpty)
					FileTitle(texture.SourceFile, info.File);
				else if (!texture.Uri.IsEmpty && !texture.Uri.StartsWith("data:"))
					FileTitle(texture.Uri, info.File);
			}
			outStats.TextureList.Add(info);
		}
		for (let material in model.Materials)
		{
			let info = new ModelMaterialInfo();
			if (material != null)
			{
				info.Name.Set(material.Name);
				switch (material.Shading)
				{
				case .Phong: info.Shading.Set("Phong");
				case .Lambert: info.Shading.Set("Lambert");
				case .Unlit: info.Shading.Set("Unlit");
				default: info.Shading.Set("PBR");
				}
				AddSlot(info, "base color", material.BaseColorTextureIndex, outStats);
				AddSlot(info, "normal", material.NormalTextureIndex, outStats);
				AddSlot(info, "metal rough", material.MetallicRoughnessTextureIndex, outStats);
				AddSlot(info, "roughness", material.SeparateRoughnessTextureIndex, outStats);
				AddSlot(info, "metalness", material.SeparateMetalnessTextureIndex, outStats);
				AddSlot(info, "occlusion", material.OcclusionTextureIndex, outStats);
				AddSlot(info, "emissive", material.EmissiveTextureIndex, outStats);
				AddSlot(info, "specular", material.SpecularTextureIndex, outStats);
			}
			outStats.MaterialList.Add(info);
		}
		// The joints of the skin the preview animates (the cook takes the first skin), not the
		// model's nodes, which include meshes and groups.
		outStats.Bones = (model.Skins.Length > 0) ? (uint32)model.Skins[0].JointCount : 0;
		outStats.Skins = (uint32)model.Skins.Length;
		for (let clip in model.Animations)
		{
			outStats.Clips.Add(new String(clip.Name));
			outStats.ClipSeconds.Add(clip.Duration);
		}
		model.CalculateBounds();
		outStats.Size = model.Bounds.Max - model.Bounds.Min;
	}

	/// The record kept beside a model's cooked files, appended: its guid, then its stats, one per
	/// line. A texture line holds its size, then its name and file separated by a tab (a name may
	/// hold spaces); a material line holds its shading and name, followed by a line per slot.
	public static void WriteRecord(Guid model, ModelStats stats, String outText)
	{
		outText.AppendF("model {}\nmeshes {}\nvertices {}\ntriangles {}\nmaterials {}\ntextures {}\nbones {}\nskins {}\nsize {} {} {}\n",
			model, stats.Meshes, stats.Vertices, stats.Triangles, stats.Materials, stats.Textures, stats.Bones, stats.Skins,
			stats.Size.X, stats.Size.Y, stats.Size.Z);
		for (int i < stats.Clips.Count)
			outText.AppendF("clip {} {}\n", stats.ClipSeconds[i], stats.Clips[i]);
		for (let texture in stats.TextureList)
			outText.AppendF("texture {} {} {}\t{}\n", texture.Width, texture.Height, texture.Name, texture.File);
		for (let material in stats.MaterialList)
		{
			outText.AppendF("material {} {}\n", material.Shading, material.Name);
			for (let slot in material.Slots)
				outText.AppendF("slot {} {}\n", slot.Texture, slot.SlotName);
		}
	}

	/// Parses a record into `outModel` and `outStats`; false when the text is not a valid record (no
	/// model guid), in which case the model cooks again.
	public static bool ReadRecord(StringView text, out Guid outModel, ModelStats outStats)
	{
		outModel = .();
		var haveModel = false;
		for (let line in text.Split('\n'))
		{
			let space = line.IndexOf(' ');
			if (space < 0)
				continue;
			let key = line.Substring(0, space);
			let value = line.Substring(space + 1);
			switch (key)
			{
			case "model":
				if (Guid.Parse(value) case .Ok(let parsed))
				{
					outModel = parsed;
					haveModel = true;
				}
			case "meshes": outStats.Meshes = Number(value);
			case "vertices": outStats.Vertices = Number(value);
			case "triangles": outStats.Triangles = Number(value);
			case "materials": outStats.Materials = Number(value);
			case "textures": outStats.Textures = Number(value);
			case "bones": outStats.Bones = Number(value);
			case "skins": outStats.Skins = Number(value);
			case "size":
				{
					float[3] parts = .();
					int at = 0;
					for (let part in value.Split(' '))
					{
						if (at < 3)
							parts[at++] = Decimal(part);
					}
					outStats.Size = .(parts[0], parts[1], parts[2]);
				}
			case "texture":
				{
					let texture = new ModelTextureInfo();
					var rest = value;
					let first = rest.IndexOf(' ');
					texture.Width = Number((first >= 0) ? rest.Substring(0, first) : rest);
					rest = (first >= 0) ? rest.Substring(first + 1) : default;
					let second = rest.IndexOf(' ');
					texture.Height = Number((second >= 0) ? rest.Substring(0, second) : rest);
					rest = (second >= 0) ? rest.Substring(second + 1) : default;
					let tab = rest.IndexOf('\t');
					texture.Name.Set((tab >= 0) ? rest.Substring(0, tab) : rest);
					if (tab >= 0)
						texture.File.Set(rest.Substring(tab + 1));
					outStats.TextureList.Add(texture);
				}
			case "material":
				{
					let material = new ModelMaterialInfo();
					let gap = value.IndexOf(' ');
					material.Shading.Set((gap >= 0) ? value.Substring(0, gap) : value);
					if (gap >= 0)
						material.Name.Set(value.Substring(gap + 1));
					outStats.MaterialList.Add(material);
				}
			case "slot":
				if (!outStats.MaterialList.IsEmpty)
				{
					let slot = new ModelMaterialInfo.Slot();
					let gap = value.IndexOf(' ');
					slot.Texture = Number((gap >= 0) ? value.Substring(0, gap) : value);
					if (gap >= 0)
						slot.SlotName.Set(value.Substring(gap + 1));
					outStats.MaterialList.Back.Slots.Add(slot);
				}
			case "clip":
				{
					let gap = value.IndexOf(' ');
					outStats.ClipSeconds.Add(Decimal((gap >= 0) ? value.Substring(0, gap) : value));
					outStats.Clips.Add(new String((gap >= 0) ? value.Substring(gap + 1) : default));
				}
			default:
			}
		}
		return haveModel;
	}

	private static void AddSlot(ModelMaterialInfo info, StringView name, int32 index, ModelStats stats)
	{
		if ((index < 0) || (index >= stats.TextureList.Count))
			return;
		let slot = new ModelMaterialInfo.Slot();
		slot.SlotName.Set(name);
		slot.Texture = (uint32)index;
		info.Slots.Add(slot);
	}

	private static uint32 Number(StringView text) => (uint32.Parse(text) case .Ok(let value)) ? value : 0;
	private static float Decimal(StringView text) => (float.Parse(text) case .Ok(let value)) ? value : 0.0f;

	/// A name without what follows its last dot.
	private static StringView Stem(StringView name)
	{
		let dot = name.LastIndexOf('.');
		return (dot > 0) ? name.Substring(0, dot) : name;
	}

	private static bool IsImageFile(StringView name)
	{
		let dot = name.LastIndexOf('.');
		if (dot < 0)
			return false;
		let suffix = name.Substring(dot + 1);
		return suffix.Equals("png", true) || suffix.Equals("jpg", true) || suffix.Equals("jpeg", true);
	}
}

/// A model file open for viewing: its stats and the bound cooked model, which lives as long as this.
class OpenModel
{
	public enum Outcome : uint8
	{
		/// Cooked by this open.
		Opened,
		/// Bound what an earlier open cooked.
		FromCache,
		NotFound,
		/// The loaders could not read it.
		LoadFailed,
		CookFailed,
		BindFailed,
	}

	public enum Begun : uint8
	{
		/// Cooked before: bound from the cache and open.
		Bound,
		/// The file must be read (LoadFile, on any thread), then Finish called.
		NeedsFile,
		Failed,
	}

	/// The record's name beside the cooked files.
	public const String cRecordName = "viewer-record.txt";

	private String mPath = new .() ~ delete _;
	private bool mLooseTextures = true;
	private String mFolder = new .() ~ delete _;
	private ModelStats mStats = new .() ~ delete _;
	private SerializerFactory mSerializers = null;
	private NativeFileSystem mFileSystem = null;
	private ContentDatabase mDatabase = null;
	private ResourceManager mResources = null;
	private ResourceFactorySet mFactories = null;
	/// Retained while open (mRetained): the manager's cache owns the handle.
	private Proxy<ModelResource> mModel = .(null);
	private bool mRetained = false;

	public ~this()
	{
		Close();
	}

	/// Whether a material without its texture takes an image beside the model (ApplyLooseTextures).
	/// On by default. It changes what cooks, so each setting has its own cache folder.
	public bool LooseTextures
	{
		get => mLooseTextures;
		set => mLooseTextures = value;
	}

	/// Opens `path`, with its cooked files under `cacheRoot`. The texture factory uploads with
	/// `device`; when it is null there are no textures. This runs Begin, LoadFile when the file must
	/// be read, then Finish, all on this thread; a window runs the same steps with the read on a
	/// worker.
	public Outcome Open(StringView path, StringView cacheRoot, IDevice device)
	{
		if (Begin(path, cacheRoot, device, let outcome) != .NeedsFile)
			return outcome;
		let model = scope Model();
		let stats = new ModelStats();
		let loaded = LoadFile(path, mLooseTextures, model, stats);
		if (loaded != .Opened)
		{
			delete stats;
			return loaded;
		}
		return Finish(model, stats);
	}

	/// Reads the file into `outModel` and counts its stats into `outStats`, applying loose textures
	/// when asked. This is the slow part of an open and is safe on any thread: it makes its own
	/// loaders rather than using the registry's. Opened on success.
	public static Outcome LoadFile(StringView path, bool looseTextures, Model outModel, ModelStats outStats)
	{
		if (!FileExists(path))
			return .NotFound;
		let gltf = scope GltfLoader();
		let fbx = scope FbxLoader();
		// The extension with its dot, as the loaders take it.
		StringView suffix = default;
		for (var i = path.Length; (i > 0) && (path[i - 1] != '/') && (path[i - 1] != '\\'); --i)
		{
			if (path[i - 1] == '.')
			{
				suffix = path.Substring(i - 1);
				break;
			}
		}
		IModelLoader loader = null;
		if (gltf.SupportsExtension(suffix))
			loader = gltf;
		else if (fbx.SupportsExtension(suffix))
			loader = fbx;
		if ((loader == null) || (loader.Load(path, outModel) != .Ok))
			return .LoadFailed;
		if (looseTextures)
			ModelLibrary.ApplyLooseTextures(outModel, path);
		ModelLibrary.CountModel(outModel, outStats);
		return .Opened;
	}

	/// The first step, run on the thread that owns the resources. It makes the cache folder, its
	/// database and resources, and binds the model when an earlier open cooked it. `outOutcome`
	/// reports the result when the return is not NeedsFile.
	public Begun Begin(StringView path, StringView cacheRoot, IDevice device, out Outcome outOutcome)
	{
		Close();
		mPath.Set(path);
		let folder = ModelLibrary.CacheFolderFor(cacheRoot, path, .. scope .(), mLooseTextures);
		outOutcome = .NotFound;
		if (folder.IsEmpty)
			return .Failed;
		outOutcome = .CookFailed;
		if (!CreateDirectory(folder) && !DirectoryExists(folder))
			return .Failed;
		mFolder.Set(folder);
		mSerializers = new (stream, mode) => new BinarySerializerContext(stream, mode);
		mFileSystem = new NativeFileSystem(folder);
		mDatabase = new ContentDatabase(mFileSystem, mSerializers, "rasset");
		mResources = new ResourceManager(mDatabase);
		mFactories = new ResourceFactorySet();
		let services = scope ResourceServiceTable();
		if (device != null)
			services.Add(typeof(IDevice), device);
		EngineComposition.CreateFactories(mFactories, services);
		mFactories.Register(mResources);
		EngineComposition.RegisterResourceTypes();

		let bytes = scope List<uint8>();
		Guid guid = .();
		let text = scope String();
		if (ReadFile(RecordPath(.. scope .()), bytes) case .Ok)
			text.Append(StringView((char8*)bytes.Ptr, bytes.Count));
		let read = new ModelStats();
		if (text.IsEmpty || !ModelLibrary.ReadRecord(text, out guid, read))
		{
			delete read;
			return .NeedsFile;
		}
		delete mStats;
		mStats = read;
		outOutcome = BindCooked(guid, .FromCache);
		return (outOutcome == .FromCache) ? .Bound : .Failed;
	}

	/// The last step, after Begin returned NeedsFile: cooks `model` (as LoadFile read it) into the
	/// cache, writes its record, and binds it. TAKES OWNERSHIP of `stats`.
	public Outcome Finish(Model model, ModelStats stats)
	{
		delete mStats;
		mStats = stats;
		if (mDatabase == null)
			return .CookFailed;
		Guid guid;
		if (ModelCook.Cook(model, mDatabase, "model") case .Ok(let cooked))
			guid = cooked;
		else
			return .CookFailed;
		let record = ModelLibrary.WriteRecord(guid, mStats, .. scope .());
		WriteFile(RecordPath(.. scope .()), .((uint8*)record.Ptr, record.Length)).IgnoreError();
		return BindCooked(guid, .Opened);
	}

	/// Releases the model and everything it bound: the manager before the factories it uses, then
	/// the database and what backs it.
	public void Close()
	{
		if (mRetained)
			mModel.Forget();
		mRetained = false;
		mModel = .(null);
		DeleteAndNullify!(mResources);
		DeleteAndNullify!(mFactories);
		DeleteAndNullify!(mDatabase);
		DeleteAndNullify!(mFileSystem);
		DeleteAndNullify!(mSerializers);
	}

	public bool IsOpen => mModel.Get != null;
	public ModelResource Model => mModel.Get;
	public ModelStats Stats => mStats;
	public StringView Path => mPath;
	public StringView CacheFolder => mFolder;
	/// The resource manager; its loads finish as it is pumped.
	public ResourceManager Resources => mResources;

	private void RecordPath(String outPath) => PathJoin(mFolder, cRecordName, outPath);

	private Outcome BindCooked(Guid guid, Outcome done)
	{
		mModel = mResources.Bind<ModelResource>(guid);
		if (mModel.Get == null)
			return .BindFailed;
		mModel.Retain();
		mRetained = true;
		return done;
	}
}
