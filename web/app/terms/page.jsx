import Link from "next/link";
import { Eyebrow, PageShell } from "../components";

export const metadata = {
  title: "Terms",
  description: "Terms for Delts."
};

const sections = [
  {
    title: "Use of Delts",
    body: "Delts is provided for workout planning, logging, and personal progress tracking. You are responsible for the accuracy of information you enter and for how you use the app during training."
  },
  {
    title: "Fitness disclaimer",
    body: "Delts is not medical advice, fitness coaching from a licensed professional, or a substitute for professional medical guidance. Consult a qualified professional before changing exercise routines, especially if you have medical conditions, injuries, or other concerns."
  },
  {
    title: "Apple Health",
    body: "If you enable Apple Health integration, you are responsible for granting and managing permissions in iOS Settings. Health data shown by Delts depends on permissions and data availability."
  },
  {
    title: "Availability",
    body: "The app may change over time. Features can be updated, renamed, removed, or temporarily unavailable as development continues."
  },
  {
    title: "Acceptable use",
    body: "Do not misuse the app, attempt to reverse engineer services connected to it, or use it in a way that violates applicable laws or platform rules."
  },
  {
    title: "Contact",
    body: "For support or terms questions, contact apoorvdarshan@gmail.com or ad13dtu@gmail.com."
  }
];

export default function TermsPage() {
  return (
    <PageShell>
      <main className="site-shell page-main">
        <header className="page-header">
          <Eyebrow>Last updated June 9, 2026</Eyebrow>
          <h1>Terms</h1>
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
