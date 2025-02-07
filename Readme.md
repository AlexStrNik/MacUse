# MacUse

> I continue to fall into the pit named Application Services

## Overview

MacUse is an experimental project in early development that aims to provide a different approach to macOS automation by combining the power of Claude Sonnet with Apple's Application Services Framework.

## What Makes It Different?

Unlike traditional macOS automation tools that rely on cursor manipulation, screenshots, or window focus changes, MacUse takes a more elegant approach:

- **No Cursor Hijacking**: Your mouse cursor stays exactly where you left it
- **No Screenshots Required**: All decisions are made by analyzing the accessibility tree
- **Focus-Preserving**: Operates without disrupting your current window focus
- **Pure Accessibility**: Leverages macOS Accessibility Tree for navigation and control

## Current State

This project is in very early development stages and should be considered experimental. It's an exploration of how we can create more reliable and less intrusive macOS automation by strictly using the accessibility framework.

## Technical Approach

MacUse operates by:

- Building a semantic understanding of application state through accessibility trees
- Executing actions via Application Services Framework
- Using Claude Sonnet for intelligent decision-making
- Performing operations without relying on screen coordinates or visual elements

## Warning

This is a raw, experimental project. Expect frequent changes and potential instability as the codebase evolves.

## Contributing

As this project is in its early stages, feedback and contributions are welcome but expect significant changes in approach and architecture.
