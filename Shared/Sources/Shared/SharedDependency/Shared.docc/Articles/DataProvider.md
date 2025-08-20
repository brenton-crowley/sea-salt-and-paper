# Getting Started with Data Providers

### Purpose of a Data Provider

Simply put, it's a way to control your object's dependencies. 

###### What constitutes a dependency?

It's anything that your object doesn't have control over. An example of this is a `UUID`.

```swift
let id = UUID() // Will generate a random string value that we don't control'
```

And it begs the question, how do we test code like this? Our property is dependent on a `UUID` but we can't verify its values in a test as it will be unique every single time.

It's just one example of not controlling our dependencies. `Date` would be another example.

### How to Control the Dependency

Of course, we probably wouldn't initialise a UUID like this directly in our code. It would be defined and injected through the constructor of a type like that of `User` below.

```swift
struct User {
    let id: UUID

    init(_ id: UUID) {
        self.id = id
    }
}
```

Then we can call User and pass in a controlled UUID:

```swift
let controlledUUID = UUID(uuidString: "deadbeef-dead-beef-dead-beefdeadbeef")
let user = User(id)
```

Of course, we could just store a UUID and pass that into user like the above code. But now we understand the problem in a simplified context, let's control a more complicated dependency.

### How to Control Network Responses

We often want to use variations of responses for live production code and test code. We don't want our tests making live network calls so we often want to simulate the call and end up with some result.

Let's inspect the following method of `URLSession`:

```swift
// Object
URLSession.shared

// Method
func data(for request: URLRequest) async throws -> (Data, URLResponse)

// Call that uses the actual URLSession.shared
let (data, response) = try await URLSession.shared.data(for: ...)
```

- We don't want to call `URLSession.shared` in our tests because that will make a live network call.
- We don't want to mock out the whole `URLSession` object.
- We need to be able to simulate the result of the method without making the call.

##### Creating a UserAPI that Fetches Users

Let's imagine we have the following API for our Users.

```swift
struct UserAPI {
    public func fetchUser(id: Int) async throws -> User {
        // 1. Must make a network call.
        // 2. Map result of network call into a `User`
    }
}
```

If we were to test `fetchUser(id:)`, then we'd need to simulate the network call. To do that, we'll create a Data Provider as an object that stores all the dependencies that we don't control. Such as the URLSession's method we want to use.

```swift
extension UserAPI {
    // Scope the data provider to its object and make it internal
    struct DataProvider: Sendable { // Sendable makes it Swift 6 compliant 
    }

}
```

> Tip: Simulate the minimum functionality you need to get the job done. Sometimes, it's quite a large chunk, but other times, it can be as simple as the method's signature.

For our scenario, we can create a property on the data provider that mimics the signature of the URLSession's method that we want to call. We'll use the method's signature to define a closure property on the data provider.

```swift
// 1. Take the method's signature:
func data(for request: URLRequest) async throws -> (Data, URLResponse)

// 2. Turn it into a closure property.
var data: @Sendable (_ request: URLRequest) async throws -> (Data, URLResponse)
``` 

With a few tweaks, a closure property looks very similar to a function definition. Defining properties in this ways will allow us to easily mock out an expected result. 

> Tip: In Xcode, `alt-click` on the method and then copy/paste the signature of the method into the property of your data provider.

Here's our data provider:

```swift
extension UserAPI {
    struct DataProvider: Sendable {
        var data: @Sendable (_ request: URLRequest) async throws -> (Data, URLResponse)
    }
}
```

What we've done here is define a contract or a template. It will allow us to create different implementations. Let's create a live implementation and a test implementation.

##### Live Implementation

Since we've directly copied the URLSession's signature, then we can supply the method directly to fulfil the contract of the data provider. 

```swift
extension UserAPI.DataProvider { // Extend the data provider
    static var live: Self {
        .init(
            // Supply the method directly
            data: URLSession.shared.data(for:)
        )
    }
}
```

If we wanted to do some manual configuration, then we could also create a custom closure implementation 

```swift
extension UserAPI.DataProvider { // Extend the data provider
    static var liveEphemeralConfig: Self {
        .init(
            data: { request in
                // Use type inference to fulfil the return type requirements.
                try await URLSession(configuration: .ephemeral)
                    .data(for: request)
            }
        )
    }
}
```

##### Test Implementation

Since we've directly copied the URLSession's signature, then we can supply the method directly to fulfil the contract of the data provider. 

```swift
extension UserAPI.DataProvider { // Extend the data provider
    static var test: Self {
        .init(
            data: { request in // Ignore the request
                // Return a tuple with mock values.
                (Data(), URLResponse(url: request.url))
            }
        )
    }
}
```

> Experiment: We could even supply Data() that's JSON encoded into a codable `User` struct, but that's beyond this scope.

#### Use the Data Provider to Mock Dependencies
Let's return to our `UserAPI` and `fetchUser(id:)` method.

```swift
struct UserAPI {
    // 1. Define a data provider property
    let dataProvider: Self.DataProvider

    public func fetchUser(id: Int) async throws -> User {
        // 2. Use the data provider to 'make' a network call.
        let request: URLRequest = .fetchUser // You'd need to create this request but we'll assume it exists.  
        let (data, _) = try await dataProvider.data(request)
        // 3. Decode the data into the Codable User struct.
        return try JSONDecoder.decode(User.self, from: data)
    }
}
```

> Important: Calling `dataProvider.data(request)` is what enables us to switch out different versions of the closure.

We'd create different implementations of `UserAPI` like this:

###### Production Version

```swift
// Using the default configuration
let userAPI = UserAPI(dataProvider: .live)

// Using the ephemeral configuration
let userAPI = UserAPI(dataProvider: .liveEphemeralConfig)
```

###### Test Version

```swift
// Using the default configuration
let userAPI = UserAPI(dataProvider: .test)

// Or create a custom data provider in tests
let userAPI = UserAPI(
    dataProvider: .init(
        data: { request in
            // Custom test implementation for granular control 
        }
    )
)
```

We've now controlled the dependency on URLSession. We have versions we can use in production and versions that we can use in tests.

With this pattern defined in our toolkit, we can apply it to any object's dependencies.

## Key Takeaways
- Mock out a dependency so that you can control its return type.
- Mock out the minimal amount necessary to control that return type.
- Use closures properties on data provider and use the method's signature to help you define the property.

