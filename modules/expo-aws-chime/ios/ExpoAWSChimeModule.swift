import ExpoModulesCore
import AmazonChimeSDK
import AVFoundation

public class ExpoAWSChimeModule: Module {
  private let logger = ConsoleLogger(name: "ExpoAWSChimeModule", level: .INFO)
  private var meetingSession: MeetingSession?

  public func definition() -> ModuleDefinition {
    Name("ExpoAWSChime")

    Events(
      "onMeetingStart",
      "onMeetingEnd",
      "onAttendeesJoin",
      "onAttendeesLeave",
      "onAttendeesMute",
      "onAttendeesUnmute",
      "onAddVideoTile",
      "onRemoveVideoTile",
      "onError"
    )

    AsyncFunction("startMeeting") { (meetingInfo: [String: Any], attendeeInfo: [String: Any]) in
      do {
        self.logger.info(msg: "Starting meeting with info: \(meetingInfo)")

        // Extract meeting info
        guard let meetingId = meetingInfo["MeetingId"] as? String else {
          throw ChimeError.missingField("MeetingId")
        }
        guard let externalMeetingId = meetingInfo["ExternalMeetingId"] as? String else {
          throw ChimeError.missingField("ExternalMeetingId")
        }
        guard let mediaRegion = meetingInfo["MediaRegion"] as? String else {
          throw ChimeError.missingField("MediaRegion")
        }
        guard let mediaPlacement = meetingInfo["MediaPlacement"] as? [String: Any] else {
          throw ChimeError.missingField("MediaPlacement")
        }

        // Extract media placement URLs
        guard let audioFallbackUrl = mediaPlacement["AudioFallbackUrl"] as? String else {
          throw ChimeError.missingField("AudioFallbackUrl")
        }
        guard let audioHostUrl = mediaPlacement["AudioHostUrl"] as? String else {
          throw ChimeError.missingField("AudioHostUrl")
        }
        guard let signalingUrl = mediaPlacement["SignalingUrl"] as? String else {
          throw ChimeError.missingField("SignalingUrl")
        }
        guard let turnControlUrl = mediaPlacement["TurnControlUrl"] as? String else {
          throw ChimeError.missingField("TurnControlUrl")
        }

        // Extract attendee info
        guard let attendeeId = attendeeInfo["AttendeeId"] as? String else {
          throw ChimeError.missingField("AttendeeId")
        }
        guard let externalUserId = attendeeInfo["ExternalUserId"] as? String else {
          throw ChimeError.missingField("ExternalUserId")
        }
        guard let joinToken = attendeeInfo["JoinToken"] as? String else {
          throw ChimeError.missingField("JoinToken")
        }

        self.logger.info(msg: "Creating meeting session")

        let meetingResponse = CreateMeetingResponse(meeting:
          Meeting(
            externalMeetingId: externalMeetingId,
            mediaPlacement: MediaPlacement(
              audioFallbackUrl: audioFallbackUrl,
              audioHostUrl: audioHostUrl,
              signalingUrl: signalingUrl,
              turnControlUrl: turnControlUrl
            ),
            mediaRegion: mediaRegion,
            meetingId: meetingId
          )
        )

        let attendeeResponse = CreateAttendeeResponse(attendee:
          Attendee(
            attendeeId: attendeeId,
            externalUserId: externalUserId,
            joinToken: joinToken
          )
        )

        let configuration = MeetingSessionConfiguration(
          createMeetingResponse: meetingResponse,
          createAttendeeResponse: attendeeResponse
        )

        self.meetingSession = DefaultMeetingSession(
          configuration: configuration,
          logger: self.logger
        )

        self.logger.info(msg: "Meeting session created")

        guard let audioVideo = self.meetingSession?.audioVideo else {
          throw ChimeError.sessionNotInitialized
        }

        // Add observers
        audioVideo.addAudioVideoObserver(observer: self)
        audioVideo.addRealtimeObserver(observer: self)
        audioVideo.addVideoTileObserver(observer: self)

        // Start audio and video
        self.logger.info(msg: "Starting audio and video")
        try audioVideo.start()
        audioVideo.startRemoteVideo()
        self.logger.info(msg: "Audio and video started")

        // Route audio to speaker
        self.logger.info(msg: "Routing audio to speaker")
        self.configureAudioSession()
        self.logger.info(msg: "Audio routed to speaker")

        self.logger.info(msg: "Meeting started successfully")
      } catch {
        self.logger.error(msg: "Error starting meeting: \(error.localizedDescription)")
        self.sendEvent("onError", ["error": error.localizedDescription])
        throw error
      }
    }

    AsyncFunction("stopMeeting") { () -> Any? in
      self.logger.info(msg: "Stopping meeting")

      // Stop local video first
      self.meetingSession?.audioVideo.stopLocalVideo()

      // Stop the meeting session
      self.meetingSession?.audioVideo.stop()

      // Clean up
      self.meetingSession = nil
      self.logger.info(msg: "Meeting stopped and cleaned up")

      return nil
    }

    AsyncFunction("mute") { () -> Any? in
      self.logger.info(msg: "Muting local audio")
      self.meetingSession?.audioVideo.realtimeLocalMute()
      self.logger.info(msg: "Local audio muted")
      return nil
    }

    AsyncFunction("unmute") { () -> Any? in
      self.logger.info(msg: "Unmuting local audio")
      self.meetingSession?.audioVideo.realtimeLocalUnmute()
      self.logger.info(msg: "Local audio unmuted")
      return nil
    }

    AsyncFunction("startLocalVideo") { () -> Any? in
      self.logger.info(msg: "Starting local video")
      do {
        try self.meetingSession?.audioVideo.startLocalVideo()
        self.logger.info(msg: "Local video started")
      } catch {
        self.logger.error(msg: "Error starting local video: \(error.localizedDescription)")
        self.sendEvent("onError", ["error": error.localizedDescription])
        throw error
      }
      return nil
    }

    AsyncFunction("stopLocalVideo") { () -> Any? in
      self.logger.info(msg: "Stopping local video")
      self.meetingSession?.audioVideo.stopLocalVideo()
      self.logger.info(msg: "Local video stopped")
      return nil
    }

    View(ExpoAWSChimeView.self) {
      Prop("tileId") { (view: ExpoAWSChimeView, tileId: Int) in
        self.logger.info(msg: "Binding tileId: \(tileId)")
        if let session = self.meetingSession {
          view.meetingSession = session
          view.setTileId(meetingSession: session, tileId: tileId)
          self.logger.info(msg: "tileId \(tileId) bound")
        }
      }

      Prop("isLocal") { (view: ExpoAWSChimeView, isLocal: Bool) in
        self.logger.info(msg: "Setting isLocal: \(isLocal)")
        view.setIsLocal(isLocal)
        self.logger.info(msg: "isLocal set to \(isLocal)")
      }
    }
  }

  private func configureAudioSession() {
    let audioSession = AVAudioSession.sharedInstance()
    do {
      try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth])
      try audioSession.setActive(true)
    } catch {
      logger.error(msg: "Failed to configure audio session: \(error.localizedDescription)")
    }
  }
}


// MARK: - AudioVideoObserver

extension ExpoAWSChimeModule: AudioVideoObserver {
  public func audioSessionDidStartConnecting(reconnecting: Bool) {}

  public func audioSessionDidStart(reconnecting: Bool) {
    logger.info(msg: "Audio session started with reconnecting: \(reconnecting)")
    if !reconnecting {
      sendEvent("onMeetingStart", [
        "timestamp": Int(Date().timeIntervalSince1970 * 1000)
      ])
      logger.info(msg: "Sent onMeetingStart event")
    }
  }

  public func audioSessionDidDrop() {}

  public func audioSessionDidStopWithStatus(sessionStatus: MeetingSessionStatus) {
    logger.info(msg: "Audio session stopped with status: \(sessionStatus.statusCode)")
    sendEvent("onMeetingEnd", [
      "sessionStatus": sessionStatus.statusCode.rawValue,
      "timestamp": Int(Date().timeIntervalSince1970 * 1000)
    ])
    logger.info(msg: "Sent onMeetingEnd event")
  }

  public func audioSessionDidCancelReconnect() {}
  public func connectionDidRecover() {}
  public func connectionDidBecomePoor() {}
  public func videoSessionDidStartConnecting() {}

  public func videoSessionDidStartWithStatus(sessionStatus: MeetingSessionStatus) {}

  public func videoSessionDidStopWithStatus(sessionStatus: MeetingSessionStatus) {}

  public func remoteVideoSourcesDidBecomeAvailable(sources: [RemoteVideoSource]) {}
  public func remoteVideoSourcesDidBecomeUnavailable(sources: [RemoteVideoSource]) {}
  public func cameraSendAvailabilityDidChange(available: Bool) {}
}

// MARK: - RealtimeObserver

extension ExpoAWSChimeModule: RealtimeObserver {
  public func volumeDidChange(volumeUpdates: [VolumeUpdate]) {}
  public func signalStrengthDidChange(signalUpdates: [SignalUpdate]) {}

  public func attendeesDidJoin(attendeeInfo: [AttendeeInfo]) {
    let attendeeIds = attendeeInfo.map { $0.attendeeId }
    let externalUserIds = attendeeInfo.map { $0.externalUserId }
    sendEvent("onAttendeesJoin", [
      "attendeeIds": attendeeIds,
      "externalUserIds": externalUserIds
    ])
    logger.info(msg: "Sent onAttendeesJoin event")
  }

  public func attendeesDidLeave(attendeeInfo: [AttendeeInfo]) {
    let attendeeIds = attendeeInfo.map { $0.attendeeId }
    let externalUserIds = attendeeInfo.map { $0.externalUserId }
    sendEvent("onAttendeesLeave", [
      "attendeeIds": attendeeIds,
      "externalUserIds": externalUserIds
    ])
    logger.info(msg: "Sent onAttendeesLeave event")
  }

  public func attendeesDidDrop(attendeeInfo: [AttendeeInfo]) {
    let attendeeIds = attendeeInfo.map { $0.attendeeId }
    let externalUserIds = attendeeInfo.map { $0.externalUserId }
    sendEvent("onAttendeesLeave", [
      "attendeeIds": attendeeIds,
      "externalUserIds": externalUserIds
    ])
    logger.info(msg: "Sent onAttendeesLeave event for dropped attendees")
  }

  public func attendeesDidMute(attendeeInfo: [AttendeeInfo]) {
    let attendeeIds = attendeeInfo.map { $0.attendeeId }
    sendEvent("onAttendeesMute", ["attendeeIds": attendeeIds])
    logger.info(msg: "Sent onAttendeesMute event")
  }

  public func attendeesDidUnmute(attendeeInfo: [AttendeeInfo]) {
    let attendeeIds = attendeeInfo.map { $0.attendeeId }
    sendEvent("onAttendeesUnmute", ["attendeeIds": attendeeIds])
    logger.info(msg: "Sent onAttendeesUnmute event")
  }
}

// MARK: - VideoTileObserver

extension ExpoAWSChimeModule: VideoTileObserver {
  public func videoTileDidAdd(tileState: VideoTileState) {
    sendEvent("onAddVideoTile", [
      "tileId": tileState.tileId,
      "attendeeId": tileState.attendeeId,
      "isLocal": tileState.isLocalTile,
      "isScreenShare": tileState.isContent,
      "pauseState": tileState.pauseState.rawValue,
      "videoStreamContentHeight": tileState.videoStreamContentHeight,
      "videoStreamContentWidth": tileState.videoStreamContentWidth
    ])
    logger.info(msg: "Sent onAddVideoTile event")
  }

  public func videoTileDidRemove(tileState: VideoTileState) {
    sendEvent("onRemoveVideoTile", [
      "tileId": tileState.tileId,
      "attendeeId": tileState.attendeeId,
      "isLocal": tileState.isLocalTile,
      "isScreenShare": tileState.isContent
    ])
    logger.info(msg: "Sent onRemoveVideoTile event")
  }

  public func videoTileDidPause(tileState: VideoTileState) {}
  public func videoTileDidResume(tileState: VideoTileState) {}
  public func videoTileSizeDidChange(tileState: VideoTileState) {}
}

// MARK: - Error Types

enum ChimeError: LocalizedError {
  case missingField(String)
  case sessionNotInitialized

  var errorDescription: String? {
    switch self {
    case .missingField(let field):
      return "\(field) is required"
    case .sessionNotInitialized:
      return "Meeting session not initialized"
    }
  }
}
