import "./globals.css";

export const metadata = {
  title: {
    default: "Delts - Gym workouts, timer, and body progress",
    template: "%s - Delts"
  },
  description:
    "Delts is an iPhone workout planner with daily workouts, a focused timer, set logging, RPE, progress charts, Apple Health sync, and custom themes.",
  icons: {
    icon: "/assets/app-icon-lime.png"
  }
};

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
