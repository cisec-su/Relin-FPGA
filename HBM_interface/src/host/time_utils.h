#pragma once

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

int comp(const void * a, const void * b) {
  return ( *(uint64_t*)a - *(uint64_t*)b );
}

int comp_double(const void * a, const void * b) {
  if (*(double*)a > *(double*)b)
    return 1;
  else if (*(double*)a < *(double*)b)
    return -1;
  else
    return 0;  
}

inline int median(int *array, int len) {
  qsort(array, len, sizeof(int), comp);
  return array[len/2];
}

inline int average(int *array, int len) {
  int sum = 0;
  for (int i=0; i<len; i++)
    sum += array[i];
  return sum/len;
}
