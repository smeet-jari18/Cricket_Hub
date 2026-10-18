# Android build failing? — `build.gradle.kts` edition

> **Pehla fact:** `android/build.gradle.kts` ka content jo error me dikhta hai wo
> **Flutter 3.47 ka stock template hai** aur is project me bilkul wahi file hai.
> Matlab file galat nahi hai — Gradle console us file ka naam isliye leta hai
> kyunki **wahi se build shuru hoti hai**, asli wajah 6 line neeche hoti hai.

Sabse pehle:

```powershell
cd "D:\Project\Cricket Hub\cricket_hub"
python tools/check_android_setup.py
```

Ye 8 cheezein check karta hai aur seedha bata deta hai kya toota hai.

---

## 1. "Unresolved reference: allprojects / Directory / Delete"

```
e: build.gradle.kts:1:1 Unresolved reference: allprojects
e: build.gradle.kts:8:25 Unresolved reference: Directory
```

**Ye build error nahi, IDE ka red squiggle hai.** Kotlin DSL ke accessors aur
default imports tabhi resolve hote hain jab **Gradle sync successfully** ho
chuka ho. Agar sync fail hua hai (SDK path, JDK, network), to IDE har cheez ko
unresolved dikhata hai.

**Fix:** error ko terminal me dekho —

```powershell
cd "D:\Project\Cricket Hub\cricket_hub"
flutter clean
flutter run -v 2>&1 | Select-String -Pattern "What went wrong" -Context 0,12
```

Jo `* What went wrong:` ke neeche aaye, wahi asli error hai. IDE ko ignore karo.

---

## 2. "Build was configured to prefer settings repositories over project repositories"

Poora message:

```
Build was configured to prefer settings repositories over project repositories
but repository 'Google' was added by build file 'android/build.gradle.kts'
```

**Wajah:** `settings.gradle.kts` me `RepositoriesMode.FAIL_ON_PROJECT_REPOS` on
hai, aur root build file bhi `allprojects { repositories { … } }` declare kar
raha hai. Dono ek saath nahi chal sakte.

**Fix A (recommended)** — root file se `allprojects` block hata do, kyunki
`settings.gradle.kts` me pehle se `google()` + `mavenCentral()` hain:

```kotlin
// android/build.gradle.kts — allprojects { repositories { … } } DELETE karo
val newBuildDir: Directory =
    rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)
...
```

**Fix B** — settings me mode dheela karo:

```kotlin
// android/settings.gradle.kts
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_PROJECT)
}
```

---

## 3. "flutter.sdk not set in local.properties"

Build shuru hote hi:

```
> flutter.sdk not set in local.properties
```

**Wajah:** `android/local.properties` missing hai ya usme `flutter.sdk` nahi.
Ye file **gitignored** hai — naye clone ya zip extract ke baad banani padti hai.

**Fix:**

```powershell
cd "D:\Project\Cricket Hub\cricket_hub"
flutter config --jdk-dir "C:\Program Files\Java\jdk-21"   # optional
flutter doctor -v                                          # SDK paths dikhayega
```

`android/local.properties`:

```properties
sdk.dir=C:\\Users\\<you>\\AppData\\Local\\Android\\Sdk
flutter.sdk=C:\\flutter
```

> Windows pe backslash **double** likhna hota hai (`\\`).

---

## 4. "SDK location not found"

```
SDK location not found. Define a valid SDK location with an ANDROID_HOME
environment variable or by setting the sdk.dir path in your project's
local.properties file
```

Same fix as #3 — `sdk.dir` line. Android Studio me: **File → Project
Structure → SDK Location**, ya `flutter doctor --android-licenses` chalao.

---

## 5. "Android Gradle plugin requires Java 17" / "Unsupported class file major version"

```
Android Gradle plugin requires Java 17 to run. You are currently using Java 11.
```

Ya:

```
Unsupported class file major version 65
```

**Wajah:** is project ka template AGP **9.1.0** + Gradle **9.3.1** hai — usko
**JDK 17 ya 21** chahiye. Purana JDK 11/8 chal raha hai.

**Fix:**

```powershell
flutter config --jdk-dir "C:\Program Files\Java\jdk-21"
java -version      # 17+ dikhna chahiye
```

---

## 6. Dono build files ek saath

```
Build file 'android/build.gradle.kts' already exists
```

ya Gradle bilkul hi ghum-phir ke fail ho jaata hai.

**Wajah:** purane project se `build.gradle` (Groovy) bhi aa gaya aur naya
`build.gradle.kts` bhi hai. Gradle ko dono me se ek hi chunna hota hai.

**Fix:** Groovy wali delete karo (`android/build.gradle`, `android/app/build.gradle`),
`.kts` rakho. Ye project `.kts` pe chalta hai.

---

## Sab kuch fail ho jaye to — nuclear option

```powershell
cd "D:\Project\Cricket Hub\cricket_hub\android"
.\gradlew.bat --stop
Remove-Item -Recurse -Force .gradle
cd ..
flutter clean
flutter pub get
flutter run -v
```

`-v` ka matlab verbose — poora error copy karne layak milega.

---

## Kaise pata chalega ki theek ho gaya

```powershell
python tools/check_android_setup.py     # 0 problems
flutter run
```

---

## 0. VS Code me file laal hai, par build chal rahi hai (sabse common)

Screenshot-type case: `build.gradle.kts` ka tab **laal**, `Problems: 1`, aur
underline `val newBuildDir: Directory =` ke `Directory` pe.

**Ye Gradle ka error nahi hai.** Ye VS Code ke Java/Kotlin language server ka
false positive hai: `.kts` file khulte waqt wo Gradle ke **implicit DSL imports**
(`org.gradle.api.file.Directory`, `org.gradle.api.tasks.Delete`, `allprojects`)
nahi jaanta, isliye har type ko "unresolved" samajhta hai.

**Proof (maine isi machine pe chalaya):**

```
$ gradle help          # yehi file, Gradle 9.3.1, JDK 21
BUILD SUCCESSFUL
$ gradle clean
BUILD SUCCESSFUL
```

Aap bhi 20 second me confirm kar sakte ho:

```powershell
cd "D:\Project\Cricket Hub\cricket_hub\android"
.\gradlew.bat help
```

`BUILD SUCCESSFUL` = file bilkul theek hai, laal underline ignore karo.

### Fix (optional — sirf editor chup karane ke liye)

File ke top pe do imports add kar do. Gradle ke liye redundant hain, par
language server ko types mil jaate hain:

```kotlin
import org.gradle.api.file.Directory
import org.gradle.api.tasks.Delete
```

Isi file me ye already add kar diye gaye hain.

### Agar VS Code me phir bhi laal rahe

1. **Android Studio** me `android/` folder kholo — wo `.kts` natively samajhta
   hai. Flutter ke liye VS Code theek hai, par Android config ke liye AS behtar.
2. Ya VS Code me **Extension Pack for Java** + **Gradle for Java** install karo,
   phir `Ctrl+Shift+P` → *Java: Clean Java Language Server Workspace* → reload.
3. Ya bas ignore karo — **Gradle khud is file ko sahi padhta hai.**

> ⚠️ Is file ko delete mat karo, aur ise `app/build.gradle.kts` me paste mat
> karo. Ye root file build output ko `android/` ke bahar move karti hai — Flutter
> ka plugin usi par depend karta hai.
