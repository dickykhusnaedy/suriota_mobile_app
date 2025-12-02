# Claude AI - Panduan Lengkap untuk Development

## Daftar Isi

- [Pengenalan](#pengenalan)
- [Kemampuan Claude](#kemampuan-claude)
- [Best Practices](#best-practices)
- [Tips Berkomunikasi dengan Claude](#tips-berkomunikasi-dengan-claude)
- [Contoh Penggunaan](#contoh-penggunaan)
- [Workflow Development](#workflow-development)
- [Troubleshooting](#troubleshooting)
- [Advanced Features](#advanced-features)

---

## Pengenalan

Claude adalah AI assistant yang dikembangkan oleh Anthropic untuk membantu developer dalam berbagai tugas coding. Claude memiliki kemampuan untuk:

- Membaca dan memahami codebase
- Menulis dan memodifikasi kode
- Debugging dan troubleshooting
- Memberikan penjelasan teknis
- Melakukan code review
- Membuat dokumentasi

### Versi Claude

- **Claude 3.5 Sonnet**: Versi terbaru dengan kemampuan reasoning yang lebih baik
- **Claude 3 Opus**: Untuk tugas-tugas kompleks yang membutuhkan deep analysis
- **Claude 3 Haiku**: Untuk tugas-tugas cepat dan sederhana

---

## Kemampuan Claude

### 1. Code Understanding

Claude dapat memahami berbagai bahasa pemrograman:

- **Mobile**: Dart/Flutter, Kotlin, Swift, React Native
- **Backend**: PHP, Node.js, Python, Java, Go
- **Frontend**: JavaScript, TypeScript, React, Vue, Angular
- **Database**: SQL (Oracle, MySQL, PostgreSQL), NoSQL (MongoDB, Firebase)

### 2. Code Generation

- Membuat file baru dengan struktur yang benar
- Generate boilerplate code
- Membuat unit tests
- Membuat dokumentasi API

### 3. Code Modification

- Refactoring code
- Fixing bugs
- Optimasi performa
- Menambah fitur baru

### 4. Analysis & Review

- Code review
- Security analysis
- Performance analysis
- Best practices recommendations

---

## Best Practices

### 1. Komunikasi yang Jelas

#### ✅ DO (Lakukan):

```
"Buatkan fungsi untuk validasi email di file auth_service.dart
dengan aturan:
- Harus mengandung @
- Domain harus valid
- Return true/false
- Tambahkan error message"
```

#### ❌ DON'T (Jangan):

```
"Bikin validasi email dong"
```

### 2. Berikan Konteks yang Cukup

#### ✅ DO:

```
"Di file device_model.dart, saya punya class DeviceModel dengan
property deviceData dan registeredData. Saya ingin method
clearAllConfiguration() juga mengclear kedua property ini setelah
berhasil clear configuration dari server."
```

#### ❌ DON'T:

```
"Clear data dong"
```

### 3. Spesifikasi Teknis

#### ✅ DO:

```
"Implementasikan pagination di list devices dengan:
- Load 20 items per page
- Infinite scroll
- Loading indicator
- Error handling
- Gunakan BLoC pattern yang sudah ada"
```

#### ❌ DON'T:

```
"Tambahin pagination"
```

### 4. Referensi File yang Tepat

#### ✅ DO:

```
"Di file lib/presentation/pages/devices/settings/settings_device_screen.dart
pada line 568, tambahkan validasi sebelum save configuration"
```

#### ❌ DON'T:

```
"Di file settings tambahin validasi"
```

---

## Tips Berkomunikasi dengan Claude

### 1. Gunakan Bahasa yang Konsisten

- Pilih bahasa Indonesia atau Inggris dan konsisten
- Gunakan istilah teknis yang benar
- Hindari singkatan yang ambigu

### 2. Breakdown Tugas Kompleks

Untuk tugas besar, pecah menjadi langkah-langkah kecil:

```
Step 1: "Buatkan model untuk Device dengan property yang dibutuhkan"
Step 2: "Buatkan service untuk fetch device dari API"
Step 3: "Implementasikan BLoC untuk manage state device"
Step 4: "Buatkan UI untuk display list devices"
```

### 3. Berikan Feedback

Jika hasil tidak sesuai, berikan feedback yang spesifik:

#### ✅ DO:

```
"Kode sudah bagus, tapi saya ingin error handling-nya lebih detail.
Tambahkan handling untuk:
- Network timeout
- Server error 500
- Unauthorized 401
- Data not found 404"
```

#### ❌ DON'T:

```
"Error handling-nya kurang"
```

### 4. Tanyakan Penjelasan

Jangan ragu untuk meminta penjelasan:

```
"Bisa jelaskan kenapa menggunakan StreamBuilder di sini
dibanding FutureBuilder?"

"Apa keuntungan menggunakan pattern ini dibanding yang sebelumnya?"

"Bisa breakdown step-by-step cara kerja fungsi ini?"
```

---

## Contoh Penggunaan

### Contoh 1: Membuat Feature Baru

**Request:**

```
Saya ingin membuat fitur notifikasi push di aplikasi Flutter.
Requirements:
- Gunakan Firebase Cloud Messaging
- Support untuk Android dan iOS
- Tampilkan notification di foreground dan background
- Handle notification tap untuk navigate ke screen tertentu
- Save notification history ke local database (Hive)

Struktur folder yang diinginkan:
lib/
  features/
    notification/
      data/
        models/
        repositories/
      domain/
        entities/
        usecases/
      presentation/
        bloc/
        pages/
        widgets/
```

### Contoh 2: Debugging

**Request:**

```
Saya mendapat error di file settings_device_screen.dart line 568:

Error: type 'Null' is not a subtype of type 'String'

Context:
- Error muncul saat user tap tombol "Save Configuration"
- Data configuration diambil dari form
- Sebelumnya tidak ada error, muncul setelah saya tambah field baru

Bisa bantu identify masalahnya dan berikan solusi?
```

### Contoh 3: Code Review

**Request:**

```
Tolong review kode di file device_service.dart, khususnya:
1. Apakah error handling sudah cukup?
2. Apakah ada potential memory leak?
3. Apakah ada yang bisa dioptimasi?
4. Apakah sudah follow best practices Flutter?

Berikan saran improvement jika ada.
```

### Contoh 4: Refactoring

**Request:**

```
File device_model.dart sudah terlalu besar (500+ lines).
Tolong refactor dengan:
1. Pisahkan concerns yang berbeda
2. Extract reusable functions
3. Improve readability
4. Maintain backward compatibility
5. Tambahkan dokumentasi yang jelas
```

---

## Workflow Development

### 1. Planning Phase

```
1. Jelaskan fitur yang ingin dibuat
2. Diskusikan arsitektur dan approach
3. Identifikasi dependencies yang dibutuhkan
4. Buat breakdown tasks
```

### 2. Implementation Phase

```
1. Mulai dari model/entity
2. Buat repository/service layer
3. Implement business logic
4. Buat UI components
5. Integrate semua layer
```

### 3. Testing Phase

```
1. Minta Claude generate unit tests
2. Review test coverage
3. Test edge cases
4. Integration testing
```

### 4. Review Phase

```
1. Code review
2. Performance check
3. Security review
4. Documentation update
```

---

## Troubleshooting

### Masalah Umum dan Solusi

#### 1. Claude Tidak Memahami Konteks

**Solusi:**

- Berikan lebih banyak informasi tentang codebase
- Share relevant code snippets
- Jelaskan arsitektur yang digunakan
- Berikan contoh konkret

#### 2. Kode yang Dihasilkan Tidak Sesuai

**Solusi:**

- Berikan feedback spesifik
- Tunjukkan contoh yang diinginkan
- Jelaskan constraint atau limitation
- Minta alternative approach

#### 3. Error Saat Implementasi

**Solusi:**

- Share complete error message
- Berikan context (file, line number)
- Jelaskan steps yang sudah dilakukan
- Share relevant code

#### 4. Claude Memberikan Solusi Terlalu Kompleks

**Solusi:**

- Minta solusi yang lebih simple
- Jelaskan level expertise Anda
- Minta step-by-step explanation
- Tanyakan alternative yang lebih sederhana

---

## Advanced Features

### 1. Multi-file Operations

Claude dapat bekerja dengan multiple files sekaligus:

```
"Saya ingin refactor authentication flow:
1. Update auth_service.dart untuk support biometric
2. Modify auth_bloc.dart untuk handle biometric state
3. Update login_screen.dart untuk show biometric option
4. Tambah biometric_helper.dart untuk utility functions

Pastikan semua perubahan compatible dan tidak break existing functionality."
```

### 2. Pattern Implementation

Minta Claude implement design patterns:

```
"Implementasikan Repository Pattern untuk data layer dengan:
- Abstract repository interface
- Concrete implementation untuk API
- Concrete implementation untuk local storage
- Dependency injection menggunakan GetIt
- Error handling yang konsisten
```

### 3. Migration & Upgrade

```
"Saya ingin migrate dari Provider ke BLoC:
1. Identify semua Provider yang digunakan
2. Buat equivalent BLoC untuk masing-masing
3. Update UI untuk consume BLoC
4. Ensure state management tetap konsisten
5. Buat migration guide untuk team
```

### 4. Performance Optimization

```
"Optimize performa di device list screen:
1. Implement lazy loading
2. Add caching mechanism
3. Optimize widget rebuilds
4. Reduce memory usage
5. Improve scroll performance

Berikan before/after metrics jika memungkinkan."
```

### 5. Documentation Generation

```
"Generate dokumentasi lengkap untuk device module:
1. API documentation
2. Code documentation (dartdoc)
3. Architecture diagram
4. Flow diagram
5. Usage examples
6. Troubleshooting guide
```

---

## Tips Khusus untuk Flutter Development

### 1. State Management

Jelaskan state management yang digunakan:

```
"Aplikasi ini menggunakan BLoC pattern. Saat membuat fitur baru,
ikuti struktur yang sudah ada di folder lib/presentation/bloc/"
```

### 2. Naming Convention

Spesifikasikan naming convention:

```
"Gunakan naming convention:
- Files: snake_case (device_model.dart)
- Classes: PascalCase (DeviceModel)
- Variables: camelCase (deviceData)
- Constants: SCREAMING_SNAKE_CASE (API_BASE_URL)
```

### 3. Folder Structure

Jelaskan struktur folder:

```
"Ikuti clean architecture:
- data/: models, repositories, data sources
- domain/: entities, use cases
- presentation/: bloc, pages, widgets
```

### 4. Dependencies

Informasikan dependencies yang digunakan:

```
"Aplikasi menggunakan:
- dio untuk HTTP client
- hive untuk local storage
- get_it untuk dependency injection
- flutter_bloc untuk state management
```

---

## Checklist Sebelum Meminta Bantuan

- [ ] Sudah mencoba solve sendiri
- [ ] Sudah search dokumentasi/Stack Overflow
- [ ] Punya error message yang lengkap
- [ ] Tahu file dan line number yang bermasalah
- [ ] Punya context yang cukup
- [ ] Sudah prepare code snippet yang relevan
- [ ] Tahu expected behavior vs actual behavior
- [ ] Sudah identifikasi steps to reproduce

---

## Template Request

### Template Bug Fix

```
**Deskripsi Bug:**
[Jelaskan bug yang terjadi]

**Expected Behavior:**
[Apa yang seharusnya terjadi]

**Actual Behavior:**
[Apa yang sebenarnya terjadi]

**Steps to Reproduce:**
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Error Message:**
```

[Paste error message]

```

**Relevant Code:**
[File path dan line number]

**Environment:**
- Flutter version: [version]
- Dart version: [version]
- Device: [Android/iOS]
- OS version: [version]
```

### Template Feature Request

```
**Feature Description:**
[Jelaskan fitur yang diinginkan]

**Requirements:**
1. [Requirement 1]
2. [Requirement 2]
3. [Requirement 3]

**Technical Constraints:**
- [Constraint 1]
- [Constraint 2]

**Acceptance Criteria:**
- [ ] [Criteria 1]
- [ ] [Criteria 2]
- [ ] [Criteria 3]

**Additional Context:**
[Informasi tambahan yang relevan]
```

### Template Code Review

```
**File to Review:**
[File path]

**Focus Areas:**
1. [Area 1 - e.g., Performance]
2. [Area 2 - e.g., Security]
3. [Area 3 - e.g., Best Practices]

**Specific Concerns:**
- [Concern 1]
- [Concern 2]

**Context:**
[Jelaskan context dari kode ini]
```

---

## Keyboard Shortcuts & Commands

### Useful Commands

- `/help` - Tampilkan bantuan
- `/clear` - Clear conversation
- `/context` - Show current context
- `/files` - List open files

### Tips Produktivitas

1. **Copy Error Messages**: Selalu copy full error message
2. **Use Code Blocks**: Format kode dengan markdown code blocks
3. **Reference Line Numbers**: Sebutkan line number untuk precision
4. **Save Conversations**: Save conversation penting untuk referensi

---

## Resources & Links

### Dokumentasi

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Documentation](https://dart.dev/guides)
- [Firebase Documentation](https://firebase.google.com/docs)

### Best Practices

- [Flutter Best Practices](https://flutter.dev/docs/development/best-practices)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [Flutter Architecture Samples](https://github.com/brianegan/flutter_architecture_samples)

### Community

- [Flutter Community](https://flutter.dev/community)
- [Stack Overflow - Flutter](https://stackoverflow.com/questions/tagged/flutter)
- [Reddit - FlutterDev](https://www.reddit.com/r/FlutterDev/)

---

## Version History

### v1.0.0 (2025-12-02)

- Initial documentation
- Added comprehensive guide
- Added templates and examples
- Added troubleshooting section

---

## Notes

### Hal yang Perlu Diingat

1. **Context Window**: Claude memiliki limit context, jadi untuk codebase besar, fokus pada file yang relevan
2. **Iterative Approach**: Untuk tugas kompleks, lakukan secara iteratif
3. **Verification**: Selalu verify kode yang dihasilkan Claude
4. **Testing**: Test thoroughly sebelum commit ke production
5. **Documentation**: Update dokumentasi setelah perubahan besar

### Limitations

1. Claude tidak bisa run code secara langsung
2. Tidak bisa access external APIs tanpa context
3. Tidak bisa modify files di luar workspace
4. Perlu context yang jelas untuk hasil optimal

---

## FAQ

### Q: Bagaimana cara memberikan context yang baik?

**A:** Berikan informasi tentang:

- Arsitektur aplikasi
- Dependencies yang digunakan
- Conventions yang diikuti
- File dan code yang relevan
- Expected behavior

### Q: Apakah Claude bisa membantu dengan debugging?

**A:** Ya, berikan:

- Complete error message
- Stack trace
- Relevant code
- Steps to reproduce
- Expected vs actual behavior

### Q: Bagaimana cara meminta code review?

**A:** Spesifikasikan:

- File yang ingin direview
- Focus areas (performance, security, etc.)
- Specific concerns
- Context dari kode tersebut

### Q: Apakah Claude bisa generate tests?

**A:** Ya, Claude bisa generate:

- Unit tests
- Widget tests
- Integration tests
- Test cases dan scenarios

### Q: Bagaimana jika hasil tidak sesuai harapan?

**A:**

- Berikan feedback yang spesifik
- Jelaskan apa yang kurang
- Berikan contoh yang diinginkan
- Minta alternative approach

---

## Conclusion

Claude adalah tool yang powerful untuk development, tapi efektivitasnya tergantung pada:

1. **Komunikasi yang jelas**: Jelaskan kebutuhan dengan detail
2. **Context yang cukup**: Berikan informasi yang relevan
3. **Feedback yang konstruktif**: Bantu Claude understand kebutuhan Anda
4. **Iterative approach**: Lakukan secara bertahap untuk hasil optimal

**Remember**: Claude adalah assistant, bukan replacement untuk developer. Selalu review, test, dan understand kode yang dihasilkan.

---

**Last Updated**: 2025-12-02  
**Maintained by**: Dicky - R&D Suriota Team  
**Version**: 1.0.0
