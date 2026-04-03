using Win32.Foundation;
using Win32.System.Com;
using Win32.System.Com.StructuredStorage;
using Win32.UI.WindowsAndMessaging;
using Win32.Graphics.Gdi;
using System;

namespace Win32.Devices.ImageAcquisition;

#region Constants
public static
{
	public const uint32 WIA_DIP_DEV_ID = 2;
	public const String WIA_DIP_DEV_ID_STR = "Unique Device ID";
	public const uint32 WIA_DIP_VEND_DESC = 3;
	public const String WIA_DIP_VEND_DESC_STR = "Manufacturer";
	public const uint32 WIA_DIP_DEV_DESC = 4;
	public const String WIA_DIP_DEV_DESC_STR = "Description";
	public const uint32 WIA_DIP_DEV_TYPE = 5;
	public const String WIA_DIP_DEV_TYPE_STR = "Type";
	public const uint32 WIA_DIP_PORT_NAME = 6;
	public const String WIA_DIP_PORT_NAME_STR = "Port";
	public const uint32 WIA_DIP_DEV_NAME = 7;
	public const String WIA_DIP_DEV_NAME_STR = "Name";
	public const uint32 WIA_DIP_SERVER_NAME = 8;
	public const String WIA_DIP_SERVER_NAME_STR = "Server";
	public const uint32 WIA_DIP_REMOTE_DEV_ID = 9;
	public const String WIA_DIP_REMOTE_DEV_ID_STR = "Remote Device ID";
	public const uint32 WIA_DIP_UI_CLSID = 10;
	public const String WIA_DIP_UI_CLSID_STR = "UI Class ID";
	public const uint32 WIA_DIP_HW_CONFIG = 11;
	public const String WIA_DIP_HW_CONFIG_STR = "Hardware Configuration";
	public const uint32 WIA_DIP_BAUDRATE = 12;
	public const String WIA_DIP_BAUDRATE_STR = "BaudRate";
	public const uint32 WIA_DIP_STI_GEN_CAPABILITIES = 13;
	public const String WIA_DIP_STI_GEN_CAPABILITIES_STR = "STI Generic Capabilities";
	public const uint32 WIA_DIP_WIA_VERSION = 14;
	public const String WIA_DIP_WIA_VERSION_STR = "WIA Version";
	public const uint32 WIA_DIP_DRIVER_VERSION = 15;
	public const String WIA_DIP_DRIVER_VERSION_STR = "Driver Version";
	public const uint32 WIA_DIP_PNP_ID = 16;
	public const String WIA_DIP_PNP_ID_STR = "PnP ID String";
	public const uint32 WIA_DIP_STI_DRIVER_VERSION = 17;
	public const String WIA_DIP_STI_DRIVER_VERSION_STR = "STI Driver Version";
	public const uint32 WIA_DPA_FIRMWARE_VERSION = 1026;
	public const String WIA_DPA_FIRMWARE_VERSION_STR = "Firmware Version";
	public const uint32 WIA_DPA_CONNECT_STATUS = 1027;
	public const String WIA_DPA_CONNECT_STATUS_STR = "Connect Status";
	public const uint32 WIA_DPA_DEVICE_TIME = 1028;
	public const String WIA_DPA_DEVICE_TIME_STR = "Device Time";
	public const uint32 WIA_DPC_PICTURES_TAKEN = 2050;
	public const String WIA_DPC_PICTURES_TAKEN_STR = "Pictures Taken";
	public const uint32 WIA_DPC_PICTURES_REMAINING = 2051;
	public const String WIA_DPC_PICTURES_REMAINING_STR = "Pictures Remaining";
	public const uint32 WIA_DPC_EXPOSURE_MODE = 2052;
	public const String WIA_DPC_EXPOSURE_MODE_STR = "Exposure Mode";
	public const uint32 WIA_DPC_EXPOSURE_COMP = 2053;
	public const String WIA_DPC_EXPOSURE_COMP_STR = "Exposure Compensation";
	public const uint32 WIA_DPC_EXPOSURE_TIME = 2054;
	public const String WIA_DPC_EXPOSURE_TIME_STR = "Exposure Time";
	public const uint32 WIA_DPC_FNUMBER = 2055;
	public const String WIA_DPC_FNUMBER_STR = "F Number";
	public const uint32 WIA_DPC_FLASH_MODE = 2056;
	public const String WIA_DPC_FLASH_MODE_STR = "Flash Mode";
	public const uint32 WIA_DPC_FOCUS_MODE = 2057;
	public const String WIA_DPC_FOCUS_MODE_STR = "Focus Mode";
	public const uint32 WIA_DPC_FOCUS_MANUAL_DIST = 2058;
	public const String WIA_DPC_FOCUS_MANUAL_DIST_STR = "Focus Manual Dist";
	public const uint32 WIA_DPC_ZOOM_POSITION = 2059;
	public const String WIA_DPC_ZOOM_POSITION_STR = "Zoom Position";
	public const uint32 WIA_DPC_PAN_POSITION = 2060;
	public const String WIA_DPC_PAN_POSITION_STR = "Pan Position";
	public const uint32 WIA_DPC_TILT_POSITION = 2061;
	public const String WIA_DPC_TILT_POSITION_STR = "Tilt Position";
	public const uint32 WIA_DPC_TIMER_MODE = 2062;
	public const String WIA_DPC_TIMER_MODE_STR = "Timer Mode";
	public const uint32 WIA_DPC_TIMER_VALUE = 2063;
	public const String WIA_DPC_TIMER_VALUE_STR = "Timer Value";
	public const uint32 WIA_DPC_POWER_MODE = 2064;
	public const String WIA_DPC_POWER_MODE_STR = "Power Mode";
	public const uint32 WIA_DPC_BATTERY_STATUS = 2065;
	public const String WIA_DPC_BATTERY_STATUS_STR = "Battery Status";
	public const uint32 WIA_DPC_THUMB_WIDTH = 2066;
	public const String WIA_DPC_THUMB_WIDTH_STR = "Thumbnail Width";
	public const uint32 WIA_DPC_THUMB_HEIGHT = 2067;
	public const String WIA_DPC_THUMB_HEIGHT_STR = "Thumbnail Height";
	public const uint32 WIA_DPC_PICT_WIDTH = 2068;
	public const String WIA_DPC_PICT_WIDTH_STR = "Picture Width";
	public const uint32 WIA_DPC_PICT_HEIGHT = 2069;
	public const String WIA_DPC_PICT_HEIGHT_STR = "Picture Height";
	public const uint32 WIA_DPC_DIMENSION = 2070;
	public const String WIA_DPC_DIMENSION_STR = "Dimension";
	public const uint32 WIA_DPC_COMPRESSION_SETTING = 2071;
	public const String WIA_DPC_COMPRESSION_SETTING_STR = "Compression Setting";
	public const uint32 WIA_DPC_FOCUS_METERING = 2072;
	public const String WIA_DPC_FOCUS_METERING_STR = "Focus Metering Mode";
	public const uint32 WIA_DPC_TIMELAPSE_INTERVAL = 2073;
	public const String WIA_DPC_TIMELAPSE_INTERVAL_STR = "Timelapse Interval";
	public const uint32 WIA_DPC_TIMELAPSE_NUMBER = 2074;
	public const String WIA_DPC_TIMELAPSE_NUMBER_STR = "Timelapse Number";
	public const uint32 WIA_DPC_BURST_INTERVAL = 2075;
	public const String WIA_DPC_BURST_INTERVAL_STR = "Burst Interval";
	public const uint32 WIA_DPC_BURST_NUMBER = 2076;
	public const String WIA_DPC_BURST_NUMBER_STR = "Burst Number";
	public const uint32 WIA_DPC_EFFECT_MODE = 2077;
	public const String WIA_DPC_EFFECT_MODE_STR = "Effect Mode";
	public const uint32 WIA_DPC_DIGITAL_ZOOM = 2078;
	public const String WIA_DPC_DIGITAL_ZOOM_STR = "Digital Zoom";
	public const uint32 WIA_DPC_SHARPNESS = 2079;
	public const String WIA_DPC_SHARPNESS_STR = "Sharpness";
	public const uint32 WIA_DPC_CONTRAST = 2080;
	public const String WIA_DPC_CONTRAST_STR = "Contrast";
	public const uint32 WIA_DPC_CAPTURE_MODE = 2081;
	public const String WIA_DPC_CAPTURE_MODE_STR = "Capture Mode";
	public const uint32 WIA_DPC_CAPTURE_DELAY = 2082;
	public const String WIA_DPC_CAPTURE_DELAY_STR = "Capture Delay";
	public const uint32 WIA_DPC_EXPOSURE_INDEX = 2083;
	public const String WIA_DPC_EXPOSURE_INDEX_STR = "Exposure Index";
	public const uint32 WIA_DPC_EXPOSURE_METERING_MODE = 2084;
	public const String WIA_DPC_EXPOSURE_METERING_MODE_STR = "Exposure Metering Mode";
	public const uint32 WIA_DPC_FOCUS_METERING_MODE = 2085;
	public const String WIA_DPC_FOCUS_METERING_MODE_STR = "Focus Metering Mode";
	public const uint32 WIA_DPC_FOCUS_DISTANCE = 2086;
	public const String WIA_DPC_FOCUS_DISTANCE_STR = "Focus Distance";
	public const uint32 WIA_DPC_FOCAL_LENGTH = 2087;
	public const String WIA_DPC_FOCAL_LENGTH_STR = "Focus Length";
	public const uint32 WIA_DPC_RGB_GAIN = 2088;
	public const String WIA_DPC_RGB_GAIN_STR = "RGB Gain";
	public const uint32 WIA_DPC_WHITE_BALANCE = 2089;
	public const String WIA_DPC_WHITE_BALANCE_STR = "White Balance";
	public const uint32 WIA_DPC_UPLOAD_URL = 2090;
	public const String WIA_DPC_UPLOAD_URL_STR = "Upload URL";
	public const uint32 WIA_DPC_ARTIST = 2091;
	public const String WIA_DPC_ARTIST_STR = "Artist";
	public const uint32 WIA_DPC_COPYRIGHT_INFO = 2092;
	public const String WIA_DPC_COPYRIGHT_INFO_STR = "Copyright Info";
	public const uint32 WIA_DPS_HORIZONTAL_BED_SIZE = 3074;
	public const String WIA_DPS_HORIZONTAL_BED_SIZE_STR = "Horizontal Bed Size";
	public const uint32 WIA_DPS_VERTICAL_BED_SIZE = 3075;
	public const String WIA_DPS_VERTICAL_BED_SIZE_STR = "Vertical Bed Size";
	public const uint32 WIA_DPS_HORIZONTAL_SHEET_FEED_SIZE = 3076;
	public const String WIA_DPS_HORIZONTAL_SHEET_FEED_SIZE_STR = "Horizontal Sheet Feed Size";
	public const uint32 WIA_DPS_VERTICAL_SHEET_FEED_SIZE = 3077;
	public const String WIA_DPS_VERTICAL_SHEET_FEED_SIZE_STR = "Vertical Sheet Feed Size";
	public const uint32 WIA_DPS_SHEET_FEEDER_REGISTRATION = 3078;
	public const String WIA_DPS_SHEET_FEEDER_REGISTRATION_STR = "Sheet Feeder Registration";
	public const uint32 WIA_DPS_HORIZONTAL_BED_REGISTRATION = 3079;
	public const String WIA_DPS_HORIZONTAL_BED_REGISTRATION_STR = "Horizontal Bed Registration";
	public const uint32 WIA_DPS_VERTICAL_BED_REGISTRATION = 3080;
	public const String WIA_DPS_VERTICAL_BED_REGISTRATION_STR = "Vertical Bed Registration";
	public const uint32 WIA_DPS_PLATEN_COLOR = 3081;
	public const String WIA_DPS_PLATEN_COLOR_STR = "Platen Color";
	public const uint32 WIA_DPS_PAD_COLOR = 3082;
	public const String WIA_DPS_PAD_COLOR_STR = "Pad Color";
	public const uint32 WIA_DPS_FILTER_SELECT = 3083;
	public const String WIA_DPS_FILTER_SELECT_STR = "Filter Select";
	public const uint32 WIA_DPS_DITHER_SELECT = 3084;
	public const String WIA_DPS_DITHER_SELECT_STR = "Dither Select";
	public const uint32 WIA_DPS_DITHER_PATTERN_DATA = 3085;
	public const String WIA_DPS_DITHER_PATTERN_DATA_STR = "Dither Pattern Data";
	public const uint32 WIA_DPS_DOCUMENT_HANDLING_CAPABILITIES = 3086;
	public const String WIA_DPS_DOCUMENT_HANDLING_CAPABILITIES_STR = "Document Handling Capabilities";
	public const uint32 WIA_DPS_DOCUMENT_HANDLING_STATUS = 3087;
	public const String WIA_DPS_DOCUMENT_HANDLING_STATUS_STR = "Document Handling Status";
	public const uint32 WIA_DPS_DOCUMENT_HANDLING_SELECT = 3088;
	public const String WIA_DPS_DOCUMENT_HANDLING_SELECT_STR = "Document Handling Select";
	public const uint32 WIA_DPS_DOCUMENT_HANDLING_CAPACITY = 3089;
	public const String WIA_DPS_DOCUMENT_HANDLING_CAPACITY_STR = "Document Handling Capacity";
	public const uint32 WIA_DPS_OPTICAL_XRES = 3090;
	public const String WIA_DPS_OPTICAL_XRES_STR = "Horizontal Optical Resolution";
	public const uint32 WIA_DPS_OPTICAL_YRES = 3091;
	public const String WIA_DPS_OPTICAL_YRES_STR = "Vertical Optical Resolution";
	public const uint32 WIA_DPS_ENDORSER_CHARACTERS = 3092;
	public const String WIA_DPS_ENDORSER_CHARACTERS_STR = "Endorser Characters";
	public const uint32 WIA_DPS_ENDORSER_STRING = 3093;
	public const String WIA_DPS_ENDORSER_STRING_STR = "Endorser String";
	public const uint32 WIA_DPS_SCAN_AHEAD_PAGES = 3094;
	public const String WIA_DPS_SCAN_AHEAD_PAGES_STR = "Scan Ahead Pages";
	public const uint32 WIA_DPS_MAX_SCAN_TIME = 3095;
	public const String WIA_DPS_MAX_SCAN_TIME_STR = "Max Scan Time";
	public const uint32 WIA_DPS_PAGES = 3096;
	public const String WIA_DPS_PAGES_STR = "Pages";
	public const uint32 WIA_DPS_PAGE_SIZE = 3097;
	public const String WIA_DPS_PAGE_SIZE_STR = "Page Size";
	public const uint32 WIA_DPS_PAGE_WIDTH = 3098;
	public const String WIA_DPS_PAGE_WIDTH_STR = "Page Width";
	public const uint32 WIA_DPS_PAGE_HEIGHT = 3099;
	public const String WIA_DPS_PAGE_HEIGHT_STR = "Page Height";
	public const uint32 WIA_DPS_PREVIEW = 3100;
	public const String WIA_DPS_PREVIEW_STR = "Preview";
	public const uint32 WIA_DPS_TRANSPARENCY = 3101;
	public const String WIA_DPS_TRANSPARENCY_STR = "Transparency Adapter";
	public const uint32 WIA_DPS_TRANSPARENCY_SELECT = 3102;
	public const String WIA_DPS_TRANSPARENCY_SELECT_STR = "Transparency Adapter Select";
	public const uint32 WIA_DPS_SHOW_PREVIEW_CONTROL = 3103;
	public const String WIA_DPS_SHOW_PREVIEW_CONTROL_STR = "Show preview control";
	public const uint32 WIA_DPS_MIN_HORIZONTAL_SHEET_FEED_SIZE = 3104;
	public const String WIA_DPS_MIN_HORIZONTAL_SHEET_FEED_SIZE_STR = "Minimum Horizontal Sheet Feed Size";
	public const uint32 WIA_DPS_MIN_VERTICAL_SHEET_FEED_SIZE = 3105;
	public const String WIA_DPS_MIN_VERTICAL_SHEET_FEED_SIZE_STR = "Minimum Vertical Sheet Feed Size";
	public const uint32 WIA_DPS_TRANSPARENCY_CAPABILITIES = 3106;
	public const String WIA_DPS_TRANSPARENCY_CAPABILITIES_STR = "Transparency Adapter Capabilities";
	public const uint32 WIA_DPS_TRANSPARENCY_STATUS = 3107;
	public const String WIA_DPS_TRANSPARENCY_STATUS_STR = "Transparency Adapter Status";
	public const uint32 WIA_DPF_MOUNT_POINT = 3330;
	public const String WIA_DPF_MOUNT_POINT_STR = "Directory mount point";
	public const uint32 WIA_DPV_LAST_PICTURE_TAKEN = 3586;
	public const String WIA_DPV_LAST_PICTURE_TAKEN_STR = "Last Picture Taken";
	public const uint32 WIA_DPV_IMAGES_DIRECTORY = 3587;
	public const String WIA_DPV_IMAGES_DIRECTORY_STR = "Images Directory";
	public const uint32 WIA_DPV_DSHOW_DEVICE_PATH = 3588;
	public const String WIA_DPV_DSHOW_DEVICE_PATH_STR = "Directshow Device Path";
	public const uint32 WIA_IPA_ITEM_NAME = 4098;
	public const String WIA_IPA_ITEM_NAME_STR = "Item Name";
	public const uint32 WIA_IPA_FULL_ITEM_NAME = 4099;
	public const String WIA_IPA_FULL_ITEM_NAME_STR = "Full Item Name";
	public const uint32 WIA_IPA_ITEM_TIME = 4100;
	public const String WIA_IPA_ITEM_TIME_STR = "Item Time Stamp";
	public const uint32 WIA_IPA_ITEM_FLAGS = 4101;
	public const String WIA_IPA_ITEM_FLAGS_STR = "Item Flags";
	public const uint32 WIA_IPA_ACCESS_RIGHTS = 4102;
	public const String WIA_IPA_ACCESS_RIGHTS_STR = "Access Rights";
	public const uint32 WIA_IPA_DATATYPE = 4103;
	public const String WIA_IPA_DATATYPE_STR = "Data Type";
	public const uint32 WIA_IPA_DEPTH = 4104;
	public const String WIA_IPA_DEPTH_STR = "Bits Per Pixel";
	public const uint32 WIA_IPA_PREFERRED_FORMAT = 4105;
	public const String WIA_IPA_PREFERRED_FORMAT_STR = "Preferred Format";
	public const uint32 WIA_IPA_FORMAT = 4106;
	public const String WIA_IPA_FORMAT_STR = "Format";
	public const uint32 WIA_IPA_COMPRESSION = 4107;
	public const String WIA_IPA_COMPRESSION_STR = "Compression";
	public const uint32 WIA_IPA_TYMED = 4108;
	public const String WIA_IPA_TYMED_STR = "Media Type";
	public const uint32 WIA_IPA_CHANNELS_PER_PIXEL = 4109;
	public const String WIA_IPA_CHANNELS_PER_PIXEL_STR = "Channels Per Pixel";
	public const uint32 WIA_IPA_BITS_PER_CHANNEL = 4110;
	public const String WIA_IPA_BITS_PER_CHANNEL_STR = "Bits Per Channel";
	public const uint32 WIA_IPA_PLANAR = 4111;
	public const String WIA_IPA_PLANAR_STR = "Planar";
	public const uint32 WIA_IPA_PIXELS_PER_LINE = 4112;
	public const String WIA_IPA_PIXELS_PER_LINE_STR = "Pixels Per Line";
	public const uint32 WIA_IPA_BYTES_PER_LINE = 4113;
	public const String WIA_IPA_BYTES_PER_LINE_STR = "Bytes Per Line";
	public const uint32 WIA_IPA_NUMBER_OF_LINES = 4114;
	public const String WIA_IPA_NUMBER_OF_LINES_STR = "Number of Lines";
	public const uint32 WIA_IPA_GAMMA_CURVES = 4115;
	public const String WIA_IPA_GAMMA_CURVES_STR = "Gamma Curves";
	public const uint32 WIA_IPA_ITEM_SIZE = 4116;
	public const String WIA_IPA_ITEM_SIZE_STR = "Item Size";
	public const uint32 WIA_IPA_COLOR_PROFILE = 4117;
	public const String WIA_IPA_COLOR_PROFILE_STR = "Color Profiles";
	public const uint32 WIA_IPA_MIN_BUFFER_SIZE = 4118;
	public const String WIA_IPA_MIN_BUFFER_SIZE_STR = "Buffer Size";
	public const uint32 WIA_IPA_BUFFER_SIZE = 4118;
	public const String WIA_IPA_BUFFER_SIZE_STR = "Buffer Size";
	public const uint32 WIA_IPA_REGION_TYPE = 4119;
	public const String WIA_IPA_REGION_TYPE_STR = "Region Type";
	public const uint32 WIA_IPA_ICM_PROFILE_NAME = 4120;
	public const String WIA_IPA_ICM_PROFILE_NAME_STR = "Color Profile Name";
	public const uint32 WIA_IPA_APP_COLOR_MAPPING = 4121;
	public const String WIA_IPA_APP_COLOR_MAPPING_STR = "Application Applies Color Mapping";
	public const uint32 WIA_IPA_PROP_STREAM_COMPAT_ID = 4122;
	public const String WIA_IPA_PROP_STREAM_COMPAT_ID_STR = "Stream Compatibility ID";
	public const uint32 WIA_IPA_FILENAME_EXTENSION = 4123;
	public const String WIA_IPA_FILENAME_EXTENSION_STR = "Filename extension";
	public const uint32 WIA_IPA_SUPPRESS_PROPERTY_PAGE = 4124;
	public const String WIA_IPA_SUPPRESS_PROPERTY_PAGE_STR = "Suppress a property page";
	public const uint32 WIA_IPC_THUMBNAIL = 5122;
	public const String WIA_IPC_THUMBNAIL_STR = "Thumbnail Data";
	public const uint32 WIA_IPC_THUMB_WIDTH = 5123;
	public const String WIA_IPC_THUMB_WIDTH_STR = "Thumbnail Width";
	public const uint32 WIA_IPC_THUMB_HEIGHT = 5124;
	public const String WIA_IPC_THUMB_HEIGHT_STR = "Thumbnail Height";
	public const uint32 WIA_IPC_AUDIO_AVAILABLE = 5125;
	public const String WIA_IPC_AUDIO_AVAILABLE_STR = "Audio Available";
	public const uint32 WIA_IPC_AUDIO_DATA_FORMAT = 5126;
	public const String WIA_IPC_AUDIO_DATA_FORMAT_STR = "Audio Format";
	public const uint32 WIA_IPC_AUDIO_DATA = 5127;
	public const String WIA_IPC_AUDIO_DATA_STR = "Audio Data";
	public const uint32 WIA_IPC_NUM_PICT_PER_ROW = 5128;
	public const String WIA_IPC_NUM_PICT_PER_ROW_STR = "Pictures per Row";
	public const uint32 WIA_IPC_SEQUENCE = 5129;
	public const String WIA_IPC_SEQUENCE_STR = "Sequence Number";
	public const uint32 WIA_IPC_TIMEDELAY = 5130;
	public const String WIA_IPC_TIMEDELAY_STR = "Time Delay";
	public const uint32 WIA_IPS_CUR_INTENT = 6146;
	public const String WIA_IPS_CUR_INTENT_STR = "Current Intent";
	public const uint32 WIA_IPS_XRES = 6147;
	public const String WIA_IPS_XRES_STR = "Horizontal Resolution";
	public const uint32 WIA_IPS_YRES = 6148;
	public const String WIA_IPS_YRES_STR = "Vertical Resolution";
	public const uint32 WIA_IPS_XPOS = 6149;
	public const String WIA_IPS_XPOS_STR = "Horizontal Start Position";
	public const uint32 WIA_IPS_YPOS = 6150;
	public const String WIA_IPS_YPOS_STR = "Vertical Start Position";
	public const uint32 WIA_IPS_XEXTENT = 6151;
	public const String WIA_IPS_XEXTENT_STR = "Horizontal Extent";
	public const uint32 WIA_IPS_YEXTENT = 6152;
	public const String WIA_IPS_YEXTENT_STR = "Vertical Extent";
	public const uint32 WIA_IPS_PHOTOMETRIC_INTERP = 6153;
	public const String WIA_IPS_PHOTOMETRIC_INTERP_STR = "Photometric Interpretation";
	public const uint32 WIA_IPS_BRIGHTNESS = 6154;
	public const String WIA_IPS_BRIGHTNESS_STR = "Brightness";
	public const uint32 WIA_IPS_CONTRAST = 6155;
	public const String WIA_IPS_CONTRAST_STR = "Contrast";
	public const uint32 WIA_IPS_ORIENTATION = 6156;
	public const String WIA_IPS_ORIENTATION_STR = "Orientation";
	public const uint32 WIA_IPS_ROTATION = 6157;
	public const String WIA_IPS_ROTATION_STR = "Rotation";
	public const uint32 WIA_IPS_MIRROR = 6158;
	public const String WIA_IPS_MIRROR_STR = "Mirror";
	public const uint32 WIA_IPS_THRESHOLD = 6159;
	public const String WIA_IPS_THRESHOLD_STR = "Threshold";
	public const uint32 WIA_IPS_INVERT = 6160;
	public const String WIA_IPS_INVERT_STR = "Invert";
	public const uint32 WIA_IPS_WARM_UP_TIME = 6161;
	public const String WIA_IPS_WARM_UP_TIME_STR = "Lamp Warm up Time";
	public const uint32 WIA_DPS_USER_NAME = 3112;
	public const String WIA_DPS_USER_NAME_STR = "User Name";
	public const uint32 WIA_DPS_SERVICE_ID = 3113;
	public const String WIA_DPS_SERVICE_ID_STR = "Service ID";
	public const uint32 WIA_DPS_DEVICE_ID = 3114;
	public const String WIA_DPS_DEVICE_ID_STR = "Device ID";
	public const uint32 WIA_DPS_GLOBAL_IDENTITY = 3115;
	public const String WIA_DPS_GLOBAL_IDENTITY_STR = "Global Identity";
	public const uint32 WIA_DPS_SCAN_AVAILABLE_ITEM = 3116;
	public const String WIA_DPS_SCAN_AVAILABLE_ITEM_STR = "Scan Available Item";
	public const uint32 WIA_IPS_DESKEW_X = 6162;
	public const String WIA_IPS_DESKEW_X_STR = "DeskewX";
	public const uint32 WIA_IPS_DESKEW_Y = 6163;
	public const String WIA_IPS_DESKEW_Y_STR = "DeskewY";
	public const uint32 WIA_IPS_SEGMENTATION = 6164;
	public const String WIA_IPS_SEGMENTATION_STR = "Segmentation";
	public const String WIA_SEGMENTATION_FILTER_STR = "SegmentationFilter";
	public const String WIA_IMAGEPROC_FILTER_STR = "ImageProcessingFilter";
	public const uint32 WIA_IPS_MAX_HORIZONTAL_SIZE = 6165;
	public const String WIA_IPS_MAX_HORIZONTAL_SIZE_STR = "Maximum Horizontal Scan Size";
	public const uint32 WIA_IPS_MAX_VERTICAL_SIZE = 6166;
	public const String WIA_IPS_MAX_VERTICAL_SIZE_STR = "Maximum Vertical Scan Size";
	public const uint32 WIA_IPS_MIN_HORIZONTAL_SIZE = 6167;
	public const String WIA_IPS_MIN_HORIZONTAL_SIZE_STR = "Minimum Horizontal Scan Size";
	public const uint32 WIA_IPS_MIN_VERTICAL_SIZE = 6168;
	public const String WIA_IPS_MIN_VERTICAL_SIZE_STR = "Minimum Vertical Scan Size";
	public const uint32 WIA_IPS_TRANSFER_CAPABILITIES = 6169;
	public const String WIA_IPS_TRANSFER_CAPABILITIES_STR = "Transfer Capabilities";
	public const uint32 WIA_IPS_SHEET_FEEDER_REGISTRATION = 3078;
	public const String WIA_IPS_SHEET_FEEDER_REGISTRATION_STR = "Sheet Feeder Registration";
	public const uint32 WIA_IPS_DOCUMENT_HANDLING_SELECT = 3088;
	public const String WIA_IPS_DOCUMENT_HANDLING_SELECT_STR = "Document Handling Select";
	public const uint32 WIA_IPS_OPTICAL_XRES = 3090;
	public const String WIA_IPS_OPTICAL_XRES_STR = "Horizontal Optical Resolution";
	public const uint32 WIA_IPS_OPTICAL_YRES = 3091;
	public const String WIA_IPS_OPTICAL_YRES_STR = "Vertical Optical Resolution";
	public const uint32 WIA_IPS_PAGES = 3096;
	public const String WIA_IPS_PAGES_STR = "Pages";
	public const uint32 WIA_IPS_PAGE_SIZE = 3097;
	public const String WIA_IPS_PAGE_SIZE_STR = "Page Size";
	public const uint32 WIA_IPS_PAGE_WIDTH = 3098;
	public const String WIA_IPS_PAGE_WIDTH_STR = "Page Width";
	public const uint32 WIA_IPS_PAGE_HEIGHT = 3099;
	public const String WIA_IPS_PAGE_HEIGHT_STR = "Page Height";
	public const uint32 WIA_IPS_PREVIEW = 3100;
	public const String WIA_IPS_PREVIEW_STR = "Preview";
	public const uint32 WIA_IPS_SHOW_PREVIEW_CONTROL = 3103;
	public const String WIA_IPS_SHOW_PREVIEW_CONTROL_STR = "Show preview control";
	public const uint32 WIA_IPS_FILM_SCAN_MODE = 3104;
	public const String WIA_IPS_FILM_SCAN_MODE_STR = "Film Scan Mode";
	public const uint32 WIA_IPS_LAMP = 3105;
	public const String WIA_IPS_LAMP_STR = "Lamp";
	public const uint32 WIA_IPS_LAMP_AUTO_OFF = 3106;
	public const String WIA_IPS_LAMP_AUTO_OFF_STR = "Lamp Auto Off";
	public const uint32 WIA_IPS_AUTO_DESKEW = 3107;
	public const String WIA_IPS_AUTO_DESKEW_STR = "Automatic Deskew";
	public const uint32 WIA_IPS_SUPPORTS_CHILD_ITEM_CREATION = 3108;
	public const String WIA_IPS_SUPPORTS_CHILD_ITEM_CREATION_STR = "Supports Child Item Creation";
	public const uint32 WIA_IPS_XSCALING = 3109;
	public const String WIA_IPS_XSCALING_STR = "Horizontal Scaling";
	public const uint32 WIA_IPS_YSCALING = 3110;
	public const String WIA_IPS_YSCALING_STR = "Vertical Scaling";
	public const uint32 WIA_IPS_PREVIEW_TYPE = 3111;
	public const String WIA_IPS_PREVIEW_TYPE_STR = "Preview Type";
	public const uint32 WIA_IPA_ITEM_CATEGORY = 4125;
	public const String WIA_IPA_ITEM_CATEGORY_STR = "Item Category";
	public const uint32 WIA_IPA_UPLOAD_ITEM_SIZE = 4126;
	public const String WIA_IPA_UPLOAD_ITEM_SIZE_STR = "Upload Item Size";
	public const uint32 WIA_IPA_ITEMS_STORED = 4127;
	public const String WIA_IPA_ITEMS_STORED_STR = "Items Stored";
	public const uint32 WIA_IPA_RAW_BITS_PER_CHANNEL = 4128;
	public const String WIA_IPA_RAW_BITS_PER_CHANNEL_STR = "Raw Bits Per Channel";
	public const uint32 WIA_IPS_FILM_NODE_NAME = 4129;
	public const String WIA_IPS_FILM_NODE_NAME_STR = "Film Node Name";
	public const uint32 WIA_IPS_PRINTER_ENDORSER = 4130;
	public const String WIA_IPS_PRINTER_ENDORSER_STR = "Printer/Endorser";
	public const uint32 WIA_IPS_PRINTER_ENDORSER_ORDER = 4131;
	public const String WIA_IPS_PRINTER_ENDORSER_ORDER_STR = "Printer/Endorser Order";
	public const uint32 WIA_IPS_PRINTER_ENDORSER_COUNTER = 4132;
	public const String WIA_IPS_PRINTER_ENDORSER_COUNTER_STR = "Printer/Endorser Counter";
	public const uint32 WIA_IPS_PRINTER_ENDORSER_STEP = 4133;
	public const String WIA_IPS_PRINTER_ENDORSER_STEP_STR = "Printer/Endorser Step";
	public const uint32 WIA_IPS_PRINTER_ENDORSER_XOFFSET = 4134;
	public const String WIA_IPS_PRINTER_ENDORSER_XOFFSET_STR = "Printer/Endorser Horizontal Offset";
	public const uint32 WIA_IPS_PRINTER_ENDORSER_YOFFSET = 4135;
	public const String WIA_IPS_PRINTER_ENDORSER_YOFFSET_STR = "Printer/Endorser Vertical Offset";
	public const uint32 WIA_IPS_PRINTER_ENDORSER_NUM_LINES = 4136;
	public const String WIA_IPS_PRINTER_ENDORSER_NUM_LINES_STR = "Printer/Endorser Lines";
	public const uint32 WIA_IPS_PRINTER_ENDORSER_STRING = 4137;
	public const String WIA_IPS_PRINTER_ENDORSER_STRING_STR = "Printer/Endorser String";
	public const uint32 WIA_IPS_PRINTER_ENDORSER_VALID_CHARACTERS = 4138;
	public const String WIA_IPS_PRINTER_ENDORSER_VALID_CHARACTERS_STR = "Printer/Endorser Valid Characters";
	public const uint32 WIA_IPS_PRINTER_ENDORSER_VALID_FORMAT_SPECIFIERS = 4139;
	public const String WIA_IPS_PRINTER_ENDORSER_VALID_FORMAT_SPECIFIERS_STR = "Printer/Endorser Valid Format Specifiers";
	public const uint32 WIA_IPS_PRINTER_ENDORSER_TEXT_UPLOAD = 4140;
	public const String WIA_IPS_PRINTER_ENDORSER_TEXT_UPLOAD_STR = "Printer/Endorser Text Upload";
	public const uint32 WIA_IPS_PRINTER_ENDORSER_TEXT_DOWNLOAD = 4141;
	public const String WIA_IPS_PRINTER_ENDORSER_TEXT_DOWNLOAD_STR = "Printer/Endorser Text Download";
	public const uint32 WIA_IPS_PRINTER_ENDORSER_GRAPHICS = 4142;
	public const String WIA_IPS_PRINTER_ENDORSER_GRAPHICS_STR = "Printer/Endorser Graphics";
	public const uint32 WIA_IPS_PRINTER_ENDORSER_GRAPHICS_POSITION = 4143;
	public const String WIA_IPS_PRINTER_ENDORSER_GRAPHICS_POSITION_STR = "Printer/Endorser Graphics Position";
	public const uint32 WIA_IPS_PRINTER_ENDORSER_GRAPHICS_MIN_WIDTH = 4144;
	public const String WIA_IPS_PRINTER_ENDORSER_GRAPHICS_MIN_WIDTH_STR = "Printer/Endorser Graphics Minimum Width";
	public const uint32 WIA_IPS_PRINTER_ENDORSER_GRAPHICS_MAX_WIDTH = 4145;
	public const String WIA_IPS_PRINTER_ENDORSER_GRAPHICS_MAX_WIDTH_STR = "Printer/Endorser Graphics Maximum Width";
	public const uint32 WIA_IPS_PRINTER_ENDORSER_GRAPHICS_MIN_HEIGHT = 4146;
	public const String WIA_IPS_PRINTER_ENDORSER_GRAPHICS_MIN_HEIGHT_STR = "Printer/Endorser Graphics Minimum Height";
	public const uint32 WIA_IPS_PRINTER_ENDORSER_GRAPHICS_MAX_HEIGHT = 4147;
	public const String WIA_IPS_PRINTER_ENDORSER_GRAPHICS_MAX_HEIGHT_STR = "Printer/Endorser Graphics Maximum Height";
	public const uint32 WIA_IPS_PRINTER_ENDORSER_GRAPHICS_UPLOAD = 4148;
	public const String WIA_IPS_PRINTER_ENDORSER_GRAPHICS_UPLOAD_STR = "Printer/Endorser Graphics Upload";
	public const uint32 WIA_IPS_PRINTER_ENDORSER_GRAPHICS_DOWNLOAD = 4149;
	public const String WIA_IPS_PRINTER_ENDORSER_GRAPHICS_DOWNLOAD_STR = "Printer/Endorser Graphics Download";
	public const uint32 WIA_IPS_BARCODE_READER = 4150;
	public const String WIA_IPS_BARCODE_READER_STR = "Barcode Reader";
	public const uint32 WIA_IPS_MAXIMUM_BARCODES_PER_PAGE = 4151;
	public const String WIA_IPS_MAXIMUM_BARCODES_PER_PAGE_STR = "Maximum Barcodes Per Page";
	public const uint32 WIA_IPS_BARCODE_SEARCH_DIRECTION = 4152;
	public const String WIA_IPS_BARCODE_SEARCH_DIRECTION_STR = "Barcode Search Direction";
	public const uint32 WIA_IPS_MAXIMUM_BARCODE_SEARCH_RETRIES = 4153;
	public const String WIA_IPS_MAXIMUM_BARCODE_SEARCH_RETRIES_STR = "Barcode Search Retries";
	public const uint32 WIA_IPS_BARCODE_SEARCH_TIMEOUT = 4154;
	public const String WIA_IPS_BARCODE_SEARCH_TIMEOUT_STR = "Barcode Search Timeout";
	public const uint32 WIA_IPS_SUPPORTED_BARCODE_TYPES = 4155;
	public const String WIA_IPS_SUPPORTED_BARCODE_TYPES_STR = "Supported Barcode Types";
	public const uint32 WIA_IPS_ENABLED_BARCODE_TYPES = 4156;
	public const String WIA_IPS_ENABLED_BARCODE_TYPES_STR = "Enabled Barcode Types";
	public const uint32 WIA_IPS_PATCH_CODE_READER = 4157;
	public const String WIA_IPS_PATCH_CODE_READER_STR = "Patch Code Reader";
	public const uint32 WIA_IPS_SUPPORTED_PATCH_CODE_TYPES = 4162;
	public const String WIA_IPS_SUPPORTED_PATCH_CODE_TYPES_STR = "Supported Patch Code Types";
	public const uint32 WIA_IPS_ENABLED_PATCH_CODE_TYPES = 4163;
	public const String WIA_IPS_ENABLED_PATCH_CODE_TYPES_STR = "Enabled Path Code Types";
	public const uint32 WIA_IPS_MICR_READER = 4164;
	public const String WIA_IPS_MICR_READER_STR = "MICR Reader";
	public const uint32 WIA_IPS_JOB_SEPARATORS = 4165;
	public const String WIA_IPS_JOB_SEPARATORS_STR = "Job Separators";
	public const uint32 WIA_IPS_LONG_DOCUMENT = 4166;
	public const String WIA_IPS_LONG_DOCUMENT_STR = "Long Document";
	public const uint32 WIA_IPS_BLANK_PAGES = 4167;
	public const String WIA_IPS_BLANK_PAGES_STR = "Blank Pages";
	public const uint32 WIA_IPS_MULTI_FEED = 4168;
	public const String WIA_IPS_MULTI_FEED_STR = "Multi-Feed";
	public const uint32 WIA_IPS_MULTI_FEED_SENSITIVITY = 4169;
	public const String WIA_IPS_MULTI_FEED_SENSITIVITY_STR = "Multi-Feed Sensitivity";
	public const uint32 WIA_IPS_AUTO_CROP = 4170;
	public const String WIA_IPS_AUTO_CROP_STR = "Auto-Crop";
	public const uint32 WIA_IPS_OVER_SCAN = 4171;
	public const String WIA_IPS_OVER_SCAN_STR = "Overscan";
	public const uint32 WIA_IPS_OVER_SCAN_LEFT = 4172;
	public const String WIA_IPS_OVER_SCAN_LEFT_STR = "Overscan Left";
	public const uint32 WIA_IPS_OVER_SCAN_RIGHT = 4173;
	public const String WIA_IPS_OVER_SCAN_RIGHT_STR = "Overscan Right";
	public const uint32 WIA_IPS_OVER_SCAN_TOP = 4174;
	public const String WIA_IPS_OVER_SCAN_TOP_STR = "Overscan Top";
	public const uint32 WIA_IPS_OVER_SCAN_BOTTOM = 4175;
	public const String WIA_IPS_OVER_SCAN_BOTTOM_STR = "Overscan Bottom";
	public const uint32 WIA_IPS_COLOR_DROP = 4176;
	public const String WIA_IPS_COLOR_DROP_STR = "Color Drop";
	public const uint32 WIA_IPS_COLOR_DROP_RED = 4177;
	public const String WIA_IPS_COLOR_DROP_RED_STR = "Color Drop Red";
	public const uint32 WIA_IPS_COLOR_DROP_GREEN = 4178;
	public const String WIA_IPS_COLOR_DROP_GREEN_STR = "Color Drop Green";
	public const uint32 WIA_IPS_COLOR_DROP_BLUE = 4179;
	public const String WIA_IPS_COLOR_DROP_BLUE_STR = "Color Drop Blue";
	public const uint32 WIA_IPS_SCAN_AHEAD = 4180;
	public const String WIA_IPS_SCAN_AHEAD_STR = "Scan Ahead";
	public const uint32 WIA_IPS_SCAN_AHEAD_CAPACITY = 4181;
	public const String WIA_IPS_SCAN_AHEAD_CAPACITY_STR = "Scan Ahead Capacity";
	public const uint32 WIA_IPS_FEEDER_CONTROL = 4182;
	public const String WIA_IPS_FEEDER_CONTROL_STR = "Feeder Control";
	public const uint32 WIA_IPS_PRINTER_ENDORSER_PADDING = 4183;
	public const String WIA_IPS_PRINTER_ENDORSER_PADDING_STR = "Printer/Endorser Padding";
	public const uint32 WIA_IPS_PRINTER_ENDORSER_FONT_TYPE = 4184;
	public const String WIA_IPS_PRINTER_ENDORSER_FONT_TYPE_STR = "Printer/Endorser Font Type";
	public const uint32 WIA_IPS_ALARM = 4185;
	public const String WIA_IPS_ALARM_STR = "Alarm";
	public const uint32 WIA_IPS_PRINTER_ENDORSER_INK = 4186;
	public const String WIA_IPS_PRINTER_ENDORSER_INK_STR = "Printer/Endorser Ink";
	public const uint32 WIA_IPS_PRINTER_ENDORSER_CHARACTER_ROTATION = 4187;
	public const String WIA_IPS_PRINTER_ENDORSER_CHARACTER_ROTATION_STR = "Printer/Endorser Character Rotation";
	public const uint32 WIA_IPS_PRINTER_ENDORSER_MAX_CHARACTERS = 4188;
	public const String WIA_IPS_PRINTER_ENDORSER_MAX_CHARACTERS_STR = "Printer/Endorser Maximum Characters";
	public const uint32 WIA_IPS_PRINTER_ENDORSER_MAX_GRAPHICS = 4189;
	public const String WIA_IPS_PRINTER_ENDORSER_MAX_GRAPHICS_STR = "Printer/Endorser Maximum Graphics";
	public const uint32 WIA_IPS_PRINTER_ENDORSER_COUNTER_DIGITS = 4190;
	public const String WIA_IPS_PRINTER_ENDORSER_COUNTER_DIGITS_STR = "Printer/Endorser Counter Digits";
	public const uint32 WIA_IPS_COLOR_DROP_MULTI = 4191;
	public const String WIA_IPS_COLOR_DROP_MULTI_STR = "Color Drop Multiple";
	public const uint32 WIA_IPS_BLANK_PAGES_SENSITIVITY = 4192;
	public const String WIA_IPS_BLANK_PAGES_SENSITIVITY_STR = "Blank Pages Sensitivity";
	public const uint32 WIA_IPS_MULTI_FEED_DETECT_METHOD = 4193;
	public const String WIA_IPS_MULTI_FEED_DETECT_METHOD_STR = "Multi-Feed Detection Method";
	public const Guid WIA_CATEGORY_FINISHED_FILE = .(0xff2b77ca, 0xcf84, 0x432b, 0xa7, 0x35, 0x3a, 0x13, 0x0d, 0xde, 0x2a, 0x88);
	public const Guid WIA_CATEGORY_FLATBED = .(0xfb607b1f, 0x43f3, 0x488b, 0x85, 0x5b, 0xfb, 0x70, 0x3e, 0xc3, 0x42, 0xa6);
	public const Guid WIA_CATEGORY_FEEDER = .(0xfe131934, 0xf84c, 0x42ad, 0x8d, 0xa4, 0x61, 0x29, 0xcd, 0xdd, 0x72, 0x88);
	public const Guid WIA_CATEGORY_FILM = .(0xfcf65be7, 0x3ce3, 0x4473, 0xaf, 0x85, 0xf5, 0xd3, 0x7d, 0x21, 0xb6, 0x8a);
	public const Guid WIA_CATEGORY_ROOT = .(0xf193526f, 0x59b8, 0x4a26, 0x98, 0x88, 0xe1, 0x6e, 0x4f, 0x97, 0xce, 0x10);
	public const Guid WIA_CATEGORY_FOLDER = .(0xc692a446, 0x6f5a, 0x481d, 0x85, 0xbb, 0x92, 0xe2, 0xe8, 0x6f, 0xd3, 0x0a);
	public const Guid WIA_CATEGORY_FEEDER_FRONT = .(0x4823175c, 0x3b28, 0x487b, 0xa7, 0xe6, 0xee, 0xbc, 0x17, 0x61, 0x4f, 0xd1);
	public const Guid WIA_CATEGORY_FEEDER_BACK = .(0x61ca74d4, 0x39db, 0x42aa, 0x89, 0xb1, 0x8c, 0x19, 0xc9, 0xcd, 0x4c, 0x23);
	public const Guid WIA_CATEGORY_AUTO = .(0xdefe5fd8, 0x6c97, 0x4dde, 0xb1, 0x1e, 0xcb, 0x50, 0x9b, 0x27, 0x0e, 0x11);
	public const Guid WIA_CATEGORY_IMPRINTER = .(0xfc65016d, 0x9202, 0x43dd, 0x91, 0xa7, 0x64, 0xc2, 0x95, 0x4c, 0xfb, 0x8b);
	public const Guid WIA_CATEGORY_ENDORSER = .(0x47102cc3, 0x127f, 0x4771, 0xad, 0xfc, 0x99, 0x1a, 0xb8, 0xee, 0x1e, 0x97);
	public const Guid WIA_CATEGORY_BARCODE_READER = .(0x36e178a0, 0x473f, 0x494b, 0xaf, 0x8f, 0x6c, 0x3f, 0x6d, 0x74, 0x86, 0xfc);
	public const Guid WIA_CATEGORY_PATCH_CODE_READER = .(0x8faa1a6d, 0x9c8a, 0x42cd, 0x98, 0xb3, 0xee, 0x97, 0x00, 0xcb, 0xc7, 0x4f);
	public const Guid WIA_CATEGORY_MICR_READER = .(0x3b86c1ec, 0x71bc, 0x4645, 0xb4, 0xd5, 0x1b, 0x19, 0xda, 0x2b, 0xe9, 0x78);
	public const Guid CLSID_WiaDefaultSegFilter = .(0xd4f4d30b, 0x0b29, 0x4508, 0x89, 0x22, 0x0c, 0x57, 0x97, 0xd4, 0x27, 0x65);
	public const uint32 WIA_TRANSFER_CHILDREN_SINGLE_SCAN = 1;
	public const uint32 WIA_USE_SEGMENTATION_FILTER = 0;
	public const uint32 WIA_DONT_USE_SEGMENTATION_FILTER = 1;
	public const uint32 WIA_FILM_COLOR_SLIDE = 0;
	public const uint32 WIA_FILM_COLOR_NEGATIVE = 1;
	public const uint32 WIA_FILM_BW_NEGATIVE = 2;
	public const uint32 WIA_LAMP_ON = 0;
	public const uint32 WIA_LAMP_OFF = 1;
	public const uint32 WIA_AUTO_DESKEW_ON = 0;
	public const uint32 WIA_AUTO_DESKEW_OFF = 1;
	public const uint32 WIA_ADVANCED_PREVIEW = 0;
	public const uint32 WIA_BASIC_PREVIEW = 1;
	public const uint32 WIA_PRINTER_ENDORSER_DISABLED = 0;
	public const uint32 WIA_PRINTER_ENDORSER_AUTO = 1;
	public const uint32 WIA_PRINTER_ENDORSER_FLATBED = 2;
	public const uint32 WIA_PRINTER_ENDORSER_FEEDER_FRONT = 3;
	public const uint32 WIA_PRINTER_ENDORSER_FEEDER_BACK = 4;
	public const uint32 WIA_PRINTER_ENDORSER_FEEDER_DUPLEX = 5;
	public const uint32 WIA_PRINTER_ENDORSER_DIGITAL = 6;
	public const uint32 WIA_PRINTER_ENDORSER_BEFORE_SCAN = 0;
	public const uint32 WIA_PRINTER_ENDORSER_AFTER_SCAN = 1;
	public const uint32 WIA_PRINT_DATE = 0;
	public const uint32 WIA_PRINT_YEAR = 1;
	public const uint32 WIA_PRINT_MONTH = 2;
	public const uint32 WIA_PRINT_DAY = 3;
	public const uint32 WIA_PRINT_WEEK_DAY = 4;
	public const uint32 WIA_PRINT_TIME_24H = 5;
	public const uint32 WIA_PRINT_TIME_12H = 6;
	public const uint32 WIA_PRINT_HOUR_24H = 7;
	public const uint32 WIA_PRINT_HOUR_12H = 8;
	public const uint32 WIA_PRINT_AM_PM = 9;
	public const uint32 WIA_PRINT_MINUTE = 10;
	public const uint32 WIA_PRINT_SECOND = 11;
	public const uint32 WIA_PRINT_PAGE_COUNT = 12;
	public const uint32 WIA_PRINT_IMAGE = 13;
	public const uint32 WIA_PRINT_MILLISECOND = 14;
	public const uint32 WIA_PRINT_MONTH_NAME = 15;
	public const uint32 WIA_PRINT_MONTH_SHORT = 16;
	public const uint32 WIA_PRINT_WEEK_DAY_SHORT = 17;
	public const uint32 WIA_PRINTER_ENDORSER_GRAPHICS_LEFT = 0;
	public const uint32 WIA_PRINTER_ENDORSER_GRAPHICS_RIGHT = 1;
	public const uint32 WIA_PRINTER_ENDORSER_GRAPHICS_TOP = 2;
	public const uint32 WIA_PRINTER_ENDORSER_GRAPHICS_BOTTOM = 3;
	public const uint32 WIA_PRINTER_ENDORSER_GRAPHICS_TOP_LEFT = 4;
	public const uint32 WIA_PRINTER_ENDORSER_GRAPHICS_TOP_RIGHT = 5;
	public const uint32 WIA_PRINTER_ENDORSER_GRAPHICS_BOTTOM_LEFT = 6;
	public const uint32 WIA_PRINTER_ENDORSER_GRAPHICS_BOTTOM_RIGHT = 7;
	public const uint32 WIA_PRINTER_ENDORSER_GRAPHICS_BACKGROUND = 8;
	public const uint32 WIA_PRINTER_ENDORSER_GRAPHICS_DEVICE_DEFAULT = 9;
	public const uint32 WIA_BARCODE_READER_DISABLED = 0;
	public const uint32 WIA_BARCODE_READER_AUTO = 1;
	public const uint32 WIA_BARCODE_READER_FLATBED = 2;
	public const uint32 WIA_BARCODE_READER_FEEDER_FRONT = 3;
	public const uint32 WIA_BARCODE_READER_FEEDER_BACK = 4;
	public const uint32 WIA_BARCODE_READER_FEEDER_DUPLEX = 5;
	public const uint32 WIA_BARCODE_HORIZONTAL_SEARCH = 0;
	public const uint32 WIA_BARCODE_VERTICAL_SEARCH = 1;
	public const uint32 WIA_BARCODE_HORIZONTAL_VERTICAL_SEARCH = 2;
	public const uint32 WIA_BARCODE_VERTICAL_HORIZONTAL_SEARCH = 3;
	public const uint32 WIA_BARCODE_AUTO_SEARCH = 4;
	public const uint32 WIA_BARCODE_UPCA = 0;
	public const uint32 WIA_BARCODE_UPCE = 1;
	public const uint32 WIA_BARCODE_CODABAR = 2;
	public const uint32 WIA_BARCODE_NONINTERLEAVED_2OF5 = 3;
	public const uint32 WIA_BARCODE_INTERLEAVED_2OF5 = 4;
	public const uint32 WIA_BARCODE_CODE39 = 5;
	public const uint32 WIA_BARCODE_CODE39_MOD43 = 6;
	public const uint32 WIA_BARCODE_CODE39_FULLASCII = 7;
	public const uint32 WIA_BARCODE_CODE93 = 8;
	public const uint32 WIA_BARCODE_CODE128 = 9;
	public const uint32 WIA_BARCODE_CODE128A = 10;
	public const uint32 WIA_BARCODE_CODE128B = 11;
	public const uint32 WIA_BARCODE_CODE128C = 12;
	public const uint32 WIA_BARCODE_GS1128 = 13;
	public const uint32 WIA_BARCODE_GS1DATABAR = 14;
	public const uint32 WIA_BARCODE_ITF14 = 15;
	public const uint32 WIA_BARCODE_EAN8 = 16;
	public const uint32 WIA_BARCODE_EAN13 = 17;
	public const uint32 WIA_BARCODE_POSTNETA = 18;
	public const uint32 WIA_BARCODE_POSTNETB = 19;
	public const uint32 WIA_BARCODE_POSTNETC = 20;
	public const uint32 WIA_BARCODE_POSTNET_DPBC = 21;
	public const uint32 WIA_BARCODE_PLANET = 22;
	public const uint32 WIA_BARCODE_INTELLIGENT_MAIL = 23;
	public const uint32 WIA_BARCODE_POSTBAR = 24;
	public const uint32 WIA_BARCODE_RM4SCC = 25;
	public const uint32 WIA_BARCODE_HIGH_CAPACITY_COLOR = 26;
	public const uint32 WIA_BARCODE_MAXICODE = 27;
	public const uint32 WIA_BARCODE_PDF417 = 28;
	public const uint32 WIA_BARCODE_CPCBINARY = 29;
	public const uint32 WIA_BARCODE_FIM = 30;
	public const uint32 WIA_BARCODE_PHARMACODE = 31;
	public const uint32 WIA_BARCODE_PLESSEY = 32;
	public const uint32 WIA_BARCODE_MSI = 33;
	public const uint32 WIA_BARCODE_JAN = 34;
	public const uint32 WIA_BARCODE_TELEPEN = 35;
	public const uint32 WIA_BARCODE_AZTEC = 36;
	public const uint32 WIA_BARCODE_SMALLAZTEC = 37;
	public const uint32 WIA_BARCODE_DATAMATRIX = 38;
	public const uint32 WIA_BARCODE_DATASTRIP = 39;
	public const uint32 WIA_BARCODE_EZCODE = 40;
	public const uint32 WIA_BARCODE_QRCODE = 41;
	public const uint32 WIA_BARCODE_SHOTCODE = 42;
	public const uint32 WIA_BARCODE_SPARQCODE = 43;
	public const uint32 WIA_BARCODE_CUSTOMBASE = 32768;
	public const uint32 WIA_PATCH_CODE_READER_DISABLED = 0;
	public const uint32 WIA_PATCH_CODE_READER_AUTO = 1;
	public const uint32 WIA_PATCH_CODE_READER_FLATBED = 2;
	public const uint32 WIA_PATCH_CODE_READER_FEEDER_FRONT = 3;
	public const uint32 WIA_PATCH_CODE_READER_FEEDER_BACK = 4;
	public const uint32 WIA_PATCH_CODE_READER_FEEDER_DUPLEX = 5;
	public const uint32 WIA_PATCH_CODE_UNKNOWN = 0;
	public const uint32 WIA_PATCH_CODE_1 = 1;
	public const uint32 WIA_PATCH_CODE_2 = 2;
	public const uint32 WIA_PATCH_CODE_3 = 3;
	public const uint32 WIA_PATCH_CODE_4 = 4;
	public const uint32 WIA_PATCH_CODE_T = 5;
	public const uint32 WIA_PATCH_CODE_6 = 6;
	public const uint32 WIA_PATCH_CODE_7 = 7;
	public const uint32 WIA_PATCH_CODE_8 = 8;
	public const uint32 WIA_PATCH_CODE_9 = 9;
	public const uint32 WIA_PATCH_CODE_10 = 10;
	public const uint32 WIA_PATCH_CODE_11 = 11;
	public const uint32 WIA_PATCH_CODE_12 = 12;
	public const uint32 WIA_PATCH_CODE_13 = 13;
	public const uint32 WIA_PATCH_CODE_14 = 14;
	public const uint32 WIA_PATCH_CODE_CUSTOM_BASE = 32768;
	public const uint32 WIA_MICR_READER_DISABLED = 0;
	public const uint32 WIA_MICR_READER_AUTO = 1;
	public const uint32 WIA_MICR_READER_FLATBED = 2;
	public const uint32 WIA_MICR_READER_FEEDER_FRONT = 3;
	public const uint32 WIA_MICR_READER_FEEDER_BACK = 4;
	public const uint32 WIA_MICR_READER_FEEDER_DUPLEX = 5;
	public const uint32 WIA_SEPARATOR_DISABLED = 0;
	public const uint32 WIA_SEPARATOR_DETECT_SCAN_CONTINUE = 1;
	public const uint32 WIA_SEPARATOR_DETECT_SCAN_STOP = 2;
	public const uint32 WIA_SEPARATOR_DETECT_NOSCAN_CONTINUE = 3;
	public const uint32 WIA_SEPARATOR_DETECT_NOSCAN_STOP = 4;
	public const uint32 WIA_LONG_DOCUMENT_DISABLED = 0;
	public const uint32 WIA_LONG_DOCUMENT_ENABLED = 1;
	public const uint32 WIA_LONG_DOCUMENT_SPLIT = 2;
	public const uint32 WIA_BLANK_PAGE_DETECTION_DISABLED = 0;
	public const uint32 WIA_BLANK_PAGE_DISCARD = 1;
	public const uint32 WIA_BLANK_PAGE_JOB_SEPARATOR = 2;
	public const uint32 WIA_MULTI_FEED_DETECT_DISABLED = 0;
	public const uint32 WIA_MULTI_FEED_DETECT_STOP_ERROR = 1;
	public const uint32 WIA_MULTI_FEED_DETECT_STOP_SUCCESS = 2;
	public const uint32 WIA_MULTI_FEED_DETECT_CONTINUE = 3;
	public const uint32 WIA_MULTI_FEED_DETECT_METHOD_LENGTH = 0;
	public const uint32 WIA_MULTI_FEED_DETECT_METHOD_OVERLAP = 1;
	public const uint32 WIA_AUTO_CROP_DISABLED = 0;
	public const uint32 WIA_AUTO_CROP_SINGLE = 1;
	public const uint32 WIA_AUTO_CROP_MULTI = 2;
	public const uint32 WIA_OVER_SCAN_DISABLED = 0;
	public const uint32 WIA_OVER_SCAN_TOP_BOTTOM = 1;
	public const uint32 WIA_OVER_SCAN_LEFT_RIGHT = 2;
	public const uint32 WIA_OVER_SCAN_ALL = 3;
	public const uint32 WIA_COLOR_DROP_DISABLED = 0;
	public const uint32 WIA_COLOR_DROP_RED = 1;
	public const uint32 WIA_COLOR_DROP_GREEN = 2;
	public const uint32 WIA_COLOR_DROP_BLUE = 3;
	public const uint32 WIA_COLOR_DROP_RGB = 4;
	public const uint32 WIA_SCAN_AHEAD_DISABLED = 0;
	public const uint32 WIA_SCAN_AHEAD_ENABLED = 1;
	public const uint32 WIA_FEEDER_CONTROL_AUTO = 0;
	public const uint32 WIA_FEEDER_CONTROL_MANUAL = 1;
	public const uint32 WIA_PRINT_PADDING_NONE = 0;
	public const uint32 WIA_PRINT_PADDING_ZERO = 1;
	public const uint32 WIA_PRINT_PADDING_BLANK = 2;
	public const uint32 WIA_PRINT_FONT_NORMAL = 0;
	public const uint32 WIA_PRINT_FONT_BOLD = 1;
	public const uint32 WIA_PRINT_FONT_EXTRA_BOLD = 2;
	public const uint32 WIA_PRINT_FONT_ITALIC_BOLD = 3;
	public const uint32 WIA_PRINT_FONT_ITALIC_EXTRA_BOLD = 4;
	public const uint32 WIA_PRINT_FONT_ITALIC = 5;
	public const uint32 WIA_PRINT_FONT_SMALL = 6;
	public const uint32 WIA_PRINT_FONT_SMALL_BOLD = 7;
	public const uint32 WIA_PRINT_FONT_SMALL_EXTRA_BOLD = 8;
	public const uint32 WIA_PRINT_FONT_SMALL_ITALIC_BOLD = 9;
	public const uint32 WIA_PRINT_FONT_SMALL_ITALIC_EXTRA_BOLD = 10;
	public const uint32 WIA_PRINT_FONT_SMALL_ITALIC = 11;
	public const uint32 WIA_PRINT_FONT_LARGE = 12;
	public const uint32 WIA_PRINT_FONT_LARGE_BOLD = 13;
	public const uint32 WIA_PRINT_FONT_LARGE_EXTRA_BOLD = 14;
	public const uint32 WIA_PRINT_FONT_LARGE_ITALIC_BOLD = 15;
	public const uint32 WIA_PRINT_FONT_LARGE_ITALIC_EXTRA_BOLD = 16;
	public const uint32 WIA_PRINT_FONT_LARGE_ITALIC = 17;
	public const uint32 WIA_ALARM_NONE = 0;
	public const uint32 WIA_ALARM_BEEP1 = 1;
	public const uint32 WIA_ALARM_BEEP2 = 2;
	public const uint32 WIA_ALARM_BEEP3 = 3;
	public const uint32 WIA_ALARM_BEEP4 = 4;
	public const uint32 WIA_ALARM_BEEP5 = 5;
	public const uint32 WIA_ALARM_BEEP6 = 6;
	public const uint32 WIA_ALARM_BEEP7 = 7;
	public const uint32 WIA_ALARM_BEEP8 = 8;
	public const uint32 WIA_ALARM_BEEP9 = 9;
	public const uint32 WIA_ALARM_BEEP10 = 10;
	public const uint32 WIA_PRIVATE_DEVPROP = 38914;
	public const uint32 WIA_PRIVATE_ITEMPROP = 71682;
	public const Guid WiaImgFmt_UNDEFINED = .(0xb96b3ca9, 0x0728, 0x11d3, 0x9d, 0x7b, 0x00, 0x00, 0xf8, 0x1e, 0xf3, 0x2e);
	public const Guid WiaImgFmt_RAWRGB = .(0xbca48b55, 0xf272, 0x4371, 0xb0, 0xf1, 0x4a, 0x15, 0x0d, 0x05, 0x7b, 0xb4);
	public const Guid WiaImgFmt_MEMORYBMP = .(0xb96b3caa, 0x0728, 0x11d3, 0x9d, 0x7b, 0x00, 0x00, 0xf8, 0x1e, 0xf3, 0x2e);
	public const Guid WiaImgFmt_BMP = .(0xb96b3cab, 0x0728, 0x11d3, 0x9d, 0x7b, 0x00, 0x00, 0xf8, 0x1e, 0xf3, 0x2e);
	public const Guid WiaImgFmt_EMF = .(0xb96b3cac, 0x0728, 0x11d3, 0x9d, 0x7b, 0x00, 0x00, 0xf8, 0x1e, 0xf3, 0x2e);
	public const Guid WiaImgFmt_WMF = .(0xb96b3cad, 0x0728, 0x11d3, 0x9d, 0x7b, 0x00, 0x00, 0xf8, 0x1e, 0xf3, 0x2e);
	public const Guid WiaImgFmt_JPEG = .(0xb96b3cae, 0x0728, 0x11d3, 0x9d, 0x7b, 0x00, 0x00, 0xf8, 0x1e, 0xf3, 0x2e);
	public const Guid WiaImgFmt_PNG = .(0xb96b3caf, 0x0728, 0x11d3, 0x9d, 0x7b, 0x00, 0x00, 0xf8, 0x1e, 0xf3, 0x2e);
	public const Guid WiaImgFmt_GIF = .(0xb96b3cb0, 0x0728, 0x11d3, 0x9d, 0x7b, 0x00, 0x00, 0xf8, 0x1e, 0xf3, 0x2e);
	public const Guid WiaImgFmt_TIFF = .(0xb96b3cb1, 0x0728, 0x11d3, 0x9d, 0x7b, 0x00, 0x00, 0xf8, 0x1e, 0xf3, 0x2e);
	public const Guid WiaImgFmt_EXIF = .(0xb96b3cb2, 0x0728, 0x11d3, 0x9d, 0x7b, 0x00, 0x00, 0xf8, 0x1e, 0xf3, 0x2e);
	public const Guid WiaImgFmt_PHOTOCD = .(0xb96b3cb3, 0x0728, 0x11d3, 0x9d, 0x7b, 0x00, 0x00, 0xf8, 0x1e, 0xf3, 0x2e);
	public const Guid WiaImgFmt_FLASHPIX = .(0xb96b3cb4, 0x0728, 0x11d3, 0x9d, 0x7b, 0x00, 0x00, 0xf8, 0x1e, 0xf3, 0x2e);
	public const Guid WiaImgFmt_ICO = .(0xb96b3cb5, 0x0728, 0x11d3, 0x9d, 0x7b, 0x00, 0x00, 0xf8, 0x1e, 0xf3, 0x2e);
	public const Guid WiaImgFmt_CIFF = .(0x9821a8ab, 0x3a7e, 0x4215, 0x94, 0xe0, 0xd2, 0x7a, 0x46, 0x0c, 0x03, 0xb2);
	public const Guid WiaImgFmt_PICT = .(0xa6bc85d8, 0x6b3e, 0x40ee, 0xa9, 0x5c, 0x25, 0xd4, 0x82, 0xe4, 0x1a, 0xdc);
	public const Guid WiaImgFmt_JPEG2K = .(0x344ee2b2, 0x39db, 0x4dde, 0x81, 0x73, 0xc4, 0xb7, 0x5f, 0x8f, 0x1e, 0x49);
	public const Guid WiaImgFmt_JPEG2KX = .(0x43e14614, 0xc80a, 0x4850, 0xba, 0xf3, 0x4b, 0x15, 0x2d, 0xc8, 0xda, 0x27);
	public const Guid WiaImgFmt_RAW = .(0x6f120719, 0xf1a8, 0x4e07, 0x9a, 0xde, 0x9b, 0x64, 0xc6, 0x3a, 0x3d, 0xcc);
	public const Guid WiaImgFmt_JBIG = .(0x41e8dd92, 0x2f0a, 0x43d4, 0x86, 0x36, 0xf1, 0x61, 0x4b, 0xa1, 0x1e, 0x46);
	public const Guid WiaImgFmt_JBIG2 = .(0xbb8e7e67, 0x283c, 0x4235, 0x9e, 0x59, 0x0b, 0x9b, 0xf9, 0x4c, 0xa6, 0x87);
	public const Guid WiaImgFmt_RTF = .(0x573dd6a3, 0x4834, 0x432d, 0xa9, 0xb5, 0xe1, 0x98, 0xdd, 0x9e, 0x89, 0x0d);
	public const Guid WiaImgFmt_XML = .(0xb9171457, 0xdac8, 0x4884, 0xb3, 0x93, 0x15, 0xb4, 0x71, 0xd5, 0xf0, 0x7e);
	public const Guid WiaImgFmt_HTML = .(0xc99a4e62, 0x99de, 0x4a94, 0xac, 0xca, 0x71, 0x95, 0x6a, 0xc2, 0x97, 0x7d);
	public const Guid WiaImgFmt_TXT = .(0xfafd4d82, 0x723f, 0x421f, 0x93, 0x18, 0x30, 0x50, 0x1a, 0xc4, 0x4b, 0x59);
	public const Guid WiaImgFmt_PDFA = .(0x9980bd5b, 0x3463, 0x43c7, 0xbd, 0xca, 0x3c, 0xaa, 0x14, 0x6f, 0x22, 0x9f);
	public const Guid WiaImgFmt_XPS = .(0x700b4a0f, 0x2011, 0x411c, 0xb4, 0x30, 0xd1, 0xe0, 0xb2, 0xe1, 0x0b, 0x28);
	public const Guid WiaImgFmt_OXPS = .(0x2c7b1240, 0xc14d, 0x4109, 0x97, 0x55, 0x04, 0xb8, 0x90, 0x25, 0x15, 0x3a);
	public const Guid WiaImgFmt_CSV = .(0x355bda24, 0x5a9f, 0x4494, 0x80, 0xdc, 0xbe, 0x75, 0x2c, 0xec, 0xbc, 0x8c);
	public const Guid WiaImgFmt_MPG = .(0xecd757e4, 0xd2ec, 0x4f57, 0x95, 0x5d, 0xbc, 0xf8, 0xa9, 0x7c, 0x4e, 0x52);
	public const Guid WiaImgFmt_AVI = .(0x32f8ca14, 0x087c, 0x4908, 0xb7, 0xc4, 0x67, 0x57, 0xfe, 0x7e, 0x90, 0xab);
	public const Guid WiaAudFmt_WAV = .(0xf818e146, 0x07af, 0x40ff, 0xae, 0x55, 0xbe, 0x8f, 0x2c, 0x06, 0x5d, 0xbe);
	public const Guid WiaAudFmt_MP3 = .(0x0fbc71fb, 0x43bf, 0x49f2, 0x91, 0x90, 0xe6, 0xfe, 0xcf, 0xf3, 0x7e, 0x54);
	public const Guid WiaAudFmt_AIFF = .(0x66e2bf4f, 0xb6fc, 0x443f, 0x94, 0xc8, 0x2f, 0x33, 0xc8, 0xa6, 0x5a, 0xaf);
	public const Guid WiaAudFmt_WMA = .(0xd61d6413, 0x8bc2, 0x438f, 0x93, 0xad, 0x21, 0xbd, 0x48, 0x4d, 0xb6, 0xa1);
	public const Guid WiaImgFmt_ASF = .(0x8d948ee9, 0xd0aa, 0x4a12, 0x9d, 0x9a, 0x9c, 0xc5, 0xde, 0x36, 0x19, 0x9b);
	public const Guid WiaImgFmt_SCRIPT = .(0xfe7d6c53, 0x2dac, 0x446a, 0xb0, 0xbd, 0xd7, 0x3e, 0x21, 0xe9, 0x24, 0xc9);
	public const Guid WiaImgFmt_EXEC = .(0x485da097, 0x141e, 0x4aa5, 0xbb, 0x3b, 0xa5, 0x61, 0x8d, 0x95, 0xd0, 0x2b);
	public const Guid WiaImgFmt_UNICODE16 = .(0x1b7639b6, 0x6357, 0x47d1, 0x9a, 0x07, 0x12, 0x45, 0x2d, 0xc0, 0x73, 0xe9);
	public const Guid WiaImgFmt_DPOF = .(0x369eeeab, 0xa0e8, 0x45ca, 0x86, 0xa6, 0xa8, 0x3c, 0xe5, 0x69, 0x7e, 0x28);
	public const Guid WiaImgFmt_XMLBAR = .(0x6235701c, 0x3a98, 0x484c, 0xb2, 0xa8, 0xfd, 0xff, 0xd8, 0x7e, 0x6b, 0x16);
	public const Guid WiaImgFmt_RAWBAR = .(0xda63f833, 0xd26e, 0x451e, 0x90, 0xd2, 0xea, 0x55, 0xa1, 0x36, 0x5d, 0x62);
	public const Guid WiaImgFmt_XMLPAT = .(0xf8986f55, 0xf052, 0x460d, 0x95, 0x23, 0x3a, 0x7d, 0xfe, 0xdb, 0xb3, 0x3c);
	public const Guid WiaImgFmt_RAWPAT = .(0x7760507c, 0x5064, 0x400c, 0x9a, 0x17, 0x57, 0x56, 0x24, 0xd8, 0x82, 0x4b);
	public const Guid WiaImgFmt_XMLMIC = .(0x2d164c61, 0xb9ae, 0x4b23, 0x89, 0x73, 0xc7, 0x06, 0x7e, 0x1f, 0xbd, 0x31);
	public const Guid WiaImgFmt_RAWMIC = .(0x22c4f058, 0x0d88, 0x409c, 0xac, 0x1c, 0xee, 0xc1, 0x2b, 0x0e, 0xa6, 0x80);
	public const Guid WIA_EVENT_DEVICE_DISCONNECTED = .(0x143e4e83, 0x6497, 0x11d2, 0xa2, 0x31, 0x00, 0xc0, 0x4f, 0xa3, 0x18, 0x09);
	public const Guid WIA_EVENT_DEVICE_CONNECTED = .(0xa28bbade, 0x64b6, 0x11d2, 0xa2, 0x31, 0x00, 0xc0, 0x4f, 0xa3, 0x18, 0x09);
	public const Guid WIA_EVENT_ITEM_DELETED = .(0x1d22a559, 0xe14f, 0x11d2, 0xb3, 0x26, 0x00, 0xc0, 0x4f, 0x68, 0xce, 0x61);
	public const Guid WIA_EVENT_ITEM_CREATED = .(0x4c8f4ef5, 0xe14f, 0x11d2, 0xb3, 0x26, 0x00, 0xc0, 0x4f, 0x68, 0xce, 0x61);
	public const Guid WIA_EVENT_TREE_UPDATED = .(0xc9859b91, 0x4ab2, 0x4cd6, 0xa1, 0xfc, 0x58, 0x2e, 0xec, 0x55, 0xe5, 0x85);
	public const Guid WIA_EVENT_VOLUME_INSERT = .(0x9638bbfd, 0xd1bd, 0x11d2, 0xb3, 0x1f, 0x00, 0xc0, 0x4f, 0x68, 0xce, 0x61);
	public const Guid WIA_EVENT_SCAN_IMAGE = .(0xa6c5a715, 0x8c6e, 0x11d2, 0x97, 0x7a, 0x00, 0x00, 0xf8, 0x7a, 0x92, 0x6f);
	public const Guid WIA_EVENT_SCAN_PRINT_IMAGE = .(0xb441f425, 0x8c6e, 0x11d2, 0x97, 0x7a, 0x00, 0x00, 0xf8, 0x7a, 0x92, 0x6f);
	public const Guid WIA_EVENT_SCAN_FAX_IMAGE = .(0xc00eb793, 0x8c6e, 0x11d2, 0x97, 0x7a, 0x00, 0x00, 0xf8, 0x7a, 0x92, 0x6f);
	public const Guid WIA_EVENT_SCAN_OCR_IMAGE = .(0x9d095b89, 0x37d6, 0x4877, 0xaf, 0xed, 0x62, 0xa2, 0x97, 0xdc, 0x6d, 0xbe);
	public const Guid WIA_EVENT_SCAN_EMAIL_IMAGE = .(0xc686dcee, 0x54f2, 0x419e, 0x9a, 0x27, 0x2f, 0xc7, 0xf2, 0xe9, 0x8f, 0x9e);
	public const Guid WIA_EVENT_SCAN_FILM_IMAGE = .(0x9b2b662c, 0x6185, 0x438c, 0xb6, 0x8b, 0xe3, 0x9e, 0xe2, 0x5e, 0x71, 0xcb);
	public const Guid WIA_EVENT_SCAN_IMAGE2 = .(0xfc4767c1, 0xc8b3, 0x48a2, 0x9c, 0xfa, 0x2e, 0x90, 0xcb, 0x3d, 0x35, 0x90);
	public const Guid WIA_EVENT_SCAN_IMAGE3 = .(0x154e27be, 0xb617, 0x4653, 0xac, 0xc5, 0x0f, 0xd7, 0xbd, 0x4c, 0x65, 0xce);
	public const Guid WIA_EVENT_SCAN_IMAGE4 = .(0xa65b704a, 0x7f3c, 0x4447, 0xa7, 0x5d, 0x8a, 0x26, 0xdf, 0xca, 0x1f, 0xdf);
	public const Guid WIA_EVENT_STORAGE_CREATED = .(0x353308b2, 0xfe73, 0x46c8, 0x89, 0x5e, 0xfa, 0x45, 0x51, 0xcc, 0xc8, 0x5a);
	public const Guid WIA_EVENT_STORAGE_DELETED = .(0x5e41e75e, 0x9390, 0x44c5, 0x9a, 0x51, 0xe4, 0x70, 0x19, 0xe3, 0x90, 0xcf);
	public const Guid WIA_EVENT_STI_PROXY = .(0xd711f81f, 0x1f0d, 0x422d, 0x86, 0x41, 0x92, 0x7d, 0x1b, 0x93, 0xe5, 0xe5);
	public const Guid WIA_EVENT_CANCEL_IO = .(0xc860f7b8, 0x9ccd, 0x41ea, 0xbb, 0xbf, 0x4d, 0xd0, 0x9c, 0x5b, 0x17, 0x95);
	public const Guid WIA_EVENT_POWER_SUSPEND = .(0xa0922ff9, 0xc3b4, 0x411c, 0x9e, 0x29, 0x03, 0xa6, 0x69, 0x93, 0xd2, 0xbe);
	public const Guid WIA_EVENT_POWER_RESUME = .(0x618f153e, 0xf686, 0x4350, 0x96, 0x34, 0x41, 0x15, 0xa3, 0x04, 0x83, 0x0c);
	public const Guid WIA_EVENT_HANDLER_NO_ACTION = .(0xe0372b7d, 0xe115, 0x4525, 0xbc, 0x55, 0xb6, 0x29, 0xe6, 0x8c, 0x74, 0x5a);
	public const Guid WIA_EVENT_HANDLER_PROMPT = .(0x5f4baad0, 0x4d59, 0x4fcd, 0xb2, 0x13, 0x78, 0x3c, 0xe7, 0xa9, 0x2f, 0x22);
	public const Guid WIA_EVENT_DEVICE_NOT_READY = .(0xd8962d7e, 0xe4dc, 0x4b4d, 0xba, 0x29, 0x66, 0x8a, 0x87, 0xf4, 0x2e, 0x6f);
	public const Guid WIA_EVENT_DEVICE_READY = .(0x7523ec6c, 0x988b, 0x419e, 0x9a, 0x0a, 0x42, 0x5a, 0xc3, 0x1b, 0x37, 0xdc);
	public const Guid WIA_EVENT_FLATBED_LID_OPEN = .(0xba0a0623, 0x437d, 0x4f03, 0xa9, 0x7d, 0x77, 0x93, 0xb1, 0x23, 0x11, 0x3c);
	public const Guid WIA_EVENT_FLATBED_LID_CLOSED = .(0xf879af0f, 0x9b29, 0x4283, 0xad, 0x95, 0xd4, 0x12, 0x16, 0x4d, 0x39, 0xa9);
	public const Guid WIA_EVENT_FEEDER_LOADED = .(0xcc8d701e, 0x9aba, 0x481d, 0xbf, 0x74, 0x78, 0xf7, 0x63, 0xdc, 0x34, 0x2a);
	public const Guid WIA_EVENT_FEEDER_EMPTIED = .(0xe70b4b82, 0x6dda, 0x46bb, 0x8f, 0xf9, 0x53, 0xce, 0xb1, 0xa0, 0x3e, 0x35);
	public const Guid WIA_EVENT_COVER_OPEN = .(0x19a12136, 0xfa1c, 0x4f66, 0x90, 0x0f, 0x8f, 0x91, 0x4e, 0xc7, 0x4e, 0xc9);
	public const Guid WIA_EVENT_COVER_CLOSED = .(0x6714a1e6, 0xe285, 0x468c, 0x9b, 0x8c, 0xda, 0x7d, 0xc4, 0xcb, 0xaa, 0x05);
	public const Guid WIA_CMD_SYNCHRONIZE = .(0x9b26b7b2, 0xacad, 0x11d2, 0xa0, 0x93, 0x00, 0xc0, 0x4f, 0x72, 0xdc, 0x3c);
	public const Guid WIA_CMD_TAKE_PICTURE = .(0xaf933cac, 0xacad, 0x11d2, 0xa0, 0x93, 0x00, 0xc0, 0x4f, 0x72, 0xdc, 0x3c);
	public const Guid WIA_CMD_DELETE_ALL_ITEMS = .(0xe208c170, 0xacad, 0x11d2, 0xa0, 0x93, 0x00, 0xc0, 0x4f, 0x72, 0xdc, 0x3c);
	public const Guid WIA_CMD_CHANGE_DOCUMENT = .(0x04e725b0, 0xacae, 0x11d2, 0xa0, 0x93, 0x00, 0xc0, 0x4f, 0x72, 0xdc, 0x3c);
	public const Guid WIA_CMD_UNLOAD_DOCUMENT = .(0x1f3b3d8e, 0xacae, 0x11d2, 0xa0, 0x93, 0x00, 0xc0, 0x4f, 0x72, 0xdc, 0x3c);
	public const Guid WIA_CMD_DIAGNOSTIC = .(0x10ff52f5, 0xde04, 0x4cf0, 0xa5, 0xad, 0x69, 0x1f, 0x8d, 0xce, 0x01, 0x41);
	public const Guid WIA_CMD_FORMAT = .(0xc3a693aa, 0xf788, 0x4d34, 0xa5, 0xb0, 0xbe, 0x71, 0x90, 0x75, 0x9a, 0x24);
	public const Guid WIA_CMD_DELETE_DEVICE_TREE = .(0x73815942, 0xdbea, 0x11d2, 0x84, 0x16, 0x00, 0xc0, 0x4f, 0xa3, 0x61, 0x45);
	public const Guid WIA_CMD_BUILD_DEVICE_TREE = .(0x9cba5ce0, 0xdbea, 0x11d2, 0x84, 0x16, 0x00, 0xc0, 0x4f, 0xa3, 0x61, 0x45);
	public const Guid WIA_CMD_START_FEEDER = .(0x5a9df6c9, 0x5f2d, 0x4a39, 0x9d, 0x6c, 0x00, 0x45, 0x6d, 0x04, 0x7f, 0x00);
	public const Guid WIA_CMD_STOP_FEEDER = .(0xd847b06d, 0x3905, 0x459c, 0x95, 0x09, 0x9b, 0x29, 0xcd, 0xb6, 0x91, 0xe7);
	public const Guid WIA_CMD_PAUSE_FEEDER = .(0x50985e4d, 0xa5b2, 0x4b71, 0x9c, 0x95, 0x6d, 0x7d, 0x7c, 0x46, 0x9a, 0x43);
	public const uint32 BASE_VAL_WIA_ERROR = 0;
	public const uint32 BASE_VAL_WIA_SUCCESS = 0;
	public const HRESULT WIA_ERROR_GENERAL_ERROR = -2145320959;
	public const HRESULT WIA_ERROR_PAPER_JAM = -2145320958;
	public const HRESULT WIA_ERROR_PAPER_EMPTY = -2145320957;
	public const HRESULT WIA_ERROR_PAPER_PROBLEM = -2145320956;
	public const HRESULT WIA_ERROR_OFFLINE = -2145320955;
	public const HRESULT WIA_ERROR_BUSY = -2145320954;
	public const HRESULT WIA_ERROR_WARMING_UP = -2145320953;
	public const HRESULT WIA_ERROR_USER_INTERVENTION = -2145320952;
	public const HRESULT WIA_ERROR_ITEM_DELETED = -2145320951;
	public const HRESULT WIA_ERROR_DEVICE_COMMUNICATION = -2145320950;
	public const HRESULT WIA_ERROR_INVALID_COMMAND = -2145320949;
	public const HRESULT WIA_ERROR_INCORRECT_HARDWARE_SETTING = -2145320948;
	public const HRESULT WIA_ERROR_DEVICE_LOCKED = -2145320947;
	public const HRESULT WIA_ERROR_EXCEPTION_IN_DRIVER = -2145320946;
	public const HRESULT WIA_ERROR_INVALID_DRIVER_RESPONSE = -2145320945;
	public const HRESULT WIA_ERROR_COVER_OPEN = -2145320944;
	public const HRESULT WIA_ERROR_LAMP_OFF = -2145320943;
	public const HRESULT WIA_ERROR_DESTINATION = -2145320942;
	public const HRESULT WIA_ERROR_NETWORK_RESERVATION_FAILED = -2145320941;
	public const HRESULT WIA_ERROR_MULTI_FEED = -2145320940;
	public const HRESULT WIA_ERROR_MAXIMUM_PRINTER_ENDORSER_COUNTER = -2145320939;
	public const HRESULT WIA_STATUS_END_OF_MEDIA = 2162689;
	public const HRESULT WIA_STATUS_WARMING_UP = 2162690;
	public const HRESULT WIA_STATUS_CALIBRATING = 2162691;
	public const HRESULT WIA_STATUS_RESERVING_NETWORK_DEVICE = 2162694;
	public const HRESULT WIA_STATUS_NETWORK_DEVICE_RESERVED = 2162695;
	public const HRESULT WIA_STATUS_CLEAR = 2162696;
	public const HRESULT WIA_STATUS_SKIP_ITEM = 2162697;
	public const HRESULT WIA_STATUS_NOT_HANDLED = 2162698;
	public const HRESULT WIA_S_CHANGE_DEVICE = 2162699;
	public const HRESULT WIA_S_NO_DEVICE_AVAILABLE = -2145320939;
	public const uint32 WIA_SELECT_DEVICE_NODEFAULT = 1;
	public const uint32 WIA_DEVICE_DIALOG_SINGLE_IMAGE = 2;
	public const uint32 WIA_DEVICE_DIALOG_USE_COMMON_UI = 4;
	public const uint32 WIA_REGISTER_EVENT_CALLBACK = 1;
	public const uint32 WIA_UNREGISTER_EVENT_CALLBACK = 2;
	public const uint32 WIA_SET_DEFAULT_HANDLER = 4;
	public const uint32 WIA_NOTIFICATION_EVENT = 1;
	public const uint32 WIA_ACTION_EVENT = 2;
	public const uint32 WIA_LINE_ORDER_TOP_TO_BOTTOM = 1;
	public const uint32 WIA_LINE_ORDER_BOTTOM_TO_TOP = 2;
	public const uint32 WIA_IS_DEFAULT_HANDLER = 1;
	public const String WIA_EVENT_DEVICE_DISCONNECTED_STR = "Device Disconnected";
	public const String WIA_EVENT_DEVICE_CONNECTED_STR = "Device Connected";
	public const uint32 TYMED_CALLBACK = 128;
	public const uint32 TYMED_MULTIPAGE_FILE = 256;
	public const uint32 TYMED_MULTIPAGE_CALLBACK = 512;
	public const uint32 IT_MSG_DATA_HEADER = 1;
	public const uint32 IT_MSG_DATA = 2;
	public const uint32 IT_MSG_STATUS = 3;
	public const uint32 IT_MSG_TERMINATION = 4;
	public const uint32 IT_MSG_NEW_PAGE = 5;
	public const uint32 IT_MSG_FILE_PREVIEW_DATA = 6;
	public const uint32 IT_MSG_FILE_PREVIEW_DATA_HEADER = 7;
	public const uint32 IT_STATUS_TRANSFER_FROM_DEVICE = 1;
	public const uint32 IT_STATUS_PROCESSING_DATA = 2;
	public const uint32 IT_STATUS_TRANSFER_TO_CLIENT = 4;
	public const uint32 IT_STATUS_MASK = 7;
	public const uint32 WIA_TRANSFER_ACQUIRE_CHILDREN = 1;
	public const uint32 WIA_TRANSFER_MSG_STATUS = 1;
	public const uint32 WIA_TRANSFER_MSG_END_OF_STREAM = 2;
	public const uint32 WIA_TRANSFER_MSG_END_OF_TRANSFER = 3;
	public const uint32 WIA_TRANSFER_MSG_DEVICE_STATUS = 5;
	public const uint32 WIA_TRANSFER_MSG_NEW_PAGE = 6;
	public const uint32 WIA_MAJOR_EVENT_DEVICE_CONNECT = 1;
	public const uint32 WIA_MAJOR_EVENT_DEVICE_DISCONNECT = 2;
	public const uint32 WIA_MAJOR_EVENT_PICTURE_TAKEN = 3;
	public const uint32 WIA_MAJOR_EVENT_PICTURE_DELETED = 4;
	public const uint32 WIA_DEVICE_NOT_CONNECTED = 0;
	public const uint32 WIA_DEVICE_CONNECTED = 1;
	public const uint32 WIA_DEVICE_COMMANDS = 1;
	public const uint32 WIA_DEVICE_EVENTS = 2;
	public const uint32 WIA_DEVINFO_ENUM_ALL = 15;
	public const uint32 WIA_DEVINFO_ENUM_LOCAL = 16;
	public const uint32 WiaItemTypeFree = 0;
	public const uint32 WiaItemTypeImage = 1;
	public const uint32 WiaItemTypeFile = 2;
	public const uint32 WiaItemTypeFolder = 4;
	public const uint32 WiaItemTypeRoot = 8;
	public const uint32 WiaItemTypeAnalyze = 16;
	public const uint32 WiaItemTypeAudio = 32;
	public const uint32 WiaItemTypeDevice = 64;
	public const uint32 WiaItemTypeDeleted = 128;
	public const uint32 WiaItemTypeDisconnected = 256;
	public const uint32 WiaItemTypeHPanorama = 512;
	public const uint32 WiaItemTypeVPanorama = 1024;
	public const uint32 WiaItemTypeBurst = 2048;
	public const uint32 WiaItemTypeStorage = 4096;
	public const uint32 WiaItemTypeTransfer = 8192;
	public const uint32 WiaItemTypeGenerated = 16384;
	public const uint32 WiaItemTypeHasAttachments = 32768;
	public const uint32 WiaItemTypeVideo = 65536;
	public const uint32 WiaItemTypeRemoved = 2147483648;
	public const uint32 WiaItemTypeDocument = 262144;
	public const uint32 WiaItemTypeProgrammableDataSource = 524288;
	public const uint32 WiaItemTypeMask = 2148532223;
	public const uint32 WIA_MAX_CTX_SIZE = 16777216;
	public const uint32 WIA_PROP_READ = 1;
	public const uint32 WIA_PROP_WRITE = 2;
	public const uint32 WIA_PROP_SYNC_REQUIRED = 4;
	public const uint32 WIA_PROP_NONE = 8;
	public const uint32 WIA_PROP_RANGE = 16;
	public const uint32 WIA_PROP_LIST = 32;
	public const uint32 WIA_PROP_FLAG = 64;
	public const uint32 WIA_PROP_CACHEABLE = 65536;
	public const uint32 COPY_PARENT_PROPERTY_VALUES = 1073741824;
	public const uint32 WIA_ITEM_CAN_BE_DELETED = 128;
	public const uint32 WIA_ITEM_READ = 1;
	public const uint32 WIA_ITEM_WRITE = 2;
	public const uint32 WIA_RANGE_MIN = 0;
	public const uint32 WIA_RANGE_NOM = 1;
	public const uint32 WIA_RANGE_MAX = 2;
	public const uint32 WIA_RANGE_STEP = 3;
	public const uint32 WIA_RANGE_NUM_ELEMS = 4;
	public const uint32 WIA_LIST_COUNT = 0;
	public const uint32 WIA_LIST_NOM = 1;
	public const uint32 WIA_LIST_VALUES = 2;
	public const uint32 WIA_LIST_NUM_ELEMS = 2;
	public const uint32 WIA_FLAG_NOM = 0;
	public const uint32 WIA_FLAG_VALUES = 1;
	public const uint32 WIA_FLAG_NUM_ELEMS = 2;
	public const uint32 WIA_DIP_FIRST = 2;
	public const uint32 WIA_IPA_FIRST = 4098;
	public const uint32 WIA_DPF_FIRST = 3330;
	public const uint32 WIA_IPS_FIRST = 6146;
	public const uint32 WIA_DPS_FIRST = 3074;
	public const uint32 WIA_IPC_FIRST = 5122;
	public const uint32 WIA_NUM_IPC = 9;
	public const uint32 WIA_RESERVED_FOR_NEW_PROPS = 1024;
	public const uint32 WHITEBALANCE_MANUAL = 1;
	public const uint32 WHITEBALANCE_AUTO = 2;
	public const uint32 WHITEBALANCE_ONEPUSH_AUTO = 3;
	public const uint32 WHITEBALANCE_DAYLIGHT = 4;
	public const uint32 WHITEBALANCE_FLORESCENT = 5;
	public const uint32 WHITEBALANCE_TUNGSTEN = 6;
	public const uint32 WHITEBALANCE_FLASH = 7;
	public const uint32 FOCUSMODE_MANUAL = 1;
	public const uint32 FOCUSMODE_AUTO = 2;
	public const uint32 FOCUSMODE_MACROAUTO = 3;
	public const uint32 EXPOSUREMETERING_AVERAGE = 1;
	public const uint32 EXPOSUREMETERING_CENTERWEIGHT = 2;
	public const uint32 EXPOSUREMETERING_MULTISPOT = 3;
	public const uint32 EXPOSUREMETERING_CENTERSPOT = 4;
	public const uint32 FLASHMODE_AUTO = 1;
	public const uint32 FLASHMODE_OFF = 2;
	public const uint32 FLASHMODE_FILL = 3;
	public const uint32 FLASHMODE_REDEYE_AUTO = 4;
	public const uint32 FLASHMODE_REDEYE_FILL = 5;
	public const uint32 FLASHMODE_EXTERNALSYNC = 6;
	public const uint32 EXPOSUREMODE_MANUAL = 1;
	public const uint32 EXPOSUREMODE_AUTO = 2;
	public const uint32 EXPOSUREMODE_APERTURE_PRIORITY = 3;
	public const uint32 EXPOSUREMODE_SHUTTER_PRIORITY = 4;
	public const uint32 EXPOSUREMODE_PROGRAM_CREATIVE = 5;
	public const uint32 EXPOSUREMODE_PROGRAM_ACTION = 6;
	public const uint32 EXPOSUREMODE_PORTRAIT = 7;
	public const uint32 CAPTUREMODE_NORMAL = 1;
	public const uint32 CAPTUREMODE_BURST = 2;
	public const uint32 CAPTUREMODE_TIMELAPSE = 3;
	public const uint32 EFFECTMODE_STANDARD = 1;
	public const uint32 EFFECTMODE_BW = 2;
	public const uint32 EFFECTMODE_SEPIA = 3;
	public const uint32 FOCUSMETERING_CENTERSPOT = 1;
	public const uint32 FOCUSMETERING_MULTISPOT = 2;
	public const uint32 POWERMODE_LINE = 1;
	public const uint32 POWERMODE_BATTERY = 2;
	public const uint32 LEFT_JUSTIFIED = 0;
	public const uint32 CENTERED = 1;
	public const uint32 RIGHT_JUSTIFIED = 2;
	public const uint32 TOP_JUSTIFIED = 0;
	public const uint32 BOTTOM_JUSTIFIED = 2;
	public const uint32 PORTRAIT = 0;
	public const uint32 LANSCAPE = 1;
	public const uint32 LANDSCAPE = 1;
	public const uint32 ROT180 = 2;
	public const uint32 ROT270 = 3;
	public const uint32 MIRRORED = 1;
	public const uint32 FEED = 1;
	public const uint32 FLAT = 2;
	public const uint32 DUP = 4;
	public const uint32 DETECT_FLAT = 8;
	public const uint32 DETECT_SCAN = 16;
	public const uint32 DETECT_FEED = 32;
	public const uint32 DETECT_DUP = 64;
	public const uint32 DETECT_FEED_AVAIL = 128;
	public const uint32 DETECT_DUP_AVAIL = 256;
	public const uint32 FILM_TPA = 512;
	public const uint32 DETECT_FILM_TPA = 1024;
	public const uint32 STOR = 2048;
	public const uint32 DETECT_STOR = 4096;
	public const uint32 ADVANCED_DUP = 8192;
	public const uint32 AUTO_SOURCE = 32768;
	public const uint32 IMPRINTER = 65536;
	public const uint32 ENDORSER = 131072;
	public const uint32 BARCODE_READER = 262144;
	public const uint32 PATCH_CODE_READER = 524288;
	public const uint32 MICR_READER = 1048576;
	public const uint32 FEED_READY = 1;
	public const uint32 FLAT_READY = 2;
	public const uint32 DUP_READY = 4;
	public const uint32 FLAT_COVER_UP = 8;
	public const uint32 PATH_COVER_UP = 16;
	public const uint32 PAPER_JAM = 32;
	public const uint32 FILM_TPA_READY = 64;
	public const uint32 STORAGE_READY = 128;
	public const uint32 STORAGE_FULL = 256;
	public const uint32 MULTIPLE_FEED = 512;
	public const uint32 DEVICE_ATTENTION = 1024;
	public const uint32 LAMP_ERR = 2048;
	public const uint32 IMPRINTER_READY = 4096;
	public const uint32 ENDORSER_READY = 8192;
	public const uint32 BARCODE_READER_READY = 16384;
	public const uint32 PATCH_CODE_READER_READY = 32768;
	public const uint32 MICR_READER_READY = 65536;
	public const uint32 FEEDER = 1;
	public const uint32 FLATBED = 2;
	public const uint32 DUPLEX = 4;
	public const uint32 FRONT_FIRST = 8;
	public const uint32 BACK_FIRST = 16;
	public const uint32 FRONT_ONLY = 32;
	public const uint32 BACK_ONLY = 64;
	public const uint32 NEXT_PAGE = 128;
	public const uint32 PREFEED = 256;
	public const uint32 AUTO_ADVANCE = 512;
	public const uint32 ADVANCED_DUPLEX = 1024;
	public const uint32 LIGHT_SOURCE_PRESENT_DETECT = 1;
	public const uint32 LIGHT_SOURCE_PRESENT = 2;
	public const uint32 LIGHT_SOURCE_DETECT_READY = 4;
	public const uint32 LIGHT_SOURCE_READY = 8;
	public const uint32 TRANSPARENCY_DYNAMIC_FRAME_SUPPORT = 1;
	public const uint32 TRANSPARENCY_STATIC_FRAME_SUPPORT = 2;
	public const uint32 LIGHT_SOURCE_SELECT = 1;
	public const uint32 LIGHT_SOURCE_POSITIVE = 2;
	public const uint32 LIGHT_SOURCE_NEGATIVE = 4;
	public const uint32 WIA_SCAN_AHEAD_ALL = 0;
	public const uint32 ALL_PAGES = 0;
	public const uint32 WIA_FINAL_SCAN = 0;
	public const uint32 WIA_PREVIEW_SCAN = 1;
	public const uint32 WIA_SHOW_PREVIEW_CONTROL = 0;
	public const uint32 WIA_DONT_SHOW_PREVIEW_CONTROL = 1;
	public const String WIA_ENDORSER_TOK_DATE = "$DATE$";
	public const String WIA_ENDORSER_TOK_TIME = "$TIME$";
	public const String WIA_ENDORSER_TOK_PAGE_COUNT = "$PAGE_COUNT$";
	public const String WIA_ENDORSER_TOK_DAY = "$DAY$";
	public const String WIA_ENDORSER_TOK_MONTH = "$MONTH$";
	public const String WIA_ENDORSER_TOK_YEAR = "$YEAR$";
	public const uint32 WIA_PAGE_A4 = 0;
	public const uint32 WIA_PAGE_LETTER = 1;
	public const uint32 WIA_PAGE_CUSTOM = 2;
	public const uint32 WIA_PAGE_USLEGAL = 3;
	public const uint32 WIA_PAGE_USLETTER = 1;
	public const uint32 WIA_PAGE_USLEDGER = 4;
	public const uint32 WIA_PAGE_USSTATEMENT = 5;
	public const uint32 WIA_PAGE_BUSINESSCARD = 6;
	public const uint32 WIA_PAGE_ISO_A0 = 7;
	public const uint32 WIA_PAGE_ISO_A1 = 8;
	public const uint32 WIA_PAGE_ISO_A2 = 9;
	public const uint32 WIA_PAGE_ISO_A3 = 10;
	public const uint32 WIA_PAGE_ISO_A4 = 0;
	public const uint32 WIA_PAGE_ISO_A5 = 11;
	public const uint32 WIA_PAGE_ISO_A6 = 12;
	public const uint32 WIA_PAGE_ISO_A7 = 13;
	public const uint32 WIA_PAGE_ISO_A8 = 14;
	public const uint32 WIA_PAGE_ISO_A9 = 15;
	public const uint32 WIA_PAGE_ISO_A10 = 16;
	public const uint32 WIA_PAGE_ISO_B0 = 17;
	public const uint32 WIA_PAGE_ISO_B1 = 18;
	public const uint32 WIA_PAGE_ISO_B2 = 19;
	public const uint32 WIA_PAGE_ISO_B3 = 20;
	public const uint32 WIA_PAGE_ISO_B4 = 21;
	public const uint32 WIA_PAGE_ISO_B5 = 22;
	public const uint32 WIA_PAGE_ISO_B6 = 23;
	public const uint32 WIA_PAGE_ISO_B7 = 24;
	public const uint32 WIA_PAGE_ISO_B8 = 25;
	public const uint32 WIA_PAGE_ISO_B9 = 26;
	public const uint32 WIA_PAGE_ISO_B10 = 27;
	public const uint32 WIA_PAGE_ISO_C0 = 28;
	public const uint32 WIA_PAGE_ISO_C1 = 29;
	public const uint32 WIA_PAGE_ISO_C2 = 30;
	public const uint32 WIA_PAGE_ISO_C3 = 31;
	public const uint32 WIA_PAGE_ISO_C4 = 32;
	public const uint32 WIA_PAGE_ISO_C5 = 33;
	public const uint32 WIA_PAGE_ISO_C6 = 34;
	public const uint32 WIA_PAGE_ISO_C7 = 35;
	public const uint32 WIA_PAGE_ISO_C8 = 36;
	public const uint32 WIA_PAGE_ISO_C9 = 37;
	public const uint32 WIA_PAGE_ISO_C10 = 38;
	public const uint32 WIA_PAGE_JIS_B0 = 39;
	public const uint32 WIA_PAGE_JIS_B1 = 40;
	public const uint32 WIA_PAGE_JIS_B2 = 41;
	public const uint32 WIA_PAGE_JIS_B3 = 42;
	public const uint32 WIA_PAGE_JIS_B4 = 43;
	public const uint32 WIA_PAGE_JIS_B5 = 44;
	public const uint32 WIA_PAGE_JIS_B6 = 45;
	public const uint32 WIA_PAGE_JIS_B7 = 46;
	public const uint32 WIA_PAGE_JIS_B8 = 47;
	public const uint32 WIA_PAGE_JIS_B9 = 48;
	public const uint32 WIA_PAGE_JIS_B10 = 49;
	public const uint32 WIA_PAGE_JIS_2A = 50;
	public const uint32 WIA_PAGE_JIS_4A = 51;
	public const uint32 WIA_PAGE_DIN_2B = 52;
	public const uint32 WIA_PAGE_DIN_4B = 53;
	public const uint32 WIA_PAGE_AUTO = 100;
	public const uint32 WIA_PAGE_CUSTOM_BASE = 32768;
	public const uint32 WIA_COMPRESSION_NONE = 0;
	public const uint32 WIA_COMPRESSION_BI_RLE4 = 1;
	public const uint32 WIA_COMPRESSION_BI_RLE8 = 2;
	public const uint32 WIA_COMPRESSION_G3 = 3;
	public const uint32 WIA_COMPRESSION_G4 = 4;
	public const uint32 WIA_COMPRESSION_JPEG = 5;
	public const uint32 WIA_COMPRESSION_JBIG = 6;
	public const uint32 WIA_COMPRESSION_JPEG2K = 7;
	public const uint32 WIA_COMPRESSION_PNG = 8;
	public const uint32 WIA_COMPRESSION_AUTO = 100;
	public const uint32 WIA_PACKED_PIXEL = 0;
	public const uint32 WIA_PLANAR = 1;
	public const uint32 WIA_DATA_THRESHOLD = 0;
	public const uint32 WIA_DATA_DITHER = 1;
	public const uint32 WIA_DATA_GRAYSCALE = 2;
	public const uint32 WIA_DATA_COLOR = 3;
	public const uint32 WIA_DATA_COLOR_THRESHOLD = 4;
	public const uint32 WIA_DATA_COLOR_DITHER = 5;
	public const uint32 WIA_DATA_RAW_RGB = 6;
	public const uint32 WIA_DATA_RAW_BGR = 7;
	public const uint32 WIA_DATA_RAW_YUV = 8;
	public const uint32 WIA_DATA_RAW_YUVK = 9;
	public const uint32 WIA_DATA_RAW_CMY = 10;
	public const uint32 WIA_DATA_RAW_CMYK = 11;
	public const uint32 WIA_DATA_AUTO = 100;
	public const uint32 WIA_DEPTH_AUTO = 0;
	public const uint32 WIA_PHOTO_WHITE_1 = 0;
	public const uint32 WIA_PHOTO_WHITE_0 = 1;
	public const uint32 WIA_PROPPAGE_SCANNER_ITEM_GENERAL = 1;
	public const uint32 WIA_PROPPAGE_CAMERA_ITEM_GENERAL = 2;
	public const uint32 WIA_PROPPAGE_DEVICE_GENERAL = 4;
	public const uint32 WIA_INTENT_NONE = 0;
	public const uint32 WIA_INTENT_IMAGE_TYPE_COLOR = 1;
	public const uint32 WIA_INTENT_IMAGE_TYPE_GRAYSCALE = 2;
	public const uint32 WIA_INTENT_IMAGE_TYPE_TEXT = 4;
	public const uint32 WIA_INTENT_IMAGE_TYPE_MASK = 15;
	public const uint32 WIA_INTENT_MINIMIZE_SIZE = 65536;
	public const uint32 WIA_INTENT_MAXIMIZE_QUALITY = 131072;
	public const uint32 WIA_INTENT_BEST_PREVIEW = 262144;
	public const uint32 WIA_INTENT_SIZE_MASK = 983040;
	public const uint32 WIA_NUM_DIP = 16;
	public const String SHELLEX_WIAUIEXTENSION_NAME = "WiaDialogExtensionHandlers";
	public const String CFSTR_WIAITEMNAMES = "WIAItemNames";
	public const String CFSTR_WIAITEMPTR = "WIAItemPointer";
	public const Guid GUID_DEVINTERFACE_IMAGE = .(0x6bdd1fc6, 0x810f, 0x11d0, 0xbe, 0xc7, 0x08, 0x00, 0x2b, 0xe2, 0x09, 0x2f);
	public const uint32 MAX_IO_HANDLES = 16;
	public const uint32 MAX_RESERVED = 4;
	public const uint32 MAX_ANSI_CHAR = 255;
	public const uint32 BUS_TYPE_SCSI = 200;
	public const uint32 BUS_TYPE_USB = 201;
	public const uint32 BUS_TYPE_PARALLEL = 202;
	public const uint32 BUS_TYPE_FIREWIRE = 203;
	public const uint32 SCAN_FIRST = 10;
	public const uint32 SCAN_NEXT = 20;
	public const uint32 SCAN_FINISHED = 30;
	public const uint32 SCANMODE_FINALSCAN = 0;
	public const uint32 SCANMODE_PREVIEWSCAN = 1;
	public const uint32 CMD_INITIALIZE = 100;
	public const uint32 CMD_UNINITIALIZE = 101;
	public const uint32 CMD_SETXRESOLUTION = 102;
	public const uint32 CMD_SETYRESOLUTION = 103;
	public const uint32 CMD_SETCONTRAST = 104;
	public const uint32 CMD_SETINTENSITY = 105;
	public const uint32 CMD_SETDATATYPE = 106;
	public const uint32 CMD_SETDITHER = 107;
	public const uint32 CMD_SETMIRROR = 108;
	public const uint32 CMD_SETNEGATIVE = 109;
	public const uint32 CMD_SETTONEMAP = 110;
	public const uint32 CMD_SETCOLORDITHER = 111;
	public const uint32 CMD_SETMATRIX = 112;
	public const uint32 CMD_SETSPEED = 113;
	public const uint32 CMD_SETFILTER = 114;
	public const uint32 CMD_LOAD_ADF = 115;
	public const uint32 CMD_UNLOAD_ADF = 116;
	public const uint32 CMD_GETADFAVAILABLE = 117;
	public const uint32 CMD_GETADFOPEN = 118;
	public const uint32 CMD_GETADFREADY = 119;
	public const uint32 CMD_GETADFHASPAPER = 120;
	public const uint32 CMD_GETADFSTATUS = 121;
	public const uint32 CMD_GETADFUNLOADREADY = 122;
	public const uint32 CMD_GETTPAAVAILABLE = 123;
	public const uint32 CMD_GETTPAOPENED = 124;
	public const uint32 CMD_TPAREADY = 125;
	public const uint32 CMD_SETLAMP = 126;
	public const uint32 CMD_SENDSCSICOMMAND = 127;
	public const uint32 CMD_STI_DEVICERESET = 128;
	public const uint32 CMD_STI_GETSTATUS = 129;
	public const uint32 CMD_STI_DIAGNOSTIC = 130;
	public const uint32 CMD_RESETSCANNER = 131;
	public const uint32 CMD_GETCAPABILITIES = 132;
	public const uint32 CMD_GET_INTERRUPT_EVENT = 133;
	public const uint32 CMD_SETGSDNAME = 134;
	public const uint32 CMD_SETSCANMODE = 135;
	public const uint32 CMD_SETSTIDEVICEHKEY = 136;
	public const uint32 CMD_GETSUPPORTEDFILEFORMATS = 138;
	public const uint32 CMD_GETSUPPORTEDMEMORYFORMATS = 139;
	public const uint32 CMD_SETFORMAT = 140;
	public const uint32 SUPPORT_COLOR = 1;
	public const uint32 SUPPORT_BW = 2;
	public const uint32 SUPPORT_GRAYSCALE = 4;
	public const uint32 MCRO_ERROR_GENERAL_ERROR = 0;
	public const uint32 MCRO_STATUS_OK = 1;
	public const uint32 MCRO_ERROR_PAPER_JAM = 2;
	public const uint32 MCRO_ERROR_PAPER_PROBLEM = 3;
	public const uint32 MCRO_ERROR_PAPER_EMPTY = 4;
	public const uint32 MCRO_ERROR_OFFLINE = 5;
	public const uint32 MCRO_ERROR_USER_INTERVENTION = 6;
	public const uint32 WIA_ORDER_RGB = 0;
	public const uint32 WIA_ORDER_BGR = 1;
	public const uint32 WiaItemTypeTwainCapabilityPassThrough = 131072;
	public const uint32 ESC_TWAIN_CAPABILITY = 2001;
	public const uint32 ESC_TWAIN_PRIVATE_SUPPORTED_CAPS = 2002;
	public const String WIAU_DEBUG_TSTR = "S";
	public const uint32 g_dwDebugFlags = 0;
	public const uint32 WIA_WSD_MANUFACTURER = 38914;
	public const String WIA_WSD_MANUFACTURER_STR = "Device manufacturer";
	public const uint32 WIA_WSD_MANUFACTURER_URL = 38915;
	public const String WIA_WSD_MANUFACTURER_URL_STR = "Manufacurer URL";
	public const uint32 WIA_WSD_MODEL_NAME = 38916;
	public const String WIA_WSD_MODEL_NAME_STR = "Model name";
	public const uint32 WIA_WSD_MODEL_NUMBER = 38917;
	public const String WIA_WSD_MODEL_NUMBER_STR = "Model number";
	public const uint32 WIA_WSD_MODEL_URL = 38918;
	public const String WIA_WSD_MODEL_URL_STR = "Model URL";
	public const uint32 WIA_WSD_PRESENTATION_URL = 38919;
	public const String WIA_WSD_PRESENTATION_URL_STR = "Presentation URL";
	public const uint32 WIA_WSD_FRIENDLY_NAME = 38920;
	public const String WIA_WSD_FRIENDLY_NAME_STR = "Friendly name";
	public const uint32 WIA_WSD_SERIAL_NUMBER = 38921;
	public const String WIA_WSD_SERIAL_NUMBER_STR = "Serial number";
	public const uint32 WIA_WSD_SCAN_AVAILABLE_ITEM = 38922;
	public const String WIA_WSD_SCAN_AVAILABLE_ITEM_STR = "Scan Available Item";
}
#endregion

#region Enums

[AllowDuplicates]
public enum WIAVIDEO_STATE : int32
{
	WIAVIDEO_NO_VIDEO = 1,
	WIAVIDEO_CREATING_VIDEO = 2,
	WIAVIDEO_VIDEO_CREATED = 3,
	WIAVIDEO_VIDEO_PLAYING = 4,
	WIAVIDEO_VIDEO_PAUSED = 5,
	WIAVIDEO_DESTROYING_VIDEO = 6,
}

#endregion

#region Function Pointers
public function HRESULT DeviceDialogFunction(DEVICEDIALOGDATA* param0);

#endregion

#region Structs
[CRepr]
public struct WIA_DITHER_PATTERN_DATA
{
	public int32 lSize;
	public BSTR bstrPatternName;
	public int32 lPatternWidth;
	public int32 lPatternLength;
	public int32 cbPattern;
	public uint8* pbPattern;
}

[CRepr]
public struct WIA_PROPID_TO_NAME
{
	public uint32 propid;
	public PWSTR pszName;
}

[CRepr]
public struct WIA_FORMAT_INFO
{
	public Guid guidFormatID;
	public int32 lTymed;
}

[CRepr]
public struct WIA_RAW_HEADER
{
	public uint32 Tag;
	public uint32 Version;
	public uint32 HeaderSize;
	public uint32 XRes;
	public uint32 YRes;
	public uint32 XExtent;
	public uint32 YExtent;
	public uint32 BytesPerLine;
	public uint32 BitsPerPixel;
	public uint32 ChannelsPerPixel;
	public uint32 DataType;
	public uint8[8] BitsPerChannel;
	public uint32 Compression;
	public uint32 PhotometricInterp;
	public uint32 LineOrder;
	public uint32 RawDataOffset;
	public uint32 RawDataSize;
	public uint32 PaletteOffset;
	public uint32 PaletteSize;
}

[CRepr]
public struct WIA_BARCODE_INFO
{
	public uint32 Size;
	public uint32 Type;
	public uint32 Page;
	public uint32 Confidence;
	public uint32 XOffset;
	public uint32 YOffset;
	public uint32 Rotation;
	public uint32 Length;
	public char16* Text mut => &Text_impl;
	private char16[ANYSIZE_ARRAY] Text_impl;
}

[CRepr]
public struct WIA_BARCODES
{
	public uint32 Tag;
	public uint32 Version;
	public uint32 Size;
	public uint32 Count;
	public WIA_BARCODE_INFO* Barcodes mut => &Barcodes_impl;
	private WIA_BARCODE_INFO[ANYSIZE_ARRAY] Barcodes_impl;
}

[CRepr]
public struct WIA_PATCH_CODE_INFO
{
	public uint32 Type;
}

[CRepr]
public struct WIA_PATCH_CODES
{
	public uint32 Tag;
	public uint32 Version;
	public uint32 Size;
	public uint32 Count;
	public WIA_PATCH_CODE_INFO* PatchCodes mut => &PatchCodes_impl;
	private WIA_PATCH_CODE_INFO[ANYSIZE_ARRAY] PatchCodes_impl;
}

[CRepr]
public struct WIA_MICR_INFO
{
	public uint32 Size;
	public uint32 Page;
	public uint32 Length;
	public char16* Text mut => &Text_impl;
	private char16[ANYSIZE_ARRAY] Text_impl;
}

[CRepr]
public struct WIA_MICR
{
	public uint32 Tag;
	public uint32 Version;
	public uint32 Size;
	public char16 Placeholder;
	public uint16 Reserved;
	public uint32 Count;
	public WIA_MICR_INFO* Micr mut => &Micr_impl;
	private WIA_MICR_INFO[ANYSIZE_ARRAY] Micr_impl;
}

[CRepr]
public struct WIA_DATA_CALLBACK_HEADER
{
	public int32 lSize;
	public Guid guidFormatID;
	public int32 lBufferSize;
	public int32 lPageCount;
}

[CRepr]
public struct WIA_DATA_TRANSFER_INFO
{
	public uint32 ulSize;
	public uint32 ulSection;
	public uint32 ulBufferSize;
	public BOOL bDoubleBuffer;
	public uint32 ulReserved1;
	public uint32 ulReserved2;
	public uint32 ulReserved3;
}

[CRepr]
public struct WIA_EXTENDED_TRANSFER_INFO
{
	public uint32 ulSize;
	public uint32 ulMinBufferSize;
	public uint32 ulOptimalBufferSize;
	public uint32 ulMaxBufferSize;
	public uint32 ulNumBuffers;
}

[CRepr]
public struct WIA_DEV_CAP
{
	public Guid guid;
	public uint32 ulFlags;
	public BSTR bstrName;
	public BSTR bstrDescription;
	public BSTR bstrIcon;
	public BSTR bstrCommandline;
}

[CRepr]
public struct WiaTransferParams
{
	public int32 lMessage;
	public int32 lPercentComplete;
	public uint64 ulTransferredBytes;
	public HRESULT hrErrorStatus;
}

[CRepr]
public struct MINIDRV_TRANSFER_CONTEXT
{
	public int32 lSize;
	public int32 lWidthInPixels;
	public int32 lLines;
	public int32 lDepth;
	public int32 lXRes;
	public int32 lYRes;
	public int32 lCompression;
	public Guid guidFormatID;
	public int32 tymed;
	public int hFile;
	public int32 cbOffset;
	public int32 lBufferSize;
	public int32 lActiveBuffer;
	public int32 lNumBuffers;
	public uint8* pBaseBuffer;
	public uint8* pTransferBuffer;
	public BOOL bTransferDataCB;
	public BOOL bClassDrvAllocBuf;
	public int lClientAddress;
	public IWiaMiniDrvCallBack* pIWiaMiniDrvCallBack;
	public int32 lImageSize;
	public int32 lHeaderSize;
	public int32 lItemSize;
	public int32 cbWidthInBytes;
	public int32 lPage;
	public int32 lCurIfdOffset;
	public int32 lPrevIfdOffset;
}

[CRepr]
public struct WIA_DEV_CAP_DRV
{
	public Guid* guid;
	public uint32 ulFlags;
	public PWSTR wszName;
	public PWSTR wszDescription;
	public PWSTR wszIcon;
}

[CRepr]
public struct WIA_PROPERTY_INFO
{
	[CRepr, Union]
	public struct _ValidVal_e__Union
	{
		[CRepr]
		public struct _Flag_e__Struct
		{
			public int32 Nom;
			public int32 ValidBits;
		}
		[CRepr]
		public struct _ListGuid_e__Struct
		{
			public int32 cNumList;
			public Guid Nom;
			public Guid* pList;
		}
		[CRepr]
		public struct _List_e__Struct
		{
			public int32 cNumList;
			public int32 Nom;
			public uint8* pList;
		}
		[CRepr]
		public struct _Range_e__Struct
		{
			public int32 Min;
			public int32 Nom;
			public int32 Max;
			public int32 Inc;
		}
		[CRepr]
		public struct _None_e__Struct
		{
			public int32 Dummy;
		}
		[CRepr]
		public struct _ListFloat_e__Struct
		{
			public int32 cNumList;
			public double Nom;
			public uint8* pList;
		}
		[CRepr]
		public struct _RangeFloat_e__Struct
		{
			public double Min;
			public double Nom;
			public double Max;
			public double Inc;
		}
		[CRepr]
		public struct _ListBStr_e__Struct
		{
			public int32 cNumList;
			public BSTR Nom;
			public BSTR* pList;
		}
		public _Range_e__Struct Range;
		public _RangeFloat_e__Struct RangeFloat;
		public _List_e__Struct List;
		public _ListFloat_e__Struct ListFloat;
		public _ListGuid_e__Struct ListGuid;
		public _ListBStr_e__Struct ListBStr;
		public _Flag_e__Struct Flag;
		public _None_e__Struct None;
	}
	public uint32 lAccessFlags;
	public VARENUM vt;
	public _ValidVal_e__Union ValidVal;
}

[CRepr]
public struct WIA_PROPERTY_CONTEXT
{
	public uint32 cProps;
	public uint32* pProps;
	public BOOL* pChanged;
}

[CRepr]
public struct WIAS_CHANGED_VALUE_INFO
{
	[CRepr, Union]
	public struct _Old_e__Union
	{
		public int32 lVal;
		public float fltVal;
		public BSTR bstrVal;
		public Guid guidVal;
	}
	[CRepr, Union]
	public struct _Current_e__Union
	{
		public int32 lVal;
		public float fltVal;
		public BSTR bstrVal;
		public Guid guidVal;
	}
	public BOOL bChanged;
	public int32 vt;
	public _Old_e__Union Old;
	public _Current_e__Union Current;
}

[CRepr]
public struct WIAS_DOWN_SAMPLE_INFO
{
	public uint32 ulOriginalWidth;
	public uint32 ulOriginalHeight;
	public uint32 ulBitsPerPixel;
	public uint32 ulXRes;
	public uint32 ulYRes;
	public uint32 ulDownSampledWidth;
	public uint32 ulDownSampledHeight;
	public uint32 ulActualSize;
	public uint32 ulDestBufSize;
	public uint32 ulSrcBufSize;
	public uint8* pSrcBuffer;
	public uint8* pDestBuffer;
}

[CRepr]
public struct WIAS_ENDORSER_VALUE
{
	public PWSTR wszTokenName;
	public PWSTR wszValue;
}

[CRepr]
public struct WIAS_ENDORSER_INFO
{
	public uint32 ulPageCount;
	public uint32 ulNumEndorserValues;
	public WIAS_ENDORSER_VALUE* pEndorserValues;
}

[CRepr]
public struct DEVICEDIALOGDATA2
{
	public uint32 cbSize;
	public IWiaItem2* pIWiaItemRoot;
	public uint32 dwFlags;
	public HWND hwndParent;
	public BSTR bstrFolderName;
	public BSTR bstrFilename;
	public int32 lNumFiles;
	public BSTR* pbstrFilePaths;
	public IWiaItem2* pWiaItem;
}

[CRepr]
public struct DEVICEDIALOGDATA
{
	public uint32 cbSize;
	public HWND hwndParent;
	public IWiaItem* pIWiaItemRoot;
	public uint32 dwFlags;
	public int32 lIntent;
	public int32 lItemCount;
	public IWiaItem** ppWiaItems;
}

[CRepr]
public struct RANGEVALUE
{
	public int32 lMin;
	public int32 lMax;
	public int32 lStep;
}

[CRepr]
public struct SCANWINDOW
{
	public int32 xPos;
	public int32 yPos;
	public int32 xExtent;
	public int32 yExtent;
}

[CRepr]
public struct SCANINFO
{
	public int32 ADF;
	public int32 TPA;
	public int32 Endorser;
	public int32 OpticalXResolution;
	public int32 OpticalYResolution;
	public int32 BedWidth;
	public int32 BedHeight;
	public RANGEVALUE IntensityRange;
	public RANGEVALUE ContrastRange;
	public int32 SupportedCompressionType;
	public int32 SupportedDataTypes;
	public int32 WidthPixels;
	public int32 WidthBytes;
	public int32 Lines;
	public int32 DataType;
	public int32 PixelBits;
	public int32 Intensity;
	public int32 Contrast;
	public int32 Xresolution;
	public int32 Yresolution;
	public SCANWINDOW Window;
	public int32 DitherPattern;
	public int32 Negative;
	public int32 Mirror;
	public int32 AutoBack;
	public int32 ColorDitherPattern;
	public int32 ToneMap;
	public int32 Compression;
	public int32 RawDataFormat;
	public int32 RawPixelOrder;
	public int32 bNeedDataAlignment;
	public int32 DelayBetweenRead;
	public int32 MaxBufferSize;
	public HANDLE[16] DeviceIOHandles;
	public int32[4] lReserved;
	public void* pMicroDriverContext;
}

[CRepr]
public struct VAL
{
	public int32 lVal;
	public double dblVal;
	public Guid* pGuid;
	public SCANINFO* pScanInfo;
	public int handle;
	public uint16** ppButtonNames;
	public HANDLE* pHandle;
	public int32 lReserved;
	public CHAR[255] szVal;
}

[CRepr]
public struct TWAIN_CAPABILITY
{
	public int32 lSize;
	public int32 lMSG;
	public int32 lCapID;
	public int32 lConType;
	public int32 lRC;
	public int32 lCC;
	public int32 lDataSize;
	public uint8* Data mut => &Data_impl;
	private uint8[ANYSIZE_ARRAY] Data_impl;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_WiaDevMgr = .(0xa1f4e726, 0x8cf1, 0x11d1, 0xbf, 0x92, 0x00, 0x60, 0x08, 0x1e, 0xd8, 0x11);


	public const Guid CLSID_WiaDevMgr2 = .(0xb6c292bc, 0x7c88, 0x41ee, 0x8b, 0x54, 0x8e, 0xc9, 0x26, 0x17, 0xe5, 0x99);


	public const Guid CLSID_WiaLog = .(0xa1e75357, 0x881a, 0x419e, 0x83, 0xe2, 0xbb, 0x16, 0xdb, 0x19, 0x7c, 0x68);


	public const Guid CLSID_WiaVideo = .(0x3908c3cd, 0x4478, 0x4536, 0xaf, 0x2f, 0x10, 0xc2, 0x5d, 0x4e, 0xf8, 0x9a);


}
#endregion

#region COM Types
[CRepr]struct IWiaDevMgr : IUnknown
{
	public new const Guid IID = .(0x5eb2502a, 0x8cf1, 0x11d1, 0xbf, 0x92, 0x00, 0x60, 0x08, 0x1e, 0xd8, 0x11);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlag, IEnumWIA_DEV_INFO** ppIEnum) EnumDeviceInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDeviceID, IWiaItem** ppWiaItemRoot) CreateDevice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndParent, int32 lDeviceType, int32 lFlags, BSTR* pbstrDeviceID, IWiaItem** ppItemRoot) SelectDeviceDlg;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndParent, int32 lDeviceType, int32 lFlags, BSTR* pbstrDeviceID) SelectDeviceDlgID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndParent, int32 lDeviceType, int32 lFlags, int32 lIntent, IWiaItem* pItemRoot, BSTR bstrFilename, Guid* pguidFormat) GetImageDlg;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags, BSTR bstrDeviceID, in Guid pEventGUID, BSTR bstrCommandline, BSTR bstrName, BSTR bstrDescription, BSTR bstrIcon) RegisterEventCallbackProgram;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags, BSTR bstrDeviceID, in Guid pEventGUID, IWiaEventCallback* pIWiaEventCallback, IUnknown** pEventObject) RegisterEventCallbackInterface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags, BSTR bstrDeviceID, in Guid pEventGUID, in Guid pClsID, BSTR bstrName, BSTR bstrDescription, BSTR bstrIcon) RegisterEventCallbackCLSID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndParent, int32 lFlags) AddDeviceDlg;
	}


	public HRESULT EnumDeviceInfo(int32 lFlag, IEnumWIA_DEV_INFO** ppIEnum) mut => VT.[Friend]EnumDeviceInfo(&this, lFlag, ppIEnum);

	public HRESULT CreateDevice(BSTR bstrDeviceID, IWiaItem** ppWiaItemRoot) mut => VT.[Friend]CreateDevice(&this, bstrDeviceID, ppWiaItemRoot);

	public HRESULT SelectDeviceDlg(HWND hwndParent, int32 lDeviceType, int32 lFlags, BSTR* pbstrDeviceID, IWiaItem** ppItemRoot) mut => VT.[Friend]SelectDeviceDlg(&this, hwndParent, lDeviceType, lFlags, pbstrDeviceID, ppItemRoot);

	public HRESULT SelectDeviceDlgID(HWND hwndParent, int32 lDeviceType, int32 lFlags, BSTR* pbstrDeviceID) mut => VT.[Friend]SelectDeviceDlgID(&this, hwndParent, lDeviceType, lFlags, pbstrDeviceID);

	public HRESULT GetImageDlg(HWND hwndParent, int32 lDeviceType, int32 lFlags, int32 lIntent, IWiaItem* pItemRoot, BSTR bstrFilename, Guid* pguidFormat) mut => VT.[Friend]GetImageDlg(&this, hwndParent, lDeviceType, lFlags, lIntent, pItemRoot, bstrFilename, pguidFormat);

	public HRESULT RegisterEventCallbackProgram(int32 lFlags, BSTR bstrDeviceID, in Guid pEventGUID, BSTR bstrCommandline, BSTR bstrName, BSTR bstrDescription, BSTR bstrIcon) mut => VT.[Friend]RegisterEventCallbackProgram(&this, lFlags, bstrDeviceID, pEventGUID, bstrCommandline, bstrName, bstrDescription, bstrIcon);

	public HRESULT RegisterEventCallbackInterface(int32 lFlags, BSTR bstrDeviceID, in Guid pEventGUID, IWiaEventCallback* pIWiaEventCallback, IUnknown** pEventObject) mut => VT.[Friend]RegisterEventCallbackInterface(&this, lFlags, bstrDeviceID, pEventGUID, pIWiaEventCallback, pEventObject);

	public HRESULT RegisterEventCallbackCLSID(int32 lFlags, BSTR bstrDeviceID, in Guid pEventGUID, in Guid pClsID, BSTR bstrName, BSTR bstrDescription, BSTR bstrIcon) mut => VT.[Friend]RegisterEventCallbackCLSID(&this, lFlags, bstrDeviceID, pEventGUID, pClsID, bstrName, bstrDescription, bstrIcon);

	public HRESULT AddDeviceDlg(HWND hwndParent, int32 lFlags) mut => VT.[Friend]AddDeviceDlg(&this, hwndParent, lFlags);
}

[CRepr]struct IEnumWIA_DEV_INFO : IUnknown
{
	public new const Guid IID = .(0x5e38b83c, 0x8cf1, 0x11d1, 0xbf, 0x92, 0x00, 0x60, 0x08, 0x1e, 0xd8, 0x11);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, IWiaPropertyStorage** rgelt, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumWIA_DEV_INFO** ppIEnum) Clone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* celt) GetCount;
	}


	public HRESULT Next(uint32 celt, IWiaPropertyStorage** rgelt, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgelt, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumWIA_DEV_INFO** ppIEnum) mut => VT.[Friend]Clone(&this, ppIEnum);

	public HRESULT GetCount(uint32* celt) mut => VT.[Friend]GetCount(&this, celt);
}

[CRepr]struct IWiaEventCallback : IUnknown
{
	public new const Guid IID = .(0xae6287b0, 0x0084, 0x11d2, 0x97, 0x3b, 0x00, 0xa0, 0xc9, 0x06, 0x8f, 0x2e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid pEventGUID, BSTR bstrEventDescription, BSTR bstrDeviceID, BSTR bstrDeviceDescription, uint32 dwDeviceType, BSTR bstrFullItemName, uint32* pulEventType, uint32 ulReserved) ImageEventCallback;
	}


	public HRESULT ImageEventCallback(in Guid pEventGUID, BSTR bstrEventDescription, BSTR bstrDeviceID, BSTR bstrDeviceDescription, uint32 dwDeviceType, BSTR bstrFullItemName, uint32* pulEventType, uint32 ulReserved) mut => VT.[Friend]ImageEventCallback(&this, pEventGUID, bstrEventDescription, bstrDeviceID, bstrDeviceDescription, dwDeviceType, bstrFullItemName, pulEventType, ulReserved);
}

[CRepr]struct IWiaDataCallback : IUnknown
{
	public new const Guid IID = .(0xa558a866, 0xa5b0, 0x11d2, 0xa0, 0x8f, 0x00, 0xc0, 0x4f, 0x72, 0xdc, 0x3c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lMessage, int32 lStatus, int32 lPercentComplete, int32 lOffset, int32 lLength, int32 lReserved, int32 lResLength, uint8* pbBuffer) BandedDataCallback;
	}


	public HRESULT BandedDataCallback(int32 lMessage, int32 lStatus, int32 lPercentComplete, int32 lOffset, int32 lLength, int32 lReserved, int32 lResLength, uint8* pbBuffer) mut => VT.[Friend]BandedDataCallback(&this, lMessage, lStatus, lPercentComplete, lOffset, lLength, lReserved, lResLength, pbBuffer);
}

[CRepr]struct IWiaDataTransfer : IUnknown
{
	public new const Guid IID = .(0xa6cef998, 0xa5b0, 0x11d2, 0xa0, 0x8f, 0x00, 0xc0, 0x4f, 0x72, 0xdc, 0x3c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, STGMEDIUM* pMedium, IWiaDataCallback* pIWiaDataCallback) idtGetData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WIA_DATA_TRANSFER_INFO* pWiaDataTransInfo, IWiaDataCallback* pIWiaDataCallback) idtGetBandedData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WIA_FORMAT_INFO* pfe) idtQueryGetData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumWIA_FORMAT_INFO** ppEnum) idtEnumWIA_FORMAT_INFO;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WIA_EXTENDED_TRANSFER_INFO* pExtendedTransferInfo) idtGetExtendedTransferInfo;
	}


	public HRESULT idtGetData(STGMEDIUM* pMedium, IWiaDataCallback* pIWiaDataCallback) mut => VT.[Friend]idtGetData(&this, pMedium, pIWiaDataCallback);

	public HRESULT idtGetBandedData(WIA_DATA_TRANSFER_INFO* pWiaDataTransInfo, IWiaDataCallback* pIWiaDataCallback) mut => VT.[Friend]idtGetBandedData(&this, pWiaDataTransInfo, pIWiaDataCallback);

	public HRESULT idtQueryGetData(WIA_FORMAT_INFO* pfe) mut => VT.[Friend]idtQueryGetData(&this, pfe);

	public HRESULT idtEnumWIA_FORMAT_INFO(IEnumWIA_FORMAT_INFO** ppEnum) mut => VT.[Friend]idtEnumWIA_FORMAT_INFO(&this, ppEnum);

	public HRESULT idtGetExtendedTransferInfo(WIA_EXTENDED_TRANSFER_INFO* pExtendedTransferInfo) mut => VT.[Friend]idtGetExtendedTransferInfo(&this, pExtendedTransferInfo);
}

[CRepr]struct IWiaItem : IUnknown
{
	public new const Guid IID = .(0x4db1ad10, 0x3391, 0x11d2, 0x9a, 0x33, 0x00, 0xc0, 0x4f, 0xa3, 0x61, 0x45);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pItemType) GetItemType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags) AnalyzeItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumWiaItem** ppIEnumWiaItem) EnumChildItems;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags) DeleteItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags, BSTR bstrItemName, BSTR bstrFullItemName, IWiaItem** ppIWiaItem) CreateChildItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags, in Guid pEventGUID, IEnumWIA_DEV_CAPS** ppIEnum) EnumRegisterEventInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags, BSTR bstrFullItemName, IWiaItem** ppIWiaItem) FindItemByName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndParent, int32 lFlags, int32 lIntent, int32* plItemCount, IWiaItem*** ppIWiaItem) DeviceDlg;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags, in Guid pCmdGUID, IWiaItem** pIWiaItem) DeviceCommand;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWiaItem** ppIWiaItem) GetRootItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags, IEnumWIA_DEV_CAPS** ppIEnumWIA_DEV_CAPS) EnumDeviceCapabilities;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* bstrData) DumpItemData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* bstrData) DumpDrvItemData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* bstrData) DumpTreeItemData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulSize, uint8* pBuffer) Diagnostic;
	}


	public HRESULT GetItemType(int32* pItemType) mut => VT.[Friend]GetItemType(&this, pItemType);

	public HRESULT AnalyzeItem(int32 lFlags) mut => VT.[Friend]AnalyzeItem(&this, lFlags);

	public HRESULT EnumChildItems(IEnumWiaItem** ppIEnumWiaItem) mut => VT.[Friend]EnumChildItems(&this, ppIEnumWiaItem);

	public HRESULT DeleteItem(int32 lFlags) mut => VT.[Friend]DeleteItem(&this, lFlags);

	public HRESULT CreateChildItem(int32 lFlags, BSTR bstrItemName, BSTR bstrFullItemName, IWiaItem** ppIWiaItem) mut => VT.[Friend]CreateChildItem(&this, lFlags, bstrItemName, bstrFullItemName, ppIWiaItem);

	public HRESULT EnumRegisterEventInfo(int32 lFlags, in Guid pEventGUID, IEnumWIA_DEV_CAPS** ppIEnum) mut => VT.[Friend]EnumRegisterEventInfo(&this, lFlags, pEventGUID, ppIEnum);

	public HRESULT FindItemByName(int32 lFlags, BSTR bstrFullItemName, IWiaItem** ppIWiaItem) mut => VT.[Friend]FindItemByName(&this, lFlags, bstrFullItemName, ppIWiaItem);

	public HRESULT DeviceDlg(HWND hwndParent, int32 lFlags, int32 lIntent, int32* plItemCount, IWiaItem*** ppIWiaItem) mut => VT.[Friend]DeviceDlg(&this, hwndParent, lFlags, lIntent, plItemCount, ppIWiaItem);

	public HRESULT DeviceCommand(int32 lFlags, in Guid pCmdGUID, IWiaItem** pIWiaItem) mut => VT.[Friend]DeviceCommand(&this, lFlags, pCmdGUID, pIWiaItem);

	public HRESULT GetRootItem(IWiaItem** ppIWiaItem) mut => VT.[Friend]GetRootItem(&this, ppIWiaItem);

	public HRESULT EnumDeviceCapabilities(int32 lFlags, IEnumWIA_DEV_CAPS** ppIEnumWIA_DEV_CAPS) mut => VT.[Friend]EnumDeviceCapabilities(&this, lFlags, ppIEnumWIA_DEV_CAPS);

	public HRESULT DumpItemData(BSTR* bstrData) mut => VT.[Friend]DumpItemData(&this, bstrData);

	public HRESULT DumpDrvItemData(BSTR* bstrData) mut => VT.[Friend]DumpDrvItemData(&this, bstrData);

	public HRESULT DumpTreeItemData(BSTR* bstrData) mut => VT.[Friend]DumpTreeItemData(&this, bstrData);

	public HRESULT Diagnostic(uint32 ulSize, uint8* pBuffer) mut => VT.[Friend]Diagnostic(&this, ulSize, pBuffer);
}

[CRepr]struct IWiaPropertyStorage : IUnknown
{
	public new const Guid IID = .(0x98b5e8a0, 0x29cc, 0x491a, 0xaa, 0xc0, 0xe6, 0xdb, 0x4f, 0xdc, 0xce, 0xb6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cpspec, PROPSPEC* rgpspec, PROPVARIANT* rgpropvar) ReadMultiple;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cpspec, PROPSPEC* rgpspec, PROPVARIANT* rgpropvar, uint32 propidNameFirst) WriteMultiple;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cpspec, PROPSPEC* rgpspec) DeleteMultiple;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cpropid, uint32* rgpropid, PWSTR* rglpwstrName) ReadPropertyNames;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cpropid, uint32* rgpropid, PWSTR* rglpwstrName) WritePropertyNames;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cpropid, uint32* rgpropid) DeletePropertyNames;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 grfCommitFlags) Commit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Revert;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumSTATPROPSTG** ppenum) Enum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FILETIME* pctime, FILETIME* patime, FILETIME* pmtime) SetTimes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid clsid) SetClass;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, STATPROPSETSTG* pstatpsstg) Stat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cpspec, PROPSPEC* rgpspec, uint32* rgflags, PROPVARIANT* rgpropvar) GetPropertyAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pulNumProps) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pCompatibilityId, IStream** ppIStream) GetPropertyStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pCompatibilityId, IStream* pIStream) SetPropertyStream;
	}


	public HRESULT ReadMultiple(uint32 cpspec, PROPSPEC* rgpspec, PROPVARIANT* rgpropvar) mut => VT.[Friend]ReadMultiple(&this, cpspec, rgpspec, rgpropvar);

	public HRESULT WriteMultiple(uint32 cpspec, PROPSPEC* rgpspec, PROPVARIANT* rgpropvar, uint32 propidNameFirst) mut => VT.[Friend]WriteMultiple(&this, cpspec, rgpspec, rgpropvar, propidNameFirst);

	public HRESULT DeleteMultiple(uint32 cpspec, PROPSPEC* rgpspec) mut => VT.[Friend]DeleteMultiple(&this, cpspec, rgpspec);

	public HRESULT ReadPropertyNames(uint32 cpropid, uint32* rgpropid, PWSTR* rglpwstrName) mut => VT.[Friend]ReadPropertyNames(&this, cpropid, rgpropid, rglpwstrName);

	public HRESULT WritePropertyNames(uint32 cpropid, uint32* rgpropid, PWSTR* rglpwstrName) mut => VT.[Friend]WritePropertyNames(&this, cpropid, rgpropid, rglpwstrName);

	public HRESULT DeletePropertyNames(uint32 cpropid, uint32* rgpropid) mut => VT.[Friend]DeletePropertyNames(&this, cpropid, rgpropid);

	public HRESULT Commit(uint32 grfCommitFlags) mut => VT.[Friend]Commit(&this, grfCommitFlags);

	public HRESULT Revert() mut => VT.[Friend]Revert(&this);

	public HRESULT Enum(IEnumSTATPROPSTG** ppenum) mut => VT.[Friend]Enum(&this, ppenum);

	public HRESULT SetTimes(FILETIME* pctime, FILETIME* patime, FILETIME* pmtime) mut => VT.[Friend]SetTimes(&this, pctime, patime, pmtime);

	public HRESULT SetClass(in Guid clsid) mut => VT.[Friend]SetClass(&this, clsid);

	public HRESULT Stat(STATPROPSETSTG* pstatpsstg) mut => VT.[Friend]Stat(&this, pstatpsstg);

	public HRESULT GetPropertyAttributes(uint32 cpspec, PROPSPEC* rgpspec, uint32* rgflags, PROPVARIANT* rgpropvar) mut => VT.[Friend]GetPropertyAttributes(&this, cpspec, rgpspec, rgflags, rgpropvar);

	public HRESULT GetCount(uint32* pulNumProps) mut => VT.[Friend]GetCount(&this, pulNumProps);

	public HRESULT GetPropertyStream(Guid* pCompatibilityId, IStream** ppIStream) mut => VT.[Friend]GetPropertyStream(&this, pCompatibilityId, ppIStream);

	public HRESULT SetPropertyStream(Guid* pCompatibilityId, IStream* pIStream) mut => VT.[Friend]SetPropertyStream(&this, pCompatibilityId, pIStream);
}

[CRepr]struct IEnumWiaItem : IUnknown
{
	public new const Guid IID = .(0x5e8383fc, 0x3391, 0x11d2, 0x9a, 0x33, 0x00, 0xc0, 0x4f, 0xa3, 0x61, 0x45);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, IWiaItem** ppIWiaItem, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumWiaItem** ppIEnum) Clone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* celt) GetCount;
	}


	public HRESULT Next(uint32 celt, IWiaItem** ppIWiaItem, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, ppIWiaItem, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumWiaItem** ppIEnum) mut => VT.[Friend]Clone(&this, ppIEnum);

	public HRESULT GetCount(uint32* celt) mut => VT.[Friend]GetCount(&this, celt);
}

[CRepr]struct IEnumWIA_DEV_CAPS : IUnknown
{
	public new const Guid IID = .(0x1fcc4287, 0xaca6, 0x11d2, 0xa0, 0x93, 0x00, 0xc0, 0x4f, 0x72, 0xdc, 0x3c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, WIA_DEV_CAP* rgelt, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumWIA_DEV_CAPS** ppIEnum) Clone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcelt) GetCount;
	}


	public HRESULT Next(uint32 celt, WIA_DEV_CAP* rgelt, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgelt, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumWIA_DEV_CAPS** ppIEnum) mut => VT.[Friend]Clone(&this, ppIEnum);

	public HRESULT GetCount(uint32* pcelt) mut => VT.[Friend]GetCount(&this, pcelt);
}

[CRepr]struct IEnumWIA_FORMAT_INFO : IUnknown
{
	public new const Guid IID = .(0x81befc5b, 0x656d, 0x44f1, 0xb2, 0x4c, 0xd4, 0x1d, 0x51, 0xb4, 0xdc, 0x81);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, WIA_FORMAT_INFO* rgelt, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumWIA_FORMAT_INFO** ppIEnum) Clone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcelt) GetCount;
	}


	public HRESULT Next(uint32 celt, WIA_FORMAT_INFO* rgelt, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgelt, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumWIA_FORMAT_INFO** ppIEnum) mut => VT.[Friend]Clone(&this, ppIEnum);

	public HRESULT GetCount(uint32* pcelt) mut => VT.[Friend]GetCount(&this, pcelt);
}

[CRepr]struct IWiaLog : IUnknown
{
	public new const Guid IID = .(0xa00c10b6, 0x82a1, 0x452f, 0x8b, 0x6c, 0x86, 0x06, 0x2a, 0xad, 0x68, 0x90);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 hInstance) InitializeLog;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hResult) hResult;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags, int32 lResID, int32 lDetail, BSTR bstrText) Log;
	}


	public HRESULT InitializeLog(int32 hInstance) mut => VT.[Friend]InitializeLog(&this, hInstance);

	public HRESULT hResult(HRESULT hResult) mut => VT.[Friend]hResult(&this, hResult);

	public HRESULT Log(int32 lFlags, int32 lResID, int32 lDetail, BSTR bstrText) mut => VT.[Friend]Log(&this, lFlags, lResID, lDetail, bstrText);
}

[CRepr]struct IWiaLogEx : IUnknown
{
	public new const Guid IID = .(0xaf1f22ac, 0x7a40, 0x4787, 0xb4, 0x21, 0xae, 0xb4, 0x7a, 0x1f, 0xbd, 0x0b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* hInstance) InitializeLogEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hResult) hResult;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags, int32 lResID, int32 lDetail, BSTR bstrText) Log;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lMethodId, HRESULT hResult) hResultEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lMethodId, int32 lFlags, int32 lResID, int32 lDetail, BSTR bstrText) LogEx;
	}


	public HRESULT InitializeLogEx(uint8* hInstance) mut => VT.[Friend]InitializeLogEx(&this, hInstance);

	public HRESULT hResult(HRESULT hResult) mut => VT.[Friend]hResult(&this, hResult);

	public HRESULT Log(int32 lFlags, int32 lResID, int32 lDetail, BSTR bstrText) mut => VT.[Friend]Log(&this, lFlags, lResID, lDetail, bstrText);

	public HRESULT hResultEx(int32 lMethodId, HRESULT hResult) mut => VT.[Friend]hResultEx(&this, lMethodId, hResult);

	public HRESULT LogEx(int32 lMethodId, int32 lFlags, int32 lResID, int32 lDetail, BSTR bstrText) mut => VT.[Friend]LogEx(&this, lMethodId, lFlags, lResID, lDetail, bstrText);
}

[CRepr]struct IWiaNotifyDevMgr : IUnknown
{
	public new const Guid IID = .(0x70681ea0, 0xe7bf, 0x4291, 0x9f, 0xb1, 0x4e, 0x88, 0x13, 0xa3, 0xf7, 0x8e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) NewDeviceArrival;
	}


	public HRESULT NewDeviceArrival() mut => VT.[Friend]NewDeviceArrival(&this);
}

[CRepr]struct IWiaItemExtras : IUnknown
{
	public new const Guid IID = .(0x6291ef2c, 0x36ef, 0x4532, 0x87, 0x6a, 0x8e, 0x13, 0x25, 0x93, 0x77, 0x8d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* bstrErrorText) GetExtendedErrorInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwEscapeCode, uint8* lpInData, uint32 cbInDataSize, uint8* pOutData, uint32 dwOutDataSize, uint32* pdwActualDataSize) Escape;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) CancelPendingIO;
	}


	public HRESULT GetExtendedErrorInfo(BSTR* bstrErrorText) mut => VT.[Friend]GetExtendedErrorInfo(&this, bstrErrorText);

	public HRESULT Escape(uint32 dwEscapeCode, uint8* lpInData, uint32 cbInDataSize, uint8* pOutData, uint32 dwOutDataSize, uint32* pdwActualDataSize) mut => VT.[Friend]Escape(&this, dwEscapeCode, lpInData, cbInDataSize, pOutData, dwOutDataSize, pdwActualDataSize);

	public HRESULT CancelPendingIO() mut => VT.[Friend]CancelPendingIO(&this);
}

[CRepr]struct IWiaAppErrorHandler : IUnknown
{
	public new const Guid IID = .(0x6c16186c, 0xd0a6, 0x400c, 0x80, 0xf4, 0xd2, 0x69, 0x86, 0xa0, 0xe7, 0x34);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND* phwnd) GetWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags, IWiaItem2* pWiaItem2, HRESULT hrStatus, int32 lPercentComplete) ReportStatus;
	}


	public HRESULT GetWindow(HWND* phwnd) mut => VT.[Friend]GetWindow(&this, phwnd);

	public HRESULT ReportStatus(int32 lFlags, IWiaItem2* pWiaItem2, HRESULT hrStatus, int32 lPercentComplete) mut => VT.[Friend]ReportStatus(&this, lFlags, pWiaItem2, hrStatus, lPercentComplete);
}

[CRepr]struct IWiaErrorHandler : IUnknown
{
	public new const Guid IID = .(0x0e4a51b1, 0xbc1f, 0x443d, 0xa8, 0x35, 0x72, 0xe8, 0x90, 0x75, 0x9e, 0xf3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags, HWND hwndParent, IWiaItem2* pWiaItem2, HRESULT hrStatus, int32 lPercentComplete) ReportStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags, IWiaItem2* pWiaItem2, HRESULT hrStatus, BSTR* pbstrDescription) GetStatusDescription;
	}


	public HRESULT ReportStatus(int32 lFlags, HWND hwndParent, IWiaItem2* pWiaItem2, HRESULT hrStatus, int32 lPercentComplete) mut => VT.[Friend]ReportStatus(&this, lFlags, hwndParent, pWiaItem2, hrStatus, lPercentComplete);

	public HRESULT GetStatusDescription(int32 lFlags, IWiaItem2* pWiaItem2, HRESULT hrStatus, BSTR* pbstrDescription) mut => VT.[Friend]GetStatusDescription(&this, lFlags, pWiaItem2, hrStatus, pbstrDescription);
}

[CRepr]struct IWiaTransfer : IUnknown
{
	public new const Guid IID = .(0xc39d6942, 0x2f4e, 0x4d04, 0x92, 0xfe, 0x4e, 0xf4, 0xd3, 0xa1, 0xde, 0x5a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags, IWiaTransferCallback* pIWiaTransferCallback) Download;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags, IStream* pSource, IWiaTransferCallback* pIWiaTransferCallback) Upload;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Cancel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumWIA_FORMAT_INFO** ppEnum) EnumWIA_FORMAT_INFO;
	}


	public HRESULT Download(int32 lFlags, IWiaTransferCallback* pIWiaTransferCallback) mut => VT.[Friend]Download(&this, lFlags, pIWiaTransferCallback);

	public HRESULT Upload(int32 lFlags, IStream* pSource, IWiaTransferCallback* pIWiaTransferCallback) mut => VT.[Friend]Upload(&this, lFlags, pSource, pIWiaTransferCallback);

	public HRESULT Cancel() mut => VT.[Friend]Cancel(&this);

	public HRESULT EnumWIA_FORMAT_INFO(IEnumWIA_FORMAT_INFO** ppEnum) mut => VT.[Friend]EnumWIA_FORMAT_INFO(&this, ppEnum);
}

[CRepr]struct IWiaTransferCallback : IUnknown
{
	public new const Guid IID = .(0x27d4eaaf, 0x28a6, 0x4ca5, 0x9a, 0xab, 0xe6, 0x78, 0x16, 0x8b, 0x95, 0x27);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags, WiaTransferParams* pWiaTransferParams) TransferCallback;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags, BSTR bstrItemName, BSTR bstrFullItemName, IStream** ppDestination) GetNextStream;
	}


	public HRESULT TransferCallback(int32 lFlags, WiaTransferParams* pWiaTransferParams) mut => VT.[Friend]TransferCallback(&this, lFlags, pWiaTransferParams);

	public HRESULT GetNextStream(int32 lFlags, BSTR bstrItemName, BSTR bstrFullItemName, IStream** ppDestination) mut => VT.[Friend]GetNextStream(&this, lFlags, bstrItemName, bstrFullItemName, ppDestination);
}

[CRepr]struct IWiaSegmentationFilter : IUnknown
{
	public new const Guid IID = .(0xec46a697, 0xac04, 0x4447, 0x8f, 0x65, 0xff, 0x63, 0xd5, 0x15, 0x4b, 0x21);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags, IStream* pInputStream, IWiaItem2* pWiaItem2) DetectRegions;
	}


	public HRESULT DetectRegions(int32 lFlags, IStream* pInputStream, IWiaItem2* pWiaItem2) mut => VT.[Friend]DetectRegions(&this, lFlags, pInputStream, pWiaItem2);
}

[CRepr]struct IWiaImageFilter : IUnknown
{
	public new const Guid IID = .(0xa8a79ffa, 0x450b, 0x41f1, 0x8f, 0x87, 0x84, 0x9c, 0xcd, 0x94, 0xeb, 0xf6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWiaItem2* pWiaItem2, IWiaTransferCallback* pWiaTransferCallback) InitializeFilter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWiaTransferCallback* pWiaTransferCallback) SetNewCallback;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags, IWiaItem2* pWiaChildItem2, RECT InputImageExtents, IStream* pInputStream) FilterPreviewImage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWiaPropertyStorage* pWiaPropertyStorage) ApplyProperties;
	}


	public HRESULT InitializeFilter(IWiaItem2* pWiaItem2, IWiaTransferCallback* pWiaTransferCallback) mut => VT.[Friend]InitializeFilter(&this, pWiaItem2, pWiaTransferCallback);

	public HRESULT SetNewCallback(IWiaTransferCallback* pWiaTransferCallback) mut => VT.[Friend]SetNewCallback(&this, pWiaTransferCallback);

	public HRESULT FilterPreviewImage(int32 lFlags, IWiaItem2* pWiaChildItem2, RECT InputImageExtents, IStream* pInputStream) mut => VT.[Friend]FilterPreviewImage(&this, lFlags, pWiaChildItem2, InputImageExtents, pInputStream);

	public HRESULT ApplyProperties(IWiaPropertyStorage* pWiaPropertyStorage) mut => VT.[Friend]ApplyProperties(&this, pWiaPropertyStorage);
}

[CRepr]struct IWiaPreview : IUnknown
{
	public new const Guid IID = .(0x95c2b4fd, 0x33f2, 0x4d86, 0xad, 0x40, 0x94, 0x31, 0xf0, 0xdf, 0x08, 0xf7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags, IWiaItem2* pWiaItem2, IWiaTransferCallback* pWiaTransferCallback) GetNewPreview;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags, IWiaItem2* pChildWiaItem2, IWiaTransferCallback* pWiaTransferCallback) UpdatePreview;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags) DetectRegions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Clear;
	}


	public HRESULT GetNewPreview(int32 lFlags, IWiaItem2* pWiaItem2, IWiaTransferCallback* pWiaTransferCallback) mut => VT.[Friend]GetNewPreview(&this, lFlags, pWiaItem2, pWiaTransferCallback);

	public HRESULT UpdatePreview(int32 lFlags, IWiaItem2* pChildWiaItem2, IWiaTransferCallback* pWiaTransferCallback) mut => VT.[Friend]UpdatePreview(&this, lFlags, pChildWiaItem2, pWiaTransferCallback);

	public HRESULT DetectRegions(int32 lFlags) mut => VT.[Friend]DetectRegions(&this, lFlags);

	public HRESULT Clear() mut => VT.[Friend]Clear(&this);
}

[CRepr]struct IEnumWiaItem2 : IUnknown
{
	public new const Guid IID = .(0x59970af4, 0xcd0d, 0x44d9, 0xab, 0x24, 0x52, 0x29, 0x56, 0x30, 0xe5, 0x82);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cElt, IWiaItem2** ppIWiaItem2, uint32* pcEltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cElt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumWiaItem2** ppIEnum) Clone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* cElt) GetCount;
	}


	public HRESULT Next(uint32 cElt, IWiaItem2** ppIWiaItem2, uint32* pcEltFetched) mut => VT.[Friend]Next(&this, cElt, ppIWiaItem2, pcEltFetched);

	public HRESULT Skip(uint32 cElt) mut => VT.[Friend]Skip(&this, cElt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumWiaItem2** ppIEnum) mut => VT.[Friend]Clone(&this, ppIEnum);

	public HRESULT GetCount(uint32* cElt) mut => VT.[Friend]GetCount(&this, cElt);
}

[CRepr]struct IWiaItem2 : IUnknown
{
	public new const Guid IID = .(0x6cba0075, 0x1287, 0x407d, 0x9b, 0x77, 0xcf, 0x0e, 0x03, 0x04, 0x35, 0xcc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lItemFlags, int32 lCreationFlags, BSTR bstrItemName, IWiaItem2** ppIWiaItem2) CreateChildItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags) DeleteItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pCategoryGUID, IEnumWiaItem2** ppIEnumWiaItem2) EnumChildItems;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags, BSTR bstrFullItemName, IWiaItem2** ppIWiaItem2) FindItemByName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pItemCategoryGUID) GetItemCategory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pItemType) GetItemType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags, HWND hwndParent, BSTR bstrFolderName, BSTR bstrFilename, int32* plNumFiles, BSTR** ppbstrFilePaths, IWiaItem2** ppItem) DeviceDlg;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags, in Guid pCmdGUID, IWiaItem2** ppIWiaItem2) DeviceCommand;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags, IEnumWIA_DEV_CAPS** ppIEnumWIA_DEV_CAPS) EnumDeviceCapabilities;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags, BSTR bstrName, in Guid riidExtensionInterface, BOOL* pbExtensionExists) CheckExtension;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags, BSTR bstrName, in Guid riidExtensionInterface, void** ppOut) GetExtension;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWiaItem2** ppIWiaItem2) GetParentItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWiaItem2** ppIWiaItem2) GetRootItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags, IWiaPreview** ppWiaPreview) GetPreviewComponent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags, in Guid pEventGUID, IEnumWIA_DEV_CAPS** ppIEnum) EnumRegisterEventInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulSize, uint8* pBuffer) Diagnostic;
	}


	public HRESULT CreateChildItem(int32 lItemFlags, int32 lCreationFlags, BSTR bstrItemName, IWiaItem2** ppIWiaItem2) mut => VT.[Friend]CreateChildItem(&this, lItemFlags, lCreationFlags, bstrItemName, ppIWiaItem2);

	public HRESULT DeleteItem(int32 lFlags) mut => VT.[Friend]DeleteItem(&this, lFlags);

	public HRESULT EnumChildItems(Guid* pCategoryGUID, IEnumWiaItem2** ppIEnumWiaItem2) mut => VT.[Friend]EnumChildItems(&this, pCategoryGUID, ppIEnumWiaItem2);

	public HRESULT FindItemByName(int32 lFlags, BSTR bstrFullItemName, IWiaItem2** ppIWiaItem2) mut => VT.[Friend]FindItemByName(&this, lFlags, bstrFullItemName, ppIWiaItem2);

	public HRESULT GetItemCategory(Guid* pItemCategoryGUID) mut => VT.[Friend]GetItemCategory(&this, pItemCategoryGUID);

	public HRESULT GetItemType(int32* pItemType) mut => VT.[Friend]GetItemType(&this, pItemType);

	public HRESULT DeviceDlg(int32 lFlags, HWND hwndParent, BSTR bstrFolderName, BSTR bstrFilename, int32* plNumFiles, BSTR** ppbstrFilePaths, IWiaItem2** ppItem) mut => VT.[Friend]DeviceDlg(&this, lFlags, hwndParent, bstrFolderName, bstrFilename, plNumFiles, ppbstrFilePaths, ppItem);

	public HRESULT DeviceCommand(int32 lFlags, in Guid pCmdGUID, IWiaItem2** ppIWiaItem2) mut => VT.[Friend]DeviceCommand(&this, lFlags, pCmdGUID, ppIWiaItem2);

	public HRESULT EnumDeviceCapabilities(int32 lFlags, IEnumWIA_DEV_CAPS** ppIEnumWIA_DEV_CAPS) mut => VT.[Friend]EnumDeviceCapabilities(&this, lFlags, ppIEnumWIA_DEV_CAPS);

	public HRESULT CheckExtension(int32 lFlags, BSTR bstrName, in Guid riidExtensionInterface, BOOL* pbExtensionExists) mut => VT.[Friend]CheckExtension(&this, lFlags, bstrName, riidExtensionInterface, pbExtensionExists);

	public HRESULT GetExtension(int32 lFlags, BSTR bstrName, in Guid riidExtensionInterface, void** ppOut) mut => VT.[Friend]GetExtension(&this, lFlags, bstrName, riidExtensionInterface, ppOut);

	public HRESULT GetParentItem(IWiaItem2** ppIWiaItem2) mut => VT.[Friend]GetParentItem(&this, ppIWiaItem2);

	public HRESULT GetRootItem(IWiaItem2** ppIWiaItem2) mut => VT.[Friend]GetRootItem(&this, ppIWiaItem2);

	public HRESULT GetPreviewComponent(int32 lFlags, IWiaPreview** ppWiaPreview) mut => VT.[Friend]GetPreviewComponent(&this, lFlags, ppWiaPreview);

	public HRESULT EnumRegisterEventInfo(int32 lFlags, in Guid pEventGUID, IEnumWIA_DEV_CAPS** ppIEnum) mut => VT.[Friend]EnumRegisterEventInfo(&this, lFlags, pEventGUID, ppIEnum);

	public HRESULT Diagnostic(uint32 ulSize, uint8* pBuffer) mut => VT.[Friend]Diagnostic(&this, ulSize, pBuffer);
}

[CRepr]struct IWiaDevMgr2 : IUnknown
{
	public new const Guid IID = .(0x79c07cf1, 0xcbdd, 0x41ee, 0x8e, 0xc3, 0xf0, 0x00, 0x80, 0xca, 0xda, 0x7a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags, IEnumWIA_DEV_INFO** ppIEnum) EnumDeviceInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags, BSTR bstrDeviceID, IWiaItem2** ppWiaItem2Root) CreateDevice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndParent, int32 lDeviceType, int32 lFlags, BSTR* pbstrDeviceID, IWiaItem2** ppItemRoot) SelectDeviceDlg;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndParent, int32 lDeviceType, int32 lFlags, BSTR* pbstrDeviceID) SelectDeviceDlgID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags, BSTR bstrDeviceID, in Guid pEventGUID, IWiaEventCallback* pIWiaEventCallback, IUnknown** pEventObject) RegisterEventCallbackInterface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags, BSTR bstrDeviceID, in Guid pEventGUID, BSTR bstrFullAppName, BSTR bstrCommandLineArg, BSTR bstrName, BSTR bstrDescription, BSTR bstrIcon) RegisterEventCallbackProgram;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags, BSTR bstrDeviceID, in Guid pEventGUID, in Guid pClsID, BSTR bstrName, BSTR bstrDescription, BSTR bstrIcon) RegisterEventCallbackCLSID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags, BSTR bstrDeviceID, HWND hwndParent, BSTR bstrFolderName, BSTR bstrFilename, int32* plNumFiles, BSTR** ppbstrFilePaths, IWiaItem2** ppItem) GetImageDlg;
	}


	public HRESULT EnumDeviceInfo(int32 lFlags, IEnumWIA_DEV_INFO** ppIEnum) mut => VT.[Friend]EnumDeviceInfo(&this, lFlags, ppIEnum);

	public HRESULT CreateDevice(int32 lFlags, BSTR bstrDeviceID, IWiaItem2** ppWiaItem2Root) mut => VT.[Friend]CreateDevice(&this, lFlags, bstrDeviceID, ppWiaItem2Root);

	public HRESULT SelectDeviceDlg(HWND hwndParent, int32 lDeviceType, int32 lFlags, BSTR* pbstrDeviceID, IWiaItem2** ppItemRoot) mut => VT.[Friend]SelectDeviceDlg(&this, hwndParent, lDeviceType, lFlags, pbstrDeviceID, ppItemRoot);

	public HRESULT SelectDeviceDlgID(HWND hwndParent, int32 lDeviceType, int32 lFlags, BSTR* pbstrDeviceID) mut => VT.[Friend]SelectDeviceDlgID(&this, hwndParent, lDeviceType, lFlags, pbstrDeviceID);

	public HRESULT RegisterEventCallbackInterface(int32 lFlags, BSTR bstrDeviceID, in Guid pEventGUID, IWiaEventCallback* pIWiaEventCallback, IUnknown** pEventObject) mut => VT.[Friend]RegisterEventCallbackInterface(&this, lFlags, bstrDeviceID, pEventGUID, pIWiaEventCallback, pEventObject);

	public HRESULT RegisterEventCallbackProgram(int32 lFlags, BSTR bstrDeviceID, in Guid pEventGUID, BSTR bstrFullAppName, BSTR bstrCommandLineArg, BSTR bstrName, BSTR bstrDescription, BSTR bstrIcon) mut => VT.[Friend]RegisterEventCallbackProgram(&this, lFlags, bstrDeviceID, pEventGUID, bstrFullAppName, bstrCommandLineArg, bstrName, bstrDescription, bstrIcon);

	public HRESULT RegisterEventCallbackCLSID(int32 lFlags, BSTR bstrDeviceID, in Guid pEventGUID, in Guid pClsID, BSTR bstrName, BSTR bstrDescription, BSTR bstrIcon) mut => VT.[Friend]RegisterEventCallbackCLSID(&this, lFlags, bstrDeviceID, pEventGUID, pClsID, bstrName, bstrDescription, bstrIcon);

	public HRESULT GetImageDlg(int32 lFlags, BSTR bstrDeviceID, HWND hwndParent, BSTR bstrFolderName, BSTR bstrFilename, int32* plNumFiles, BSTR** ppbstrFilePaths, IWiaItem2** ppItem) mut => VT.[Friend]GetImageDlg(&this, lFlags, bstrDeviceID, hwndParent, bstrFolderName, bstrFilename, plNumFiles, ppbstrFilePaths, ppItem);
}

[CRepr]struct IWiaMiniDrv : IUnknown
{
	public new const Guid IID = .(0xd8cdee14, 0x3c6c, 0x11d2, 0x9a, 0x35, 0x00, 0xc0, 0x4f, 0xa3, 0x61, 0x45);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* __MIDL__IWiaMiniDrv0000, int32 __MIDL__IWiaMiniDrv0001, BSTR __MIDL__IWiaMiniDrv0002, BSTR __MIDL__IWiaMiniDrv0003, IUnknown* __MIDL__IWiaMiniDrv0004, IUnknown* __MIDL__IWiaMiniDrv0005, IWiaDrvItem** __MIDL__IWiaMiniDrv0006, IUnknown** __MIDL__IWiaMiniDrv0007, int32* __MIDL__IWiaMiniDrv0008) drvInitializeWia;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* __MIDL__IWiaMiniDrv0009, int32 __MIDL__IWiaMiniDrv0010, MINIDRV_TRANSFER_CONTEXT* __MIDL__IWiaMiniDrv0011, int32* __MIDL__IWiaMiniDrv0012) drvAcquireItemData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* __MIDL__IWiaMiniDrv0013, int32 __MIDL__IWiaMiniDrv0014, int32* __MIDL__IWiaMiniDrv0015) drvInitItemProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* __MIDL__IWiaMiniDrv0016, int32 __MIDL__IWiaMiniDrv0017, uint32 __MIDL__IWiaMiniDrv0018, PROPSPEC* __MIDL__IWiaMiniDrv0019, int32* __MIDL__IWiaMiniDrv0020) drvValidateItemProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* __MIDL__IWiaMiniDrv0021, int32 __MIDL__IWiaMiniDrv0022, MINIDRV_TRANSFER_CONTEXT* __MIDL__IWiaMiniDrv0023, int32* __MIDL__IWiaMiniDrv0024) drvWriteItemProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* __MIDL__IWiaMiniDrv0025, int32 __MIDL__IWiaMiniDrv0026, uint32 __MIDL__IWiaMiniDrv0027, PROPSPEC* __MIDL__IWiaMiniDrv0028, int32* __MIDL__IWiaMiniDrv0029) drvReadItemProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* __MIDL__IWiaMiniDrv0030, int32 __MIDL__IWiaMiniDrv0031, int32* __MIDL__IWiaMiniDrv0032) drvLockWiaDevice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* __MIDL__IWiaMiniDrv0033, int32 __MIDL__IWiaMiniDrv0034, int32* __MIDL__IWiaMiniDrv0035) drvUnLockWiaDevice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* __MIDL__IWiaMiniDrv0036, int32 __MIDL__IWiaMiniDrv0037, int32* __MIDL__IWiaMiniDrv0038) drvAnalyzeItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 __MIDL__IWiaMiniDrv0039, int32 __MIDL__IWiaMiniDrv0040, PWSTR* __MIDL__IWiaMiniDrv0041, int32* __MIDL__IWiaMiniDrv0042) drvGetDeviceErrorStr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* __MIDL__IWiaMiniDrv0043, int32 __MIDL__IWiaMiniDrv0044, in Guid __MIDL__IWiaMiniDrv0045, IWiaDrvItem** __MIDL__IWiaMiniDrv0046, int32* __MIDL__IWiaMiniDrv0047) drvDeviceCommand;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* __MIDL__IWiaMiniDrv0048, int32 __MIDL__IWiaMiniDrv0049, int32* __MIDL__IWiaMiniDrv0050, WIA_DEV_CAP_DRV** __MIDL__IWiaMiniDrv0051, int32* __MIDL__IWiaMiniDrv0052) drvGetCapabilities;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* __MIDL__IWiaMiniDrv0053, int32 __MIDL__IWiaMiniDrv0054, int32* __MIDL__IWiaMiniDrv0055) drvDeleteItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 __MIDL__IWiaMiniDrv0056, uint8* __MIDL__IWiaMiniDrv0057, int32* __MIDL__IWiaMiniDrv0058) drvFreeDrvItemContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* __MIDL__IWiaMiniDrv0059, int32 __MIDL__IWiaMiniDrv0060, int32* __MIDL__IWiaMiniDrv0061, WIA_FORMAT_INFO** __MIDL__IWiaMiniDrv0062, int32* __MIDL__IWiaMiniDrv0063) drvGetWiaFormatInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid pEventGUID, BSTR bstrDeviceID, uint32 ulReserved) drvNotifyPnpEvent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* __MIDL__IWiaMiniDrv0064) drvUnInitializeWia;
	}


	public HRESULT drvInitializeWia(uint8* __MIDL__IWiaMiniDrv0000, int32 __MIDL__IWiaMiniDrv0001, BSTR __MIDL__IWiaMiniDrv0002, BSTR __MIDL__IWiaMiniDrv0003, IUnknown* __MIDL__IWiaMiniDrv0004, IUnknown* __MIDL__IWiaMiniDrv0005, IWiaDrvItem** __MIDL__IWiaMiniDrv0006, IUnknown** __MIDL__IWiaMiniDrv0007, int32* __MIDL__IWiaMiniDrv0008) mut => VT.[Friend]drvInitializeWia(&this, __MIDL__IWiaMiniDrv0000, __MIDL__IWiaMiniDrv0001, __MIDL__IWiaMiniDrv0002, __MIDL__IWiaMiniDrv0003, __MIDL__IWiaMiniDrv0004, __MIDL__IWiaMiniDrv0005, __MIDL__IWiaMiniDrv0006, __MIDL__IWiaMiniDrv0007, __MIDL__IWiaMiniDrv0008);

	public HRESULT drvAcquireItemData(uint8* __MIDL__IWiaMiniDrv0009, int32 __MIDL__IWiaMiniDrv0010, MINIDRV_TRANSFER_CONTEXT* __MIDL__IWiaMiniDrv0011, int32* __MIDL__IWiaMiniDrv0012) mut => VT.[Friend]drvAcquireItemData(&this, __MIDL__IWiaMiniDrv0009, __MIDL__IWiaMiniDrv0010, __MIDL__IWiaMiniDrv0011, __MIDL__IWiaMiniDrv0012);

	public HRESULT drvInitItemProperties(uint8* __MIDL__IWiaMiniDrv0013, int32 __MIDL__IWiaMiniDrv0014, int32* __MIDL__IWiaMiniDrv0015) mut => VT.[Friend]drvInitItemProperties(&this, __MIDL__IWiaMiniDrv0013, __MIDL__IWiaMiniDrv0014, __MIDL__IWiaMiniDrv0015);

	public HRESULT drvValidateItemProperties(uint8* __MIDL__IWiaMiniDrv0016, int32 __MIDL__IWiaMiniDrv0017, uint32 __MIDL__IWiaMiniDrv0018, PROPSPEC* __MIDL__IWiaMiniDrv0019, int32* __MIDL__IWiaMiniDrv0020) mut => VT.[Friend]drvValidateItemProperties(&this, __MIDL__IWiaMiniDrv0016, __MIDL__IWiaMiniDrv0017, __MIDL__IWiaMiniDrv0018, __MIDL__IWiaMiniDrv0019, __MIDL__IWiaMiniDrv0020);

	public HRESULT drvWriteItemProperties(uint8* __MIDL__IWiaMiniDrv0021, int32 __MIDL__IWiaMiniDrv0022, MINIDRV_TRANSFER_CONTEXT* __MIDL__IWiaMiniDrv0023, int32* __MIDL__IWiaMiniDrv0024) mut => VT.[Friend]drvWriteItemProperties(&this, __MIDL__IWiaMiniDrv0021, __MIDL__IWiaMiniDrv0022, __MIDL__IWiaMiniDrv0023, __MIDL__IWiaMiniDrv0024);

	public HRESULT drvReadItemProperties(uint8* __MIDL__IWiaMiniDrv0025, int32 __MIDL__IWiaMiniDrv0026, uint32 __MIDL__IWiaMiniDrv0027, PROPSPEC* __MIDL__IWiaMiniDrv0028, int32* __MIDL__IWiaMiniDrv0029) mut => VT.[Friend]drvReadItemProperties(&this, __MIDL__IWiaMiniDrv0025, __MIDL__IWiaMiniDrv0026, __MIDL__IWiaMiniDrv0027, __MIDL__IWiaMiniDrv0028, __MIDL__IWiaMiniDrv0029);

	public HRESULT drvLockWiaDevice(uint8* __MIDL__IWiaMiniDrv0030, int32 __MIDL__IWiaMiniDrv0031, int32* __MIDL__IWiaMiniDrv0032) mut => VT.[Friend]drvLockWiaDevice(&this, __MIDL__IWiaMiniDrv0030, __MIDL__IWiaMiniDrv0031, __MIDL__IWiaMiniDrv0032);

	public HRESULT drvUnLockWiaDevice(uint8* __MIDL__IWiaMiniDrv0033, int32 __MIDL__IWiaMiniDrv0034, int32* __MIDL__IWiaMiniDrv0035) mut => VT.[Friend]drvUnLockWiaDevice(&this, __MIDL__IWiaMiniDrv0033, __MIDL__IWiaMiniDrv0034, __MIDL__IWiaMiniDrv0035);

	public HRESULT drvAnalyzeItem(uint8* __MIDL__IWiaMiniDrv0036, int32 __MIDL__IWiaMiniDrv0037, int32* __MIDL__IWiaMiniDrv0038) mut => VT.[Friend]drvAnalyzeItem(&this, __MIDL__IWiaMiniDrv0036, __MIDL__IWiaMiniDrv0037, __MIDL__IWiaMiniDrv0038);

	public HRESULT drvGetDeviceErrorStr(int32 __MIDL__IWiaMiniDrv0039, int32 __MIDL__IWiaMiniDrv0040, PWSTR* __MIDL__IWiaMiniDrv0041, int32* __MIDL__IWiaMiniDrv0042) mut => VT.[Friend]drvGetDeviceErrorStr(&this, __MIDL__IWiaMiniDrv0039, __MIDL__IWiaMiniDrv0040, __MIDL__IWiaMiniDrv0041, __MIDL__IWiaMiniDrv0042);

	public HRESULT drvDeviceCommand(uint8* __MIDL__IWiaMiniDrv0043, int32 __MIDL__IWiaMiniDrv0044, in Guid __MIDL__IWiaMiniDrv0045, IWiaDrvItem** __MIDL__IWiaMiniDrv0046, int32* __MIDL__IWiaMiniDrv0047) mut => VT.[Friend]drvDeviceCommand(&this, __MIDL__IWiaMiniDrv0043, __MIDL__IWiaMiniDrv0044, __MIDL__IWiaMiniDrv0045, __MIDL__IWiaMiniDrv0046, __MIDL__IWiaMiniDrv0047);

	public HRESULT drvGetCapabilities(uint8* __MIDL__IWiaMiniDrv0048, int32 __MIDL__IWiaMiniDrv0049, int32* __MIDL__IWiaMiniDrv0050, WIA_DEV_CAP_DRV** __MIDL__IWiaMiniDrv0051, int32* __MIDL__IWiaMiniDrv0052) mut => VT.[Friend]drvGetCapabilities(&this, __MIDL__IWiaMiniDrv0048, __MIDL__IWiaMiniDrv0049, __MIDL__IWiaMiniDrv0050, __MIDL__IWiaMiniDrv0051, __MIDL__IWiaMiniDrv0052);

	public HRESULT drvDeleteItem(uint8* __MIDL__IWiaMiniDrv0053, int32 __MIDL__IWiaMiniDrv0054, int32* __MIDL__IWiaMiniDrv0055) mut => VT.[Friend]drvDeleteItem(&this, __MIDL__IWiaMiniDrv0053, __MIDL__IWiaMiniDrv0054, __MIDL__IWiaMiniDrv0055);

	public HRESULT drvFreeDrvItemContext(int32 __MIDL__IWiaMiniDrv0056, uint8* __MIDL__IWiaMiniDrv0057, int32* __MIDL__IWiaMiniDrv0058) mut => VT.[Friend]drvFreeDrvItemContext(&this, __MIDL__IWiaMiniDrv0056, __MIDL__IWiaMiniDrv0057, __MIDL__IWiaMiniDrv0058);

	public HRESULT drvGetWiaFormatInfo(uint8* __MIDL__IWiaMiniDrv0059, int32 __MIDL__IWiaMiniDrv0060, int32* __MIDL__IWiaMiniDrv0061, WIA_FORMAT_INFO** __MIDL__IWiaMiniDrv0062, int32* __MIDL__IWiaMiniDrv0063) mut => VT.[Friend]drvGetWiaFormatInfo(&this, __MIDL__IWiaMiniDrv0059, __MIDL__IWiaMiniDrv0060, __MIDL__IWiaMiniDrv0061, __MIDL__IWiaMiniDrv0062, __MIDL__IWiaMiniDrv0063);

	public HRESULT drvNotifyPnpEvent(in Guid pEventGUID, BSTR bstrDeviceID, uint32 ulReserved) mut => VT.[Friend]drvNotifyPnpEvent(&this, pEventGUID, bstrDeviceID, ulReserved);

	public HRESULT drvUnInitializeWia(uint8* __MIDL__IWiaMiniDrv0064) mut => VT.[Friend]drvUnInitializeWia(&this, __MIDL__IWiaMiniDrv0064);
}

[CRepr]struct IWiaMiniDrvCallBack : IUnknown
{
	public new const Guid IID = .(0x33a57d5a, 0x3de8, 0x11d2, 0x9a, 0x36, 0x00, 0xc0, 0x4f, 0xa3, 0x61, 0x45);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lReason, int32 lStatus, int32 lPercentComplete, int32 lOffset, int32 lLength, MINIDRV_TRANSFER_CONTEXT* pTranCtx, int32 lReserved) MiniDrvCallback;
	}


	public HRESULT MiniDrvCallback(int32 lReason, int32 lStatus, int32 lPercentComplete, int32 lOffset, int32 lLength, MINIDRV_TRANSFER_CONTEXT* pTranCtx, int32 lReserved) mut => VT.[Friend]MiniDrvCallback(&this, lReason, lStatus, lPercentComplete, lOffset, lLength, pTranCtx, lReserved);
}

[CRepr]struct IWiaMiniDrvTransferCallback : IUnknown
{
	public new const Guid IID = .(0xa9d2ee89, 0x2ce5, 0x4ff0, 0x8a, 0xdb, 0xc9, 0x61, 0xd1, 0xd7, 0x74, 0xca);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags, BSTR bstrItemName, BSTR bstrFullItemName, IStream** ppIStream) GetNextStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lFlags, WiaTransferParams* pWiaTransferParams) SendMessage;
	}


	public HRESULT GetNextStream(int32 lFlags, BSTR bstrItemName, BSTR bstrFullItemName, IStream** ppIStream) mut => VT.[Friend]GetNextStream(&this, lFlags, bstrItemName, bstrFullItemName, ppIStream);

	public HRESULT SendMessage(int32 lFlags, WiaTransferParams* pWiaTransferParams) mut => VT.[Friend]SendMessage(&this, lFlags, pWiaTransferParams);
}

[CRepr]struct IWiaDrvItem : IUnknown
{
	public new const Guid IID = .(0x1f02b5c5, 0xb00c, 0x11d2, 0xa0, 0x94, 0x00, 0xc0, 0x4f, 0x72, 0xdc, 0x3c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* __MIDL__IWiaDrvItem0000) GetItemFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8** __MIDL__IWiaDrvItem0001) GetDeviceSpecContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* __MIDL__IWiaDrvItem0002) GetFullItemName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* __MIDL__IWiaDrvItem0003) GetItemName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWiaDrvItem* __MIDL__IWiaDrvItem0004) AddItemToFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 __MIDL__IWiaDrvItem0005) UnlinkItemTree;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 __MIDL__IWiaDrvItem0006) RemoveItemFromFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 __MIDL__IWiaDrvItem0007, BSTR __MIDL__IWiaDrvItem0008, IWiaDrvItem** __MIDL__IWiaDrvItem0009) FindItemByName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR __MIDL__IWiaDrvItem0010, IWiaDrvItem** __MIDL__IWiaDrvItem0011) FindChildItemByName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWiaDrvItem** __MIDL__IWiaDrvItem0012) GetParentItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWiaDrvItem** __MIDL__IWiaDrvItem0013) GetFirstChildItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWiaDrvItem** __MIDL__IWiaDrvItem0014) GetNextSiblingItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* __MIDL__IWiaDrvItem0015) DumpItemData;
	}


	public HRESULT GetItemFlags(int32* __MIDL__IWiaDrvItem0000) mut => VT.[Friend]GetItemFlags(&this, __MIDL__IWiaDrvItem0000);

	public HRESULT GetDeviceSpecContext(uint8** __MIDL__IWiaDrvItem0001) mut => VT.[Friend]GetDeviceSpecContext(&this, __MIDL__IWiaDrvItem0001);

	public HRESULT GetFullItemName(BSTR* __MIDL__IWiaDrvItem0002) mut => VT.[Friend]GetFullItemName(&this, __MIDL__IWiaDrvItem0002);

	public HRESULT GetItemName(BSTR* __MIDL__IWiaDrvItem0003) mut => VT.[Friend]GetItemName(&this, __MIDL__IWiaDrvItem0003);

	public HRESULT AddItemToFolder(IWiaDrvItem* __MIDL__IWiaDrvItem0004) mut => VT.[Friend]AddItemToFolder(&this, __MIDL__IWiaDrvItem0004);

	public HRESULT UnlinkItemTree(int32 __MIDL__IWiaDrvItem0005) mut => VT.[Friend]UnlinkItemTree(&this, __MIDL__IWiaDrvItem0005);

	public HRESULT RemoveItemFromFolder(int32 __MIDL__IWiaDrvItem0006) mut => VT.[Friend]RemoveItemFromFolder(&this, __MIDL__IWiaDrvItem0006);

	public HRESULT FindItemByName(int32 __MIDL__IWiaDrvItem0007, BSTR __MIDL__IWiaDrvItem0008, IWiaDrvItem** __MIDL__IWiaDrvItem0009) mut => VT.[Friend]FindItemByName(&this, __MIDL__IWiaDrvItem0007, __MIDL__IWiaDrvItem0008, __MIDL__IWiaDrvItem0009);

	public HRESULT FindChildItemByName(BSTR __MIDL__IWiaDrvItem0010, IWiaDrvItem** __MIDL__IWiaDrvItem0011) mut => VT.[Friend]FindChildItemByName(&this, __MIDL__IWiaDrvItem0010, __MIDL__IWiaDrvItem0011);

	public HRESULT GetParentItem(IWiaDrvItem** __MIDL__IWiaDrvItem0012) mut => VT.[Friend]GetParentItem(&this, __MIDL__IWiaDrvItem0012);

	public HRESULT GetFirstChildItem(IWiaDrvItem** __MIDL__IWiaDrvItem0013) mut => VT.[Friend]GetFirstChildItem(&this, __MIDL__IWiaDrvItem0013);

	public HRESULT GetNextSiblingItem(IWiaDrvItem** __MIDL__IWiaDrvItem0014) mut => VT.[Friend]GetNextSiblingItem(&this, __MIDL__IWiaDrvItem0014);

	public HRESULT DumpItemData(BSTR* __MIDL__IWiaDrvItem0015) mut => VT.[Friend]DumpItemData(&this, __MIDL__IWiaDrvItem0015);
}

[CRepr]struct IWiaVideo : IUnknown
{
	public new const Guid IID = .(0xd52920aa, 0xdb88, 0x41f0, 0x94, 0x6c, 0xe0, 0x0d, 0xc0, 0xa1, 0x9c, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbPreviewVisible) get_PreviewVisible;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL bPreviewVisible) put_PreviewVisible;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrImageDirectory) get_ImagesDirectory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrImageDirectory) put_ImagesDirectory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrWiaDeviceID, HWND hwndParent, BOOL bStretchToFitParent, BOOL bAutoBeginPlayback) CreateVideoByWiaDevID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uiDeviceNumber, HWND hwndParent, BOOL bStretchToFitParent, BOOL bAutoBeginPlayback) CreateVideoByDevNum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrFriendlyName, HWND hwndParent, BOOL bStretchToFitParent, BOOL bAutoBeginPlayback) CreateVideoByName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DestroyVideo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Play;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Pause;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrNewImageFilename) TakePicture;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL bStretchToFitParent) ResizeVideo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WIAVIDEO_STATE* pState) GetCurrentState;
	}


	public HRESULT get_PreviewVisible(BOOL* pbPreviewVisible) mut => VT.[Friend]get_PreviewVisible(&this, pbPreviewVisible);

	public HRESULT put_PreviewVisible(BOOL bPreviewVisible) mut => VT.[Friend]put_PreviewVisible(&this, bPreviewVisible);

	public HRESULT get_ImagesDirectory(BSTR* pbstrImageDirectory) mut => VT.[Friend]get_ImagesDirectory(&this, pbstrImageDirectory);

	public HRESULT put_ImagesDirectory(BSTR bstrImageDirectory) mut => VT.[Friend]put_ImagesDirectory(&this, bstrImageDirectory);

	public HRESULT CreateVideoByWiaDevID(BSTR bstrWiaDeviceID, HWND hwndParent, BOOL bStretchToFitParent, BOOL bAutoBeginPlayback) mut => VT.[Friend]CreateVideoByWiaDevID(&this, bstrWiaDeviceID, hwndParent, bStretchToFitParent, bAutoBeginPlayback);

	public HRESULT CreateVideoByDevNum(uint32 uiDeviceNumber, HWND hwndParent, BOOL bStretchToFitParent, BOOL bAutoBeginPlayback) mut => VT.[Friend]CreateVideoByDevNum(&this, uiDeviceNumber, hwndParent, bStretchToFitParent, bAutoBeginPlayback);

	public HRESULT CreateVideoByName(BSTR bstrFriendlyName, HWND hwndParent, BOOL bStretchToFitParent, BOOL bAutoBeginPlayback) mut => VT.[Friend]CreateVideoByName(&this, bstrFriendlyName, hwndParent, bStretchToFitParent, bAutoBeginPlayback);

	public HRESULT DestroyVideo() mut => VT.[Friend]DestroyVideo(&this);

	public HRESULT Play() mut => VT.[Friend]Play(&this);

	public HRESULT Pause() mut => VT.[Friend]Pause(&this);

	public HRESULT TakePicture(BSTR* pbstrNewImageFilename) mut => VT.[Friend]TakePicture(&this, pbstrNewImageFilename);

	public HRESULT ResizeVideo(BOOL bStretchToFitParent) mut => VT.[Friend]ResizeVideo(&this, bStretchToFitParent);

	public HRESULT GetCurrentState(WIAVIDEO_STATE* pState) mut => VT.[Friend]GetCurrentState(&this, pState);
}

[CRepr]struct IWiaUIExtension2 : IUnknown
{
	public new const Guid IID = .(0x305600d7, 0x5088, 0x46d7, 0x9a, 0x15, 0xb7, 0x7b, 0x09, 0xcd, 0xba, 0x7a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DEVICEDIALOGDATA2* pDeviceDialogData) DeviceDialog;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDeviceId, HICON* phIcon, uint32 nSize) GetDeviceIcon;
	}


	public HRESULT DeviceDialog(DEVICEDIALOGDATA2* pDeviceDialogData) mut => VT.[Friend]DeviceDialog(&this, pDeviceDialogData);

	public HRESULT GetDeviceIcon(BSTR bstrDeviceId, HICON* phIcon, uint32 nSize) mut => VT.[Friend]GetDeviceIcon(&this, bstrDeviceId, phIcon, nSize);
}

[CRepr]struct IWiaUIExtension : IUnknown
{
	public new const Guid IID = .(0xda319113, 0x50ee, 0x4c80, 0xb4, 0x60, 0x57, 0xd0, 0x05, 0xd4, 0x4a, 0x2c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DEVICEDIALOGDATA* pDeviceDialogData) DeviceDialog;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDeviceId, HICON* phIcon, uint32 nSize) GetDeviceIcon;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDeviceId, HBITMAP* phBitmap, uint32 nMaxWidth, uint32 nMaxHeight) GetDeviceBitmapLogo;
	}


	public HRESULT DeviceDialog(DEVICEDIALOGDATA* pDeviceDialogData) mut => VT.[Friend]DeviceDialog(&this, pDeviceDialogData);

	public HRESULT GetDeviceIcon(BSTR bstrDeviceId, HICON* phIcon, uint32 nSize) mut => VT.[Friend]GetDeviceIcon(&this, bstrDeviceId, phIcon, nSize);

	public HRESULT GetDeviceBitmapLogo(BSTR bstrDeviceId, HBITMAP* phBitmap, uint32 nMaxWidth, uint32 nMaxHeight) mut => VT.[Friend]GetDeviceBitmapLogo(&this, bstrDeviceId, phBitmap, nMaxWidth, nMaxHeight);
}

#endregion
