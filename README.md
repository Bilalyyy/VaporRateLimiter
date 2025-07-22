<!--
  README.md for VaporRateLimiter
  https://github.com/<your-github>/VaporRateLimiter
-->

# VaporRateLimiter

<p align="center">
  <img src="https://app-soon.com/wp-content/uploads/2025/07/RateLimiter-2.png" alt="VaporRateLimiter logo" width="180">
</p>


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
- Gentle with legitimate users who make mistakes, relentless with attackers
- Exponential penalty increases after each set of 5 consecutive failed attempts (60, 120, 240, 480... seconds)
- Effectively protects against brute-force attacks, even when facing advanced techniques such as massive, concurrent (parallel) request attempts.
- Logs all suspicious activities and lockouts
- Easy integration into any existing Vapor project

---
## Prerequisites

This package assumes you already have an existing Vapor project.

- You have added **Fluent** as a dependency and are using a **Postgres** database.

If you do not have this setup, please follow the [official Vapor getting started documentation](https://docs.vapor.codes/getting-started/hello-world/).

You will also need a `User` model conforming to the `ModelAuthenticatable` protocol to enable authentication features.

If you need to implement this, refer to the [official Vapor authentication documentation](https://docs.vapor.codes/security/authentication/#model-authenticatable).

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

Apply the `RateLimiter` middleware to your login route to enable brute-force protection.
For example:

```swift
import Vapor
import VaporRateLimiter

struct AuthController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let routes = routes.grouped("api", "v1", "auth")
        // ...

        let limitedRoutes = routes.grouped(RateLimiter())
        limitedRoutes.post("login", use: loginHandler)
        // ...
    }
}
```

### Final Step: Clearing login attempts after successful authentication

To prevent your users from being locked out for hours due to old, accumulated failed attempts,
it’s important to clear their login attempts after a successful authentication.

This is usually done in your `loginHandler` function.
Make sure to add the following line **after a successful login**:

```swift
private func loginHandler(_ req: Request) async throws -> HTTPStatus {
    // ... authentication logic ...
    try await req.connexionAttempsSvc.userIsLoged(user.mail, req.logger)
    // ...
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
            
