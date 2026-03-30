# Image Viewer Design

**Date:** 2026-03-30
**Feature:** Tap-to-enlarge with pinch-to-zoom for quest screenshots

## Summary

Add a fullscreen image viewer that appears when the user taps any screenshot in a quest detail view. The viewer supports pinch-to-zoom (via a UIScrollView wrapper) and can be dismissed by tapping, swiping down, or tapping a close button.

## Components

### New: `ZoomableScrollView.swift`

A `UIViewRepresentable` wrapping a `UIScrollView` containing a `UIImageView`.

- Accepts a `UIImage`
- Configures `minimumZoomScale = 1.0`, `maximumZoomScale = 5.0`
- Centers the image in the scroll view at all zoom levels (via `UIScrollViewDelegate.scrollViewDidZoom`)
- Implements `UIScrollViewDelegate.viewForZooming` to return the `UIImageView`
- No SwiftUI dependencies — fully self-contained

### New: `ImageViewerOverlay.swift`

A SwiftUI `View` that presents the zoomable image as a fullscreen overlay.

- Black background (`Color.black`)
- Hosts `ZoomableScrollView` filling the safe area
- `@Binding var image: UIImage?` — set to `nil` to dismiss
- Appears/disappears with `.opacity` animation (fade in/out)
- **Tap to dismiss:** a `TapGesture` on the overlay dismisses when zoom scale is 1× (detected via a `@State` published from the scroll view coordinator); ignored when zoomed in so the user can reposition
- **Swipe down to dismiss:** a `DragGesture` tracks vertical offset; releasing with sufficient downward velocity or displacement sets `image = nil` and animates back otherwise
- **Close button:** `✕` button top-right corner, always visible, dismisses unconditionally

### Modified: `QuestDetailView.swift`

Small change to the `.image` case in `blockView()`:

- Add `@State private var selectedImage: UIImage?`
- Wrap the existing `Image(uiImage:)` block in a `Button` that sets `selectedImage`
- Add a visual affordance on the image (a small magnifying glass icon overlay, bottom-right corner) so it's clear the image is tappable
- Add `.overlay(alignment: .top)` on the `ScrollView` to present `ImageViewerOverlay(image: $selectedImage)` when non-nil

## Interaction Flow

1. User taps screenshot → `selectedImage` set → `ImageViewerOverlay` fades in
2. User pinches to zoom / pans (UIScrollView native behavior)
3. Dismiss via:
   - a. Tap image at 1× zoom → fade out
   - b. Swipe down → tracks drag, releases → dismisses
   - c. Tap ✕ button → dismisses unconditionally

## Out of Scope

- Sharing or saving images
- Swiping between multiple images (gallery mode)
- Caption or filename display in the viewer
