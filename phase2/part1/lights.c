/*
 * lights.c
 *
 *  Created on: Dec 10, 2025
 *      Author: anous
 */

#include <stdint.h>
#include "system.h"
#include "altera_avalon_pio_regs.h"
#include "io.h"

int main() {
    printf("Starting lights program...\n");

    while (1) {
        // Read the 8-bit value from the SWITCHES PIO
        uint32_t sw = IORD_ALTERA_AVALON_PIO_DATA(SWITCHES_BASE);

        // Write the same value to the LEDS PIO
        IOWR_ALTERA_AVALON_PIO_DATA(LEDS_BASE, sw);
    }

    return 0;
}





