import {
  View,
  Text,
  TextInput,
  Pressable,
  StyleSheet,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  Alert,
} from "react-native";
import { useRouter } from "expo-router";
import { useState } from "react";
import { useAuth } from "@/hooks/use-auth";

/**
 * Forgot Password Screen
 *
 * Sends a password reset email via Supabase.
 *
 * @module auth
 */
export default function ForgotPasswordScreen() {
  const router = useRouter();
  const { resetPassword } = useAuth();
  const [email, setEmail] = useState("");
  const [isLoading, setIsLoading] = useState(false);

  const handleReset = async () => {
    if (!email) {
      Alert.alert("Error", "Please enter your email address");
      return;
    }

    setIsLoading(true);
    const { error } = await resetPassword(email);
    setIsLoading(false);

    if (error) {
      Alert.alert("Error", error.message);
      return;
    }

    Alert.alert(
      "Email sent",
      "Check your inbox for a password reset link.",
      [{ text: "OK", onPress: () => router.back() }]
    );
  };

  return (
    <KeyboardAvoidingView
      behavior={Platform.OS === "ios" ? "padding" : "height"}
      style={styles.container}
    >
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        keyboardShouldPersistTaps="handled"
      >
        {/* Back button */}
        <Pressable style={styles.backButton} onPress={() => router.back()}>
          <Text style={styles.backText}>← Back</Text>
        </Pressable>

        {/* Header */}
        <View style={styles.header}>
          <Text style={styles.title}>Forgot password?</Text>
          <Text style={styles.subtitle}>
            Enter your email and we'll send you a reset link.
          </Text>
        </View>

        {/* Form */}
        <View style={styles.form}>
          <View style={styles.inputContainer}>
            <Text style={styles.label}>Email</Text>
            <TextInput
              style={styles.input}
              placeholder="you@example.com"
              placeholderTextColor="#9CA3AF"
              value={email}
              onChangeText={setEmail}
              keyboardType="email-address"
              autoCapitalize="none"
              autoCorrect={false}
            />
          </View>

          <Pressable
            style={[styles.button, isLoading && styles.buttonDisabled]}
            onPress={handleReset}
            disabled={isLoading}
          >
            <Text style={styles.buttonText}>
              {isLoading ? "Sending..." : "Send Reset Link"}
            </Text>
          </Pressable>
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#FFFFFF",
  },
  scrollContent: {
    flexGrow: 1,
    padding: 24,
  },
  backButton: {
    marginBottom: 32,
    marginTop: 8,
  },
  backText: {
    fontSize: 16,
    color: "#6366F1",
    fontWeight: "500",
  },
  header: {
    marginBottom: 40,
  },
  title: {
    fontSize: 28,
    fontWeight: "bold",
    color: "#111827",
    marginBottom: 12,
  },
  subtitle: {
    fontSize: 16,
    color: "#6B7280",
    lineHeight: 24,
  },
  form: {
    gap: 20,
  },
  inputContainer: {
    gap: 8,
  },
  label: {
    fontSize: 14,
    fontWeight: "500",
    color: "#374151",
  },
  input: {
    borderWidth: 1,
    borderColor: "#E5E7EB",
    borderRadius: 12,
    paddingHorizontal: 16,
    paddingVertical: 14,
    fontSize: 16,
    color: "#111827",
    backgroundColor: "#F9FAFB",
  },
  button: {
    backgroundColor: "#6366F1",
    borderRadius: 12,
    paddingVertical: 16,
    alignItems: "center",
    marginTop: 8,
  },
  buttonDisabled: {
    opacity: 0.7,
  },
  buttonText: {
    fontSize: 16,
    fontWeight: "600",
    color: "white",
  },
});
