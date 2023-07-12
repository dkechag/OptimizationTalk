const sz = 256;
const array2d = [];

for (let x = 0; x < sz; x++) {
  const array = [];
  for (let y = 0; y < sz; y++) {
    array.push(Math.floor(Math.random() * 256));
  }
  array2d.push(array);
}

function dct2d(array2d) {
  const sz = array2d.length;
  const coef = dctCoef(sz);
  const temp = [];
  const result = [];

  for (let x = 0; x < sz; x++) {
    temp[x] = [];
    for (let i = 0; i < sz; i++) {
      let sum = 0;
      for (let j = 0; j < sz; j++) {
        sum += array2d[x][j] * coef[j][i];
      }
      temp[x][i] = sum;
    }
  }

  for (let y = 0; y < sz; y++) {
    result[y] = [];
    for (let i = 0; i < sz; i++) {
      let sum = 0;
      for (let j = 0; j < sz; j++) {
        sum += temp[j][y] * coef[j][i];
      }
      result[y][i] = sum;
    }
  }

  return result;
}

function dctCoef(sz) {
  const fact = Math.PI / sz;
  const coef = [];

  for (let i = 0; i < sz; i++) {
    const mult = i * fact;
    coef[i] = [];
    for (let j = 0; j < sz; j++) {
      coef[i][j] = Math.cos((j + 0.5) * mult);
    }
  }

  return coef;
}

// Calling and timing code
const startTime = Date.now();
const result = dct2d(array2d);
const endTime = Date.now();
const executionTime = endTime - startTime;
console.log('Execution time:', executionTime);

