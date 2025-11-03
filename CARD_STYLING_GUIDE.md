# Card Styling Guide - Streaming Device Card

Dokumentasi ini berisi panduan styling untuk card component yang digunakan di aplikasi, berdasarkan implementasi `_streamingDeviceCard()` di `data_display_screen.dart`.

## Overview

Card ini menampilkan data sensor secara real-time dengan desain yang clean dan modern. Setiap sensor memiliki card terpisah yang menampilkan nama sensor, alamat, nilai, dan timestamp update terakhir.

---

## 1. Container Utama Card

### Properties
```dart
Container(
  margin: const EdgeInsets.only(bottom: 12),
  decoration: BoxDecoration(
    color: AppColor.whiteColor,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: AppColor.primaryColor.withValues(alpha: 0.2),
      width: 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
  ),
)
```

### Specifications
- **Margin Bottom**: `12px` - Jarak antar card
- **Background**: `AppColor.whiteColor` - Warna putih untuk background
- **Border Radius**: `12px` - Sudut rounded yang smooth
- **Border**:
  - Color: `AppColor.primaryColor` dengan opacity `0.2` (20%)
  - Width: `1.5px` - Border yang tipis namun terlihat
- **Shadow**:
  - Color: `Colors.black` dengan opacity `0.05` (5%)
  - Blur Radius: `4px`
  - Offset: `(0, 2)` - Shadow ke bawah sedikit

### Visual Effect
Card memiliki efek elevated/mengambang dengan shadow yang subtle, memberikan kesan depth tanpa terlalu mencolok.

---

## 2. Padding Dalam Card

```dart
Padding(
  padding: const EdgeInsets.all(12),
  child: Column(...)
)
```

- **All Sides**: `12px` - Padding yang konsisten di semua sisi

---

## 3. Header Section (Nama Sensor + Live Badge)

### Layout Structure
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Expanded(child: Text(...)),  // Sensor Name
    Container(...),               // Live Badge
  ],
)
```

### Sensor Name Text
```dart
Text(
  sensorName,
  style: context.h6.copyWith(
    color: AppColor.primaryColor,
    fontWeight: FontWeight.bold,
  ),
  overflow: TextOverflow.ellipsis,
)
```

**Specifications:**
- Typography: `h6` (heading 6)
- Color: `AppColor.primaryColor`
- Weight: `FontWeight.bold`
- Overflow: `TextOverflow.ellipsis` - Truncate dengan "..." jika terlalu panjang

### Live Badge
```dart
Container(
  padding: const EdgeInsets.symmetric(
    horizontal: 6,
    vertical: 2,
  ),
  decoration: BoxDecoration(
    color: Colors.green,
    borderRadius: BorderRadius.circular(8),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.circle, color: Colors.white, size: 5),
      const SizedBox(width: 3),
      Text(
        'Live',
        style: context.buttonTextSmallest.copyWith(
          color: Colors.white,
          fontSize: 9,
        ),
      ),
    ],
  ),
)
```

**Specifications:**
- **Padding**: Horizontal `6px`, Vertical `2px`
- **Background**: `Colors.green` - Indikator streaming aktif
- **Border Radius**: `8px`
- **Icon**:
  - Type: `Icons.circle`
  - Size: `5px` (dot kecil)
  - Color: `Colors.white`
- **Text**:
  - Content: "Live"
  - Size: `9px`
  - Color: `Colors.white`
  - Gap between icon and text: `3px`

---

## 4. Address Section

```dart
Row(
  children: [
    Icon(
      Icons.location_on_outlined,
      size: 14,
      color: AppColor.grey,
    ),
    const SizedBox(width: 3),
    Text(
      'Addr: $sensorAddress',
      style: context.bodySmall.copyWith(
        color: AppColor.grey,
        fontSize: 11,
      ),
    ),
  ],
)
```

**Specifications:**
- **Spacing from Header**: `8px` (via SizedBox)
- **Icon**:
  - Type: `Icons.location_on_outlined`
  - Size: `14px`
  - Color: `AppColor.grey`
- **Text**:
  - Typography: `bodySmall`
  - Size: `11px`
  - Color: `AppColor.grey`
  - Format: "Addr: [address]"
  - Gap between icon and text: `3px`

---

## 5. Value Section (Highlight Container)

```dart
Container(
  width: double.infinity,
  padding: const EdgeInsets.symmetric(
    vertical: 10,
    horizontal: 12,
  ),
  decoration: BoxDecoration(
    color: AppColor.lightPrimaryColor.withValues(alpha: 0.3),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(
      color: AppColor.primaryColor.withValues(alpha: 0.2),
      width: 1,
    ),
  ),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text('Value:', ...),        // Label
      Text(sensorValue, ...),     // Value
    ],
  ),
)
```

**Specifications:**
- **Spacing from Address**: `10px` (via SizedBox)
- **Width**: `double.infinity` - Full width
- **Padding**: Vertical `10px`, Horizontal `12px`
- **Background**: `AppColor.lightPrimaryColor` dengan opacity `0.3` (30%)
- **Border**:
  - Color: `AppColor.primaryColor` dengan opacity `0.2` (20%)
  - Width: `1px`
- **Border Radius**: `8px`

### Label Text ("Value:")
```dart
Text(
  'Value:',
  style: context.bodySmall.copyWith(
    color: AppColor.grey,
    fontSize: 12,
  ),
)
```
- Typography: `bodySmall`
- Size: `12px`
- Color: `AppColor.grey`

### Value Text (Sensor Reading)
```dart
Text(
  sensorValue,
  style: context.h5.copyWith(
    color: AppColor.primaryColor,
    fontWeight: FontWeight.bold,
  ),
)
```
- Typography: `h5` (heading 5) - Lebih besar untuk emphasis
- Color: `AppColor.primaryColor`
- Weight: `FontWeight.bold`

**Visual Purpose:** Container ini adalah focal point dari card, dengan background yang kontras dan text yang bold untuk menarik perhatian ke nilai sensor.

---

## 6. Last Update Section

```dart
Row(
  children: [
    Icon(Icons.access_time, size: 12, color: AppColor.grey),
    const SizedBox(width: 4),
    Expanded(
      child: Text(
        lastUpdate,
        style: context.bodySmall.copyWith(
          color: AppColor.grey,
          fontSize: 10,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    ),
  ],
)
```

**Specifications:**
- **Spacing from Value**: `8px` (via SizedBox)
- **Icon**:
  - Type: `Icons.access_time`
  - Size: `12px`
  - Color: `AppColor.grey`
- **Text**:
  - Typography: `bodySmall`
  - Size: `10px` - Paling kecil karena info sekunder
  - Color: `AppColor.grey`
  - Overflow: `TextOverflow.ellipsis`
  - Gap between icon and text: `4px`

---

## 7. Spacing Hierarchy

Vertical spacing dari atas ke bawah:

```
Header (Sensor Name + Live Badge)
    ↓ 8px
Address Section
    ↓ 10px
Value Container
    ↓ 8px
Last Update Section
```

**Spacing Pattern:**
- Standard spacing: `8px`
- Before value container: `10px` (sedikit lebih besar untuk emphasis)
- Between elements in same section: `3-4px`

---

## 8. Color Palette Usage

### Primary Elements
- **Sensor Name**: `AppColor.primaryColor` + Bold
- **Value Text**: `AppColor.primaryColor` + Bold
- **Card Border**: `AppColor.primaryColor` @ 20% opacity

### Secondary/Info Elements
- **Address Text**: `AppColor.grey`
- **Value Label**: `AppColor.grey`
- **Last Update**: `AppColor.grey`
- **Icons**: `AppColor.grey`

### Backgrounds
- **Card Background**: `AppColor.whiteColor`
- **Value Container**: `AppColor.lightPrimaryColor` @ 30% opacity
- **Shadow**: `Colors.black` @ 5% opacity

### Status Indicators
- **Live Badge**: `Colors.green` (background) + `Colors.white` (text/icon)

---

## 9. Empty State

Jika tidak ada data sensor, tampilkan:

```dart
Container(
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: AppColor.cardColor,
    borderRadius: BorderRadius.circular(12),
  ),
  child: Center(
    child: Column(
      children: [
        Icon(Icons.sensors, size: 40, color: AppColor.grey),
        const SizedBox(height: 8),
        Text(
          'Waiting for sensor data...',
          style: context.bodySmall.copyWith(color: AppColor.grey),
        ),
      ],
    ),
  ),
)
```

**Specifications:**
- Padding: `20px` all sides
- Background: `AppColor.cardColor`
- Border Radius: `12px`
- Icon: `Icons.sensors`, size `40px`
- Text: `bodySmall`, grey color

---

## 10. Implementation Tips

### Consistency Guidelines

1. **Border Radius**: Gunakan `12px` untuk container utama, `8px` untuk sub-elements
2. **Opacity Levels**:
   - Borders: 20% (`alpha: 0.2`)
   - Backgrounds: 30% (`alpha: 0.3`)
   - Shadows: 5% (`alpha: 0.05`)
3. **Icon Sizes**:
   - Large (focal): `40px`
   - Medium (section icons): `12-14px`
   - Small (indicators): `5px`
4. **Text Sizes**:
   - Main heading: `h6` or `h5`
   - Standard info: `bodySmall` (`11-12px`)
   - Metadata: `10px`
   - Badge: `9px`

### Responsive Behavior

- Sensor name menggunakan `Expanded` + `TextOverflow.ellipsis` untuk handle nama panjang
- Last update juga menggunakan `Expanded` + `TextOverflow.ellipsis`
- Value container menggunakan `width: double.infinity` untuk full width

### Accessibility

- Font sizes tidak terlalu kecil (minimum 9px untuk badge)
- Contrast ratio bagus antara text dan background
- Icon size cukup besar untuk touch targets (minimum 12px)

---

## Reference Implementation

### Streaming Card
File: `lib/presentation/pages/devices/device_communication/data_display_screen.dart`
Widget: `_streamingDeviceCard()` (lines 404-583)

### Device List Card
File: `lib/presentation/pages/devices/device_communication/device_communications_screen.dart`
Widget: `_cardDeviceConnection()` (lines 256-405)

---

## Visual Hierarchy Summary

```
1. SENSOR VALUE (h5, bold, primaryColor)         ← Highest priority
2. Sensor Name (h6, bold, primaryColor)          ← High priority
3. Live Badge (green, small)                     ← Status indicator
4. Address (bodySmall, 11px, grey)               ← Medium priority
5. Last Update (bodySmall, 10px, grey)           ← Low priority
```

Hierarchy ini memastikan user langsung melihat nilai sensor (informasi paling penting) diikuti dengan identitas sensor.

---

## 11. Device Card Variant

Variant card untuk menampilkan device dalam list dengan action buttons.

### Container Structure
```dart
Container(
  decoration: BoxDecoration(
    color: AppColor.whiteColor,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: AppColor.primaryColor.withValues(alpha: 0.2),
      width: 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
  ),
  child: Padding(
    padding: const EdgeInsets.all(12),
    child: Column(...),
  ),
)
```

### Layout Sections

#### 1. Header (Icon + Title + Badge)
```dart
Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    // Icon container with background
    Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: AppColor.lightPrimaryColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: Image.asset(...),
    ),
    const SizedBox(width: 12),
    // Title & Badge
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: h6 + bold + primaryColor),
          const SizedBox(height: 6),
          ProtocolBadge(...),
        ],
      ),
    ),
  ],
)
```

**Specifications:**
- Icon size: `50x50px`
- Icon background: `lightPrimaryColor @ 20%` opacity
- Icon border radius: `8px`
- Gap between icon and text: `12px`
- Gap between title and badge: `6px`

#### 2. Protocol Badge
```dart
Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  decoration: BoxDecoration(
    color: AppColor.primaryColor.withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(
      color: AppColor.primaryColor.withValues(alpha: 0.3),
      width: 1,
    ),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.settings_input_component, color: primaryColor, size: 12),
      const SizedBox(width: 4),
      Text(protocol, style: bodySmall + fontSize(11) + w600 + primaryColor),
    ],
  ),
)
```

**Specifications:**
- Background: `primaryColor @ 10%` opacity
- Border: `primaryColor @ 30%` opacity, width `1px`
- Icon size: `12px`
- Text size: `11px`
- Font weight: `w600`

#### 3. ID Section
```dart
Row(
  children: [
    Icon(Icons.fingerprint, size: 14, color: AppColor.grey),
    const SizedBox(width: 4),
    Expanded(
      child: Text(
        'ID: $deviceId',
        style: bodySmall + fontSize(11) + grey,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  ],
)
```

**Spacing:** `10px` from header

#### 4. Action Buttons

**Responsive Behavior:**
- Small screens (<400px): Stack vertically
- Regular screens (≥400px): Side by side

**Button Specifications:**
```dart
ElevatedButton.icon(
  icon: Icon(icon, size: 16, color: white),
  label: Text(label, style: bodySmall + w600 + fontSize(12)),
  style: ElevatedButton.styleFrom(
    backgroundColor: color,
    elevation: 0,
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
)
```

- Height: `36px`
- Icon size: `16px`
- Text size: `12px`
- Border radius: `8px`
- No elevation
- Colors: Primary (edit), Red (delete)

**Vertical Layout (Small screens):**
```
[Edit Button - Full Width]
    ↓ 8px
[Delete Button - Full Width]
```

**Horizontal Layout (Regular screens):**
```
[Edit Button - 50%]  8px  [Delete Button - 50%]
```

### Spacing Summary

```
Icon + Title + Badge
    ↓ 10px
ID Section
    ↓ 12px
Action Buttons
```

### Complete Vertical Spacing

```
padding: 12px (top)
  Header Row (Icon + Title + Badge)
    ↓ 10px
  ID Section
    ↓ 12px
  Action Buttons
padding: 12px (bottom)
```

---

## 12. Responsive Breakpoints

### Device Card
- **Small Screen**: `< 400px`
  - Buttons: Vertical stack, full width
  - Title: Max 2 lines

- **Regular Screen**: `≥ 400px`
  - Buttons: Horizontal row, equal width (50% each)
  - Title: Max 2 lines

### General Guidelines
- Use `MediaQuery.of(context).size.width` for breakpoints
- Prefer `Expanded` + `TextOverflow.ellipsis` for long text
- Icon containers get subtle background for better contrast
- Maintain minimum touch target size (36px height for buttons)

---

## 13. Color Consistency Table

| Element Type | Color | Opacity | Usage |
|--------------|-------|---------|-------|
| Card Background | `whiteColor` | 100% | Main card background |
| Card Border | `primaryColor` | 20% | Card outline |
| Card Shadow | `black` | 5% | Subtle depth |
| Primary Text | `primaryColor` | 100% | Titles, important values |
| Secondary Text | `grey` | 100% | Labels, metadata |
| Icon Background | `lightPrimaryColor` | 20% | Icon container |
| Badge Background | `primaryColor` | 10% | Protocol badge |
| Badge Border | `primaryColor` | 30% | Badge outline |
| Value Container | `lightPrimaryColor` | 30% | Highlight background |
| Status Indicator | `green` | 100% | Live/active status |

---

## 14. Best Practices

### DO ✓
- Use consistent border radius (12px main, 8px sub-elements)
- Apply subtle shadows for depth (5% opacity)
- Use opacity for borders (20%) and backgrounds (10-30%)
- Maintain visual hierarchy with text sizes and weights
- Make text responsive with `Expanded` + `TextOverflow.ellipsis`
- Use meaningful icons with consistent sizes
- Provide adequate spacing between elements (8px, 10px, 12px)
- Ensure touch targets are at least 36px high

### DON'T ✗
- Don't use heavy shadows (max 5% opacity)
- Don't mix different border radius sizes randomly
- Don't forget responsive layouts for small screens
- Don't use too many different font sizes (stick to guide)
- Don't ignore text overflow handling
- Don't make buttons smaller than 36px height
- Don't use full opacity for borders (too harsh)

---

## 15. Accessibility Checklist

- [ ] Minimum text size is 10px (preferably 11px+)
- [ ] Minimum touch target is 36px height
- [ ] Color contrast ratio is sufficient
- [ ] Icons have minimum size of 12px (preferably 14px+)
- [ ] Text can wrap or truncate gracefully
- [ ] Buttons have clear labels, not just icons
- [ ] Important information uses bold or color emphasis
- [ ] Spacing allows for easy scanning
