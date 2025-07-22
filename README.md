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

## ⚙️ Configuration

**Before configuring the rate limiter, make sure you are using session-based authentication and have added the session model migration.**
Your `configure.swift` file should contain something similar to:

```swift

//...
app.sessions.use(.fluent)

app.sessions.configuration.cookieName = "your-cookie-name-session"
app.sessions.configuration.cookieFactory = { sessionID in
    .init(
        string: sessionID.string,
        expires: Date().addingTimeInterval(60 * 60 * 24 * 30), // 30 days
        isSecure: true
    )
}

app.middleware.use(app.sessions.middleware)

// Session-based authentication
app.middleware.use(User.sessionAuthenticator())

app.migrations.add(SessionRecord.migration)
//...

```

### Step 1: Add the ConnexionAttempt model migration

To work properly, VaporRateLimiter requires a new model in your database to track login attempts.
This means you need to run a migration.
Make sure to add `CreateConnexionAttempt()` to your migration list.
For example, in your `configure.swift` file:

```swift

import VaporRateLimiter
//...

public func configure(_ app: Application) async throws {

    //...

    app.migrations.add(CreateConnexionAttempt())
    //...
}
```

### Step 2: Protect your login endpoint with the middleware

Apply the `RateLimit` middleware to your login route to enable brute-force protection.
For example:

```swift
import Vapor
import VaporRateLimiter

struct AuthController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let routes = routes.grouped("api", "v1", "auth")
        // ...

        let limitedRoutes = routes.grouped(RateLimit())
        limitedRoutes.post("login", use: loginHandler)
        // ...
    }
}
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

## 🗄️ Database

This package relies on Fluent/Postgres for persistent tracking.
Ensure you have a working Postgres database and run the included migration:

```swift
app.migrations.add(RateLimiterMigration())
```

---

## 📋 License

MIT © [<your-github>](https://github.com/<your-github>)
            
