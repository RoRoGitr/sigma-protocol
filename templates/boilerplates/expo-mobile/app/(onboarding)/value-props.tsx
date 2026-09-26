import { View, Text, Pressable, StyleSheet, ScrollView } from "react-native";
import { useRouter } from "expo-router";

/**
 * Onboarding Value Props Screen
 *
 * Highlights key app features. Navigates to permissions.
 *
 * @module mobileOnboarding
 */
export default function ValuePropsScreen() {
  const router = useRouter();

  return (
    <View style={styles.container}>
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}
      >
        {/* Header */}
        <View style={styles.header}>
          <Text style={styles.eyebrow}>Why you'll love it</Text>
          <Text style={styles.title}>Everything you need</Text>
          <Text style={styles.subtitle}>
            Built with best-in-class tools so you can focus on what matters.
          </Text>
        </View>

        {/* Feature cards */}
        <View style={styles.cards}>
          {features.map((feature, idx) => (
            <View key={idx} style={styles.card}>
              <View style={[styles.iconContainer, { backgroundColor: feature.color }]}>
                <Text style={styles.icon}>{feature.icon}</Text>
              </View>
              <View style={styles.cardText}>
                <Text style={styles.cardTitle}>{feature.title}</Text>
                <Text style={styles.cardDescription}>{feature.description}</Text>
              </View>
            </View>
          ))}
        </View>
      </ScrollView>

      {/* CTA */}
      <View style={styles.footer}>
        <Pressable
          style={styles.button}
          onPress={() => router.push("/(onboarding)/permissions")}
        >
          <Text style={styles.buttonText}>Next</Text>
        </Pressable>

        <Text style={styles.stepIndicator}>2 of 3</Text>
      </View>
    </View>
  );
}

const features = [
  {
    icon: "🔐",
    color: "#EEF2FF",
    title: "Secure Authentication",
    description: "Email, password, and OAuth sign-in via Supabase.",
  },
  {
    icon: "💳",
    color: "#F0FDF4",
    title: "In-App Purchases",
    description: "Subscriptions and one-time purchases via RevenueCat.",
  },
  {
    icon: "⚡",
    color: "#FFF7ED",
    title: "Fast & Native",
    description: "60fps animations and native feel on iOS and Android.",
  },
  {
    icon: "🌙",
    color: "#F5F3FF",
    title: "Dark Mode",
    description: "Automatic dark/light mode that follows system settings.",
  },
];

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#FFFFFF",
  },
  scrollContent: {
    paddingHorizontal: 24,
    paddingTop: 60,
    paddingBottom: 24,
  },
  header: {
    marginBottom: 40,
  },
  eyebrow: {
    fontSize: 13,
    fontWeight: "600",
    color: "#6366F1",
    textTransform: "uppercase",
    letterSpacing: 1,
    marginBottom: 8,
  },
  title: {
    fontSize: 32,
    fontWeight: "bold",
    color: "#111827",
    marginBottom: 12,
  },
  subtitle: {
    fontSize: 16,
    color: "#6B7280",
    lineHeight: 24,
  },
  cards: {
    gap: 16,
  },
  card: {
    flexDirection: "row",
    alignItems: "flex-start",
    gap: 16,
    padding: 16,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: "#F3F4F6",
    backgroundColor: "#FAFAFA",
  },
  iconContainer: {
    width: 48,
    height: 48,
    borderRadius: 12,
    alignItems: "center",
    justifyContent: "center",
    flexShrink: 0,
  },
  icon: {
    fontSize: 22,
  },
  cardText: {
    flex: 1,
    gap: 4,
  },
  cardTitle: {
    fontSize: 16,
    fontWeight: "600",
    color: "#111827",
  },
  cardDescription: {
    fontSize: 14,
    color: "#6B7280",
    lineHeight: 20,
  },
  footer: {
    padding: 24,
    paddingBottom: 40,
    gap: 16,
    alignItems: "center",
    borderTopWidth: 1,
    borderTopColor: "#F3F4F6",
  },
  button: {
    backgroundColor: "#6366F1",
    borderRadius: 16,
    paddingVertical: 18,
    alignItems: "center",
    width: "100%",
  },
  buttonText: {
    fontSize: 18,
    fontWeight: "600",
    color: "white",
  },
  stepIndicator: {
    fontSize: 13,
    color: "#9CA3AF",
  },
});
