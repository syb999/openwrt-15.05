#include "skf.h"
#include <string.h>

#ifndef _WIN32
#include <dlfcn.h>
#include <unistd.h>
#else
#include <windows.h>
#endif

PSKF_FUNCLIST FunctionList;

int load_library()
{
	int ret = 0;
	void * lib_handle = NULL;
	char  path[128] = {0};

#ifdef _WIN32
	P_SKF_GetFuncList GetFunction = NULL;
	GetCurrentDirectory(MAX_PATH, path);
	strcat(path, "\\SKF.dll");
	printf("Load Dll %s\n", path);
	lib_handle = LoadLibrary(path);
	if (lib_handle==NULL)
	{
		ret = GetLastError();
		printf("Load Dll Fail:%d\n", ret);
		return ret;
	}
	else
	{
		GetFunction = (P_SKF_GetFuncList)GetProcAddress(lib_handle, "SKF_GetFuncList");
		if (GetFunction == NULL)
		{
			ret = GetLastError();
			return ret;
		}
		printf("Load Dll OK\n");
		ret = GetFunction(&FunctionList);
		if (ret) return ret;
	}
#else
	P_SKF_GetFuncList get_func_list;

    getcwd(path, sizeof(path));
    strcat(path, "/libskf.so");
	lib_handle = dlopen(path, RTLD_LAZY );
	if (!lib_handle)
	{
		printf("Open Error:%s.\n", dlerror());
		return 0;
	}

	get_func_list = dlsym(lib_handle, "SKF_GetFuncList");
	if (get_func_list == NULL)
	{
		printf("Dlsym Error:%s.\n", dlerror());
		return 0;
	}

	ret = get_func_list(&FunctionList);
	if (ret) 
	{
		printf("fnGetList ERROR 0x%x", ret);
		return ret;
	}
#endif

	return ret;
}

void print_data(char *info, unsigned char *data, unsigned int len)
{
    int i = 0;
    if (info) printf("%s\n", info);

    for (i = 0; i < len; i++) {
        if (i && i % 16 == 0) printf("\n");
        printf("0x%02x ", data[i]);
    }
    printf("\n");
}

int sym_gdb_test(HANDLE hdev, unsigned int algo, unsigned char *key, unsigned char *iv, unsigned int iv_len, unsigned char *data, unsigned int data_len, unsigned char *gdb_data, unsigned int gdb_data_len)
{
    int ret = 0;
	HANDLE hkey;
	BLOCKCIPHERPARAM bp;
	u8 enc_data[1024] = {0};
	u32 enc_len = 0, enc_final_len = 0;
	u8 dec_data[1024] = {0};
	u32 dec_len = 0, dec_final_len = 0;

	ret = FunctionList->SKF_SetSymmKey(hdev, key, algo, &hkey);
	if (ret) {
		printf("SKF_SetSymmKey() failed: %#x\n", ret);
		return ret;
	}

	memset(&bp, 0, sizeof(bp));
	bp.IVLen = iv_len;
	if (bp.IVLen > 0) {
	    if (!iv) {
            printf("sym cbc mode, but iv is null\n");
            return -1;
        }

        memcpy(bp.IV, iv, bp.IVLen);
    }

	ret = FunctionList->SKF_EncryptInit(hkey, bp);
	if (ret) {
		printf("SKF_EncryptInit() failed: %#x\n", ret);
		return ret;
	}

	ret = FunctionList->SKF_EncryptUpdate(hkey, data, data_len, enc_data, &enc_len);
	if (ret) {
		printf("SKF_EncryptInit() failed: %#x\n", ret);
		return ret;
	}

	ret = FunctionList->SKF_EncryptFinal(hkey, enc_data + enc_len, &enc_final_len);
	if (ret) {
		printf("SKF_EncryptInit() failed: %#x\n", ret);
		return ret;
	}
	enc_len += enc_final_len;

	/**
	 * show original data and encrypted data
	 */
	print_data("original data: ", data, data_len);
	print_data("encrypted data: ", enc_data, enc_len);

	if (gdb_data && gdb_data_len > 0 && (enc_len != gdb_data_len || memcmp(gdb_data, enc_data, enc_len))) {
	    printf("enc and gdb data is not same!\n");
	    return -1;
    }

	ret = FunctionList->SKF_DecryptInit(hkey, bp);
	if (ret) {
		printf("SKF_DecryptInit() failed: %#x\n", ret);
		return ret;
	}

	ret = FunctionList->SKF_DecryptUpdate(hkey, enc_data, enc_len, dec_data, &dec_len);
	if (ret) {
		printf("SKF_EncryptInit() failed: %#x\n", ret);
		return ret;
	}

	ret = FunctionList->SKF_DecryptFinal(hkey, dec_data + dec_len, &dec_final_len);
	if (ret) {
		printf("SKF_EncryptInit() failed: %#x\n", ret);
		return ret;
	}
	dec_len += dec_final_len;

	/**
	 * show encrypted data and decrypted data
	 */
	print_data("encrypted data: ", enc_data, enc_len);
	print_data("decrypted data: ", dec_data, dec_len);

	if (enc_len != dec_len || memcmp(data, dec_data, enc_len)) {
		printf("enc and dec data is not same!\n");
		ret = -1;
	} else {
		printf("sym enc and dec succ!\n");
	}

    return ret;
}

int sm4_ecb_gdb_data_test(HANDLE hdev)
{
    int ret = 0;
    unsigned char key[] = {0x77,0x7f,0x23,0xc6,0xfe,0x7b,0x48,0x73,0xdd,0x59,0x5c,0xff,0xf6,0x5f,0x58,0xec};
    unsigned char data[] = {0x5f,0xe9,0x7c,0xcd,0x58,0xfe,0xd7,0xab,0x41,0xf7,0x1e,0xfb,0xfd,0xe7,0xe1,0x46};
    unsigned char gdb_data[] = {0x56,0xda,0x23,0xe2,0x5f,0xa7,0xcd,0x82,0x5d,0x51,0xc2,0x20,0xf5,0x98,0x09,0x0b};

    ret = sym_gdb_test(hdev, SGD_SMS4_ECB, key, NULL, 0, data, sizeof(data), gdb_data, sizeof(gdb_data));
    return ret;
}

int get_device_info(HANDLE hdev)
{
    int ret = 0;
    DEVINFO info;

    memset(&info, 0, sizeof(info));
    ret = FunctionList->SKF_GetDevInfo(hdev, &info);
    if (ret) {
        printf("SKF_GetDevInfo() failed: %#x\n", ret);
        return ret;
    }

    printf("Manufacturer: %s\n", info.Manufacturer);
    printf("Issuer: %s\n", info.Issuer);
    printf("Label: %s\n", info.Label);
    printf("SerialNumber: %s\n", info.SerialNumber);

    return ret;
}

int main(int agrc, char *agrv[])
{
	int ret = 0;
	char devices[128] = {0};
	u32 devices_size = sizeof(devices);
	HANDLE hdev;

	ret = load_library();
	if (ret) {
		printf("load_library() failed: %#x\n", ret);
		return ret;
	}

	//ret = FunctionList->SKF_EnumDev(1, devices, &devices_size);
	if (ret) {
		printf("SKF_EnumDev() failed: %#x\n", ret);
		goto end;
	}

	ret = FunctionList->SKF_ConnectDev("ccm3310_spi", &hdev);
	//ret = FunctionList->SKF_ConnectDev("spidev1.0", &hdev);
	if (ret) {
		printf("SKF_ConnectDev() failed: %#x\n", ret);
		goto end;
	}

    ret = get_device_info(hdev);
    if (ret) {
		printf("get device info failed: %#x\n", ret);
        goto end;
    }

	ret = sm4_ecb_gdb_data_test(hdev);
	if (ret) {
		printf("sym_test() failed: %#x\n", ret);
	}

end:
	if (hdev) ret = FunctionList->SKF_DisConnectDev(hdev);

#ifdef _WIN32
	system("pause");
#endif
	return 0;
}
