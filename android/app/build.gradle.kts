import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Assinatura de release: lida de android/key.properties (não versionado).
// Sem esse arquivo, cai na chave de debug para que `flutter build apk` funcione
// durante o desenvolvimento. NUNCA publique um release assinado com a chave de debug.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "br.com.novaalianca.nova_alianca_app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Necessário para flutter_local_notifications (APIs de data/hora Java 8+).
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "br.com.novaalianca.nova_alianca_app"
        // minSdk 23: requisito confortável para Firebase Auth/Firestore e FCM.
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
                storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String?
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                // Fallback de desenvolvimento — não usar para publicação.
                signingConfigs.getByName("debug")
            }
            // R8/shrink desativado por padrão (comportamento padrão do Flutter).
            // Para ativar, use o proguard-rules.pro incluído e teste o release.
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

// Aplica o plugin do Google Services somente se google-services.json existir,
// para não quebrar o build antes de o Firebase estar configurado.
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
    apply(plugin = "com.google.firebase.crashlytics")
}

flutter {
    source = "../.."
}

dependencies {
    // Suporte às APIs de data/hora Java 8+ em Android antigos.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
