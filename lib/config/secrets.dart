library;

const String kAdmobAppId =
    String.fromEnvironment('ADMOB_APP_ID', defaultValue: '');

const String kShareBannerUnitId =
    String.fromEnvironment('ADMOB_SHARE_BANNER_UNIT_ID', defaultValue: '');

const String kEditPageBannerUnitId =
    String.fromEnvironment('ADMOB_EDIT_PAGE_BANNER_UNIT_ID', defaultValue: '');

const String kInterstitialShareUnitId =
    String.fromEnvironment('ADMOB_INTERSTITIAL_SHARE_UNIT_ID', defaultValue: '');

const String kInterstitialPreviewUnitId =
    String.fromEnvironment('ADMOB_INTERSTITIAL_PREVIEW_UNIT_ID',
        defaultValue: '');

const String kBitlyApiToken =
    String.fromEnvironment('BITLY_API_TOKEN', defaultValue: '');
