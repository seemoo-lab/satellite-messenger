APP_PATH=$HOME"/Library/Developer/Xcode/DerivedData/StewieMessenger-*/Build/Products/Debug-iphoneos/StewieMessenger.app"
ENT_PATH=$(pwd)"/StewieMessenger"

rm -r ./Payload 
rm StewieMessenger.tipa
mkdir ./Payload 
cp -r $APP_PATH ./Payload/StewieMessenger.app
ldid -S$ENT_PATH/StewieMessenger-JB.entitlements ./Payload/StewieMessenger.app/StewieMessenger
zip -r StewieMessenger.tipa ./Payload
