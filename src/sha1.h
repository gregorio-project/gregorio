/*
 * FIPS-180-1 compliant SHA-1 implementation
 *
 * Copyright (C) 2015 The Gregorio Project (see CONTRIBUTORS.md)
 * Copyright (C) 2006-2014, ARM Limited, All Rights Reserved
 *
 * This file is part of Gregorio.
 *
 * This file was originally part of mbed TLS (https://tls.mbed.org)
 * It has been modified to remove features not necessary for Gregorio.
 *
 * Gregorio is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Gregorio is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Gregorio.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef _SHA1_H
#define _SHA1_H

#include <stddef.h>

#if defined(_MSC_VER) && !defined(EFIX64) && !defined(EFI32)
#include <basetsd.h>
typedef UINT32 uint32_t;
#else
#include <inttypes.h>
#endif

/**
 * \brief          SHA-1 context structure
 */
typedef struct
{
    uint32_t total[2];          /*!< number of bytes processed  */
    uint32_t state[5];          /*!< intermediate digest state  */
    unsigned char buffer[64];   /*!< data block being processed */

    unsigned char ipad[64];     /*!< HMAC: inner padding        */
    unsigned char opad[64];     /*!< HMAC: outer padding        */
}
sha1_context;

/**
 * \brief          Initialize SHA-1 context
 *
 * \param ctx      SHA-1 context to be initialized
 */
void sha1_init( sha1_context *ctx );

/**
 * \brief          Clear SHA-1 context
 *
 * \param ctx      SHA-1 context to be cleared
 */
void sha1_free( sha1_context *ctx );

/**
 * \brief          SHA-1 context setup
 *
 * \param ctx      context to be initialized
 */
void sha1_starts( sha1_context *ctx );

/**
 * \brief          SHA-1 process buffer
 *
 * \param ctx      SHA-1 context
 * \param input    buffer holding the  data
 * \param ilen     length of the input data
 */
void sha1_update( sha1_context *ctx, const unsigned char *input, size_t ilen );

/**
 * \brief          SHA-1 final digest
 *
 * \param ctx      SHA-1 context
 * \param output   SHA-1 checksum result
 */
void sha1_finish( sha1_context *ctx, unsigned char output[20] );

/* Internal use */
void sha1_process( sha1_context *ctx, const unsigned char data[64] );

/**
 * \brief          Output = SHA-1( input buffer )
 *
 * \param input    buffer holding the  data
 * \param ilen     length of the input data
 * \param output   SHA-1 checksum result
 */
void sha1( const unsigned char *input, size_t ilen, unsigned char output[20] );

#endif /* sha1.h */
