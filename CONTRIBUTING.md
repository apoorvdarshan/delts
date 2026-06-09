# Contributing

Thanks for helping improve Delts.

## Development Setup

1. Clone the repository.
2. Open `ios/delts.xcodeproj` in Xcode for iOS development.
3. Run the static website locally with:

```sh
cd web
python3 -m http.server 3000
```

## Workflow

- Keep changes focused and easy to review.
- Match existing SwiftUI structure, naming, and visual patterns.
- Prefer app-wide helpers such as `Color.deltsAccent`, `DeltsBackground`, and existing row/card components.
- Test affected screens on an iPhone or simulator before opening a pull request.
- Do not commit generated build output from `build/`.

## Code Style

- Use clear Swift names and keep views small when practical.
- Keep comments rare and useful.
- Avoid unrelated refactors in feature or bug fix changes.
- Keep website changes dependency-free unless a dependency is clearly needed.

## Pull Requests

Include:

- What changed.
- Screens or flows tested.
- Any known limitations.

## Contact

For contributor questions, contact apoorvdarshan@gmail.com or ad13dtu@gmail.com.

