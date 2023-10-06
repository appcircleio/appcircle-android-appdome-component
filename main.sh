#!/bin/bash
set -e

APPDOME_APP_PATH=$AC_APPDOME_APP_PATH
APPDOME_API_KEY=$AC_APPDOME_API_KEY
APPDOME_FUSION_SET_ID=$AC_APPDOME_FUSION_SET_ID
APPDOME_TEAM_ID=$AC_APPDOME_TEAM_ID
APPDOME_SIGN_METHOD=$AC_APPDOME_SIGN_METHOD
APPDOME_GP_SIGNING=$AC_APPDOME_GP_SIGNING
APPDOME_BUILD_LOGS=$AC_APPDOME_BUILD_LOGS
ANDROID_KEYSTORE_PATH=$AC_ANDROID_KEYSTORE_PATH

download_file() {
	file_location=$1
	uri=$(echo $file_location | awk -F "?" '{print $1}')
	echo $file_location
	downloaded_file=$(basename $uri)
	curl -L $file_location --output $downloaded_file && echo $downloaded_file
}

if [[ $APPDOME_APP_PATH == *"http"* ]];
then
	app_file=AC_REPOSITORY_DIR/$(download_file $APPDOME_APP_PATH)
else
	app_file=$APPDOME_APP_PATH
fi
certificate_output=AC_REPOSITORY_DIR/certificate.pdf
secured_app_output=AC_REPOSITORY_DIR/Appdome_$(basename $app_file)

tm=""
if [[ -n $APPDOME_TEAM_ID ]]; then
	tm="--team_id ${team_id}"
fi

cp "$ANDROID_KEYSTORE_PATH" "$ANDROID_KEYSTORE_PATH.keystore"

git clone https://github.com/Appdome/appdome-api-bash.git > /dev/null
cd appdome-api-bash

cf=""
if [[ -n $SIGN_FINGERPRINT ]]; then
	cf="--signing_fingerprint ${SIGN_FINGERPRINT}"
fi

gp=""
if [[ $APPDOME_GP_SIGNING == "true" ]]; then
	gp="--google_play_signing"
	if [[ -z $AC_GOOGLE_SIGN_FINGERPRINT ]]; then
		echo "AC_GOOGLE_SIGN_FINGERPRINT must be provided as a Secret for Google Play signing. Exiting."
		exit 1
	fi
	cf="--signing_fingerprint ${AC_GOOGLE_SIGN_FINGERPRINT}"
fi

bl=""
if [[ $APPDOME_BUILD_LOGS == "true" ]]; then
	bl="-bl"
fi

case $APPDOME_SIGN_METHOD in
"Private-Signing")		echo "Private Signing"
						./appdome_api.sh --api_key $APPDOME_API_KEY \
							--app $app_file \
							--fusion_set_id $APPDOME_FUSION_SET_ID \
							$tm \
							--private_signing \
							$gp \
							$cf \
							$bl \
							--output $secured_app_output \
							--certificate_output $certificate_output 
						;;
"Auto-Dev-Signing")		echo "Auto Dev Signing"
						./appdome_api.sh --api_key $APPDOME_API_KEY \
							--app $app_file \
							--fusion_set_id $APPDOME_FUSION_SET_ID \
							$tm \
							--auto_dev_private_signing \
							$gp \
							$cf \
							$bl \
							--output $secured_app_output \
							--certificate_output $certificate_output 
						;;
"On-Appdome")			echo "On Appdome Signing"
						keystore_file="$ANDROID_KEYSTORE_PATH.keystore"
						keystore_pass=$AC_ANDROID_KEYSTORE_PASSWORD
						keystore_alias=$AC_ANDROID_ALIAS
						key_pass=$AC_ANDROID_ALIAS_PASSWORD
						./appdome_api.sh --api_key $APPDOME_API_KEY \
							--app $app_file \
							--fusion_set_id $APPDOME_FUSION_SET_ID \
							$tm \
							--sign_on_appdome \
							--keystore $keystore_file \
							--keystore_pass $keystore_pass \
							--keystore_alias $keystore_alias \
							$gp \
							$cf \
							$bl \
							--key_pass $key_pass \
							--output $secured_app_output \
							--certificate_output $certificate_output 
						;;
esac

echo "Outputs are being prepared."

if [[ $secured_app_output == *.sh ]]; then
	echo "AC_APPDOME_PRIVATE_SIGN_SCRIPT_PATH=$secured_app_output" >> $AC_ENV_FILE_PATH
elif [[ $secured_app_output == *.apk ]]; then
	echo "AC_APPDOME_SECURED_APK_PATH=$secured_app_output" >> $AC_ENV_FILE_PATH
elif [[ $secured_app_output == *.aab ]]; then
	echo "AC_APPDOME_SECURED_AAB_PATH=$secured_app_output" >> $AC_ENV_FILE_PATH
else
	echo "Secured app output is undefined: $secured_app_output"
	exit 1
fi

cp $secured_app_output $AC_OUTPUT_DIR
cp $certificate_output $AC_OUTPUT_DIR
echo "AC_APPDOME_CERTIFICATE_PATH=$certificate_output" >> $AC_ENV_FILE_PATH