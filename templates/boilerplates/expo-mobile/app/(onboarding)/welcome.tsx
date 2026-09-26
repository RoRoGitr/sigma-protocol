import { View, Text, Pressable, StyleSheet } from "react-native";
import { useRouter } from "expo-router";
import { LinearGradient } from "expo-linear-gradient";

/**
 * Onboarding Welcome Screen (named route)
 *
 * App branding introduction. Navigates to value-props.
 *
 * @module mobileOnboarding
 */
export default function WelcomeScreen() {
  const router = useRouter();

  return (
    <LinearGradient
      colors={["#8B5CF6", "#6366F1", "#3B82F6"]}
      style={styles.container}
    >
      <View style={styles.content}>
        <View style={styles.logoContainer}>
          <View style={styles.logo} />
        </View>

        <Text style={styles.title}>Welcome</Text>
        <Text style={styles.subtitle}>
          Let's get you set up in just a few steps.
        </Text>
      </View>

      <View style={styles.ctaContainer}>
        <Pressable
          style={styles.button}
          onPress={() => router.push("/(onboarding)/value-props")}
        >
          <Text style={styles.buttonText}>Continue</Text>
        </Pressable>
      </View>
    </LinearGradient>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  content: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    paddingHorizontal: 32,
  },
  logoContainer: {
    marginBottom: 32,
  },
  logo: {
    width: 100,
    height: 100,
    borderRadius: 24,
    backgroundColor: "rgba(255, 255, 255, 0.2)",
  },
  title: {
    fontSize: 36,
    fontWeight: "bold",
    color: "white",
    marginBottom: 16,
    textAlign: "center",
  },
  subtitle: {
    fontSize: 18,
    color: "rgba(255, 255, 255, 0.8)",
    textAlign: "center",
  },
  ctaContainer: {
    padding: 32,
  },
  button: {
    backgroundColor: "white",
    borderRadius: 16,
    paddingVertical: 18,
    alignItems: "center",
  },
  buttonText: {
    fontSize: 18,
    fontWeight: "600",
    color: "#6366F1",
  },
});
