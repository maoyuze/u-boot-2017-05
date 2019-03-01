static void delay(unsigned int n)
{
    while(n--);
}

void led_loop()
{
    unsigned int gpm4con = ((volatile unsigned int *)0x110002e0);
    unsigned int gpm4dat = ((volatile unsigned int *)0x110002e4);

    gpm4con |= 0x1111;

    while(1)
    {
        gpm4dat = 0;
        delay(9999999);
        gpm4dat = 0xff;
        delay(9999999);
    }
}
