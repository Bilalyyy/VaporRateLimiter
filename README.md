<!--
  README.md for VaporRateLimiter
  https://github.com/<your-github>/VaporRateLimiter
-->

# VaporRateLimiter

<p align="center">
  <img src="https://app-soon.com/wp-content/uploads/2025/07/VaporRateLimiter_Logo-2_516.png" alt="VaporRateLimiter logo" width="180">
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

This documentation assumes you already have an existing Vapor project.

- You have added **Fluent** as a dependency and are using a **Postgres** database.

If you do not have this setup, please follow the [official Vapor getting started documentation](https://docs.vapor.codes/getting-started/hello-world/).

You may also need a `User` model that conforms to the `ModelAuthenticable` protocol to enable authentication features.
If you need to implement this, refer to the [official Vapor authentication documentation](https://docs.vapor.codes/security/authentication/#model-authenticatable).

---

## 📦 Installation

Add this package to your `Package.swift` dependencies:

```swift
.package(url: "https://github.com/Bilalyyy/VaporRateLimiter", from: "1.0.0")
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

By default, the threshold for failed attempts before applying the exponential penalty is set to five.
This means a user can make up to five incorrect login attempts before being subject to a penalty (a waiting period during which further login attempts are blocked).
You can customize this value to fit your security needs:

```swift
let limitedRoutes = routes.grouped(RateLimiter(threshold: Int))
```

#### 💡 How does VaporRateLimiter work?

VaporRateLimiter is a middleware that intercepts incoming requests on the routes where it is applied **before** they reach your route handlers.  
When a request is intercepted, the middleware attempts to record an entry in the database to track attempts from the sender.  
To do this, it uses a unique key to identify the sender—by default, this key is the user's email address (the value associated with the `"mail"` field in your request data).

**Important:**  
If the middleware does not find a value for the expected key, it cannot register a new entry and the process will fail.  
Make sure you are using the correct key for your use case.

If you want to track attempts using a different identifier (for example, an API key or username), you can customize the key as follows:

```swift
    // Make sure you use the key used in your request
let limitedRoutes = routes.grouped(RateLimiter(keyToRegister: "apiKey"))
```
This flexibility allows you to adapt VaporRateLimiter to a variety of use cases—whether you’re protecting login endpoints, API access, or any other sensitive route.

---

> ⚠️ **Note:** For safety and convenience, the rate limiter middleware is disabled in the development environment.

---

> ⚠️ **Note:** Do not confuse the key intercepted from the request by VaporRateLimiter (for example, `"mail"` or `"apiKey"`) with the database field where the value is stored.  
> The key you specify in the middleware (`keyToRegister`) can be changed to suit your needs,  
> but the field used in the database is always the same: `key_id` (in the `ConnexionAttempt` model).

---

### Final Step: Clearing login attempts after successful authentication

To prevent your users from being locked out for hours due to old, accumulated failed attempts,
it’s important to clear their login attempts after a successful authentication.

This is usually done in your `loginHandler` function.
Make sure to add the following line **after a successful login**:

```swift
private func loginHandler(_ req: Request) async throws -> HTTPStatus {
    // ... authentication logic ...
    // ... After the user is authenticated
    try await req.connexionAttempsSvc.userIsLoged(user.mail)
    // ...
}
```

---

## ✍️ Contributing

For contribution guidelines, see [CONTRIBUTING](CONTRIBUTING.md).

---

## ✉️ Contact

Feel free to open an [issue](../../issues) or contact me by [email](mailto:contact@app-soon.com).
You can also find me on [Linkedin](https://www.linkedin.com/in/gregory-larose-developpeur).

---

## 📋 License

MIT © [Bilalyyy](https://github.com/Bilalyyy)
            
