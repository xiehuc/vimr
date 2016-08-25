/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

import Cocoa
import RxSwift

enum MainWindowEvent {
  case allWindowsClosed
}

class MainWindowManager {
  
  static private let userHomeUrl = NSURL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)

  private let source: Observable<Any>
  private let disposeBag = DisposeBag()

  private let subject = PublishSubject<Any>()
  var sink: Observable<Any> {
    return self.subject.asObservable()
  }
  
  private var mainWindowComponents = [String:MainWindowComponent]()
  private var keyMainWindow: MainWindowComponent?

  private var data: PrefData

  init(source: Observable<Any>, initialData: PrefData) {
    self.source = source
    self.data = initialData

    self.addReactions()
  }

  func newMainWindow(urls urls: [NSURL] = [], cwd: NSURL = MainWindowManager.userHomeUrl) -> MainWindowComponent {
    let mainWindowComponent = MainWindowComponent(
      source: self.source, manager: self, urls: urls, initialData: self.data
    )
    mainWindowComponent.set(cwd: cwd)
    self.mainWindowComponents[mainWindowComponent.uuid] = mainWindowComponent
    
    return mainWindowComponent
  }
  
  func closeMainWindow(mainWindowComponent: MainWindowComponent) {
    if self.keyMainWindow === mainWindowComponent {
//      NSLog("\(#function): Setting key main window to nil from \(self.keyMainWindow?.uuid)")
      self.keyMainWindow = nil
    }
    self.mainWindowComponents.removeValueForKey(mainWindowComponent.uuid)
    
    if self.mainWindowComponents.isEmpty {
      self.subject.onNext(MainWindowEvent.allWindowsClosed)
    }
  }

  func hasDirtyWindows() -> Bool {
    return self.mainWindowComponents.values.reduce(false) { $0 ? true : $1.isDirty() }
  }
  
  func openInKeyMainWindow(urls urls:[NSURL] = [], cwd: NSURL = MainWindowManager.userHomeUrl) {
    guard !self.mainWindowComponents.isEmpty else {
      self.newMainWindow(urls: urls, cwd: cwd)
      return
    }
    
    guard let keyMainWindow = self.keyMainWindow else {
      self.newMainWindow(urls: urls, cwd: cwd)
      return
    }
    
    keyMainWindow.set(cwd: cwd)
    keyMainWindow.open(urls: urls)
  }
  
  func setKeyWindow(mainWindow: MainWindowComponent?) {
    self.keyMainWindow = mainWindow
  }
  
  func closeAllWindowsWithoutSaving() {
    self.mainWindowComponents.values.forEach { $0.closeAllNeoVimWindowsWithoutSaving() }
  }

  /// Assumes that no window is dirty.
  func closeAllWindows() {
    self.mainWindowComponents.values.forEach { $0.closeAllNeoVimWindows() }
  }

  func hasMainWindow() -> Bool {
    return !self.mainWindowComponents.isEmpty
  }

  private func addReactions() {
    self.source
      .filter { $0 is PrefData }
      .map { $0 as! PrefData }
      .subscribeNext { [unowned self] prefData in
        self.data = prefData
      }
      .addDisposableTo(self.disposeBag)
  }
}