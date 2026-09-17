using System;

namespace Dxc_Beef
{
	public static class Dxc
	{
		/// <summary>
		/// Creates a single uninitialized object of the class associated with a specified CLSID.
		/// </summary>
		/// <param name="rclsid">
		/// The CLSID associated with the data and code that will be used to create the object.
		/// </param>
		/// <param name="riid">
		/// A reference to the identifier of the interface to be used to communicate
		/// with the object.
		/// </param>
		/// <param name="ppv">
		/// Address of pointer variable that receives the interface pointer requested
		/// in riid. Upon successful return, *ppv contains the requested interface
		/// pointer. Upon failure, *ppv contains NULL.</param>
		/// <remarks>
		/// While this function is similar to CoCreateInstance, there is no COM involvement.
		/// </remarks>

#if BF_PLATFORM_WINDOWS
		[CallingConvention(.Stdcall), CLink, Import("dxcompiler.lib")]
		private static extern HRESULT DxcCreateInstance(
			in Guid rclsid,
			in Guid riid,
			out void* ppv);
#else
		/// Resolved at run time, not linked. See DxcLibrary for why: a static reference makes
		/// a wasm link fail on a symbol no browser has, for a path a browser never takes.
		private static HRESULT DxcCreateInstance(in Guid rclsid, in Guid riid, out void* ppv)
		{
			let entry = DxcLibrary.CreateInstance;
			if (entry == null)
			{
				ppv = null;
				return (HRESULT)0x80004005; // E_FAIL: no dxcompiler on this machine
			}
			return entry(rclsid, riid, out ppv);
		}
#endif

#if BF_PLATFORM_WINDOWS
		[CallingConvention(.Stdcall), CLink, Import("dxcompiler.lib")]
		private static extern HRESULT DxcCreateInstance2(
			in IMalloc* pMalloc,
			in Guid rclsid,
			in Guid riid,
			out void* ppv);
#endif

		public static HRESULT CreateInstance<T>(out T* ppv) where T : IUnknown, var
		{
			void* ptr = null;
			//Console.WriteLine($"CLSID:{T.sCLSID.GetString(.. scope .())}, IID:{T.sIID.GetString(.. scope .())}");
			var result = DxcCreateInstance(T.sCLSID, T.IID, out ptr);

			ppv = (.)ptr;

			return result;
		}
	}

	/*
	public struct DxcDiaDataSource : IUnknown
	{
		public static Guid sCLSID = CLSID_DxcDiaDataSource;
	}
	*/
}