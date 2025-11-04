# UI Components Guide

Dokumentasi komprehensif untuk semua reusable UI components yang digunakan di aplikasi Suriota Mobile App. Semua components ini mengikuti design system yang konsisten dan dapat digunakan di seluruh aplikasi.

---

## Table of Contents

1. [Buttons](#buttons)
   - [Gradient Button](#gradient-button)
   - [Compact Icon Button](#compact-icon-button)
2. [Cards](#cards)
   - [Device Card](#device-card)
   - [Streaming Data Card](#streaming-data-card)
   - [Modbus Config Card](#modbus-config-card)
3. [Selection Components](#selection-components)
   - [Selection Card](#selection-card)
4. [Information Display](#information-display)
   - [Info Badge](#info-badge)
   - [Section Divider](#section-divider)
5. [Design Tokens](#design-tokens)

---

## Buttons

### Gradient Button

Button dengan gradient background dan shadow untuk primary actions.

#### Usage

```dart
import 'package:gateway_config/presentation/widgets/common/gradient_button.dart';

// Basic usage
GradientButton(
  text: 'Save Data',
  onPressed: () => print('Saved'),
)

// With icon
GradientButton(
  text: 'Update Configuration',
  icon: Icons.update,
  onPressed: () {},
)

// Custom colors (for danger actions)
GradientButton(
  text: 'Delete',
  icon: Icons.delete,
  colors: [AppColor.redColor, AppColor.redColor.withValues(alpha: 0.8)],
  onPressed: () {},
)

// With loading state
GradientButton(
  text: 'Saving...',
  loading: true,
  onPressed: () {},
)
```

#### Variants

```dart
// Using preset variants
GradientButtonVariants.save(onPressed: () {});
GradientButtonVariants.update(onPressed: () {});
GradientButtonVariants.submit(onPressed: () {});
GradientButtonVariants.danger(text: 'Delete', onPressed: () {});
GradientButtonVariants.success(text: 'Confirm', onPressed: () {});
```

#### Specifications

| Property | Default | Description |
|----------|---------|-------------|
| height | `54px` | Button height |
| width | `double.infinity` | Button width (full width) |
| borderRadius | `12px` | Corner radius |
| iconSize | `22px` | Icon size |
| spacing | `10px` | Gap between icon and text |
| shadow.blurRadius | `8px` | Shadow blur |
| shadow.offset | `(0, 4)` | Shadow offset |
| shadow.opacity | `30%` | Shadow opacity |

#### States

- **Default**: Full gradient with shadow
- **Disabled**: Grey color, no shadow, onPressed = null
- **Loading**: Shows CircularProgressIndicator

---

### Compact Icon Button

Button kecil dengan icon saja untuk action buttons dalam card atau list.

#### Usage

```dart
import 'package:gateway_config/presentation/widgets/common/compact_icon_button.dart';

// Single button
CompactIconButton(
  icon: Icons.edit,
  color: AppColor.primaryColor,
  onPressed: () => print('Edit'),
  tooltip: 'Edit',
)

// Disabled state
CompactIconButton(
  icon: Icons.delete,
  color: AppColor.redColor,
  onPressed: null, // Grey when disabled
)

// In a row
CompactIconButtonRow(
  buttons: [
    CompactIconButton(
      icon: Icons.edit,
      color: AppColor.primaryColor,
      onPressed: () {},
    ),
    CompactIconButton(
      icon: Icons.delete,
      color: AppColor.redColor,
      onPressed: () {},
    ),
  ],
  spacing: 8, // Gap between buttons
)

// In a column
CompactIconButtonColumn(
  buttons: [
    CompactIconButton(icon: Icons.edit, color: AppColor.primaryColor, onPressed: () {}),
    CompactIconButton(icon: Icons.delete, color: AppColor.redColor, onPressed: () {}),
  ],
  spacing: 6,
)
```

#### Specifications

| Property | Default | Description |
|----------|---------|-------------|
| size | `32px` | Button size (width & height) |
| iconSize | `16px` | Icon size |
| borderRadius | `6px` | Corner radius |
| shadow.blurRadius | `3px` | Shadow blur |
| shadow.offset | `(0, 1)` | Shadow offset |
| shadow.opacity | `25%` | Shadow opacity |

#### States

- **Default**: Colored with shadow
- **Disabled**: Grey color when onPressed = null
- **Hover**: Native ripple effect (Material)

#### Common Colors

- **Edit**: `AppColor.primaryColor`
- **Delete**: `AppColor.redColor`
- **View**: `AppColor.primaryColor`
- **More**: `AppColor.grey`

---

## Cards

### Device Card

Card untuk menampilkan device dalam list dengan 3 kolom layout.

#### Layout Structure

```
┌─────────────────────────────────────────────────┐
│  [Icon]  Device Name          [Edit] [Delete]  │
│          Protocol Badge                         │
│          ID: device_id                          │
└─────────────────────────────────────────────────┘
```

#### Specifications

**Container:**
- Background: `AppColor.whiteColor`
- Border: `primaryColor @ 20%` opacity, width `1.5px`
- Border radius: `12px`
- Shadow: `black @ 5%` opacity, blur `4px`, offset `(0, 2)`
- Padding: `12px` all sides

**Column 1 - Icon (50x50px):**
- Background: `lightPrimaryColor @ 20%` opacity
- Border radius: `8px`
- Icon size: varies by type

**Column 2 - Info (Expanded):**
- Device Name: `h6`, bold, `primaryColor` or `blackColor`
- Protocol Badge: Custom badge component
- Device ID: `bodySmall`, `10px`, grey with icon

**Column 3 - Actions:**
- Two `CompactIconButton` (32x32px)
- Spacing: `6px` vertical (column) or horizontal (row)

#### Usage Example

```dart
// Reference implementation in:
// lib/presentation/pages/devices/device_communication/device_communications_screen.dart
```

---

### Streaming Data Card

Card untuk menampilkan data sensor real-time.

#### Layout Structure

```
┌─────────────────────────────────────────────────┐
│  Sensor Name                    [Live Badge]    │
│  Addr: address                                  │
│  ┌───────────────────────────────────────────┐ │
│  │ Value:              sensor_value          │ │
│  └───────────────────────────────────────────┘ │
│  ⏰ Last Update: timestamp                      │
└─────────────────────────────────────────────────┘
```

#### Specifications

**Container:**
- Background: `AppColor.whiteColor`
- Border: `primaryColor @ 20%` opacity, width `1.5px`
- Border radius: `12px`
- Shadow: `black @ 5%` opacity, blur `4px`
- Padding: `12px`
- Margin bottom: `12px`

**Elements:**
- Sensor Name: `h6`, bold, `primaryColor`
- Live Badge: Green background, white text, `9px`
- Address: Icon `14px`, text `11px`, grey
- Value Container:
  - Background: `lightPrimaryColor @ 30%` opacity
  - Border: `primaryColor @ 20%` opacity
  - Border radius: `8px`
  - Padding: `10px` vertical, `12px` horizontal
  - Value text: `h5`, bold, `primaryColor`
- Last Update: Icon `12px`, text `10px`, grey

#### Spacing Hierarchy

```
Sensor Name + Live Badge
    ↓ 8px
Address
    ↓ 10px
Value Container
    ↓ 8px
Last Update
```

---

### Modbus Config Card

Card untuk menampilkan konfigurasi Modbus register.

#### Layout Structure

```
┌─────────────────────────────────────────────────┐
│  [Storage]  Register Name       [Edit] [Delete]│
│  Icon       Address: 40001                      │
│             DataType                            │
└─────────────────────────────────────────────────┘
```

#### Specifications

Similar to Device Card but with:
- Icon: `Icons.storage`, size `28px`
- Register Name: `h5`, bold, `blackColor`
- Address: Icon `location_on_outlined`, `12px`
- Data Type Badge: Compact badge, `9px` font

---

## Selection Components

### Selection Card

Card selection component dengan icon, title, dan subtitle.

#### Usage

```dart
import 'package:gateway_config/presentation/widgets/common/selection_card.dart';

SelectionCard<String>(
  items: [
    SelectionCardItem(
      value: 'RTU',
      title: 'Modbus RTU',
      subtitle: 'Serial communication (RS485)',
      icon: Icons.settings_input_component,
    ),
    SelectionCardItem(
      value: 'TCP',
      title: 'Modbus TCP',
      subtitle: 'Ethernet/IP communication',
      icon: Icons.lan,
    ),
  ],
  selectedValue: selectedModbus,
  onChanged: (value) => setState(() => selectedModbus = value),
)
```

#### Specifications

**Container:**
- Background: `whiteColor`
- Border: `primaryColor @ 15%` opacity, width `1.5px`
- Border radius: `12px`
- Padding: `4px`

**Option Card:**
- Padding: `12px`
- Border radius: `8px`
- Selected:
  - Border: `primaryColor`, width `2px`
  - Background: `primaryColor @ 10%` opacity
- Icon container: `48x48px`
  - Selected: `primaryColor` background
  - Unselected: `grey @ 20%` background
- Title: `h6`, bold
- Subtitle: `bodySmall`, `11px`, grey
- Check icon: `24px`

---

## Information Display

### Info Badge

Badge kecil untuk menampilkan informasi, status, atau kategori.

#### Usage

```dart
import 'package:gateway_config/presentation/widgets/common/info_badge.dart';

// Basic badge
InfoBadge(text: 'RTU')

// With icon
InfoBadge(
  text: 'Active',
  icon: Icons.check_circle,
)

// Custom colors
InfoBadge(
  text: 'Premium',
  backgroundColor: AppColor.primaryColor,
  textColor: AppColor.whiteColor,
)

// Using variants
InfoBadgeVariants.success('Active')
InfoBadgeVariants.error('Failed')
InfoBadgeVariants.warning('Pending')
InfoBadgeVariants.info('New')
InfoBadgeVariants.primary('RTU')
InfoBadgeVariants.secondary('Offline')
InfoBadgeVariants.live() // Special live indicator
```

#### Specifications

| Property | Default | Description |
|----------|---------|-------------|
| padding | `8px, 4px` | Horizontal, Vertical |
| borderRadius | `8px` | Corner radius |
| border.width | `1px` | Border thickness |
| fontSize | `11px` | Text size |
| fontWeight | `w600` | Text weight |
| iconSize | `12px` | Icon size |
| icon spacing | `4px` | Gap between icon and text |

#### Variants

| Variant | Background | Border | Text/Icon |
|---------|------------|--------|-----------|
| Primary | Primary @ 10% | Primary @ 30% | Primary |
| Success | Green @ 10% | Green @ 30% | Green 700 |
| Error | Red @ 10% | Red @ 30% | Red |
| Warning | Orange @ 10% | Orange @ 30% | Orange 700 |
| Info | Blue @ 10% | Blue @ 30% | Blue 700 |
| Secondary | Grey @ 10% | Grey @ 30% | Grey |
| Live | Green | Transparent | White |

---

### Section Divider

Divider untuk memisahkan section dalam form atau halaman.

#### Usage

```dart
import 'package:gateway_config/presentation/widgets/common/section_divider.dart';

// Basic usage
SectionDivider(title: 'Personal Information')

// With icon
SectionDivider(
  title: 'Advanced Settings',
  icon: Icons.settings,
)

// Custom colors
SectionDivider(
  title: 'Danger Zone',
  accentColor: AppColor.redColor,
  textColor: AppColor.redColor,
)
```

#### Specifications

**Container:**
- Padding: `12px` horizontal, `10px` vertical
- Background: `primaryColor @ 8%` opacity
- Border: `primaryColor @ 20%` opacity, width `1px`
- Border radius: `8px`

**Elements:**
- Accent bar: `4px` width, `20px` height, radius `2px`
- Icon (optional): `20px` size
- Title: `h6`, bold, `primaryColor`
- Spacing:
  - Bar to Icon/Title: `10px`
  - Icon to Title: `8px`

---

## Design Tokens

### Border Radius

```dart
// Main containers (cards, buttons)
borderRadius: 12px

// Sub-elements (badges, icon containers)
borderRadius: 8px

// Small elements (accent bars, mini badges)
borderRadius: 6px

// Tiny elements
borderRadius: 2px
```

### Opacity Levels

```dart
// Backgrounds
light: 0.08 (8%)
medium: 0.1 - 0.2 (10-20%)
strong: 0.3 (30%)

// Borders
subtle: 0.15 (15%)
normal: 0.2 (20%)
strong: 0.3 (30%)

// Shadows
subtle: 0.05 (5%)
normal: 0.25 (25%)
strong: 0.3 (30%)
```

### Spacing Scale

```dart
2px  - Very tight (badge internal)
4px  - Tight (between icon and text in badge)
6px  - Compact (between stacked buttons)
8px  - Standard (card sections)
10px - Comfortable (before value container)
12px - Spacious (card padding, section spacing)
16px - Large (major sections)
24px - Extra large (page margins)
```

### Typography Scale

```dart
h3  - Major headings
h5  - Section headings, important values
h6  - Card titles, labels
bodySmall - Standard text (11-12px)
10px - Metadata, timestamps
9px  - Tiny badges

Font Weights:
normal - 400
w600   - 600 (badges, emphasis)
bold   - 700 (headings, values)
```

### Shadow Presets

```dart
// Card shadow
BoxShadow(
  color: Colors.black.withValues(alpha: 0.05),
  blurRadius: 4,
  offset: Offset(0, 2),
)

// Button shadow
BoxShadow(
  color: buttonColor.withValues(alpha: 0.3),
  blurRadius: 8,
  offset: Offset(0, 4),
)

// Icon button shadow
BoxShadow(
  color: buttonColor.withValues(alpha: 0.25),
  blurRadius: 3,
  offset: Offset(0, 1),
)
```

### Color Usage

```dart
// Primary elements (titles, important data)
AppColor.primaryColor

// Secondary elements (labels, metadata)
AppColor.grey

// Backgrounds
AppColor.whiteColor        // Cards
AppColor.cardColor         // Alternative card bg
AppColor.lightPrimaryColor // Highlighted containers

// Status colors
Colors.green    // Success, active, live
AppColor.redColor // Danger, delete, error
Colors.orange   // Warning
Colors.blue     // Info
```

### Icon Sizes

```dart
// Large focal icons (empty states)
64px

// Medium icons (card icons, headers)
28px - 40px

// Standard icons (buttons, inline)
20px - 24px

// Small icons (badges, inline text)
12px - 16px

// Tiny icons (status dots)
5px - 8px
```

---

## Best Practices

### DO ✓

- Use preset components whenever possible
- Follow the spacing scale consistently
- Use semantic color variants (success, error, warning)
- Provide disabled states for buttons
- Include loading states for async actions
- Add tooltips to icon-only buttons
- Use `Expanded` + `TextOverflow.ellipsis` for long text
- Maintain minimum touch targets (32px for icon buttons)
- Use gradient buttons for primary actions only

### DON'T ✗

- Don't create one-off button styles
- Don't use random opacity values
- Don't mix different border radius sizes
- Don't ignore disabled and loading states
- Don't use heavy shadows (max 8px blur for buttons)
- Don't make icon buttons smaller than 32px
- Don't use emojis in production UI
- Don't override component colors without reason

---

## Component Checklist

When creating or using components, ensure:

- [ ] Follows spacing scale (2, 4, 6, 8, 10, 12px)
- [ ] Uses standard border radius (6, 8, 12px)
- [ ] Has proper opacity levels (5-30%)
- [ ] Includes disabled state
- [ ] Handles overflow with ellipsis
- [ ] Has minimum touch target (32px)
- [ ] Uses semantic colors
- [ ] Consistent with design tokens
- [ ] Has documentation/examples
- [ ] Is reusable and generic enough

---

## Migration Guide

### Migrating Existing Components

1. **Identify custom widgets** that can be replaced with reusable components
2. **Import the new component**:
   ```dart
   import 'package:gateway_config/presentation/widgets/common/[component_name].dart';
   ```
3. **Replace old implementation** with new component
4. **Test thoroughly** to ensure behavior is consistent
5. **Remove old code** after successful migration

### Example Migration

**Before:**
```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  decoration: BoxDecoration(
    color: AppColor.primaryColor.withOpacity(0.1),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: AppColor.primaryColor.withOpacity(0.3)),
  ),
  child: Text('RTU', style: context.bodySmall),
)
```

**After:**
```dart
InfoBadge(text: 'RTU')
// or
InfoBadgeVariants.primary('RTU')
```

---

## Support

For questions or issues with components:
1. Check this documentation first
2. Review component source code
3. Look at reference implementations
4. Create an issue with clear example

---

**Last Updated:** 2025-01-04
**Version:** 1.0.0
