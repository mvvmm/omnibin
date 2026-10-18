import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";

const SUPPORT_EMAIL = "support@omnib.in";

export default function PrivacyPolicy() {
  return (
    <div className="relative z-10 mx-auto max-w-3xl px-4 py-12 sm:px-6 lg:px-8">
      <Card className="mx-auto w-full p-8 md:p-12">
        <CardHeader className="px-0">
          <CardTitle className="text-3xl">Privacy Policy</CardTitle>
          <CardDescription className="text-base">
            <strong>Last updated:</strong> {new Date().toLocaleDateString()}
          </CardDescription>
        </CardHeader>
        <CardContent className="px-0">
          <div className="space-y-8">
            <section className="space-y-3">
              <h2 className="text-xl font-semibold">1. Introduction</h2>
              <p className="text-sm text-muted-foreground">
                Welcome to omnibin (&quot;we,&quot; &quot;our,&quot; or
                &quot;us&quot;). This Privacy Policy explains how we collect,
                use, disclose, and safeguard your information when you use our
                cross-platform copy/paste application and related services.
              </p>
            </section>

            <section className="space-y-3">
              <h2 className="text-xl font-semibold">
                2. Information We Collect
              </h2>
              <div className="space-y-4">
                <div>
                  <h3 className="text-lg font-medium mb-2">
                    2.1 Content You Share
                  </h3>
                  <p className="text-sm mb-2 text-muted-foreground">
                    We collect the content you choose to share through our
                    application, including:
                  </p>
                  <ul className="list-disc pl-6 text-sm text-muted-foreground">
                    <li>Text content you copy and paste</li>
                    <li>Files you upload and share</li>
                    <li>URLs you share for link previews</li>
                  </ul>
                </div>

                <div>
                  <h3 className="text-lg font-medium mb-2">
                    2.2 Account Information
                  </h3>
                  <p className="text-sm mb-2 text-muted-foreground">
                    When you create an account, we collect:
                  </p>
                  <ul className="list-disc pl-6 text-sm text-muted-foreground">
                    <li>Email address (for authentication)</li>
                    <li>Account preferences and settings</li>
                    <li>Authentication tokens (stored securely)</li>
                  </ul>
                </div>

                <div>
                  <h3 className="text-lg font-medium mb-2">
                    2.3 Usage Information
                  </h3>
                  <p className="text-sm mb-2 text-muted-foreground">
                    We automatically collect certain information about your use
                    of our service:
                  </p>
                  <ul className="list-disc pl-6 text-sm text-muted-foreground">
                    <li>Device information (platform, version)</li>
                    <li>Usage patterns and frequency</li>
                    <li>Error logs and performance data</li>
                  </ul>
                </div>
              </div>
            </section>

            <section className="space-y-3">
              <h2 className="text-xl font-semibold">
                3. How We Use Your Information
              </h2>
              <p className="text-sm mb-2 text-muted-foreground">
                We use the information we collect to:
              </p>
              <ul className="list-disc pl-6 text-sm text-muted-foreground">
                <li>Provide and maintain our copy/paste service</li>
                <li>Sync your content across your devices</li>
                <li>Generate link previews for shared URLs</li>
                <li>Authenticate your account and maintain security</li>
                <li>Improve our application and user experience</li>
                <li>Provide customer support</li>
              </ul>
            </section>

            <section className="space-y-3">
              <h2 className="text-xl font-semibold">4. Information Sharing</h2>
              <p className="text-sm mb-2 text-muted-foreground">
                We do not sell, trade, or otherwise transfer your personal
                information to third parties, except in the following
                circumstances:
              </p>
              <ul className="list-disc pl-6 text-sm text-muted-foreground">
                <li>
                  <strong>Service Providers:</strong> We may share information
                  with trusted third-party services that help us operate our
                  application (e.g., cloud storage, authentication)
                </li>
                <li>
                  <strong>Legal Requirements:</strong> We may disclose
                  information if required by law or to protect our rights and
                  safety
                </li>
                <li>
                  <strong>Consent:</strong> We may share information with your
                  explicit consent
                </li>
              </ul>
            </section>

            <section className="space-y-3">
              <h2 className="text-xl font-semibold">5. Data Security</h2>
              <p className="text-sm mb-2 text-muted-foreground">
                We implement appropriate security measures to protect your
                information:
              </p>
              <ul className="list-disc pl-6 text-sm text-muted-foreground">
                <li>End-to-end encryption for sensitive data</li>
                <li>Secure authentication using industry standards</li>
                <li>Regular security audits and updates</li>
                <li>Access controls and monitoring</li>
              </ul>
            </section>

            <section className="space-y-3">
              <h2 className="text-xl font-semibold">6. Data Retention</h2>
              <p className="text-sm text-muted-foreground">
                We retain your information for as long as necessary to provide
                our services and as required by law. You can delete your account
                and associated data at any time through the application
                settings.
              </p>
            </section>

            <section className="space-y-3">
              <h2 className="text-xl font-semibold">7. Your Rights</h2>
              <p className="text-sm mb-2 text-muted-foreground">
                You have the right to:
              </p>
              <ul className="list-disc pl-6 text-sm text-muted-foreground">
                <li>Access your personal information</li>
                <li>Correct inaccurate information</li>
                <li>Delete your account and data</li>
                <li>Export your data</li>
                <li>Opt out of certain data processing</li>
              </ul>
            </section>

            <section className="space-y-3">
              <h2 className="text-xl font-semibold">8. Third-Party Services</h2>
              <p className="text-sm mb-2 text-muted-foreground">
                Our application may integrate with third-party services for:
              </p>
              <ul className="list-disc pl-6 text-sm text-muted-foreground">
                <li>Authentication (Auth0)</li>
                <li>Cloud storage (Cloudflare)</li>
                <li>Link preview generation</li>
              </ul>
              <p className="text-sm mt-2 text-muted-foreground">
                These services have their own privacy policies, and we encourage
                you to review them.
              </p>
            </section>

            <section className="space-y-3">
              <h2 className="text-xl font-semibold">
                9. Children&apos;s Privacy
              </h2>
              <p className="text-sm text-muted-foreground">
                Our service is not intended for children under 13. We do not
                knowingly collect personal information from children under 13.
              </p>
            </section>

            <section className="space-y-3">
              <h2 className="text-xl font-semibold">
                10. Changes to This Policy
              </h2>
              <p className="text-sm text-muted-foreground">
                We may update this Privacy Policy from time to time. We will
                notify you of any material changes by posting the new Privacy
                Policy on this page and updating the &quot;Last updated&quot;
                date.
              </p>
            </section>

            <section className="space-y-3">
              <h2 className="text-xl font-semibold">11. Contact Us</h2>
              <p className="text-sm mb-2 text-muted-foreground">
                If you have any questions about this Privacy Policy, please
                contact us a{" "}
                <a className="underline" href={`mailto:${SUPPORT_EMAIL}`}>
                  {SUPPORT_EMAIL}
                </a>{" "}
              </p>
            </section>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
