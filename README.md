<!--
  README.md for VaporRateLimiter
  https://github.com/<your-github>/VaporRateLimiter
-->

# VaporRateLimiter

![Swift](https://img.shields.io/badge/swift-5.9-orange?style=flat-square)
![Vapor](https://img.shields.io/badge/vapor-4.x-green?style=flat-square)
![Postgres](https://img.shields.io/badge/postgres-required-blue?style=flat-square)

> **A Vapor middleware that protects your application from brute-force attacks.**
> Easy to integrate, configurable, and powered by Fluent/Postgres for secure login attempt tracking.

---

## 🚀 Features

- Limits the number of login attempts per IP or email
- Configurable exponential penalty after repeated failures
- Logs all suspicious activities and lockouts
- Easy integration into any existing Vapor project

---

## 📦 Installation

Add this package to your `Package.swift` dependencies:

```swift
.package(url: "https://github.com/<your-github>/VaporRateLimiter.git", from: "1.0.0")
```

And add `"VaporRateLimiter"` to your target dependencies.

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
            
