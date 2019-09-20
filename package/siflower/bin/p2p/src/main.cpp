
#include "slsdk.h"
#include <stdio.h>
#include <stdlib.h>
#include <getopt.h>
#include <string.h>

#include <iostream>
#include <string>

#define LOG printf


SLCLIENT g_client;
SLSESSION g_session = SLSESSION_INVAILD;
std::string* g_address = NULL;


void print_help() {
  printf( "help -hv -u -p\n" );
}


void print_version() {
  printf( "version 1.0\n" );
}

bool session_create( ESLSessionType plugin_type, SLSESSION* session, std::string& name, SLSESSION_CALLBACK callback );

void session_destroy( const SLSESSION& session );

class arguments {
public:
  void parse( int argc, char** argv );

  std::string openid;
  std::string openkey;
};


void _client_callback( SLCLIENT client, SLCLIENT_EVENT event, unsigned long custom ) {
  switch( event ) {
  case SLCLIENT_EVENT_ONCONNECT:
    LOG( "连接服务器成功\n" );
    break;

  case SLCLIENT_EVENT_ONDISCONNECT:
    LOG( "与服务器连接已断开\n" );
    break;

  case SLCLIENT_EVENT_ONLOGIN:
    {
      const char* s = SLGetClientAddress( client );
      if( s ) {
        *g_address = std::string( s, strlen( s ) );
      }

      LOG( "登录向日葵服务器成功(%s)\n", g_address->c_str() );
    }
    break;

  case SLCLIENT_EVENT_ONLOGINFAIL:
    LOG( "登录向日葵服务器失败\n" );
    break;

  default:
    break;
  }
}




int main( int argc, char** argv ) {
  // init arguments
  arguments args;
  args.parse( argc, argv );
  std::string addr;
  g_address = &addr;

  if( args.openid.empty() || args.openkey.empty() ) {
    LOG( "无效的openid/openkey\n" );
    return -1;
  }

  SLInitialize();
  g_client = SLCreateClient();
  if( g_client == SLCLIENT_INVAILD ) {
    LOG( "创建向日葵客户端失败.\n" );
    return -1;
  }

  if( !SLSetClientCallback( g_client, _client_callback, ( unsigned long )0 ) ) {
    LOG( "设置事件通知失败.\n" );
    return -1;
  }

  if( !SLLoginWithOpenID( g_client, args.openid.c_str(), args.openkey.c_str() ) ) {
    LOG( "登录服务器失败.\n" );
    return -1;
  }

  LOG( "初始化客户端成功!\n" );

  std::string action;
  while(std::getline(std::cin, action)) {
    if(action == "exit") {
      break;
    }

    if( action == "port" ) {
      session_destroy( g_session );
      std::string name;
      if( session_create( eSLSessionType_Port, &g_session, name, NULL ) ) {
        LOG( "创建会话成功:\n -a \"%s\" -s \"%s\"\n", g_address->c_str(), name.c_str() );
      }
    } else if( action == "desktop" ) {
      session_destroy( g_session );
      std::string name;
      if( session_create( eSLSessionType_Desktop, &g_session, name, NULL ) ) {
        LOG( "创建会话成功:\n -a \"%s\" -s \"%s\"\n", g_address->c_str(), name.c_str() );
      }

    }
  }

  SLUninitialize();

  return 0;
}

bool session_create( ESLSessionType plugin_type, SLSESSION* session, std::string& name, SLSESSION_CALLBACK callback ) {
  SLSESSION s = SLCreateClientSession( g_client, plugin_type );
  if( s == SLSESSION_INVAILD ) {
    LOG( "创建会话失败\n" );
    return false;
  }

  if( callback ) {
    SLSESSION_CALLBACK_PROP prop;
    prop.pfnCallback = callback;
    prop.nCustom = 0;
    SLSetClientSessionOpt( g_client, s, eSLSessionOpt_callback, ( const char* )&prop, sizeof( prop ) );
  }

  const char* sname = SLGetClientSessionName( g_client, s );
  if( sname ) {
    name = std::string( sname, strlen( sname ) );
  }

  *session = s;
  return true;
}

void session_destroy( const SLSESSION& session ) {
  if( session == SLSESSION_INVAILD ) {
    return;
  }

  if( !SLDestroyClientSession( g_client, session ) ) {
    LOG( "销毁会话失败\n" );
  } else {
    LOG( "销毁会话成功\n" );
  }
}



void arguments::parse( int argc, char** argv ) {
  static struct option long_opts[] = {
    { "help",    no_argument, NULL, 'h' },
    { "version", no_argument, NULL, 'v' },
    { "openid",  required_argument, NULL, 'u' },
    { "openkey", required_argument, NULL, 'p' },
    { 0, 0, 0, 0 }
  };

  int c;
  while( ( c = getopt_long( argc, argv, "hvu:p:", long_opts, NULL ) ) != -1 ) {
    switch( ( signed char )c  ) {
    case 'h':
      print_help();
      exit( 0 );
      break;

    case 'v':
      print_version();
      exit( 0 );
      break;

    case 'u':
      openid = std::string( optarg, strlen( optarg ) );
      break;

    case 'p':
      openkey = std::string( optarg, strlen( optarg ) );
      break;

    default:
      break;
    }
  }
}
