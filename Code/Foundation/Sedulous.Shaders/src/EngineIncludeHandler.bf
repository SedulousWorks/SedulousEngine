using System;
using System.Collections;
using System.Interop;
using Dxc_Beef;

namespace Sedulous.Shaders;

/// The one include handler every compile gives DXC.
///
/// The preprocessor forms each candidate path itself, as it always has (a quoted include: the
/// includer's directory first, then each -I directory in order) and asks for it; this handler
/// serves the candidate from the caller's IShaderIncludeResolver when one is set (no disk
/// access, a miss is not found), else from disk through DXC's default handler. Either way an
/// `effect` block in the served text is expanded before DXC sees it, so an effect's include
/// works on the cook's disk route and the editor's resolver route alike. A text without an
/// effect block is served as it was read.
///
/// A hand built COM object: DXC reaches it through a vtable, so the three IUnknown slots and
/// LoadSource are static functions taking the instance back as their first argument. It lives
/// for ONE compile on the caller's stack, and DXC does not retain it, so the reference count is
/// nominal and Release frees nothing.
[CRepr]
struct EngineIncludeHandler
{
	/// The vtable layout DXC expects: IUnknown's three, then LoadSource.
	[CRepr]
	private struct VTableLayout
	{
		public function [CallingConvention(.Stdcall)] HRESULT(EngineIncludeHandler* self,
			in Guid riid, void** ppvObject) QueryInterface;
		public function [CallingConvention(.Stdcall)] uint32(EngineIncludeHandler* self) AddRef;
		public function [CallingConvention(.Stdcall)] uint32(EngineIncludeHandler* self) Release;
		public function [CallingConvention(.Stdcall)] HRESULT(EngineIncludeHandler* self,
			c_wchar* fileName, out IDxcBlob* outSource) LoadSource;
	}

	private static VTableLayout sVTable = .()
		{
			QueryInterface = => OnQueryInterface,
			AddRef = => OnAddRef,
			Release = => OnRelease,
			LoadSource = => OnLoadSource
		};

	// FIRST FIELD, because that is what a COM pointer points at.
	private VTableLayout* mVTable = &sVTable;
	private IDxcUtils* mUtils = null;
	/// Null: from disk.
	private void* mResolver = null;
	/// DXC's default handler, owned by the compiler.
	private IDxcIncludeHandler* mDisk = null;
	private uint32 mReferences = 1;

	public this(IDxcUtils* utils, IShaderIncludeResolver resolver, IDxcIncludeHandler* disk)
	{
		mUtils = utils;
		mResolver = (resolver != null) ? Internal.UnsafeCastToPtr(resolver) : null;
		mDisk = disk;
	}

	/// The handler as DXC takes it. Valid only while this instance is alive.
	public IDxcIncludeHandler* Handle mut => (IDxcIncludeHandler*)&this;

	/// The binding's HRESULT enum names only the two success codes, so the failures this has
	/// to answer with are spelled out.
	private const HRESULT cPointer = (HRESULT)(int32)0x80004003;
	private const HRESULT cNoInterface = (HRESULT)(int32)0x80004002;
	private const HRESULT cFail = (HRESULT)(int32)0x80004005;

	private static HRESULT OnQueryInterface(EngineIncludeHandler* self, in Guid riid,
		void** ppvObject)
	{
		if (ppvObject == null)
			return cPointer;

		if ((riid == IUnknown.IID) || (riid == IDxcIncludeHandler.sIID))
		{
			*ppvObject = (void*)self;
			self.mReferences++;
			return .S_OK;
		}

		*ppvObject = null;
		return cNoInterface;
	}

	private static uint32 OnAddRef(EngineIncludeHandler* self) => ++self.mReferences;

	private static uint32 OnRelease(EngineIncludeHandler* self) =>
		(self.mReferences > 0) ? --self.mReferences : 0;

	private static HRESULT OnLoadSource(EngineIncludeHandler* self, c_wchar* fileName,
		out IDxcBlob* outSource)
	{
		outSource = null;
		if ((fileName == null) || (self.mUtils == null) || ((self.mResolver == null) && (self.mDisk == null)))
			return cPointer;

		// Every candidate the preprocessor forms is normalised the same way before the
		// resolver sees it: DXC writes the includer's directory as a "./" prefix, and on
		// Windows it separates with backslashes.
		let path = scope String();
		Narrow(fileName, path);
		path.Replace('\\', '/');
		while (path.StartsWith("./"))
			path.Remove(0, 2);

		if (self.mResolver != null)
		{
			let resolver = (IShaderIncludeResolver)Internal.UnsafeCastToObject(self.mResolver);
			let source = scope String();
			if (!resolver.LoadInclude(path, source))
				return cFail; // not found, so the preprocessor reports the miss
			return Serve(self, source, path, out outSource);
		}

		IDxcBlob* diskBlob = null;
		let read = self.mDisk.[Friend]VT.LoadSource(self.mDisk, fileName, out diskBlob);
		if ((read != .S_OK) || (diskBlob == null))
			return (read != .S_OK) ? read : cFail;
		var text = StringView((char8*)diskBlob.GetBufferPointer(), (int)diskBlob.GetBufferSize());
		if ((text.Length >= 3) && ((uint8)text[0] == 0xEF) && ((uint8)text[1] == 0xBB) && ((uint8)text[2] == 0xBF))
			text = text.Substring(3); // a UTF-8 byte order mark
		if (!ShaderProperties.HasEffect(text))
		{
			outSource = diskBlob; // exactly what DXC's own handler read
			return .S_OK;
		}
		let served = Serve(self, text, path, out outSource);
		diskBlob.Release();
		return served;
	}

	/// The text as DXC compiles it: effect blocks expanded (a block with errors becomes `#error`
	/// lines at their lines in this file, which fail the compile naming them).
	private static HRESULT Serve(EngineIncludeHandler* self, StringView text, StringView fileName,
		out IDxcBlob* outSource)
	{
		outSource = null;
		var served = text;
		let expanded = scope String();
		if (ShaderProperties.HasEffect(text))
		{
			let blocks = scope List<ShaderEffectBlock>();
			defer { ClearAndDeleteItems!(blocks); }
			ShaderProperties.ExpandEffects(text, fileName, expanded, blocks);
			served = expanded;
		}

		IDxcBlobEncoding* blob = null;
		let result = self.mUtils.[Friend]VT.CreateBlob(self.mUtils, (void*)served.Ptr,
			(uint32)served.Length, DXC_CP_UTF8, out blob);
		if ((result != .S_OK) || (blob == null))
			return (result != .S_OK) ? result : cFail;

		outSource = (IDxcBlob*)blob;
		return .S_OK;
	}

	/// The platform's wide string back to UTF-8. Two bytes per unit on Windows and four on
	/// Linux, which is why this is not a cast.
	private static void Narrow(c_wchar* wide, String outText)
	{
		for (int i = 0; wide[i] != 0; i++)
			outText.Append((char32)wide[i]);
	}
}
