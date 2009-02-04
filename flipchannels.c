/*
 * Guillaume Cottenceau (gc at mandrakesoft.com)
 *
 * Small modification for R/B channel flippage by MHW.
 *
 * Everything else is Copyright 2002 MandrakeSoft.
 *
 * This software may be freely redistributed under the terms of the GNU
 * public license.
 *
 * Adapted by Cédric Luthi for crippng QuickLook plugin
 */

#include <unistd.h>
#include <stdbool.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>

//#define PNG_DEBUG 3
#include <png.h>

int x, y;

int width, height;
png_byte color_type;
png_byte bit_depth;

png_structp png_ptr;
png_infop info_ptr;
int number_of_passes;
png_bytep * row_pointers;

bool read_png_file(int fd)
{
    unsigned char header[8]; /* 8 is the maximum size that can be checked */

    /* open file and test for it being a png */
    FILE *fp = fdopen(fd, "rb");
    if (!fp)
        return false;
    fread(header, 1, 8, fp);
    if (png_sig_cmp(header, 0, 8))
        return false;


    /* initialize stuff */
    png_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
    
    if (!png_ptr)
        return false;

    info_ptr = png_create_info_struct(png_ptr);
    if (!info_ptr)
        return false;

    if (setjmp(png_jmpbuf(png_ptr)))
        return false;

    png_init_io(png_ptr, fp);
    png_set_sig_bytes(png_ptr, 8);

    png_read_info(png_ptr, info_ptr);

    width = info_ptr->width;
    height = info_ptr->height;
    color_type = info_ptr->color_type;
    bit_depth = info_ptr->bit_depth;

    number_of_passes = png_set_interlace_handling(png_ptr);
    png_read_update_info(png_ptr, info_ptr);


    /* read file */
    if (setjmp(png_jmpbuf(png_ptr)))
        return false;

    row_pointers = (png_bytep*) malloc(sizeof(png_bytep) * height);
    for (y=0; y<height; y++)
        row_pointers[y] = (png_byte*) malloc(info_ptr->rowbytes);

    png_read_image(png_ptr, row_pointers);

    fclose(fp);
    return true;
}


bool write_png_file(int fd)
{
    /* create file */
    FILE *fp = fdopen(fd, "wb");
    if (!fp)
        return false;


    /* initialize stuff */
    png_ptr = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
    
    if (!png_ptr)
        return false;

    info_ptr = png_create_info_struct(png_ptr);
    if (!info_ptr)
        return false;

    if (setjmp(png_jmpbuf(png_ptr)))
        return false;

    png_init_io(png_ptr, fp);


    /* write header */
    if (setjmp(png_jmpbuf(png_ptr)))
        return false;

    png_set_IHDR(png_ptr, info_ptr, width, height,
             bit_depth, color_type, PNG_INTERLACE_NONE,
             PNG_COMPRESSION_TYPE_BASE, PNG_FILTER_TYPE_BASE);

    png_write_info(png_ptr, info_ptr);


    /* write bytes */
    if (setjmp(png_jmpbuf(png_ptr)))
        return false;

    png_write_image(png_ptr, row_pointers);


    /* end write */
    if (setjmp(png_jmpbuf(png_ptr)))
        return false;

    png_write_end(png_ptr, NULL);

        /* cleanup heap allocation */
    for (y=0; y<height; y++)
        free(row_pointers[y]);
    free(row_pointers);

    fclose(fp);
    return true;
}


bool process_file(void)
{
    int i;

    if (info_ptr->color_type != PNG_COLOR_TYPE_RGBA)
        return false;


    /* Run through the pixels and flip R and B. */
    for (i = 0; i < height; i++){
        for (y = 0; y < width * 4; y += 4){
            png_byte tmp;

            tmp = *(*(row_pointers+i)+y);
            *(*(row_pointers+i)+y) = *(*(row_pointers+i)+y+2);
            *(*(row_pointers+i)+y+2) = tmp;
        }
    }
    return true;
}


bool flip_channels(int inputFd, int outputFd)
{
    bool ok = read_png_file(inputFd);
    if (!ok)
        return false;
    ok = process_file();
    if (!ok)
        return false;
    return write_png_file(outputFd);
}
