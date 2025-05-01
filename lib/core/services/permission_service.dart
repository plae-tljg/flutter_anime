import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io' show Platform;

class PermissionService {
  static Future<bool> requestStoragePermission(BuildContext context) async {
    if (Platform.isAndroid) {
      if (await _isAndroid13OrHigher()) {
        return await _requestMediaPermission(context);
      } else {
        return await _requestLegacyStoragePermission(context);
      }
    }
    return true;
  }

  static Future<bool> _isAndroid13OrHigher() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      return androidInfo.version.sdkInt >= 33;
    }
    return false;
  }

  static Future<bool> _requestMediaPermission(BuildContext context) async {
    var status = await Permission.videos.status;

    if (status.isGranted) {
      return true;
    }

    status = await Permission.videos.request();

    if (status.isDenied) {
      if (context.mounted) {
        final shouldShowRationale = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('需要视频访问权限'),
            content: const Text('访问视频需要相应的权限，请在设置中允许访问视频。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('去设置'),
              ),
            ],
          ),
        );

        if (shouldShowRationale == true) {
          await openAppSettings();
        }
      }
      return false;
    }

    return status.isGranted;
  }

  static Future<bool> _requestLegacyStoragePermission(
      BuildContext context) async {
    var status = await Permission.storage.status;

    if (status.isGranted) {
      return true;
    }

    status = await Permission.storage.request();

    if (status.isDenied) {
      if (context.mounted) {
        final shouldShowRationale = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('需要存储权限'),
            content: const Text('访问视频需要存储权限，请在设置中允许访问存储。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('去设置'),
              ),
            ],
          ),
        );

        if (shouldShowRationale == true) {
          await openAppSettings();
        }
      }
      return false;
    }

    return status.isGranted;
  }

  static Future<bool> checkStoragePermission() async {
    if (Platform.isAndroid) {
      if (await _isAndroid13OrHigher()) {
        return await Permission.videos.isGranted;
      } else {
        return await Permission.storage.isGranted;
      }
    }
    return true;
  }
}
