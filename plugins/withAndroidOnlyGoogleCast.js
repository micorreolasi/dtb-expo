const { createRunOncePlugin } = require('@expo/config-plugins');
const { withAndroidGoogleCast } = require('react-native-google-cast/lib/commonjs/plugin/withAndroidGoogleCast');

const withAndroidOnlyGoogleCast = (config, props = {}) => {
  return withAndroidGoogleCast(config, {
    receiverAppId: props.receiverAppId || 'CC1AD845',
    expandedController: props.expandedController ?? false,
    androidPlayServicesCastFrameworkVersion: props.androidPlayServicesCastFrameworkVersion
  });
};

module.exports = createRunOncePlugin(withAndroidOnlyGoogleCast, 'with-android-only-google-cast');
