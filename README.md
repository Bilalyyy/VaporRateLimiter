<!--
  README.md for VaporRateLimiter
  https://github.com/<your-github>/VaporRateLimiter
-->

<p align="center">
  <img src="https://app-soon.com/wp-content/uploads/2025/07/RateLimiter-2.png" alt="VaporRateLimiter logo" width="180">
</p>

# VaporRateLimiter

![Swift](https://img.shields.io/badge/swift-5.9+-orange?style=flat-square)
![Vapor](https://img.shields.io/badge/vapor-4.x-green?style=flat-square)
![Fluent](https://img.shields.io/badge/fluent-required-yellow?style=flat-square)
![Postgres](https://img.shields.io/badge/postgres-required-blue?style=flat-square)


> A Vapor middleware that effectively protects your application against brute-force attacks.
> Easy and fast to integrate. Optimized with Fluent for seamless Postgres support.
> Also provides login attempt tracking.

---

## 🚀 Features

- Limits the number of login attempts per IP and email
- Exponential penalty after repeated failures
- Logs all suspicious activities and lockouts
- Easy integration into any existing Vapor project

---
## Prerequisites

This package assumes you already have an existing Vapor project.

- You have added **Fluent** as a dependency, and you are using a **Postgres** database.
- Your application uses an authentication system based on **sessions** (with Vapor's authentication API).
- You have a `User` model conforming to the `ModelAuthenticatable` protocol.

If you do not have this setup, please follow the [official Vapor authentication documentation](https://docs.vapor.codes/security/authentication/#session).

---

## 📦 Installation

Add this package to your `Package.swift` dependencies:

```swift
    .package(url: "https://github.com/Bilalyyy/VaporRateLimiter", from: "0.0.5")
```

And add `"VaporRateLimiter"` to your target dependencies.

```swift
    .product(name: "VaporRateLimiter", package: "VaporRateLimiter")
```

---

## 🛠️ Usage

Import the package in your file:

```swift
import VaporRateLimiter
```

Register the middleware in your `configure.swift`:

```swift
app.middleware.use(RateLimiterMiddleware())
```

Configure the rate limiter as needed (see documentation for advanced configuration).

---

## ⚙️ Configuration

You can customize:

- Maximum attempts per time window
- Lockout duration and penalty escalation
- Tracking by IP, email, or custom keys
- Logging and notification hooks

Example:

```swift
let limiter = RateLimiterMiddleware(
    maxAttempts: 5,
    window: .minutes(10),
    penalty: .exponential(base: 60, factor: 2)
)
app.middleware.use(limiter)
```

---

## 🗄️ Database

This package relies on Fluent/Postgres for persistent tracking.
Ensure you have a working Postgres database and run the included migration:

```swift
app.migrations.add(RateLimiterMigration())
```

---

## 📋 License

MIT © [<your-github>](https://github.com/<your-github>)
            
