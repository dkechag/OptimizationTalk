import math
import random
import time

sz = 256
array2d = []

for x in range(sz):
    array = [random.randint(0, 255) for _ in range(sz)]
    array2d.append(array)


def dct2d(array2d):
    sz = len(array2d)
    coef = dct_coef(sz)
    temp = [[0] * sz for _ in range(sz)]
    result = [[0] * sz for _ in range(sz)]

    for x in range(sz):
        for i in range(sz):
            sum = 0
            for j in range(sz):
                sum += array2d[x][j] * coef[j][i]
            temp[x][i] = sum

    for y in range(sz):
        for i in range(sz):
            sum = 0
            for j in range(sz):
                sum += temp[j][y] * coef[j][i]
            result[y][i] = sum

    return result

def dct_coef(sz):
    fact = math.pi / sz
    coef = [[0] * sz for _ in range(sz)]

    for i in range(sz):
        mult = i * fact
        for j in range(sz):
            coef[j][i] = math.cos((j + 0.5) * mult)

    return coef

start_time = time.time()
result = dct2d(array2d)
print('Time: {:.3f}'.format(time.time() - start_time))
