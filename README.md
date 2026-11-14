# Find Job

Flutter job-search application using Firebase Authentication, Cloud Firestore,
and Firebase Storage. Existing Firebase initialization, login, registration,
profile editing, CV upload, and the six-tab navigation remain in place.

## Account entry

The authenticated session is routed using the existing Firestore identity
documents: `companies/{uid}` opens the company account, `institutions/{uid}`
opens the institution account, and candidate sessions retain the existing
candidate flow. Company and institution administration are kept separate from
candidate profiles and from each other. Company registration uses its own
Firebase Authentication email/password credentials, followed by the company
profile form.

## Recruitment data

- `users/{uid}` stores the private candidate profile.
- `companies/{uid}` stores the single company administered by that account.
  The document ID and `ownerUid` are the Firebase Authentication UID.
- `jobs/{jobId}` stores job postings, the owning UID, and a company ID. Public
  company contact fields are copied into each posting so job details can be
  read without exposing private company documents.

The Employment tab streams only jobs with `status == "published"` and hides
postings outside their publication/deadline dates. Company administration
streams jobs by `ownerUid`. Postings persist the designed work location,
profile/document requirements, skills, salary privacy, benefits, dates,
vacancy count, application channel, and contact details. Text matching and combinable filters
run on the currently streamed published jobs on-device; this supports the
current scale but is not a full-text search service. Larger datasets should
use a dedicated search index or add structured Firestore queries and indexes.
City, area, modality, employment type, experience, salary, and posting age
filters are currently applied locally.

## Institutional courses

- `institutions/{uid}` stores one institution request/profile per Firebase
  Authentication UID. It includes the legal and public names, institution type,
  tax/accreditation details, location, official domains, representative and
  administrator contact, requested 2FA flag, and `verificationStatus`.
- `courses/{courseId}` stores a course with a generated document ID,
  `ownerUid`, institution name/location, program details, requirements, price,
  dates, admissions contacts, optional brochure URL, and `status`
  (`draft`, `published`, or `retired`).
- Institution users can read their own institution record and manage their
  own drafts. The Courses catalog reads published, currently open courses only.
  A course may be published or retired only when its owner has the trusted
  `institution: true` custom claim and the institution record is marked
  `verified`.
- Brochures are stored under
  `institutions/{uid}/courses/{courseId}/brochure.pdf`; access is restricted to
  the owning authenticated account.

The repository does not include a trusted domain-verification service or a
Firebase Functions backend. Consequently, a new institution remains pending
and can save drafts, but cannot publish or retire a course until an authorized
backend verifies its domain, sets `verificationStatus` to `verified`, and
issues the custom claim. The client never grants itself that role. The
registration form's 2FA field records a request; it does not configure a
second factor in Firebase Authentication.

The institutional sign-in flow likewise uses Firebase email/password
authentication. Institutional domain SSO and one-time 2FA-code verification
are not configured in this client and are not represented as working
authentication methods.

`firestore.rules` contains the intended access controls. Deploying the local
rules to the Firebase project is still a manual Firebase CLI/Console operation;
changing this file alone does not publish rules. No Firebase credentials or
admin keys belong in the client application.

Run the checks with `flutter analyze`, `flutter test`, and `flutter build web`.
