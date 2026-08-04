import { sensor } from '@kit.SensorServiceKit'
import preferences from '@ohos.data.preferences'

@Component
export struct Calibrate {
  pathStack: NavPathStack = new NavPathStack()
  @State collecting: boolean = false
  @State offsetX: number = 0
  @State offsetY: number = 0
  @State offsetZ: number = 0
  @State done: boolean = false
  @State rangeX: number = 0
  @State rangeY: number = 0
  @State rangeZ: number = 0
  private minX: number = Number.MAX_VALUE
  private maxX: number = -Number.MAX_VALUE
  private minY: number = Number.MAX_VALUE
  private maxY: number = -Number.MAX_VALUE
  private minZ: number = Number.MAX_VALUE
  private maxZ: number = -Number.MAX_VALUE

  // Stops the sensor when the page is hidden
  aboutToDisappear(): void {
    if (this.collecting) {
      sensor.off(sensor.SensorId.MAGNETIC_FIELD)
      this.collecting = false
    }
  }

  // Starts the sensor and collects min/max values for each axis to calculate offsets.
  private startCalibration(): void {
    this.minX = Number.MAX_VALUE;
    this.maxX = -Number.MAX_VALUE
    this.minY = Number.MAX_VALUE;
    this.maxY = -Number.MAX_VALUE
    this.minZ = Number.MAX_VALUE;
    this.maxZ = -Number.MAX_VALUE
    this.rangeX = 0
    this.rangeY = 0
    this.rangeZ = 0
    this.done = false
    this.collecting = true

    try {
      sensor.on(sensor.SensorId.MAGNETIC_FIELD, (data: sensor.MagneticFieldResponse) => {
        this.minX = Math.min(this.minX, data.x)
        this.maxX = Math.max(this.maxX, data.x)
        this.minY = Math.min(this.minY, data.y)
        this.maxY = Math.max(this.maxY, data.y)
        this.minZ = Math.min(this.minZ, data.z)
        this.maxZ = Math.max(this.maxZ, data.z)

        this.rangeX = this.maxX - this.minX
        this.rangeY = this.maxY - this.minY
        this.rangeZ = this.maxZ - this.minZ
      }, { interval: 50_000_000 })
    } catch (e) {
      this.collecting = false
    }
  }

  // Stops the sensor, calculates offsets, and saves them to preferences.
  private finishCalibration(): void {
    sensor.off(sensor.SensorId.MAGNETIC_FIELD)
    this.collecting = false

    this.offsetX = (this.maxX + this.minX) / 2
    this.offsetY = (this.maxY + this.minY) / 2
    this.offsetZ = (this.maxZ + this.minZ) / 2
    this.done = true

    this.saveOffsets()
  }

  private coverageOk(): boolean {
    return this.rangeX > 60 && this.rangeY > 60 && this.rangeZ > 60
  }

  // Saves the calculated offsets to preferences for later use.
  private async saveOffsets(): Promise<void> {
    try {
      const store = await preferences.getPreferences(getContext(this), 'magcal')
      await store.put('offsetX', this.offsetX)
      await store.put('offsetY', this.offsetY)
      await store.put('offsetZ', this.offsetZ)
      await store.flush()
    } catch (e) {
      console.info('Save failed')
    }
  }

  build() {
    NavDestination() {
      Column({ space: 12 }) {
        Text($r('app.string.title_calibration'))
          .fontSize(20)
          .fontColor($r('app.color.text_primary'))
        if (this.collecting) {
          Text($r('app.string.hint_figure_eight'))
            .fontSize(14)
            .fontColor($r('app.color.status_warning'))
          Text(`X ${this.rangeX.toFixed(0)}  Y ${this.rangeY.toFixed(0)}  Z ${this.rangeZ.toFixed(0)}`)
            .fontSize(12)
            .fontColor(this.coverageOk() ? $r('app.color.status_normal') : $r('app.color.text_secondary'))
          Text(this.coverageOk() ? $r('app.string.coverage_good') : $r('app.string.coverage_keep_rotating'))
            .fontSize(12)
            .fontColor(this.coverageOk() ? $r('app.color.status_normal') : $r('app.color.text_secondary'))
          Button($r('app.string.btn_finish'))
            .fontSize(13)
            .height(34)
            .enabled(this.coverageOk())
            .onClick(() => this.finishCalibration())
        } else if (this.done) {
          Text($r('app.string.label_offsets'))
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
          Text(`X ${this.offsetX.toFixed(1)}`)
            .fontSize(12)
            .fontColor($r('app.color.status_normal'))
          Text(`Y ${this.offsetY.toFixed(1)}`)
            .fontSize(12)
            .fontColor($r('app.color.status_normal'))
          Text(`Z ${this.offsetZ.toFixed(1)}`)
            .fontSize(12)
            .fontColor($r('app.color.status_normal'))
          Button($r('app.string.btn_redo'))
            .fontSize(13)
            .height(34)
            .onClick(() => this.startCalibration())
        } else {
          Text($r('app.string.hint_figure_eight'))
            .fontSize(11)
            .fontColor($r('app.color.text_secondary'))
            .textAlign(TextAlign.Center)
            .margin({ left: 20, right: 20 })
          Button($r('app.string.btn_start'))
            .fontSize(13)
            .height(34)
            .onClick(() => this.startCalibration())
        }
        Button($r('app.string.btn_back'))
          .fontSize(13)
          .height(30)
          .fontColor($r('app.color.bg_button_secondary'))
          .onClick(() => this.pathStack.pop())
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .backgroundColor($r('app.color.bg_primary'))
    }
    .hideTitleBar(true)
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack
    })
  }
}
