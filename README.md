# goalsync

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Payment & Monetization Architecture

Pennora implements a modular payment gateway abstraction with support for:
- Demo Payment Gateway (for development, testing, and judge demonstrations)
- Razorpay Test / Live Gateway Adapter
- Cryptographic Webhook verification (HMAC-SHA256)
- Strict webhook idempotency (replayed events do not produce duplicate payments, subscriptions, or revenue events)
- Entitlement gating via backend JWT claims and database subscription verification

> [!IMPORTANT]
> If Pennora is published on Google Play, verify the current Google Play billing requirements for digital subscriptions before enabling external gateway checkout in the production store build.

