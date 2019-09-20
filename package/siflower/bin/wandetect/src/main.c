#include "discovery.h"

char dt_iface[16];

int main (int argc,char * * argv) {
	char c = 0;
	int ret;
    while ((c = getopt(argc, argv, "i:")) != EOF)
    {
        switch (c)
        {
            case 'i':
                sprintf(dt_iface, "%s", optarg);
                break;
            default:
                break;
        }
    }
	LOG("start detect pppoe %s\n",dt_iface);
	ret=detect_pppoe();
	if(ret == 1){
		printf("pppoe\n");
	}
	return 0;
}
