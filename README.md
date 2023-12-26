# Appcircle _Appdome Build-to-Secure for Android_ component

Integration that allows activating security and app protection features, building and signing mobile apps using Appdome's API

## Required Inputs

- `AC_APPDOME_APP_PATH`: App file URL or environment variable. URL to app file (apk/aab) or an environment variable representing its path (i.e. $AC_APK_PATH or $AC_AAB_PATH)
- `AC_APPDOME_FUSION_SET_ID`: Appdome Fusion set ID
- `AC_APPDOME_SIGN_METHOD`: App signing method.
- `AC_APPDOME_GP_SIGNING`: Sign the app for Google Play? If 'true', requires $AC_SIGN_FINGERPRINT in the Secrets tab.
- `AC_APPDOME_BUILD_LOGS`: Build with diagnostic logs?

## Optional Inputs

- `AC_APPDOME_TEAM_ID`: Appdome Team ID.

## Output Variables

- `AC_APPDOME_SECURED_APK_PATH`: Local path of the secured .apk file. Available when 'Signing Method' set to 'On-Appdome' or 'Private-Signing'.
- `AC_APPDOME_SECURED_AAB_PATH`: Local path of the secured .aab file. Available when 'Signing Method' set to 'On-Appdome' or 'Private-Signing'.
- `AC_APPDOME_PRIVATE_SIGN_SCRIPT_PATH`: Local path of the .sh sign script file. Available when 'Signing Method' set to 'Auto-Dev-Signing
- `AC_APPDOME_CERTIFICATE_PATH`: Local path of the Certified Secure Certificate .pdf file
