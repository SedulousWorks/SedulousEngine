using System;
using System.Interop;
using Dxc_Beef;

namespace Sedulous.Shaders;

/// The include handler DXC calls when a compile carries an IShaderIncludeResolver.
///
/// A hand built COM object: DXC reaches it through a vtable, so the three IUnknown slots and
/// LoadSource are static functions taking the instance back as their first argument. It lives
/// for ONE compile on the caller's stack, and DXC does not retain it, so the reference count is
/// nominal and Release frees nothing.
[CRepr]
struct ResolverIncludeHandler
{
	/// The vtable layout DXC expects: IUnknown's three, then LoadSource.
	[CRepr]
	private struct VTableLayout
	{
		public function [CallingConvention(.Stdcall)] HRESULT(ResolverIncludeHandler* self,
			in Guid riid, void** ppvObject) QueryInterface;
		public function [CallingConvention(.Stdcall)] uint32(ResolverIncludeHandler* self) AddRef;
		public function [CallingConvention(.Stdcall)] uint32(ResolverIncludeHandler* self) Release;
		public function [CallingConvention(.Stdcall)] HRESULT(ResolverIncludeHandler* self,
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
	private void* mResolver = null;
	private uint32 mReferences = 1;

	public this(IDxcUtils* utils, IShaderIncludeResolver resolver)
	{
		mUtils = utils;
		mResolver = Internal.UnsafeCastToPtr(resolver);
	}

	/// The handler as DXC takes it. Valid only while this instance is alive.
	public IDxcIncludeHandler* Handle mut => (IDxcIncludeHandler*)&this;

	/// The binding's HRESULT enum names only the two success codes, so the failures this has
	/// to answer with are spelled out.
	private const HRESULT cPointer = (HRESULT)(int32)0x80004003;
	private const HRESULT cNoInterface = (HRESULT)(int32)0x80004002;
	private const HRESULT cFail = (HRESULT)(int32)0x80004005;

	private static HRESULT OnQueryInterface(ResolverIncludeHandler* self, in Guid riid,
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

	private static uint32 OnAddRef(ResolverIncludeHandler* self) => ++self.mReferences;

	private static uint32 OnRelease(ResolverIncludeHandler* self) =>
		(self.mReferences > 0) ? --self.mReferences : 0;

	private static HRESULT OnLoadSource(ResolverIncludeHandler* self, c_wchar* fileName,
		out IDxcBlob* outSource)
	{
		outSource = null;
		if ((fileName == null) || (self.mResolver == null) || (self.mUtils == null))
			return cPointer;

		// Every candidate the preprocessor forms is normalised the same way before the
		// resolver sees it: DXC writes the includer's directory as a "./" prefix, and on
		// Windows it separates with backslashes.
		let path = scope String();
		Narrow(fileName, path);
		path.Replace('\\', '/');
		while (path.StartsWith("./"))
			path.Remove(0, 2);

		let resolver = (IShaderIncludeResolver)Internal.UnsafeCastToObject(self.mResolver);
		let source = scope String();
		if (!resolver.LoadInclude(path, source))
			return cFail; // not found, so the preprocessor reports the miss

		IDxcBlobEncoding* blob = null;
		let result = self.mUtils.[Friend]VT.CreateBlob(self.mUtils, (void*)source.Ptr,
			(uint32)source.Length, DXC_CP_UTF8, out blob);
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
