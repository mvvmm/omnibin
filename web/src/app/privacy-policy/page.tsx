import type { Metadata } from "next";
import {
	Card,
	CardContent,
	CardDescription,
	CardHeader,
	CardTitle,
} from "@/components/ui/card";

export const metadata: Metadata = {
	title: "Privacy Policy",
	description:
		"Privacy Policy for omnibin - cross-platform copy/paste. Learn how we collect, use, and protect your data when using our clipboard sync service.",
};

const SUPPORT_EMAIL = "support@omnib.in";

export default function PrivacyPolicy() {
	return (
		<div className="relative z-10 mx-auto max-w-3xl px-4 py-12 sm:px-6 lg:px-8">
			<Card className="mx-auto w-full p-8 md:p-12 glass">
				<CardHeader className="px-0">
					<CardTitle className="text-3xl">Privacy Policy</CardTitle>
					<CardDescription className="text-base">
						<strong>Last updated:</strong> {new Date().toLocaleDateString()}
					</CardDescription>
				</CardHeader>
				<CardContent className="px-0">
					<div className="space-y-8">
						<section className="space-y-3">
							<h2
								className="text-xl font-semibold"
								style={{ color: "var(--foreground)" }}
							>
								1. Introduction
							</h2>
							<p className="text-sm" style={{ color: "var(--muted-80)" }}>
								Welcome to omnibin ("we," "our," or "us"). This Privacy Policy
								explains how we collect, use, disclose, and safeguard your
								information when you use our cross-platform copy/paste
								application and related services.
							</p>
						</section>

						<section className="space-y-3">
							<h2
								className="text-xl font-semibold"
								style={{ color: "var(--foreground)" }}
							>
								2. Information We Collect
							</h2>
							<div className="space-y-4">
								<div>
									<h3
										className="text-lg font-medium mb-2"
										style={{ color: "var(--foreground)" }}
									>
										2.1 Content You Share
									</h3>
									<p
										className="text-sm mb-2"
										style={{ color: "var(--muted-80)" }}
									>
										We collect the content you choose to share through our
										application, including:
									</p>
									<ul
										className="list-disc pl-6 text-sm"
										style={{ color: "var(--muted-80)" }}
									>
										<li>Text content you copy and paste</li>
										<li>Files you upload and share</li>
										<li>URLs you share for link previews</li>
									</ul>
								</div>

								<div>
									<h3
										className="text-lg font-medium mb-2"
										style={{ color: "var(--foreground)" }}
									>
										2.2 Account Information
									</h3>
									<p
										className="text-sm mb-2"
										style={{ color: "var(--muted-80)" }}
									>
										When you create an account, we collect:
									</p>
									<ul
										className="list-disc pl-6 text-sm"
										style={{ color: "var(--muted-80)" }}
									>
										<li>Email address (for authentication)</li>
										<li>Account preferences and settings</li>
										<li>Authentication tokens (stored securely)</li>
									</ul>
								</div>

								<div>
									<h3
										className="text-lg font-medium mb-2"
										style={{ color: "var(--foreground)" }}
									>
										2.3 Usage Information
									</h3>
									<p
										className="text-sm mb-2"
										style={{ color: "var(--muted-80)" }}
									>
										We automatically collect certain information about your use
										of our service:
									</p>
									<ul
										className="list-disc pl-6 text-sm"
										style={{ color: "var(--muted-80)" }}
									>
										<li>Device information (platform, version)</li>
										<li>Usage patterns and frequency</li>
										<li>Error logs and performance data</li>
									</ul>
								</div>
							</div>
						</section>

						<section className="space-y-3">
							<h2
								className="text-xl font-semibold"
								style={{ color: "var(--foreground)" }}
							>
								3. How We Use Your Information
							</h2>
							<p className="text-sm mb-2" style={{ color: "var(--muted-80)" }}>
								We use the information we collect to:
							</p>
							<ul
								className="list-disc pl-6 text-sm"
								style={{ color: "var(--muted-80)" }}
							>
								<li>Provide and maintain our copy/paste service</li>
								<li>Sync your content across your devices</li>
								<li>Generate link previews for shared URLs</li>
								<li>Authenticate your account and maintain security</li>
								<li>Improve our application and user experience</li>
								<li>Provide customer support</li>
							</ul>
						</section>

						<section className="space-y-3">
							<h2
								className="text-xl font-semibold"
								style={{ color: "var(--foreground)" }}
							>
								4. Information Sharing
							</h2>
							<p className="text-sm mb-2" style={{ color: "var(--muted-80)" }}>
								We do not sell, trade, or otherwise transfer your personal
								information to third parties, except in the following
								circumstances:
							</p>
							<ul
								className="list-disc pl-6 text-sm"
								style={{ color: "var(--muted-80)" }}
							>
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
							<h2
								className="text-xl font-semibold"
								style={{ color: "var(--foreground)" }}
							>
								5. Data Security
							</h2>
							<p className="text-sm mb-2" style={{ color: "var(--muted-80)" }}>
								We implement appropriate security measures to protect your
								information:
							</p>
							<ul
								className="list-disc pl-6 text-sm"
								style={{ color: "var(--muted-80)" }}
							>
								<li>End-to-end encryption for sensitive data</li>
								<li>Secure authentication using industry standards</li>
								<li>Regular security audits and updates</li>
								<li>Access controls and monitoring</li>
							</ul>
						</section>

						<section className="space-y-3">
							<h2
								className="text-xl font-semibold"
								style={{ color: "var(--foreground)" }}
							>
								6. Data Retention
							</h2>
							<p className="text-sm" style={{ color: "var(--muted-80)" }}>
								We retain your information for as long as necessary to provide
								our services and as required by law. You can delete your account
								and associated data at any time through the application
								settings.
							</p>
						</section>

						<section className="space-y-3">
							<h2
								className="text-xl font-semibold"
								style={{ color: "var(--foreground)" }}
							>
								7. Your Rights
							</h2>
							<p className="text-sm mb-2" style={{ color: "var(--muted-80)" }}>
								You have the right to:
							</p>
							<ul
								className="list-disc pl-6 text-sm"
								style={{ color: "var(--muted-80)" }}
							>
								<li>Access your personal information</li>
								<li>Correct inaccurate information</li>
								<li>Delete your account and data</li>
								<li>Export your data</li>
								<li>Opt out of certain data processing</li>
							</ul>
						</section>

						<section className="space-y-3">
							<h2
								className="text-xl font-semibold"
								style={{ color: "var(--foreground)" }}
							>
								8. Third-Party Services
							</h2>
							<p className="text-sm mb-2" style={{ color: "var(--muted-80)" }}>
								Our application may integrate with third-party services for:
							</p>
							<ul
								className="list-disc pl-6 text-sm"
								style={{ color: "var(--muted-80)" }}
							>
								<li>Authentication (Auth0)</li>
								<li>Cloud storage (AWS S3)</li>
								<li>Link preview generation</li>
							</ul>
							<p className="text-sm mt-2" style={{ color: "var(--muted-80)" }}>
								These services have their own privacy policies, and we encourage
								you to review them.
							</p>
						</section>

						<section className="space-y-3">
							<h2
								className="text-xl font-semibold"
								style={{ color: "var(--foreground)" }}
							>
								9. Children's Privacy
							</h2>
							<p className="text-sm" style={{ color: "var(--muted-80)" }}>
								Our service is not intended for children under 13. We do not
								knowingly collect personal information from children under 13.
							</p>
						</section>

						<section className="space-y-3">
							<h2
								className="text-xl font-semibold"
								style={{ color: "var(--foreground)" }}
							>
								10. Changes to This Policy
							</h2>
							<p className="text-sm" style={{ color: "var(--muted-80)" }}>
								We may update this Privacy Policy from time to time. We will
								notify you of any material changes by posting the new Privacy
								Policy on this page and updating the "Last updated" date.
							</p>
						</section>

						<section className="space-y-3">
							<h2
								className="text-xl font-semibold"
								style={{ color: "var(--foreground)" }}
							>
								11. Contact Us
							</h2>
							<p className="text-sm mb-2" style={{ color: "var(--muted-80)" }}>
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
