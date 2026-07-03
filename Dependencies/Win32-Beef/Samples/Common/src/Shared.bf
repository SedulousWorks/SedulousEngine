using Win32.Foundation;
using Win32.Storage.FileSystem;
using Win32;
namespace Common;

typealias DWORD = uint32;

public static {
	public const uint32 fourccRIFF = FOURCC!('R', 'I', 'F', 'F');
	public const uint32 fourccDATA = FOURCC!('d', 'a', 't', 'a');
	public const uint32 fourccFMT = FOURCC!('f', 'm', 't', ' ');
	public const uint32 fourccWAVE = FOURCC!('W', 'A', 'V', 'E');
	public const uint32 fourccXWMA = FOURCC!('X', 'W', 'M', 'A');
	public const uint32 fourccDPDS = FOURCC!('d', 'p', 'd', 's');

	public static HRESULT FindChunk(HANDLE hFile, DWORD fourcc, ref DWORD dwChunkSize, ref DWORD dwChunkDataPosition)
	{
		HRESULT hr = S_OK;
		if (INVALID_SET_FILE_POINTER == SetFilePointer(hFile, 0, null, .FILE_BEGIN))
			return HRESULT_FROM_WIN32(GetLastError());

		DWORD dwChunkType = 0;
		DWORD dwChunkDataSize = 0;
		DWORD dwRIFFDataSize = 0;
		DWORD dwFileType = 0;
		DWORD bytesRead = 0;
		DWORD dwOffset = 0;

		while (hr == S_OK)
		{
			DWORD dwRead;
			if (0 == ReadFile(hFile, &dwChunkType, sizeof(DWORD), &dwRead, null))
				hr = HRESULT_FROM_WIN32(GetLastError());

			if (0 == ReadFile(hFile, &dwChunkDataSize, sizeof(DWORD), &dwRead, null))
				hr = HRESULT_FROM_WIN32(GetLastError());

			switch (dwChunkType)
			{
			case fourccRIFF:
				dwRIFFDataSize = dwChunkDataSize;
				dwChunkDataSize = 4;
				if (0 == ReadFile(hFile, &dwFileType, sizeof(DWORD), &dwRead, null))
					hr = HRESULT_FROM_WIN32(GetLastError());
				break;

			default:
				if (INVALID_SET_FILE_POINTER == SetFilePointer(hFile, (.)dwChunkDataSize, null, .FILE_CURRENT))
					return HRESULT_FROM_WIN32(GetLastError());
			}

			dwOffset += sizeof(DWORD) * 2;

			if (dwChunkType == fourcc)
			{
				dwChunkSize = dwChunkDataSize;
				dwChunkDataPosition = dwOffset;
				return S_OK;
			}

			dwOffset += dwChunkDataSize;

			if (bytesRead >= dwRIFFDataSize)
				return S_FALSE;
		}

		return S_OK;
	}

	public static HRESULT ReadChunkData(HANDLE hFile, void* buffer, DWORD buffersize, DWORD bufferoffset)
	{
		HRESULT hr = S_OK;
		if (INVALID_SET_FILE_POINTER == SetFilePointer(hFile, (.)bufferoffset, null, .FILE_BEGIN))
			return HRESULT_FROM_WIN32(GetLastError());
		DWORD dwRead;
		if (0 == ReadFile(hFile, buffer, buffersize, &dwRead, null))
			hr = HRESULT_FROM_WIN32(GetLastError());
		return hr;
	}

}