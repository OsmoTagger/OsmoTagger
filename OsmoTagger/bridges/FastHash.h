//
//  FastHash.h
//  OSM editor
//
//  Created by Evgen Bodunov on 4.10.22.
//

#ifndef FastHash_h
#define FastHash_h

#import <Foundation/Foundation.h>
#include <stdint.h>

uint32_t CalcFastHash(NSString *str);

#endif /* FastHash_h */
