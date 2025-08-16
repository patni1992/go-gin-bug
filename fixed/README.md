# Fixed Version - Race Condition Solution

This version fixes the race condition bug by adding **thread synchronization**.

## The Problem

**Gin creates goroutines automatically** - each HTTP request runs in its own goroutine:

```
Request 1 → Goroutine A → postAlbums()
Request 2 → Goroutine B → postAlbums()  ← Running simultaneously!
Request 3 → Goroutine C → postAlbums()
```

Multiple goroutines were modifying the `albums` slice simultaneously:

```go
albums = append(albums, newAlbum)  // UNSAFE!
```

## The Solution: Mutex

A **mutex** (mutual exclusion) is like a digital lock - only one goroutine can access the protected data at a time. Others are **queued** and wait their turn.

```
Goroutine A: Lock() → modifies albums → Unlock()
Goroutine B: Lock() → ⏳ WAITS... → gets lock → modifies albums → Unlock()
Goroutine C: Lock() → ⏳ WAITS... → ⏳ WAITS... → gets lock → modifies albums → Unlock()
```

**Think of it like a coffee shop queue** - everyone waits in line, the barista serves one customer at a time. No requests are lost, they just take turns!

### What We Added

1. **Import sync package:**

   ```go
   import "sync"
   ```

2. **Create a mutex:**

   ```go
   var albumsMutex sync.RWMutex
   ```

3. **Lock before writing:**

   ```go
   albumsMutex.Lock()
   albums = append(albums, newAlbum)
   albumsMutex.Unlock()
   ```

4. **Lock before reading:**
   ```go
   albumsMutex.RLock()
   defer albumsMutex.RUnlock()
   // ... read albums safely
   ```

## Why RWMutex?

- **RLock()** - Multiple goroutines can read at the same time
- **Lock()** - Only one goroutine can write at a time
- **Better performance** than regular mutex for read-heavy workloads

## Simple Analogy

Think of the albums slice like a shared notebook:

- **Without mutex:** Everyone writes in the notebook at once → messy, lost data
- **With mutex:** Only one person can write at a time → clean, no data loss
- **RWMutex:** Multiple people can read simultaneously, but writing requires exclusive access

## Test the Fix

```bash
go run fixed/main.go
./test.sh
```

Result: `LOST: 0` every time! 🎉
