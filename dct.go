package main

import (
	"fmt"
	"math"
	"math/rand"
	"time"
)

func main() {
	sz := 256
	array2d := make([][]float64, sz)
	for x := 0; x < sz; x++ {
		array2d[x] = make([]float64, sz)
		for y := 0; y < sz; y++ {
			array2d[x][y] = rand.Float64()*256
		}
	}

	startTime := time.Now()
	result := dct2d(array2d)
	fmt.Printf("Time: %.3f\n", time.Since(startTime).Seconds())
	_ = result[0][0]
}

func dct2d(array2d [][]float64) [][]float64 {
	sz := len(array2d)
	coef := dctCoef(sz)
	temp := make([][]float64, sz)
	result := make([][]float64, sz)

	for x := 0; x < sz; x++ {
		temp[x] = make([]float64, sz)
		for i := 0; i < sz; i++ {
			var sum float64
			for j := 0; j < sz; j++ {
				sum += array2d[x][j] * coef[j][i]
			}
			temp[x][i] = sum
		}
	}

	for y := 0; y < sz; y++ {
		result[y] = make([]float64, sz)
		for i := 0; i < sz; i++ {
			var sum float64
			for j := 0; j < sz; j++ {
				sum += temp[j][y] * coef[j][i]
			}
			result[y][i] = sum
		}
	}

	return result
}

func dctCoef(sz int) [][]float64 {
	fact := math.Pi / float64(sz)
	coef := make([][]float64, sz)

	for i := 0; i < sz; i++ {
		mult := float64(i) * fact
		coef[i] = make([]float64, sz)
		for j := 0; j < sz; j++ {
			coef[i][j] = math.Cos((float64(j) + 0.5) * mult)
		}
	}

	return coef
}
