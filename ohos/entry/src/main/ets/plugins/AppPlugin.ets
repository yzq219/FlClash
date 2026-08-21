import {
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';
import { bundleManager } from '@kit.AbilityKit';
import { image } from '@kit.ImageKit';
import { util } from '@kit.ArkTS';
import EntryAbility from '../entryability/EntryAbility';

export default class AppPlugin implements FlutterPlugin, MethodCallHandler {
  private parent: EntryAbility
  private channel: MethodChannel | undefined
  private packageIconCache: Map<string, string> = new Map()
  private set excludeFromRecent(excluded: boolean) {
    AppStorage.setOrCreate('exclude_recent', excluded)
  }

  constructor(entryAbility: EntryAbility) {
    this.parent = entryAbility
  }

  getUniqueClassName(): string {
    return "AppPlugin"
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), "com.follow.clash/app")
    this.channel.setMethodCallHandler(this)
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null)
    }
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    if (call.method === "moveTaskToBack") {
      this.parent.handleMoveTaskToBack(result)
    } else if (call.method === "updateExcludeFromRecents") {
      this.excludeFromRecent = (call.args as Map<string, boolean>).get('value') as boolean
      result.success(true)
    } else if (call.method === "initShortcuts") {
      result.success(true)
    } else if (call.method === "getPackages") {
      this.parent.handleGetPackages(result)
    } else if (call.method === "getChinaPackageNames") {
      result.success("[]")
    } else if (call.method === "getPackageIcon") {
      this.handleGetPackageIcon(call, result)
    } else if (call.method === "tip") {
      result.success(true)
    } else {
      result.notImplemented()
    }
  }

  private async handleGetPackageIcon(call: MethodCall, result: MethodResult): Promise<void> {
    const packageName = (call.args as Map<string, string>).get('packageName')
    if (packageName == null || packageName.length === 0) {
      result.success("")
      return
    }
    const cachedIcon = this.packageIconCache.get(packageName)
    if (cachedIcon != null) {
      result.success(cachedIcon)
      return
    }
    try {
      const bundleInfo = await bundleManager.getBundleInfo(
        packageName,
        bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION,
      )
      const bundleContext = this.parent.context.createBundleContext(packageName)
      const drawableDescriptor = bundleContext.resourceManager.getDrawableDescriptor(bundleInfo.appInfo.iconId)
      const pixelMap = drawableDescriptor.getPixelMap()
      const imagePacker = image.createImagePacker()
      const packedIcon = await imagePacker.packing(pixelMap, {
        format: "image/png",
        quality: 90,
      })
      const encodedIcon = new util.Base64Helper().encodeToStringSync(new Uint8Array(packedIcon))
      this.packageIconCache.set(packageName, encodedIcon)
      result.success(encodedIcon)
    } catch (_) {
      result.success("")
    }
  }
}
