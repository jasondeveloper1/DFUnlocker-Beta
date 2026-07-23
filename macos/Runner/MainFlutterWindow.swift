import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    let minSize = NSSize(width: 1100, height: 700)
    self.minSize = minSize
    self.setContentSize(NSSize(width: 1200, height: 760))
    self.title = "DFUUnlocker beta"

    super.awakeFromNib()
  }
}
