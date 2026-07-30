# Regras ProGuard/R8 (opcionais — R8 está desativado por padrão no build).
# Ative isMinifyEnabled/isShrinkResources em build.gradle.kts e teste o release
# antes de publicar. Regras de keep úteis com Firebase/Flutter:

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Flutter (o plugin já traz regras; mantidas aqui por referência)
-keep class io.flutter.** { *; }

# Modelos serializados via reflexão (adicione os seus, se necessário).
