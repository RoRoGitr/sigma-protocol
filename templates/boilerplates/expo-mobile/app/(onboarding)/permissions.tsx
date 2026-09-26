import {
  View,
  Text,
  Pressable,
  StyleSheet,
  Platform,
  Alert,
} from "react-native";
import { useRouter } from "expo-router";
import * as Notifications from "expo-notifications";

/**
 * Onboarding Permissions Screen
 *
 * Requests push notification permission before entering the app.
 * Navigates to the main tab navigator on completion.
 *
 * @module mobileOnboarding
 */
export default function PermissionsScreen() {
  const router = useRouter();

  const requestNotificationPermission = async () => {
    if (Platform.OS === "web") {
      router.replace("/(tabs)");
      return;
    }

    const { status } = await Notifications.requestPermissionsAsync();

    if (status !== "granted") {
      Alert.alert(
        "Notifications off",
        "You can enable notifications later in your device settings.",
        [{ text: "OK", onPress: () => router.replace("/(tabs)") }]
      );
      return;
    }

    router.replace("/(tabs)");
  };

  const skipPermissions = () => {
    router.replace("/(tabs)");
  };

  return (
    <View style={styles.container}>
      <View style={styles.content}>
        {/* Icon */}
        <View style={styles.iconContainer}>
          <Text style={styles.iconEmoji}>🔔</Text>
        </View>

        {/* Text */}
        <Text style={styles.title}>Stay in the loop</Text>
        <Text style={styles.subtitle}>
          Enable notifications to get important updates, reminders, and news
          delivered directly to you.
        </Text>

        {/* Permission items */}
        <View style={styles.permissionList}>
          {permissions.map((item, idx) => (
            <View key={idx} style={styles.permissionItem}>
              <Text style={styles.permissionIcon}>{item.icon}</Text>
              <View style={styles.permissionText}>
                <Text style={styles.permissionTitle}>{item.title}</Text>
                <Text style={styles.permissionDescription}>
                  {item.description}
                </Text>
              </View>
            </View>
          ))}
        </View>
      </View>

      {/* CTA */}
      <View style={styles.footer}>
        <Pressable style={styles.button} onPress={requestNotificationPermission}>
          <Text style={styles.buttonText}>Allow Notifications</Text>
        </Pressable>

        <Pressable style={styles.skipButton} onPress={skipPermissions}>
          <Text style={styles.skipText}>Maybe later</Text>
        </Pressable>

        <Text style={styles.stepIndicator}>3 of 3</Text>
      </View>
    </View>
  );
}

const permissions = [
  {
    icon: "📣",
    title: "Important updates",
    description: "Get notified about new features and announcements.",
  },
  {
    icon: "⏰",
    title: "Reminders",
    description: "Timely reminders so you never miss a beat.",
  },
];

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#FFFFFF",
  },
  content: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    paddingHorizontal: 24,
  },
  iconContainer: {
    width: 96,
    height: 96,
    borderRadius: 24,
    backgroundColor: "#EEF2FF",
    alignItems: "center",
    justifyContent: "center",
    marginBottom: 32,
  },
  iconEmoji: {
    fontSize: 44,
  },
  title: {
    fontSize: 28,
    fontWeight: "bold",
    color: "#111827",
    marginBottom: 12,
    textAlign: "center",
  },
  subtitle: {
    fontSize: 16,
    color: "#6B7280",
    lineHeight: 24,
    textAlign: "center",
    marginBottom: 40,
  },
  permissionList: {
    width: "100%",
    gap: 16,
  },
  permissionItem: {
    flexDirection: "row",
    alignItems: "flex-start",
    gap: 16,
    padding: 16,
    borderRadius: 16,
    backgroundColor: "#F9FAFB",
    borderWidth: 1,
    borderColor: "#F3F4F6",
  },
  permissionIcon: {
    fontSize: 24,
  },
  permissionText: {
    flex: 1,
    gap: 4,
  },
  permissionTitle: {
    fontSize: 15,
    fontWeight: "600",
    color: "#111827",
  },
  permissionDescription: {
    fontSize: 13,
    color: "#6B7280",
    lineHeight: 18,
  },
  footer: {
    padding: 24,
    paddingBottom: 40,
    gap: 12,
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
  skipButton: {
    paddingVertical: 8,
    alignItems: "center",
  },
  skipText: {
    fontSize: 15,
    color: "#6B7280",
  },
  stepIndicator: {
    fontSize: 13,
    color: "#9CA3AF",
    marginTop: 4,
  },
});
