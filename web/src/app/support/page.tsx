import type { Metadata } from "next";
import Link from "next/link";
import { Button } from "@/components/ui/button";
import {
	Card,
	CardContent,
	CardDescription,
	CardHeader,
	CardTitle,
} from "@/components/ui/card";

export const metadata: Metadata = {
	title: "Support",
	description:
		"Get help with omnibin. Report bugs, request features, or contact support for assistance with your cross-platform clipboard.",
};

const BUG_GITHUB_URL =
	"https://github.com/mvvmm/omnibin/issues/new?template=bug_report.yml";
const FEATURE_GITHUB_URL =
	"https://github.com/mvvmm/omnibin/issues/new?template=feature_request.yml";
const SUPPORT_EMAIL = "support@omnib.in";

function buildMailtoHref(subject: string, body: string) {
	// Mailto URIs (RFC 6068) require percent-encoding; '+' is not a space.
	// Convert newlines to CRLF for best client compatibility before encoding.
	const encodedSubject = encodeURIComponent(subject);
	const encodedBody = encodeURIComponent(body.replace(/\n/g, "\r\n"));
	return `mailto:${SUPPORT_EMAIL}?subject=${encodedSubject}&body=${encodedBody}`;
}

const BUG_EMAIL_SUBJECT = "[Bug] REPLACE WITH SHORT SUMMARY";
const BUG_EMAIL_BODY = [
	"Thanks for filing a bug for omnibin!",
	"",
	"Short summary:",
	"",
	"Overview of the issue:",
	"",
	"How would you like to see this fixed?:",
	"",
	"Item type: (Text / Image / File / Other)",
	"Character length (if text):",
	"File size (if image/file):",
	"File attachment (if file):",
	"",
	"Where was the item pasted? (source):",
	"Where is it being copied to? (destination):",
	"",
	"Steps to reproduce:",
	"1.",
	"2.",
	"3.",
	"",
	"Expected behavior:",
	"",
	"Actual behavior:",
	"",
	"Screenshots / recordings (optional):",
	"",
	"Additional context:",
].join("\n");

const FEATURE_EMAIL_SUBJECT = "[Feature] REPLACE WITH SHORT SUMMARY";
const FEATURE_EMAIL_BODY = [
	"Thanks for suggesting a feature for omnibin!",
	"",
	"What would you like to see implemented/supported in omnibin?:",
	"",
	"Use case / user story (Why is this useful? Who benefits?):",
	"",
	"Possible approach or details (optional):",
	"",
	"Alternatives considered (optional):",
	"",
	"Additional context (optional):",
].join("\n");

export default function SupportPage() {
	const bugMailto = buildMailtoHref(BUG_EMAIL_SUBJECT, BUG_EMAIL_BODY);
	const featureMailto = buildMailtoHref(
		FEATURE_EMAIL_SUBJECT,
		FEATURE_EMAIL_BODY,
	);

	return (
		<div className="relative z-10 mx-auto max-w-3xl px-4 py-12 sm:px-6 lg:px-8">
			<Card
				className="mx-auto w-full p-8 md:p-12"
				style={{
					backgroundColor: "var(--card-bg)",
					borderColor: "var(--border)",
				}}
			>
				<CardHeader className="px-0">
					<CardTitle className="text-3xl">Support</CardTitle>
					<CardDescription className="text-base">
						Need help or want to report a bug?
					</CardDescription>
				</CardHeader>
				<CardContent className="px-0">
					<div className="space-y-8">
						<section className="space-y-3">
							<h2
								className="text-xl font-semibold"
								style={{ color: "var(--foreground)" }}
							>
								Report a bug
							</h2>
							<p className="text-sm" style={{ color: "var(--muted-80)" }}>
								Open a bug report issue on GitHub or send an email.
							</p>
							<div className="flex flex-col gap-3 sm:flex-row">
								<Button asChild variant="default">
									<Link
										href={BUG_GITHUB_URL}
										target="_blank"
										rel="noopener noreferrer"
										className="bg-gradient-to-r from-omnibin-primary to-omnibin-secondary text-white"
									>
										Github Issue
									</Link>
								</Button>
								<Button asChild variant="secondary">
									<a href={bugMailto}>Email Template</a>
								</Button>
							</div>
						</section>

						<section className="space-y-3">
							<h2
								className="text-xl font-semibold"
								style={{ color: "var(--foreground)" }}
							>
								Request a feature
							</h2>
							<p className="text-sm" style={{ color: "var(--muted-80)" }}>
								Open a feature request issue on GitHub or email.
							</p>
							<div className="flex flex-col gap-3 sm:flex-row">
								<Button
									asChild
									className="bg-gradient-to-r from-omnibin-primary to-omnibin-secondary text-white"
								>
									<Link
										href={FEATURE_GITHUB_URL}
										target="_blank"
										rel="noopener noreferrer"
									>
										Github Issue
									</Link>
								</Button>
								<Button asChild variant="secondary">
									<a href={featureMailto}>Email Template</a>
								</Button>
							</div>
						</section>

						<section className="space-y-3">
							<h2
								className="text-xl font-semibold"
								style={{ color: "var(--foreground)" }}
							>
								Anything else
							</h2>
							<p className="text-sm" style={{ color: "var(--muted-80)" }}>
								You can always email{" "}
								<a className="underline" href={`mailto:${SUPPORT_EMAIL}`}>
									{SUPPORT_EMAIL}
								</a>{" "}
								with any questions, feedback, or support needs.
							</p>
						</section>
					</div>
				</CardContent>
			</Card>
		</div>
	);
}
