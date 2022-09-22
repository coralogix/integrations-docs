package main

import (
	"math/rand"
	"testing"
	"time"
)

const SECOND_IN_NS = 1_000_000_000

func randomTime() time.Time {
  rand.Seed(time.Now().UnixNano())
  timeFrom := time.Date(1970, time.January, 1, 0, 0, 0, 0, time.UTC).UnixNano()
  timeTo := time.Now().UnixNano()
  timeDiff := timeTo - timeFrom
  timeRand := rand.Int63n(timeDiff) + timeFrom
  seconds, nanoseconds := timeRand / SECOND_IN_NS, timeRand % SECOND_IN_NS

  return time.Unix(seconds, nanoseconds)
}

func BenchmarkParseTimestamp(b *testing.B) {
  for i := 0; i < b.N; i++ {
    parseTimestamp(randomTime().Format(time.RFC3339Nano))
  }
}
