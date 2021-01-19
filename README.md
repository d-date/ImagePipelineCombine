<a href="https://swift.org/package-manager/"><img src="https://img.shields.io/badge/SPM-ready-orange.svg"></a>
<a href="https://github.com/d-date/ImagePipelineCombine/blob/master/LICENSE"><img alt="MIT License" src="http://img.shields.io/badge/license-MIT-blue.svg"/></a>

# ImagePipelineCombine

An image loading and caching framework for SwiftUI using Combine.

This framework respects [ImagePipeline](https://github.com/folio-sec/ImagePipeline), but cutting off image process feature.

## Usage


### For SwiftUI
By using RemoteImage confirming to SwiftUI.View, fetch image with URL and cache on memory.

```swift
var body: some View {
  RemoteImage(url: url, defaultImage: defaultImage)
}
```

### Using Publisher

```swift
  let pipeline = ImagePipeline()
  pipeline.load(url)
    .sink { (completion) in

    } receiveValue: { (image) in
    
    }
  }
  .store(in: &cancellables)  
```

## Supported content types

✅ PNG  
✅ JPEG  
✅ GIF  
✅ WebP 

## Supported platforms
- macOS v10.15 and later
- iOS v13.0 and later
- tvOS v13.0 and later

Note: watchOS is not supported now since SnapshotTesting is not supported for watchOS.

## Work in progress
- [ ] Disk Caching
- [ ] Image Processing

## Installation

Only support via Swift package manager installation.

### Swift Package Manager

```swift
dependencies: [
  .package(url: "https://github.com/d-date/ImagePipelineCombine.git", from: "0.1.0")
]
```

