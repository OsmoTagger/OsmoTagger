//
//  FastHash.m
//  OSM editor
//
//  Created by Evgen Bodunov on 4.10.22.
//

#include "FastHash.h"

uint32_t get16bits(const char *d)
{
    return ((uint32_t)d[1] << 8) + d[0];
}

uint32_t CalcFastHashC(const char *data, size_t l)
{
    if (l <= 0 || data == NULL)
        return 0;

    uint32_t hash = (uint32_t)l;
    size_t rem = l & 3;
    l >>= 2;
    /* Main loop */
    for (; l > 0; l--) {
        hash += get16bits(data);
        uint32_t tmp = (get16bits(data + 2) << 11) ^ hash;
        hash = (hash << 16) ^ tmp;
        data += 2 * sizeof(uint16_t);
        hash += hash >> 11;
    }

    /* Handle end cases */
    switch (rem) {
    case 3:
        hash += get16bits(data);
        hash ^= hash << 16;
        hash ^= ((uint32_t)data[2]) << 18;
        hash += hash >> 11;
        break;
    case 2:
        hash += get16bits(data);
        hash ^= hash << 11;
        hash += hash >> 17;
        break;
    case 1:
        hash += (signed char)*data;
        hash ^= hash << 10;
        hash += hash >> 1;
        break;
    default:
        break;
    }

    /* Force "avalanching" of final 127 bits */
    hash ^= hash << 3;
    hash += hash >> 5;
    hash ^= hash << 4;
    hash += hash >> 17;
    hash ^= hash << 25;
    hash += hash >> 6;
    return hash;
}

uint32_t CalcFastHash(NSString *str) {
    return CalcFastHashC(str.UTF8String, str.length);
}
