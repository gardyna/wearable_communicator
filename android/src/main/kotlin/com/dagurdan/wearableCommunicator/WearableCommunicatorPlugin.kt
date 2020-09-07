package com.dagurdan.wearableCommunicator

import android.app.Activity
import androidx.annotation.NonNull
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable
import io.flutter.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import org.json.JSONObject

/** WearableCommunicatorPlugin */
public class WearableCommunicatorPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel

  private var activity: Activity? = null

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.getFlutterEngine().getDartExecutor(), "wearableCommunicator")
    channel.setMethodCallHandler(this);
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
    @JvmStatic
    fun registerWith(registrar: Registrar) {
      val channel = MethodChannel(registrar.messenger(), "wearableCommunicator")
      channel.setMethodCallHandler(WearableCommunicatorPlugin())
    }
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
        "getPlatformVersion" -> {
          result.success("Android ${android.os.Build.VERSION.RELEASE}")
        }
        "sendMessage" -> {
            sendMessage(call, result)
        }
        "setData" -> {
            setData(call, result)
        }
        "listenMessages" -> {
            registerMessageListener(call, result)
        }
        "listenData" -> {
            registerDataLayerListener(call, result)
        }
        else -> {
          result.notImplemented()
        }
    }
  }

    private fun registerMessageListener(call: MethodCall, result: Result) {
    }

    private fun registerDataLayerListener(call: MethodCall, result: Result) {
        Wearable.getDataClient(activity!!).addListener { dataEventBuffer ->
            dataEventBuffer.forEach { event ->
                channel.invokeMethod("dataReceived", event.dataItem.data)
            }
        }
    }

    private fun sendMessage(call: MethodCall, result: Result) {
        if (activity == null) {
            result.success(null)
        } else {
            try {
                val argument = call.arguments<HashMap<String, Any>>()
                val client = Wearable.getMessageClient(activity!!)
                Wearable.getNodeClient(activity!!).connectedNodes.addOnSuccessListener { nodes ->
                    nodes.forEach { node ->
                        val json = JSONObject(argument).toString()
                        client.sendMessage(node.id, "MessageChannel", json.toByteArray())
                        Log.d("WearableCommunicator","sent message: $json to ${node.displayName}")
                    }
                    result.success(null)
                }.addOnFailureListener { ex ->
                    result.error(ex.message, ex.localizedMessage, ex)
                }

            } catch (ex: Exception) {
                Log.d("WearableCommunicator", "Failed to send message", ex)
            }
        }
    }

    private fun setData(call: MethodCall, result: Result) {
        try {
            val data = call.argument<HashMap<String, Any>>("data") ?: return
            val name = call.argument<String>("path") ?: return
            val request = PutDataMapRequest.create(name).run {
                loop@ for ((key, value) in data) {
                    when(value) {
                        is String -> dataMap.putString(key, value)
                        is Int -> dataMap.putInt(key, value)
                        is Float -> dataMap.putFloat(key, value)
                        is Double -> dataMap.putDouble(key, value)
                        is Long -> dataMap.putLong(key, value)
                        is Boolean -> dataMap.putBoolean(key, value)
                        is List<*> -> {
                            if (value.isNullOrEmpty()) continue@loop
                            value.asArrayListOfType<Int>()?.let {
                                dataMap.putIntegerArrayList(key, it)
                            }
                            value.asArrayListOfType<String>()?.let {
                                dataMap.putStringArrayList(key, it)
                            }
                            value.asArrayOfType<Float>()?.let {
                                dataMap.putFloatArray(key, it.toFloatArray())
                            }
                            value.asArrayOfType<Long>()?.let {
                                dataMap.putLongArray(key, it.toLongArray())
                            }
                        }
                        else -> {
                        }
                    }
                }
                asPutDataRequest()
            }
            Wearable.getDataClient(activity!!).putDataItem(request)
            result.success(null)
        } catch (ex: Exception) {
            Log.d("WearableCommunicator", "Failed to send message", ex)
        }
    }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }
}

inline fun <reified T> List<*>.asArrayListOfType(): ArrayList<T>? =
        if (all { it is T })
            @Suppress("UNCHECKED_CAST")
            this as ArrayList<T> else
            null

inline fun <reified T> List<*>.asArrayOfType(): Array<T>? =
        if (all { it is T })
            @Suppress("UNCHECKED_CAST")
            this as Array<T> else
            null

