# Image Viewer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let users tap any screenshot in a quest detail view to open a fullscreen, pinch-to-zoom image overlay.

**Architecture:** Two new files — `ZoomableScrollView` (UIViewRepresentable wrapping UIScrollView for native zoom) and `ImageViewerOverlay` (SwiftUI fullscreen dark overlay) — plus a small change to `QuestDetailView` to make image blocks tappable.

**Tech Stack:** SwiftUI, UIKit (UIScrollView/UIImageView via UIViewRepresentable), XCTest + SnapshotTesting

---

## File Map

| File | Action | Responsibility |
|------|--------|----------------|
| `app/Sources/Views/QuestDetail/ZoomableScrollView.swift` | Create | UIScrollView wrapper; handles pinch zoom, pan, centering |
| `app/Sources/Views/QuestDetail/ImageViewerOverlay.swift` | Create | Fullscreen overlay; tap/swipe dismiss, close button |
| `app/Sources/Views/QuestDetail/QuestDetailView.swift` | Modify | Add `selectedImage` state, wrap image blocks in Button, present overlay |
| `app/Tests/SnapshotTests.swift` | Modify | Add snapshot for ImageViewerOverlay; re-record QuestDetail |

---

## Task 1: ZoomableScrollView

**Files:**
- Create: `app/Sources/Views/QuestDetail/ZoomableScrollView.swift`
- Modify: `app/Tests/SnapshotTests.swift`

- [ ] **Step 1: Write the failing snapshot test**

Add to `app/Tests/SnapshotTests.swift` inside `final class SnapshotTests`:

```swift
func test_zoomableScrollView_snapshot() {
    // Use a simple 300×200 solid-color image as fixture
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 200))
    let uiImage = renderer.image { ctx in
        UIColor.systemGreen.setFill()
        ctx.fill(CGRect(x: 0, y: 0, width: 300, height: 200))
    }
    snapshotView(
        ZoomableScrollView(image: uiImage, zoomScale: .constant(1.0))
            .frame(width: 390, height: 300),
        named: "ZoomableScrollView"
    )
}
```

- [ ] **Step 2: Run test to confirm it fails**

```
xcodebuild test -scheme TOTKWalkthrough -destination 'platform=iOS Simulator,name=iPhone 15' -testIdentifier 'SnapshotTests/test_zoomableScrollView_snapshot' 2>&1 | tail -20
```

Expected: compile error — `ZoomableScrollView` does not exist yet.

- [ ] **Step 3: Create ZoomableScrollView.swift**

Create `app/Sources/Views/QuestDetail/ZoomableScrollView.swift`:

```swift
// ZoomableScrollView.swift — UIScrollView-based zoomable image view, used by ImageViewerOverlay.
import SwiftUI
import UIKit

struct ZoomableScrollView: UIViewRepresentable {
    let image: UIImage
    @Binding var zoomScale: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(zoomScale: $zoomScale)
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bouncesZoom = true
        scrollView.backgroundColor = .clear

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),
        ])

        context.coordinator.imageView = imageView
        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {}

    final class Coordinator: NSObject, UIScrollViewDelegate {
        var imageView: UIImageView?
        @Binding var zoomScale: CGFloat

        init(zoomScale: Binding<CGFloat>) {
            _zoomScale = zoomScale
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            imageView
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            zoomScale = scrollView.zoomScale
            let verticalInset = max((scrollView.bounds.height - scrollView.contentSize.height) / 2, 0)
            let horizontalInset = max((scrollView.bounds.width - scrollView.contentSize.width) / 2, 0)
            scrollView.contentInset = UIEdgeInsets(
                top: verticalInset, left: horizontalInset,
                bottom: verticalInset, right: horizontalInset
            )
        }

        func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
            zoomScale = scale
        }
    }
}
```

- [ ] **Step 4: Record the snapshot (record mode)**

In `app/Tests/SnapshotTests.swift`, temporarily change the new test to record:

```swift
func test_zoomableScrollView_snapshot() {
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 200))
    let uiImage = renderer.image { ctx in
        UIColor.systemGreen.setFill()
        ctx.fill(CGRect(x: 0, y: 0, width: 300, height: 200))
    }
    snapshotView(
        ZoomableScrollView(image: uiImage, zoomScale: .constant(1.0))
            .frame(width: 390, height: 300),
        named: "ZoomableScrollView",
        record: true   // ← add this
    )
}
```

Run:

```
xcodebuild test -scheme TOTKWalkthrough -destination 'platform=iOS Simulator,name=iPhone 15' -testIdentifier 'SnapshotTests/test_zoomableScrollView_snapshot' 2>&1 | tail -20
```

Expected: test passes (records the reference image).

- [ ] **Step 5: Switch back to verify mode and confirm pass**

Remove `record: true` from the test. Run again:

```
xcodebuild test -scheme TOTKWalkthrough -destination 'platform=iOS Simulator,name=iPhone 15' -testIdentifier 'SnapshotTests/test_zoomableScrollView_snapshot' 2>&1 | tail -20
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add app/Sources/Views/QuestDetail/ZoomableScrollView.swift app/Tests/SnapshotTests.swift app/Tests/__Snapshots__
git commit -m "feat: add ZoomableScrollView UIScrollView wrapper"
```

---

## Task 2: ImageViewerOverlay

**Files:**
- Create: `app/Sources/Views/QuestDetail/ImageViewerOverlay.swift`
- Modify: `app/Tests/SnapshotTests.swift`

- [ ] **Step 1: Write the failing snapshot test**

Add to `app/Tests/SnapshotTests.swift`:

```swift
func test_imageViewerOverlay_snapshot() {
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 200))
    let uiImage = renderer.image { ctx in
        UIColor.systemBlue.setFill()
        ctx.fill(CGRect(x: 0, y: 0, width: 300, height: 200))
    }
    var image: UIImage? = uiImage
    let binding = Binding(get: { image }, set: { image = $0 })
    snapshotView(
        ImageViewerOverlay(image: binding),
        named: "ImageViewerOverlay"
    )
}
```

- [ ] **Step 2: Run test to confirm it fails**

```
xcodebuild test -scheme TOTKWalkthrough -destination 'platform=iOS Simulator,name=iPhone 15' -testIdentifier 'SnapshotTests/test_imageViewerOverlay_snapshot' 2>&1 | tail -20
```

Expected: compile error — `ImageViewerOverlay` does not exist yet.

- [ ] **Step 3: Create ImageViewerOverlay.swift**

Create `app/Sources/Views/QuestDetail/ImageViewerOverlay.swift`:

```swift
// ImageViewerOverlay.swift — Fullscreen dark overlay for viewing quest screenshots with zoom and gesture dismiss.
import SwiftUI

struct ImageViewerOverlay: View {
    @Binding var image: UIImage?

    @State private var dragOffset: CGSize = .zero
    @State private var zoomScale: CGFloat = 1.0

    private let dismissThreshold: CGFloat = 120

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black
                .ignoresSafeArea()
                .opacity(backgroundOpacity)

            if let img = image {
                ZoomableScrollView(image: img, zoomScale: $zoomScale)
                    .ignoresSafeArea()
                    .offset(y: max(dragOffset.height, 0))
                    .simultaneousGesture(swipeDownGesture)
                    .onTapGesture {
                        guard zoomScale <= 1.0 else { return }
                        dismiss()
                    }
            }

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.white)
                    .shadow(radius: 4)
                    .padding()
            }
        }
        .opacity(backgroundOpacity)
        .animation(.easeInOut(duration: 0.25), value: image != nil)
    }

    private var backgroundOpacity: Double {
        max(0, 1.0 - Double(dragOffset.height) / 300.0)
    }

    private var swipeDownGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                guard zoomScale <= 1.0, value.translation.height > 0 else { return }
                dragOffset = value.translation
            }
            .onEnded { value in
                guard zoomScale <= 1.0 else {
                    withAnimation(.spring(response: 0.3)) { dragOffset = .zero }
                    return
                }
                if value.translation.height > dismissThreshold ||
                   value.predictedEndTranslation.height > dismissThreshold {
                    dismiss()
                } else {
                    withAnimation(.spring(response: 0.3)) { dragOffset = .zero }
                }
            }
    }

    private func dismiss() {
        withAnimation(.easeInOut(duration: 0.2)) {
            image = nil
            dragOffset = .zero
        }
    }
}
```

- [ ] **Step 4: Record the snapshot**

Temporarily add `record: true` to `test_imageViewerOverlay_snapshot`:

```swift
snapshotView(
    ImageViewerOverlay(image: binding),
    named: "ImageViewerOverlay",
    record: true   // ← add this
)
```

Run:

```
xcodebuild test -scheme TOTKWalkthrough -destination 'platform=iOS Simulator,name=iPhone 15' -testIdentifier 'SnapshotTests/test_imageViewerOverlay_snapshot' 2>&1 | tail -20
```

Expected: PASS (records reference).

- [ ] **Step 5: Switch back to verify mode and confirm pass**

Remove `record: true`. Run again:

```
xcodebuild test -scheme TOTKWalkthrough -destination 'platform=iOS Simulator,name=iPhone 15' -testIdentifier 'SnapshotTests/test_imageViewerOverlay_snapshot' 2>&1 | tail -20
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add app/Sources/Views/QuestDetail/ImageViewerOverlay.swift app/Tests/SnapshotTests.swift app/Tests/__Snapshots__
git commit -m "feat: add ImageViewerOverlay with swipe-down and tap dismiss"
```

---

## Task 3: Wire into QuestDetailView

**Files:**
- Modify: `app/Sources/Views/QuestDetail/QuestDetailView.swift`
- Modify: `app/Tests/SnapshotTests.swift`

- [ ] **Step 1: Add `selectedImage` state and overlay to QuestDetailView**

In `app/Sources/Views/QuestDetail/QuestDetailView.swift`, add the state property after the existing `@State` declarations (around line 11):

```swift
@State private var selectedImage: UIImage?
```

Wrap the `ScrollView` body with an overlay for the image viewer. The current `body` starts with `ScrollView {`. Wrap the entire `ScrollView` to add `.overlay`:

```swift
var body: some View {
    ScrollView {
        // ... existing content unchanged ...
    }
    .background(themeManager.colors.background)
    .overlay {
        if selectedImage != nil {
            ImageViewerOverlay(image: $selectedImage)
                .ignoresSafeArea()
        }
    }
    .toolbar { /* ... existing toolbar unchanged ... */ }
    // ... rest unchanged ...
}
```

- [ ] **Step 2: Make image blocks tappable with a magnifying glass affordance**

Replace the `.image` case in `blockView()` (currently lines 106–117) with:

```swift
case .image(let filename):
    let imagePath = questContentURL.appendingPathComponent(filename).path
    if let uiImage = UIImage(contentsOfFile: imagePath) {
        Button {
            selectedImage = uiImage
        } label: {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(themeManager.colors.cardBorder, lineWidth: 1)
                )
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "magnifyingglass")
                        .font(.caption)
                        .padding(6)
                        .background(.black.opacity(0.5))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .padding(6)
                }
        }
        .buttonStyle(.plain)
    }
```

- [ ] **Step 3: Re-record the QuestDetail snapshot**

The magnifying glass affordance changes the appearance of image blocks, so the existing snapshot reference is now stale. Temporarily set `record: true` in `test_questDetail_snapshot`:

```swift
func test_questDetail_snapshot() async throws {
    try await contentStore.load()
    guard let quest = contentStore.quests.first else {
        XCTFail("No quests loaded from fixtures")
        return
    }
    snapshotView(QuestDetailView(quest: quest), named: "QuestDetail", record: true)
}
```

Run:

```
xcodebuild test -scheme TOTKWalkthrough -destination 'platform=iOS Simulator,name=iPhone 15' -testIdentifier 'SnapshotTests/test_questDetail_snapshot' 2>&1 | tail -20
```

Expected: PASS (records new reference).

- [ ] **Step 4: Switch back to verify mode**

Remove `record: true` from `test_questDetail_snapshot`. Run the full snapshot suite:

```
xcodebuild test -scheme TOTKWalkthrough -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing SnapshotTests 2>&1 | tail -30
```

Expected: all tests PASS.

- [ ] **Step 5: Commit**

```bash
git add app/Sources/Views/QuestDetail/QuestDetailView.swift app/Tests/SnapshotTests.swift app/Tests/__Snapshots__
git commit -m "feat: tap screenshots to open fullscreen zoom viewer (R12)"
```
