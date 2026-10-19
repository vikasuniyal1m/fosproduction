package dev.applicazza.flutter.plugins.whatsapp_stickers_plus

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ContentResolver
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.io.File


/** WhatsappStickersPlugin */
public class WhatsappStickersPlugin: FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private var context: Context? = null
  private var stickerPackList: List<StickerPack>? = null
  private var activity: Activity? = null
  private var pendingResult: Result? = null
  val ADD_PACK = 200

  private fun replySuccess(value: Any?) {
    val r = pendingResult ?: return
    pendingResult = null
    r.success(value)
  }

  private fun replyError(code: String, message: String) {
    val r = pendingResult ?: return
    pendingResult = null
    r.error(code, message, null)
  }

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "whatsapp_stickers_plus")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext
  }

  // This static function is optional and equivalent to onAttachedToEngine. It supports the old
  // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
  // plugin registration via this function while apps migrate to use the new Android APIs
  // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
  //
  // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
  // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
  // depending on the user's project. onAttachedToEngine or registerWith must both be defined
  // in the same class.
  companion object {

    private const val EXTRA_STICKER_PACK_ID = "sticker_pack_id"
    private const val EXTRA_STICKER_PACK_AUTHORITY = "sticker_pack_authority"
    private const val EXTRA_STICKER_PACK_NAME = "sticker_pack_name"

    @JvmStatic
    fun getContentProviderAuthorityURI(context: Context): Uri{
      return Uri.Builder().scheme(ContentResolver.SCHEME_CONTENT).authority(getContentProviderAuthority(context)).appendPath(StickerContentProvider.METADATA).build()
    }

    @JvmStatic
    fun getContentProviderAuthority(context: Context): String {
      return context.packageName + ".stickercontentprovider"
    }
    
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "getPlatformVersion" ->
        result.success("Android " + android.os.Build.VERSION.RELEASE)
      "isWhatsAppInstalled" ->
        result.success(context?.let { WhitelistCheck.isWhatsAppInstalled(it) });
      "isWhatsAppConsumerAppInstalled" ->
        result.success(context?.packageManager?.let { WhitelistCheck.isWhatsAppConsumerAppInstalled(it) } ?: false);
      "isWhatsAppSmbAppInstalled" ->
        result.success(context?.packageManager?.let { WhitelistCheck.isWhatsAppSmbAppInstalled(it) } ?: false);
      "isStickerPackInstalled" -> {
        val stickerPackIdentifier = call.argument<String>("identifier");
        if (stickerPackIdentifier != null && context != null) {
          val installed = WhitelistCheck.isWhitelisted(context!!, stickerPackIdentifier)
          result.success(installed);
        }
      }
      "sendToWhatsApp" -> {
        pendingResult = result
        try{
          val stickerPack: StickerPack = ConfigFileManager.fromMethodCall(context!!, call)
          // update json file
          ConfigFileManager.addNewPack(context, stickerPack)
          context?.let { StickerPackValidator.verifyStickerPackValidity(it, stickerPack) };
          // send intent to whatsapp
          val pm = context?.packageManager
          val ws = pm?.let { WhitelistCheck.isWhatsAppConsumerAppInstalled(it) } ?: false
          if(!(ws || (pm?.let { WhitelistCheck.isWhatsAppSmbAppInstalled(it) } ?: false))){
            throw InvalidPackException(InvalidPackException.OTHER, "WhatsApp is not installed on target device!")
          }
          val whatsAppPackage = if(ws) WhitelistCheck.CONSUMER_WHATSAPP_PACKAGE_NAME else WhitelistCheck.SMB_WHATSAPP_PACKAGE_NAME
          val stickerPackIdentifier = stickerPack.identifier
          val stickerPackName = stickerPack.name
          val authority: String? = context?.let { getContentProviderAuthority(it) }

          val intent = createIntentToAddStickerPack(authority, stickerPackIdentifier, stickerPackName)
          intent.setPackage(whatsAppPackage)

          try {
            Log.d("WhatsappStickers", "Launching WhatsApp pack=$stickerPackIdentifier authority=$authority")
            this.activity?.startActivityForResult(intent, ADD_PACK)
          } catch (e: ActivityNotFoundException) {
            throw InvalidPackException(InvalidPackException.FAILED, "Sticker pack not added. If you'd like to add it, make sure you update to the latest version of WhatsApp.")
          }

        } catch (e: InvalidPackException){
          replyError(e.code, e.message ?: "Invalid sticker pack")
        } catch (e: java.io.IOException) {
          Log.e("WhatsappStickers", "Staging failed", e)
          replyError(InvalidPackException.FILE_NOT_FOUND, e.message ?: "Could not stage sticker files")
        }
      }
      else -> result.notImplemented()
    }
  }

  fun createIntentToAddStickerPack(authority: String?, identifier: String?, stickerPackName: String?): Intent {
    return Intent().apply {
      action = "com.whatsapp.intent.action.ENABLE_STICKER_PACK"
      putExtra(EXTRA_STICKER_PACK_ID, identifier)
      putExtra(EXTRA_STICKER_PACK_AUTHORITY, authority)
      putExtra(EXTRA_STICKER_PACK_NAME, stickerPackName)
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    this.activity = null
    channel.setMethodCallHandler(null)
  }

  override fun onDetachedFromActivity() {
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    this.activity = binding.activity
    binding.addActivityResultListener(this)
  }

  override fun onDetachedFromActivityForConfigChanges() {
  }

  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
    if (requestCode != ADD_PACK) return false
    if (pendingResult == null) {
      Log.w("WhatsappStickers", "onActivityResult ignored — no pending result")
      return true
    }

    when (resultCode) {
      Activity.RESULT_CANCELED -> {
        val validationError = data?.getStringExtra("validation_error")
        if (validationError != null) {
          Log.e("WhatsappStickers", "WhatsApp validation failed: $validationError")
          replyError("error", validationError)
        } else {
          replyError("cancelled", "cancelled")
        }
      }
      Activity.RESULT_OK -> {
        val bundle = data?.extras
        when {
          bundle?.containsKey("add_successful") == true -> replySuccess("add_successful")
          bundle?.containsKey("already_added") == true -> replyError("already_added", "already_added")
          else -> replySuccess("success")
        }
      }
      else -> replySuccess("unknown")
    }
    return true
  }
}
