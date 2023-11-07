rm -r ./.build
rm -r ./Sources/EngineCore/EngineCore.xcframework

CONFIG=Release

xcodebuild archive \
    -project ./Sources/EngineCore/EngineCore.xcodeproj \
    -scheme EngineCore \
    -configuration $CONFIG \
    -archivePath ./.build/macOS \
    -destination "generic/platform=macOS,name=Any Mac" \
    clean \
    | xcpretty

xcodebuild archive \
    -project ./Sources/EngineCore/EngineCore.xcodeproj \
    -scheme EngineCore \
    -configuration $CONFIG \
    -archivePath ./.build/macCatalyst \
    -destination "generic/platform=macOS,variant=Mac Catalyst" \
    clean \
    | xcpretty

xcodebuild archive \
    -project ./Sources/EngineCore/EngineCore.xcodeproj \
    -scheme EngineCore \
    -configuration $CONFIG \
    -archivePath ./.build/iOS \
    -destination "generic/platform=iOS" \
    clean \
    | xcpretty

xcodebuild archive \
    -project ./Sources/EngineCore/EngineCore.xcodeproj \
    -scheme EngineCore \
    -configuration $CONFIG \
    -archivePath ./.build/iOSSimulator \
    -destination "generic/platform=iOS Simulator" \
    clean \
    | xcpretty

xcodebuild archive \
    -project ./Sources/EngineCore/EngineCore.xcodeproj \
    -scheme EngineCore \
    -configuration $CONFIG \
    -archivePath ./.build/tvOS \
    -destination "generic/platform=tvOS" \
    clean \
    | xcpretty

xcodebuild archive \
    -project ./Sources/EngineCore/EngineCore.xcodeproj \
    -scheme EngineCore \
    -configuration $CONFIG \
    -archivePath ./.build/tvOSSimulator \
    -destination "generic/platform=tvOS Simulator" \
    clean \
    | xcpretty

xcodebuild archive \
    -project ./Sources/EngineCore/EngineCore.xcodeproj \
    -scheme EngineCore \
    -configuration $CONFIG \
    -archivePath ./.build/watchOS \
    -destination "generic/platform=watchOS" \
    clean \
    | xcpretty

xcodebuild archive \
    -project ./Sources/EngineCore/EngineCore.xcodeproj \
    -scheme EngineCore \
    -configuration $CONFIG \
    -archivePath ./.build/watchOSSimulator \
    -destination "generic/platform=watchOS Simulator" \
    clean \
    | xcpretty

#xcodebuild archive \
#    -project ./Sources/EngineCore/EngineCore.xcodeproj \
#    -scheme EngineCore \
#    -configuration $CONFIG \
#    -archivePath ./.build/visionOS \
#    -destination "generic/platform=visionOS" \
#    clean \
#    | xcpretty
#
#xcodebuild archive \
#    -project ./Sources/EngineCore/EngineCore.xcodeproj \
#    -scheme EngineCore \
#    -configuration $CONFIG \
#    -archivePath ./.build/visionOSSimulator \
#    -destination "generic/platform=visionOS Simulator" \
#    clean \
#    | xcpretty

#    -framework ./.build/visionOS.xcarchive/Products/Library/Frameworks/EngineCore.framework \
#    -framework ./.build/visionOSSimulator.xcarchive/Products/Library/Frameworks/EngineCore.framework \

xcodebuild -create-xcframework \
    -framework ./.build/macOS.xcarchive/Products/Library/Frameworks/EngineCore.framework \
    -framework ./.build/macCatalyst.xcarchive/Products/Library/Frameworks/EngineCore.framework \
    -framework ./.build/iOS.xcarchive/Products/Library/Frameworks/EngineCore.framework \
    -framework ./.build/iOSSimulator.xcarchive/Products/Library/Frameworks/EngineCore.framework \
    -framework ./.build/tvOS.xcarchive/Products/Library/Frameworks/EngineCore.framework \
    -framework ./.build/tvOSSimulator.xcarchive/Products/Library/Frameworks/EngineCore.framework \
    -framework ./.build/watchOS.xcarchive/Products/Library/Frameworks/EngineCore.framework \
    -framework ./.build/watchOSSimulator.xcarchive/Products/Library/Frameworks/EngineCore.framework \
    -output ./Sources/EngineCore/EngineCore.xcframework \
    | xcpretty

cd ./Sources/EngineCore
zip -r -y ./EngineCore.xcframework.zip ./EngineCore.xcframework
cd ../..
swift package compute-checksum ./Sources/EngineCore/EngineCore.xcframework.zip
