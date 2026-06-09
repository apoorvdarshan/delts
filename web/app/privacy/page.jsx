import Link from "next/link";
import { Eyebrow, PageShell } from "../components";

export const metadata = {
  title: "Privacy Policy",
  description: "Privacy Policy for Delts."
};

const sections = [
  {
    title: "Overview",
    body: "Delts is an iPhone workout planning and tracking app. This policy explains the information handled by the app and the choices available to users. This document is informational and should be reviewed before publication."
  },
  {
    title: "Information you enter",
    body: "Delts can store workout plans, selected exercises, sets, reps, RPE, workout timing, body weight, body fat, profile preferences, training goals, target muscles, issues, equipment preferences, and app settings such as appearance and theme."
  },
  {
    title: "Apple Health",
    body: "Apple Health access is optional. If you grant permission, Delts can read and write supported body weight and body fat records. You can revoke Health access in iOS Settings at any time."
  },
  {
    title: "Accounts, analytics, and ads",
    body: "Delts does not require an account for the core app experience. The app is not designed around third-party advertising. If analytics, crash reporting, cloud sync, or subscriptions are added later, this policy should be updated before release."
  },
  {
    title: "Support contacts",
    body: "For privacy questions, contact apoorvdarshan@gmail.com or ad13dtu@gmail.com."
  },
  {
    title: "Changes",
    body: "This policy may be updated when app behavior changes. The date above should be updated when a new policy is published."
  }
];

export default function PrivacyPage() {
  return (
    <PageShell>
      <main className="site-shell page-main">
        <header className="page-header">
          <Eyebrow>Last updated June 9, 2026</Eyebrow>
          <h1>Privacy Policy</h1>
        </header>

        <div className="policy">
          {sections.map((section) => (
            <article key={section.title}>
              <h2>{section.title}</h2>
              <p>{section.body}</p>
            </article>
          ))}
        </div>

        <p className="page-return">
          <Link href="/">Back to home</Link>
        </p>
      </main>
    </PageShell>
  );
}
