# Race Condition Demo

This project demonstrates a **race condition bug** found in the Go web service tutorial and shows how to fix it.

**Based on:** [Tutorial: Developing a RESTful API with Go and Gin](https://go.dev/doc/tutorial/web-service-gin)
**Video walkthrough:** [Youtube video](https://www.youtube.com/watch?v=5diIXJ5HQGU)

## Project Structure

```
├── main.go              # ❌ Buggy version with race condition
├── fixed/main.go        # ✅ Fixed version with proper synchronization
├── test.sh       # Test script to trigger the race condition
└── README.md           # This file
```

## The Bug

**Location:** `main.go` line 49

```go
albums = append(albums, newAlbum)  // UNSAFE!
```

When multiple HTTP requests hit the server simultaneously, Gin creates separate goroutines for each request. These goroutines all try to modify the `albums` slice at the same time, causing data loss.

## Why This Code is Unsafe

**Most operations in Go are not thread-safe by default**. This is by design - Go prioritizes performance and lets developers choose their synchronization strategy explicitly rather than adding overhead to every operation.

### The Race Condition

When multiple goroutines execute `albums = append(albums, newAlbum)` simultaneously, they can interfere with each other's operations, causing data loss or corruption.

### Why Reads Are Also Unsafe

Even simple reads can be dangerous during writes:

```go
// Reading while append is reallocating
func getAlbums(c *gin.Context) {
    c.IndentedJSON(http.StatusOK, albums) // Might read from freed memory!
}
```

**The slice header contains three values** (pointer, length, capacity). If a read happens while these are being updated, you get inconsistent data or crashes.

### Other Unsafe Operations

This same problem exists with many Go operations:

```go
// Map operations - NOT thread-safe
userSessions["user123"] = session     // Race condition!
delete(userSessions, "user456")       // Race condition!

// Slice modifications - NOT thread-safe
items[0] = newValue                   // Race condition!
items = items[:len(items)-1]          // Race condition!

// Even simple assignments - NOT thread-safe for complex types
config = newConfig                    // Race condition if config is a struct!
```

**Go's philosophy**: Concurrency safety is explicit, not implicit. You must choose your synchronization method.

## Testing the Bug

The test script sends 500 concurrent requests and compares expected vs actual album count:

### How the Test Works

The script runs 20 parallel `hey` processes, each sending 25 requests simultaneously:

```bash
for i in {1..20}; do
    hey -n 25 -c 25 ...  # 25 requests with 25 concurrent connections
done
```

- **`-n 25`** = Total requests per process (25)
- **`-c 25`** = Concurrent workers per process (25)  
- **20 processes** = 20 × 25 = 500 total requests
- **Multiple processes** create more timing chaos than one process with 500 connections

**Tools needed:**

- `curl` (built-in) - Makes HTTP requests
- `hey` (`brew install hey`) - Load testing tool
- `jq` (`brew install jq`) - JSON processor

**Run the test:**

```bash
# Test the buggy version
go run main.go
./test.sh

# Test the fixed version
go run fixed/main.go
./test.sh
```

**Windows users:** Use [WSL (Windows Subsystem for Linux)](https://docs.microsoft.com/en-us/windows/wsl/install) to run the bash test script.

## Expected Results

**Buggy version:**

```
EXPECTED: 503
ACTUAL:   501
LOST:     2
🎯 RACE CONDITION TRIGGERED
```

_Note: Results may vary - race conditions are non-deterministic. Sometimes you might see 0 lost albums, other times more than 2._

**Fixed version:**

```
EXPECTED: 503
ACTUAL:   503
LOST:     0
❌ No race condition
```

## The Solution

The fixed version (`fixed/main.go`) uses a **mutex** to synchronize access:

```go
var albumsMutex sync.RWMutex

func postAlbums(c *gin.Context) {
    // ... validation code ...

    albumsMutex.Lock()
    albums = append(albums, newAlbum)
    albumsMutex.Unlock()

    c.IndentedJSON(http.StatusCreated, newAlbum)
}
```

**See `fixed/README.md` for detailed explanation of the fix.**
