import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class PermissionService {
  static Future<bool> requestStoragePermission(BuildContext context) async {
    // 检查当前权限状态
    var status = await Permission.storage.status;

    if (status.isGranted) {
      return true;
    }

    // 请求权限
    status = await Permission.storage.request();

    if (status.isDenied) {
      // 如果用户拒绝了权限，显示解释对话框
      if (context.mounted) {
        final shouldShowRationale = await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('需要存储权限'),
                content: const Text('下载视频需要存储权限，请在设置中允许访问存储。'),
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
          // 打开应用设置页面
          await openAppSettings();
        }
      }
      return false;
    }

    return status.isGranted;
  }

  static Future<bool> checkStoragePermission() async {
    return await Permission.storage.isGranted;
  }
}
