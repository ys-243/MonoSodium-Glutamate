# For building iOS app
The release.yml script uses the ```--no-codesign flag```, so it bypasses the need for Apple Developer certificates. 
However, the build will still fail unless your local Flutter project has its metadata correctly structured for iOS. To fix this:

1. Run pod install locally: Ensure you have opened your terminal and run 
```terminal
cd ios && pod install
```
at least once locally to generate the correct Podfiles. Commit any changes to the repository.

2. Set a Bundle Identifier: Your project must have a valid bundle ID (e.g., ```com.yourname.appname```). You can set this in Xcode or inside the ```ios/Runner.xcodeproj/project.pbxproj``` file.