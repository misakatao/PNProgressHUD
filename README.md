# PNProgressHUD

[![Version](https://img.shields.io/cocoapods/v/PNProgressHUD.svg?style=flat)](https://cocoapods.org/pods/PNProgressHUD)
[![License](https://img.shields.io/cocoapods/l/PNProgressHUD.svg?style=flat)](https://cocoapods.org/pods/PNProgressHUD)
[![Platform](https://img.shields.io/cocoapods/p/PNProgressHUD.svg?style=flat)](https://cocoapods.org/pods/PNProgressHUD)

A clean, lightweight progress HUD for iOS, written in Swift. Supports loading indicators, progress rings, success/error/info states, and plain text messages with customizable styles and mask types.

## Features

- Loading indicator with optional status text
- Determinate progress ring animation
- Success / Error / Info status display with icons
- Plain text message (no icon)
- Three visual styles: Light, Dark, Custom
- Five mask types: None, Clear, Black, Gradient, Custom
- Haptic feedback support
- Grace time to avoid flashing for quick operations
- Parallax motion effect
- Notification-based lifecycle events

## Requirements

- iOS 11.0+
- Swift 5.0+
- Xcode 14+

## Installation

### CocoaPods

Add the following to your `Podfile`:

```ruby
pod 'PNProgressHUD'
```

Then run:

```bash
pod install
```

## Usage

### Show Loading

```swift
import PNProgressHUD

// Show loading with status text
ProgressHUD.show("Loading...")

// Show loading without text
ProgressHUD.show()

// Dismiss
ProgressHUD.dismiss()
```

### Show Progress

```swift
// Show determinate progress (0.0 ~ 1.0)
ProgressHUD.show("Uploading...", 0.5)
```

### Show Status Messages

```swift
// Success
ProgressHUD.showSuccess("Done!")

// Error
ProgressHUD.showError("Failed")

// Info
ProgressHUD.showInfo("FYI")

// Plain text message (auto-dismiss)
ProgressHUD.showMessage("Hello")
```

### Dismiss

```swift
// Dismiss immediately
ProgressHUD.dismiss()

// Dismiss with delay
ProgressHUD.dismiss(1.0)

// Dismiss with delay and completion
ProgressHUD.dismiss(1.0) {
    print("HUD dismissed")
}
```

### Customization

```swift
let hud = ProgressHUD.shared

// Style
hud.defaultStyle = .dark          // .light, .dark, .custom

// Mask type
hud.defaultMaskType = .black      // .none, .clear, .black, .gradient, .custom

// Animation type
hud.defaultAnimationType = .flat  // .flat (ring), .native (UIActivityIndicator)

// Appearance
hud.font = .systemFont(ofSize: 14)
hud.cornerRadius = 14.0
hud.minimumSize = CGSize(width: 100, height: 100)

// Ring
hud.ringThickness = 2.0
hud.ringRadius = 18.0
hud.ringNoTextRadius = 24.0

// Colors (used when style is .custom)
hud.customColor = .black          // HUD background
hud.foregroundColor = .white      // Text and icon tint
hud.foregroundImageColor = .white // Icon tint override
hud.backgroundLayerColor = UIColor(white: 0, alpha: 0.4)

// Timing
hud.graceTimeInterval = 0         // Delay before showing
hud.minimumDismissTimeInterval = 5.0
hud.fadeInAnimationDuration = 0.15
hud.fadeOutAnimationDuration = 0.15

// Misc
hud.hapticsEnabled = false
hud.motionEffectEnabled = true
hud.imageViewSize = CGSize(width: 28, height: 28)
hud.offsetFromCenter = .zero
```

### Custom Images

```swift
let hud = ProgressHUD.shared
hud.infoImage = UIImage(named: "custom_info")
hud.successImage = UIImage(named: "custom_success")
hud.errorImage = UIImage(named: "custom_error")
```

### Container View

By default the HUD is displayed on the front window. To show it inside a specific view:

```swift
ProgressHUD.shared.containerView = myView
ProgressHUD.show("Loading...")
```

### Notifications

Observe HUD lifecycle events:

```swift
NotificationCenter.default.addObserver(
    self,
    selector: #selector(hudDidAppear),
    name: ProgressHUD.didAppearNotification,
    object: nil
)
```

Available notifications:
- `ProgressHUD.willAppearNotification`
- `ProgressHUD.didAppearNotification`
- `ProgressHUD.willDisappearNotification`
- `ProgressHUD.didDisappearNotification`
- `ProgressHUD.didReceiveTouchEventNotification`
- `ProgressHUD.didTouchDownInsideNotification`

## Example

To run the example project, clone the repo and run `pod install` from the `Example` directory:

```bash
git clone https://github.com/misakatao/PNProgressHUD.git
cd PNProgressHUD/Example
pod install
open PNProgressHUD.xcworkspace
```

## Author

misakatao (misakatao@gmail.com)

## License

PNProgressHUD is available under the MIT license. See the [LICENSE](LICENSE) file for details.
