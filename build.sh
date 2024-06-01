WORKING_LOCATION="$(pwd)"
APPLICATION_NAME=GeoCCMod  # Only change this line
BUILD_SCHEME=Release

if [ -d "build" ]; then
    rm -r build
fi
if [ ! -d "build" ]; then
    mkdir build
fi

cd build

xcodebuild -project "$WORKING_LOCATION/$APPLICATION_NAME.xcodeproj" \
    -scheme "$APPLICATION_NAME" \
    -configuration $BUILD_SCHEME \
    -derivedDataPath "$WORKING_LOCATION/build/DerivedDataApp" \
    -destination 'generic/platform=iOS' \
    clean build \
    CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGN_ENTITLEMENTS="" CODE_SIGNING_ALLOWED="NO"
    
# Handle build failure
if [ $? != 0 ]; then
    echo "=== Exiting w/ build failure ==="
    cd ..
    rm -r build
    exit 1
fi

# Copy .app to build folder
DD_APP_PATH="$WORKING_LOCATION/build/DerivedDataApp/Build/Products/$BUILD_SCHEME-iphoneos/$APPLICATION_NAME.app"
TARGET_APP="$WORKING_LOCATION/build/$APPLICATION_NAME.app"
cp -r "$DD_APP_PATH" "$TARGET_APP"

# Strip and remove code signing
strip "$TARGET_APP/$APPLICATION_NAME"
codesign --remove "$TARGET_APP"
if [ -e "$TARGET_APP/_CodeSignature" ]; then
    rm -rf "$TARGET_APP/_CodeSignature"
fi
if [ -e "$TARGET_APP/embedded.mobileprovision" ]; then
    rm -rf "$TARGET_APP/embedded.mobileprovision"
fi

# Add entitlements
echo "=== Adding entitlements ==="
ldid -S"$WORKING_LOCATION/$APPLICATION_NAME/$APPLICATION_NAME.entitlements" "$TARGET_APP/$APPLICATION_NAME"
echo "=== Done adding entitlements ==="

# Package
mkdir Payload
cp -r "$APPLICATION_NAME.app" Payload/
zip -vr "$APPLICATION_NAME.tipa" Payload
rm -r Payload

echo "=== All Done !! ==="
echo "Location: $WORKING_LOCATION/build/$APPLICATION_NAME.tipa"
