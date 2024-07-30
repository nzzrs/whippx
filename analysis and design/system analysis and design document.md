
## introduction
this document provides a comprehensive analysis and design for whisperx.

## system overview

### general description
the system is designed to provide transcription services for audio files and audio recording. it aims to assist users by converting spoken words into text, facilitating the creation of written records of audio content. the system also allows users to save both transcribed text and recorded audio files locally.

### system architecture
the system is built using flutter for cross-platform mobile development, and utilizes whisperx for transcription services on a remote server running in render. the app is designed to run on both android and ios platforms.

## high-level design

### architecture diagram

```mermaid
%%{init: {"theme": "dark", "flowchart": {"curve": "linear", "useMaxWidth": false}}}%%
flowchart TD

subgraph flutter_app [flutter application]

    ui[user interface]
    logic[business logic]
    whisperx_api[whisperx api]
    storage[local storage]

end

subgraph render_server [render server]

    whisperx_service[whisperx service]

end

user --> ui
ui --> logic
logic --> whisperx_api
logic --> storage
whisperx_api -->|transcription request| whisperx_service
whisperx_service -->|transcription response| whisperx_api
storage -->|save/load files| logic
```

### components diagram

```mermaid
%%{init: {"theme": "dark", "flowchart": {"curve": "linear", "useMaxWidth": false}}}%%
flowchart TD

subgraph flutter_app [flutter application]

    ui[user interface]
    audio_manager[audio manager]
    transcription_service[transcription service]
    file_manager[file manager]
    storage[local storage]

end

subgraph render_server [render server]

    whisperx_service[whisperx service]

end

user --> ui
ui --> audio_manager
audio_manager --> transcription_service
audio_manager --> file_manager
transcription_service --> whisperx_api
whisperx_api --> whisperx_service
file_manager --> storage
```

### interfaces

- **user interface (ui)**: provides the front-end components for user interactions.
- **audio manager**: handles audio recording and playback functionalities.
- **transcription service**: interfaces with whisperx to transcribe audio.
- **file manager**: manages the saving and loading of audio and text files.
- **local storage**: provides the mechanism for storing files on the device.
- **whisperx api**: sends transcription requests to the whisperx service on the render server.
- **render server**: remote server hosting the whisperx service.

## detailed design

### class diagram

```mermaid
%%{init: {"theme": "dark", "flowchart": {"curve": "linear", "useMaxWidth": false}}}%%
classDiagram

class ui {
    - start_recording()
    - stop_recording()
    - save_transcription()
}

class audio_manager {
    - record_audio()
    - stop_recording()
}

class transcription_service {
    - transcribe_audio()
}

class file_manager {
    - save_file()
    - load_file()
}

class local_storage {
    - store_data()
    - retrieve_data()
}

class whisperx_api {
    - send_request()
    - receive_response()
}

```

### sequence diagrams

#### rq01 sequence

```mermaid

%%{init: {"theme": "dark", "sequence": {"mirrorActors": true}}}%%

sequenceDiagram
    participant user
    participant ui
    participant audio_manager
    participant transcription_service
    participant whisperx_api
    participant render_server

    user->>ui: open application
    ui->>user: display ui
    user->>ui: select audio file
    ui->>audio_manager: process audio file
    audio_manager->>transcription_service: transcribe audio file
    transcription_service->>whisperx_api: send audio file
    whisperx_api->>render_server: transcribe audio
    render_server->>whisperx_api: return transcribed text
    whisperx_api->>transcription_service: return transcribed text
    transcription_service-->>audio_manager: return transcribed text
    audio_manager-->>ui: display transcribed text
    ui->>user: show transcribed text

```

#### rq02 sequence

```mermaid

%%{init: {"theme": "dark", "sequence": {"mirrorActors": true}}}%%

sequenceDiagram
    participant user
    participant ui
    participant audio_manager
    participant transcription_service
    participant whisperx_api
    participant render_server

    user->>ui: open application
    ui->>user: display ui
    user->>ui: start recording
    ui->>audio_manager: start recording audio
    user->>ui: stop recording
    ui->>audio_manager: stop recording audio
    audio_manager->>transcription_service: transcribe audio file
    transcription_service->>whisperx_api: send audio file
    whisperx_api->>render_server: transcribe audio
    render_server->>whisperx_api: return transcribed text
    whisperx_api->>transcription_service: return transcribed text
    transcription_service-->>audio_manager: return transcribed text
    audio_manager-->>ui: display final transcribed text
    ui->>user: show final transcribed text

```
### state diagram

```mermaid
%%{init: {"theme": "dark", "flowchart": {"curve": "linear", "useMaxWidth": false}}}%%
stateDiagram-v2
    [*] --> idle
    
    idle --> recording : start_recording()
    recording --> processing : stop_recording()
    processing --> displaying : transcription complete
    
	idle --> selecting_file : selecting_file()
    selecting_file --> transcribing : transcribing()
    transcribing --> displaying : transcription complete
    displaying --> idle : save_transcription()

```

### user interface design

- **home screen**: features a large microphone icon in the center, an open icon in one corner, and the app name in the other corner. when recording, the animation shows audio levels in form of waves.
- **transcription screen**: shows the transcribed text with option to save.

### technical considerations

### platform and environment
- **platforms**: android and ios
- **environment**: developed using flutter, integrated with whisperx for transcription services hosted on render
- **server service**: render

### technologies and tools
- **flutter**: cross-platform mobile development framework
- **whisperx**: transcription model
- **emacs**: ide