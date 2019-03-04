#define TX  (*((volatile unsigned int *)0x13800020))
static void delay(n)
{
    while(n--);
}
void my_putc(char c)
{
(*((volatile unsigned int *)0x13800020))=c;
}

void my_puts(char *p)
{
    while(*p != '\0')
    {
        my_putc(*p);
        p++;
    }
}
