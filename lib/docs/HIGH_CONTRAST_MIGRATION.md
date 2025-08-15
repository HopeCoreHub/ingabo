# High Contrast Mode Migration Guide

## Current Status
✅ **Core Theme System** - Complete high contrast theme implemented
✅ **Main Page Components** - Quick Access cards and navigation updated  
✅ **Settings Page** - High contrast toggle working
✅ **Text System** - LocalizedText and AccessibleText support high contrast
⚠️ **Individual Pages** - Some pages still use hardcoded colors

## Quick Fix for Remaining Components

### The Problem
Some components in Forum, Mahoro, and Muganga pages use hardcoded colors instead of theme colors:

```dart
// ❌ BAD - Hardcoded colors
Container(
  color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
  // ...
)

// ❌ BAD - Hardcoded gradients
decoration: BoxDecoration(
  gradient: LinearGradient(
    colors: [accentColor, accentColor.withOpacity(0.7)],
  ),
)
```

### The Solution
Use theme colors and AccessibilityUtils:

```dart
// ✅ GOOD - Theme-aware colors
Container(
  color: Theme.of(context).colorScheme.surface,
  // ...
)

// ✅ GOOD - High contrast aware
Container(
  color: AccessibilityUtils.getAccessibleSurfaceColor(context),
  decoration: BoxDecoration(
    border: AccessibilityUtils.isHighContrastEnabled(context)
        ? Border.all(
            color: AccessibilityUtils.getAccessibleBorderColor(context),
            width: 2.0,
          )
        : null,
  ),
)
```

## Quick Migration Pattern

For any hardcoded color usage, replace with:

### 1. Background Colors
```dart
// Replace this:
color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,

// With this:
color: AccessibilityUtils.getAccessibleSurfaceColor(context),
```

### 2. Text Colors
```dart
// Replace this:
style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),

// With this:
style: AccessibilityUtils.getTextStyle(context, color: null),
```

### 3. Remove Gradients in High Contrast
```dart
decoration: BoxDecoration(
  gradient: AccessibilityUtils.isHighContrastEnabled(context) 
      ? null 
      : LinearGradient(/* your gradient */),
  color: AccessibilityUtils.isHighContrastEnabled(context)
      ? AccessibilityUtils.getAccessibleSurfaceColor(context)
      : null,
  border: AccessibilityUtils.isHighContrastEnabled(context)
      ? Border.all(
          color: AccessibilityUtils.getAccessibleBorderColor(context),
          width: 2.0,
        )
      : null,
)
```

### 4. Elevation/Shadows
```dart
boxShadow: AccessibilityUtils.getAccessibleShadow(context, normalShadow),
elevation: AccessibilityUtils.getAccessibleElevation(context, 4.0),
```

## Automatic Theme Integration

The good news is that **most components will automatically work** if they use:
- `Theme.of(context).colorScheme.primary`
- `Theme.of(context).colorScheme.surface`
- `Theme.of(context).colorScheme.onSurface`
- `Theme.of(context).textTheme.bodyLarge`
- etc.

The main theme system now automatically provides high contrast colors when high contrast mode is enabled.

## Testing Checklist

✅ Enable high contrast mode in Settings
✅ Check main page - cards should have borders, no gradients
✅ Check navigation - should have borders
✅ Check text - should be pure black/white
✅ Check buttons - should have thick borders
✅ No shadows should be visible
✅ No gradients should be visible

## Long-term Solution

Eventually, all pages should:
1. Use theme colors instead of hardcoded colors
2. Use AccessibilityUtils for custom components
3. Use the new HighContrastContainer widgets
4. Follow the high contrast design principles

This migration can be done incrementally as each page is updated.









