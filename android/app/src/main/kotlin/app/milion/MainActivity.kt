package app.milion

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "milion/rotation")
            .setStreamHandler(RotationStream(this))
    }
}

/**
 * LU look-up: the device-to-world rotation matrix (row-major, 9 floats) from
 * the game rotation vector (gyroscope + accelerometer, no magnetometer, so a
 * church's metal does not swing the view). World Z is up; the heading is
 * arbitrary and re-centred in Dart. Listens only while Dart subscribes.
 */
private class RotationStream(context: Context) : EventChannel.StreamHandler, SensorEventListener {
    private val sensors = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    private val matrix = FloatArray(9)
    private var sink: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        val sensor = sensors.getDefaultSensor(Sensor.TYPE_GAME_ROTATION_VECTOR)
            ?: sensors.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
        if (sensor == null) {
            events.error("unavailable", "No rotation-vector sensor", null)
            return
        }
        sink = events
        // The view repaints only when a reading arrives, so readings must come
        // faster than the display: SENSOR_DELAY_GAME (20 ms, 50 Hz) left a
        // 33 ms gap about ten times a second on the A52s's 60 Hz screen
        // (2026-11-09). 10 ms stays under Android 12's 200 Hz limit.
        sensors.registerListener(this, sensor, SAMPLING_PERIOD_US)
    }

    companion object {
        const val SAMPLING_PERIOD_US = 10_000
    }

    override fun onCancel(arguments: Any?) {
        sensors.unregisterListener(this)
        sink = null
    }

    override fun onSensorChanged(event: SensorEvent) {
        SensorManager.getRotationMatrixFromVector(matrix, event.values)
        sink?.success(matrix.map { it.toDouble() })
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit
}
