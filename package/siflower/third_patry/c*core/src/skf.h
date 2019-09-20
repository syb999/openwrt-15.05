#ifndef __SKF_FUNC_H__
#define __SKF_FUNC_H__

#include "skf_type.h"

#ifndef _WIN32
#define DEVAPI
#else

#ifdef SKF_FOR_NR
#ifdef SKF
#define DEVAPI __declspec(dllexport)  __cdecl 
#else
#define DEVAPI __declspec(dllimport)  __cdecl
#endif
#else
#define DEVAPI __declspec(dllimport)  __cdecl
// #define DEVAPI __stdcall //使用__cdecl在格尔的“国密介质检测工具V3.exe”调用后会崩溃
#endif

#endif

#define __PASTE(x,y)      x##y

#ifdef __cplusplus
extern "C" {
#endif


#ifndef _WIN32
#define SKF_FUN_DEF(name,args) extern u32 __attribute__ ((visibility("default"))) name args
#else
#define SKF_FUN_DEF(name,args) u32  DEVAPI name args
#endif

#ifdef SKF_FOR_NR
#define SKF_FUN_POINTER(name,args) u32 (* name) args
#else
#define SKF_FUN_POINTER(name,args) u32 (* name) args
// #define SKF_FUN_POINTER(name,args) u32 (DEVAPI * name) args
#endif

#define SKF_FUN_INFO(name,args) \
	SKF_FUN_DEF(name,args);\
	typedef SKF_FUN_POINTER(__PASTE(P_,name),args)

SKF_FUN_INFO(SKF_WaitForDevEvent, (LPSTR szDevName,u32 *pulDevNameLen, u32 *pulEvent));
SKF_FUN_INFO(SKF_CancelWaitForDevEvent, ());
SKF_FUN_INFO(SKF_EnumDev, (BOOL bPresent, LPSTR szNameList, u32 *pulSize));
SKF_FUN_INFO(SKF_ConnectDev, (LPSTR szName, DEVHANDLE *phDev));
SKF_FUN_INFO(SKF_DisconnectDev, (DEVHANDLE hDev));
SKF_FUN_INFO(SKF_DisConnectDev, (DEVHANDLE hDev));
SKF_FUN_INFO(SKF_GetDevState, (LPSTR szDevName, u32 *pulDevState));
SKF_FUN_INFO(SKF_SetLabel, (DEVHANDLE hDev, LPSTR szLabel));
SKF_FUN_INFO(SKF_GetDevInfo, (DEVHANDLE hDev, PDEVINFO pInfo));
SKF_FUN_INFO(SKF_LockDev, (DEVHANDLE hDev, u32 ulTimeOut));
SKF_FUN_INFO(SKF_UnlockDev, (DEVHANDLE hDev));
SKF_FUN_INFO(SKF_Transmit, (DEVHANDLE hDev, u8* pbCommand, u32 ulCommandLen,
				u8* pbData, u32* pulDataLen));

SKF_FUN_INFO(SKF_ChangeDevAuthKey, (DEVHANDLE hDev, u8 *pbKeyValue, u32 ulKeyLen));
SKF_FUN_INFO(SKF_DevAuth, (DEVHANDLE hDev, u8 *pbAuthData, u32 ulLen));
SKF_FUN_INFO(SKF_ChangePIN, (HAPPLICATION hApplication, u32 ulPinType, LPSTR szOldPin, 
				LPSTR szNewPin, u32* pulRetry));
SKF_FUN_INFO(SKF_GetPINInfo, (HAPPLICATION hApplication, u32 ulPINType, u32 *pulMaxRetryCount,
				u32 *pulRemainRetryCount, BOOL *pbDefaultPin));
SKF_FUN_INFO(SKF_VerifyPIN, (HAPPLICATION hApplication, u32 ulPinType, LPSTR szPin,
				u32* pulRetry));
SKF_FUN_INFO(SKF_UnblockPIN, (HAPPLICATION hApplication,LPSTR szAdminPin,LPSTR szNewUserPin,
				u32* pulRetry));
SKF_FUN_INFO(SKF_ClearSecureState, (HAPPLICATION hApplication));

SKF_FUN_INFO(SKF_CreateApplication, (DEVHANDLE hDev, LPSTR szAppName, LPSTR szAdminPin,
				u32 ulAdminPinRetry, LPSTR szUserPin, u32 ulUserPinRetry,
				u32 ulCreateFileRights, HAPPLICATION *phApplication));
SKF_FUN_INFO(SKF_EnumApplication, (DEVHANDLE hDev, LPSTR szAppName, u32* pulSize));
SKF_FUN_INFO(SKF_DeleteApplication, (DEVHANDLE hDev, LPSTR szAppName));
SKF_FUN_INFO(SKF_OpenApplication, (DEVHANDLE hDev, LPSTR szAppName, HAPPLICATION* phApplication));
SKF_FUN_INFO(SKF_CloseApplication, (HAPPLICATION hApplication));

SKF_FUN_INFO(SKF_CreateFile, (HAPPLICATION hApplication, LPSTR szFileName, u32 ulFileSize,
				u32 ulReadRights, u32 ulWriteRights));
SKF_FUN_INFO(SKF_DeleteFile, (HAPPLICATION hApplication, LPSTR szFileName));
SKF_FUN_INFO(SKF_EnumFiles, (HAPPLICATION hApplication, LPSTR szFileList, u32 *pulSize));
SKF_FUN_INFO(SKF_GetFileInfo, (HAPPLICATION hApplication, LPSTR szFileName, 
				PFILEATTRIBUTE pFileInfo));
SKF_FUN_INFO(SKF_ReadFile, (HAPPLICATION hApplication, LPSTR szFileName, u32 ulOffset, 
				u32 ulSize, u8 * pbOutData, u32 *pulOutLen));
SKF_FUN_INFO(SKF_WriteFile, (HAPPLICATION hApplication, LPSTR szFileName, u32 ulOffset, 
				u8 *pbData, u32 ulSize));

SKF_FUN_INFO(SKF_CreateContainer, (HAPPLICATION hApplication, LPSTR szContainerName, 
				HCONTAINER *phContainer));
SKF_FUN_INFO(SKF_DeleteContainer, (HAPPLICATION hApplication, LPSTR szContainerName));
SKF_FUN_INFO(SKF_OpenContainer, (HAPPLICATION hApplication,LPSTR szContainerName,
				HCONTAINER *phContainer));
SKF_FUN_INFO(SKF_CloseContainer, (HCONTAINER hContainer));
SKF_FUN_INFO(SKF_EnumContainer, (HAPPLICATION hApplication,LPSTR szContainerName,u32* pulSize));
SKF_FUN_INFO(SKF_GetContainerType, (HCONTAINER hContainer, u32 *pulContainerType));
SKF_FUN_INFO(SKF_ImportCertificate,(HCONTAINER hContainer, BOOL bSignFlag,  u8* pbCert, u32 ulCertLen));
SKF_FUN_INFO(SKF_ExportCertificate,(HCONTAINER hContainer, BOOL bSignFlag,  u8* pbCert, u32 *pulCertLen));

SKF_FUN_INFO(SKF_GenRandom, (DEVHANDLE hDev,u8* pbRandom,u32 ulRandom));
SKF_FUN_INFO(SKF_GenExtRSAKey, (DEVHANDLE hDev, u32 ulBitLen, PRSAPRIVATEKEYBLOB pBlob));
SKF_FUN_INFO(SKF_GenRSAKeyPair, (HCONTAINER hContainer, u32 ulBitLen, PRSAPUBLICKEYBLOB pBlob));
SKF_FUN_INFO(SKF_ImportRSAKeyPair, ( HCONTAINER hContainer, u32 ulSymAlgId, u8 *pbWrappedKey,
				u32 ulWrappedKeyLen, u8 *pbEncryptedData, u32 ulEncryptedDataLen));
SKF_FUN_INFO(SKF_RSASignData, (HCONTAINER hContainer, u8 *pbData, u32 ulDataLen,
				u8 *pbSignature, u32 *pulSignLen));
SKF_FUN_INFO(SKF_RSAVerify, (DEVHANDLE hDev, PRSAPUBLICKEYBLOB pRSAPubKeyBlob, u8 *pbData,
				u32 ulDataLen, u8 *pbSignature, u32 ulSignLen));
SKF_FUN_INFO(SKF_RSAExportSessionKey, (HCONTAINER hContainer, u32 ulAlgId, 
				PRSAPUBLICKEYBLOB pPubKey, u8 *pbData, u32 *pulDataLen, HANDLE *phSessionKey));
SKF_FUN_INFO(SKF_ExtRSAPubKeyOperation, (DEVHANDLE hDev, PRSAPUBLICKEYBLOB pRSAPubKeyBlob,
				u8* pbInput,	u32 ulInputLen, u8* pbOutput, u32* pulOutputLen));
SKF_FUN_INFO(SKF_ExtRSAPriKeyOperation, (DEVHANDLE hDev, PRSAPRIVATEKEYBLOB pRSAPriKeyBlob,
				u8* pbInput,	u32 ulInputLen, u8* pbOutput, u32* pulOutputLen));
SKF_FUN_INFO(SKF_GenECCKeyPair, (HCONTAINER hContainer, u32 ulAlgId, PECCPUBLICKEYBLOB pBlob));
SKF_FUN_INFO(SKF_ImportECCKeyPair, (HCONTAINER hContainer, PENVELOPEDKEYBLOB blob));
SKF_FUN_INFO(SKF_ECCSignData, (HCONTAINER hContainer, u8 *pbData, u32 ulDataLen,
				PECCSIGNATUREBLOB pSignature));
SKF_FUN_INFO(SKF_ECCVerify, (DEVHANDLE hDev , PECCPUBLICKEYBLOB pECCPubKeyBlob, u8 *pbData,
				u32 ulDataLen, PECCSIGNATUREBLOB pSignature));
SKF_FUN_INFO(SKF_ECCExportSessionKey, (HCONTAINER hContainer, u32 ulAlgId, 
				PECCPUBLICKEYBLOB pPubKey, PECCCIPHERBLOB pData, HANDLE *phSessionKey));
SKF_FUN_INFO(SKF_ExtECCEncrypt, (DEVHANDLE hDev, PECCPUBLICKEYBLOB pECCPubKeyBlob, 
				u8* pbPlainText,	u32 ulPlainTextLen, PECCCIPHERBLOB pCipherText));
SKF_FUN_INFO(SKF_ExtECCDecrypt, (DEVHANDLE hDev, PECCPRIVATEKEYBLOB pECCPriKeyBlob,
				PECCCIPHERBLOB pCipherText, u8* pbPlainText, u32* pulPlainTextLen));
SKF_FUN_INFO(SKF_ExtECCSign, (DEVHANDLE hDev, PECCPRIVATEKEYBLOB pECCPriKeyBlob,
				u8* pbData, u32 ulDataLen, PECCSIGNATUREBLOB pSignature));
SKF_FUN_INFO(SKF_ExtECCVerify, (DEVHANDLE hDev, PECCPUBLICKEYBLOB pECCPubKeyBlob,
				u8* pbData, u32 ulDataLen, PECCSIGNATUREBLOB pSignature));
#ifdef SKF_FOR_NR
SKF_FUN_INFO(SKF_GenerateAgreementDataWithECC, (HCONTAINER hContainer, u32 ulAlgId,
			 PECCPUBLICKEYBLOB pTempECCPubKeyBlob,HANDLE *phAgreementHandle));
#else
SKF_FUN_INFO(SKF_GenerateAgreementDataWithECC, (HCONTAINER hContainer, u32 ulAlgId,
				PECCPUBLICKEYBLOB pTempECCPubKeyBlob,u8* pbID, u32 ulIDLen,
				HANDLE *phAgreementHandle));
#endif
SKF_FUN_INFO(SKF_GenerateAgreementDataAndKeyWithECC, (HANDLE hContainer, u32 ulAlgId,
				PECCPUBLICKEYBLOB pSponsorECCPubKeyBlob, PECCPUBLICKEYBLOB pSponsorTempECCPubKeyBlob,
				PECCPUBLICKEYBLOB pTempECCPubKeyBlob, u8* pbID, u32 ulIDLen, u8 *pbSponsorID,
				u32 ulSponsorIDLen, HANDLE *phKeyHandle));
#ifdef SKF_FOR_NR
SKF_FUN_INFO(SKF_GenerateKeyWithECC, (HANDLE hAgreementHandle, PECCPUBLICKEYBLOB pECCPubKeyBlob,
			 PECCPUBLICKEYBLOB pTempECCPubKeyBlob, u8* pbIDA, u32 ulIDALen, u8* pbID, u32 ulIDLen,HANDLE *phKeyHandle));
#else
SKF_FUN_INFO(SKF_GenerateKeyWithECC, (HANDLE hAgreementHandle, PECCPUBLICKEYBLOB pECCPubKeyBlob,
				PECCPUBLICKEYBLOB pTempECCPubKeyBlob, u8* pbID, u32 ulIDLen, HANDLE *phKeyHandle));
#endif
SKF_FUN_INFO(SKF_ExportPublicKey, (HCONTAINER hContainer, BOOL bSignFlag, u8* pbBlob,
				u32* pulBlobLen));

SKF_FUN_INFO(SKF_ImportSessionKey, (HCONTAINER hContainer, u32 ulAlgId,u8 *pbWrapedData,
				u32 ulWrapedLen, HANDLE *phKey));
SKF_FUN_INFO(SKF_SetSymmKey, (DEVHANDLE hDev, u8* pbKey, u32 ulAlgID, HANDLE* phKey));
SKF_FUN_INFO(SKF_EncryptInit, (HANDLE hKey, BLOCKCIPHERPARAM Param));
SKF_FUN_INFO(SKF_EncryptUpdate, (HANDLE hKey, u8* pbData, u32 ulDataLen, u8*pbEncrypt,
				u32* pulEncryptLen));
SKF_FUN_INFO(SKF_EncryptFinal, (HANDLE hKey, u8*pbEncrypt,u32* pulEncryptLen));
SKF_FUN_INFO(SKF_Encrypt, (HANDLE hKey, u8* pbData, u32 ulDataLen, u8*pbEncrypt,
				u32* pulEncryptLen));
SKF_FUN_INFO(SKF_DecryptInit, (HANDLE hKey, BLOCKCIPHERPARAM Param));
SKF_FUN_INFO(SKF_DecryptUpdate, (HANDLE hKey, u8* pbData, u32 ulDataLen, u8*pbDecrypt,
				u32* pulDecryptLen));
SKF_FUN_INFO(SKF_DecryptFinal, (HANDLE hKey, u8*pbDecrypt, u32* pulDecryptLen));
SKF_FUN_INFO(SKF_Decrypt, (HANDLE hKey, u8* pbData, u32 ulDataLen, u8*pbDecrypt,
				u32* pulDecryptLen));
SKF_FUN_INFO(SKF_DigestInit, (DEVHANDLE hDev, u32 ulAlgID,  PECCPUBLICKEYBLOB pPubKey, 
				u8 *pucID, u32 ulIDLen, HANDLE *phHash));
SKF_FUN_INFO(SKF_DigestUpdate, (HANDLE hHash, u8* pbData, u32 ulDataLen));
SKF_FUN_INFO(SKF_DigestFinal, (HANDLE hHash, u8* pbDigest, u32* pulDigestLen));
SKF_FUN_INFO(SKF_Digest, (HANDLE hHash, u8* pbData, u32 ulDataLen, u8* pbDigest, 
				u32* pulDigestLen));
SKF_FUN_INFO(SKF_MacInit, (HANDLE hKey, BLOCKCIPHERPARAM* pMacParam, HANDLE* phMac));
SKF_FUN_INFO(SKF_MacUpdate, (HANDLE hMac, u8* pbData, u32 ulDataLen));
SKF_FUN_INFO(SKF_MacFinal, (HANDLE hMac, u8* pbMac, u32* pulMacLen));
SKF_FUN_INFO(SKF_Mac, (HANDLE hMac, u8* pbData, u32 ulDataLen, u8* pbMac, u32* pulMacLen));
SKF_FUN_INFO(SKF_CloseHandle, (HANDLE hHandle));

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////// VENDOR DEFINED FUNCTIONS ////////////////////////////////////
#ifdef ANDROID
SKF_FUN_INFO(V_SetAppPath, (const char* szAppPath));
#endif

SKF_FUN_INFO(V_GenerateKey, (HCONTAINER hContainer, u32 ulAlgId, HANDLE *phSessionKey));
SKF_FUN_INFO(V_ECCExportSessionKeyByHandle, (HANDLE hSessionKey, 
			 ECCPUBLICKEYBLOB *pPubKey,PECCCIPHERBLOB pbData));
SKF_FUN_INFO(V_RSAExportSessionKeyByHandle, (HANDLE hSessionKey, 
			 RSAPUBLICKEYBLOB *pPubKey, u8 *pbData, u32 *pulDataLen));
SKF_FUN_INFO(V_ECCPrvKeyDecrypt, (HCONTAINER hContainer, u32 ulKeySpec,
			 PECCCIPHERBLOB pCipherText, u8 *pbData, u32 *pulDataLen));
SKF_FUN_INFO(V_RSAPrvKeyDecrypt, (HCONTAINER hContainer, u8 *pbCipherData, 
			 u32 ulCipherDataLen, u8 *pbData, u32 *pbDataLen));

#define V_F_KEY_BITS_256		0x00000001
#define V_F_KEY_BITS_512		0x00000002
#define V_F_KEY_BITS_1024		0x00000003
#define V_F_KEY_BITS_2048		0x00000004
#define V_F_KEY_BITS_MASK		0x0000000F
#define V_F_KEY_ALGO_RSA		0x00000010
#define V_F_KEY_ALGO_SM2		0x00000020
#define V_F_KEY_ALGO_MASK		0x00000030
#define V_F_KEY_USAGE_SIGN		0x00000040
#define V_F_KEY_LITTLE_ENDIAN	0x00000080

SKF_FUN_INFO(V_ImportKeyPair, (HCONTAINER hContainer, u32 ulFlags, u8 *pbKeyData, 
			 u32 ulKeyData));

SKF_FUN_INFO(V_Cipher, (DEVHANDLE hDev, CIPHER_PARAM* pParam, u8* pbData, u32 *pcbData, u32 cbBuf));

//-----------------------------------------------------------------------------------------------//
typedef struct func_list_st
{
	VERSION										version;
#define SKF_DEF_FUN_T(name) __PASTE(P_,name)	name
#ifdef ANDROID
	SKF_DEF_FUN_T(V_SetAppPath);
#endif
	SKF_DEF_FUN_T(SKF_WaitForDevEvent);
	SKF_DEF_FUN_T(SKF_CancelWaitForDevEvent);
	SKF_DEF_FUN_T(SKF_EnumDev);
	SKF_DEF_FUN_T(SKF_ConnectDev);
	SKF_DEF_FUN_T(SKF_DisConnectDev);
	SKF_DEF_FUN_T(SKF_GetDevState);
	SKF_DEF_FUN_T(SKF_SetLabel);
	SKF_DEF_FUN_T(SKF_GetDevInfo);
	SKF_DEF_FUN_T(SKF_LockDev);
	SKF_DEF_FUN_T(SKF_UnlockDev);
	SKF_DEF_FUN_T(SKF_Transmit);

	SKF_DEF_FUN_T(SKF_ChangeDevAuthKey);
	SKF_DEF_FUN_T(SKF_DevAuth);
	SKF_DEF_FUN_T(SKF_ChangePIN);
	SKF_DEF_FUN_T(SKF_GetPINInfo);
	SKF_DEF_FUN_T(SKF_VerifyPIN);
	SKF_DEF_FUN_T(SKF_UnblockPIN);
	SKF_DEF_FUN_T(SKF_ClearSecureState);

	SKF_DEF_FUN_T(SKF_CreateApplication);
	SKF_DEF_FUN_T(SKF_EnumApplication);
	SKF_DEF_FUN_T(SKF_DeleteApplication);
	SKF_DEF_FUN_T(SKF_OpenApplication);
	SKF_DEF_FUN_T(SKF_CloseApplication);

	SKF_DEF_FUN_T(SKF_CreateFile);
	SKF_DEF_FUN_T(SKF_DeleteFile);
	SKF_DEF_FUN_T(SKF_EnumFiles);
	SKF_DEF_FUN_T(SKF_GetFileInfo);
	SKF_DEF_FUN_T(SKF_ReadFile);
	SKF_DEF_FUN_T(SKF_WriteFile);

	SKF_DEF_FUN_T(SKF_CreateContainer);
	SKF_DEF_FUN_T(SKF_DeleteContainer);
	SKF_DEF_FUN_T(SKF_OpenContainer);
	SKF_DEF_FUN_T(SKF_CloseContainer);
	SKF_DEF_FUN_T(SKF_EnumContainer);
	SKF_DEF_FUN_T(SKF_GetContainerType);
	SKF_DEF_FUN_T(SKF_ImportCertificate);
	SKF_DEF_FUN_T(SKF_ExportCertificate);

	SKF_DEF_FUN_T(SKF_GenRandom);
	SKF_DEF_FUN_T(SKF_GenExtRSAKey);
	SKF_DEF_FUN_T(SKF_GenRSAKeyPair);
	SKF_DEF_FUN_T(SKF_ImportRSAKeyPair);
	SKF_DEF_FUN_T(SKF_RSASignData);
	SKF_DEF_FUN_T(SKF_RSAVerify);
	SKF_DEF_FUN_T(SKF_RSAExportSessionKey);
	SKF_DEF_FUN_T(SKF_ExtRSAPubKeyOperation);
	SKF_DEF_FUN_T(SKF_ExtRSAPriKeyOperation);
	SKF_DEF_FUN_T(SKF_GenECCKeyPair);
	SKF_DEF_FUN_T(SKF_ImportECCKeyPair);
	SKF_DEF_FUN_T(SKF_ECCSignData);
	SKF_DEF_FUN_T(SKF_ECCVerify);
	SKF_DEF_FUN_T(SKF_ECCExportSessionKey);
	SKF_DEF_FUN_T(SKF_ExtECCEncrypt);
	SKF_DEF_FUN_T(SKF_ExtECCDecrypt);
	SKF_DEF_FUN_T(SKF_ExtECCSign);
	SKF_DEF_FUN_T(SKF_ExtECCVerify);
	SKF_DEF_FUN_T(SKF_GenerateAgreementDataWithECC);
	SKF_DEF_FUN_T(SKF_GenerateAgreementDataAndKeyWithECC);
	SKF_DEF_FUN_T(SKF_GenerateKeyWithECC);
	SKF_DEF_FUN_T(SKF_ExportPublicKey);

	SKF_DEF_FUN_T(SKF_ImportSessionKey);
	SKF_DEF_FUN_T(SKF_SetSymmKey);
	SKF_DEF_FUN_T(SKF_EncryptInit);
	SKF_DEF_FUN_T(SKF_EncryptUpdate);
	SKF_DEF_FUN_T(SKF_EncryptFinal);
	SKF_DEF_FUN_T(SKF_Encrypt);
	SKF_DEF_FUN_T(SKF_DecryptInit);
	SKF_DEF_FUN_T(SKF_DecryptUpdate);
	SKF_DEF_FUN_T(SKF_DecryptFinal);
	SKF_DEF_FUN_T(SKF_Decrypt);
	SKF_DEF_FUN_T(SKF_DigestInit);
	SKF_DEF_FUN_T(SKF_DigestUpdate);
	SKF_DEF_FUN_T(SKF_DigestFinal);
	SKF_DEF_FUN_T(SKF_Digest);
	SKF_DEF_FUN_T(SKF_MacInit);
	SKF_DEF_FUN_T(SKF_MacUpdate);
	SKF_DEF_FUN_T(SKF_MacFinal);
	SKF_DEF_FUN_T(SKF_Mac);
	SKF_DEF_FUN_T(SKF_CloseHandle);

	SKF_DEF_FUN_T(V_GenerateKey);
	SKF_DEF_FUN_T(V_ECCExportSessionKeyByHandle);
	SKF_DEF_FUN_T(V_RSAExportSessionKeyByHandle);
	SKF_DEF_FUN_T(V_ECCPrvKeyDecrypt);
	SKF_DEF_FUN_T(V_RSAPrvKeyDecrypt);
	SKF_DEF_FUN_T(V_ImportKeyPair);
	SKF_DEF_FUN_T(V_Cipher);
#undef SKF_DEF_FUN_T

}SKF_FUNCLIST,*PSKF_FUNCLIST;

SKF_FUN_INFO(SKF_GetFuncList,(PSKF_FUNCLIST* pFuncList));

#ifdef __cplusplus
};
#endif

#endif  /*__SKF_FUNC_H__*/
