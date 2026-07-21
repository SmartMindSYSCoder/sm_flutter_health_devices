# Suppress warnings for error-prone annotations
-dontwarn com.google.errorprone.annotations.CanIgnoreReturnValue
-dontwarn com.google.errorprone.annotations.CheckReturnValue
-dontwarn com.google.errorprone.annotations.Immutable
-dontwarn com.google.errorprone.annotations.RestrictedApi

# Suppress warnings for javax annotations
-dontwarn javax.annotation.Nullable
-dontwarn javax.annotation.concurrent.GuardedBy
# Please add these rules to your existing keep rules in order to suppress warnings.
# This is generated automatically by the Android Gradle plugin.
-dontwarn kotlinx.android.parcel.Parcelize
-dontwarn org.apache.commons.io.FileUtils