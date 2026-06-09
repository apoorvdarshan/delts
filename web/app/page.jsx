import Link from "next/link";
import { Eyebrow, PageShell } from "./components";

const features = [
  {
    title: "Daily workout board",
    body: "Build today from the exercise library, saved workouts, or copied days. Cards show sets, reps, RPE, and the muscle/equipment context at a glance."
  },
  {
    title: "Workout timer",
    body: "The main red timer starts and ends the workout, drives session timing, and supports a focused Live Activity timer on iPhone."
  },
  {
    title: "Set, rep, and RPE logging",
    body: "Log reps and effort only while the workout is active, with support for strength RPE and CR10-style effort tracking."
  },
  {
    title: "Exercise library",
    body: "Browse exercises by target muscles, equipment, level, and split. Detail pages keep the exercise image visible while instructions scroll."
  },
  {
    title: "Progress charts",
    body: "Track weight and body fat with weekly, monthly, 3M, 6M, 1Y, and all-time ranges, visible grid lines, averages, net change, and goals."
  },
  {
    title: "Apple Health sync",
    body: "Optional HealthKit access can import and save body weight and body fat logs when the user grants permission."
  },
  {
    title: "Body composition pickers",
    body: "Choose exact body fat numbers or visual ranges, with separate preferences for current and goal body fat."
  },
  {
    title: "Personalized preferences",
    body: "Set height, weight, training goal, target muscles, issues, frequency, duration range, split, equipment, and optional 1RM anchors."
  },
  {
    title: "Custom themes and icons",
    body: "Switch between Lime, Cyan, Pink, Amber, and Violet. The app tint and Home Screen icon change from the same setting."
  }
];

const stats = [
  ["4", "core workout tabs for home, library, progress, and settings."],
  ["2", "body metrics tracked with clear goal lines."],
  ["5", "theme and app icon color options."],
  ["0", "accounts required to start using the app."]
];

const icons = ["lime", "cyan", "pink", "amber", "violet"];

export default function HomePage() {
  return (
    <PageShell>
      <main>
        <section className="hero" aria-labelledby="hero-title">
          <div className="site-shell hero-content">
            <Eyebrow>iPhone workout command center</Eyebrow>
            <h1 id="hero-title">Delts</h1>
            <p className="hero-copy">
              Plan the session, hit the red timer, log the real sets, and watch weight and
              body fat progress without turning your workout into admin work.
            </p>
            <div className="hero-actions">
              <Link className="button primary" href="#features">
                Explore features
              </Link>
              <Link className="button" href="/privacy">
                Read privacy
              </Link>
            </div>
          </div>
        </section>

        <div className="site-shell quick-stats" aria-label="App highlights">
          {stats.map(([value, label]) => (
            <div className="stat-card" key={label}>
              <strong>{value}</strong>
              <span>{label}</span>
            </div>
          ))}
        </div>

        <section id="features" className="site-shell" aria-labelledby="features-title">
          <div className="section-heading">
            <Eyebrow>What Delts does</Eyebrow>
            <h2 id="features-title">A gym app built around the session timer.</h2>
            <p>
              Delts treats the red start button as the workout source of truth. Add
              workouts, start the timer, log the work, and keep the rest quiet.
            </p>
          </div>
          <div className="feature-grid">
            {features.map((feature, index) => (
              <article className="feature-card" key={feature.title}>
                <span className="number">{String(index + 1).padStart(2, "0")}</span>
                <div>
                  <h3>{feature.title}</h3>
                  <p>{feature.body}</p>
                </div>
              </article>
            ))}
          </div>
        </section>

        <section id="product" className="site-shell" aria-labelledby="product-title">
          <div className="product-strip">
            <div className="phone-stage" aria-label="Delts app preview">
              <div className="phone">
                <div className="phone-header">
                  <span>Today</span>
                  <span>4 workouts</span>
                </div>
                <div className="timer-button">0:00</div>
                <div className="mini-panel">
                  <div className="mini-grid">
                    <span>
                      <strong>0</strong>Sets
                    </span>
                    <span>
                      <strong>4</strong>Workouts
                    </span>
                    <span>
                      <strong>0</strong>Reps
                    </span>
                    <span>
                      <strong>--</strong>Burn
                    </span>
                  </div>
                  <WorkoutRow icon="lime" title="Ab Crunch Machine" detail="Abdominals - Machine" />
                  <WorkoutRow icon="cyan" title="90/90 Hamstring" detail="Hamstrings - Body Only" />
                  <WorkoutRow icon="pink" title="Adductor/Groin" detail="Adductors - Unspecified" />
                </div>
              </div>
            </div>

            <div className="detail-stack">
              <div className="section-heading">
                <Eyebrow>The flow</Eyebrow>
                <h2 id="product-title">Start, train, log, review.</h2>
                <p>
                  The homepage keeps workout setup visible, the detail view keeps
                  instructions and exercise images close, and progress keeps the long-term
                  signal readable.
                </p>
              </div>
              <Callout title="Focused workout state">
                Editing set data is tied to an active timer. That keeps planned workouts
                separate from performed work.
              </Callout>
              <Callout title="Readable progress">
                Weight and body fat charts use a visible grid, exact four x-axis dates per
                range, and year labels when long ranges cross years.
              </Callout>
              <article className="callout">
                <h3>Theme-linked identity</h3>
                <p>Theme color and app icon stay matched, with real icon previews in Settings.</p>
                <div className="theme-row" aria-label="Theme icon options">
                  {icons.map((icon) => (
                    <img
                      key={icon}
                      src={`/assets/app-icon-${icon}.png`}
                      alt={`${titleCase(icon)} Delts icon`}
                    />
                  ))}
                </div>
              </article>
            </div>
          </div>
        </section>

        <section id="privacy" className="site-shell" aria-labelledby="privacy-title">
          <div className="section-heading">
            <Eyebrow>Privacy and control</Eyebrow>
            <h2 id="privacy-title">No account required. Health access is optional.</h2>
            <p>
              Delts is designed around local workout planning and logging. Apple Health
              access is permission-based and can be turned off by the user.
            </p>
          </div>
          <div className="legal-grid">
            <article className="legal-card">
              <h3>Privacy Policy</h3>
              <p>
                Explains what the app stores, how optional HealthKit sync works, and how to
                contact support.
              </p>
              <p>
                <Link href="/privacy">Open privacy policy</Link>
              </p>
            </article>
            <article className="legal-card">
              <h3>Terms</h3>
              <p>
                Explains acceptable use, fitness disclaimers, app availability, and support
                contact points.
              </p>
              <p>
                <Link href="/terms">Open terms</Link>
              </p>
            </article>
          </div>
        </section>

        <section className="site-shell" aria-labelledby="docs-title">
          <div className="section-heading">
            <Eyebrow>Open project docs</Eyebrow>
            <h2 id="docs-title">Built with contributor and security docs.</h2>
            <p>
              The repo includes README, contributing, security, and App Store listing notes
              for development and submission workflows.
            </p>
          </div>
          <div className="doc-grid">
            <article className="doc-card">
              <h3>Support</h3>
              <p>For product questions, contact apoorvdarshan@gmail.com or ad13dtu@gmail.com.</p>
            </article>
            <article className="doc-card">
              <h3>Source</h3>
              <p>
                The iOS app and website live in the same repository, with the Next.js site
                under <code>web/</code>.
              </p>
            </article>
          </div>
        </section>
      </main>
    </PageShell>
  );
}

function WorkoutRow({ icon, title, detail }) {
  return (
    <div className="workout-row">
      <img className="workout-thumb" src={`/assets/app-icon-${icon}.png`} alt="" />
      <div>
        <b>{title}</b>
        <small>{detail}</small>
      </div>
    </div>
  );
}

function Callout({ title, children }) {
  return (
    <article className="callout">
      <h3>{title}</h3>
      <p>{children}</p>
    </article>
  );
}

function titleCase(value) {
  return value.charAt(0).toUpperCase() + value.slice(1);
}
