import type { Metadata } from "next";
import "./globals.css";
import { ConvexClientProvider } from "@/components/providers/convex-client-provider";

export const metadata: Metadata = {
  title: "SSS Next.js AI",
  description: "AI-first Next.js app with Convex real-time backend",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body>
        <ConvexClientProvider>{children}</ConvexClientProvider>
      </body>
    </html>
  );
}
