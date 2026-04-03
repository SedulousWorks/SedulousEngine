using Win32.Foundation;
using Win32.Graphics.Direct2D.Common;
using Win32.System.Com;
using Win32.System.Com.StructuredStorage;
using Win32.Graphics.Gdi;
using Win32.UI.WindowsAndMessaging;
using Win32.Graphics.Dxgi.Common;
using System;

namespace Win32.Graphics.Imaging;

#region Constants
public static
{
	public const uint32 WINCODEC_SDK_VERSION1 = 566;
	public const uint32 WINCODEC_SDK_VERSION2 = 567;
	public const Guid CLSID_WICImagingFactory = .(0xcacaf262, 0x9370, 0x4615, 0xa1, 0x3b, 0x9f, 0x55, 0x39, 0xda, 0x4c, 0x0a);
	public const Guid CLSID_WICImagingFactory1 = .(0xcacaf262, 0x9370, 0x4615, 0xa1, 0x3b, 0x9f, 0x55, 0x39, 0xda, 0x4c, 0x0a);
	public const Guid CLSID_WICImagingFactory2 = .(0x317d06e8, 0x5f24, 0x433d, 0xbd, 0xf7, 0x79, 0xce, 0x68, 0xd8, 0xab, 0xc2);
	public const uint32 WINCODEC_SDK_VERSION = 567;
	public const Guid GUID_VendorMicrosoft = .(0xf0e749ca, 0xedef, 0x4589, 0xa7, 0x3a, 0xee, 0x0e, 0x62, 0x6a, 0x2a, 0x2b);
	public const Guid GUID_VendorMicrosoftBuiltIn = .(0x257a30fd, 0x06b6, 0x462b, 0xae, 0xa4, 0x63, 0xf7, 0x0b, 0x86, 0xe5, 0x33);
	public const Guid CLSID_WICPngDecoder = .(0x389ea17b, 0x5078, 0x4cde, 0xb6, 0xef, 0x25, 0xc1, 0x51, 0x75, 0xc7, 0x51);
	public const Guid CLSID_WICPngDecoder1 = .(0x389ea17b, 0x5078, 0x4cde, 0xb6, 0xef, 0x25, 0xc1, 0x51, 0x75, 0xc7, 0x51);
	public const Guid CLSID_WICPngDecoder2 = .(0xe018945b, 0xaa86, 0x4008, 0x9b, 0xd4, 0x67, 0x77, 0xa1, 0xe4, 0x0c, 0x11);
	public const Guid CLSID_WICBmpDecoder = .(0x6b462062, 0x7cbf, 0x400d, 0x9f, 0xdb, 0x81, 0x3d, 0xd1, 0x0f, 0x27, 0x78);
	public const Guid CLSID_WICIcoDecoder = .(0xc61bfcdf, 0x2e0f, 0x4aad, 0xa8, 0xd7, 0xe0, 0x6b, 0xaf, 0xeb, 0xcd, 0xfe);
	public const Guid CLSID_WICJpegDecoder = .(0x9456a480, 0xe88b, 0x43ea, 0x9e, 0x73, 0x0b, 0x2d, 0x9b, 0x71, 0xb1, 0xca);
	public const Guid CLSID_WICGifDecoder = .(0x381dda3c, 0x9ce9, 0x4834, 0xa2, 0x3e, 0x1f, 0x98, 0xf8, 0xfc, 0x52, 0xbe);
	public const Guid CLSID_WICTiffDecoder = .(0xb54e85d9, 0xfe23, 0x499f, 0x8b, 0x88, 0x6a, 0xce, 0xa7, 0x13, 0x75, 0x2b);
	public const Guid CLSID_WICWmpDecoder = .(0xa26cec36, 0x234c, 0x4950, 0xae, 0x16, 0xe3, 0x4a, 0xac, 0xe7, 0x1d, 0x0d);
	public const Guid CLSID_WICDdsDecoder = .(0x9053699f, 0xa341, 0x429d, 0x9e, 0x90, 0xee, 0x43, 0x7c, 0xf8, 0x0c, 0x73);
	public const Guid CLSID_WICBmpEncoder = .(0x69be8bb4, 0xd66d, 0x47c8, 0x86, 0x5a, 0xed, 0x15, 0x89, 0x43, 0x37, 0x82);
	public const Guid CLSID_WICPngEncoder = .(0x27949969, 0x876a, 0x41d7, 0x94, 0x47, 0x56, 0x8f, 0x6a, 0x35, 0xa4, 0xdc);
	public const Guid CLSID_WICJpegEncoder = .(0x1a34f5c1, 0x4a5a, 0x46dc, 0xb6, 0x44, 0x1f, 0x45, 0x67, 0xe7, 0xa6, 0x76);
	public const Guid CLSID_WICGifEncoder = .(0x114f5598, 0x0b22, 0x40a0, 0x86, 0xa1, 0xc8, 0x3e, 0xa4, 0x95, 0xad, 0xbd);
	public const Guid CLSID_WICTiffEncoder = .(0x0131be10, 0x2001, 0x4c5f, 0xa9, 0xb0, 0xcc, 0x88, 0xfa, 0xb6, 0x4c, 0xe8);
	public const Guid CLSID_WICWmpEncoder = .(0xac4ce3cb, 0xe1c1, 0x44cd, 0x82, 0x15, 0x5a, 0x16, 0x65, 0x50, 0x9e, 0xc2);
	public const Guid CLSID_WICDdsEncoder = .(0xa61dde94, 0x66ce, 0x4ac1, 0x88, 0x1b, 0x71, 0x68, 0x05, 0x88, 0x89, 0x5e);
	public const Guid CLSID_WICAdngDecoder = .(0x981d9411, 0x909e, 0x42a7, 0x8f, 0x5d, 0xa7, 0x47, 0xff, 0x05, 0x2e, 0xdb);
	public const Guid CLSID_WICJpegQualcommPhoneEncoder = .(0x68ed5c62, 0xf534, 0x4979, 0xb2, 0xb3, 0x68, 0x6a, 0x12, 0xb2, 0xb3, 0x4c);
	public const Guid CLSID_WICHeifDecoder = .(0xe9a4a80a, 0x44fe, 0x4de4, 0x89, 0x71, 0x71, 0x50, 0xb1, 0x0a, 0x51, 0x99);
	public const Guid CLSID_WICHeifEncoder = .(0x0dbecec1, 0x9eb3, 0x4860, 0x9c, 0x6f, 0xdd, 0xbe, 0x86, 0x63, 0x45, 0x75);
	public const Guid CLSID_WICWebpDecoder = .(0x7693e886, 0x51c9, 0x4070, 0x84, 0x19, 0x9f, 0x70, 0x73, 0x8e, 0xc8, 0xfa);
	public const Guid CLSID_WICRAWDecoder = .(0x41945702, 0x8302, 0x44a6, 0x94, 0x45, 0xac, 0x98, 0xe8, 0xaf, 0xa0, 0x86);
	public const Guid GUID_ContainerFormatBmp = .(0x0af1d87e, 0xfcfe, 0x4188, 0xbd, 0xeb, 0xa7, 0x90, 0x64, 0x71, 0xcb, 0xe3);
	public const Guid GUID_ContainerFormatPng = .(0x1b7cfaf4, 0x713f, 0x473c, 0xbb, 0xcd, 0x61, 0x37, 0x42, 0x5f, 0xae, 0xaf);
	public const Guid GUID_ContainerFormatIco = .(0xa3a860c4, 0x338f, 0x4c17, 0x91, 0x9a, 0xfb, 0xa4, 0xb5, 0x62, 0x8f, 0x21);
	public const Guid GUID_ContainerFormatJpeg = .(0x19e4a5aa, 0x5662, 0x4fc5, 0xa0, 0xc0, 0x17, 0x58, 0x02, 0x8e, 0x10, 0x57);
	public const Guid GUID_ContainerFormatTiff = .(0x163bcc30, 0xe2e9, 0x4f0b, 0x96, 0x1d, 0xa3, 0xe9, 0xfd, 0xb7, 0x88, 0xa3);
	public const Guid GUID_ContainerFormatGif = .(0x1f8a5601, 0x7d4d, 0x4cbd, 0x9c, 0x82, 0x1b, 0xc8, 0xd4, 0xee, 0xb9, 0xa5);
	public const Guid GUID_ContainerFormatWmp = .(0x57a37caa, 0x367a, 0x4540, 0x91, 0x6b, 0xf1, 0x83, 0xc5, 0x09, 0x3a, 0x4b);
	public const Guid GUID_ContainerFormatDds = .(0x9967cb95, 0x2e85, 0x4ac8, 0x8c, 0xa2, 0x83, 0xd7, 0xcc, 0xd4, 0x25, 0xc9);
	public const Guid GUID_ContainerFormatAdng = .(0xf3ff6d0d, 0x38c0, 0x41c4, 0xb1, 0xfe, 0x1f, 0x38, 0x24, 0xf1, 0x7b, 0x84);
	public const Guid GUID_ContainerFormatHeif = .(0xe1e62521, 0x6787, 0x405b, 0xa3, 0x39, 0x50, 0x07, 0x15, 0xb5, 0x76, 0x3f);
	public const Guid GUID_ContainerFormatWebp = .(0xe094b0e2, 0x67f2, 0x45b3, 0xb0, 0xea, 0x11, 0x53, 0x37, 0xca, 0x7c, 0xf3);
	public const Guid GUID_ContainerFormatRaw = .(0xfe99ce60, 0xf19c, 0x433c, 0xa3, 0xae, 0x00, 0xac, 0xef, 0xa9, 0xca, 0x21);
	public const Guid CLSID_WICImagingCategories = .(0xfae3d380, 0xfea4, 0x4623, 0x8c, 0x75, 0xc6, 0xb6, 0x11, 0x10, 0xb6, 0x81);
	public const Guid CATID_WICBitmapDecoders = .(0x7ed96837, 0x96f0, 0x4812, 0xb2, 0x11, 0xf1, 0x3c, 0x24, 0x11, 0x7e, 0xd3);
	public const Guid CATID_WICBitmapEncoders = .(0xac757296, 0x3522, 0x4e11, 0x98, 0x62, 0xc1, 0x7b, 0xe5, 0xa1, 0x76, 0x7e);
	public const Guid CATID_WICPixelFormats = .(0x2b46e70f, 0xcda7, 0x473e, 0x89, 0xf6, 0xdc, 0x96, 0x30, 0xa2, 0x39, 0x0b);
	public const Guid CATID_WICFormatConverters = .(0x7835eae8, 0xbf14, 0x49d1, 0x93, 0xce, 0x53, 0x3a, 0x40, 0x7b, 0x22, 0x48);
	public const Guid CATID_WICMetadataReader = .(0x05af94d8, 0x7174, 0x4cd2, 0xbe, 0x4a, 0x41, 0x24, 0xb8, 0x0e, 0xe4, 0xb8);
	public const Guid CATID_WICMetadataWriter = .(0xabe3b9a4, 0x257d, 0x4b97, 0xbd, 0x1a, 0x29, 0x4a, 0xf4, 0x96, 0x22, 0x2e);
	public const Guid CLSID_WICDefaultFormatConverter = .(0x1a3f11dc, 0xb514, 0x4b17, 0x8c, 0x5f, 0x21, 0x54, 0x51, 0x38, 0x52, 0xf1);
	public const Guid CLSID_WICFormatConverterHighColor = .(0xac75d454, 0x9f37, 0x48f8, 0xb9, 0x72, 0x4e, 0x19, 0xbc, 0x85, 0x60, 0x11);
	public const Guid CLSID_WICFormatConverterNChannel = .(0xc17cabb2, 0xd4a3, 0x47d7, 0xa5, 0x57, 0x33, 0x9b, 0x2e, 0xfb, 0xd4, 0xf1);
	public const Guid CLSID_WICFormatConverterWMPhoto = .(0x9cb5172b, 0xd600, 0x46ba, 0xab, 0x77, 0x77, 0xbb, 0x7e, 0x3a, 0x00, 0xd9);
	public const Guid CLSID_WICPlanarFormatConverter = .(0x184132b8, 0x32f8, 0x4784, 0x91, 0x31, 0xdd, 0x72, 0x24, 0xb2, 0x34, 0x38);
	public const uint32 WIC_JPEG_MAX_COMPONENT_COUNT = 4;
	public const uint32 WIC_JPEG_MAX_TABLE_INDEX = 3;
	public const uint32 WIC_JPEG_SAMPLE_FACTORS_ONE = 17;
	public const uint32 WIC_JPEG_SAMPLE_FACTORS_THREE_420 = 1118498;
	public const uint32 WIC_JPEG_SAMPLE_FACTORS_THREE_422 = 1118497;
	public const uint32 WIC_JPEG_SAMPLE_FACTORS_THREE_440 = 1118482;
	public const uint32 WIC_JPEG_SAMPLE_FACTORS_THREE_444 = 1118481;
	public const uint32 WIC_JPEG_QUANTIZATION_BASELINE_ONE = 0;
	public const uint32 WIC_JPEG_QUANTIZATION_BASELINE_THREE = 65792;
	public const uint32 WIC_JPEG_HUFFMAN_BASELINE_ONE = 0;
	public const uint32 WIC_JPEG_HUFFMAN_BASELINE_THREE = 1118464;
	public const Guid GUID_WICPixelFormatDontCare = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x00);
	public const Guid GUID_WICPixelFormat1bppIndexed = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x01);
	public const Guid GUID_WICPixelFormat2bppIndexed = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x02);
	public const Guid GUID_WICPixelFormat4bppIndexed = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x03);
	public const Guid GUID_WICPixelFormat8bppIndexed = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x04);
	public const Guid GUID_WICPixelFormatBlackWhite = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x05);
	public const Guid GUID_WICPixelFormat2bppGray = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x06);
	public const Guid GUID_WICPixelFormat4bppGray = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x07);
	public const Guid GUID_WICPixelFormat8bppGray = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x08);
	public const Guid GUID_WICPixelFormat8bppAlpha = .(0xe6cd0116, 0xeeba, 0x4161, 0xaa, 0x85, 0x27, 0xdd, 0x9f, 0xb3, 0xa8, 0x95);
	public const Guid GUID_WICPixelFormat16bppBGR555 = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x09);
	public const Guid GUID_WICPixelFormat16bppBGR565 = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x0a);
	public const Guid GUID_WICPixelFormat16bppBGRA5551 = .(0x05ec7c2b, 0xf1e6, 0x4961, 0xad, 0x46, 0xe1, 0xcc, 0x81, 0x0a, 0x87, 0xd2);
	public const Guid GUID_WICPixelFormat16bppGray = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x0b);
	public const Guid GUID_WICPixelFormat24bppBGR = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x0c);
	public const Guid GUID_WICPixelFormat24bppRGB = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x0d);
	public const Guid GUID_WICPixelFormat32bppBGR = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x0e);
	public const Guid GUID_WICPixelFormat32bppBGRA = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x0f);
	public const Guid GUID_WICPixelFormat32bppPBGRA = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x10);
	public const Guid GUID_WICPixelFormat32bppGrayFloat = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x11);
	public const Guid GUID_WICPixelFormat32bppRGB = .(0xd98c6b95, 0x3efe, 0x47d6, 0xbb, 0x25, 0xeb, 0x17, 0x48, 0xab, 0x0c, 0xf1);
	public const Guid GUID_WICPixelFormat32bppRGBA = .(0xf5c7ad2d, 0x6a8d, 0x43dd, 0xa7, 0xa8, 0xa2, 0x99, 0x35, 0x26, 0x1a, 0xe9);
	public const Guid GUID_WICPixelFormat32bppPRGBA = .(0x3cc4a650, 0xa527, 0x4d37, 0xa9, 0x16, 0x31, 0x42, 0xc7, 0xeb, 0xed, 0xba);
	public const Guid GUID_WICPixelFormat48bppRGB = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x15);
	public const Guid GUID_WICPixelFormat48bppBGR = .(0xe605a384, 0xb468, 0x46ce, 0xbb, 0x2e, 0x36, 0xf1, 0x80, 0xe6, 0x43, 0x13);
	public const Guid GUID_WICPixelFormat64bppRGB = .(0xa1182111, 0x186d, 0x4d42, 0xbc, 0x6a, 0x9c, 0x83, 0x03, 0xa8, 0xdf, 0xf9);
	public const Guid GUID_WICPixelFormat64bppRGBA = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x16);
	public const Guid GUID_WICPixelFormat64bppBGRA = .(0x1562ff7c, 0xd352, 0x46f9, 0x97, 0x9e, 0x42, 0x97, 0x6b, 0x79, 0x22, 0x46);
	public const Guid GUID_WICPixelFormat64bppPRGBA = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x17);
	public const Guid GUID_WICPixelFormat64bppPBGRA = .(0x8c518e8e, 0xa4ec, 0x468b, 0xae, 0x70, 0xc9, 0xa3, 0x5a, 0x9c, 0x55, 0x30);
	public const Guid GUID_WICPixelFormat16bppGrayFixedPoint = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x13);
	public const Guid GUID_WICPixelFormat32bppBGR101010 = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x14);
	public const Guid GUID_WICPixelFormat48bppRGBFixedPoint = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x12);
	public const Guid GUID_WICPixelFormat48bppBGRFixedPoint = .(0x49ca140e, 0xcab6, 0x493b, 0x9d, 0xdf, 0x60, 0x18, 0x7c, 0x37, 0x53, 0x2a);
	public const Guid GUID_WICPixelFormat96bppRGBFixedPoint = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x18);
	public const Guid GUID_WICPixelFormat96bppRGBFloat = .(0xe3fed78f, 0xe8db, 0x4acf, 0x84, 0xc1, 0xe9, 0x7f, 0x61, 0x36, 0xb3, 0x27);
	public const Guid GUID_WICPixelFormat128bppRGBAFloat = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x19);
	public const Guid GUID_WICPixelFormat128bppPRGBAFloat = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x1a);
	public const Guid GUID_WICPixelFormat128bppRGBFloat = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x1b);
	public const Guid GUID_WICPixelFormat32bppCMYK = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x1c);
	public const Guid GUID_WICPixelFormat64bppRGBAFixedPoint = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x1d);
	public const Guid GUID_WICPixelFormat64bppBGRAFixedPoint = .(0x356de33c, 0x54d2, 0x4a23, 0xbb, 0x04, 0x9b, 0x7b, 0xf9, 0xb1, 0xd4, 0x2d);
	public const Guid GUID_WICPixelFormat64bppRGBFixedPoint = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x40);
	public const Guid GUID_WICPixelFormat128bppRGBAFixedPoint = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x1e);
	public const Guid GUID_WICPixelFormat128bppRGBFixedPoint = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x41);
	public const Guid GUID_WICPixelFormat64bppRGBAHalf = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x3a);
	public const Guid GUID_WICPixelFormat64bppPRGBAHalf = .(0x58ad26c2, 0xc623, 0x4d9d, 0xb3, 0x20, 0x38, 0x7e, 0x49, 0xf8, 0xc4, 0x42);
	public const Guid GUID_WICPixelFormat64bppRGBHalf = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x42);
	public const Guid GUID_WICPixelFormat48bppRGBHalf = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x3b);
	public const Guid GUID_WICPixelFormat32bppRGBE = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x3d);
	public const Guid GUID_WICPixelFormat16bppGrayHalf = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x3e);
	public const Guid GUID_WICPixelFormat32bppGrayFixedPoint = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x3f);
	public const Guid GUID_WICPixelFormat32bppRGBA1010102 = .(0x25238d72, 0xfcf9, 0x4522, 0xb5, 0x14, 0x55, 0x78, 0xe5, 0xad, 0x55, 0xe0);
	public const Guid GUID_WICPixelFormat32bppRGBA1010102XR = .(0x00de6b9a, 0xc101, 0x434b, 0xb5, 0x02, 0xd0, 0x16, 0x5e, 0xe1, 0x12, 0x2c);
	public const Guid GUID_WICPixelFormat32bppR10G10B10A2 = .(0x604e1bb5, 0x8a3c, 0x4b65, 0xb1, 0x1c, 0xbc, 0x0b, 0x8d, 0xd7, 0x5b, 0x7f);
	public const Guid GUID_WICPixelFormat32bppR10G10B10A2HDR10 = .(0x9c215c5d, 0x1acc, 0x4f0e, 0xa4, 0xbc, 0x70, 0xfb, 0x3a, 0xe8, 0xfd, 0x28);
	public const Guid GUID_WICPixelFormat64bppCMYK = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x1f);
	public const Guid GUID_WICPixelFormat24bpp3Channels = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x20);
	public const Guid GUID_WICPixelFormat32bpp4Channels = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x21);
	public const Guid GUID_WICPixelFormat40bpp5Channels = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x22);
	public const Guid GUID_WICPixelFormat48bpp6Channels = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x23);
	public const Guid GUID_WICPixelFormat56bpp7Channels = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x24);
	public const Guid GUID_WICPixelFormat64bpp8Channels = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x25);
	public const Guid GUID_WICPixelFormat48bpp3Channels = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x26);
	public const Guid GUID_WICPixelFormat64bpp4Channels = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x27);
	public const Guid GUID_WICPixelFormat80bpp5Channels = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x28);
	public const Guid GUID_WICPixelFormat96bpp6Channels = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x29);
	public const Guid GUID_WICPixelFormat112bpp7Channels = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x2a);
	public const Guid GUID_WICPixelFormat128bpp8Channels = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x2b);
	public const Guid GUID_WICPixelFormat40bppCMYKAlpha = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x2c);
	public const Guid GUID_WICPixelFormat80bppCMYKAlpha = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x2d);
	public const Guid GUID_WICPixelFormat32bpp3ChannelsAlpha = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x2e);
	public const Guid GUID_WICPixelFormat40bpp4ChannelsAlpha = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x2f);
	public const Guid GUID_WICPixelFormat48bpp5ChannelsAlpha = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x30);
	public const Guid GUID_WICPixelFormat56bpp6ChannelsAlpha = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x31);
	public const Guid GUID_WICPixelFormat64bpp7ChannelsAlpha = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x32);
	public const Guid GUID_WICPixelFormat72bpp8ChannelsAlpha = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x33);
	public const Guid GUID_WICPixelFormat64bpp3ChannelsAlpha = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x34);
	public const Guid GUID_WICPixelFormat80bpp4ChannelsAlpha = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x35);
	public const Guid GUID_WICPixelFormat96bpp5ChannelsAlpha = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x36);
	public const Guid GUID_WICPixelFormat112bpp6ChannelsAlpha = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x37);
	public const Guid GUID_WICPixelFormat128bpp7ChannelsAlpha = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x38);
	public const Guid GUID_WICPixelFormat144bpp8ChannelsAlpha = .(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x39);
	public const Guid GUID_WICPixelFormat8bppY = .(0x91b4db54, 0x2df9, 0x42f0, 0xb4, 0x49, 0x29, 0x09, 0xbb, 0x3d, 0xf8, 0x8e);
	public const Guid GUID_WICPixelFormat8bppCb = .(0x1339f224, 0x6bfe, 0x4c3e, 0x93, 0x02, 0xe4, 0xf3, 0xa6, 0xd0, 0xca, 0x2a);
	public const Guid GUID_WICPixelFormat8bppCr = .(0xb8145053, 0x2116, 0x49f0, 0x88, 0x35, 0xed, 0x84, 0x4b, 0x20, 0x5c, 0x51);
	public const Guid GUID_WICPixelFormat16bppCbCr = .(0xff95ba6e, 0x11e0, 0x4263, 0xbb, 0x45, 0x01, 0x72, 0x1f, 0x34, 0x60, 0xa4);
	public const Guid GUID_WICPixelFormat16bppYQuantizedDctCoefficients = .(0xa355f433, 0x48e8, 0x4a42, 0x84, 0xd8, 0xe2, 0xaa, 0x26, 0xca, 0x80, 0xa4);
	public const Guid GUID_WICPixelFormat16bppCbQuantizedDctCoefficients = .(0xd2c4ff61, 0x56a5, 0x49c2, 0x8b, 0x5c, 0x4c, 0x19, 0x25, 0x96, 0x48, 0x37);
	public const Guid GUID_WICPixelFormat16bppCrQuantizedDctCoefficients = .(0x2fe354f0, 0x1680, 0x42d8, 0x92, 0x31, 0xe7, 0x3c, 0x05, 0x65, 0xbf, 0xc1);
	public const uint32 FACILITY_WINCODEC_ERR = 2200;
	public const uint32 WINCODEC_ERR_BASE = 8192;
	public const int32 WINCODEC_ERR_GENERIC_ERROR = -2147467259;
	public const int32 WINCODEC_ERR_INVALIDPARAMETER = -2147024809;
	public const int32 WINCODEC_ERR_OUTOFMEMORY = -2147024882;
	public const int32 WINCODEC_ERR_NOTIMPLEMENTED = -2147467263;
	public const int32 WINCODEC_ERR_ABORTED = -2147467260;
	public const int32 WINCODEC_ERR_ACCESSDENIED = -2147024891;
	public const uint32 WICRawChangeNotification_ExposureCompensation = 1;
	public const uint32 WICRawChangeNotification_NamedWhitePoint = 2;
	public const uint32 WICRawChangeNotification_KelvinWhitePoint = 4;
	public const uint32 WICRawChangeNotification_RGBWhitePoint = 8;
	public const uint32 WICRawChangeNotification_Contrast = 16;
	public const uint32 WICRawChangeNotification_Gamma = 32;
	public const uint32 WICRawChangeNotification_Sharpness = 64;
	public const uint32 WICRawChangeNotification_Saturation = 128;
	public const uint32 WICRawChangeNotification_Tint = 256;
	public const uint32 WICRawChangeNotification_NoiseReduction = 512;
	public const uint32 WICRawChangeNotification_DestinationColorContext = 1024;
	public const uint32 WICRawChangeNotification_ToneCurve = 2048;
	public const uint32 WICRawChangeNotification_Rotation = 4096;
	public const uint32 WICRawChangeNotification_RenderMode = 8192;
	public const Guid GUID_MetadataFormatUnknown = .(0xa45e592f, 0x9078, 0x4a7c, 0xad, 0xb5, 0x4e, 0xdc, 0x4f, 0xd6, 0x1b, 0x1f);
	public const Guid GUID_MetadataFormatIfd = .(0x537396c6, 0x2d8a, 0x4bb6, 0x9b, 0xf8, 0x2f, 0x0a, 0x8e, 0x2a, 0x3a, 0xdf);
	public const Guid GUID_MetadataFormatSubIfd = .(0x58a2e128, 0x2db9, 0x4e57, 0xbb, 0x14, 0x51, 0x77, 0x89, 0x1e, 0xd3, 0x31);
	public const Guid GUID_MetadataFormatExif = .(0x1c3c4f9d, 0xb84a, 0x467d, 0x94, 0x93, 0x36, 0xcf, 0xbd, 0x59, 0xea, 0x57);
	public const Guid GUID_MetadataFormatGps = .(0x7134ab8a, 0x9351, 0x44ad, 0xaf, 0x62, 0x44, 0x8d, 0xb6, 0xb5, 0x02, 0xec);
	public const Guid GUID_MetadataFormatInterop = .(0xed686f8e, 0x681f, 0x4c8b, 0xbd, 0x41, 0xa8, 0xad, 0xdb, 0xf6, 0xb3, 0xfc);
	public const Guid GUID_MetadataFormatApp0 = .(0x79007028, 0x268d, 0x45d6, 0xa3, 0xc2, 0x35, 0x4e, 0x6a, 0x50, 0x4b, 0xc9);
	public const Guid GUID_MetadataFormatApp1 = .(0x8fd3dfc3, 0xf951, 0x492b, 0x81, 0x7f, 0x69, 0xc2, 0xe6, 0xd9, 0xa5, 0xb0);
	public const Guid GUID_MetadataFormatApp13 = .(0x326556a2, 0xf502, 0x4354, 0x9c, 0xc0, 0x8e, 0x3f, 0x48, 0xea, 0xf6, 0xb5);
	public const Guid GUID_MetadataFormatIPTC = .(0x4fab0914, 0xe129, 0x4087, 0xa1, 0xd1, 0xbc, 0x81, 0x2d, 0x45, 0xa7, 0xb5);
	public const Guid GUID_MetadataFormatIRB = .(0x16100d66, 0x8570, 0x4bb9, 0xb9, 0x2d, 0xfd, 0xa4, 0xb2, 0x3e, 0xce, 0x67);
	public const Guid GUID_MetadataFormat8BIMIPTC = .(0x0010568c, 0x0852, 0x4e6a, 0xb1, 0x91, 0x5c, 0x33, 0xac, 0x5b, 0x04, 0x30);
	public const Guid GUID_MetadataFormat8BIMResolutionInfo = .(0x739f305d, 0x81db, 0x43cb, 0xac, 0x5e, 0x55, 0x01, 0x3e, 0xf9, 0xf0, 0x03);
	public const Guid GUID_MetadataFormat8BIMIPTCDigest = .(0x1ca32285, 0x9ccd, 0x4786, 0x8b, 0xd8, 0x79, 0x53, 0x9d, 0xb6, 0xa0, 0x06);
	public const Guid GUID_MetadataFormatXMP = .(0xbb5acc38, 0xf216, 0x4cec, 0xa6, 0xc5, 0x5f, 0x6e, 0x73, 0x97, 0x63, 0xa9);
	public const Guid GUID_MetadataFormatThumbnail = .(0x243dcee9, 0x8703, 0x40ee, 0x8e, 0xf0, 0x22, 0xa6, 0x00, 0xb8, 0x05, 0x8c);
	public const Guid GUID_MetadataFormatChunktEXt = .(0x568d8936, 0xc0a9, 0x4923, 0x90, 0x5d, 0xdf, 0x2b, 0x38, 0x23, 0x8f, 0xbc);
	public const Guid GUID_MetadataFormatXMPStruct = .(0x22383cf1, 0xed17, 0x4e2e, 0xaf, 0x17, 0xd8, 0x5b, 0x8f, 0x6b, 0x30, 0xd0);
	public const Guid GUID_MetadataFormatXMPBag = .(0x833cca5f, 0xdcb7, 0x4516, 0x80, 0x6f, 0x65, 0x96, 0xab, 0x26, 0xdc, 0xe4);
	public const Guid GUID_MetadataFormatXMPSeq = .(0x63e8df02, 0xeb6c, 0x456c, 0xa2, 0x24, 0xb2, 0x5e, 0x79, 0x4f, 0xd6, 0x48);
	public const Guid GUID_MetadataFormatXMPAlt = .(0x7b08a675, 0x91aa, 0x481b, 0xa7, 0x98, 0x4d, 0xa9, 0x49, 0x08, 0x61, 0x3b);
	public const Guid GUID_MetadataFormatLSD = .(0xe256031e, 0x6299, 0x4929, 0xb9, 0x8d, 0x5a, 0xc8, 0x84, 0xaf, 0xba, 0x92);
	public const Guid GUID_MetadataFormatIMD = .(0xbd2bb086, 0x4d52, 0x48dd, 0x96, 0x77, 0xdb, 0x48, 0x3e, 0x85, 0xae, 0x8f);
	public const Guid GUID_MetadataFormatGCE = .(0x2a25cad8, 0xdeeb, 0x4c69, 0xa7, 0x88, 0x0e, 0xc2, 0x26, 0x6d, 0xca, 0xfd);
	public const Guid GUID_MetadataFormatAPE = .(0x2e043dc2, 0xc967, 0x4e05, 0x87, 0x5e, 0x61, 0x8b, 0xf6, 0x7e, 0x85, 0xc3);
	public const Guid GUID_MetadataFormatJpegChrominance = .(0xf73d0dcf, 0xcec6, 0x4f85, 0x9b, 0x0e, 0x1c, 0x39, 0x56, 0xb1, 0xbe, 0xf7);
	public const Guid GUID_MetadataFormatJpegLuminance = .(0x86908007, 0xedfc, 0x4860, 0x8d, 0x4b, 0x4e, 0xe6, 0xe8, 0x3e, 0x60, 0x58);
	public const Guid GUID_MetadataFormatJpegComment = .(0x220e5f33, 0xafd3, 0x474e, 0x9d, 0x31, 0x7d, 0x4f, 0xe7, 0x30, 0xf5, 0x57);
	public const Guid GUID_MetadataFormatGifComment = .(0xc4b6e0e0, 0xcfb4, 0x4ad3, 0xab, 0x33, 0x9a, 0xad, 0x23, 0x55, 0xa3, 0x4a);
	public const Guid GUID_MetadataFormatChunkgAMA = .(0xf00935a5, 0x1d5d, 0x4cd1, 0x81, 0xb2, 0x93, 0x24, 0xd7, 0xec, 0xa7, 0x81);
	public const Guid GUID_MetadataFormatChunkbKGD = .(0xe14d3571, 0x6b47, 0x4dea, 0xb6, 0x0a, 0x87, 0xce, 0x0a, 0x78, 0xdf, 0xb7);
	public const Guid GUID_MetadataFormatChunkiTXt = .(0xc2bec729, 0x0b68, 0x4b77, 0xaa, 0x0e, 0x62, 0x95, 0xa6, 0xac, 0x18, 0x14);
	public const Guid GUID_MetadataFormatChunkcHRM = .(0x9db3655b, 0x2842, 0x44b3, 0x80, 0x67, 0x12, 0xe9, 0xb3, 0x75, 0x55, 0x6a);
	public const Guid GUID_MetadataFormatChunkhIST = .(0xc59a82da, 0xdb74, 0x48a4, 0xbd, 0x6a, 0xb6, 0x9c, 0x49, 0x31, 0xef, 0x95);
	public const Guid GUID_MetadataFormatChunkiCCP = .(0xeb4349ab, 0xb685, 0x450f, 0x91, 0xb5, 0xe8, 0x02, 0xe8, 0x92, 0x53, 0x6c);
	public const Guid GUID_MetadataFormatChunksRGB = .(0xc115fd36, 0xcc6f, 0x4e3f, 0x83, 0x63, 0x52, 0x4b, 0x87, 0xc6, 0xb0, 0xd9);
	public const Guid GUID_MetadataFormatChunktIME = .(0x6b00ae2d, 0xe24b, 0x460a, 0x98, 0xb6, 0x87, 0x8b, 0xd0, 0x30, 0x72, 0xfd);
	public const Guid GUID_MetadataFormatDds = .(0x4a064603, 0x8c33, 0x4e60, 0x9c, 0x29, 0x13, 0x62, 0x31, 0x70, 0x2d, 0x08);
	public const Guid GUID_MetadataFormatHeif = .(0x817ef3e1, 0x1288, 0x45f4, 0xa8, 0x52, 0x26, 0x0d, 0x9e, 0x7c, 0xce, 0x83);
	public const Guid GUID_MetadataFormatHeifHDR = .(0x568b8d8a, 0x1e65, 0x438c, 0x89, 0x68, 0xd6, 0x0e, 0x10, 0x12, 0xbe, 0xb9);
	public const Guid GUID_MetadataFormatWebpANIM = .(0x6dc4fda6, 0x78e6, 0x4102, 0xae, 0x35, 0xbc, 0xfa, 0x1e, 0xdc, 0xc7, 0x8b);
	public const Guid GUID_MetadataFormatWebpANMF = .(0x43c105ee, 0xb93b, 0x4abb, 0xb0, 0x03, 0xa0, 0x8c, 0x0d, 0x87, 0x04, 0x71);
	public const Guid CLSID_WICUnknownMetadataReader = .(0x699745c2, 0x5066, 0x4b82, 0xa8, 0xe3, 0xd4, 0x04, 0x78, 0xdb, 0xec, 0x8c);
	public const Guid CLSID_WICUnknownMetadataWriter = .(0xa09cca86, 0x27ba, 0x4f39, 0x90, 0x53, 0x12, 0x1f, 0xa4, 0xdc, 0x08, 0xfc);
	public const Guid CLSID_WICApp0MetadataWriter = .(0xf3c633a2, 0x46c8, 0x498e, 0x8f, 0xbb, 0xcc, 0x6f, 0x72, 0x1b, 0xbc, 0xde);
	public const Guid CLSID_WICApp0MetadataReader = .(0x43324b33, 0xa78f, 0x480f, 0x91, 0x11, 0x96, 0x38, 0xaa, 0xcc, 0xc8, 0x32);
	public const Guid CLSID_WICApp1MetadataWriter = .(0xee366069, 0x1832, 0x420f, 0xb3, 0x81, 0x04, 0x79, 0xad, 0x06, 0x6f, 0x19);
	public const Guid CLSID_WICApp1MetadataReader = .(0xdde33513, 0x774e, 0x4bcd, 0xae, 0x79, 0x02, 0xf4, 0xad, 0xfe, 0x62, 0xfc);
	public const Guid CLSID_WICApp13MetadataWriter = .(0x7b19a919, 0xa9d6, 0x49e5, 0xbd, 0x45, 0x02, 0xc3, 0x4e, 0x4e, 0x4c, 0xd5);
	public const Guid CLSID_WICApp13MetadataReader = .(0xaa7e3c50, 0x864c, 0x4604, 0xbc, 0x04, 0x8b, 0x0b, 0x76, 0xe6, 0x37, 0xf6);
	public const Guid CLSID_WICIfdMetadataReader = .(0x8f914656, 0x9d0a, 0x4eb2, 0x90, 0x19, 0x0b, 0xf9, 0x6d, 0x8a, 0x9e, 0xe6);
	public const Guid CLSID_WICIfdMetadataWriter = .(0xb1ebfc28, 0xc9bd, 0x47a2, 0x8d, 0x33, 0xb9, 0x48, 0x76, 0x97, 0x77, 0xa7);
	public const Guid CLSID_WICSubIfdMetadataReader = .(0x50d42f09, 0xecd1, 0x4b41, 0xb6, 0x5d, 0xda, 0x1f, 0xda, 0xa7, 0x56, 0x63);
	public const Guid CLSID_WICSubIfdMetadataWriter = .(0x8ade5386, 0x8e9b, 0x4f4c, 0xac, 0xf2, 0xf0, 0x00, 0x87, 0x06, 0xb2, 0x38);
	public const Guid CLSID_WICExifMetadataReader = .(0xd9403860, 0x297f, 0x4a49, 0xbf, 0x9b, 0x77, 0x89, 0x81, 0x50, 0xa4, 0x42);
	public const Guid CLSID_WICExifMetadataWriter = .(0xc9a14cda, 0xc339, 0x460b, 0x90, 0x78, 0xd4, 0xde, 0xbc, 0xfa, 0xbe, 0x91);
	public const Guid CLSID_WICGpsMetadataReader = .(0x3697790b, 0x223b, 0x484e, 0x99, 0x25, 0xc4, 0x86, 0x92, 0x18, 0xf1, 0x7a);
	public const Guid CLSID_WICGpsMetadataWriter = .(0xcb8c13e4, 0x62b5, 0x4c96, 0xa4, 0x8b, 0x6b, 0xa6, 0xac, 0xe3, 0x9c, 0x76);
	public const Guid CLSID_WICInteropMetadataReader = .(0xb5c8b898, 0x0074, 0x459f, 0xb7, 0x00, 0x86, 0x0d, 0x46, 0x51, 0xea, 0x14);
	public const Guid CLSID_WICInteropMetadataWriter = .(0x122ec645, 0xcd7e, 0x44d8, 0xb1, 0x86, 0x2c, 0x8c, 0x20, 0xc3, 0xb5, 0x0f);
	public const Guid CLSID_WICThumbnailMetadataReader = .(0xfb012959, 0xf4f6, 0x44d7, 0x9d, 0x09, 0xda, 0xa0, 0x87, 0xa9, 0xdb, 0x57);
	public const Guid CLSID_WICThumbnailMetadataWriter = .(0xd049b20c, 0x5dd0, 0x44fe, 0xb0, 0xb3, 0x8f, 0x92, 0xc8, 0xe6, 0xd0, 0x80);
	public const Guid CLSID_WICIPTCMetadataReader = .(0x03012959, 0xf4f6, 0x44d7, 0x9d, 0x09, 0xda, 0xa0, 0x87, 0xa9, 0xdb, 0x57);
	public const Guid CLSID_WICIPTCMetadataWriter = .(0x1249b20c, 0x5dd0, 0x44fe, 0xb0, 0xb3, 0x8f, 0x92, 0xc8, 0xe6, 0xd0, 0x80);
	public const Guid CLSID_WICIRBMetadataReader = .(0xd4dcd3d7, 0xb4c2, 0x47d9, 0xa6, 0xbf, 0xb8, 0x9b, 0xa3, 0x96, 0xa4, 0xa3);
	public const Guid CLSID_WICIRBMetadataWriter = .(0x5c5c1935, 0x0235, 0x4434, 0x80, 0xbc, 0x25, 0x1b, 0xc1, 0xec, 0x39, 0xc6);
	public const Guid CLSID_WIC8BIMIPTCMetadataReader = .(0x0010668c, 0x0801, 0x4da6, 0xa4, 0xa4, 0x82, 0x65, 0x22, 0xb6, 0xd2, 0x8f);
	public const Guid CLSID_WIC8BIMIPTCMetadataWriter = .(0x00108226, 0xee41, 0x44a2, 0x9e, 0x9c, 0x4b, 0xe4, 0xd5, 0xb1, 0xd2, 0xcd);
	public const Guid CLSID_WIC8BIMResolutionInfoMetadataReader = .(0x5805137a, 0xe348, 0x4f7c, 0xb3, 0xcc, 0x6d, 0xb9, 0x96, 0x5a, 0x05, 0x99);
	public const Guid CLSID_WIC8BIMResolutionInfoMetadataWriter = .(0x4ff2fe0e, 0xe74a, 0x4b71, 0x98, 0xc4, 0xab, 0x7d, 0xc1, 0x67, 0x07, 0xba);
	public const Guid CLSID_WIC8BIMIPTCDigestMetadataReader = .(0x02805f1e, 0xd5aa, 0x415b, 0x82, 0xc5, 0x61, 0xc0, 0x33, 0xa9, 0x88, 0xa6);
	public const Guid CLSID_WIC8BIMIPTCDigestMetadataWriter = .(0x2db5e62b, 0x0d67, 0x495f, 0x8f, 0x9d, 0xc2, 0xf0, 0x18, 0x86, 0x47, 0xac);
	public const Guid CLSID_WICPngTextMetadataReader = .(0x4b59afcc, 0xb8c3, 0x408a, 0xb6, 0x70, 0x89, 0xe5, 0xfa, 0xb6, 0xfd, 0xa7);
	public const Guid CLSID_WICPngTextMetadataWriter = .(0xb5ebafb9, 0x253e, 0x4a72, 0xa7, 0x44, 0x07, 0x62, 0xd2, 0x68, 0x56, 0x83);
	public const Guid CLSID_WICXMPMetadataReader = .(0x72b624df, 0xae11, 0x4948, 0xa6, 0x5c, 0x35, 0x1e, 0xb0, 0x82, 0x94, 0x19);
	public const Guid CLSID_WICXMPMetadataWriter = .(0x1765e14e, 0x1bd4, 0x462e, 0xb6, 0xb1, 0x59, 0x0b, 0xf1, 0x26, 0x2a, 0xc6);
	public const Guid CLSID_WICXMPStructMetadataReader = .(0x01b90d9a, 0x8209, 0x47f7, 0x9c, 0x52, 0xe1, 0x24, 0x4b, 0xf5, 0x0c, 0xed);
	public const Guid CLSID_WICXMPStructMetadataWriter = .(0x22c21f93, 0x7ddb, 0x411c, 0x9b, 0x17, 0xc5, 0xb7, 0xbd, 0x06, 0x4a, 0xbc);
	public const Guid CLSID_WICXMPBagMetadataReader = .(0xe7e79a30, 0x4f2c, 0x4fab, 0x8d, 0x00, 0x39, 0x4f, 0x2d, 0x6b, 0xbe, 0xbe);
	public const Guid CLSID_WICXMPBagMetadataWriter = .(0xed822c8c, 0xd6be, 0x4301, 0xa6, 0x31, 0x0e, 0x14, 0x16, 0xba, 0xd2, 0x8f);
	public const Guid CLSID_WICXMPSeqMetadataReader = .(0x7f12e753, 0xfc71, 0x43d7, 0xa5, 0x1d, 0x92, 0xf3, 0x59, 0x77, 0xab, 0xb5);
	public const Guid CLSID_WICXMPSeqMetadataWriter = .(0x6d68d1de, 0xd432, 0x4b0f, 0x92, 0x3a, 0x09, 0x11, 0x83, 0xa9, 0xbd, 0xa7);
	public const Guid CLSID_WICXMPAltMetadataReader = .(0xaa94dcc2, 0xb8b0, 0x4898, 0xb8, 0x35, 0x00, 0x0a, 0xab, 0xd7, 0x43, 0x93);
	public const Guid CLSID_WICXMPAltMetadataWriter = .(0x076c2a6c, 0xf78f, 0x4c46, 0xa7, 0x23, 0x35, 0x83, 0xe7, 0x08, 0x76, 0xea);
	public const Guid CLSID_WICLSDMetadataReader = .(0x41070793, 0x59e4, 0x479a, 0xa1, 0xf7, 0x95, 0x4a, 0xdc, 0x2e, 0xf5, 0xfc);
	public const Guid CLSID_WICLSDMetadataWriter = .(0x73c037e7, 0xe5d9, 0x4954, 0x87, 0x6a, 0x6d, 0xa8, 0x1d, 0x6e, 0x57, 0x68);
	public const Guid CLSID_WICGCEMetadataReader = .(0xb92e345d, 0xf52d, 0x41f3, 0xb5, 0x62, 0x08, 0x1b, 0xc7, 0x72, 0xe3, 0xb9);
	public const Guid CLSID_WICGCEMetadataWriter = .(0xaf95dc76, 0x16b2, 0x47f4, 0xb3, 0xea, 0x3c, 0x31, 0x79, 0x66, 0x93, 0xe7);
	public const Guid CLSID_WICIMDMetadataReader = .(0x7447a267, 0x0015, 0x42c8, 0xa8, 0xf1, 0xfb, 0x3b, 0x94, 0xc6, 0x83, 0x61);
	public const Guid CLSID_WICIMDMetadataWriter = .(0x8c89071f, 0x452e, 0x4e95, 0x96, 0x82, 0x9d, 0x10, 0x24, 0x62, 0x71, 0x72);
	public const Guid CLSID_WICAPEMetadataReader = .(0x1767b93a, 0xb021, 0x44ea, 0x92, 0x0f, 0x86, 0x3c, 0x11, 0xf4, 0xf7, 0x68);
	public const Guid CLSID_WICAPEMetadataWriter = .(0xbd6edfca, 0x2890, 0x482f, 0xb2, 0x33, 0x8d, 0x73, 0x39, 0xa1, 0xcf, 0x8d);
	public const Guid CLSID_WICJpegChrominanceMetadataReader = .(0x50b1904b, 0xf28f, 0x4574, 0x93, 0xf4, 0x0b, 0xad, 0xe8, 0x2c, 0x69, 0xe9);
	public const Guid CLSID_WICJpegChrominanceMetadataWriter = .(0x3ff566f0, 0x6e6b, 0x49d4, 0x96, 0xe6, 0xb7, 0x88, 0x86, 0x69, 0x2c, 0x62);
	public const Guid CLSID_WICJpegLuminanceMetadataReader = .(0x356f2f88, 0x05a6, 0x4728, 0xb9, 0xa4, 0x1b, 0xfb, 0xce, 0x04, 0xd8, 0x38);
	public const Guid CLSID_WICJpegLuminanceMetadataWriter = .(0x1d583abc, 0x8a0e, 0x4657, 0x99, 0x82, 0xa3, 0x80, 0xca, 0x58, 0xfb, 0x4b);
	public const Guid CLSID_WICJpegCommentMetadataReader = .(0x9f66347c, 0x60c4, 0x4c4d, 0xab, 0x58, 0xd2, 0x35, 0x86, 0x85, 0xf6, 0x07);
	public const Guid CLSID_WICJpegCommentMetadataWriter = .(0xe573236f, 0x55b1, 0x4eda, 0x81, 0xea, 0x9f, 0x65, 0xdb, 0x02, 0x90, 0xd3);
	public const Guid CLSID_WICGifCommentMetadataReader = .(0x32557d3b, 0x69dc, 0x4f95, 0x83, 0x6e, 0xf5, 0x97, 0x2b, 0x2f, 0x61, 0x59);
	public const Guid CLSID_WICGifCommentMetadataWriter = .(0xa02797fc, 0xc4ae, 0x418c, 0xaf, 0x95, 0xe6, 0x37, 0xc7, 0xea, 0xd2, 0xa1);
	public const Guid CLSID_WICPngGamaMetadataReader = .(0x3692ca39, 0xe082, 0x4350, 0x9e, 0x1f, 0x37, 0x04, 0xcb, 0x08, 0x3c, 0xd5);
	public const Guid CLSID_WICPngGamaMetadataWriter = .(0xff036d13, 0x5d4b, 0x46dd, 0xb1, 0x0f, 0x10, 0x66, 0x93, 0xd9, 0xfe, 0x4f);
	public const Guid CLSID_WICPngBkgdMetadataReader = .(0x0ce7a4a6, 0x03e8, 0x4a60, 0x9d, 0x15, 0x28, 0x2e, 0xf3, 0x2e, 0xe7, 0xda);
	public const Guid CLSID_WICPngBkgdMetadataWriter = .(0x68e3f2fd, 0x31ae, 0x4441, 0xbb, 0x6a, 0xfd, 0x70, 0x47, 0x52, 0x5f, 0x90);
	public const Guid CLSID_WICPngItxtMetadataReader = .(0xaabfb2fa, 0x3e1e, 0x4a8f, 0x89, 0x77, 0x55, 0x56, 0xfb, 0x94, 0xea, 0x23);
	public const Guid CLSID_WICPngItxtMetadataWriter = .(0x31879719, 0xe751, 0x4df8, 0x98, 0x1d, 0x68, 0xdf, 0xf6, 0x77, 0x04, 0xed);
	public const Guid CLSID_WICPngChrmMetadataReader = .(0xf90b5f36, 0x367b, 0x402a, 0x9d, 0xd1, 0xbc, 0x0f, 0xd5, 0x9d, 0x8f, 0x62);
	public const Guid CLSID_WICPngChrmMetadataWriter = .(0xe23ce3eb, 0x5608, 0x4e83, 0xbc, 0xef, 0x27, 0xb1, 0x98, 0x7e, 0x51, 0xd7);
	public const Guid CLSID_WICPngHistMetadataReader = .(0x877a0bb7, 0xa313, 0x4491, 0x87, 0xb5, 0x2e, 0x6d, 0x05, 0x94, 0xf5, 0x20);
	public const Guid CLSID_WICPngHistMetadataWriter = .(0x8a03e749, 0x672e, 0x446e, 0xbf, 0x1f, 0x2c, 0x11, 0xd2, 0x33, 0xb6, 0xff);
	public const Guid CLSID_WICPngIccpMetadataReader = .(0xf5d3e63b, 0xcb0f, 0x4628, 0xa4, 0x78, 0x6d, 0x82, 0x44, 0xbe, 0x36, 0xb1);
	public const Guid CLSID_WICPngIccpMetadataWriter = .(0x16671e5f, 0x0ce6, 0x4cc4, 0x97, 0x68, 0xe8, 0x9f, 0xe5, 0x01, 0x8a, 0xde);
	public const Guid CLSID_WICPngSrgbMetadataReader = .(0xfb40360c, 0x547e, 0x4956, 0xa3, 0xb9, 0xd4, 0x41, 0x88, 0x59, 0xba, 0x66);
	public const Guid CLSID_WICPngSrgbMetadataWriter = .(0xa6ee35c6, 0x87ec, 0x47df, 0x9f, 0x22, 0x1d, 0x5a, 0xad, 0x84, 0x0c, 0x82);
	public const Guid CLSID_WICPngTimeMetadataReader = .(0xd94edf02, 0xefe5, 0x4f0d, 0x85, 0xc8, 0xf5, 0xa6, 0x8b, 0x30, 0x00, 0xb1);
	public const Guid CLSID_WICPngTimeMetadataWriter = .(0x1ab78400, 0xb5a3, 0x4d91, 0x8a, 0xce, 0x33, 0xfc, 0xd1, 0x49, 0x9b, 0xe6);
	public const Guid CLSID_WICDdsMetadataReader = .(0x276c88ca, 0x7533, 0x4a86, 0xb6, 0x76, 0x66, 0xb3, 0x60, 0x80, 0xd4, 0x84);
	public const Guid CLSID_WICDdsMetadataWriter = .(0xfd688bbd, 0x31ed, 0x4db7, 0xa7, 0x23, 0x93, 0x49, 0x27, 0xd3, 0x83, 0x67);
	public const Guid CLSID_WICHeifMetadataReader = .(0xacddfc3f, 0x85ec, 0x41bc, 0xbd, 0xef, 0x1b, 0xc2, 0x62, 0xe4, 0xdb, 0x05);
	public const Guid CLSID_WICHeifMetadataWriter = .(0x3ae45e79, 0x40bc, 0x4401, 0xac, 0xe5, 0xdd, 0x3c, 0xb1, 0x6e, 0x6a, 0xfe);
	public const Guid CLSID_WICHeifHDRMetadataReader = .(0x2438de3d, 0x94d9, 0x4be8, 0x84, 0xa8, 0x4d, 0xe9, 0x5a, 0x57, 0x5e, 0x75);
	public const Guid CLSID_WICWebpAnimMetadataReader = .(0x076f9911, 0xa348, 0x465c, 0xa8, 0x07, 0xa2, 0x52, 0xf3, 0xf2, 0xd3, 0xde);
	public const Guid CLSID_WICWebpAnmfMetadataReader = .(0x85a10b03, 0xc9f6, 0x439f, 0xbe, 0x5e, 0xc0, 0xfb, 0xef, 0x67, 0x80, 0x7c);
}
#endregion

#region Enums

[AllowDuplicates]
public enum WICColorContextType : int32
{
	WICColorContextUninitialized = 0,
	WICColorContextProfile = 1,
	WICColorContextExifColorSpace = 2,
}


[AllowDuplicates]
public enum WICBitmapCreateCacheOption : int32
{
	WICBitmapNoCache = 0,
	WICBitmapCacheOnDemand = 1,
	WICBitmapCacheOnLoad = 2,
	WICBITMAPCREATECACHEOPTION_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WICDecodeOptions : int32
{
	WICDecodeMetadataCacheOnDemand = 0,
	WICDecodeMetadataCacheOnLoad = 1,
	WICMETADATACACHEOPTION_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WICBitmapEncoderCacheOption : int32
{
	WICBitmapEncoderCacheInMemory = 0,
	WICBitmapEncoderCacheTempFile = 1,
	WICBitmapEncoderNoCache = 2,
	WICBITMAPENCODERCACHEOPTION_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WICComponentType : int32
{
	WICDecoder = 1,
	WICEncoder = 2,
	WICPixelFormatConverter = 4,
	WICMetadataReader = 8,
	WICMetadataWriter = 16,
	WICPixelFormat = 32,
	WICAllComponents = 63,
	WICCOMPONENTTYPE_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WICComponentEnumerateOptions : int32
{
	WICComponentEnumerateDefault = 0,
	WICComponentEnumerateRefresh = 1,
	WICComponentEnumerateDisabled = -2147483648,
	WICComponentEnumerateUnsigned = 1073741824,
	WICComponentEnumerateBuiltInOnly = 536870912,
	WICCOMPONENTENUMERATEOPTIONS_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WICBitmapInterpolationMode : int32
{
	WICBitmapInterpolationModeNearestNeighbor = 0,
	WICBitmapInterpolationModeLinear = 1,
	WICBitmapInterpolationModeCubic = 2,
	WICBitmapInterpolationModeFant = 3,
	WICBitmapInterpolationModeHighQualityCubic = 4,
	WICBITMAPINTERPOLATIONMODE_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WICBitmapPaletteType : int32
{
	WICBitmapPaletteTypeCustom = 0,
	WICBitmapPaletteTypeMedianCut = 1,
	WICBitmapPaletteTypeFixedBW = 2,
	WICBitmapPaletteTypeFixedHalftone8 = 3,
	WICBitmapPaletteTypeFixedHalftone27 = 4,
	WICBitmapPaletteTypeFixedHalftone64 = 5,
	WICBitmapPaletteTypeFixedHalftone125 = 6,
	WICBitmapPaletteTypeFixedHalftone216 = 7,
	WICBitmapPaletteTypeFixedWebPalette = 7,
	WICBitmapPaletteTypeFixedHalftone252 = 8,
	WICBitmapPaletteTypeFixedHalftone256 = 9,
	WICBitmapPaletteTypeFixedGray4 = 10,
	WICBitmapPaletteTypeFixedGray16 = 11,
	WICBitmapPaletteTypeFixedGray256 = 12,
	WICBITMAPPALETTETYPE_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WICBitmapDitherType : int32
{
	WICBitmapDitherTypeNone = 0,
	WICBitmapDitherTypeSolid = 0,
	WICBitmapDitherTypeOrdered4x4 = 1,
	WICBitmapDitherTypeOrdered8x8 = 2,
	WICBitmapDitherTypeOrdered16x16 = 3,
	WICBitmapDitherTypeSpiral4x4 = 4,
	WICBitmapDitherTypeSpiral8x8 = 5,
	WICBitmapDitherTypeDualSpiral4x4 = 6,
	WICBitmapDitherTypeDualSpiral8x8 = 7,
	WICBitmapDitherTypeErrorDiffusion = 8,
	WICBITMAPDITHERTYPE_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WICBitmapAlphaChannelOption : int32
{
	WICBitmapUseAlpha = 0,
	WICBitmapUsePremultipliedAlpha = 1,
	WICBitmapIgnoreAlpha = 2,
	WICBITMAPALPHACHANNELOPTIONS_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WICBitmapTransformOptions : int32
{
	WICBitmapTransformRotate0 = 0,
	WICBitmapTransformRotate90 = 1,
	WICBitmapTransformRotate180 = 2,
	WICBitmapTransformRotate270 = 3,
	WICBitmapTransformFlipHorizontal = 8,
	WICBitmapTransformFlipVertical = 16,
	WICBITMAPTRANSFORMOPTIONS_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WICBitmapLockFlags : int32
{
	WICBitmapLockRead = 1,
	WICBitmapLockWrite = 2,
	WICBITMAPLOCKFLAGS_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WICBitmapDecoderCapabilities : int32
{
	WICBitmapDecoderCapabilitySameEncoder = 1,
	WICBitmapDecoderCapabilityCanDecodeAllImages = 2,
	WICBitmapDecoderCapabilityCanDecodeSomeImages = 4,
	WICBitmapDecoderCapabilityCanEnumerateMetadata = 8,
	WICBitmapDecoderCapabilityCanDecodeThumbnail = 16,
	WICBITMAPDECODERCAPABILITIES_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WICProgressOperation : int32
{
	WICProgressOperationCopyPixels = 1,
	WICProgressOperationWritePixels = 2,
	WICProgressOperationAll = 65535,
	WICPROGRESSOPERATION_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WICProgressNotification : int32
{
	WICProgressNotificationBegin = 65536,
	WICProgressNotificationEnd = 131072,
	WICProgressNotificationFrequent = 262144,
	WICProgressNotificationAll = -65536,
	WICPROGRESSNOTIFICATION_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WICComponentSigning : int32
{
	WICComponentSigned = 1,
	WICComponentUnsigned = 2,
	WICComponentSafe = 4,
	WICComponentDisabled = -2147483648,
	WICCOMPONENTSIGNING_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WICGifLogicalScreenDescriptorProperties : uint32
{
	WICGifLogicalScreenSignature = 1,
	WICGifLogicalScreenDescriptorWidth = 2,
	WICGifLogicalScreenDescriptorHeight = 3,
	WICGifLogicalScreenDescriptorGlobalColorTableFlag = 4,
	WICGifLogicalScreenDescriptorColorResolution = 5,
	WICGifLogicalScreenDescriptorSortFlag = 6,
	WICGifLogicalScreenDescriptorGlobalColorTableSize = 7,
	WICGifLogicalScreenDescriptorBackgroundColorIndex = 8,
	WICGifLogicalScreenDescriptorPixelAspectRatio = 9,
	WICGifLogicalScreenDescriptorProperties_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WICGifImageDescriptorProperties : uint32
{
	WICGifImageDescriptorLeft = 1,
	WICGifImageDescriptorTop = 2,
	WICGifImageDescriptorWidth = 3,
	WICGifImageDescriptorHeight = 4,
	WICGifImageDescriptorLocalColorTableFlag = 5,
	WICGifImageDescriptorInterlaceFlag = 6,
	WICGifImageDescriptorSortFlag = 7,
	WICGifImageDescriptorLocalColorTableSize = 8,
	WICGifImageDescriptorProperties_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WICGifGraphicControlExtensionProperties : uint32
{
	WICGifGraphicControlExtensionDisposal = 1,
	WICGifGraphicControlExtensionUserInputFlag = 2,
	WICGifGraphicControlExtensionTransparencyFlag = 3,
	WICGifGraphicControlExtensionDelay = 4,
	WICGifGraphicControlExtensionTransparentColorIndex = 5,
	WICGifGraphicControlExtensionProperties_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WICGifApplicationExtensionProperties : uint32
{
	WICGifApplicationExtensionApplication = 1,
	WICGifApplicationExtensionData = 2,
	WICGifApplicationExtensionProperties_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WICGifCommentExtensionProperties : uint32
{
	WICGifCommentExtensionText = 1,
	WICGifCommentExtensionProperties_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WICJpegCommentProperties : uint32
{
	WICJpegCommentText = 1,
	WICJpegCommentProperties_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WICJpegLuminanceProperties : uint32
{
	WICJpegLuminanceTable = 1,
	WICJpegLuminanceProperties_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WICJpegChrominanceProperties : uint32
{
	WICJpegChrominanceTable = 1,
	WICJpegChrominanceProperties_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WIC8BIMIptcProperties : uint32
{
	WIC8BIMIptcPString = 0,
	WIC8BIMIptcEmbeddedIPTC = 1,
	WIC8BIMIptcProperties_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WIC8BIMResolutionInfoProperties : uint32
{
	WIC8BIMResolutionInfoPString = 1,
	WIC8BIMResolutionInfoHResolution = 2,
	WIC8BIMResolutionInfoHResolutionUnit = 3,
	WIC8BIMResolutionInfoWidthUnit = 4,
	WIC8BIMResolutionInfoVResolution = 5,
	WIC8BIMResolutionInfoVResolutionUnit = 6,
	WIC8BIMResolutionInfoHeightUnit = 7,
	WIC8BIMResolutionInfoProperties_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WIC8BIMIptcDigestProperties : uint32
{
	WIC8BIMIptcDigestPString = 1,
	WIC8BIMIptcDigestIptcDigest = 2,
	WIC8BIMIptcDigestProperties_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WICPngGamaProperties : uint32
{
	WICPngGamaGamma = 1,
	WICPngGamaProperties_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WICPngBkgdProperties : uint32
{
	WICPngBkgdBackgroundColor = 1,
	WICPngBkgdProperties_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WICPngItxtProperties : uint32
{
	WICPngItxtKeyword = 1,
	WICPngItxtCompressionFlag = 2,
	WICPngItxtLanguageTag = 3,
	WICPngItxtTranslatedKeyword = 4,
	WICPngItxtText = 5,
	WICPngItxtProperties_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WICPngChrmProperties : uint32
{
	WICPngChrmWhitePointX = 1,
	WICPngChrmWhitePointY = 2,
	WICPngChrmRedX = 3,
	WICPngChrmRedY = 4,
	WICPngChrmGreenX = 5,
	WICPngChrmGreenY = 6,
	WICPngChrmBlueX = 7,
	WICPngChrmBlueY = 8,
	WICPngChrmProperties_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WICPngHistProperties : uint32
{
	WICPngHistFrequencies = 1,
	WICPngHistProperties_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WICPngIccpProperties : uint32
{
	WICPngIccpProfileName = 1,
	WICPngIccpProfileData = 2,
	WICPngIccpProperties_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WICPngSrgbProperties : uint32
{
	WICPngSrgbRenderingIntent = 1,
	WICPngSrgbProperties_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WICPngTimeProperties : uint32
{
	WICPngTimeYear = 1,
	WICPngTimeMonth = 2,
	WICPngTimeDay = 3,
	WICPngTimeHour = 4,
	WICPngTimeMinute = 5,
	WICPngTimeSecond = 6,
	WICPngTimeProperties_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WICHeifProperties : uint32
{
	WICHeifOrientation = 1,
	WICHeifProperties_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WICHeifHdrProperties : uint32
{
	WICHeifHdrMaximumLuminanceLevel = 1,
	WICHeifHdrMaximumFrameAverageLuminanceLevel = 2,
	WICHeifHdrMinimumMasteringDisplayLuminanceLevel = 3,
	WICHeifHdrMaximumMasteringDisplayLuminanceLevel = 4,
	WICHeifHdrCustomVideoPrimaries = 5,
	WICHeifHdrProperties_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WICWebpAnimProperties : uint32
{
	WICWebpAnimLoopCount = 1,
	WICWebpAnimProperties_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WICWebpAnmfProperties : uint32
{
	WICWebpAnmfFrameDuration = 1,
	WICWebpAnmfProperties_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WICSectionAccessLevel : uint32
{
	WICSectionAccessLevelRead = 1,
	WICSectionAccessLevelReadWrite = 3,
	WICSectionAccessLevel_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WICPixelFormatNumericRepresentation : uint32
{
	WICPixelFormatNumericRepresentationUnspecified = 0,
	WICPixelFormatNumericRepresentationIndexed = 1,
	WICPixelFormatNumericRepresentationUnsignedInteger = 2,
	WICPixelFormatNumericRepresentationSignedInteger = 3,
	WICPixelFormatNumericRepresentationFixed = 4,
	WICPixelFormatNumericRepresentationFloat = 5,
	WICPixelFormatNumericRepresentation_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WICPlanarOptions : int32
{
	WICPlanarOptionsDefault = 0,
	WICPlanarOptionsPreserveSubsampling = 1,
	WICPLANAROPTIONS_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WICJpegIndexingOptions : uint32
{
	WICJpegIndexingOptionsGenerateOnDemand = 0,
	WICJpegIndexingOptionsGenerateOnLoad = 1,
	WICJpegIndexingOptions_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WICJpegTransferMatrix : uint32
{
	WICJpegTransferMatrixIdentity = 0,
	WICJpegTransferMatrixBT601 = 1,
	WICJpegTransferMatrix_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WICJpegScanType : uint32
{
	WICJpegScanTypeInterleaved = 0,
	WICJpegScanTypePlanarComponents = 1,
	WICJpegScanTypeProgressive = 2,
	WICJpegScanType_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WICTiffCompressionOption : int32
{
	WICTiffCompressionDontCare = 0,
	WICTiffCompressionNone = 1,
	WICTiffCompressionCCITT3 = 2,
	WICTiffCompressionCCITT4 = 3,
	WICTiffCompressionLZW = 4,
	WICTiffCompressionRLE = 5,
	WICTiffCompressionZIP = 6,
	WICTiffCompressionLZWHDifferencing = 7,
	WICTIFFCOMPRESSIONOPTION_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WICJpegYCrCbSubsamplingOption : int32
{
	WICJpegYCrCbSubsamplingDefault = 0,
	WICJpegYCrCbSubsampling420 = 1,
	WICJpegYCrCbSubsampling422 = 2,
	WICJpegYCrCbSubsampling444 = 3,
	WICJpegYCrCbSubsampling440 = 4,
	WICJPEGYCRCBSUBSAMPLING_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WICPngFilterOption : int32
{
	WICPngFilterUnspecified = 0,
	WICPngFilterNone = 1,
	WICPngFilterSub = 2,
	WICPngFilterUp = 3,
	WICPngFilterAverage = 4,
	WICPngFilterPaeth = 5,
	WICPngFilterAdaptive = 6,
	WICPNGFILTEROPTION_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WICNamedWhitePoint : int32
{
	WICWhitePointDefault = 1,
	WICWhitePointDaylight = 2,
	WICWhitePointCloudy = 4,
	WICWhitePointShade = 8,
	WICWhitePointTungsten = 16,
	WICWhitePointFluorescent = 32,
	WICWhitePointFlash = 64,
	WICWhitePointUnderwater = 128,
	WICWhitePointCustom = 256,
	WICWhitePointAutoWhiteBalance = 512,
	WICWhitePointAsShot = 1,
	WICNAMEDWHITEPOINT_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WICRawCapabilities : int32
{
	WICRawCapabilityNotSupported = 0,
	WICRawCapabilityGetSupported = 1,
	WICRawCapabilityFullySupported = 2,
	WICRAWCAPABILITIES_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WICRawRotationCapabilities : int32
{
	WICRawRotationCapabilityNotSupported = 0,
	WICRawRotationCapabilityGetSupported = 1,
	WICRawRotationCapabilityNinetyDegreesSupported = 2,
	WICRawRotationCapabilityFullySupported = 3,
	WICRAWROTATIONCAPABILITIES_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WICRawParameterSet : int32
{
	WICAsShotParameterSet = 1,
	WICUserAdjustedParameterSet = 2,
	WICAutoAdjustedParameterSet = 3,
	WICRAWPARAMETERSET_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WICRawRenderMode : int32
{
	WICRawRenderModeDraft = 1,
	WICRawRenderModeNormal = 2,
	WICRawRenderModeBestQuality = 3,
	WICRAWRENDERMODE_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WICDdsDimension : int32
{
	WICDdsTexture1D = 0,
	WICDdsTexture2D = 1,
	WICDdsTexture3D = 2,
	WICDdsTextureCube = 3,
	WICDDSTEXTURE_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WICDdsAlphaMode : int32
{
	WICDdsAlphaModeUnknown = 0,
	WICDdsAlphaModeStraight = 1,
	WICDdsAlphaModePremultiplied = 2,
	WICDdsAlphaModeOpaque = 3,
	WICDdsAlphaModeCustom = 4,
	WICDDSALPHAMODE_FORCE_DWORD = 2147483647,
}


[AllowDuplicates]
public enum WICMetadataCreationOptions : int32
{
	WICMetadataCreationDefault = 0,
	WICMetadataCreationAllowUnknown = 0,
	WICMetadataCreationFailUnknown = 65536,
	WICMetadataCreationMask = -65536,
}


[AllowDuplicates]
public enum WICPersistOptions : int32
{
	WICPersistOptionDefault = 0,
	WICPersistOptionLittleEndian = 0,
	WICPersistOptionBigEndian = 1,
	WICPersistOptionStrictFormat = 2,
	WICPersistOptionNoCacheStream = 4,
	WICPersistOptionPreferUTF8 = 8,
	WICPersistOptionMask = 65535,
}

#endregion

#region Function Pointers
public function HRESULT PFNProgressNotification(void* pvData, uint32 uFrameNum, WICProgressOperation operation, double dblProgress);

#endregion

#region Structs
[CRepr]
public struct WICRect
{
	public int32 X;
	public int32 Y;
	public int32 Width;
	public int32 Height;
}

[CRepr]
public struct WICBitmapPattern
{
	public ULARGE_INTEGER Position;
	public uint32 Length;
	public uint8* Pattern;
	public uint8* Mask;
	public BOOL EndOfStream;
}

[CRepr]
public struct WICImageParameters
{
	public D2D1_PIXEL_FORMAT PixelFormat;
	public float DpiX;
	public float DpiY;
	public float Top;
	public float Left;
	public uint32 PixelWidth;
	public uint32 PixelHeight;
}

[CRepr]
public struct WICBitmapPlaneDescription
{
	public Guid Format;
	public uint32 Width;
	public uint32 Height;
}

[CRepr]
public struct WICBitmapPlane
{
	public Guid Format;
	public uint8* pbBuffer;
	public uint32 cbStride;
	public uint32 cbBufferSize;
}

[CRepr]
public struct WICJpegFrameHeader
{
	public uint32 Width;
	public uint32 Height;
	public WICJpegTransferMatrix TransferMatrix;
	public WICJpegScanType ScanType;
	public uint32 cComponents;
	public uint32 ComponentIdentifiers;
	public uint32 SampleFactors;
	public uint32 QuantizationTableIndices;
}

[CRepr]
public struct WICJpegScanHeader
{
	public uint32 cComponents;
	public uint32 RestartInterval;
	public uint32 ComponentSelectors;
	public uint32 HuffmanTableIndices;
	public uint8 StartSpectralSelection;
	public uint8 EndSpectralSelection;
	public uint8 SuccessiveApproximationHigh;
	public uint8 SuccessiveApproximationLow;
}

[CRepr]
public struct WICRawCapabilitiesInfo
{
	public uint32 cbSize;
	public uint32 CodecMajorVersion;
	public uint32 CodecMinorVersion;
	public WICRawCapabilities ExposureCompensationSupport;
	public WICRawCapabilities ContrastSupport;
	public WICRawCapabilities RGBWhitePointSupport;
	public WICRawCapabilities NamedWhitePointSupport;
	public uint32 NamedWhitePointSupportMask;
	public WICRawCapabilities KelvinWhitePointSupport;
	public WICRawCapabilities GammaSupport;
	public WICRawCapabilities TintSupport;
	public WICRawCapabilities SaturationSupport;
	public WICRawCapabilities SharpnessSupport;
	public WICRawCapabilities NoiseReductionSupport;
	public WICRawCapabilities DestinationColorProfileSupport;
	public WICRawCapabilities ToneCurveSupport;
	public WICRawRotationCapabilities RotationSupport;
	public WICRawCapabilities RenderModeSupport;
}

[CRepr]
public struct WICRawToneCurvePoint
{
	public double Input;
	public double Output;
}

[CRepr]
public struct WICRawToneCurve
{
	public uint32 cPoints;
	public WICRawToneCurvePoint* aPoints mut => &aPoints_impl;
	private WICRawToneCurvePoint[ANYSIZE_ARRAY] aPoints_impl;
}

[CRepr]
public struct WICDdsParameters
{
	public uint32 Width;
	public uint32 Height;
	public uint32 Depth;
	public uint32 MipLevels;
	public uint32 ArraySize;
	public DXGI_FORMAT DxgiFormat;
	public WICDdsDimension Dimension;
	public WICDdsAlphaMode AlphaMode;
}

[CRepr]
public struct WICDdsFormatInfo
{
	public DXGI_FORMAT DxgiFormat;
	public uint32 BytesPerBlock;
	public uint32 BlockWidth;
	public uint32 BlockHeight;
}

[CRepr]
public struct WICMetadataPattern
{
	public ULARGE_INTEGER Position;
	public uint32 Length;
	public uint8* Pattern;
	public uint8* Mask;
	public ULARGE_INTEGER DataOffset;
}

[CRepr]
public struct WICMetadataHeader
{
	public ULARGE_INTEGER Position;
	public uint32 Length;
	public uint8* Header;
	public ULARGE_INTEGER DataOffset;
}

#endregion

#region COM Types
[CRepr]struct IWICPalette : IUnknown
{
	public new const Guid IID = .(0x00000040, 0xa8f2, 0x4877, 0xba, 0x0a, 0xfd, 0x2b, 0x66, 0x45, 0xfb, 0x94);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WICBitmapPaletteType ePaletteType, BOOL fAddTransparentColor) InitializePredefined;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pColors, uint32 cCount) InitializeCustom;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICBitmapSource* pISurface, uint32 cCount, BOOL fAddTransparentColor) InitializeFromBitmap;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICPalette* pIPalette) InitializeFromPalette;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WICBitmapPaletteType* pePaletteType) COM_GetType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcCount) GetColorCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cCount, uint32* pColors, uint32* pcActualColors) GetColors;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfIsBlackWhite) IsBlackWhite;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfIsGrayscale) IsGrayscale;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfHasAlpha) HasAlpha;
	}


	public HRESULT InitializePredefined(WICBitmapPaletteType ePaletteType, BOOL fAddTransparentColor) mut => VT.[Friend]InitializePredefined(&this, ePaletteType, fAddTransparentColor);

	public HRESULT InitializeCustom(uint32* pColors, uint32 cCount) mut => VT.[Friend]InitializeCustom(&this, pColors, cCount);

	public HRESULT InitializeFromBitmap(IWICBitmapSource* pISurface, uint32 cCount, BOOL fAddTransparentColor) mut => VT.[Friend]InitializeFromBitmap(&this, pISurface, cCount, fAddTransparentColor);

	public HRESULT InitializeFromPalette(IWICPalette* pIPalette) mut => VT.[Friend]InitializeFromPalette(&this, pIPalette);

	public HRESULT GetType(WICBitmapPaletteType* pePaletteType) mut => VT.[Friend]COM_GetType(&this, pePaletteType);

	public HRESULT GetColorCount(uint32* pcCount) mut => VT.[Friend]GetColorCount(&this, pcCount);

	public HRESULT GetColors(uint32 cCount, uint32* pColors, uint32* pcActualColors) mut => VT.[Friend]GetColors(&this, cCount, pColors, pcActualColors);

	public HRESULT IsBlackWhite(BOOL* pfIsBlackWhite) mut => VT.[Friend]IsBlackWhite(&this, pfIsBlackWhite);

	public HRESULT IsGrayscale(BOOL* pfIsGrayscale) mut => VT.[Friend]IsGrayscale(&this, pfIsGrayscale);

	public HRESULT HasAlpha(BOOL* pfHasAlpha) mut => VT.[Friend]HasAlpha(&this, pfHasAlpha);
}

[CRepr]struct IWICBitmapSource : IUnknown
{
	public new const Guid IID = .(0x00000120, 0xa8f2, 0x4877, 0xba, 0x0a, 0xfd, 0x2b, 0x66, 0x45, 0xfb, 0x94);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* puiWidth, uint32* puiHeight) GetSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pPixelFormat) GetPixelFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pDpiX, double* pDpiY) GetResolution;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICPalette* pIPalette) CopyPalette;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WICRect* prc, uint32 cbStride, uint32 cbBufferSize, uint8* pbBuffer) CopyPixels;
	}


	public HRESULT GetSize(uint32* puiWidth, uint32* puiHeight) mut => VT.[Friend]GetSize(&this, puiWidth, puiHeight);

	public HRESULT GetPixelFormat(Guid* pPixelFormat) mut => VT.[Friend]GetPixelFormat(&this, pPixelFormat);

	public HRESULT GetResolution(double* pDpiX, double* pDpiY) mut => VT.[Friend]GetResolution(&this, pDpiX, pDpiY);

	public HRESULT CopyPalette(IWICPalette* pIPalette) mut => VT.[Friend]CopyPalette(&this, pIPalette);

	public HRESULT CopyPixels(WICRect* prc, uint32 cbStride, uint32 cbBufferSize, uint8* pbBuffer) mut => VT.[Friend]CopyPixels(&this, prc, cbStride, cbBufferSize, pbBuffer);
}

[CRepr]struct IWICFormatConverter : IWICBitmapSource
{
	public new const Guid IID = .(0x00000301, 0xa8f2, 0x4877, 0xba, 0x0a, 0xfd, 0x2b, 0x66, 0x45, 0xfb, 0x94);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWICBitmapSource.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICBitmapSource* pISource, Guid* dstFormat, WICBitmapDitherType dither, IWICPalette* pIPalette, double alphaThresholdPercent, WICBitmapPaletteType paletteTranslate) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* srcPixelFormat, Guid* dstPixelFormat, BOOL* pfCanConvert) CanConvert;
	}


	public HRESULT Initialize(IWICBitmapSource* pISource, Guid* dstFormat, WICBitmapDitherType dither, IWICPalette* pIPalette, double alphaThresholdPercent, WICBitmapPaletteType paletteTranslate) mut => VT.[Friend]Initialize(&this, pISource, dstFormat, dither, pIPalette, alphaThresholdPercent, paletteTranslate);

	public HRESULT CanConvert(Guid* srcPixelFormat, Guid* dstPixelFormat, BOOL* pfCanConvert) mut => VT.[Friend]CanConvert(&this, srcPixelFormat, dstPixelFormat, pfCanConvert);
}

[CRepr]struct IWICPlanarFormatConverter : IWICBitmapSource
{
	public new const Guid IID = .(0xbebee9cb, 0x83b0, 0x4dcc, 0x81, 0x32, 0xb0, 0xaa, 0xa5, 0x5e, 0xac, 0x96);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWICBitmapSource.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICBitmapSource** ppPlanes, uint32 cPlanes, Guid* dstFormat, WICBitmapDitherType dither, IWICPalette* pIPalette, double alphaThresholdPercent, WICBitmapPaletteType paletteTranslate) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pSrcPixelFormats, uint32 cSrcPlanes, Guid* dstPixelFormat, BOOL* pfCanConvert) CanConvert;
	}


	public HRESULT Initialize(IWICBitmapSource** ppPlanes, uint32 cPlanes, Guid* dstFormat, WICBitmapDitherType dither, IWICPalette* pIPalette, double alphaThresholdPercent, WICBitmapPaletteType paletteTranslate) mut => VT.[Friend]Initialize(&this, ppPlanes, cPlanes, dstFormat, dither, pIPalette, alphaThresholdPercent, paletteTranslate);

	public HRESULT CanConvert(Guid* pSrcPixelFormats, uint32 cSrcPlanes, Guid* dstPixelFormat, BOOL* pfCanConvert) mut => VT.[Friend]CanConvert(&this, pSrcPixelFormats, cSrcPlanes, dstPixelFormat, pfCanConvert);
}

[CRepr]struct IWICBitmapScaler : IWICBitmapSource
{
	public new const Guid IID = .(0x00000302, 0xa8f2, 0x4877, 0xba, 0x0a, 0xfd, 0x2b, 0x66, 0x45, 0xfb, 0x94);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWICBitmapSource.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICBitmapSource* pISource, uint32 uiWidth, uint32 uiHeight, WICBitmapInterpolationMode mode) Initialize;
	}


	public HRESULT Initialize(IWICBitmapSource* pISource, uint32 uiWidth, uint32 uiHeight, WICBitmapInterpolationMode mode) mut => VT.[Friend]Initialize(&this, pISource, uiWidth, uiHeight, mode);
}

[CRepr]struct IWICBitmapClipper : IWICBitmapSource
{
	public new const Guid IID = .(0xe4fbcf03, 0x223d, 0x4e81, 0x93, 0x33, 0xd6, 0x35, 0x55, 0x6d, 0xd1, 0xb5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWICBitmapSource.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICBitmapSource* pISource, WICRect* prc) Initialize;
	}


	public HRESULT Initialize(IWICBitmapSource* pISource, WICRect* prc) mut => VT.[Friend]Initialize(&this, pISource, prc);
}

[CRepr]struct IWICBitmapFlipRotator : IWICBitmapSource
{
	public new const Guid IID = .(0x5009834f, 0x2d6a, 0x41ce, 0x9e, 0x1b, 0x17, 0xc5, 0xaf, 0xf7, 0xa7, 0x82);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWICBitmapSource.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICBitmapSource* pISource, WICBitmapTransformOptions options) Initialize;
	}


	public HRESULT Initialize(IWICBitmapSource* pISource, WICBitmapTransformOptions options) mut => VT.[Friend]Initialize(&this, pISource, options);
}

[CRepr]struct IWICBitmapLock : IUnknown
{
	public new const Guid IID = .(0x00000123, 0xa8f2, 0x4877, 0xba, 0x0a, 0xfd, 0x2b, 0x66, 0x45, 0xfb, 0x94);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* puiWidth, uint32* puiHeight) GetSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcbStride) GetStride;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcbBufferSize, uint8** ppbData) GetDataPointer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pPixelFormat) GetPixelFormat;
	}


	public HRESULT GetSize(uint32* puiWidth, uint32* puiHeight) mut => VT.[Friend]GetSize(&this, puiWidth, puiHeight);

	public HRESULT GetStride(uint32* pcbStride) mut => VT.[Friend]GetStride(&this, pcbStride);

	public HRESULT GetDataPointer(uint32* pcbBufferSize, uint8** ppbData) mut => VT.[Friend]GetDataPointer(&this, pcbBufferSize, ppbData);

	public HRESULT GetPixelFormat(Guid* pPixelFormat) mut => VT.[Friend]GetPixelFormat(&this, pPixelFormat);
}

[CRepr]struct IWICBitmap : IWICBitmapSource
{
	public new const Guid IID = .(0x00000121, 0xa8f2, 0x4877, 0xba, 0x0a, 0xfd, 0x2b, 0x66, 0x45, 0xfb, 0x94);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWICBitmapSource.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WICRect* prcLock, uint32 flags, IWICBitmapLock** ppILock) Lock;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICPalette* pIPalette) SetPalette;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double dpiX, double dpiY) SetResolution;
	}


	public HRESULT Lock(WICRect* prcLock, uint32 flags, IWICBitmapLock** ppILock) mut => VT.[Friend]Lock(&this, prcLock, flags, ppILock);

	public HRESULT SetPalette(IWICPalette* pIPalette) mut => VT.[Friend]SetPalette(&this, pIPalette);

	public HRESULT SetResolution(double dpiX, double dpiY) mut => VT.[Friend]SetResolution(&this, dpiX, dpiY);
}

[CRepr]struct IWICColorContext : IUnknown
{
	public new const Guid IID = .(0x3c613a02, 0x34b2, 0x44ea, 0x9a, 0x7c, 0x45, 0xae, 0xa9, 0xc6, 0xfd, 0x6d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR wzFilename) InitializeFromFilename;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbBuffer, uint32 cbBufferSize) InitializeFromMemory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 value) InitializeFromExifColorSpace;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WICColorContextType* pType) COM_GetType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cbBuffer, uint8* pbBuffer, uint32* pcbActual) GetProfileBytes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pValue) GetExifColorSpace;
	}


	public HRESULT InitializeFromFilename(PWSTR wzFilename) mut => VT.[Friend]InitializeFromFilename(&this, wzFilename);

	public HRESULT InitializeFromMemory(uint8* pbBuffer, uint32 cbBufferSize) mut => VT.[Friend]InitializeFromMemory(&this, pbBuffer, cbBufferSize);

	public HRESULT InitializeFromExifColorSpace(uint32 value) mut => VT.[Friend]InitializeFromExifColorSpace(&this, value);

	public HRESULT GetType(WICColorContextType* pType) mut => VT.[Friend]COM_GetType(&this, pType);

	public HRESULT GetProfileBytes(uint32 cbBuffer, uint8* pbBuffer, uint32* pcbActual) mut => VT.[Friend]GetProfileBytes(&this, cbBuffer, pbBuffer, pcbActual);

	public HRESULT GetExifColorSpace(uint32* pValue) mut => VT.[Friend]GetExifColorSpace(&this, pValue);
}

[CRepr]struct IWICColorTransform : IWICBitmapSource
{
	public new const Guid IID = .(0xb66f034f, 0xd0e2, 0x40ab, 0xb4, 0x36, 0x6d, 0xe3, 0x9e, 0x32, 0x1a, 0x94);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWICBitmapSource.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICBitmapSource* pIBitmapSource, IWICColorContext* pIContextSource, IWICColorContext* pIContextDest, Guid* pixelFmtDest) Initialize;
	}


	public HRESULT Initialize(IWICBitmapSource* pIBitmapSource, IWICColorContext* pIContextSource, IWICColorContext* pIContextDest, Guid* pixelFmtDest) mut => VT.[Friend]Initialize(&this, pIBitmapSource, pIContextSource, pIContextDest, pixelFmtDest);
}

[CRepr]struct IWICFastMetadataEncoder : IUnknown
{
	public new const Guid IID = .(0xb84e2c09, 0x78c9, 0x4ac4, 0x8b, 0xd3, 0x52, 0x4a, 0xe1, 0x66, 0x3a, 0x2f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Commit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICMetadataQueryWriter** ppIMetadataQueryWriter) GetMetadataQueryWriter;
	}


	public HRESULT Commit() mut => VT.[Friend]Commit(&this);

	public HRESULT GetMetadataQueryWriter(IWICMetadataQueryWriter** ppIMetadataQueryWriter) mut => VT.[Friend]GetMetadataQueryWriter(&this, ppIMetadataQueryWriter);
}

[CRepr]struct IWICStream : IStream
{
	public new const Guid IID = .(0x135ff860, 0x22b7, 0x4ddf, 0xb0, 0xf6, 0x21, 0x8f, 0x4f, 0x29, 0x9a, 0x43);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IStream.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* pIStream) InitializeFromIStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR wzFileName, uint32 dwDesiredAccess) InitializeFromFilename;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pbBuffer, uint32 cbBufferSize) InitializeFromMemory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* pIStream, ULARGE_INTEGER ulOffset, ULARGE_INTEGER ulMaxSize) InitializeFromIStreamRegion;
	}


	public HRESULT InitializeFromIStream(IStream* pIStream) mut => VT.[Friend]InitializeFromIStream(&this, pIStream);

	public HRESULT InitializeFromFilename(PWSTR wzFileName, uint32 dwDesiredAccess) mut => VT.[Friend]InitializeFromFilename(&this, wzFileName, dwDesiredAccess);

	public HRESULT InitializeFromMemory(uint8* pbBuffer, uint32 cbBufferSize) mut => VT.[Friend]InitializeFromMemory(&this, pbBuffer, cbBufferSize);

	public HRESULT InitializeFromIStreamRegion(IStream* pIStream, ULARGE_INTEGER ulOffset, ULARGE_INTEGER ulMaxSize) mut => VT.[Friend]InitializeFromIStreamRegion(&this, pIStream, ulOffset, ulMaxSize);
}

[CRepr]struct IWICEnumMetadataItem : IUnknown
{
	public new const Guid IID = .(0xdc2bb46d, 0x3f07, 0x481e, 0x86, 0x25, 0x22, 0x0c, 0x4a, 0xed, 0xbb, 0x33);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, PROPVARIANT* rgeltSchema, PROPVARIANT* rgeltId, PROPVARIANT* rgeltValue, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICEnumMetadataItem** ppIEnumMetadataItem) Clone;
	}


	public HRESULT Next(uint32 celt, PROPVARIANT* rgeltSchema, PROPVARIANT* rgeltId, PROPVARIANT* rgeltValue, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgeltSchema, rgeltId, rgeltValue, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IWICEnumMetadataItem** ppIEnumMetadataItem) mut => VT.[Friend]Clone(&this, ppIEnumMetadataItem);
}

[CRepr]struct IWICMetadataQueryReader : IUnknown
{
	public new const Guid IID = .(0x30989668, 0xe1c9, 0x4597, 0xb3, 0x95, 0x45, 0x8e, 0xed, 0xb8, 0x08, 0xdf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pguidContainerFormat) GetContainerFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cchMaxLength, char16* wzNamespace, uint32* pcchActualLength) GetLocation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR wzName, PROPVARIANT* pvarValue) GetMetadataByName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumString** ppIEnumString) GetEnumerator;
	}


	public HRESULT GetContainerFormat(Guid* pguidContainerFormat) mut => VT.[Friend]GetContainerFormat(&this, pguidContainerFormat);

	public HRESULT GetLocation(uint32 cchMaxLength, char16* wzNamespace, uint32* pcchActualLength) mut => VT.[Friend]GetLocation(&this, cchMaxLength, wzNamespace, pcchActualLength);

	public HRESULT GetMetadataByName(PWSTR wzName, PROPVARIANT* pvarValue) mut => VT.[Friend]GetMetadataByName(&this, wzName, pvarValue);

	public HRESULT GetEnumerator(IEnumString** ppIEnumString) mut => VT.[Friend]GetEnumerator(&this, ppIEnumString);
}

[CRepr]struct IWICMetadataQueryWriter : IWICMetadataQueryReader
{
	public new const Guid IID = .(0xa721791a, 0x0def, 0x4d06, 0xbd, 0x91, 0x21, 0x18, 0xbf, 0x1d, 0xb1, 0x0b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWICMetadataQueryReader.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR wzName, PROPVARIANT* pvarValue) SetMetadataByName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR wzName) RemoveMetadataByName;
	}


	public HRESULT SetMetadataByName(PWSTR wzName, PROPVARIANT* pvarValue) mut => VT.[Friend]SetMetadataByName(&this, wzName, pvarValue);

	public HRESULT RemoveMetadataByName(PWSTR wzName) mut => VT.[Friend]RemoveMetadataByName(&this, wzName);
}

[CRepr]struct IWICBitmapEncoder : IUnknown
{
	public new const Guid IID = .(0x00000103, 0xa8f2, 0x4877, 0xba, 0x0a, 0xfd, 0x2b, 0x66, 0x45, 0xfb, 0x94);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* pIStream, WICBitmapEncoderCacheOption cacheOption) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pguidContainerFormat) GetContainerFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICBitmapEncoderInfo** ppIEncoderInfo) GetEncoderInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cCount, IWICColorContext** ppIColorContext) SetColorContexts;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICPalette* pIPalette) SetPalette;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICBitmapSource* pIThumbnail) SetThumbnail;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICBitmapSource* pIPreview) SetPreview;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICBitmapFrameEncode** ppIFrameEncode, IPropertyBag2** ppIEncoderOptions) CreateNewFrame;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Commit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICMetadataQueryWriter** ppIMetadataQueryWriter) GetMetadataQueryWriter;
	}


	public HRESULT Initialize(IStream* pIStream, WICBitmapEncoderCacheOption cacheOption) mut => VT.[Friend]Initialize(&this, pIStream, cacheOption);

	public HRESULT GetContainerFormat(Guid* pguidContainerFormat) mut => VT.[Friend]GetContainerFormat(&this, pguidContainerFormat);

	public HRESULT GetEncoderInfo(IWICBitmapEncoderInfo** ppIEncoderInfo) mut => VT.[Friend]GetEncoderInfo(&this, ppIEncoderInfo);

	public HRESULT SetColorContexts(uint32 cCount, IWICColorContext** ppIColorContext) mut => VT.[Friend]SetColorContexts(&this, cCount, ppIColorContext);

	public HRESULT SetPalette(IWICPalette* pIPalette) mut => VT.[Friend]SetPalette(&this, pIPalette);

	public HRESULT SetThumbnail(IWICBitmapSource* pIThumbnail) mut => VT.[Friend]SetThumbnail(&this, pIThumbnail);

	public HRESULT SetPreview(IWICBitmapSource* pIPreview) mut => VT.[Friend]SetPreview(&this, pIPreview);

	public HRESULT CreateNewFrame(IWICBitmapFrameEncode** ppIFrameEncode, IPropertyBag2** ppIEncoderOptions) mut => VT.[Friend]CreateNewFrame(&this, ppIFrameEncode, ppIEncoderOptions);

	public HRESULT Commit() mut => VT.[Friend]Commit(&this);

	public HRESULT GetMetadataQueryWriter(IWICMetadataQueryWriter** ppIMetadataQueryWriter) mut => VT.[Friend]GetMetadataQueryWriter(&this, ppIMetadataQueryWriter);
}

[CRepr]struct IWICBitmapFrameEncode : IUnknown
{
	public new const Guid IID = .(0x00000105, 0xa8f2, 0x4877, 0xba, 0x0a, 0xfd, 0x2b, 0x66, 0x45, 0xfb, 0x94);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPropertyBag2* pIEncoderOptions) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uiWidth, uint32 uiHeight) SetSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double dpiX, double dpiY) SetResolution;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pPixelFormat) SetPixelFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cCount, IWICColorContext** ppIColorContext) SetColorContexts;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICPalette* pIPalette) SetPalette;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICBitmapSource* pIThumbnail) SetThumbnail;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 lineCount, uint32 cbStride, uint32 cbBufferSize, uint8* pbPixels) WritePixels;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICBitmapSource* pIBitmapSource, WICRect* prc) WriteSource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Commit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICMetadataQueryWriter** ppIMetadataQueryWriter) GetMetadataQueryWriter;
	}


	public HRESULT Initialize(IPropertyBag2* pIEncoderOptions) mut => VT.[Friend]Initialize(&this, pIEncoderOptions);

	public HRESULT SetSize(uint32 uiWidth, uint32 uiHeight) mut => VT.[Friend]SetSize(&this, uiWidth, uiHeight);

	public HRESULT SetResolution(double dpiX, double dpiY) mut => VT.[Friend]SetResolution(&this, dpiX, dpiY);

	public HRESULT SetPixelFormat(Guid* pPixelFormat) mut => VT.[Friend]SetPixelFormat(&this, pPixelFormat);

	public HRESULT SetColorContexts(uint32 cCount, IWICColorContext** ppIColorContext) mut => VT.[Friend]SetColorContexts(&this, cCount, ppIColorContext);

	public HRESULT SetPalette(IWICPalette* pIPalette) mut => VT.[Friend]SetPalette(&this, pIPalette);

	public HRESULT SetThumbnail(IWICBitmapSource* pIThumbnail) mut => VT.[Friend]SetThumbnail(&this, pIThumbnail);

	public HRESULT WritePixels(uint32 lineCount, uint32 cbStride, uint32 cbBufferSize, uint8* pbPixels) mut => VT.[Friend]WritePixels(&this, lineCount, cbStride, cbBufferSize, pbPixels);

	public HRESULT WriteSource(IWICBitmapSource* pIBitmapSource, WICRect* prc) mut => VT.[Friend]WriteSource(&this, pIBitmapSource, prc);

	public HRESULT Commit() mut => VT.[Friend]Commit(&this);

	public HRESULT GetMetadataQueryWriter(IWICMetadataQueryWriter** ppIMetadataQueryWriter) mut => VT.[Friend]GetMetadataQueryWriter(&this, ppIMetadataQueryWriter);
}

[CRepr]struct IWICPlanarBitmapFrameEncode : IUnknown
{
	public new const Guid IID = .(0xf928b7b8, 0x2221, 0x40c1, 0xb7, 0x2e, 0x7e, 0x82, 0xf1, 0x97, 0x4d, 0x1a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 lineCount, WICBitmapPlane* pPlanes, uint32 cPlanes) WritePixels;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICBitmapSource** ppPlanes, uint32 cPlanes, WICRect* prcSource) WriteSource;
	}


	public HRESULT WritePixels(uint32 lineCount, WICBitmapPlane* pPlanes, uint32 cPlanes) mut => VT.[Friend]WritePixels(&this, lineCount, pPlanes, cPlanes);

	public HRESULT WriteSource(IWICBitmapSource** ppPlanes, uint32 cPlanes, WICRect* prcSource) mut => VT.[Friend]WriteSource(&this, ppPlanes, cPlanes, prcSource);
}

[CRepr]struct IWICBitmapDecoder : IUnknown
{
	public new const Guid IID = .(0x9edde9e7, 0x8dee, 0x47ea, 0x99, 0xdf, 0xe6, 0xfa, 0xf2, 0xed, 0x44, 0xbf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* pIStream, uint32* pdwCapability) QueryCapability;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* pIStream, WICDecodeOptions cacheOptions) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pguidContainerFormat) GetContainerFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICBitmapDecoderInfo** ppIDecoderInfo) GetDecoderInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICPalette* pIPalette) CopyPalette;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICMetadataQueryReader** ppIMetadataQueryReader) GetMetadataQueryReader;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICBitmapSource** ppIBitmapSource) GetPreview;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cCount, IWICColorContext** ppIColorContexts, uint32* pcActualCount) GetColorContexts;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICBitmapSource** ppIThumbnail) GetThumbnail;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pCount) GetFrameCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, IWICBitmapFrameDecode** ppIBitmapFrame) GetFrame;
	}


	public HRESULT QueryCapability(IStream* pIStream, uint32* pdwCapability) mut => VT.[Friend]QueryCapability(&this, pIStream, pdwCapability);

	public HRESULT Initialize(IStream* pIStream, WICDecodeOptions cacheOptions) mut => VT.[Friend]Initialize(&this, pIStream, cacheOptions);

	public HRESULT GetContainerFormat(Guid* pguidContainerFormat) mut => VT.[Friend]GetContainerFormat(&this, pguidContainerFormat);

	public HRESULT GetDecoderInfo(IWICBitmapDecoderInfo** ppIDecoderInfo) mut => VT.[Friend]GetDecoderInfo(&this, ppIDecoderInfo);

	public HRESULT CopyPalette(IWICPalette* pIPalette) mut => VT.[Friend]CopyPalette(&this, pIPalette);

	public HRESULT GetMetadataQueryReader(IWICMetadataQueryReader** ppIMetadataQueryReader) mut => VT.[Friend]GetMetadataQueryReader(&this, ppIMetadataQueryReader);

	public HRESULT GetPreview(IWICBitmapSource** ppIBitmapSource) mut => VT.[Friend]GetPreview(&this, ppIBitmapSource);

	public HRESULT GetColorContexts(uint32 cCount, IWICColorContext** ppIColorContexts, uint32* pcActualCount) mut => VT.[Friend]GetColorContexts(&this, cCount, ppIColorContexts, pcActualCount);

	public HRESULT GetThumbnail(IWICBitmapSource** ppIThumbnail) mut => VT.[Friend]GetThumbnail(&this, ppIThumbnail);

	public HRESULT GetFrameCount(uint32* pCount) mut => VT.[Friend]GetFrameCount(&this, pCount);

	public HRESULT GetFrame(uint32 index, IWICBitmapFrameDecode** ppIBitmapFrame) mut => VT.[Friend]GetFrame(&this, index, ppIBitmapFrame);
}

[CRepr]struct IWICBitmapSourceTransform : IUnknown
{
	public new const Guid IID = .(0x3b16811b, 0x6a43, 0x4ec9, 0xb7, 0x13, 0x3d, 0x5a, 0x0c, 0x13, 0xb9, 0x40);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WICRect* prc, uint32 uiWidth, uint32 uiHeight, Guid* pguidDstFormat, WICBitmapTransformOptions dstTransform, uint32 nStride, uint32 cbBufferSize, uint8* pbBuffer) CopyPixels;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* puiWidth, uint32* puiHeight) GetClosestSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pguidDstFormat) GetClosestPixelFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WICBitmapTransformOptions dstTransform, BOOL* pfIsSupported) DoesSupportTransform;
	}


	public HRESULT CopyPixels(WICRect* prc, uint32 uiWidth, uint32 uiHeight, Guid* pguidDstFormat, WICBitmapTransformOptions dstTransform, uint32 nStride, uint32 cbBufferSize, uint8* pbBuffer) mut => VT.[Friend]CopyPixels(&this, prc, uiWidth, uiHeight, pguidDstFormat, dstTransform, nStride, cbBufferSize, pbBuffer);

	public HRESULT GetClosestSize(uint32* puiWidth, uint32* puiHeight) mut => VT.[Friend]GetClosestSize(&this, puiWidth, puiHeight);

	public HRESULT GetClosestPixelFormat(Guid* pguidDstFormat) mut => VT.[Friend]GetClosestPixelFormat(&this, pguidDstFormat);

	public HRESULT DoesSupportTransform(WICBitmapTransformOptions dstTransform, BOOL* pfIsSupported) mut => VT.[Friend]DoesSupportTransform(&this, dstTransform, pfIsSupported);
}

[CRepr]struct IWICPlanarBitmapSourceTransform : IUnknown
{
	public new const Guid IID = .(0x3aff9cce, 0xbe95, 0x4303, 0xb9, 0x27, 0xe7, 0xd1, 0x6f, 0xf4, 0xa6, 0x13);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* puiWidth, uint32* puiHeight, WICBitmapTransformOptions dstTransform, WICPlanarOptions dstPlanarOptions, Guid* pguidDstFormats, WICBitmapPlaneDescription* pPlaneDescriptions, uint32 cPlanes, BOOL* pfIsSupported) DoesSupportTransform;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WICRect* prcSource, uint32 uiWidth, uint32 uiHeight, WICBitmapTransformOptions dstTransform, WICPlanarOptions dstPlanarOptions, WICBitmapPlane* pDstPlanes, uint32 cPlanes) CopyPixels;
	}


	public HRESULT DoesSupportTransform(uint32* puiWidth, uint32* puiHeight, WICBitmapTransformOptions dstTransform, WICPlanarOptions dstPlanarOptions, Guid* pguidDstFormats, WICBitmapPlaneDescription* pPlaneDescriptions, uint32 cPlanes, BOOL* pfIsSupported) mut => VT.[Friend]DoesSupportTransform(&this, puiWidth, puiHeight, dstTransform, dstPlanarOptions, pguidDstFormats, pPlaneDescriptions, cPlanes, pfIsSupported);

	public HRESULT CopyPixels(WICRect* prcSource, uint32 uiWidth, uint32 uiHeight, WICBitmapTransformOptions dstTransform, WICPlanarOptions dstPlanarOptions, WICBitmapPlane* pDstPlanes, uint32 cPlanes) mut => VT.[Friend]CopyPixels(&this, prcSource, uiWidth, uiHeight, dstTransform, dstPlanarOptions, pDstPlanes, cPlanes);
}

[CRepr]struct IWICBitmapFrameDecode : IWICBitmapSource
{
	public new const Guid IID = .(0x3b16811b, 0x6a43, 0x4ec9, 0xa8, 0x13, 0x3d, 0x93, 0x0c, 0x13, 0xb9, 0x40);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWICBitmapSource.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICMetadataQueryReader** ppIMetadataQueryReader) GetMetadataQueryReader;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cCount, IWICColorContext** ppIColorContexts, uint32* pcActualCount) GetColorContexts;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICBitmapSource** ppIThumbnail) GetThumbnail;
	}


	public HRESULT GetMetadataQueryReader(IWICMetadataQueryReader** ppIMetadataQueryReader) mut => VT.[Friend]GetMetadataQueryReader(&this, ppIMetadataQueryReader);

	public HRESULT GetColorContexts(uint32 cCount, IWICColorContext** ppIColorContexts, uint32* pcActualCount) mut => VT.[Friend]GetColorContexts(&this, cCount, ppIColorContexts, pcActualCount);

	public HRESULT GetThumbnail(IWICBitmapSource** ppIThumbnail) mut => VT.[Friend]GetThumbnail(&this, ppIThumbnail);
}

[CRepr]struct IWICProgressiveLevelControl : IUnknown
{
	public new const Guid IID = .(0xdaac296f, 0x7aa5, 0x4dbf, 0x8d, 0x15, 0x22, 0x5c, 0x59, 0x76, 0xf8, 0x91);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcLevels) GetLevelCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pnLevel) GetCurrentLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 nLevel) SetCurrentLevel;
	}


	public HRESULT GetLevelCount(uint32* pcLevels) mut => VT.[Friend]GetLevelCount(&this, pcLevels);

	public HRESULT GetCurrentLevel(uint32* pnLevel) mut => VT.[Friend]GetCurrentLevel(&this, pnLevel);

	public HRESULT SetCurrentLevel(uint32 nLevel) mut => VT.[Friend]SetCurrentLevel(&this, nLevel);
}

[CRepr]struct IWICProgressCallback : IUnknown
{
	public new const Guid IID = .(0x4776f9cd, 0x9517, 0x45fa, 0xbf, 0x24, 0xe8, 0x9c, 0x5e, 0xc5, 0xc6, 0x0c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uFrameNum, WICProgressOperation operation, double dblProgress) Notify;
	}


	public HRESULT Notify(uint32 uFrameNum, WICProgressOperation operation, double dblProgress) mut => VT.[Friend]Notify(&this, uFrameNum, operation, dblProgress);
}

[CRepr]struct IWICBitmapCodecProgressNotification : IUnknown
{
	public new const Guid IID = .(0x64c1024e, 0xc3cf, 0x4462, 0x80, 0x78, 0x88, 0xc2, 0xb1, 0x1c, 0x46, 0xd9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PFNProgressNotification pfnProgressNotification, void* pvData, uint32 dwProgressFlags) RegisterProgressNotification;
	}


	public HRESULT RegisterProgressNotification(PFNProgressNotification pfnProgressNotification, void* pvData, uint32 dwProgressFlags) mut => VT.[Friend]RegisterProgressNotification(&this, pfnProgressNotification, pvData, dwProgressFlags);
}

[CRepr]struct IWICComponentInfo : IUnknown
{
	public new const Guid IID = .(0x23bc3f0a, 0x698b, 0x4357, 0x88, 0x6b, 0xf2, 0x4d, 0x50, 0x67, 0x13, 0x34);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WICComponentType* pType) GetComponentType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pclsid) GetCLSID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pStatus) GetSigningStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cchAuthor, char16* wzAuthor, uint32* pcchActual) GetAuthor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pguidVendor) GetVendorGUID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cchVersion, char16* wzVersion, uint32* pcchActual) GetVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cchSpecVersion, char16* wzSpecVersion, uint32* pcchActual) GetSpecVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cchFriendlyName, char16* wzFriendlyName, uint32* pcchActual) GetFriendlyName;
	}


	public HRESULT GetComponentType(WICComponentType* pType) mut => VT.[Friend]GetComponentType(&this, pType);

	public HRESULT GetCLSID(Guid* pclsid) mut => VT.[Friend]GetCLSID(&this, pclsid);

	public HRESULT GetSigningStatus(uint32* pStatus) mut => VT.[Friend]GetSigningStatus(&this, pStatus);

	public HRESULT GetAuthor(uint32 cchAuthor, char16* wzAuthor, uint32* pcchActual) mut => VT.[Friend]GetAuthor(&this, cchAuthor, wzAuthor, pcchActual);

	public HRESULT GetVendorGUID(Guid* pguidVendor) mut => VT.[Friend]GetVendorGUID(&this, pguidVendor);

	public HRESULT GetVersion(uint32 cchVersion, char16* wzVersion, uint32* pcchActual) mut => VT.[Friend]GetVersion(&this, cchVersion, wzVersion, pcchActual);

	public HRESULT GetSpecVersion(uint32 cchSpecVersion, char16* wzSpecVersion, uint32* pcchActual) mut => VT.[Friend]GetSpecVersion(&this, cchSpecVersion, wzSpecVersion, pcchActual);

	public HRESULT GetFriendlyName(uint32 cchFriendlyName, char16* wzFriendlyName, uint32* pcchActual) mut => VT.[Friend]GetFriendlyName(&this, cchFriendlyName, wzFriendlyName, pcchActual);
}

[CRepr]struct IWICFormatConverterInfo : IWICComponentInfo
{
	public new const Guid IID = .(0x9f34fb65, 0x13f4, 0x4f15, 0xbc, 0x57, 0x37, 0x26, 0xb5, 0xe5, 0x3d, 0x9f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWICComponentInfo.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cFormats, Guid* pPixelFormatGUIDs, uint32* pcActual) GetPixelFormats;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICFormatConverter** ppIConverter) CreateInstance;
	}


	public HRESULT GetPixelFormats(uint32 cFormats, Guid* pPixelFormatGUIDs, uint32* pcActual) mut => VT.[Friend]GetPixelFormats(&this, cFormats, pPixelFormatGUIDs, pcActual);

	public HRESULT CreateInstance(IWICFormatConverter** ppIConverter) mut => VT.[Friend]CreateInstance(&this, ppIConverter);
}

[CRepr]struct IWICBitmapCodecInfo : IWICComponentInfo
{
	public new const Guid IID = .(0xe87a44c4, 0xb76e, 0x4c47, 0x8b, 0x09, 0x29, 0x8e, 0xb1, 0x2a, 0x27, 0x14);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWICComponentInfo.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pguidContainerFormat) GetContainerFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cFormats, Guid* pguidPixelFormats, uint32* pcActual) GetPixelFormats;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cchColorManagementVersion, char16* wzColorManagementVersion, uint32* pcchActual) GetColorManagementVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cchDeviceManufacturer, char16* wzDeviceManufacturer, uint32* pcchActual) GetDeviceManufacturer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cchDeviceModels, char16* wzDeviceModels, uint32* pcchActual) GetDeviceModels;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cchMimeTypes, char16* wzMimeTypes, uint32* pcchActual) GetMimeTypes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cchFileExtensions, char16* wzFileExtensions, uint32* pcchActual) GetFileExtensions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfSupportAnimation) DoesSupportAnimation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfSupportChromakey) DoesSupportChromakey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfSupportLossless) DoesSupportLossless;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfSupportMultiframe) DoesSupportMultiframe;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR wzMimeType, BOOL* pfMatches) MatchesMimeType;
	}


	public HRESULT GetContainerFormat(Guid* pguidContainerFormat) mut => VT.[Friend]GetContainerFormat(&this, pguidContainerFormat);

	public HRESULT GetPixelFormats(uint32 cFormats, Guid* pguidPixelFormats, uint32* pcActual) mut => VT.[Friend]GetPixelFormats(&this, cFormats, pguidPixelFormats, pcActual);

	public HRESULT GetColorManagementVersion(uint32 cchColorManagementVersion, char16* wzColorManagementVersion, uint32* pcchActual) mut => VT.[Friend]GetColorManagementVersion(&this, cchColorManagementVersion, wzColorManagementVersion, pcchActual);

	public HRESULT GetDeviceManufacturer(uint32 cchDeviceManufacturer, char16* wzDeviceManufacturer, uint32* pcchActual) mut => VT.[Friend]GetDeviceManufacturer(&this, cchDeviceManufacturer, wzDeviceManufacturer, pcchActual);

	public HRESULT GetDeviceModels(uint32 cchDeviceModels, char16* wzDeviceModels, uint32* pcchActual) mut => VT.[Friend]GetDeviceModels(&this, cchDeviceModels, wzDeviceModels, pcchActual);

	public HRESULT GetMimeTypes(uint32 cchMimeTypes, char16* wzMimeTypes, uint32* pcchActual) mut => VT.[Friend]GetMimeTypes(&this, cchMimeTypes, wzMimeTypes, pcchActual);

	public HRESULT GetFileExtensions(uint32 cchFileExtensions, char16* wzFileExtensions, uint32* pcchActual) mut => VT.[Friend]GetFileExtensions(&this, cchFileExtensions, wzFileExtensions, pcchActual);

	public HRESULT DoesSupportAnimation(BOOL* pfSupportAnimation) mut => VT.[Friend]DoesSupportAnimation(&this, pfSupportAnimation);

	public HRESULT DoesSupportChromakey(BOOL* pfSupportChromakey) mut => VT.[Friend]DoesSupportChromakey(&this, pfSupportChromakey);

	public HRESULT DoesSupportLossless(BOOL* pfSupportLossless) mut => VT.[Friend]DoesSupportLossless(&this, pfSupportLossless);

	public HRESULT DoesSupportMultiframe(BOOL* pfSupportMultiframe) mut => VT.[Friend]DoesSupportMultiframe(&this, pfSupportMultiframe);

	public HRESULT MatchesMimeType(PWSTR wzMimeType, BOOL* pfMatches) mut => VT.[Friend]MatchesMimeType(&this, wzMimeType, pfMatches);
}

[CRepr]struct IWICBitmapEncoderInfo : IWICBitmapCodecInfo
{
	public new const Guid IID = .(0x94c9b4ee, 0xa09f, 0x4f92, 0x8a, 0x1e, 0x4a, 0x9b, 0xce, 0x7e, 0x76, 0xfb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWICBitmapCodecInfo.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICBitmapEncoder** ppIBitmapEncoder) CreateInstance;
	}


	public HRESULT CreateInstance(IWICBitmapEncoder** ppIBitmapEncoder) mut => VT.[Friend]CreateInstance(&this, ppIBitmapEncoder);
}

[CRepr]struct IWICBitmapDecoderInfo : IWICBitmapCodecInfo
{
	public new const Guid IID = .(0xd8cd007f, 0xd08f, 0x4191, 0x9b, 0xfc, 0x23, 0x6e, 0xa7, 0xf0, 0xe4, 0xb5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWICBitmapCodecInfo.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cbSizePatterns, WICBitmapPattern* pPatterns, uint32* pcPatterns, uint32* pcbPatternsActual) GetPatterns;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* pIStream, BOOL* pfMatches) MatchesPattern;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICBitmapDecoder** ppIBitmapDecoder) CreateInstance;
	}


	public HRESULT GetPatterns(uint32 cbSizePatterns, WICBitmapPattern* pPatterns, uint32* pcPatterns, uint32* pcbPatternsActual) mut => VT.[Friend]GetPatterns(&this, cbSizePatterns, pPatterns, pcPatterns, pcbPatternsActual);

	public HRESULT MatchesPattern(IStream* pIStream, BOOL* pfMatches) mut => VT.[Friend]MatchesPattern(&this, pIStream, pfMatches);

	public HRESULT CreateInstance(IWICBitmapDecoder** ppIBitmapDecoder) mut => VT.[Friend]CreateInstance(&this, ppIBitmapDecoder);
}

[CRepr]struct IWICPixelFormatInfo : IWICComponentInfo
{
	public new const Guid IID = .(0xe8eda601, 0x3d48, 0x431a, 0xab, 0x44, 0x69, 0x05, 0x9b, 0xe8, 0x8b, 0xbe);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWICComponentInfo.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pFormat) GetFormatGUID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICColorContext** ppIColorContext) GetColorContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* puiBitsPerPixel) GetBitsPerPixel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* puiChannelCount) GetChannelCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uiChannelIndex, uint32 cbMaskBuffer, uint8* pbMaskBuffer, uint32* pcbActual) GetChannelMask;
	}


	public HRESULT GetFormatGUID(Guid* pFormat) mut => VT.[Friend]GetFormatGUID(&this, pFormat);

	public HRESULT GetColorContext(IWICColorContext** ppIColorContext) mut => VT.[Friend]GetColorContext(&this, ppIColorContext);

	public HRESULT GetBitsPerPixel(uint32* puiBitsPerPixel) mut => VT.[Friend]GetBitsPerPixel(&this, puiBitsPerPixel);

	public HRESULT GetChannelCount(uint32* puiChannelCount) mut => VT.[Friend]GetChannelCount(&this, puiChannelCount);

	public HRESULT GetChannelMask(uint32 uiChannelIndex, uint32 cbMaskBuffer, uint8* pbMaskBuffer, uint32* pcbActual) mut => VT.[Friend]GetChannelMask(&this, uiChannelIndex, cbMaskBuffer, pbMaskBuffer, pcbActual);
}

[CRepr]struct IWICPixelFormatInfo2 : IWICPixelFormatInfo
{
	public new const Guid IID = .(0xa9db33a2, 0xaf5f, 0x43c7, 0xb6, 0x79, 0x74, 0xf5, 0x98, 0x4b, 0x5a, 0xa4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWICPixelFormatInfo.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfSupportsTransparency) SupportsTransparency;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WICPixelFormatNumericRepresentation* pNumericRepresentation) GetNumericRepresentation;
	}


	public HRESULT SupportsTransparency(BOOL* pfSupportsTransparency) mut => VT.[Friend]SupportsTransparency(&this, pfSupportsTransparency);

	public HRESULT GetNumericRepresentation(WICPixelFormatNumericRepresentation* pNumericRepresentation) mut => VT.[Friend]GetNumericRepresentation(&this, pNumericRepresentation);
}

[CRepr]struct IWICImagingFactory : IUnknown
{
	public new const Guid IID = .(0xec5ec8a9, 0xc395, 0x4314, 0x9c, 0x77, 0x54, 0xd7, 0xa9, 0x35, 0xff, 0x70);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR wzFilename, in Guid pguidVendor, uint32 dwDesiredAccess, WICDecodeOptions metadataOptions, IWICBitmapDecoder** ppIDecoder) CreateDecoderFromFilename;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* pIStream, in Guid pguidVendor, WICDecodeOptions metadataOptions, IWICBitmapDecoder** ppIDecoder) CreateDecoderFromStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint hFile, in Guid pguidVendor, WICDecodeOptions metadataOptions, IWICBitmapDecoder** ppIDecoder) CreateDecoderFromFileHandle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid clsidComponent, IWICComponentInfo** ppIInfo) CreateComponentInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid guidContainerFormat, in Guid pguidVendor, IWICBitmapDecoder** ppIDecoder) CreateDecoder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid guidContainerFormat, in Guid pguidVendor, IWICBitmapEncoder** ppIEncoder) CreateEncoder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICPalette** ppIPalette) CreatePalette;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICFormatConverter** ppIFormatConverter) CreateFormatConverter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICBitmapScaler** ppIBitmapScaler) CreateBitmapScaler;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICBitmapClipper** ppIBitmapClipper) CreateBitmapClipper;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICBitmapFlipRotator** ppIBitmapFlipRotator) CreateBitmapFlipRotator;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICStream** ppIWICStream) CreateStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICColorContext** ppIWICColorContext) CreateColorContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICColorTransform** ppIWICColorTransform) CreateColorTransformer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uiWidth, uint32 uiHeight, Guid* pixelFormat, WICBitmapCreateCacheOption option, IWICBitmap** ppIBitmap) CreateBitmap;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICBitmapSource* pIBitmapSource, WICBitmapCreateCacheOption option, IWICBitmap** ppIBitmap) CreateBitmapFromSource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICBitmapSource* pIBitmapSource, uint32 x, uint32 y, uint32 width, uint32 height, IWICBitmap** ppIBitmap) CreateBitmapFromSourceRect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uiWidth, uint32 uiHeight, Guid* pixelFormat, uint32 cbStride, uint32 cbBufferSize, uint8* pbBuffer, IWICBitmap** ppIBitmap) CreateBitmapFromMemory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HBITMAP hBitmap, HPALETTE hPalette, WICBitmapAlphaChannelOption options, IWICBitmap** ppIBitmap) CreateBitmapFromHBITMAP;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HICON hIcon, IWICBitmap** ppIBitmap) CreateBitmapFromHICON;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 componentTypes, uint32 options, IEnumUnknown** ppIEnumUnknown) CreateComponentEnumerator;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICBitmapDecoder* pIDecoder, IWICFastMetadataEncoder** ppIFastEncoder) CreateFastMetadataEncoderFromDecoder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICBitmapFrameDecode* pIFrameDecoder, IWICFastMetadataEncoder** ppIFastEncoder) CreateFastMetadataEncoderFromFrameDecode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid guidMetadataFormat, in Guid pguidVendor, IWICMetadataQueryWriter** ppIQueryWriter) CreateQueryWriter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICMetadataQueryReader* pIQueryReader, in Guid pguidVendor, IWICMetadataQueryWriter** ppIQueryWriter) CreateQueryWriterFromReader;
	}


	public HRESULT CreateDecoderFromFilename(PWSTR wzFilename, in Guid pguidVendor, uint32 dwDesiredAccess, WICDecodeOptions metadataOptions, IWICBitmapDecoder** ppIDecoder) mut => VT.[Friend]CreateDecoderFromFilename(&this, wzFilename, pguidVendor, dwDesiredAccess, metadataOptions, ppIDecoder);

	public HRESULT CreateDecoderFromStream(IStream* pIStream, in Guid pguidVendor, WICDecodeOptions metadataOptions, IWICBitmapDecoder** ppIDecoder) mut => VT.[Friend]CreateDecoderFromStream(&this, pIStream, pguidVendor, metadataOptions, ppIDecoder);

	public HRESULT CreateDecoderFromFileHandle(uint hFile, in Guid pguidVendor, WICDecodeOptions metadataOptions, IWICBitmapDecoder** ppIDecoder) mut => VT.[Friend]CreateDecoderFromFileHandle(&this, hFile, pguidVendor, metadataOptions, ppIDecoder);

	public HRESULT CreateComponentInfo(in Guid clsidComponent, IWICComponentInfo** ppIInfo) mut => VT.[Friend]CreateComponentInfo(&this, clsidComponent, ppIInfo);

	public HRESULT CreateDecoder(in Guid guidContainerFormat, in Guid pguidVendor, IWICBitmapDecoder** ppIDecoder) mut => VT.[Friend]CreateDecoder(&this, guidContainerFormat, pguidVendor, ppIDecoder);

	public HRESULT CreateEncoder(in Guid guidContainerFormat, in Guid pguidVendor, IWICBitmapEncoder** ppIEncoder) mut => VT.[Friend]CreateEncoder(&this, guidContainerFormat, pguidVendor, ppIEncoder);

	public HRESULT CreatePalette(IWICPalette** ppIPalette) mut => VT.[Friend]CreatePalette(&this, ppIPalette);

	public HRESULT CreateFormatConverter(IWICFormatConverter** ppIFormatConverter) mut => VT.[Friend]CreateFormatConverter(&this, ppIFormatConverter);

	public HRESULT CreateBitmapScaler(IWICBitmapScaler** ppIBitmapScaler) mut => VT.[Friend]CreateBitmapScaler(&this, ppIBitmapScaler);

	public HRESULT CreateBitmapClipper(IWICBitmapClipper** ppIBitmapClipper) mut => VT.[Friend]CreateBitmapClipper(&this, ppIBitmapClipper);

	public HRESULT CreateBitmapFlipRotator(IWICBitmapFlipRotator** ppIBitmapFlipRotator) mut => VT.[Friend]CreateBitmapFlipRotator(&this, ppIBitmapFlipRotator);

	public HRESULT CreateStream(IWICStream** ppIWICStream) mut => VT.[Friend]CreateStream(&this, ppIWICStream);

	public HRESULT CreateColorContext(IWICColorContext** ppIWICColorContext) mut => VT.[Friend]CreateColorContext(&this, ppIWICColorContext);

	public HRESULT CreateColorTransformer(IWICColorTransform** ppIWICColorTransform) mut => VT.[Friend]CreateColorTransformer(&this, ppIWICColorTransform);

	public HRESULT CreateBitmap(uint32 uiWidth, uint32 uiHeight, Guid* pixelFormat, WICBitmapCreateCacheOption option, IWICBitmap** ppIBitmap) mut => VT.[Friend]CreateBitmap(&this, uiWidth, uiHeight, pixelFormat, option, ppIBitmap);

	public HRESULT CreateBitmapFromSource(IWICBitmapSource* pIBitmapSource, WICBitmapCreateCacheOption option, IWICBitmap** ppIBitmap) mut => VT.[Friend]CreateBitmapFromSource(&this, pIBitmapSource, option, ppIBitmap);

	public HRESULT CreateBitmapFromSourceRect(IWICBitmapSource* pIBitmapSource, uint32 x, uint32 y, uint32 width, uint32 height, IWICBitmap** ppIBitmap) mut => VT.[Friend]CreateBitmapFromSourceRect(&this, pIBitmapSource, x, y, width, height, ppIBitmap);

	public HRESULT CreateBitmapFromMemory(uint32 uiWidth, uint32 uiHeight, Guid* pixelFormat, uint32 cbStride, uint32 cbBufferSize, uint8* pbBuffer, IWICBitmap** ppIBitmap) mut => VT.[Friend]CreateBitmapFromMemory(&this, uiWidth, uiHeight, pixelFormat, cbStride, cbBufferSize, pbBuffer, ppIBitmap);

	public HRESULT CreateBitmapFromHBITMAP(HBITMAP hBitmap, HPALETTE hPalette, WICBitmapAlphaChannelOption options, IWICBitmap** ppIBitmap) mut => VT.[Friend]CreateBitmapFromHBITMAP(&this, hBitmap, hPalette, options, ppIBitmap);

	public HRESULT CreateBitmapFromHICON(HICON hIcon, IWICBitmap** ppIBitmap) mut => VT.[Friend]CreateBitmapFromHICON(&this, hIcon, ppIBitmap);

	public HRESULT CreateComponentEnumerator(uint32 componentTypes, uint32 options, IEnumUnknown** ppIEnumUnknown) mut => VT.[Friend]CreateComponentEnumerator(&this, componentTypes, options, ppIEnumUnknown);

	public HRESULT CreateFastMetadataEncoderFromDecoder(IWICBitmapDecoder* pIDecoder, IWICFastMetadataEncoder** ppIFastEncoder) mut => VT.[Friend]CreateFastMetadataEncoderFromDecoder(&this, pIDecoder, ppIFastEncoder);

	public HRESULT CreateFastMetadataEncoderFromFrameDecode(IWICBitmapFrameDecode* pIFrameDecoder, IWICFastMetadataEncoder** ppIFastEncoder) mut => VT.[Friend]CreateFastMetadataEncoderFromFrameDecode(&this, pIFrameDecoder, ppIFastEncoder);

	public HRESULT CreateQueryWriter(in Guid guidMetadataFormat, in Guid pguidVendor, IWICMetadataQueryWriter** ppIQueryWriter) mut => VT.[Friend]CreateQueryWriter(&this, guidMetadataFormat, pguidVendor, ppIQueryWriter);

	public HRESULT CreateQueryWriterFromReader(IWICMetadataQueryReader* pIQueryReader, in Guid pguidVendor, IWICMetadataQueryWriter** ppIQueryWriter) mut => VT.[Friend]CreateQueryWriterFromReader(&this, pIQueryReader, pguidVendor, ppIQueryWriter);
}

[CRepr]struct IWICDevelopRawNotificationCallback : IUnknown
{
	public new const Guid IID = .(0x95c75a6e, 0x3e8c, 0x4ec2, 0x85, 0xa8, 0xae, 0xbc, 0xc5, 0x51, 0xe5, 0x9b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 NotificationMask) Notify;
	}


	public HRESULT Notify(uint32 NotificationMask) mut => VT.[Friend]Notify(&this, NotificationMask);
}

[CRepr]struct IWICDevelopRaw : IWICBitmapFrameDecode
{
	public new const Guid IID = .(0xfbec5e44, 0xf7be, 0x4b65, 0xb7, 0xf8, 0xc0, 0xc8, 0x1f, 0xef, 0x02, 0x6d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWICBitmapFrameDecode.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WICRawCapabilitiesInfo* pInfo) QueryRawCapabilitiesInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WICRawParameterSet ParameterSet) LoadParameterSet;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPropertyBag2** ppCurrentParameterSet) GetCurrentParameterSet;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double ev) SetExposureCompensation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pEV) GetExposureCompensation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 Red, uint32 Green, uint32 Blue) SetWhitePointRGB;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pRed, uint32* pGreen, uint32* pBlue) GetWhitePointRGB;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WICNamedWhitePoint WhitePoint) SetNamedWhitePoint;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WICNamedWhitePoint* pWhitePoint) GetNamedWhitePoint;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 WhitePointKelvin) SetWhitePointKelvin;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pWhitePointKelvin) GetWhitePointKelvin;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pMinKelvinTemp, uint32* pMaxKelvinTemp, uint32* pKelvinTempStepValue) GetKelvinRangeInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double Contrast) SetContrast;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pContrast) GetContrast;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double Gamma) SetGamma;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pGamma) GetGamma;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double Sharpness) SetSharpness;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pSharpness) GetSharpness;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double Saturation) SetSaturation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pSaturation) GetSaturation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double Tint) SetTint;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pTint) GetTint;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double NoiseReduction) SetNoiseReduction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pNoiseReduction) GetNoiseReduction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICColorContext* pColorContext) SetDestinationColorContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cbToneCurveSize, WICRawToneCurve* pToneCurve) SetToneCurve;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cbToneCurveBufferSize, WICRawToneCurve* pToneCurve, uint32* pcbActualToneCurveBufferSize) GetToneCurve;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double Rotation) SetRotation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pRotation) GetRotation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WICRawRenderMode RenderMode) SetRenderMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WICRawRenderMode* pRenderMode) GetRenderMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICDevelopRawNotificationCallback* pCallback) SetNotificationCallback;
	}


	public HRESULT QueryRawCapabilitiesInfo(WICRawCapabilitiesInfo* pInfo) mut => VT.[Friend]QueryRawCapabilitiesInfo(&this, pInfo);

	public HRESULT LoadParameterSet(WICRawParameterSet ParameterSet) mut => VT.[Friend]LoadParameterSet(&this, ParameterSet);

	public HRESULT GetCurrentParameterSet(IPropertyBag2** ppCurrentParameterSet) mut => VT.[Friend]GetCurrentParameterSet(&this, ppCurrentParameterSet);

	public HRESULT SetExposureCompensation(double ev) mut => VT.[Friend]SetExposureCompensation(&this, ev);

	public HRESULT GetExposureCompensation(double* pEV) mut => VT.[Friend]GetExposureCompensation(&this, pEV);

	public HRESULT SetWhitePointRGB(uint32 Red, uint32 Green, uint32 Blue) mut => VT.[Friend]SetWhitePointRGB(&this, Red, Green, Blue);

	public HRESULT GetWhitePointRGB(uint32* pRed, uint32* pGreen, uint32* pBlue) mut => VT.[Friend]GetWhitePointRGB(&this, pRed, pGreen, pBlue);

	public HRESULT SetNamedWhitePoint(WICNamedWhitePoint WhitePoint) mut => VT.[Friend]SetNamedWhitePoint(&this, WhitePoint);

	public HRESULT GetNamedWhitePoint(WICNamedWhitePoint* pWhitePoint) mut => VT.[Friend]GetNamedWhitePoint(&this, pWhitePoint);

	public HRESULT SetWhitePointKelvin(uint32 WhitePointKelvin) mut => VT.[Friend]SetWhitePointKelvin(&this, WhitePointKelvin);

	public HRESULT GetWhitePointKelvin(uint32* pWhitePointKelvin) mut => VT.[Friend]GetWhitePointKelvin(&this, pWhitePointKelvin);

	public HRESULT GetKelvinRangeInfo(uint32* pMinKelvinTemp, uint32* pMaxKelvinTemp, uint32* pKelvinTempStepValue) mut => VT.[Friend]GetKelvinRangeInfo(&this, pMinKelvinTemp, pMaxKelvinTemp, pKelvinTempStepValue);

	public HRESULT SetContrast(double Contrast) mut => VT.[Friend]SetContrast(&this, Contrast);

	public HRESULT GetContrast(double* pContrast) mut => VT.[Friend]GetContrast(&this, pContrast);

	public HRESULT SetGamma(double Gamma) mut => VT.[Friend]SetGamma(&this, Gamma);

	public HRESULT GetGamma(double* pGamma) mut => VT.[Friend]GetGamma(&this, pGamma);

	public HRESULT SetSharpness(double Sharpness) mut => VT.[Friend]SetSharpness(&this, Sharpness);

	public HRESULT GetSharpness(double* pSharpness) mut => VT.[Friend]GetSharpness(&this, pSharpness);

	public HRESULT SetSaturation(double Saturation) mut => VT.[Friend]SetSaturation(&this, Saturation);

	public HRESULT GetSaturation(double* pSaturation) mut => VT.[Friend]GetSaturation(&this, pSaturation);

	public HRESULT SetTint(double Tint) mut => VT.[Friend]SetTint(&this, Tint);

	public HRESULT GetTint(double* pTint) mut => VT.[Friend]GetTint(&this, pTint);

	public HRESULT SetNoiseReduction(double NoiseReduction) mut => VT.[Friend]SetNoiseReduction(&this, NoiseReduction);

	public HRESULT GetNoiseReduction(double* pNoiseReduction) mut => VT.[Friend]GetNoiseReduction(&this, pNoiseReduction);

	public HRESULT SetDestinationColorContext(IWICColorContext* pColorContext) mut => VT.[Friend]SetDestinationColorContext(&this, pColorContext);

	public HRESULT SetToneCurve(uint32 cbToneCurveSize, WICRawToneCurve* pToneCurve) mut => VT.[Friend]SetToneCurve(&this, cbToneCurveSize, pToneCurve);

	public HRESULT GetToneCurve(uint32 cbToneCurveBufferSize, WICRawToneCurve* pToneCurve, uint32* pcbActualToneCurveBufferSize) mut => VT.[Friend]GetToneCurve(&this, cbToneCurveBufferSize, pToneCurve, pcbActualToneCurveBufferSize);

	public HRESULT SetRotation(double Rotation) mut => VT.[Friend]SetRotation(&this, Rotation);

	public HRESULT GetRotation(double* pRotation) mut => VT.[Friend]GetRotation(&this, pRotation);

	public HRESULT SetRenderMode(WICRawRenderMode RenderMode) mut => VT.[Friend]SetRenderMode(&this, RenderMode);

	public HRESULT GetRenderMode(WICRawRenderMode* pRenderMode) mut => VT.[Friend]GetRenderMode(&this, pRenderMode);

	public HRESULT SetNotificationCallback(IWICDevelopRawNotificationCallback* pCallback) mut => VT.[Friend]SetNotificationCallback(&this, pCallback);
}

[CRepr]struct IWICDdsDecoder : IUnknown
{
	public new const Guid IID = .(0x409cd537, 0x8532, 0x40cb, 0x97, 0x74, 0xe2, 0xfe, 0xb2, 0xdf, 0x4e, 0x9c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WICDdsParameters* pParameters) GetParameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 arrayIndex, uint32 mipLevel, uint32 sliceIndex, IWICBitmapFrameDecode** ppIBitmapFrame) GetFrame;
	}


	public HRESULT GetParameters(WICDdsParameters* pParameters) mut => VT.[Friend]GetParameters(&this, pParameters);

	public HRESULT GetFrame(uint32 arrayIndex, uint32 mipLevel, uint32 sliceIndex, IWICBitmapFrameDecode** ppIBitmapFrame) mut => VT.[Friend]GetFrame(&this, arrayIndex, mipLevel, sliceIndex, ppIBitmapFrame);
}

[CRepr]struct IWICDdsEncoder : IUnknown
{
	public new const Guid IID = .(0x5cacdb4c, 0x407e, 0x41b3, 0xb9, 0x36, 0xd0, 0xf0, 0x10, 0xcd, 0x67, 0x32);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WICDdsParameters* pParameters) SetParameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WICDdsParameters* pParameters) GetParameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICBitmapFrameEncode** ppIFrameEncode, uint32* pArrayIndex, uint32* pMipLevel, uint32* pSliceIndex) CreateNewFrame;
	}


	public HRESULT SetParameters(WICDdsParameters* pParameters) mut => VT.[Friend]SetParameters(&this, pParameters);

	public HRESULT GetParameters(WICDdsParameters* pParameters) mut => VT.[Friend]GetParameters(&this, pParameters);

	public HRESULT CreateNewFrame(IWICBitmapFrameEncode** ppIFrameEncode, uint32* pArrayIndex, uint32* pMipLevel, uint32* pSliceIndex) mut => VT.[Friend]CreateNewFrame(&this, ppIFrameEncode, pArrayIndex, pMipLevel, pSliceIndex);
}

[CRepr]struct IWICDdsFrameDecode : IUnknown
{
	public new const Guid IID = .(0x3d4c0c61, 0x18a4, 0x41e4, 0xbd, 0x80, 0x48, 0x1a, 0x4f, 0xc9, 0xf4, 0x64);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pWidthInBlocks, uint32* pHeightInBlocks) GetSizeInBlocks;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WICDdsFormatInfo* pFormatInfo) GetFormatInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WICRect* prcBoundsInBlocks, uint32 cbStride, uint32 cbBufferSize, uint8* pbBuffer) CopyBlocks;
	}


	public HRESULT GetSizeInBlocks(uint32* pWidthInBlocks, uint32* pHeightInBlocks) mut => VT.[Friend]GetSizeInBlocks(&this, pWidthInBlocks, pHeightInBlocks);

	public HRESULT GetFormatInfo(WICDdsFormatInfo* pFormatInfo) mut => VT.[Friend]GetFormatInfo(&this, pFormatInfo);

	public HRESULT CopyBlocks(WICRect* prcBoundsInBlocks, uint32 cbStride, uint32 cbBufferSize, uint8* pbBuffer) mut => VT.[Friend]CopyBlocks(&this, prcBoundsInBlocks, cbStride, cbBufferSize, pbBuffer);
}

[CRepr]struct IWICJpegFrameDecode : IUnknown
{
	public new const Guid IID = .(0x8939f66e, 0xc46a, 0x4c21, 0xa9, 0xd1, 0x98, 0xb3, 0x27, 0xce, 0x16, 0x79);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfIndexingSupported) DoesSupportIndexing;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WICJpegIndexingOptions options, uint32 horizontalIntervalSize) SetIndexing;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ClearIndexing;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 scanIndex, uint32 tableIndex, DXGI_JPEG_AC_HUFFMAN_TABLE* pAcHuffmanTable) GetAcHuffmanTable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 scanIndex, uint32 tableIndex, DXGI_JPEG_DC_HUFFMAN_TABLE* pDcHuffmanTable) GetDcHuffmanTable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 scanIndex, uint32 tableIndex, DXGI_JPEG_QUANTIZATION_TABLE* pQuantizationTable) GetQuantizationTable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WICJpegFrameHeader* pFrameHeader) GetFrameHeader;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 scanIndex, WICJpegScanHeader* pScanHeader) GetScanHeader;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 scanIndex, uint32 scanOffset, uint32 cbScanData, uint8* pbScanData, uint32* pcbScanDataActual) CopyScan;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 streamOffset, uint32 cbStreamData, uint8* pbStreamData, uint32* pcbStreamDataActual) CopyMinimalStream;
	}


	public HRESULT DoesSupportIndexing(BOOL* pfIndexingSupported) mut => VT.[Friend]DoesSupportIndexing(&this, pfIndexingSupported);

	public HRESULT SetIndexing(WICJpegIndexingOptions options, uint32 horizontalIntervalSize) mut => VT.[Friend]SetIndexing(&this, options, horizontalIntervalSize);

	public HRESULT ClearIndexing() mut => VT.[Friend]ClearIndexing(&this);

	public HRESULT GetAcHuffmanTable(uint32 scanIndex, uint32 tableIndex, DXGI_JPEG_AC_HUFFMAN_TABLE* pAcHuffmanTable) mut => VT.[Friend]GetAcHuffmanTable(&this, scanIndex, tableIndex, pAcHuffmanTable);

	public HRESULT GetDcHuffmanTable(uint32 scanIndex, uint32 tableIndex, DXGI_JPEG_DC_HUFFMAN_TABLE* pDcHuffmanTable) mut => VT.[Friend]GetDcHuffmanTable(&this, scanIndex, tableIndex, pDcHuffmanTable);

	public HRESULT GetQuantizationTable(uint32 scanIndex, uint32 tableIndex, DXGI_JPEG_QUANTIZATION_TABLE* pQuantizationTable) mut => VT.[Friend]GetQuantizationTable(&this, scanIndex, tableIndex, pQuantizationTable);

	public HRESULT GetFrameHeader(WICJpegFrameHeader* pFrameHeader) mut => VT.[Friend]GetFrameHeader(&this, pFrameHeader);

	public HRESULT GetScanHeader(uint32 scanIndex, WICJpegScanHeader* pScanHeader) mut => VT.[Friend]GetScanHeader(&this, scanIndex, pScanHeader);

	public HRESULT CopyScan(uint32 scanIndex, uint32 scanOffset, uint32 cbScanData, uint8* pbScanData, uint32* pcbScanDataActual) mut => VT.[Friend]CopyScan(&this, scanIndex, scanOffset, cbScanData, pbScanData, pcbScanDataActual);

	public HRESULT CopyMinimalStream(uint32 streamOffset, uint32 cbStreamData, uint8* pbStreamData, uint32* pcbStreamDataActual) mut => VT.[Friend]CopyMinimalStream(&this, streamOffset, cbStreamData, pbStreamData, pcbStreamDataActual);
}

[CRepr]struct IWICJpegFrameEncode : IUnknown
{
	public new const Guid IID = .(0x2f0c601f, 0xd2c6, 0x468c, 0xab, 0xfa, 0x49, 0x49, 0x5d, 0x98, 0x3e, 0xd1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 scanIndex, uint32 tableIndex, DXGI_JPEG_AC_HUFFMAN_TABLE* pAcHuffmanTable) GetAcHuffmanTable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 scanIndex, uint32 tableIndex, DXGI_JPEG_DC_HUFFMAN_TABLE* pDcHuffmanTable) GetDcHuffmanTable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 scanIndex, uint32 tableIndex, DXGI_JPEG_QUANTIZATION_TABLE* pQuantizationTable) GetQuantizationTable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cbScanData, uint8* pbScanData) WriteScan;
	}


	public HRESULT GetAcHuffmanTable(uint32 scanIndex, uint32 tableIndex, DXGI_JPEG_AC_HUFFMAN_TABLE* pAcHuffmanTable) mut => VT.[Friend]GetAcHuffmanTable(&this, scanIndex, tableIndex, pAcHuffmanTable);

	public HRESULT GetDcHuffmanTable(uint32 scanIndex, uint32 tableIndex, DXGI_JPEG_DC_HUFFMAN_TABLE* pDcHuffmanTable) mut => VT.[Friend]GetDcHuffmanTable(&this, scanIndex, tableIndex, pDcHuffmanTable);

	public HRESULT GetQuantizationTable(uint32 scanIndex, uint32 tableIndex, DXGI_JPEG_QUANTIZATION_TABLE* pQuantizationTable) mut => VT.[Friend]GetQuantizationTable(&this, scanIndex, tableIndex, pQuantizationTable);

	public HRESULT WriteScan(uint32 cbScanData, uint8* pbScanData) mut => VT.[Friend]WriteScan(&this, cbScanData, pbScanData);
}

[CRepr]struct IWICMetadataBlockReader : IUnknown
{
	public new const Guid IID = .(0xfeaa2a8d, 0xb3f3, 0x43e4, 0xb2, 0x5c, 0xd1, 0xde, 0x99, 0x0a, 0x1a, 0xe1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pguidContainerFormat) GetContainerFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcCount) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 nIndex, IWICMetadataReader** ppIMetadataReader) GetReaderByIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumUnknown** ppIEnumMetadata) GetEnumerator;
	}


	public HRESULT GetContainerFormat(Guid* pguidContainerFormat) mut => VT.[Friend]GetContainerFormat(&this, pguidContainerFormat);

	public HRESULT GetCount(uint32* pcCount) mut => VT.[Friend]GetCount(&this, pcCount);

	public HRESULT GetReaderByIndex(uint32 nIndex, IWICMetadataReader** ppIMetadataReader) mut => VT.[Friend]GetReaderByIndex(&this, nIndex, ppIMetadataReader);

	public HRESULT GetEnumerator(IEnumUnknown** ppIEnumMetadata) mut => VT.[Friend]GetEnumerator(&this, ppIEnumMetadata);
}

[CRepr]struct IWICMetadataBlockWriter : IWICMetadataBlockReader
{
	public new const Guid IID = .(0x08fb9676, 0xb444, 0x41e8, 0x8d, 0xbe, 0x6a, 0x53, 0xa5, 0x42, 0xbf, 0xf1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWICMetadataBlockReader.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICMetadataBlockReader* pIMDBlockReader) InitializeFromBlockReader;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 nIndex, IWICMetadataWriter** ppIMetadataWriter) GetWriterByIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICMetadataWriter* pIMetadataWriter) AddWriter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 nIndex, IWICMetadataWriter* pIMetadataWriter) SetWriterByIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 nIndex) RemoveWriterByIndex;
	}


	public HRESULT InitializeFromBlockReader(IWICMetadataBlockReader* pIMDBlockReader) mut => VT.[Friend]InitializeFromBlockReader(&this, pIMDBlockReader);

	public HRESULT GetWriterByIndex(uint32 nIndex, IWICMetadataWriter** ppIMetadataWriter) mut => VT.[Friend]GetWriterByIndex(&this, nIndex, ppIMetadataWriter);

	public HRESULT AddWriter(IWICMetadataWriter* pIMetadataWriter) mut => VT.[Friend]AddWriter(&this, pIMetadataWriter);

	public HRESULT SetWriterByIndex(uint32 nIndex, IWICMetadataWriter* pIMetadataWriter) mut => VT.[Friend]SetWriterByIndex(&this, nIndex, pIMetadataWriter);

	public HRESULT RemoveWriterByIndex(uint32 nIndex) mut => VT.[Friend]RemoveWriterByIndex(&this, nIndex);
}

[CRepr]struct IWICMetadataReader : IUnknown
{
	public new const Guid IID = .(0x9204fe99, 0xd8fc, 0x4fd5, 0xa0, 0x01, 0x95, 0x36, 0xb0, 0x67, 0xa8, 0x99);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pguidMetadataFormat) GetMetadataFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICMetadataHandlerInfo** ppIHandler) GetMetadataHandlerInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcCount) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 nIndex, PROPVARIANT* pvarSchema, PROPVARIANT* pvarId, PROPVARIANT* pvarValue) GetValueByIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPVARIANT* pvarSchema, PROPVARIANT* pvarId, PROPVARIANT* pvarValue) GetValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICEnumMetadataItem** ppIEnumMetadata) GetEnumerator;
	}


	public HRESULT GetMetadataFormat(Guid* pguidMetadataFormat) mut => VT.[Friend]GetMetadataFormat(&this, pguidMetadataFormat);

	public HRESULT GetMetadataHandlerInfo(IWICMetadataHandlerInfo** ppIHandler) mut => VT.[Friend]GetMetadataHandlerInfo(&this, ppIHandler);

	public HRESULT GetCount(uint32* pcCount) mut => VT.[Friend]GetCount(&this, pcCount);

	public HRESULT GetValueByIndex(uint32 nIndex, PROPVARIANT* pvarSchema, PROPVARIANT* pvarId, PROPVARIANT* pvarValue) mut => VT.[Friend]GetValueByIndex(&this, nIndex, pvarSchema, pvarId, pvarValue);

	public HRESULT GetValue(PROPVARIANT* pvarSchema, PROPVARIANT* pvarId, PROPVARIANT* pvarValue) mut => VT.[Friend]GetValue(&this, pvarSchema, pvarId, pvarValue);

	public HRESULT GetEnumerator(IWICEnumMetadataItem** ppIEnumMetadata) mut => VT.[Friend]GetEnumerator(&this, ppIEnumMetadata);
}

[CRepr]struct IWICMetadataWriter : IWICMetadataReader
{
	public new const Guid IID = .(0xf7836e16, 0x3be0, 0x470b, 0x86, 0xbb, 0x16, 0x0d, 0x0a, 0xec, 0xd7, 0xde);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWICMetadataReader.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPVARIANT* pvarSchema, PROPVARIANT* pvarId, PROPVARIANT* pvarValue) SetValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 nIndex, PROPVARIANT* pvarSchema, PROPVARIANT* pvarId, PROPVARIANT* pvarValue) SetValueByIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPVARIANT* pvarSchema, PROPVARIANT* pvarId) RemoveValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 nIndex) RemoveValueByIndex;
	}


	public HRESULT SetValue(PROPVARIANT* pvarSchema, PROPVARIANT* pvarId, PROPVARIANT* pvarValue) mut => VT.[Friend]SetValue(&this, pvarSchema, pvarId, pvarValue);

	public HRESULT SetValueByIndex(uint32 nIndex, PROPVARIANT* pvarSchema, PROPVARIANT* pvarId, PROPVARIANT* pvarValue) mut => VT.[Friend]SetValueByIndex(&this, nIndex, pvarSchema, pvarId, pvarValue);

	public HRESULT RemoveValue(PROPVARIANT* pvarSchema, PROPVARIANT* pvarId) mut => VT.[Friend]RemoveValue(&this, pvarSchema, pvarId);

	public HRESULT RemoveValueByIndex(uint32 nIndex) mut => VT.[Friend]RemoveValueByIndex(&this, nIndex);
}

[CRepr]struct IWICStreamProvider : IUnknown
{
	public new const Guid IID = .(0x449494bc, 0xb468, 0x4927, 0x96, 0xd7, 0xba, 0x90, 0xd3, 0x1a, 0xb5, 0x05);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream** ppIStream) GetStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwPersistOptions) GetPersistOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pguidPreferredVendor) GetPreferredVendorGUID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RefreshStream;
	}


	public HRESULT GetStream(IStream** ppIStream) mut => VT.[Friend]GetStream(&this, ppIStream);

	public HRESULT GetPersistOptions(uint32* pdwPersistOptions) mut => VT.[Friend]GetPersistOptions(&this, pdwPersistOptions);

	public HRESULT GetPreferredVendorGUID(Guid* pguidPreferredVendor) mut => VT.[Friend]GetPreferredVendorGUID(&this, pguidPreferredVendor);

	public HRESULT RefreshStream() mut => VT.[Friend]RefreshStream(&this);
}

[CRepr]struct IWICPersistStream : IPersistStream
{
	public new const Guid IID = .(0x00675040, 0x6908, 0x45f8, 0x86, 0xa3, 0x49, 0xc7, 0xdf, 0xd6, 0xd9, 0xad);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPersistStream.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* pIStream, in Guid pguidPreferredVendor, uint32 dwPersistOptions) LoadEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* pIStream, uint32 dwPersistOptions, BOOL fClearDirty) SaveEx;
	}


	public HRESULT LoadEx(IStream* pIStream, in Guid pguidPreferredVendor, uint32 dwPersistOptions) mut => VT.[Friend]LoadEx(&this, pIStream, pguidPreferredVendor, dwPersistOptions);

	public HRESULT SaveEx(IStream* pIStream, uint32 dwPersistOptions, BOOL fClearDirty) mut => VT.[Friend]SaveEx(&this, pIStream, dwPersistOptions, fClearDirty);
}

[CRepr]struct IWICMetadataHandlerInfo : IWICComponentInfo
{
	public new const Guid IID = .(0xaba958bf, 0xc672, 0x44d1, 0x8d, 0x61, 0xce, 0x6d, 0xf2, 0xe6, 0x82, 0xc2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWICComponentInfo.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pguidMetadataFormat) GetMetadataFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cContainerFormats, Guid* pguidContainerFormats, uint32* pcchActual) GetContainerFormats;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cchDeviceManufacturer, char16* wzDeviceManufacturer, uint32* pcchActual) GetDeviceManufacturer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cchDeviceModels, char16* wzDeviceModels, uint32* pcchActual) GetDeviceModels;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfRequiresFullStream) DoesRequireFullStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfSupportsPadding) DoesSupportPadding;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfFixedSize) DoesRequireFixedSize;
	}


	public HRESULT GetMetadataFormat(Guid* pguidMetadataFormat) mut => VT.[Friend]GetMetadataFormat(&this, pguidMetadataFormat);

	public HRESULT GetContainerFormats(uint32 cContainerFormats, Guid* pguidContainerFormats, uint32* pcchActual) mut => VT.[Friend]GetContainerFormats(&this, cContainerFormats, pguidContainerFormats, pcchActual);

	public HRESULT GetDeviceManufacturer(uint32 cchDeviceManufacturer, char16* wzDeviceManufacturer, uint32* pcchActual) mut => VT.[Friend]GetDeviceManufacturer(&this, cchDeviceManufacturer, wzDeviceManufacturer, pcchActual);

	public HRESULT GetDeviceModels(uint32 cchDeviceModels, char16* wzDeviceModels, uint32* pcchActual) mut => VT.[Friend]GetDeviceModels(&this, cchDeviceModels, wzDeviceModels, pcchActual);

	public HRESULT DoesRequireFullStream(BOOL* pfRequiresFullStream) mut => VT.[Friend]DoesRequireFullStream(&this, pfRequiresFullStream);

	public HRESULT DoesSupportPadding(BOOL* pfSupportsPadding) mut => VT.[Friend]DoesSupportPadding(&this, pfSupportsPadding);

	public HRESULT DoesRequireFixedSize(BOOL* pfFixedSize) mut => VT.[Friend]DoesRequireFixedSize(&this, pfFixedSize);
}

[CRepr]struct IWICMetadataReaderInfo : IWICMetadataHandlerInfo
{
	public new const Guid IID = .(0xeebf1f5b, 0x07c1, 0x4447, 0xa3, 0xab, 0x22, 0xac, 0xaf, 0x78, 0xa8, 0x04);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWICMetadataHandlerInfo.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid guidContainerFormat, uint32 cbSize, WICMetadataPattern* pPattern, uint32* pcCount, uint32* pcbActual) GetPatterns;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid guidContainerFormat, IStream* pIStream, BOOL* pfMatches) MatchesPattern;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICMetadataReader** ppIReader) CreateInstance;
	}


	public HRESULT GetPatterns(in Guid guidContainerFormat, uint32 cbSize, WICMetadataPattern* pPattern, uint32* pcCount, uint32* pcbActual) mut => VT.[Friend]GetPatterns(&this, guidContainerFormat, cbSize, pPattern, pcCount, pcbActual);

	public HRESULT MatchesPattern(in Guid guidContainerFormat, IStream* pIStream, BOOL* pfMatches) mut => VT.[Friend]MatchesPattern(&this, guidContainerFormat, pIStream, pfMatches);

	public HRESULT CreateInstance(IWICMetadataReader** ppIReader) mut => VT.[Friend]CreateInstance(&this, ppIReader);
}

[CRepr]struct IWICMetadataWriterInfo : IWICMetadataHandlerInfo
{
	public new const Guid IID = .(0xb22e3fba, 0x3925, 0x4323, 0xb5, 0xc1, 0x9e, 0xbf, 0xc4, 0x30, 0xf2, 0x36);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWICMetadataHandlerInfo.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid guidContainerFormat, uint32 cbSize, WICMetadataHeader* pHeader, uint32* pcbActual) GetHeader;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICMetadataWriter** ppIWriter) CreateInstance;
	}


	public HRESULT GetHeader(in Guid guidContainerFormat, uint32 cbSize, WICMetadataHeader* pHeader, uint32* pcbActual) mut => VT.[Friend]GetHeader(&this, guidContainerFormat, cbSize, pHeader, pcbActual);

	public HRESULT CreateInstance(IWICMetadataWriter** ppIWriter) mut => VT.[Friend]CreateInstance(&this, ppIWriter);
}

[CRepr]struct IWICComponentFactory : IWICImagingFactory
{
	public new const Guid IID = .(0x412d0c3a, 0x9650, 0x44fa, 0xaf, 0x5b, 0xdd, 0x2a, 0x06, 0xc8, 0xe8, 0xfb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWICImagingFactory.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid guidMetadataFormat, in Guid pguidVendor, uint32 dwOptions, IStream* pIStream, IWICMetadataReader** ppIReader) CreateMetadataReader;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid guidContainerFormat, in Guid pguidVendor, uint32 dwOptions, IStream* pIStream, IWICMetadataReader** ppIReader) CreateMetadataReaderFromContainer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid guidMetadataFormat, in Guid pguidVendor, uint32 dwMetadataOptions, IWICMetadataWriter** ppIWriter) CreateMetadataWriter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICMetadataReader* pIReader, in Guid pguidVendor, IWICMetadataWriter** ppIWriter) CreateMetadataWriterFromReader;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICMetadataBlockReader* pIBlockReader, IWICMetadataQueryReader** ppIQueryReader) CreateQueryReaderFromBlockReader;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWICMetadataBlockWriter* pIBlockWriter, IWICMetadataQueryWriter** ppIQueryWriter) CreateQueryWriterFromBlockWriter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPBAG2* ppropOptions, uint32 cCount, IPropertyBag2** ppIPropertyBag) CreateEncoderPropertyBag;
	}


	public HRESULT CreateMetadataReader(in Guid guidMetadataFormat, in Guid pguidVendor, uint32 dwOptions, IStream* pIStream, IWICMetadataReader** ppIReader) mut => VT.[Friend]CreateMetadataReader(&this, guidMetadataFormat, pguidVendor, dwOptions, pIStream, ppIReader);

	public HRESULT CreateMetadataReaderFromContainer(in Guid guidContainerFormat, in Guid pguidVendor, uint32 dwOptions, IStream* pIStream, IWICMetadataReader** ppIReader) mut => VT.[Friend]CreateMetadataReaderFromContainer(&this, guidContainerFormat, pguidVendor, dwOptions, pIStream, ppIReader);

	public HRESULT CreateMetadataWriter(in Guid guidMetadataFormat, in Guid pguidVendor, uint32 dwMetadataOptions, IWICMetadataWriter** ppIWriter) mut => VT.[Friend]CreateMetadataWriter(&this, guidMetadataFormat, pguidVendor, dwMetadataOptions, ppIWriter);

	public HRESULT CreateMetadataWriterFromReader(IWICMetadataReader* pIReader, in Guid pguidVendor, IWICMetadataWriter** ppIWriter) mut => VT.[Friend]CreateMetadataWriterFromReader(&this, pIReader, pguidVendor, ppIWriter);

	public HRESULT CreateQueryReaderFromBlockReader(IWICMetadataBlockReader* pIBlockReader, IWICMetadataQueryReader** ppIQueryReader) mut => VT.[Friend]CreateQueryReaderFromBlockReader(&this, pIBlockReader, ppIQueryReader);

	public HRESULT CreateQueryWriterFromBlockWriter(IWICMetadataBlockWriter* pIBlockWriter, IWICMetadataQueryWriter** ppIQueryWriter) mut => VT.[Friend]CreateQueryWriterFromBlockWriter(&this, pIBlockWriter, ppIQueryWriter);

	public HRESULT CreateEncoderPropertyBag(PROPBAG2* ppropOptions, uint32 cCount, IPropertyBag2** ppIPropertyBag) mut => VT.[Friend]CreateEncoderPropertyBag(&this, ppropOptions, cCount, ppIPropertyBag);
}

#endregion

#region Functions
public static
{
	[Import("WindowsCodecs.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WICConvertBitmapSource(Guid* dstFormat, IWICBitmapSource* pISrc, IWICBitmapSource** ppIDst);

	[Import("WindowsCodecs.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WICCreateBitmapFromSection(uint32 width, uint32 height, Guid* pixelFormat, HANDLE hSection, uint32 stride, uint32 offset, IWICBitmap** ppIBitmap);

	[Import("WindowsCodecs.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WICCreateBitmapFromSectionEx(uint32 width, uint32 height, Guid* pixelFormat, HANDLE hSection, uint32 stride, uint32 offset, WICSectionAccessLevel desiredAccessLevel, IWICBitmap** ppIBitmap);

	[Import("WindowsCodecs.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WICMapGuidToShortName(in Guid guid, uint32 cchName, char16* wzName, uint32* pcchActual);

	[Import("WindowsCodecs.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WICMapShortNameToGuid(PWSTR wzName, Guid* pguid);

	[Import("WindowsCodecs.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WICMapSchemaToName(in Guid guidMetadataFormat, PWSTR pwzSchema, uint32 cchName, char16* wzName, uint32* pcchActual);

	[Import("WindowsCodecs.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WICMatchMetadataContent(in Guid guidContainerFormat, Guid* pguidVendor, IStream* pIStream, Guid* pguidMetadataFormat);

	[Import("WindowsCodecs.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WICSerializeMetadataContent(in Guid guidContainerFormat, IWICMetadataWriter* pIWriter, uint32 dwPersistOptions, IStream* pIStream);

	[Import("WindowsCodecs.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WICGetMetadataContentSize(in Guid guidContainerFormat, IWICMetadataWriter* pIWriter, ULARGE_INTEGER* pcbSize);

}
#endregion
