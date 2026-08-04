import { sensor } from '@kit.SensorServiceKit'
import { Calibrate } from './Calibrate'

@Entry
@Component
struct Index {
  @State magnitude: number = 0;
  pathStack: NavPathStack = new NavPathStack()
  @State error: boolean = false
  private listening: boolean = false

  // Subscribe when the page becomes visible, so returning from
  // calibration restarts the stream that Calibrate closed.
  onPageShow(): void {
    this.startSensor()
  }

  aboutToDisappear(): void {
    this.stopSensor()
  }

  // Guard against double subscription
  private startSensor() {
    if (this.listening) {
      return
    }
    try {
      sensor.on(sensor.SensorId.MAGNETIC_FIELD, (data: sensor.MagneticFieldResponse) => {
        this.magnitude = Math.sqrt(data.x * data.x + data.y * data.y + data.z * data.z);
      }, { interval: 100_000_000 })
      this.listening = true
    } catch (e) {
      this.error = true;
    }
  }

  //Stops the sensor when the page is hidden or when navigating to calibration.
  private stopSensor() {
    if (!this.listening) {
      return
    }
    sensor.off(sensor.SensorId.MAGNETIC_FIELD)
    this.listening = false
  }

  // Navigates to the calibration page and stops the sensor to avoid double subscription.
  private openCalibration(): void {
    this.stopSensor()
    this.pathStack.pushPathByName('Calibrate', '')
  }

  private statusColor(): ResourceColor {
    if (this.magnitude < 25 || this.magnitude > 120) {
      return $r('app.color.status_danger')
    }
    if (this.magnitude > 65) {
      return $r('app.color.status_warning')
    }
    return $r('app.color.status_normal')
  }

  private statusText(): Resource {
    if (this.magnitude < 25) {
      return $r('app.string.status_too_weak')
    }
    if (this.magnitude > 120) {
      return $r('app.string.status_strong_interference')
    }
    if (this.magnitude > 65) {
      return $r('app.string.status_interference')
    }
    return $r('app.string.status_normal')

  }

  @Builder
  PageMap(name: string) {
    if (name === 'Calibrate') {
      Calibrate()
    }
  }

  build() {
    Navigation(this.pathStack) {
      Column({ space: 12 }) {
        if (this.error) {
          Text($r('app.string.error_sensor_unavailable'))
            .fontSize(20)
            .fontColor($r('app.color.status_danger'))
        } else {
          Text(`${this.magnitude.toFixed(1)}`)
            .fontSize(48)
            .fontColor(this.statusColor())
        }
        Text($r('app.string.unit_microtesla'))
          .fontSize(18)
          .fontColor($r('app.color.text_secondary'))
        Text(this.statusText())
          .fontSize(20)
          .fontColor(this.statusColor())
        Button($r('app.string.btn_calibrate'))
          .fontSize(16)
          .margin({ top: 10 })
          .onClick(() => this.openCalibration())
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .backgroundColor($r('app.color.bg_primary'))
    }
    .hideTitleBar(true)
    .navDestination(this.PageMap)
    .onNavBarStateChange((isVisible: boolean) => {
      if (isVisible) {
        this.startSensor()
      }
    })
    .width('100%')
    .height('100%')
  }
}