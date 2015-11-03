#include <fcgi_stdio.h>
#include <stdlib.h>

int main(void)
{
  char* contentType = "Content-type: text/plain";
  char* status = "Status: 200 OK";
  char* body = "Hello, I am a fcgi-program using C";
  
  while (FCGI_Accept() >= 0)
  {
    printf("%s\r\n%s\r\n\r\n%s", contentType, status, body);
  }

  return 0;
}
