# Super Simple Authentication Toolkit

A collection of Dart Frog functions that power the super_simple_authentication_server

## Features

- Dart Frog Handlers to handle authentication requests
- Connect to database via DataStorage interface
- Send emails and sms via external providers
- Integration with Google and Apple social sign ins
- Asymmetric and symmetric tokens

## Handlers

The `super_simple_authentication_toolkit` provides a set of Dart Frog handlers to manage various authentication flows:

- **`createAccountHandler()`**: Handles user registration with email and password. It takes an email and password from the request, hashes the password, creates a new user in the configured `DataStorage`, and issues a new JWT and refresh token.
- **`refreshTokenHandler()`**: Manages the refreshing of access tokens. It expects a refresh token in the request, revokes the old refresh token, updates the associated session, and then issues a new JWT and a new refresh token.
- **`sendOtpHandler({String fromEmail, String fromName, String? emailSubject, bool debugOtps})`**: Sends a One-Time Password (OTP) to a user via email or phone. It uses the `DataStorage` to store the hashed OTP and integrates with configured email (`Sendgrid`) or SMS (`SmsProvider`) providers. The `debugOtps` parameter can be used to print OTPs to the console for testing purposes.
- **`signInAnonymouslyHandler()`**: Allows users to sign in without providing any credentials. It creates a new anonymous user in `DataStorage` and issues a JWT and refresh token.
- **`signInWithCredentialHandler()`**: Facilitates third-party sign-in using credentials from providers like Google or Apple. It verifies the provided credential, retrieves or creates a user in `DataStorage`, and issues a JWT and refresh token.
- **`signInWithEmailPasswordHandler()`**: Handles user login with an email and password. It verifies the credentials against the stored user data in `DataStorage` and, upon successful verification, issues a JWT and refresh token.
- **`verifyOtpHandler({Future<void> Function({required String userId, String? email, String? phoneNumber})? onNewUser})`**: Verifies an OTP submitted by the user. If the OTP is valid, it revokes the OTP, either creates a new user or identifies an existing one based on the identifier, and issues a JWT and refresh token. An optional `onNewUser` callback can be provided to execute logic when a new user is created.

## Data Storage

The toolkit defines a `DataStorage` interface, which abstracts the underlying data persistence layer. This allows for flexible integration with different databases or storage solutions.

- **`DataStorage` (abstract class)**: Defines the contract for all data storage operations, including creating/retrieving users, sessions, refresh tokens, and OTPs.
- **`InMemoryDataStorage`**: A provided in-memory implementation of the `DataStorage` interface. This is useful for development, testing, and simple deployments where data persistence across restarts is not critical.

## 3rd Party Integrations

The toolkit offers integrations with various third-party services for sending emails, SMS, and handling social logins:

### Email

- **`Sendgrid({required String apiKey, required String baseUrl})`**: A client for sending emails via the Sendgrid API. It requires a Sendgrid API key and the base URL for the Sendgrid API.

### SMS

- **`SmsProvider` (abstract class)**: An interface defining methods for sending SMS messages.
- **`Textbelt({required String apiKey})`**: An implementation of `SmsProvider` that uses the Textbelt API to send SMS messages. It requires a Textbelt API key.
- **`Twilio({required String accountSid, required String authenticationToken, required String messagingServiceSid})`**: An implementation of `SmsProvider` that uses the Twilio API to send SMS messages. It requires Twilio account SID, authentication token, and messaging service SID.

### Social Sign-In

- **`SignInWithApple({required String bundleId, String? serviceId})`**: A utility for verifying Apple ID tokens. It requires the iOS/macOS bundle ID and optionally a service ID for web/Android sign-in.
- **`SignInWithGoogle({required String clientId})`**: A utility for verifying Google ID tokens. It requires the Google client ID.
