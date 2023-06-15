#!/bin/bash
set -e

download_file() {
	file_location=$1
	uri=$(echo $file_location | awk -F "?" '{print $1}')
	echo $file_location
	downloaded_file=$(basename $uri)
	curl -L $file_location --output $downloaded_file && echo $downloaded_file
}

if [[ -z $APPDOME_API_KEY ]]; then
	echo 'APPDOME_API_KEY must be provided as a Secret. Exiting.'
	exit 1
fi

if [[ $AC_APPDOME_APP_PATH == *"http"* ]];
then
	app_file=../$(download_file $AC_APPDOME_APP_PATH)
else
	app_file=$AC_APPDOME_APP_PATH
fi
certificate_output=$AC_REPOSITORY_DIR/certificate.pdf
secured_app_output=$AC_REPOSITORY_DIR/Appdome_$(basename $app_file)


tm=""
if [[ -n $AC_APPDOME_TEAM_ID ]]; then
	tm="--team_id ${team_id}"
fi

git clone https://github.com/Appdome/appdome-api-bash.git > /dev/null
cd appdome-api-bash

echo "Android platform detected"

cf=""
if [[ -n $SIGN_FINGERPRINT ]]; then
	cf="--signing_fingerprint ${SIGN_FINGERPRINT}"
fi

gp=""
if [[ $AC_APPDOME_GP_SIGNING == "true" ]]; then
	gp="--google_play_signing"
	if [[ -z $AC_GOOGLE_SIGN_FINGERPRINT ]]; then
		echo "AC_GOOGLE_SIGN_FINGERPRINT must be provided as a Secret for Google Play signing. Exiting."
		exit 1
	fi
	cf="--signing_fingerprint ${AC_GOOGLE_SIGN_FINGERPRINT}"
fi

bl=""
if [[ $AC_APPDOME_BUILD_LOGS == "true" ]]; then
	bl="-bl"
fi

case $AC_APPDOME_SIGN_METHOD in
"Private-Signing")		echo "Private Signing"
						./appdome_api.sh --api_key $APPDOME_API_KEY \
							--app $app_file \
							--fusion_set_id $AC_APPDOME_FUSION_SET_ID \
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
							--fusion_set_id $AC_APPDOME_FUSION_SET_ID \
							$tm \
							--auto_dev_private_signing \
							$gp \
							$cf \
							$bl \
							--output $secured_app_output \
							--certificate_output $certificate_output 
						;;
"On-Appdome")			echo "On Appdome Signing"
						keystore_file=$AC_ANDROID_KEYSTORE_PATH
						keystore_pass=$AC_ANDROID_KEYSTORE_PASSWORD
						keystore_alias=$AC_ANDROID_ALIAS
						key_pass=$AC_ANDROID_ALIAS_PASSWORD
						echo ./appdome_api.sh --api_key $APPDOME_API_KEY \
							--app $app_file \
							--fusion_set_id $AC_APPDOME_FUSION_SET_ID \
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

rm -rf appdome-api-bash
if [[ $secured_app_output == *.sh ]]; then
	echo "AC_APPDOME_PRIVATE_SIGN_SCRIPT_PATH=$secured_app_output" >> $AC_ENV_FILE_PATH
elif [[ $secured_app_output == *.apk ]]; then
	echo "AC_APPDOME_PRIVATE_SIGN_SCRIPT_PATH=$secured_app_output" >> $AC_ENV_FILE_PATH
else
	echo "AC_APPDOME_PRIVATE_SIGN_SCRIPT_PATH=$secured_app_output" >> $AC_ENV_FILE_PATH
fi
echo "AC_APPDOME_CERTIFICATE_PATH=$certificate_output" >> $AC_ENV_FILE_PATH