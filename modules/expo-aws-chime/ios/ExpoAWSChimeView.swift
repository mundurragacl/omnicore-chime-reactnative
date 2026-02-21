import ExpoModulesCore
import AmazonChimeSDK
import UIKit

class ExpoAWSChimeView: ExpoView {
  private let logger = ConsoleLogger(name: "ExpoAWSChimeView", level: .INFO)
  var tileId: Int?
  private var isLocalTile: Bool = false
  weak var meetingSession: MeetingSession?

  private lazy var videoRenderView: DefaultVideoRenderView = {
    let renderView = DefaultVideoRenderView()
    renderView.contentMode = .scaleAspectFill
    renderView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(renderView)
    NSLayoutConstraint.activate([
      renderView.topAnchor.constraint(equalTo: topAnchor),
      renderView.bottomAnchor.constraint(equalTo: bottomAnchor),
      renderView.leadingAnchor.constraint(equalTo: leadingAnchor),
      renderView.trailingAnchor.constraint(equalTo: trailingAnchor)
    ])
    logger.info(msg: "Video render view created and added")
    return renderView
  }()

  required init(appContext: AppContext? = nil) {
    super.init(appContext: appContext)
    logger.info(msg: "Creating ExpoAWSChimeView")
    // Trigger lazy initialization
    _ = videoRenderView
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    if let session = meetingSession, let currentTileId = tileId {
      logger.info(msg: "deinit: Unbinding video view from tile \(currentTileId)")
      session.audioVideo.unbindVideoView(tileId: currentTileId)
    }
  }

  func setIsLocal(_ isLocal: Bool) {
    logger.info(msg: "Setting isLocal to \(isLocal) for tile \(String(describing: tileId))")
    self.isLocalTile = isLocal
    // Mirror local camera for self-view
    if isLocal {
      videoRenderView.mirror = true
    }
    logger.info(msg: "Set isLocal to \(isLocal) for tile \(String(describing: tileId))")
  }

  func setTileId(meetingSession: MeetingSession, tileId: Int) {
    logger.info(msg: "Binding video view to tile \(tileId)")
    self.tileId = tileId
    meetingSession.audioVideo.bindVideoView(videoView: videoRenderView, tileId: tileId)
    logger.info(msg: "Successfully bound video view to tile \(tileId)")
  }

  func unsetTileId(meetingSession: MeetingSession) {
    if let currentTileId = tileId {
      logger.info(msg: "Unbinding video view from tile \(currentTileId)")
      meetingSession.audioVideo.unbindVideoView(tileId: currentTileId)
      self.tileId = nil
      self.isLocalTile = false
      logger.info(msg: "Successfully unbound video view from tile \(currentTileId)")
    }
  }
}
