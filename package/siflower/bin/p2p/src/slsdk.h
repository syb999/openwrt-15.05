/** \file slsdk.h
 * \brief Sunlogin SDK api define
 * \author Oray
 */

#ifndef __ORAY_SLSDK_H__
#define __ORAY_SLSDK_H__


/** \brief SLAPI */
#ifdef WIN32
#define WIN32_LEAN_AND_MEAN
#define SLAPI __stdcall
#include <windows.h>
#else
#define SLAPI
#endif

#ifdef __cplusplus
extern "C" {
#endif

/**
 * \brief SLAPI版本号
 */
#define SLAPI_VERSION 1

/**
 * \brief 被控制端环境
 */
typedef unsigned long SLCLIENT;

/**
 * \brief 控制端环境
 */
typedef unsigned long SLREMOTE;

/**
 * \brief 被控制端会话
 */
typedef unsigned int SLSESSION;

/** \brief 64 and 32 integer size type definde
 *
 */
#ifndef _WIN32
typedef unsigned long long SLUINT64;
typedef long long SLINT64;
#else
typedef unsigned __int64 SLUINT64;
typedef __int64 SLINT64;
#endif
typedef unsigned int SLUINT32;
typedef int SLINT32;


/**
 * \brief 无效被控制端环境
 */
#define SLCLIENT_INVAILD 0

/**
 * \brief 无效控制端环境
 */
#define SLREMOTE_INVAILD 0

/**
 * \brief 无效会话
 */
#define SLSESSION_INVAILD (-1)

/** \brief Error code
 *
 */
enum SLERRCODE {
  //成功
  SLERRCODE_SUCCESSED = 0, 

  //内部错误
  SLERRCODE_INNER = 1, 

  //未初始化
  SLERRCODE_UNINITIALIZED = 2, 

  //参数错误
  SLERRCODE_ARGS = 3,

  //不支持
  SLERRCODE_NOTSUPPORT = 4,

  //网络连接失败
  SLERRCODE_CONNECT_FAILED = 5, 

  //网络连接超时
  SLERRCODE_CONNECT_TIMEOUT = 6,

  //会话不存在
  SLERRCODE_SESSION_NOTEXIST = 7,

  //会话溢出
  SLERRCODE_SESSION_OVERFLOW = 8,

  //会话类型错误
  SLERRCODE_SESSION_WRONGTYPE = 9,

  //OPENID过期
  SLERRCODE_EXPIRED = 10,
};

/** \brief Session's option
 *
 */
enum ESLSessionOpt {
  eSLSessionOpt_window = 1,					/*!< Window container */
  eSLSessionOpt_callback = 2,				/*!< Callback */
  eSLSessionOpt_deviceSource = 3,			/*!< Device's source */
  eSLSessionOpt_connected = 4,				/*!< Connect status */
  eSLSessionOpt_desktopctrl_listener = 5,	/*!< Desktop control listener */
  eSLSessionOpt_ipport = 6,					/*!< Port forward ip and port */
  eSLSessionOpt_savepath = 7, /*!< File transfer save path */
};

/** \brief Session's event
 *
 */
enum ESLSessionEvent {
  eSLSessionEvent_OnConnected = 1, 		  /*!< Session connected event */
  eSLSessionEvent_OnDisconnected = 2, 	/*!< Session disconnected event */
  eSLSessionEvent_OnDisplayChanged = 3,	/*!< Display resolution is changed */
  eSLSessionEvent_OnNewFiletrans = 4,   /*!< Recv a new file transfer item */
};

/** \brief Session callback
 *
 * \param session - Id of the session
 * \param evt - Type of event
 * \param sdata - String format data
 * \param custom - User data bind to the callback
 */
typedef void ( SLAPI *SLSESSION_CALLBACK )( SLSESSION session, ESLSessionEvent evt, const char* sdata, unsigned long custom );

/**
 * \brief 会话回调属性
 */
typedef struct tagSLSESSION_CALLBACK_PROP {
	SLSESSION_CALLBACK pfnCallback;	//!< 回调函数
	unsigned long nCustom;			//!< 自定义数据
} SLSESSION_CALLBACK_PROP;

/** \brief 会话类型
 *
 */
enum ESLSessionType {
	eSLSessionType_Desktop,		/*!< Remote Desktop session */
	eSLSessionType_File,		/*!< Remote File session */
	eSLSessionType_Cmd,			/*!< Remote CMD session */
	eSLSessionType_Sound,		/*!< Remote sound session */
	eSLSessionType_DataTrans,	/*!< Data transfer session */
	eSLSessionType_DesktopView,	/*!< Remote desktop view mode session */
	eSLSessionType_Port,		/*!< Port forward session */
  eSLSessionType_FileTrans, /*!< File transfer session */
};

enum SLProxyType
{
	SLProxy_None,
	SLProxy_HTTP,
	SLProxy_Socks5,
	SLProxy_Socks4,
	SLProxy_IE,
};

/**
* 代理类型
*/
struct SLPROXY_INFO
{
	char ip[20];
	char port[10];
	char user[20];
	char pwd[20];
	char domain[200];
	SLProxyType type;	//ProxyType		
};


typedef enum __slmode {
  UI = 0,
  SERVICE = 1,
} SLMODE;


/** \brief Initialize SLSDK's enviroment
 *
 * \return 是否初始化成功
 */
bool SLAPI SLInitialize();

/*
 * \brief 退出SLAPI环境
 * \desc 建议在整个进程退出前调用，以释放SLAPI环境所使用的资源
 * \return 是否退出成功
 */
bool SLAPI SLUninitialize();

/*
 * \brief 获取最后的错误码
 * \return 返回SLERRCODE错误码
 */
SLERRCODE SLAPI SLGetLastError();

/*
 * \brief 设置最后的错误码
 * \param errCode 错误码
 * \return 是否设置成功
 */
bool SLAPI SLSetLastError(SLERRCODE errCode);

/*
 * \brief 获取错误码详细说明
 * \return 详细信息，如果错误码不存在则返回“未知错误”
 */
const char* SLAPI SLGetErrorDesc(SLERRCODE errCode);




/** \brief 被控制端事件
 *
 */
enum SLCLIENT_EVENT
{
	SLCLIENT_EVENT_ONCONNECT = 0,	//!< 连接成功
	SLCLIENT_EVENT_ONDISCONNECT,	//!< 断开连接
	SLCLIENT_EVENT_ONLOGIN,			//!< 登录成功
	SLCLIENT_EVENT_ONLOGINFAIL,		//!< 登录失败
};

/** \brief Create a new client with ui mode
 *
 * \return if success return a new instance, else SLCLIENT_INVAILD
 */
SLCLIENT SLAPI SLCreateClient(void);

/** \brief Create a new client with service mode or ui mode
 *
 * \param mode - Client's mode {@see SLMODE}
 * \return if success return a new instance, else SLCLIENT_INVAILD
 */
SLCLIENT SLAPI SLCreateClientEx( SLMODE mode );


/*
 * \brief 销毁一个被控制端环境
 * \param client 要销毁的被控制端环境
 */
bool SLAPI SLDestroyClient( SLCLIENT client );

/*
 * \brief 被控制端回调事件
 * \param client 被控制端环境
 * \param event 事件
 * \param custom 用户自定义参数
 */
typedef void (SLAPI *SLCLIENT_CALLBACK)(SLCLIENT client, SLCLIENT_EVENT event, unsigned long custom);

/*
 * \brief 设置被控制端事件回调函数
 * \param client 被控制端环境
 * \param pfnCallback 回调函数地址
 * \param custom 用户自定义参数，回调时内部程序会将此参数一并回调
 * \return 是否设置成功
 */
bool SLAPI SLSetClientCallback(SLCLIENT client, SLCLIENT_CALLBACK pfnCallback, unsigned long custom);

/*
 * \brief 被控制端登录服务器
 * \param client 被控制端环境
 * \param pstrOpenID 开发者的ID号
 * \param pstrOpenKey 开发者ID对应的验证码
 * \return 是否登录成功
 */
bool SLAPI SLClientLoginWithOpenID(SLCLIENT client, const char* pstrOpenID, const char* pstrOpenKey);
  
/** \brief Short name for SLClientLoginWithOpenID
 *
 */
bool SLAPI SLLoginWithOpenID(SLCLIENT client, const char* pstrOpenID, const char* pstrOpenKey);

  
/*
 * \brief 被控制端登录服务器
 * \param client 被控制端环境
 * \param szAddr 服务器地址
 * \param szLic lincense
 * \return 是否登录成功
 */
bool SLAPI SLClientLoginWithLicense(SLCLIENT client, const char* szAddr, const char* szLic);

/*
 * \brief 被控制端是否登录中
 * \param client 被控制端环境
 */
bool SLAPI SLClientIsOnLoginned(SLCLIENT client);
/*
 * \brief 在被控制端环境中创建一个会话
 * \param client 被控制端环境
 * \return 会话值，如果创建失败，则返回SLSESSION_INVAILD
 */
SLSESSION SLAPI SLCreateClientSession(SLCLIENT client, ESLSessionType eType);

/*
 * \brief 销毁一个会话
 * \param client 被控制端环境
 * \param session 会话
 * \return 是否销毁成功
 */
bool SLAPI SLDestroyClientSession(SLCLIENT client, SLSESSION session);

/*
* \brief 打开被控端日志
* \param client 被控制端环境
* \param path 路径
* \return 是否设置成功
*/
bool SLAPI SLOpenClientLog(SLCLIENT client, const char* path);

/*
* \brief 设置代理
* \param client 被控制端环境
* \param proxy 代理设置
* \return 是否设置成功
*/
bool SLAPI SLSetClientProxy(SLCLIENT client, const SLPROXY_INFO& proxy);

/*
 * \brief 枚举被控端当前有多少个会话
 * \param client 被控制端环境
 * \param pSessionArray 会话数组（输出参数）
 * \param nArraySize 数组长度
 * \return 一个有多少个会话
 */
unsigned int SLAPI SLEnumClientSession(SLCLIENT client, SLSESSION* pSessionArray, unsigned int nArraySize);

/*
 * \brief 获取被控制端连接地址
 * \remark 必须在登录成功后再获取才能获取正确的值，即当回调事件SLCLIENT_EVENT_ONLOGIN发生后调用。通过该值主控制端才能使用该会话的服务
 * \return 地址
 */
const char* SLAPI SLGetClientAddress(SLCLIENT client);

/*
 * \brief 获取被控制端某个会话的值
 * \remark 通过该值主控制端才能使用该会话的服务
 * \return 会话值，如果会话不存在则返回NULL
 */
const char* SLAPI SLGetClientSessionName(SLCLIENT client, SLSESSION session);

/*
 * \brief 被控制端某个会话发送数据
 * \param client 被控制端环境
 * \param session 会话
 * \param lpData 发送的数据
 * \param nLen 发送的数据长度
 * \return 发送的字节数
 * \remark 目前只适用于DataTrans类型的会话
 */
unsigned long SLAPI SLClientSessionSendData(SLCLIENT client, SLSESSION session, const char* lpData, unsigned long nLen);

/*
 * \brief 被控制端某个会话接收数据
 * \param client 被控制端环境
 * \param session 会话
 * \param lpData 接收数据的缓冲区
 * \param nLen 准备接收的数据长度
 * \return 实际接收到的字节数
 * \remark 目前只适用于DataTrans类型的会话
 */
unsigned long SLAPI SLClientSessionRecvData(SLCLIENT client, SLSESSION session, char* lpData, unsigned long nLen);

/*
 * \brief 获取被控制端某个会话某个属性值
 * \return 是否获取成功
 */
bool SLAPI SLGetClientSessionOpt(SLCLIENT client, SLSESSION session, ESLSessionOpt eOpt, char* pOptVal, unsigned int nOptLen);

/*
 * \brief 设置被控制端某个会话某个属性值
 * \return 是否设置成功
 */
bool SLAPI SLSetClientSessionOpt(SLCLIENT client, SLSESSION session, ESLSessionOpt eOpt, const char* pOptVal, unsigned int nOptLen);

/*
 * \brief 开启WEB服务
 * \return 是否成功
 */
bool SLAPI SLStartWebServer(SLCLIENT client, unsigned int nPort=0);

/*
 * \brief 关闭WEB服务
 * \return 是否成功
 */
bool SLAPI SLStopWebServer(SLCLIENT client);

/*
 * \brief web服务过滤方法，返回true表示已经处理了当前事件，底层将不会再处理
 * \param client 被控制端环境
 * \param data 指向数据的指针
 * \param size 数据长度
 */
typedef bool (SLAPI *SLWEB_FILTER)(SLCLIENT client,const void* data,unsigned int size);

/*
 * \brief 设置web服务过滤方法
 * \param client 被控制端环境
 * \param filter 函数指针
 */
bool SLAPI SlSetWebServerFilter(SLCLIENT client,SLWEB_FILTER filter);

/*
 * \brief 向web客户端发送数据
 * \param client 被控制端环境
 * \param data 指向数据的指针
 * \param size 数据长度
 */
bool SLAPI SlWebServerSend( SLCLIENT client,const void* pdata,unsigned int size );

/** \brief Send file to peer
 *
 * \param client - Client
 * \param session - Specified session
 * \param filepath - File to be sent 
 * \param resume - Resume transfer
 *
 * \return transfer id of file.
 */
SLUINT32 SLAPI SLClientSendFile( SLCLIENT client, SLSESSION session, const wchar_t* filepath, bool resume );


/** \brief Kill the file item with fid
 *
 * \param client - Client
 * \param session - Specified session
 * \param fid - Id of file item 
 *
 * \return true is ok else failed.
 */
bool SLAPI SLClientKillFile( SLCLIENT client, SLSESSION session, SLUINT32 fid );


/** \brief Get name of file item with fid
 *
 * \param client - Client
 * \param session - Specified session
 * \param fid - Id of file item 
 *
 * \return Name of file item
 */
const wchar_t* SLAPI SLClientGetFileName( SLCLIENT client, SLSESSION session, SLUINT32 fid );

/** \brief Get file size  
 *
 * \param client - Client
 * \param session - Specified session
 * \param fid - Id of file item 
 *
 * \return File item's size.
 */
SLUINT64 SLAPI SLClientGetFileSize( SLCLIENT client, SLSESSION session, SLUINT32 fid );


/** \brief Get file transfered
 *
 * \param client - Client
 * \param session - Specified session
 * \param fid - Id of file item 
 *
 * \return File item's transfered size.
 */
SLUINT64 SLAPI SLClientGetFileTransfered(  SLCLIENT client, SLSESSION session, SLUINT32 fid );


/** \brief File state is in transfering or not
 *
 * \param client - Client 
 * \param session - Specified session
 * \param fid - Id of file item 
 *
 * \return true is transfering else not.
 */
bool SLAPI SLClientFileIsTransfering( SLCLIENT client, SLSESSION session, SLUINT32 fid );


/** \brief File state is done or not
 *
 * \param client - Client
 * \param session - Specified session
 * \param fid - Id of file item 
 *
 * \return true is done else not.
 */
bool SLAPI SLClientFileIsDone( SLCLIENT client, SLSESSION session, SLUINT32 fid );

/** \brief File state is killed or not
 *
 * \param client - Client
 * \param session - Specified session
 * \param fid - Id of file item 
 *
 * \return true is killed else not.
 */
bool SLAPI SLClientFileIsKilled( SLCLIENT client, SLSESSION session, SLUINT32 fid );



/************************************************************************/
/* 控制端相关API                                                        */
/************************************************************************/
/**
 * \brief 主控制端事件
 */
enum SLREMOTE_EVENT
{
  SLREMOTE_EVENT_ONCONNECT = 0, 		//!< 连接成功
  SLREMOTE_EVENT_ONDISCONNECT, 			//!< 断开连接
  SLREMOTE_EVENT_ONDISCONNECT_FOR_FULL, //!< 断开连接(因为连接数满了)  
};

/*
 * \brief 创建一个控制端环境
 * \return 返回被控制端环境值，如果创建失败则返回SLREMOTE_INVAILD
 */
SLREMOTE SLAPI SLCreateRemote(void);

/*
 * \brief 销毁一个控制端环境
 * \param remote 控制端环境
 * \return 是否销毁成功
 */
bool SLAPI SLDestroyRemote(SLREMOTE remote);

/*
* \brief 打开控制端日志
* \param remote 控制端环境
* \param path 路径
* \return 是否设置成功
*/
bool SLAPI SLOpenRemoteLog(SLREMOTE remote, const char* path);

/*
* \brief 设置代理
* \param client 被控制端环境
* \param remote 控制端环境
* \return 是否设置成功
*/
bool SLAPI SLSetRemoteProxy(SLREMOTE remote, const SLPROXY_INFO& proxy);

/*
 * \brief 主控制端回调事件
 * \param remote 主控制端环境
 * \param event 事件
 * \param custom 用户自定义参数
 */
typedef void (SLAPI *SLREMOTE_CALLBACK)(SLREMOTE remote, SLSESSION session, SLREMOTE_EVENT event, unsigned long custom);

/*
 * \brief 设置主控制端事件回调函数
 * \param remote 主控制端环境
 * \param pfnCallback 回调函数地址
 * \param custom 用户自定义参数，回调时内部程序会将此参数一并回调
 * \return 是否设置成功
 */
bool SLAPI SLSetRemoteCallback(SLREMOTE remote, SLREMOTE_CALLBACK pfnCallback, unsigned long custom);

/*
 * \brief 创建主控制端会话
 * \param remote 控制端环境
 * \param eType 会话类型
 * \param pstrAddress 远程被控制端地址
 * \param pstrSession 远程桌面会话名
 * \return 会话
 */
SLSESSION SLAPI SLCreateRemoteSession(SLREMOTE remote, ESLSessionType eType, const char* pstrAddress, const char* pstrSession);

/*
 * \brief 创建主控制端空会话(无连接)
 * \param remote 控制端环境
 * \param eType 会话类型
 * \remark 和SLCreateRemoteSession不同的是创建一个空会话，不进行连接，后面必须再使用SLConnectRemoteSession来连接会话
 * \return 会话
 */
SLSESSION SLAPI SLCreateRemoteEmptySession(SLREMOTE remote, ESLSessionType eType);

/*
 * \brief 连接主控端会话
 * \param remote 控制端环境
 * \param session 会话
 * \param pstrAddress 远程被控制端地址
 * \param pstrSession 远程桌面会话名
 * \return 会话
 */
bool SLAPI SLConnectRemoteSession(SLREMOTE remote, SLSESSION session, const char* pstrAddress, const char* pstrSession);

/*
 * \brief 销毁一个会话
 * \param remote 控制端环境
 * \param session 会话
 * \return 是否销毁成功
 */
bool SLAPI SLDestroyRemoteSession(SLREMOTE remote, SLSESSION session);

/*
 * \brief 主控制端某个会话发送数据
 * \param remote 主控制端环境
 * \param session 会话
 * \param lpData 发送的数据
 * \param nLen 发送的数据长度
 * \return 发送的字节数
 * \remark 目前只适用于DataTrans类型的会话
 */
unsigned long SLAPI SLRemoteSessionSendData(SLREMOTE remote, SLSESSION session, const char* lpData, unsigned long nLen);

/*
 * \brief 主控制端某个会话接收数据
 * \param remote 主控制端环境
 * \param session 会话
 * \param lpData 接收数据的缓冲区
 * \param nLen 接收数据缓冲区长度
 * \return 实际接收到的字节数
 * \remark 目前只适用于DataTrans类型的会话
 */
unsigned long SLAPI SLRemoteSessionRecvData(SLREMOTE remote, SLSESSION session, char* lpData, unsigned long nLen);

/*
 * \brief 获取主控制端某个会话某个属性值
 * \return 是否设置成功
 */
bool SLAPI SLGetRemoteSessionOpt(SLREMOTE remote, SLSESSION session, ESLSessionOpt eOpt, char* pOptVal, unsigned int nOptLen);

/*
 * \brief 设置主控制端某个会话某个属性值
 * \return 是否设置成功
 */
bool SLAPI SLSetRemoteSessionOpt(SLREMOTE remote, SLSESSION session, ESLSessionOpt eOpt, const char* pOptVal, unsigned int nOptLen);

/*
 * \brief 设置远程桌面窗口的大小
 * \return 是否设置成功
 */
bool SLAPI SLSetDesktopSessionPos(SLREMOTE remote, SLSESSION session, int x,int y,int width,int height);

/*
 * \brief Show desktop window
 * \return 是否设置成功
 */
bool SLAPI SLSetDesktopSessionVisible( SLREMOTE remote, SLSESSION session );

  
/** \brief	Get original desktop size
 * \return	
 */
bool SLAPI SLGetDesktopSessionOriginSize( SLREMOTE remote, SLSESSION session, int* width, int* height );


/** \brief Start desktop record, Only one file in recording.
 * 
 * \param remote - Peer
 * \param session - Specified session
 * \param filepath - Desktop record file 
 *
 * \return true is ok else failed.
 */
bool SLAPI SLRemoteDesktopStartRecord( SLREMOTE remote, SLSESSION session, const char* filepath );


/** \brief Stop desktop record
 * 
 * \param remote - Peer
 * \param session - Specified session
 *
 */
void SLAPI SLRemoteDesktopStopRecord( SLREMOTE remote, SLSESSION session );





/** \brief Send file to peer
 *
 * \param remote - Peer
 * \param session - Specified session
 * \param filepath - File to be sent 
 * \param resume - Resume transfer
 *
 * \return transfer id of file.
 */
SLUINT32 SLAPI SLRemoteSendFile(SLREMOTE remote, SLSESSION session, const wchar_t* filepath, bool resume );


/** \brief Kill the file item with fid
 *
 * \param remote - Peer
 * \param session - Specified session
 * \param fid - Id of file item 
 *
 * \return true is ok else failed.
 */
bool SLAPI SLRemoteKillFile( SLREMOTE remote, SLSESSION session, SLUINT32 fid );

/** \brief Get name of file item with fid
 *
 * \param remote - Peer
 * \param session - Specified session
 * \param fid - Id of file item 
 *
 * \return Name of file item
 */
const wchar_t* SLAPI SLRemoteGetFileName( SLREMOTE client, SLSESSION session, SLUINT32 fid );


/** \brief Get file size  
 *
 * \param remote - Peer
 * \param session - Specified session
 * \param fid - Id of file item 
 *
 * \return File item's size.
 */
SLUINT64 SLAPI SLRemoteGetFileSize(  SLREMOTE remote, SLSESSION session, SLUINT32 fid );


/** \brief Get file transfered
 *
 * \param remote - Peer
 * \param session - Specified session
 * \param fid - Id of file item 
 *
 * \return File item's transfered size.
 */
SLUINT64 SLAPI SLRemoteGetFileTransfered(  SLREMOTE remote, SLSESSION session, SLUINT32 fid );


/** \brief File state is in transfering or not
 *
 * \param remote - Peer
 * \param session - Specified session
 * \param fid - Id of file item 
 *
 * \return true is transfering else not.
 */
bool SLAPI SLRemoteFileIsTransfering( SLREMOTE remote, SLSESSION session, SLUINT32 fid );


/** \brief File state is done or not
 *
 * \param remote - Peer
 * \param session - Specified session
 * \param fid - Id of file item 
 *
 * \return true is done else not.
 */
bool SLAPI SLRemoteFileIsDone( SLREMOTE remote, SLSESSION session, SLUINT32 fid );

/** \brief File state is killed or not
 *
 * \param remote - Peer
 * \param session - Specified session
 * \param fid - Id of file item 
 *
 * \return true is killed else not.
 */
bool SLAPI SLRemoteFileIsKilled( SLREMOTE remote, SLSESSION session, SLUINT32 fid );



#ifdef __cplusplus
}
#endif


#endif //__ORAY_SLSDK_H__
