import Link from "next/link";

export function SiteHeader() {
  return (
    <header className="topbar">
      <div className="site-shell topbar-inner">
        <Link className="brand" href="/" aria-label="Delts home">
          <img src="/assets/app-icon-lime.png" alt="" />
          <span>Delts</span>
        </Link>
        <nav className="nav-links" aria-label="Primary">
          <Link href="/#features">Features</Link>
          <Link href="/#product">Product</Link>
          <Link href="/#privacy">Privacy</Link>
          <Link href="/privacy">Privacy Policy</Link>
          <Link href="/terms">Terms</Link>
        </nav>
      </div>
    </header>
  );
}

export function SiteFooter() {
  return (
    <footer className="footer">
      <div className="site-shell footer-inner">
        <span>&copy; 2026 Delts.</span>
        <span>
          <Link href="/privacy">Privacy</Link> / <Link href="/terms">Terms</Link>
        </span>
      </div>
    </footer>
  );
}

export function Eyebrow({ children }) {
  return <span className="eyebrow">{children}</span>;
}

export function PageShell({ children }) {
  return (
    <>
      <SiteHeader />
      {children}
      <SiteFooter />
    </>
  );
}
