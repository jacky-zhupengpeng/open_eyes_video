import 'dart:io';

import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:douban/network/interceptor/common_parameter_interceptor.dart';
import 'package:douban/network/proxy.dart';
import 'package:douban/utils/app_util.dart';
import 'file:///C:/Users/IDM-PC/Desktop/open_eyes_vide/lib/network/interceptor/dio_log_interceptor.dart';
import 'package:douban/utils/loading_utils.dart';
import 'code.dart';
import 'interceptor/response_interceptor.dart';
import 'result_data.dart';
import 'address.dart';

class HttpManager {
  static const CONTENT_TYPE_FORM = "application/x-www-form-urlencoded";

  static HttpManager _instance = HttpManager._internal();
  Dio _dio;

  static const CODE_SUCCESS = 200;
  static const CODE_TIME_OUT = -1;

  factory HttpManager() => _instance;

  ///通用全局单例，第一次使用时初始化
  HttpManager._internal({String baseUrl}) {
    if (null == _dio) {
      _dio = new Dio(new BaseOptions(
          baseUrl: Address.BASE_URL,
          connectTimeout: 60000,
          receiveTimeout: 60000,
          responseType: ResponseType.json,
          // validateStatus: (status) {
          //   // 不使用http状态码判断状态，使用AdapterInterceptor来处理（适用于标准REST风格）
          //   return true;
          // },
          headers: httpHeaders));
      _dio.interceptors.add(new DioLogInterceptor());
//      _dio.interceptors.add(new PrettyDioLogger());
      _dio.interceptors.add(new CommonParameterInterceptor());
      _dio.interceptors.add(new ResponseInterceptors());

      if (!AppUtil.isReleaseMode()) {
        (_dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
            (HttpClient client) {
          client.findProxy = (uri) {
            return "PROXY " + Proxy.HOST + ":" + Proxy.PORT;
          };
          client.badCertificateCallback =
              (X509Certificate cert, String host, int port) => true;
        };
      }
    }
  }

  static HttpManager getInstance({String baseUrl}) {
    if (baseUrl == null) {
      return _instance._normal();
    } else {
      return _instance._baseUrl(baseUrl);
    }
  }

  //用于指定特定域名
  HttpManager _baseUrl(String baseUrl) {
    if (_dio != null) {
      _dio.options.baseUrl = baseUrl;
    }
    return this;
  }

  //一般请求，默认域名
  HttpManager _normal() {
    if (_dio != null) {
      if (_dio.options.baseUrl != Address.BASE_URL) {
        _dio.options.baseUrl = Address.BASE_URL;
      }
    }
    return this;
  }

  ///通用的GET请求
  get(api, {params, withLoading = true}) async {
    if (withLoading) {
      LoadingUtils.show();
    }

    Response response;
    try {
      response = await _dio.get(api, queryParameters: params);
      if (withLoading) {
        LoadingUtils.dismiss();
      }
    } on DioError catch (e) {
      if (withLoading) {
        LoadingUtils.dismiss();
      }
      return resultError(e);
    }

    if (response.data is DioError) {
      return resultError(response.data['code']);
    }

    return response.data;
  }

  ///通用的POST请求
  post(api, {params, withLoading = true}) async {
    if (withLoading) {
      LoadingUtils.show();
    }

    Response response;

    try {
      response = await _dio.post(api, data: params);
      if (withLoading) {
        LoadingUtils.dismiss();
      }
    } on DioError catch (e) {
      if (withLoading) {
        LoadingUtils.dismiss();
      }
      return resultError(e);
    }

    if (response.data is DioError) {
      return resultError(response.data['code']);
    }

    return response.data;
  }
}

ResultData resultError(DioError e) {
  Response errorResponse;
  if (e.response != null) {
    errorResponse = e.response;
  } else {
    errorResponse = new Response(statusCode: 666);
  }
  if (e.type == DioErrorType.CONNECT_TIMEOUT ||
      e.type == DioErrorType.RECEIVE_TIMEOUT) {
    errorResponse.statusCode = Code.NETWORK_TIMEOUT;
  }
  return new ResultData(
      errorResponse.statusMessage, false, errorResponse.statusCode);
}

/// 自定义Header
Map<String, dynamic> httpHeaders = {
  "content-type": HttpManager.CONTENT_TYPE_FORM,
  "responseType": ResponseType.plain
};
