from flask import Flask, jsonify
from flask_socketio import SocketIO, emit
import whisperx
import torch
import tempfile
import os
import base64

app = Flask(__name__)
socketio = SocketIO(app, cors_allowed_origins="*")

device = "cuda" if torch.cuda.is_available() else "cpu"
_models = {}

def get_model(size):
    if size not in _models:
        print(f"Loading model: {size}")
        _models[size] = whisperx.load_model(size, device, compute_type="float32")
    return _models[size]

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({"status": "ok"}), 200

@socketio.on('connect')
def handle_connect():
    print('Client connected')

@socketio.on('disconnect')
def handle_disconnect():
    print('Client disconnected')

@socketio.on('transcribe')
def handle_transcribe(data):
    audio_data = data['audio']
    model_size = data.get('model_size', 'large-v2')
    tmp_path = None

    valid_models = ["small", "medium", "large-v2"]
    if model_size not in valid_models:
        emit('error', {'error': 'Invalid model size'})
        return

    try:
        model = get_model(model_size)

        decoded_audio_data = base64.b64decode(audio_data)

        with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as tmp:
            tmp.write(decoded_audio_data)
            tmp_path = tmp.name

        audio = whisperx.load_audio(tmp_path)
        result = model.transcribe(audio, batch_size=16)
        transcription_text = "\n".join([segment['text'] for segment in result["segments"]])
        emit('transcription_result', {'transcription': transcription_text})
    except Exception as e:
        emit('error', {'error': str(e)})
    finally:
        if tmp_path and os.path.exists(tmp_path):
            os.remove(tmp_path)

if __name__ == '__main__':
    socketio.run(app, debug=True, host='0.0.0.0')
