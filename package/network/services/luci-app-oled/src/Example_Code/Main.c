/*
 * Main.c
 *
 *  Created on  : Sep 6, 2017
 *  Author      : Vinay Divakar
 *  Description : Example usage of the SSD1306 Driver API's
 *  Website     : www.deeplyembedded.org
 */

/* Lib Includes */
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <limits.h>
#include <signal.h>
#include <signal.h>
#include <syslog.h>
#include <dirent.h>

/* Header Files */
#include "I2C.h"
#include "SSD1306_OLED.h"
#include "example_app.h"

#define MAX_FD_THRESHOLD 50
#define MEMORY_THRESHOLD (50*1024)
#define WATCHDOG_INTERVAL 600

/* Oh Compiler-Please leave me as is */
volatile unsigned char flag = 0;
volatile sig_atomic_t running = 1;
int watchdog_counter = 0;

void monitor_resources(void);
int safe_atoi(const char *str, int *value);
long get_memory_usage(void);
void safe_cleanup(void);

/* Alarm Signal Handler */
void signal_handler(int sig) {
    static volatile sig_atomic_t exiting = 0;
    if(exiting++) return;
    
    if(sig == SIGALRM) {
        flag = 5;
    } else {
        running = 0;
    }
}


void monitor_resources(void) {
    DIR *dir = opendir("/proc/self/fd");
    if(dir) {
        size_t count = 0;
        while(readdir(dir)) count++;
        closedir(dir);
    }
    
    long mem_used = get_memory_usage();
}

int safe_atoi(const char *str, int *value) {
    char *endptr;
    long val = strtol(str, &endptr, 10);
    if (*endptr != '\0' || val < 0 || val > (long)INT_MAX) {
        return -1;
    }
    *value = (int)val;
    return 0;
}
 
long get_memory_usage(void) {
    FILE* fp = fopen("/proc/self/status", "r");
    if(!fp) return -1;
    
    long mem = -1;
    char line[128];
    
    while(fgets(line, sizeof(line), fp)) {
        if(strncmp(line, "VmRSS:", 6) == 0) {
            sscanf(line+6, "%ld", &mem);
            break;
        }
    }
    
    fclose(fp);
    return mem;
}

void safe_cleanup(void) {
    clearDisplay();
    Display();
    #ifdef I2C_CLEANUP
    i2c_cleanup();
    #endif
    closelog();
}

int main(int argc, char* argv[])
{
    int date=atoi(argv[1]);
    int lanip=atoi(argv[2]);
    int wanip=atoi(argv[3]);
    int cputemp=atoi(argv[4]);
    int cpufreq=atoi(argv[5]);
    int netspeed=atoi(argv[6]);
    int time=atoi(argv[7]);
    int drawline=atoi(argv[8]);
    int drawrect=atoi(argv[9]);
    int fillrect=atoi(argv[10]);
    int drawcircle=atoi(argv[11]);
    int drawroundcircle=atoi(argv[12]);
    int fillroundcircle=atoi(argv[13]);
    int drawtriangle=atoi(argv[14]);
    int filltriangle=atoi(argv[15]);
    int displaybitmap=atoi(argv[16]);
    int displayinvertnormal=atoi(argv[17]);
    int drawbitmapeg=atoi(argv[18]);
    int scroll=atoi(argv[19]);
    char *text=argv[20];
    char *eth=argv[21];
    char *path=argv[22];
    int rotate=atoi(argv[23]);
    int needinit=atoi(argv[24]);

    static unsigned long last_reset = 0;
    const unsigned long reset_interval = 60000;

    if(path == NULL)
        path = I2C_DEV0_PATH;

    /* Initialize I2C bus and connect to the I2C Device */
    if(init_i2c_dev(path, SSD1306_OLED_ADDR) == 0)
    {
        printf("I2C: Bus Connected to SSD1306\r\n");
    }
    else
    {
        printf("I2C: OOPS! Something Went Wrong\r\n");
        exit(1);
    }

    /* Register the Alarm Handler */
    signal(SIGALRM, signal_handler);
    signal(SIGINT, signal_handler);
    signal(SIGTERM, signal_handler);
    signal(SIGSEGV, signal_handler);
    signal(SIGPIPE, SIG_IGN);

    /* Run SDD1306 Initialization Sequence */
    if (needinit==1)
        display_Init_seq();

    if (rotate==1)
        display_rotate();
    else
        display_normal();

    /* Clear display */
    clearDisplay();

    // draw a single pixel
//    drawPixel(0, 1, WHITE);
//    Display();
//    usleep(1000000);
//    clearDisplay();

    // draw many lines
    while(running){
        monitor_resources();
        if(scroll){
            testscrolltext(text);
            usleep(1000000);
            clearDisplay();
        }

        if(drawline){
            testdrawline();
            usleep(1000000);
            clearDisplay();
        }

        // draw rectangles
        if(drawrect){
            testdrawrect();
            usleep(1000000);
            clearDisplay();
        }

        // draw multiple rectangles
        if(fillrect){
            testfillrect();
            usleep(1000000);
            clearDisplay();
        }

        // draw mulitple circles
        if(drawcircle){
            testdrawcircle();
            usleep(1000000);
            clearDisplay();
        }

        // draw a white circle, 10 pixel radius
        if(drawroundcircle){
            testdrawroundrect();
            usleep(1000000);
            clearDisplay();
        }

        // Fill the round rectangle
        if(fillroundcircle){
            testfillroundrect();
            usleep(1000000);
            clearDisplay();
        }

        // Draw triangles
        if(drawtriangle){
            testdrawtriangle();
            usleep(1000000);
            clearDisplay();
        }
        // Fill triangles
        if(filltriangle){
            testfilltriangle();
            usleep(1000000);
            clearDisplay();
        }

        // Display miniature bitmap
        if(displaybitmap){
            display_bitmap();
            Display();
            usleep(1000000);
        };

        // Display Inverted image and normalize it back
        if(displayinvertnormal){
            display_invert_normal();
            clearDisplay();
            usleep(1000000);
            Display();
        }

        // Generate Signal after 20 Seconds

        // draw a bitmap icon and 'animate' movement
        if(drawbitmapeg){
            alarm(10);
            flag=0;
            testdrawbitmap_eg();
            clearDisplay();
            usleep(1000000);
            Display();
        }

        //setCursor(0,0);
        setTextColor(WHITE);

        // info display
        int sum = date+lanip+wanip+cpufreq+cputemp+netspeed;
        if (sum == 0) {
            clearDisplay();
            return 0;
        }

        for(int i = 1; i < time; i++){
            if (sum == 1){//only one item for display
                if (date) testdate(CENTER, 8);
                if (lanip) testlanip(CENTER, 8);
                if (wanip) testwanip(CENTER, 8);
                if (cpufreq) testcpufreq(CENTER, 8);
                if (cputemp) testcputemp(CENTER, 8);
                if (netspeed) testnetspeed(SPLIT,0);
                Display();
                usleep(1000000);
                clearDisplay();
            }else if (sum == 2){//two items for display
                if(date) {testdate(CENTER, 16*(date-1));}
                    if(lanip) {testlanip(CENTER, 16*(date+lanip-1));}
                    if(wanip) {testwanip(CENTER, 16*(date+wanip-1));}
                    if(cpufreq) {testcpufreq(CENTER, 16*(date+lanip+wanip+cpufreq-1));}
                    if(cputemp) {testcputemp(CENTER, 16*(date+lanip+wanip+cpufreq+cputemp-1));}
                    if(netspeed) {testnetspeed(MERGE, 16*(date+lanip+wanip+cpufreq+cputemp+netspeed-1));}
                Display();
                usleep(1000000);
                clearDisplay();
            }else{//more than two items for display
                if(date) {testdate(FULL, 8*(date-1));}
                if(lanip) {testlanip(FULL, 8*(date+lanip-1));
                }else if (wanip) {testwanip(FULL, 8*(date+wanip-1));}
                if(lanip && wanip) {testwanip(FULL, 8*(date+lanip+wanip-1));}
                if(cpufreq && cputemp) {
                    testcpu(8*(date+lanip+wanip));
                    if(netspeed) {testnetspeed(FULL, 8*(date+lanip+wanip+1+netspeed-1));}
                }else{
                    if(cpufreq) {testcpufreq(FULL, 8*(date+lanip+wanip+cpufreq-1));}
                    if(cputemp) {testcputemp(FULL, 8*(date+lanip+wanip+cpufreq+cputemp-1));}
                    if(netspeed) {testnetspeed(FULL, 8*(date+lanip+wanip+cpufreq+cputemp+netspeed-1));}
                }
                Display();
                usleep(1000000);
                clearDisplay();
            }
        }

        if(++watchdog_counter > WATCHDOG_INTERVAL) {
            watchdog_counter = 0;
            if(get_memory_usage() > MEMORY_THRESHOLD) {
                running = 0;
            }
        }
    }

    safe_cleanup();
    return EXIT_SUCCESS;
}
