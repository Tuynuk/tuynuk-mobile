![alt text](https://lokdon.com/wp-content/uploads/2021/09/Subtitle_01-2.jpg)

# Tuynuk

## Overview

Tuynuk is a mobile application designed for secure, temporary file transfer. With this
app, users can send and receive encrypted files within disposable sessions, ensuring that their data
remains private and is not stored long-term. Built using Flutter and Dart, the app leverages
advanced cryptographic techniques to provide robust security features, making it ideal for users who
need a secure and ephemeral file transfer solution.

## Features

- **Disposable Sessions**: Create temporary file transfer sessions that automatically expire after a
  certain period, ensuring no long-term data retention.
- **End-to-End Encryption (E2EE)**: Secure files with AES encryption and elliptic curve
  cryptography, guaranteeing that only the intended recipient can access them.
- **Asynchronous Operations**: Use Dart isolates to handle encryption and decryption tasks in the
  background, providing a smooth user experience.
- **Automatic Key Management**: Generate and manage encryption keys for each session automatically,
  simplifying the user experience while maintaining security.
- **User-Friendly Interface**: Enjoy a simple and intuitive interface designed for quick and easy
  secure file transfer.

## Screenshots

![Screenshot 1](https://github.com/xaldarof/tuynuk/blob/main/assets/images/logo_dark.png)

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/xaldarof/tuynuk.git

2. Get dependencies:
   ```bash
   flutter pub get

3. Run the application:
   ```bash
   flutter run

## Usage

### Creating a Disposable Session

1. Open the app and tap the "New Session" button.
2. Select a contact to start a new file transfer session.
3. Transfer files securely within the session. All files will be encrypted and only accessible
   within this session.

### Sending and Receiving Files

1. Within an active session, select the file you wish to send.
2. The file will be encrypted and sent to the recipient.
3. The recipient can then decrypt and access the file within the session.

### Session Expiry

1. Sessions are designed to expire after a predefined period.
2. Once a session expires, all files within the session will be permanently deleted, ensuring no
   residual data remains.

## Technical Details

### AES Encryption and Decryption

The app uses AES encryption in CBC mode with PKCS7 padding for secure file encryption. Encryption
and decryption can be handled asynchronously using Dart isolates for optimal performance.

### Elliptic Curve Cryptography

Tuynuk utilizes elliptic curve cryptography (ECC) for secure key exchanges and session
key generation, ensuring that all cryptographic operations adhere to industry standards.

### Secure Random Number Generation

The app employs a cryptographically secure random number generator to create encryption keys and
initialization vectors, providing high security for all cryptographic processes.

### Key Management

The app automatically handles key generation and management for each session, making it easy for
users to focus on file transfer without worrying about cryptographic details.

## Contributing

We welcome contributions to Tuynuk! Please submit pull requests and open issues to help
improve the application.

